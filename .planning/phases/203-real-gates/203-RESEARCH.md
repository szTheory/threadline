# Phase 203: Real Gates - Research

**Researched:** 2026-09-22
**Domain:** Elixir static-analysis gates (Credo 1.7.18 config semantics, Dialyxir 1.4.8, `mix xref`), layer-boundary refactor, ExUnit source-scan contract tests
**Confidence:** HIGH. Every count and mechanism below was re-measured or read against the live tree this session. Scratch configs lived in `/tmp/p203/`, and `.credo.exs` was never touched.

## Summary

The live tree matches CONTEXT D-00 exactly. Running Credo's full default set with `--strict` gives **484 findings**: AliasUsage 356 (lib 24 / test 332), 82 mechanical, and 46 structural (30 `Refactor.Nesting` + 16 `Refactor.CyclomaticComplexity`). The 356 AliasUsage findings reduce to **91 distinct (file, module) pairs across 56 files**. Under the pre-committed sizing rule (ROADMAP.md:43-51), 484 falls in the **150-600 band**, so the prescribed shape is "split mechanical from judgment", which D-01 confirms. The Dialyzer backlog is **already 0**: `.dialyzer_ignore.exs` is `[]` and `mix dialyzer --no-check` reports `Total errors: 0`. The compile-connected xref cycle count is **0** today. The `@compile {:no_warn_undefined, ...}` line can be deleted with zero warnings on 1.17.3, and a scratch `mix compile --force --warnings-as-errors` proved it.

Three findings change or sharpen the locked plan. **(1)** D-02 says "copy `deps/credo/.credo.exs` verbatim" and also "no `enabled:` key". That upstream file *is* an `enabled:` list (line 68). The only shape that satisfies both is to copy the scaffolding verbatim (files, plugins, requires, parse_timeout, color) and replace `checks:` with `%{extra: [...], disabled: [...]}`. I proved this shape reproduces all 484 findings and all 69 default checks. **(2)** Keeping the upstream opt-in list inside the project's `disabled:` (the literal reading of D-06) is a measured hazard. Credo merges every `disabled:` entry as `{check, false}` *over* its embedded defaults. A `disabled:` entry for a default check suppressed it completely in a scratch run (exit 0, no output). So when Credo promotes `Refactor.UtcNowTruncate` (upstream line 168 labels it "Checks scheduled for next check update"), a copied list would silently keep it off. That is exactly the failure GATE-01 exists to prevent. **(3)** Credo's `ModuleDoc` ignores `*Live`, `*Controller`, `Router`, and `Ecto.Schema` users by default. That is why ActorLive and TransactionLive slipped through before Phase 200. A single `extra:` delta that clears those ignore lists makes Credo enforce GATE-05's moduledoc half. Measured: it produces exactly **1** new finding (`test/support/repo.ex`, `Threadline.Test.Repo`).

Several carried notes are stale. `critic.synth.ex` references the operator surface at **:8**, not :30. `filter_params.ex:121` no longer holds a stale comment; the two real stale line-range comments are `timeline_live.ex:34` (`auth.ex:21-27`) and `export_controller.ex:349` (`timeline_live.ex:366-373`). The "three modules missing `@moduledoc`" are **already fixed**: an AST scan of all 110 lib `defmodule`s finds 0 missing, and Phase 200 commit bf42de71 fixed ActorLive/TransactionLive. The FilterParams/Scope move also has **more pins than CONTEXT lists**: `public_surface_contract_test.exs:639,641`, `filter_params_test.exs:1,5,146`, and `export_controller_test.exs:436`.

