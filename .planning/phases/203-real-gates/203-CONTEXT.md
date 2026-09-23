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
