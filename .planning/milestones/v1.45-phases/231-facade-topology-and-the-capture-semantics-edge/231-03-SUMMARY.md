---
phase: 231-facade-topology-and-the-capture-semantics-edge
plan: 03
subsystem: docs
tags: [doc-contract, facade, api-surface, source-size]

requires:
  - phase: 231-02
    provides: "Threadline.Query and Threadline.Investigation hidden (@moduledoc false); every rendered lib doc and five guides rewritten onto the Threadline facade"
provides:
  - "test/threadline/facade_only_references_contract_test.exs — mutation-controlled, non-vacuous guard forbidding any Threadline.Query.*/Threadline.Investigation.* reference in guides/README/example-app outside the timeline_query/1 escape hatch"
  - "examples/threadline_phoenix/priv/scripts/incident_replay.exs on Threadline.history/3 (last D-11 row closed)"
  - "lib/threadline/query.ex back under the 800-line source-size limit via the new Threadline.Query.ActionHydration hidden submodule"
affects: ["232 (retiring other internal helper names will touch ActionHydration's deprecation shim too)"]

actuals:
  tokens: 33000
  tasks: 2
  commits: 3
  plan_head_before: ff5345defce0ef1dddc541f8c6eb494160868600
  plan_head_after: 3de91c131a26991a0a1c1135903310d4d673fddf

tech-stack:
  added: []
  patterns:
    - "defdelegate with the same name/arity as the split-off function, so every existing call site and literal-source test assertion stays byte-identical across a module split"
    - "exact-match function-name allowlist (membership, never prefix) for a doc-contract scanner, proven by a near-miss fixture case"

key-files:
  created:
    - test/threadline/facade_only_references_contract_test.exs
    - lib/threadline/query/action_hydration.ex
  modified:
    - examples/threadline_phoenix/priv/scripts/incident_replay.exs
    - lib/threadline/query.ex

key-decisions:
  - "D-12 scanner implementation: offenders/2 and bare_aliases/2 both return {label, line, matched_text} tuples; the backtick/call regexes keep a capture group around the function name (not in the literal pattern text from 231-CONTEXT.md, which had no capture) so the allowlist can do an exact membership check instead of a substring/prefix match"
  - "Rule 1 blocking fix: split lib/threadline/query.ex (grown to 950 lines in 231-01, no exception) into Threadline.Query.ActionHydration — a new @moduledoc false submodule holding hydrate_actions/3 and the deprecated :preload shim helpers. Query.hydrate_actions/3 keeps its name/arity via defdelegate, so lib/threadline/investigation.ex, lib/threadline/operator_surface/live/timeline_live.ex, and every literal-source test assertion referencing Query.hydrate_actions needed zero changes"
  - "extract_transaction_action_preload renamed to extract_tx_action_preload (internal-only helper, no external references) purely to fit mix format's line-length limit after module qualification"

requirements-completed: [API-04, API-07]