**Primary recommendation:** Follow D-21's five plans in strict serial order, with no parallel waves. The file overlap between the alias, mechanical, and structural sets is heavy, and the structural disables must be placed against *final* line numbers. Write `.credo.exs` as verbatim scaffolding plus `checks: %{extra: [TagTODO exit 0, ModuleDoc ignore-lists cleared, MissedMetadataKey metadata_keys], disabled: []}`, and lock it with a contract test.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- 46 structural findings (Nesting/CyclomaticComplexity) → Phase 204, ratcheted via the ceiling test.
- Possible `max_nesting: 3` tuning → a Phase 204 decision, not here.
- `boundary` library adoption for compile-time layer enforcement → Phase 204 or later, if layer rules grow beyond one forbidden namespace.
- Removing the runtime Capture↔Semantics association edge → only in a milestone that allows breaking public API.
- Retiring `critic.synth` / critic tooling → separate decision.
- Opt-in Credo checks (`Readability.Specs`) → TYPES-01.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GATE-01 | `mix credo --strict` runs Credo's full default check set, with project adjustments expressed as deltas | §Credo config semantics: the `extra:`/`disabled:` merge reproduces all 69 default checks and all 484 findings. The verbatim file contains `enabled:`, so "verbatim" must mean the scaffolding only. The upstream `disabled:` list is a future-suppression hazard (Open Q1). `mix credo info --strict --verbose --format json` gives a machine-checkable effective-set count |
| GATE-02 | Every finding fixed or registered with exact count + named successor | Full per-site list below (Appendix A). Disable-comment grammar verified in `config_comment_finder.ex:53`. Register-test template: `dialyzer_ignore_contract_test.exs`. Successor naming gap flagged (Open Q2) |
| GATE-03 | No capture/semantics/query/export module references the operator surface | Live grep shows exactly 3 references (`query.ex:35`, `export/orchestrator.ex:11`, `critic.synth.ex:8`). Full pin inventory for both `git mv`s is below and is larger than CONTEXT lists |
| GATE-04 | Capture↔Semantics cycle resolved, suppression removed not relocated | The suppression is the only `no_warn_undefined` in `lib/`, `mix.exs`, `config/`, `test/`. Deleting it compiles clean with `--warnings-as-errors` (scratch, 1.17.3). Compile-connected cycles = 0 before and after. `--fail-above`/`compile-connected` exist in Elixir 1.15 docs |
| GATE-05 | No comment cites a moved file location; every module has deliberate `@moduledoc`/`false` | Sweep found 2 stale line-range comments (not the ones in the notes). Moduledoc gap is already 0 in `lib/`. Credo's ModuleDoc `ignore_names` blind spot, plus a measured 1-finding delta to close it |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use the canonical `mix verify.*` / `mix ci.*` entrypoints; cite them verbatim in CI and docs. Wire into the existing `verify.credo` (`mix.exs:125`) and `ci.all` (`mix.exs:184`). Do not invent parallel entrypoints except the xref step D-19 requires.
- **Stable CI job IDs:** never rename `verify-credo`, `verify-test`, etc. (`ci.yml`). Adding *steps* inside a job is fine. `ci_workflow_parity_contract_test.exs:16` asserts `^  verify-credo:` exists.
- Honest default tests: do not silently exclude suites from `mix test`.
- Doc contract tests keep README/guides/example aligned. The renames touch doc-contract refute lists.
- Keep the three-layer architecture (capture / semantics / exploration). GATE-03 enforces part of it.
- `mix compile --warnings-as-errors` must stay green, including the Elixir 1.15 / OTP 26 min lane (`ci.yml:288-299`).
- **GSD:** `state.begin-phase` needs flags (`--phase 203 --name ... --plans N`) with gsd-core v1.14.0. Hand-check `STATE.md`/`ROADMAP.md` after `state.*` handlers. **Never `git add .planning/` wholesale**; stage explicit paths only.
- Cross-cutting milestone invariants (ROADMAP.md:55-64): no operator-UI design/visual change; `git mv` for every move; `git rm` for removals; one file per commit where contract tests are involved; no Elixir/OTP floor bump; no capture/query/auth semantic change.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lint policy (`.credo.exs`, `verify.credo`) | Build/CI tooling | ExUnit contract test | The config is the policy; the contract test prevents config-shape drift (DECOUPLE-01: gates read source, never `.planning/`) |
| Tenant scope hook (`Scope.apply/2`) | Query layer (`Threadline.Query.Scope`) | Operator surface (supplies `:scope_query_fn`) | It is invoked only by `Query.maybe_apply_scope/2` (`query.ex:731`). The operator surface injects the function; it does not own the mechanism |
| URL→filter codec (`FilterParams`) | Query layer (`Threadline.Query.FilterParams`) | Export orchestrator, 4 LiveViews/controllers | Consumed by `export/orchestrator.ex:293` and by non-export navigation (timeline/start). It is a query-filter concept |
| Capture↔Semantics association | Capture schema (`belongs_to :action`) | Semantics schema (`has_many :transactions`) | Runtime-only bidirectional Ecto association, the same shape as AuditTransaction↔AuditChange |
| Layer-boundary enforcement | ExUnit source-scan contract test | — | Established repo pattern (`public_surface_contract_test.exs` source scans). `boundary` dep is deferred |
| Structural-debt register | ExUnit contract test (ceiling) | ROADMAP Phase 204 notes (human mirror only) | Must live in source per DECOUPLE-01 |

## Standard Stack

No new packages. Everything used is already locked in `mix.lock`.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| credo | 1.7.18 [VERIFIED: mix.lock `"credo": {:hex, :credo, "1.7.18", ...}`] | Lint gate | Already the dep; `{:credo, "~> 1.7", only: [:dev, :test], runtime: false}` (`mix.exs:103`) |
| dialyxir | 1.4.8 [VERIFIED: mix.lock] | Dialyzer gate (verify-only here) | Already wired as `verify.dialyzer` (`mix.exs:126`, `["dialyzer --no-check"]`) |
| mix xref (Elixir stdlib) | Elixir 1.17.3 local / 1.15 min lane | Compile-connected cycle gate | `--format cycles`, `--label compile-connected`, `--fail-above` are all documented in 1.15 [CITED: mix.hexdocs.pm/1.15.0/Mix.Tasks.Xref.html] |
| ExUnit | stdlib | Contract tests | Repo convention |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ExUnit source-scan for GATE-03 | `boundary` lib / custom Credo check | Deferred by CONTEXT (D-15). Do not add |
| Contract-test moduledoc scan for GATE-05 | Credo `ModuleDoc` delta `[ignore_names: [], ignore_modules_using: []]` | Credo-native, measured at 1 finding. **Recommended** as the enforcement, optionally backed by a scan (see Pattern 4) |

**Installation:** none.

## Package Legitimacy Audit

Not applicable. This phase installs no external packages; credo 1.7.18 and dialyxir 1.4.8 are already locked. **Packages removed:** none. **Packages flagged:** none.

## Credo Config Semantics (the core of GATE-01)

### How Credo merges configs [VERIFIED: deps/credo/lib/credo/config_file.ex, deps/credo/lib/credo/execution/task/append_default_config.ex:8-13]

- Credo always appends its **own embedded** `.credo.exs` as the base: `@default_config_file_content File.read!(@default_config_filename)` (append_default_config.ex:9). It then merges the user's config on top. `--config-file X` replaces the *project* `.credo.exs` but still merges onto the embedded default.
- `config_file.ex:376-386`: if the user config has `checks: %{enabled: list}`, **that list replaces the base entirely.** This is today's vacuous 2-check gate.
- `config_file.ex:388-399` (quoted verbatim):
  ```elixir
  def merge_checks(%__MODULE__{checks: %{enabled: checks_base}}, %__MODULE__{
        checks: %{} = checks_other
      })
      when is_list(checks_base) do
    base = normalize_check_tuples(checks_base)
    other = normalize_check_tuples(checks_other[:extra])
    disabled = disable_check_tuples(checks_other[:disabled])

    %{
      enabled: base |> Keyword.merge(other) |> Keyword.merge(disabled),
      disabled: checks_other[:disabled] || []
    }
  end
  ```
  So `extra:` entries **replace** the base params for the same check (Keyword.merge by module key), and **every `disabled:` entry is forced to `false` over the base**, including checks the base enables.
- Credo also merges `.credo.exs` from every parent directory and each `./config` subdir (`relevant_directories/1`). I checked `/Users/jon/.credo.exs`, `/Users/jon/projects/.credo.exs`, and `config/.credo.exs`: none exist.

### Empirical proofs run this session (scratch configs in `/tmp/p203/`)

