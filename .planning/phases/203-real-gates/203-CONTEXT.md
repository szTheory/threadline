# Phase 203: Real Gates - Context

**Gathered:** 2026-09-22
**Status:** Ready for planning
**Mode:** Advisor (research-then-recommend). Three parallel research passes; maintainer accepted the full recommendation set ("go ahead follow ur recs auto").

<domain>
## Phase Boundary

Make `mix credo --strict` a gate with teeth: Credo's full default check set, rebuilt verbatim from `deps/credo/.credo.exs` with project adjustments expressed only as `extra:`/`disabled:` deltas. Every finding is fixed or held by a counted, test-pinned register naming a successor. Fix the three layer inversions into `Threadline.OperatorSurface.*` and delete the Capture↔Semantics `no_warn_undefined` papering. Fix stale file-location comments and missing `@moduledoc`s. Requirements GATE-01..GATE-05.

Out of scope: any fix requiring extracting a module or splitting a function (→ Phase 204); opt-in Credo checks such as `Readability.Specs` (→ TYPES-01); `boundary` library adoption; any operator-UI design/IA/visual change; capture/query/auth semantic change; Elixir/OTP floor bump.

</domain>

<decisions>
## Implementation Decisions

### Measured starting point (re-measured 2026-09-22, supersedes 198-01's 377)
- **D-00:** Full-default Credo today = **484 findings** (198-01 measured 377; Phase 201 grew it). `AliasUsage` 356 (lib 24 / test 332). Excluding AliasUsage: 128 (lib 91 / test 37) = **82 mechanical + 46 structural** (30 `Refactor.Nesting`, 16 `Refactor.CyclomaticComplexity`, complexity 10–33, max at `Retention.Policy.resolve!`). Raw JSON: `/Users/jon/.claude/jobs/77cf1bdd/tmp/credo-now.json` (ephemeral — planner must re-measure with `mix credo --strict --config-file deps/credo/.credo.exs --format json`, never by editing `.credo.exs`).
- **D-00b:** **Dialyzer backlog is already drained**: `mix dialyzer --no-check` → `Total errors: 0`, `.dialyzer_ignore.exs` is `[]`. The "dialyzer backlog drained" goal clause is verify-only in this phase, not work — do not invent a dialyzer plan. Re-confirm at phase end after the refactors.

### Sizing-rule resolution
- **D-01:** 484 lands in the pre-committed 150–600 band → **split mechanical from judgment**. The ">600 or one dominating check → register it" branch is NOT taken: measured, AliasUsage's 356 findings are only **91 distinct (file, aliased-module) pairs across 56 files** (three targets = 169: `Threadline.Test.Repo` 83, `Threadline.Storage.Local` 58, `Ecto.Adapters.SQL` 28). Registering cheap mechanical debt would be less honest than paying it. This also removes the conflict with the roadmap's "never disable AliasUsage".

### Credo config shape (GATE-01)
- **D-02:** `.credo.exs` = `deps/credo/.credo.exs` copied verbatim, then deltas only. **No `enabled:` key anywhere.** — **Reversibility:** reversible.
- **D-03:** `AliasUsage` stays at Credo's upstream defaults in both `lib/` and `test/` — no `if_called_more_often_than: 2` delta (measured: it only drops 356→279, doesn't earn a delta), no per-check `files: %{excluded: ["test/"]}` scoping. Fix all 356.
- **D-04:** `Design.TagTODO` → `exit_status: 0` via `extra:`; `Design.TagFIXME` stays blocking (the honest asymmetry). Planner must **verify** that an `extra:` entry for an already-default check overrides its params in Credo 1.7.18 (e.g. `mix credo explain`/config contract test showing TagTODO exit_status 0) — if not, use the mechanism that does and record it.
- **D-05:** Nesting / CyclomaticComplexity keep upstream thresholds (`max_nesting 2`, `max_complexity 9`). No raised thresholds (max complexity 33 would hide every new complex function), no disabling.
- **D-06:** Upstream opt-in (`disabled:`) list stays verbatim — do not enable `Readability.Specs` or any opt-in check (TYPES-01).