coverage:
  - id: D12
    description: "test/threadline/facade_only_references_contract_test.exs scans guides/*.md, README.md, examples/threadline_phoenix/README.md, examples/threadline_phoenix/lib/**/*.{ex,heex} and examples/threadline_phoenix/priv/scripts/*.exs with the backtick and call forms, allowlists exactly timeline_query by exact match, and fails on any other Threadline.Query./Threadline.Investigation. reference; CHANGELOG.md, examples/threadline_phoenix/test/**, e2e/ and .planning/ are not scanned"
    requirement: "API-04"
    verification:
      - kind: unit
        ref: "test/threadline/facade_only_references_contract_test.exs#the real scope reports zero facade-only offenders"
        status: pass
      - kind: unit
        ref: "test/threadline/facade_only_references_contract_test.exs#self-test (fixture, non-vacuous)"
        status: pass
    human_judgment: false
  - id: D12-alias
    description: "A bare alias of Threadline.Query or Threadline.Investigation in the scanned scope fails with a message containing \"extend the scanner\"; a struct-group alias (alias Threadline.Investigation.{IncidentBundle, ...}) does not trip it"
    requirement: "API-04"
    verification:
      - kind: unit
        ref: "test/threadline/facade_only_references_contract_test.exs#has zero bare aliases of the hidden modules (extend the scanner otherwise)"
        status: pass
      - kind: unit
        ref: "test/threadline/facade_only_references_contract_test.exs#the alias guard does not flag a struct-group alias fixture"
        status: pass
    human_judgment: false
  - id: D11
    description: "examples/threadline_phoenix/priv/scripts/incident_replay.exs calls Threadline.history/3 instead of the hidden Query function; the example app's incident replay smoke test still passes"
    requirement: "API-04"
    verification:
      - kind: unit
        ref: "test/threadline/facade_only_references_contract_test.exs#the real scope reports zero facade-only offenders"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/incident_replay_smoke_test.exs"
        status: pass
    human_judgment: false
  - id: D13
    description: "A mutation control proves the facade-only scanner is live: re-adding a hidden-module call to a guide turns the test red, naming the file and line; restoring the guide turns it green again"
    requirement: "API-04"
    verification:
      - kind: other
        ref: "manual mutation run recorded below (red/restore/green), guide left unmodified in the committed tree"
        status: pass
    human_judgment: false
  - id: SC5
    description: "mix compile --warnings-as-errors is clean for lib/ and test/ (MIX_ENV=test) and for the example app (mix verify.example), MIX_ENV=dev mix docs --warnings-as-errors is clean, and mix ci.all exits 0"
    requirement: "API-04"
    verification:
      - kind: other
        ref: "MIX_ENV=test mix compile --warnings-as-errors --force"
        status: pass
      - kind: other
        ref: "mix verify.example"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
      - kind: other
        ref: "mix ci.all"
        status: pass
    human_judgment: false
  - id: source-size
    description: "lib/threadline/query.ex, which grew past the 800-line source-size contract limit in 231-01, is split so the contract passes again with no new exception"
    requirement: "API-07"
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#file length the real tree matches the file exceptions exactly"
        status: pass
    human_judgment: false

duration: 3h 10min
completed: 2026-10-03
status: complete
---

# Phase 231 Plan 03: Facade Topology and the Capture/Semantics Edge Summary

**Added a mutation-controlled facade-only doc-contract scanner over guides/README/example-app, moved the example app's last hidden-module call onto `Threadline.history/3`, and proved the whole phase green with `mix ci.all` — discovering and fixing a 231-01 regression (`query.ex` over the 800-line source-size limit) along the way.**

## Performance

- **Duration:** ~3h 10min (includes a session interruption and resume; see Deviations)
- **Started:** 2026-10-03T16:05:00Z (approx, continues from 231-02)
- **Completed:** 2026-10-03T19:15:00Z (approx)
- **Tasks:** 2 completed
- **Files:** 2 created (184 + 173 lines), 2 modified (189, 799 lines)

## Accomplishments