| Probe | Config | Result |
|-------|--------|--------|
| D-04: does `extra:` override a default check's params? | `checks: %{extra: [{Credo.Check.Design.TagTODO, [exit_status: 0]}], disabled: []}` on a file containing `# TODO:` | Finding still printed, **exit 0** (base config: exit 2). **D-04 verified.** `mix credo info` shows `('Design.TagTODO', {'exit_status': 0})` |
| Does `disabled:` suppress a *default* check? | `checks: %{disabled: [{Credo.Check.Design.TagTODO, []}]}` | **No output, exit 0.** The check was fully suppressed |
| Does the delta shape reproduce full defaults? | verbatim `files:` + `checks: %{extra: [TagTODO exit 0], disabled: []}` over `lib/`+`test/` | **484 findings, exit 30.** Identical to `--config-file deps/credo/.credo.exs` |
| Effective check set | `mix credo info --strict --verbose --format json --config-file <X>` | **69 checks** for both verbatim and delta configs. Equals the 69 entries in upstream `enabled:` (lines 68-165). The current repo config yields **2** |
| ModuleDoc blind-spot delta | add `{Credo.Check.Readability.ModuleDoc, [ignore_names: [], ignore_modules_using: []]}` to `extra:` | **485 = 484 + 1**: `test/support/repo.ex:1 Threadline.Test.Repo` |
| Runtime | full default vs current | 1.15 s vs 0.49 s wall. The `verify-credo` job's `timeout-minutes: 10` is ample |

### Recommended `.credo.exs` shape (Plan 5)

Verbatim upstream scaffolding (`deps/credo/.credo.exs` lines 1-66, comments included), with these changes:

```elixir
      strict: true,   # delta vs upstream `strict: false` (deps/credo/.credo.exs:49) — bare `mix credo` == gate
      ...
      checks: %{
        extra: [
          # TODO stays advisory, FIXME stays blocking (D-04; verified: extra: overrides params)
          {Credo.Check.Design.TagTODO, [exit_status: 0]},
          # GATE-05: upstream ignore_names skips *Live/*Controller/Router/Repo/Ecto.Schema users
          {Credo.Check.Readability.ModuleDoc, [ignore_names: [], ignore_modules_using: []]},
          # D-09 Logger decision (see Pitfall 3) — env-independent
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig,
           [metadata_keys: [:deleted_changes, :deleted_transactions, :batch, :total_changes, :total_transactions]]}
        ],
        disabled: []   # see Open Question 1 — recommended empty
      }
```

`strict: true` is already the repo's current value (current `.credo.exs` line 5). The five Logger metadata keys are quoted from `lib/threadline/retention.ex:180-186`: `deleted_changes: n1, deleted_transactions: n2, batch: idx, total_changes: tc, total_transactions: tt`. The ModuleDoc and Logger deltas are recommendations beyond D-08's pinned list; the planner must add them to the pinned delta list if adopted.

## Architecture Patterns

### System Architecture Diagram (gate data flow after Phase 203)

```
 developer / CI push
        │
        ▼
 mix ci.all (MIX_ENV=test)  ─────────────────────────────┐   GitHub Actions (job IDs frozen)
   verify.format                                         │     verify-credo  ─► mix verify.credo  (MIX_ENV=dev!)
   verify.credo ──► Credo: embedded defaults (69 checks) │     verify-test[min|current]
                    ⊕ .credo.exs extra:/disabled: deltas │        compile --warnings-as-errors
                    ⊕ per-site credo:disable comments ───┼──►     + NEW step: xref cycles --fail-above 0
                    → exit 0 only if 0 unsuppressed      │        mix verify.test ─► ExUnit contract tests:
   compile --warnings-as-errors                          │            credo_config_contract (shape + register ceiling)
   NEW verify.xref_cycles (compile-connected, fail>0)    │            layer_boundary_contract (no OperatorSurface)
   verify.compile_no_optional                            │            no_warn_undefined contract
   verify.test ─► contract tests (as right)              │     verify-dialyzer ─► mix verify.dialyzer (0 errors)
   ... verify.dialyzer (dev) ... browser lane            │     ci-required ◄─ needs all 14 jobs (unchanged)
```

### Plan ordering and parallelism (verified overlap)

Measured file overlap between the fix groups: alias∩mechanical = 7 files, alias∩structural = 5, mechanical∩structural = 15. Heavily shared files include `query.ex`, `timeline_live.ex`, `filter_params.ex`, `mechanical_checker.ex`, `export_controller.ex`, and `release_artifact_contract_test.exs`. **All five plans must be serial waves.** Plan 4 must re-measure line numbers *after* Plans 2-3, because alias insertion shifts every reported line. Memory also notes that worktrees have no `deps/`/`_build`, so no Elixir suite can run there. Executors need the main checkout, or must re-record the dispatch sentinel as `none`.

### Pattern 1: Whole-module `git mv` + rename with all pins in one commit
**What:** A module rename changes the module name that callers compile against, so the mv, callers, and pins must land together or the tree won't compile. This is the one place "one file per commit" cannot be literal; D-11/D-12 already say "same commit".

**Pin inventory for `Threadline.OperatorSurface.Scope` → `Threadline.Query.Scope`** [VERIFIED: grep + Read this session]:
- `lib/threadline/operator_surface/scope.ex:1`: `defmodule Threadline.OperatorSurface.Scope do` (git mv to `lib/threadline/query/scope.ex`; the `lib/threadline/query/` dir already exists and holds `actor_history_page.ex`)
- `lib/threadline/query.ex:35`: `alias Threadline.OperatorSurface.Scope, as: OperatorScope`. Use at `:731`: `OperatorScope.apply(query, opts)`. Rename the alias (e.g. `alias Threadline.Query.Scope`). **`Scope.apply/2` must stay byte-identical**; it is the tenant-scoping enforcement point (see Security)
- `test/threadline/code_walkthrough_doc_contract_test.exs:80`: `"Threadline.OperatorSurface.Scope",` (refute list)
- `test/threadline/how_threadline_works_doc_contract_test.exs:78`: `refute String.contains?(doc, "Threadline.OperatorSurface.Scope")`
- **Not in CONTEXT:** `test/threadline/public_surface_contract_test.exs:641`: `Threadline.OperatorSurface.Scope,` inside `modules_for_visibility_tag(:module_visibility_operator_helpers)` (lines 636-644). That test asserts `module in application_modules()` ("is absent from the compiled app"), so it **fails loudly** if not updated. Decide whether the renamed module stays under the `operator_helpers` tag or moves to `:module_visibility_domain_tail` (lines 613-620); either keeps the tag non-empty
- `CHANGELOG.md:105`: historical entry. **Do not edit** (history)