### Structural findings filed to Phase 204 (GATE-02)
- **D-07:** All **46** structural findings (30 Nesting + 16 CyclomaticComplexity) are filed to Phase 204 per the hard rule, held by a per-site `# credo:disable-for-next-line Credo.Check.Refactor.<Check>` placed directly above the **reported** line (for Nesting that's the nested construct, not the `def`). The Phase 204 reference goes on its **own comment line above** (Credo parses trailing text after the check name as params — `config_comment.ex`). No blanket filing: a Nesting site that flattens with `with` *without* extracting/splitting a function may be fixed in place instead; the count shrinks accordingly.
- **D-08:** The enforced register lives in **source, not `.planning/`** (DECOUPLE-01 forbids gates reading `.planning/`): new `test/threadline/credo_config_contract_test.exs`, modelled on `test/threadline/dialyzer_ignore_contract_test.exs` `@warning_ceiling`. It asserts:
  1. `.credo.exs` has no `enabled:` key and its delta list equals a pinned list exactly;
  2. count of `credo:disable-for-next-line Credo.Check.Refactor.(Nesting|CyclomaticComplexity)` in `lib/`+`test/` equals the per-check register counts and is ≤ a ceiling that only goes down (Phase 204 ratchets it);
  3. every other `credo:disable*` form is rejected (for-this-file, for-lines, nameless, any other check);
  4. each disable has an adjacent `# Phase 204 (STRUCT-…)` line;
  5. the scanned file set is non-empty (the "vacuous gate" lesson).
  Each register row = {check, exact count, successor "Phase 204 / STRUCT-xx"}. ROADMAP/phase docs only mirror it for humans.

### Mechanical fixes
- **D-09:** Fix all 82 mechanical findings in place. Two need a stated decision in the plan: `Warning.MissedMetadataKeyInLoggerConfig` at `lib/threadline/retention.ex:181` (a library must not own the host's Logger config — resolve via test-env config or the check's metadata param, and say which); `Warning.SpecWithStruct` in public `Threadline.Query` specs (use `AuditChange.t()`/`AuditTransaction.t()`; dialyzer must stay at 0).
- **D-10:** New `AliasOrder` findings created by alias insertion are fixed in the same plan. Short-name collisions (e.g. `StartLiveTest.Auth` vs `OperatorSurface.Auth`) must use `as:` — `--warnings-as-errors` compile is the backstop.

### Layer inversions (GATE-03)
- **D-11:** `git mv lib/threadline/operator_surface/scope.ex lib/threadline/query/scope.ex` → `Threadline.Query.Scope` (keep `@moduledoc false`). Its only caller is `Query.maybe_apply_scope/2`; no operator-surface module calls it (they pass `:scope_query_fn` via opts). Same commit retargets the refute lists in `test/threadline/code_walkthrough_doc_contract_test.exs:80` and `test/threadline/how_threadline_works_doc_contract_test.exs:78` to the new name (otherwise they pass vacuously).
- **D-12:** `git mv lib/threadline/operator_surface/exports/filter_params.ex lib/threadline/query/filter_params.ex` → `Threadline.Query.FilterParams` (not `Export.*` — timeline/start pages use it for non-export navigation). Update `export/orchestrator.ex` + the 4 operator-surface callers (timeline_live, start_live, export_status_live, export_controller). Same commit updates `test/threadline/operator_surface/exports_doc_contract_test.exs` `@filter_params_path` (:10) and the module-name assertion (:157-158).
- **D-13:** A whole-module `git mv` + rename is **not** extraction under the 204 rule. Do not inline, split, or dependency-invert either module.
- **D-14:** `lib/mix/tasks/critic.synth.ex` stays put: Mix tasks are not in the four GATE-03 layers, it is already excluded from the Hex package and pinned in `test/threadline/release_artifact_contract_test.exs:153-165`. It gets an explicit, existence-checked allowlist entry in the GATE-03 test. Do not delete (critic retirement is a separate decision).
- **D-15:** Enforcement: new ExUnit source-scan contract test (e.g. `test/threadline/layer_boundary_contract_test.exs`) — every `lib/**/*.ex` outside `lib/threadline/operator_surface.ex`, `lib/threadline/operator_surface/**`, and `lib/mix/tasks/critic.*` must not contain `OperatorSurface`. Assert allowlisted paths exist and the scan set is non-empty. No `boundary` dep, no custom Credo check.
- **D-16:** Layer-inversion plan runs **before** the AliasUsage plan, so lib/ alias fixes don't alias over the inversions.

### Capture↔Semantics cycle (GATE-04)
- **D-17:** Delete the `@compile {:no_warn_undefined, Threadline.Semantics.AuditAction}` at `lib/threadline/capture/audit_transaction.ex:59`; **keep** `belongs_to :action` and `AuditAction`'s `has_many :transactions`. Evidence: the line arrived in 20789c34 alongside `AuditAction` itself and suppresses nothing (scratch compile with `--warnings-as-errors` on 1.17.3: 0 warnings). The `:action` association is load-bearing public API (`query.ex:109` preload, `investigation.ex:231`, transaction_live/timeline_live pattern matches, investigation tests, moduledoc + guides). — **Reversibility:** reversible.
- **D-18:** GATE-04 "cycle resolved" is interpreted as **zero compile-connected cycles + zero `no_warn_undefined` papering**. The remaining runtime xref edge is the ordinary bidirectional Ecto association shape (same as AuditTransaction↔AuditChange, which is not a defect). Removing the runtime edge would break public API (`Repo.preload(tx, :action)`) — explicitly rejected.
- **D-19:** Pin it with (a) `mix xref graph --format cycles --label compile-connected --fail-above 0` wired as a named verify step (exits 0 today; `--fail-above` exists in 1.15), and (b) a contract test failing on any `no_warn_undefined` in `lib/**/*.ex` **or** in `Mix.Project.config()[:elixirc_options]` (so it can't relocate). Confirm the Elixir 1.15 min lane compiles warnings-as-errors after deletion.

### GATE-05
- **D-20:** Fix stale file-location comments (known: `exports/filter_params.ex:121` — note it moves under D-12 — and `controllers/export_controller.ex:361`; sweep `lib/` for others). Give the missing modules a deliberate `@moduledoc` or `@moduledoc false`. Mechanical; rides with the non-alias mechanical plan.

### Plan shape (planner may adjust count, not order constraints)
- **D-21:** Recommended 5 plans:
  1. GATE-03 + GATE-04 — the two `git mv`s with their pins (one file per commit), `@compile` deletion, layer-boundary + no_warn_undefined contract tests, xref cycle step.
  2. Mechanical, alias-driven — all 356 AliasUsage + resulting AliasOrder.
  3. Mechanical, other — the remaining 82 incl. Logger-metadata and SpecWithStruct decisions, plus GATE-05.
  4. Structural filing — 46 per-site disables with Phase 204 lines, register + ceiling contract test.
  5. Config rebuild — verbatim `.credo.exs` + deltas, config-shape contract test, `mix verify.credo` in `ci.all` green; dialyzer re-confirmed at 0; mirror register counts into ROADMAP Phase 204 notes.
  Plan 5 is where the gate goes live; before it, measure with `--config-file` against the verbatim config.

### Post-research resolutions (2026-09-22 — advisor fan-out after 203-RESEARCH.md; these AMEND the decisions they name)
- **D-22 (amends D-02):** "Verbatim" = copy `deps/credo/.credo.exs` scaffolding (top of file through the `checks:` key, comments kept) exactly, change only `strict: true`, and **replace** upstream's `checks: %{enabled: [...], disabled: [...]}` with `checks: %{extra: [...], disabled: []}`. Upstream's own `enabled:` list is exactly the replacing form GATE-01 forbids, so it is not copied. Header comment cites the source: `# Scaffolding copied from credo <vsn> deps/credo/.credo.exs; checks are deltas over Credo's embedded defaults — do not add enabled:`. — **Reversibility:** reversible.
- **D-23 (amends D-06):** `disabled: []` — **empty, not upstream's opt-in list copied.** Credo's merge forces every `disabled:` entry off even after a Credo release promotes it to default (probe-proven; e.g. `UtcNowTruncate` "scheduled for next check update"), so a copied list is itself a silent-drop vector. D-06's intent (no opt-in check enabled, TYPES-01) is enforced by assertion instead: the contract test evaluates `deps/credo/.credo.exs` at test time and fails if any `extra:` module is in upstream's `disabled:` list or absent from upstream's `enabled:` list (extras may only re-parameterize default checks, never add checks).
- **D-24 (resolves D-04/D-09/GATE-05 deltas):** The pinned `extra:` delta set is exactly three entries: (1) `Design.TagTODO [exit_status: 0]`; (2) `Readability.ModuleDoc` with `ignore_names: []` and `ignore_modules_using: []` cleared (a Hex library's LiveViews/controllers appear in hexdocs; closes the blind spot that let ActorLive/TransactionLive slip; adds exactly 1 finding, `test/support/repo.ex` → `@moduledoc false`) — this is GATE-05's Credo-native "every module has a deliberate moduledoc" gate; (3) `Warning.MissedMetadataKeyInLoggerConfig [metadata_keys: [...]]` listing the keys used at `lib/threadline/retention.ex` (research: `:deleted_changes, :deleted_transactions, :batch, :total_changes, :total_transactions` — re-verify). **D-09's Logger decision = the check's `metadata_keys:` param, NOT Logger config** (the CI `verify-credo` job runs in dev while `ci.all` runs in test, so env config would pass locally and fail in CI; and a library must not prescribe host Logger config). AliasUsage gets **no** delta (confirms D-03; an `extra:` entry would also silently drop upstream's `priority: :low, if_nested_deeper_than: 2` params). Because an `extra:` entry replaces that check's params wholesale, each entry must restate any upstream params it needs.
- **D-25 (strict):** `strict: true` in `.credo.exs` **and** keep `"verify.credo": ["credo --strict"]`, so bare `mix credo` shows exactly what CI enforces (upstream sets AliasUsage `priority: :low`, which non-strict runs hide).
- **D-26 (config contract test assertions, extends D-08(1)):** `credo_config_contract_test.exs` asserts: no `:enabled` key; `checks` keys ⊆ `[:extra, :disabled]`; `disabled == []` (message cites GATE-01); `extra` modules == pinned `@deltas`; every `extra` module ∈ upstream `enabled:` and ∉ upstream `disabled:` (read from `deps/credo/.credo.exs` at test time); every `extra` param key ∈ `Mod.param_names()`; header-cited Credo version == `Application.spec(:credo, :vsn)` (a Credo bump fails with "re-diff the scaffolding and bump the header"); upstream embedded `enabled:` count ≥ `@min_default_checks 69` (lower bound only, not a full snapshot); `strict: true`; `verify.credo` alias string pinned.
  - **D-26 interpretation note (2026-09-22, plan-check iteration 1):** "every `extra` param key ∈ `Mod.param_names()`" is read as "∈ `Mod.param_names()` ∪ Credo's builtin params". Measured: `TagTODO.param_names() == [:include_doc]`; `exit_status` is a builtin param every check accepts (`Credo.Check.Params.builtin_param_names/0` in credo 1.7.18: `category, exit_status, files, priority, tags` + `__`-prefixed forms), so the literal D-26 check could never pass alongside D-04/D-24's `[exit_status: 0]`. The contract test pins `@credo_builtin_params [:category, :exit_status, :files, :priority, :tags]` and accepts a delta key iff it is in `Mod.param_names() ++ @credo_builtin_params`; it also asserts that pinned list ⊆ `Credo.Check.Params.builtin_param_names()` so a Credo change that drops one fails loudly. Unknown/misspelled keys still fail. — **Reversibility:** reversible.
- **D-27 (resolves Open Q2; amends D-07/D-08(4)):** The structural register's named successor is a **new requirement STRUCT-07** in Phase 204 (none of STRUCT-01..06 owns draining it; STRUCT-03 is lib-only and measures size, not structure). Wording to add to REQUIREMENTS.md: `- [ ] **STRUCT-07**: The Credo structural register (Refactor.Nesting and Refactor.CyclomaticComplexity per-site disables in lib/ and test/) is drained to zero and its ceiling pinned at 0, or each remaining site is re-registered with its exact count and a named successor beyond v1.41, with the ceiling lowered to match.` + traceability row `STRUCT-07 | Phase 204 | Pending` + ROADMAP Phase 204 requirements → `STRUCT-01..STRUCT-07` with a success criterion "the credo_config_contract_test structural ceiling is ratcheted from <final count> to 0, or every remaining site names a post-v1.41 successor (STRUCT-07)". Per-site form: `# Phase 204 (STRUCT-07): <why it needs extraction/splitting>` on its own line directly above `# credo:disable-for-next-line Credo.Check.Refactor.<Check>` (nothing after the check name). Register: `@register %{Nesting => {n, "Phase 204 / STRUCT-07"}, CyclomaticComplexity => {m, ...}}`, scanned count per check must **equal** the register exactly (not ≤ — a new site cannot hide in slack from in-place fixes), `@ceiling` == register total, and a literal `@historical_max 46` the ceiling may never exceed. Failure message: "fix it (prefer `with`/early return); adding a disable requires raising the register in review." Per-line disable (not for-this-file, not thresholds) is the honest form — it moves with the code and suppresses exactly one site.
- **D-31 (2026-09-23, maintainer decision during 203-08 execution; amends D-27 per-site form):** The per-site line above each `# credo:disable-for-next-line` is `# Structural debt: <why it needs extraction/splitting>` — no phase number and no requirement ID. D-27's `# Phase 204 (STRUCT-07): ` form collided with `release_artifact_contract_test.exs` (`:phase_prose` bans `Phase \d+` in packaged source; 22 of 30 lib sites are packaged), and a `STRUCT-07` tag would leak a planning requirement ID into the Hex package, contrary to that contract's intent. The named successor `Phase 204 / STRUCT-07` lives only in the test-resident `@register` in `credo_config_contract_test.exs` (not packaged). Applied uniformly to lib/ and test/ so Plan 09's adjacency contract checks one prefix. Rest of D-27 (STRUCT-07 requirement, exact-count register, ceiling, historical max) unchanged.
- **D-28 (resolves Open Q3; commit granularity + type):** Hybrid: **one commit per `*_contract_test.exs` file and one per `lib/` file**; non-contract test files are batched **by directory**. AliasUsage and the AliasOrder it causes land in the **same** per-file commit (never split by check). Type is `refactor` (never `fix` — releasable, would pollute CHANGELOG via release-please; `style` is reserved for `mix format`). Templates: `refactor(203-NN): alias repeated module references in <path>` / `refactor(203-NN): resolve <Check> findings in <dir-or-file>`, body: "Mechanical Credo sweep: <checks>. No behavior change. Verified: <commands>." Keep mechanical commits pure (no semantic edits mixed in) so they are `.git-blame-ignore-revs`-eligible later.
- **D-29 (carried-note corrections, amends D-20/D-14 citations):** Research re-verified the carried notes against the live tree: the stale line-range comments are `lib/threadline/operator_surface/live/timeline_live.ex:34` ("auth.ex:21-27") and `lib/threadline/operator_surface/controllers/export_controller.ex:349` ("timeline_live.ex:366-373") — there is **no** stale comment at `filter_params.ex:121`; `critic.synth.ex` references the operator surface at **:8**; the "3 missing `@moduledoc`" were already fixed in Phase 200 (bf42de71) — the only moduledoc work is `test/support/repo.ex` surfaced by D-24(2). Plans must cite live line numbers re-measured at execution time, never these.
- **D-30 (pins missed by D-11/D-12):** The Scope/FilterParams renames must also update `test/threadline/public_surface_contract_test.exs:639,641`, `filter_params_test.exs:1,5,146` (git mv to `test/threadline/query/`), and `test/threadline/operator_surface/export_controller_test.exs:436`; the `exports_doc_contract_test.exs` `String.to_atom` guard must be **repointed**, not dropped. `SpecWithStruct` fix requires adding `@type t` to `AuditChange`, `AuditTransaction`, `ActorRef` (precedent `retention/policy.ex:15-20`) and covers `change_diff.ex:84` and `sigra.ex:18,58` too.

### Claude's Discretion
- Exact names of new contract test files; exact `as:` alias names; whether individual Nesting sites flatten in place (only if no function split/extract).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & rules
- `.planning/ROADMAP.md` §"Phase 203: Real Gates" (~line 715) — goal, success criteria, carried notes, hard 204 rule
- `.planning/ROADMAP.md` ~line 43 — pre-committed sizing rule; cross-cutting invariants (~line 55)
- `.planning/REQUIREMENTS.md` — GATE-01..05 (lines 76-80); DECOUPLE-07/08 note (line 134)

### Measurements
- `.planning/audits/198-credo-histogram.md` — 198-01 baseline histogram (377; superseded by D-00 count)
- `.planning/audits/198-credo-full-default.json` — 198-01 raw JSON
- `.planning/phases/198-green-bringup/198-01-SUMMARY.md` — how the out-of-repo full-default measurement was taken

### Credo internals
- `deps/credo/.credo.exs` — verbatim source for the rebuilt config
- `deps/credo/lib/credo/check/params.ex` — per-check `:files` support
- `deps/credo/lib/credo/check/config_comment.ex` — disable-comment parsing (trailing text = params)

### Precedents
- `test/threadline/dialyzer_ignore_contract_test.exs` — ceiling/ratchet contract-test pattern to mirror
- `test/threadline/public_surface_contract_test.exs:528` — source-scan pattern (`Path.wildcard("lib/**/*.ex")`)
- `test/threadline/release_artifact_contract_test.exs:153-165` — maintainer-only path allowlist incl. `lib/mix/tasks/critic.`

### Sites
- `lib/threadline/query.ex:35,731`; `lib/threadline/export/orchestrator.ex:11,293`; `lib/mix/tasks/critic.synth.ex:8`
- `lib/threadline/operator_surface/scope.ex`; `lib/threadline/operator_surface/exports/filter_params.ex`
- `lib/threadline/capture/audit_transaction.ex:59-60`; `lib/threadline/semantics/audit_action.ex:47`
- `test/threadline/code_walkthrough_doc_contract_test.exs:80`; `test/threadline/how_threadline_works_doc_contract_test.exs:78`; `test/threadline/operator_surface/exports_doc_contract_test.exs:10,157-158`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Dialyzer ceiling contract test — direct template for the Credo register/ceiling test.
- `mix verify.credo` / `mix ci.all` aliases already exist in `mix.exs` — wire, don't invent.

### Established Patterns
- Invariants are enforced by ExUnit source-scan contract tests, not xref/boundary tooling.
- `git mv` for every move; one file per commit where contract tests are involved.
- Gates must not read `.planning/` (DECOUPLE-01).
- `.planning/` must never be `git add`ed wholesale — stage explicit paths only.

### Integration Points
- `.credo.exs` (currently a 2-check `enabled:` list — the vacuous gate).
- `mix.exs` aliases (`verify.credo`, `ci.all`) and CI `verify-*` jobs.
- Elixir 1.15 min lane (warnings-as-errors) must stay green.

</code_context>

<specifics>
## Specific Ideas

- "A counted, documented exclusion is honest. A config that runs 2 checks in 0.1s and calls itself a gate is not." — the bar for every delta.
- Scope was already the DI point (`scope_query_fn`); FilterParams is a URL→Query filter codec. Both are misfiled query concepts, not surface concepts.

</specifics>

<deferred>
## Deferred Ideas

- 46 structural findings (Nesting/CyclomaticComplexity) → Phase 204, ratcheted via the ceiling test.
- Possible `max_nesting: 3` tuning → a Phase 204 decision, not here.
- `boundary` library adoption for compile-time layer enforcement → Phase 204 or later, if layer rules grow beyond one forbidden namespace.
- Removing the runtime Capture↔Semantics association edge → only in a milestone that allows breaking public API.
- Retiring `critic.synth` / critic tooling → separate decision.
- Opt-in Credo checks (`Readability.Specs`) → TYPES-01.

</deferred>

---

*Phase: 203-real-gates*
*Context gathered: 2026-09-22*