- `test/threadline/facade_only_references_contract_test.exs` (new, 11 tests): scans `guides/*.md`, `README.md`, the example app README, `lib/**/*.{ex,heex}`, and `priv/scripts/*.exs` for the two locked `Threadline.Query.*`/`Threadline.Investigation.*` reference patterns (backtick and call forms), allowlisting exactly `timeline_query` by **exact name match** — a near-miss like `timeline_query_x` still trips it. A self-test fixture proves the scanner is non-vacuous; per-glob assertions prove every scope entry resolves to at least one file; a bare-alias guard fails loudly with "extend the scanner" on `alias Threadline.Query`/`alias Threadline.Investigation` while leaving struct-group aliases (`alias Threadline.Investigation.{IncidentBundle, ...}`) untouched.
- `examples/threadline_phoenix/priv/scripts/incident_replay.exs:117` now calls `Threadline.history/3` instead of `Threadline.Query.history/3` — the last row of 231-CONTEXT.md's D-11 table. The example app's incident-replay smoke test (`examples/threadline_phoenix/test/threadline_phoenix/incident_replay_smoke_test.exs`) still passes (5/0).
- D-13 mutation control for the new scanner (recorded below): a temporary hidden-module line appended to `guides/how-threadline-works.md` turns the real-scope test red, naming the exact file and line; `git checkout` of that one file restores it, and the suite is green again. The mutated guide was never committed.
- **Rule 1 blocking fix, discovered running the Task 2 phase gate:** `lib/threadline/query.ex` had grown to 950 lines in 231-01 (the `hydrate_actions/3` helper plus the deprecated `:preload` shim), silently tripping `test/threadline/source_size_contract_test.exs`'s 800-line limit with no named exception — a real regression traceable to this phase, not caught by 231-01/231-02's own narrower verify commands. Split both clusters into a new hidden submodule, `Threadline.Query.ActionHydration`; `Threadline.Query.hydrate_actions/3` keeps its exact name and arity via `defdelegate`, so every existing call site (`investigation.ex`, `timeline_live.ex`) and every literal-source test assertion needed zero changes. `query.ex` is now 799 lines.
- `MIX_ENV=test mix compile --warnings-as-errors --force`, `mix test --warnings-as-errors` (2769 tests, 0 failures), `mix verify.example` (130 tests, 0 failures), `MIX_ENV=dev mix docs --warnings-as-errors`, `mix verify.credo` (0 issues), `mix verify.format`, and `mix ci.all` are all green. `mix ci.all`'s browser lane matches the documented baseline exactly: 318 passed, 26 skipped.

## Task Commits

1. **Task 1: Tracer — facade-only scanner + example script onto the facade**
   - `fa8a24bc` `test(231-03): add failing facade-only references contract test` (RED — the real-scope test failed naming `examples/threadline_phoenix/priv/scripts/incident_replay.exs:117`)
   - `6e58912e` `feat(231-03): move the example replay script onto Threadline.history/3` (GREEN — 11/0)
   - Mutation control (D-13) run and recorded below; not committed (the mutated guide was restored via `git checkout`, never staged).
2. **Task 2: Phase gate — discovered and fixed the 231-01 source-size regression, then proved SC5**
   - `3de91c13` `fix(231-03): split ActionHydration out of query.ex to clear the 800-line gate`
   - All remaining gate commands (`mix test --warnings-as-errors`, `mix verify.example`, `MIX_ENV=dev mix docs --warnings-as-errors`, `mix ci.all`) ran clean after this fix and produced no further file changes.

**Plan metadata:** (this commit)

## D-13 Mutation Control Record (231-03 scanner)

```
$ echo '`Threadline.Investigation.row_history/4`' >> guides/how-threadline-works.md
$ mix test test/threadline/facade_only_references_contract_test.exs
  1) test the real scope reports zero facade-only offenders (Threadline.FacadeOnlyReferencesContractTest)
     Found hidden-module reference(s) outside the documented escape hatch (Threadline.Query.timeline_query/1). Rewrite to a Threadline facade call:
     guides/how-threadline-works.md:361 `Threadline.Investigation.row_history/4`
  11 tests, 1 failure

$ git checkout -- guides/how-threadline-works.md
$ git diff --quiet -- guides/how-threadline-works.md && echo "restored clean"
restored clean

$ mix test test/threadline/facade_only_references_contract_test.exs
  11 tests, 0 failures
```

The guide was never staged or committed in its mutated state.

## Gate Evidence (SC5)

```
$ MIX_ENV=test mix compile --warnings-as-errors --force
Generated threadline app                     # exit 0, no warnings

$ mix test --warnings-as-errors
32 properties, 2769 tests, 0 failures, 3 excluded   # exit 0

$ mix verify.example
130 tests, 0 failures                         # exit 0

$ MIX_ENV=dev mix docs --warnings-as-errors
Generating docs...
View html docs at "doc/index.html"           # exit 0

$ git diff --quiet 0e5eda11 -- lib/threadline/capture/migration.ex lib/threadline/semantics/migration.ex lib/threadline/capture/trigger_sql.ex priv
# exit 0 — SC4 untouched capture/semantics/trigger/migration files

$ mix verify.credo
4983 mods/funs, found no issues.              # exit 0

$ mix verify.format
# exit 0

$ mix ci.all
verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.5.1)
verify-repo-hygiene: 4497 tracked text file(s) clean; 8 allowlist entries used, 0 inert
No cycles found
...
Total errors: 0, Skipped: 0, Unnecessary Skips: 0   # Dialyzer
done (passed successfully)
17 tests, 0 failures, 16 excluded              # live Dialyzer slice proof
...
  26 skipped
  318 passed (4.6m)                            # browser lane, matches documented baseline exactly
# exit 0
```