**Pin inventory for `Threadline.OperatorSurface.Exports.FilterParams` → `Threadline.Query.FilterParams`:**
- lib callers: `export/orchestrator.ex:11` (alias), `:293` (`FilterParams.parse`); `operator_surface/live/{timeline_live,start_live,export_status_live}.ex`; `operator_surface/controllers/export_controller.ex`
- `test/threadline/operator_surface/exports_doc_contract_test.exs:10`: `@filter_params_path "lib/threadline/operator_surface/exports/filter_params.ex"`. Used at :140, :192, :267 via `File.read!`, so a stale path **crashes** rather than passing vacuously. Also :157-158: `String.contains?(lv_src, "Threadline.OperatorSurface.Exports.FilterParams") or String.contains?(lv_src, "alias Threadline.OperatorSurface.Exports.FilterParams")`
- **Not in CONTEXT:** `test/threadline/operator_surface/exports/filter_params_test.exs:1` (`defmodule Threadline.OperatorSurface.Exports.FilterParamsTest`), `:5` (alias), `:146` (`File.read!("lib/threadline/operator_surface/exports/filter_params.ex")`). Recommend `git mv` to `test/threadline/query/filter_params_test.exs` with module `Threadline.Query.FilterParamsTest` (keeps `WrongTestFilename` happy)
- **Not in CONTEXT:** `test/threadline/operator_surface/controllers/export_controller_test.exs:436`: `Threadline.OperatorSurface.Exports.FilterParams.canonical_query(%{`
- **Not in CONTEXT:** `test/threadline/public_surface_contract_test.exs:639`: `Threadline.OperatorSurface.Exports.FilterParams,` (same visibility-tag concern)
- The file carries its own findings that move with it (line numbers unchanged by a pure rename): CC `:49`, CC `:141`, Nesting `:158`, RedundantWithClauseResult `:36`, PreferImplicitTry `:185`
- Ignored: `priv/ci/hex_evaluator/deps/...` copies are git-ignored (`.gitignore:49`). `mix.exs` `groups_for_modules` does not name either module.

### Pattern 2: Register/ceiling contract test (mirror `dialyzer_ignore_contract_test.exs`)
**What:** Throw-based `validate_contract/…` returning `:ok | {:error, msg}`, with `demand!/2` + `fail!/1` helpers. Pair a positive test on the real tree with negative tests on synthetic sources (broad forms rejected, over-ceiling rejected, missing adjacent comment rejected). The dialyzer test also asserts its own source never contains the literal planning directory name (`planning_directory = "." <> "planning"; refute File.read!(__ENV__.file) =~ planning_directory`). Copy that trick, because `planning_dependency_contract_test.exs` scans tracked tests for `.planning/...` file IO.

For Credo:
- Parse `.credo.exs` with `Code.string_to_quoted!/1` (never eval for the shape check) and assert no `:enabled` key under `checks:` anywhere in the AST.
- `Code.eval_file(".credo.exs")` to compare `extra:`/`disabled:` against a pinned `@deltas` exactly.
- Regex-scan `Path.wildcard("{lib,test}/**/*.{ex,exs}")` for `~r/#\s*credo:([\w\-:]+)\s*(.*)/i`. This is the **same regex Credo uses** (`config_comment_finder.ex:53`: `~r/#\s*credo\:([\w\-\:]+)\s*(.*)/im`), so the test sees exactly what Credo sees.
- Require the instruction to be `disable-for-next-line` and param in `{Credo.Check.Refactor.Nesting, Credo.Check.Refactor.CyclomaticComplexity}`.
- Require the immediately preceding line to match `~r/^\s*# Phase 204 \(STRUCT-\d\d\)/`.
- Per-check counts must equal the register and be `≤ @ceiling`.
- Optional: a slow-lane assertion that `System.cmd("mix", ["credo","info","--strict","--verbose","--format","json"])` reports ≥ 69 checks. Avoid it in the default suite, because a nested `mix` inside `mix test` is slow and env-sensitive; put the 69-check assertion in the plan's verification command instead.

### Pattern 3: Layer-boundary + no_warn_undefined source scans
```elixir
# test/threadline/layer_boundary_contract_test.exs (sketch)
@allow ["lib/threadline/operator_surface.ex", "lib/mix/tasks/critic.synth.ex", "lib/mix/tasks/critic.measure.ex"]
files = Path.wildcard("lib/**/*.ex")
        |> Enum.reject(&(String.starts_with?(&1, "lib/threadline/operator_surface/") or &1 in @allow))
assert files != []                               # vacuous-gate guard
for p <- @allow, do: assert File.regular?(p)     # allowlist existence
offenders = for f <- files, File.read!(f) =~ "OperatorSurface", do: f
assert offenders == []
```
Use a case-sensitive `OperatorSurface` substring. It catches aliases, multi-alias `{…}` forms, `Module.concat`, and `:"Elixir.…"` atoms. `critic.measure.ex` contains only lowercase `"test/fixtures/operator_surface"` strings, which are fine either way. For no_warn_undefined: scan `lib/**/*.ex` for `no_warn_undefined` **and** assert `Keyword.get(Mix.Project.config()[:elixirc_options] || [], :no_warn_undefined) == nil`. Today the only occurrence repo-wide is `lib/threadline/capture/audit_transaction.ex:59` [VERIFIED: grep of lib, mix.exs, test, config].

### Pattern 4: GATE-05 enforcement
- **Moduledoc:** the Credo ModuleDoc delta (measured: 1 finding, fixed by `@moduledoc false` in `test/support/repo.ex`). Upstream defaults (`deps/credo/lib/credo/check/readability/module_doc.ex:4-8`):
  `ignore_names: [~r/(\.\w+Controller|\.Endpoint|\.\w+Live(\.\w+)?|\.Repo|\.Router|\.\w+Socket|\.\w+View|\.\w+HTML|\.\w+JSON|\.Telemetry|\.Layouts|\.Mailer)$/]`, `ignore_modules_using: [Credo.Check, Ecto.Schema, Phoenix.LiveView, ~r/\.Web$/]`. ModuleDoc skips `.exs` files (`if Path.extname(filename) == ".exs" do []`), so test modules are unaffected.
- **Stale location comments:** fix the two sites, then add a cheap scan asserting no lib comment matches `~r/#.*\b[\w\/.-]+\.exs?:\d+/`. Symbol references (e.g. "see `TimelineLive.safe_validate/1`") don't rot.

### Anti-Patterns to Avoid
- **Copying upstream `enabled:` verbatim.** It re-creates the replace-not-merge vacuity for any check a future Credo adds.
- **Trailing text on a disable comment** (`# credo:disable-for-next-line Credo.Check.Refactor.Nesting — Phase 204`). The param becomes the atom `:"Elixir.Credo.Check.Refactor.Nesting — Phase 204"`, which never matches (`config_comment.ex` `value_for/1` → `String.to_atom("Elixir.#{param_string}")`). The suppression silently fails and the gate goes red.
- **Nameless `# credo:disable-for-next-line`.** `params_ignore_issue?([], _)` returns `true`, so it suppresses *every* check on that line. D-08(3) must reject it.
- **Placing a Nesting disable above the `def`.** It must sit directly above the *reported* line (`line_no_issue == line_no + 1`, config_comment.ex).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Effective-check introspection | a parser of Credo internals | `mix credo info --strict --verbose --format json` → `config.checks` | Stable CLI output; measured 69 |
| Disable-comment detection | your own grammar | Credo's regex `~r/#\s*credo\:([\w\-\:]+)\s*(.*)/im` | Guarantees test/Credo agreement |
| Cycle detection | a custom xref walker | `mix xref graph --format cycles --label compile-connected --fail-above 0` | Stdlib, in 1.15 |
| Moduledoc enforcement | a new scanner | Credo ModuleDoc with ignore lists cleared | Measured, one delta |
| Ratchet contract | new design | clone `dialyzer_ignore_contract_test.exs` structure | House precedent, reviewed |

## Runtime State Inventory (module-rename portion)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. `Scope` and `FilterParams` are pure functions. No DB rows, saved views, or export jobs store module names. `saved_views` store URL params (the FilterParams *input*), not the module | None |
| Live service config | None. No external service references these module names | None |
| OS-registered state | None | None |
| Secrets/env vars | None. `config/*.exs` does not name either module [VERIFIED: grep] | None |
| Build artifacts | `_build/{dev,test}/lib/threadline/ebin/Elixir.Threadline.OperatorSurface.Scope.beam` etc. go stale. Mix removes beams for deleted sources on recompile. The Dialyzer PLT cache may hold stale module info. Git-ignored `priv/ci/hex_evaluator/deps/threadline/` is a hex-published copy, irrelevant | `mix compile --force` once; if `verify.dialyzer` goes red, rebuild the PLT (`MIX_ENV=dev mix dialyzer --plt`, per memory note) |

## Common Pitfalls

### Pitfall 1: The upstream `disabled:` list suppresses future default checks
**What goes wrong:** Copying upstream lines 166-201 into the project's `disabled:` forces 35 checks to `false`. When Credo 1.8 promotes one (e.g. `Refactor.UtcNowTruncate`, listed under "Checks scheduled for next check update", line 167-169), this repo silently stays off. That is the exact failure GATE-01's wording forbids.
**How to avoid:** Use `disabled: []` and enforce "no opt-in enabled" by asserting none of the upstream opt-in modules appear in `extra:`. See Open Q1.
**Warning signs:** `mix credo info --strict --verbose --format json` count after a Credo bump is lower than the upstream default `enabled:` length.

### Pitfall 2: Structural disables placed against stale line numbers
**What goes wrong:** Plans 2-3 insert aliases, change `cond`→`if`, and so on, which shifts lines. Disables written from today's JSON land one or more lines off and suppress nothing (or the wrong thing).
**How to avoid:** Plan 4 re-runs `mix credo --strict --config-file deps/credo/.credo.exs --format json` **after** Plans 2-3 and places disables from that output. Then re-run and confirm 0 remaining structural findings.

### Pitfall 3: `MissedMetadataKeyInLoggerConfig` is environment-dependent
**What goes wrong:** The check reads `Application.get_env(:logger, :default_formatter)[:metadata]` at run time (`missed_metadata_key_in_logger_config.ex:128-131`). The `verify-credo` CI job runs under MIX_ENV=dev (no `preferred_cli_env` entry for `verify.credo`), while `ci.all` runs it under MIX_ENV=test. A test-env-only Logger config therefore turns `ci.all` green and the CI job red, or the reverse. Adding Logger config to `config/config.exs` also makes the library ship an opinion about host Logger config that hosts never load.
**How to avoid:** Use the check's `metadata_keys:` param in `.credo.exs` `extra:` (env-independent, pinned by the contract test). Record that decision in the plan per D-09.

### Pitfall 4: `SpecWithStruct` fixes need types that don't exist yet
**What goes wrong:** D-09 says "use `AuditChange.t()`/`AuditTransaction.t()`", but **neither schema defines `@type t`**, and neither does `Threadline.Semantics.ActorRef` [VERIFIED: grep `@type` in the three files returns only `actor_ref.ex:24 @types` attribute]. Two more sites exist beyond `Query`: `change_diff.ex:84` (`%AuditChange{}`) and `integrations/sigra.ex:18,58` (`%ActorRef{}`).
**How to avoid:** Add `@type t :: %__MODULE__{}` (with a `@typedoc`) to `AuditChange`, `AuditTransaction`, `ActorRef`. There is house precedent: `query/actor_history_page.ex:12`, `retention/policy.ex:16`. This is an additive public typespec that shows in HexDocs. Keep Dialyzer at 0 (`MIX_ENV=dev mix dialyzer --no-check`).