## Files Created/Modified

- `test/threadline/facade_only_references_contract_test.exs` (new) — the D-12 scanner: `scope_files/0`, `offenders/2`, `bare_aliases/2`, `format_offenders/1`, 11 tests
- `lib/threadline/query/action_hydration.ex` (new) — `Threadline.Query.ActionHydration`, `@moduledoc false`: `hydrate_actions/3` (+ 3 private helpers) and the deprecated `:preload` shim (`extract_action_preload/1`, `extract_tx_action_preload/1`, `extract_nested_transaction_action/2` (private), `maybe_warn_deprecated_action_preload/1`)
- `lib/threadline/query.ex` — removed the two extracted clusters; added `alias Threadline.Query.{ActionHydration, ...}` and `defdelegate hydrate_actions(items, repo, opts \\ []), to: ActionHydration`; the two internal call sites in `audit_transaction/2` and `audit_changes_for_transaction/2` now call `ActionHydration.extract_action_preload/1` / `ActionHydration.extract_tx_action_preload/1` / `ActionHydration.maybe_warn_deprecated_action_preload/1`. 950 → 799 lines.
- `examples/threadline_phoenix/priv/scripts/incident_replay.exs` — `Threadline.Query.history(...)` → `Threadline.history(...)`

## Decisions Made

- The D-12 scanner's regexes keep the two patterns from 231-CONTEXT.md but add a capture group around the function name, needed so the allowlist check is exact-membership (`name in @allowed_functions`) rather than a substring test — this is what makes `timeline_query_x` fail while `timeline_query` passes.
- `hydrate_actions/3` stays reachable at the exact same `Threadline.Query.hydrate_actions/3` name/arity after the split, via `defdelegate`, specifically so no caller or literal-source test needed to change — only the deprecation-shim's *private* helpers (never referenced outside `query.ex`) were renamed (`extract_tx_action_preload`) or re-qualified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `lib/threadline/query.ex` exceeded the 800-line source-size contract limit**
- **Found during:** Task 2, running `mix test --warnings-as-errors` as the first phase-gate command
- **Issue:** `query.ex` had grown to 950 lines during 231-01 (adding `hydrate_actions/3` and the deprecated `:action` preload shim), 150 lines over `test/threadline/source_size_contract_test.exs`'s 800-line limit, with no named exception. Confirmed pre-existing to this plan's own commits: `git show ff5345de:lib/threadline/query.ex | wc -l` also reports 950, and the file was exactly 800 lines at phase 231's start commit (`1059931b^`) — so the regression is traceable to 231-01, inside this phase, not to 231-03's own work.
- **Fix:** Extracted `hydrate_actions/3` (+ 3 private helpers) and the deprecated-preload shim (4 more helpers) into a new hidden submodule, `Threadline.Query.ActionHydration`. `Query.hydrate_actions/3` is preserved via `defdelegate`, so `investigation.ex`, `timeline_live.ex`, and the literal-source assertions in `query_test.exs`/`timeline_live_test.exs` needed no changes. The two deprecation-shim call sites in `audit_transaction/2` / `audit_changes_for_transaction/2` were re-qualified to `ActionHydration.*`. One internal-only helper was renamed (`extract_transaction_action_preload` → `extract_tx_action_preload`) purely to satisfy `mix format`'s line-length limit after qualification.
- **Files modified:** `lib/threadline/query.ex` (950 → 799 lines), new `lib/threadline/query/action_hydration.ex` (173 lines)
- **Verification:** `mix test test/threadline/source_size_contract_test.exs` (18/0), the full suite (2769 tests, 0 failures), `mix verify.example` (130/0), `mix verify.credo` (0 issues), `mix verify.format` (clean), `mix ci.all` (exit 0, 318 browser tests passed / 26 skipped, matching the documented baseline).
- **Committed in:** `3de91c13`