### Pitfall 5: `StringSigils` fix must preserve bytes
**What goes wrong:** `row_history_focus_evidence_contract_test.exs:41-42` builds a bash script with `\\0`, `\\\"` escapes and `#{@flag}` interpolation. Converting to `~S` disables both, which changes the generated script.
**How to avoid:** Use `~s` with a delimiter absent from the content (content contains `{}`, `'`, `[[`). Prove equality before/after in iex.

### Pitfall 6: Alias insertion in multi-module test files
**What goes wrong:** 15 of the 56 alias files define several top-level/sibling modules (e.g. `start_live_test.exs` defines `StartLiveTest.Auth`, `.Router`, `.Endpoint`, and `Live.StartLiveTest`). Aliases are lexically scoped, so each module needs its own `alias`. Aliasing `Threadline.OperatorSurface.StartLiveTest.Auth` as `Auth` can shadow `Threadline.OperatorSurface.Auth` elsewhere. Inside Phoenix `scope ..., Alias do` blocks, route targets get the scope prefix.
**How to avoid:** Use `as:` for any short name that already exists in the file (D-10). Keep function-capture options (`&Mod.fun/1`) outside route-target position. `mix compile --warnings-as-errors` plus the file's own tests are the backstop. No in-file short-name collisions exist among the 91 trigger pairs [measured].