**2. [Rule 1 - Bug] Two `mix verify.credo` findings in the new contract test file**
- **Found during:** Task 2, running `mix verify.credo` as part of the phase gate
- **Issue:** `test/threadline/facade_only_references_contract_test.exs`'s `format_offenders/1` used `Enum.map/2 |> Enum.join/2` (Credo: prefer `Enum.map_join/3`), and `bare_aliases/2`'s `case` inside a `flat_map` callback nested one level too deep.
- **Fix:** `format_offenders/1` now uses `Enum.map_join/3` directly; `bare_aliases/2`'s `case` was replaced with a direct `Regex.scan |> Enum.map` pipe (an empty scan result already maps to `[]`, so behavior is unchanged).
- **Files modified:** `test/threadline/facade_only_references_contract_test.exs`
- **Verification:** `mix verify.credo` → 0 issues; `mix test test/threadline/facade_only_references_contract_test.exs` → 11/0 (unchanged).
- **Committed in:** `3de91c13`

---

**Total deviations:** 2 auto-fixed (both Rule 1, both surfaced by the Task 2 phase-gate commands themselves — not pre-existing issues deferred from elsewhere). **Impact on plan:** Both fixes were scoped to files this task already owned or was actively gating; neither changed any documented behavior, Ecto schema, trigger, or migration. `files_modified` in this plan's frontmatter listed only the contract test and the example script; the source-size fix added `lib/threadline/query.ex` (expected — it's where the scanner's hidden-module reference check lives conceptually, and the plan's own Task 2 action text anticipates exactly this: "The file listed is only touched if a gate below exposes a defect") and a new file, `lib/threadline/query/action_hydration.ex`, not listed in the plan's `files_modified`. This is a deviation from the plan's stated file list, recorded here per Rule 1.

## Issues Encountered

One session interruption (network/API error) occurred mid-Task-2, after the `ActionHydration` split was made on disk but before it was committed or the gates were re-run. Resumed from the coordinator's handoff: verified the on-disk state matched exactly (uncommitted `query.ex` + untracked `action_hydration.ex` + the credo-fix edit to the contract test, nothing else), re-ran every gate from scratch rather than trusting any in-flight result, and confirmed real exit codes directly (not through a piped `tail`, which had silently masked a `mix test` exit code during Task 2's first attempt — see note below).

**Tooling note for future executors:** `mix test --warnings-as-errors 2>&1 | tail -N` reports the exit code of `tail`, not of `mix test` — it was 0 even when the suite had a real failure. Redirect to a file and check `$?` directly (or use `bash -o pipefail`) when the exit code itself is the gate.

## Known Stubs

None — no stub patterns introduced. This plan added a doc-contract test, a module split with no behavior change, and a one-line call-site edit in an example script.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- API-04 is fully satisfied: `Threadline.Query`/`Threadline.Investigation` are hidden (231-02), every guide/README/example-app reference goes through the facade or the named escape hatch (231-02 + this plan), and the facade-only contract is mutation-controlled and non-vacuous (this plan).
- API-07 is fully satisfied: the capture/semantics association is dropped (231-01), `.action` hydration is batched and hidden (231-01, relocated into `ActionHydration` this plan with no behavior change), and SC4 (capture/semantics/trigger/migration files untouched since `0e5eda11`) holds.
- `mix ci.all` is green end-to-end on this tree.
- Phase 231 (Facade Topology and the Capture/Semantics Edge) is complete. Ready for `/gsd-plan-phase 232`.

## Self-Check: PASSED

- All key-files (created + modified) verified present on disk
- All 3 task commits (`fa8a24bc`, `6e58912e`, `3de91c13`) verified present via `git log --oneline --all`
- Plan `<verification>` block re-run clean: `mix test test/threadline/facade_only_references_contract_test.exs` (11/0), `mix ci.all` (exit 0)

---
*Phase: 231-facade-topology-and-the-capture-semantics-edge*
*Completed: 2026-10-03*