### Pitfall 7: `mix test` needs Postgres on the right port
**What goes wrong:** `test/test_helper.exs` always calls `storage_up`. `config/test.exs:7` defaults `DB_PORT` to 5432, and locally **5432 is some other listener** (a playstead docker DB is running), while **5433 (threadline's compose) is not responding**.
**How to avoid:** `docker compose up -d` from the repo root, then `DB_PORT=5433 MIX_ENV=test mix test ...`. Never point tests at the foreign 5432.

### Pitfall 8: `ci.all` browser lane baseline
Per memory: the healthy local browser result includes 8 pre-existing screenshot failures (baselines from 180-04). Never regenerate baselines; a 9th failure or a changed hash is a real regression. Also per memory: a `ci.all` Dialyzer red can be a PLT cache miss (`mix dialyzer --plt`).

## Code Examples

### Disable comment with separate successor line (verified grammar)
```elixir
    # Phase 204 (STRUCT-03): flatten nested case — requires function split, filed per 203 hard rule
    # credo:disable-for-next-line Credo.Check.Refactor.Nesting
    case Storage.fetch(key) do
```
(Credo: `config_comment_finder.ex:53`, `config_comment.ex` `ignores_issue?` for `disable-for-next-line` requires `line_no_issue == line_no + 1`.)

### xref cycle step (verified exit 0 on current tree and on the scratch tree with `@compile` deleted)
```elixir
# mix.exs aliases
"verify.xref_cycles": ["xref graph --format cycles --label compile-connected --fail-above 0"],
```
CI: add a step to `verify-test` (both matrix lanes, so 1.15 proves it) after `Compile (warnings as errors)`: `run: mix verify.xref_cycles`. Job IDs stay unchanged. `ci_workflow_parity_contract_test.exs:37-60` asserts only presence and order of specific existing steps, so adding one is safe. Insert it in `ci.all` after `"compile --warnings-as-errors"`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `checks: [ {...} ]` list (merged as `extra`) / `checks: %{enabled: [...]}` (replaces) | `checks: %{extra: [...], disabled: [...]}` over embedded defaults | Credo 1.6+ `@valid_checks_keys ~w(enabled disabled extra)a` (config_file.ex:16) | Delta configs track upstream default additions automatically |

## Appendix A: Live finding inventory (full default, `--strict`, 2026-09-22)

**Totals:** 484 = AliasUsage 356 + mechanical 82 + structural 46. Distinct files: alias 56, mechanical 48, structural 35.

**Mechanical (82):** MapJoin 18 (lib 12 / test 6) · AliasOrder 11 (6/5, plus any created by alias insertion) · RedundantWithClauseResult 11 (10/1) · SpecWithStruct 8 (lib: `query.ex:65,106,106,117,649`, `change_diff.ex:84`, `integrations/sigra.ex:18,58`) · PreferImplicitTry 7 · ExpensiveEmptyEnumCheck 6 · NegatedConditionsWithElse 5 · StringSigils 4 (test) · CondStatements 3 (`timeline_live.ex:1079`, `query.ex:604,819`) · RejectReject 2 · FilterFilter 2 · ParenthesesOnZeroArityDefs 1 (`capture/trigger_sql.ex:22` `def install_function(), do: install_function([])`) · MaxLineLength 1 (`auth_test.exs:109`) · UnlessWithElse 1 · MissedMetadataKeyInLoggerConfig 1 (`retention.ex:181`) · WithSingleClause 1 (`policy/redaction_presenter.ex:250`).

**Structural: CyclomaticComplexity (16):** `critic.measure.ex:344`(13) · `threadline.export.ex:38`(13) · `change_diff.ex:111`(11) · `critic_trust/measure.ex:56`(18) · `evidence.ex:286`(10) · `export/orchestrator.ex:20`(12) · `filter_params.ex:49`(10), `:141`(16) · `export_status_live.ex:465`(11) · `stress_live.ex:1267`(10), `:1311`(13) · `presentation.ex:204`(17) · `router.ex:56`(12) · `query.ex:479`(13) · `retention/policy.ex:48`(33) · `test/support/getting_started_fixtures.ex:6`(24).

**Structural: Nesting (30; lib 19 / test 11):** lib: `threadline.install.ex:102`, `threadline.verify_coverage.ex:125`, `audit.ex:85`, `krippendorff_alpha.ex:44,138`, `rank_metrics.ex:34`, `export/cleanup_task.ex:63`, `operator_surface/auth.ex:127`, `export_controller.ex:38`, `filter_params.ex:158`, `actor_live.ex:46`, `export_status_live.ex:624`, `row_history_component.ex:153`, `timeline_live.ex:170`(depth 4), `:1014`, `transaction_live.ex:67`, `mechanical_checker.ex:642`, `redaction_presenter.ex:319`, `storage/local.ex:45`. test: `getting_started_fixtures.ex:33`, `dialyzer_ignore_contract_test.exs:452`, `guide_graph_contract_test.exs:223`, `card_nesting_regression_test.exs:188`, `operator_surface_fixture_contract_test.exs:184,223,257`, `rendered_output_contract_test.exs:440,632,648`, `release_artifact_contract_test.exs:423`(depth 4).

**AliasUsage top triggers:** `Threadline.Test.Repo` 83, `Threadline.Storage.Local` 58, `Ecto.Adapters.SQL` 28, `Threadline.Capture.TriggerSQL` 13, `…StartLiveTest.Auth` 13, `Mix.Tasks.Threadline.Health.Coverage` 12, `Threadline.Capture.AuditTransaction` 11, `Mix.Tasks.Critic.Measure` 11. Lib alias files (12): `threadline.incident.ex`, `continuity.ex`, `evidence/proof.ex`, `export/cleanup_task.ex`, `export_queue/oban.ex`, `export_queue/task_adapter.ex`, `health.ex`, `health/coverage_schemas.ex`, `operator_surface/auth.ex`, `timeline_live.ex`, `style.ex` (`Threadline.OperatorSurface.Fonts`), `retention/pruner.ex`. No test asserts fully-qualified source text for these lib names [VERIFIED: grep of the tests that read each file]. The dialyzer fixture JSONs cite historical lines but are not re-validated against source lines.

**Stale location comments (GATE-05) [VERIFIED: sweep of all file refs in lib comments]:**
- `lib/threadline/operator_surface/live/timeline_live.ex:34`: `# For :ok / true returns, the assign is absent. (auth.ex:21-27)`. auth.ex:21-27 is now the assign pipeline, and the comment is also semantically stale: auth.ex:34/45 assign `:threadline_scope` to `nil`, not absent.
- `lib/threadline/operator_surface/controllers/export_controller.ex:349`: `# ---- Filter validation (lifted from timeline_live.ex:366-373) ----`. The referent is now `timeline_live.ex:1370` `defp safe_validate`.
- All other path citations in lib comments resolve to existing files (priv/fonts, the e2e spec, style.ex, ui_form_policy_contract_test.exs, version_truth_doc_contract_test.exs, stress_fixtures_test.exs `@page_path_cases`, pager_test.exs, mechanical_checker_test.exs).
- Note: `filter_params.ex:121` (carried note) is **not** a comment today.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Deleting the `@compile {:no_warn_undefined, …}` compiles clean on Elixir 1.15/OTP 26 (verified only on 1.17.3; 1.15 not installed locally) | GATE-04 | Min-lane red. Mitigation: the CI min lane runs `compile --warnings-as-errors`, and no_warn_undefined only affects remote-call warnings, which `belongs_to` does not emit |
| A2 | Credo 1.8 will promote `UtcNowTruncate` (upstream comment says "scheduled for next check update") | Pitfall 1 | Low: the hazard is structural regardless of which check is promoted |
| A3 | Mix deletes stale beams for renamed modules on normal recompile | Runtime State | Stale-module test flakiness; mitigated by `mix compile --force` |
| A4 | `STRUCT-03` is the right successor ID for all 46 structural rows | Code Examples / Open Q2 | Register names a requirement that doesn't own the work |

## Open Questions

1. **Upstream opt-in list in `disabled:` (D-06 literal vs GATE-01 intent)**
   - What we know: `disabled:` forces checks off over defaults (proven empirically). The opt-ins are already off in the embedded base, so copying the list adds nothing today and can only subtract later.
   - Recommendation: `disabled: []`, and satisfy D-06's intent ("do not enable opt-ins") by having the contract test assert that `extra:` contains none of the upstream opt-in modules. The planner should record this as the D-06 interpretation (reversible).
2. **Which requirement owns the 46 structural rows in Phase 204?**
   - What we know: STRUCT-01..06 cover CSS hash, style split, file/function size, separator comments, case templates, and ci.all redundancy. None says "drain the Nesting/CyclomaticComplexity register", and 12 of the sites are in `test/`, which STRUCT-03 (`lib/` only) does not cover. GATE-02 also says "named successor **milestone**".
   - Recommendation: use `STRUCT-03` for lib sites. Have Plan 5's ROADMAP mirror add an explicit Phase 204 note/success line ("ratchet `credo_config_contract_test` ceiling to 0"). Flag the test-site ownership for the maintainer.
3. **Commit granularity for 56 alias files.** The "one file per commit wherever contract tests are involved" convention applies to many of them (`*_contract_test.exs`). Recommendation: one commit per contract-test file and per lib file; batch the remaining non-contract tests by directory.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / OTP (asdf) | everything | ✓ | 1.17.3-otp-27 / 27.3.4.15 (`.tool-versions`; untracked, per git status) | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27` prefix |
| Elixir 1.15 | min-lane proof | ✗ locally | (1.18.4, 1.19.x, 1.20.2 installed) | CI `verify-test (min)` lane |
| Credo | gate | ✓ | 1.7.18 | — |
| Dialyzer PLT | verify.dialyzer | ✓ | 0 errors, 1.8 s warm | `MIX_ENV=dev mix dialyzer --plt` on cache miss |
| PostgreSQL :5433 (threadline compose) | `mix test`, `ci.all` | ✗ (no response) | — | `docker compose up -d` from repo root. **Do not** use the foreign :5432 listener |
| Node/Playwright | `ci.all` browser lane | ✓ (nodejs 22.14.0 pinned) | — | Use `mix verify.example_browser`, never raw playwright |

**Blocking without action:** Postgres :5433. Executors must start compose before any `mix test`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (stdlib), contract-test convention `test/threadline/*_contract_test.exs` |
| Config file | `test/test_helper.exs` (always requires Postgres) |
| Quick run command | `DB_PORT=5433 MIX_ENV=test mix test test/threadline/credo_config_contract_test.exs test/threadline/layer_boundary_contract_test.exs` |
| Full suite command | `DB_PORT=5433 MIX_ENV=test mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GATE-01 | `.credo.exs` has no `enabled:`, deltas equal pinned list, effective set = 69 | contract + CLI | `mix test test/threadline/credo_config_contract_test.exs` ; `mix credo info --strict --verbose --format json \| jq '.config.checks\|length'` → 69 (all recommended `extra:` entries re-parameterize checks already in the default set, so the count stays 69) | ❌ Wave 0 |
| GATE-01/02 | gate is live and green | CLI | `mix verify.credo` exit 0 ; `mix credo --strict --config-file deps/credo/.credo.exs --format json` shows only register-suppressed categories remaining (i.e. 46 Nesting/CC under the delta config minus in-place flattens, and 0 under the project config) | ✅ alias exists |
| GATE-02 | register counts exact, ceiling non-increasing, only allowed disable form, adjacent Phase 204 line, non-empty scan | contract | `mix test test/threadline/credo_config_contract_test.exs` | ❌ Wave 0 |
| GATE-03 | no `OperatorSurface` outside allowlist; allowlist paths exist; scan non-empty | contract | `mix test test/threadline/layer_boundary_contract_test.exs` | ❌ Wave 0 |
| GATE-03 | renamed modules keep behaviour (tenant scope, filter codec) | existing unit/integration | `mix test test/threadline/query/filter_params_test.exs test/threadline/operator_surface/exports_doc_contract_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/public_surface_contract_test.exs` | ✅ (after mv) |
| GATE-04 | 0 compile-connected cycles; no `no_warn_undefined` in lib or elixirc_options | CLI + contract | `mix verify.xref_cycles` ; `mix compile --force --warnings-as-errors` ; contract test (fold into layer_boundary or own file) | ❌ Wave 0 |
| GATE-04 | `:action` preload still works | existing integration | `mix test test/threadline/investigation_test.exs` | ✅ |
| GATE-05 | every lib module has deliberate moduledoc; no `file.ex:NN` comments | Credo delta + contract | `mix verify.credo` (ModuleDoc delta) ; scan test | ❌ Wave 0 |
| (D-00b) | Dialyzer stays at 0 after SpecWithStruct/type additions | CLI | `MIX_ENV=dev mix dialyzer --no-check` → `Total errors: 0` | ✅ |

### Sampling Rate
- **Per task commit:** `mix compile --warnings-as-errors` plus the touched file's tests plus the relevant contract test.
- **Per plan:** `mix credo --strict --config-file deps/credo/.credo.exs --format json` re-measure (count must drop by exactly the plan's scope), `mix verify.format`.
- **Phase gate:** `DB_PORT=5433 MIX_ENV=test mix ci.all` green (browser lane at its known baseline), plus `MIX_ENV=dev mix dialyzer --no-check` = 0 and `mix verify.xref_cycles` exit 0.

### Wave 0 Gaps
- [ ] `test/threadline/credo_config_contract_test.exs`: GATE-01/02 (shape, pinned deltas, register, ceiling)
- [ ] `test/threadline/layer_boundary_contract_test.exs`: GATE-03 + GATE-04 no_warn_undefined scan (and optionally the GATE-05 stale-location scan)
- [ ] `mix.exs` alias `verify.xref_cycles` + `ci.all` entry + `verify-test` CI step
- Framework install: none.

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | **yes (indirect)** | `Scope.apply/2` is the tenant-scoping hook: it calls `scope_query_fn.(query, scope, context)` when both are set. The move must be byte-identical in body. Scoped-surface tests (`TimelineLiveScopedTest`, `TransactionLiveScopedTest`, `StartLiveScopedTest`) must stay green |
| V5 Input Validation | **yes (indirect)** | `FilterParams` is the URL-param allowlist, using compile-time atom literals and `String.to_existing_atom`. The `exports_doc_contract_test.exs:266` guard ("must NEVER call String.to_atom") reads via `@filter_params_path` and must be repointed, not dropped |
| V6 Cryptography | no | — |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tenant-scope bypass via a refactor that alters `Scope.apply/2` | Elevation of privilege | Pure `git mv` + module rename only (D-13); scoped LiveView tests |
| Atom-table exhaustion via a FilterParams edit | DoS | Keep the `String.to_existing_atom` guard test pointed at the new path |
| Silent lint suppression (nameless or broad `credo:disable`) | Tampering (of the gate) | D-08(3) rejects every non-register disable form |

## Sources

### Primary (HIGH confidence, read or executed this session)
- `deps/credo/.credo.exs` (lines 49, 68, 85-86, 92, 166-201); `deps/credo/lib/credo/config_file.ex` (16, 340-420); `deps/credo/lib/credo/execution/task/append_default_config.ex` (8-13); `deps/credo/lib/credo/check/config_comment.ex`; `config_comment_finder.ex:53`; `readability/module_doc.ex:4-8, 58-65`; `warning/missed_metadata_key_in_logger_config.ex:54-140`
- Live runs: full-default Credo JSON (484), delta-config reproduction (484), TagTODO override probe, disabled-suppression probe, ModuleDoc delta probe (485), `mix credo info` (69/69/2), `mix xref graph` cycles (0 compile-connected; 3 runtime cycles incl. AuditTransaction↔AuditAction), scratch compile with `@compile` deleted (0 warnings), `MIX_ENV=dev mix dialyzer --no-check` (0 errors), AST moduledoc scan (110 lib defmodules, 0 missing)
- Repo files: `.credo.exs`, `mix.exs:103,124-210`, `.github/workflows/ci.yml:107-130,253-379,924-960`, `test/threadline/dialyzer_ignore_contract_test.exs`, `public_surface_contract_test.exs:1-80,195-240,520-575,600-645`, `ci_workflow_parity_contract_test.exs:1-100`, `capture/audit_transaction.ex:50-69`, `semantics/audit_action.ex:35-60`, `operator_surface/scope.ex`, `retention.ex:170-195`, `test/test_helper.exs`

### Secondary
- [mix xref 1.15.0 docs](https://mix.hexdocs.pm/1.15.0/Mix.Tasks.Xref.html): `--format cycles`, `compile-connected` label, and `--fail-above` present in 1.15

## Metadata

**Confidence breakdown:**
- Credo config mechanics: HIGH. Source read and behaviour proven by scratch probes.
- Finding inventory: HIGH. Measured; matches D-00 exactly.
- GATE-03/04 mechanics: HIGH for 1.17.3; MEDIUM for the 1.15 lane (A1).
- Pitfalls: HIGH (each tied to a read file or probe).

**Research date:** 2026-09-22
**Valid until:** until the next `mix.lock` credo bump or any commit touching `lib/` (line numbers are volatile; the counts hold until then).
