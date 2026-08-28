---
phase: 198-green-bringup
plan: 08
subsystem: testing
tags: [ecto, storage-schema, test-hygiene, contract-test, tdd]

requires:
  - phase: 198-04
    provides: "the corrected root-cause diagnosis (79 test-side defects assuming an unprefixed search_path) and the D-02 no-search-path decision this plan enforces"
provides:
  - "the proven port recipe (repo_opts() as trailing opts on every Ecto call) for the remaining 14 defective files, to be applied mechanically in 198-12"
  - "a non-vacuous, behaviourally-armed guard (Threadline.StorageSchemaMaskContractTest) that fails if the forbidden search_path/default-prefix shortcut is ever reintroduced"
affects: [198-12]

actuals:
  tokens: 9700
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Threadline.StorageSchemaCase.repo_opts() as the trailing opts arg on every Ecto call against a Threadline-owned schema in non-DataCase test modules (import Threadline.StorageSchemaCase directly when the module is a plain ExUnit.Case, not Threadline.DataCase)"
    - "Behavioural + positive-control test pair (raise-then-succeed) as the non-vacuous shape for a regression guard, backed by a source-refutation pair (repo callback + config glob) for the two concrete forbidden routes"

key-files:
  created: []
  modified:
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/storage_schema_prefix_contract_test.exs

key-decisions:
  - "Used Threadline.StorageSchemaCase.repo_opts/0 (TRIAGE option 2) exclusively — no prefix: \"threadline\" literal, no config/repo/lib changes, per the plan's pre-decided remediation shape."
  - "All 20 repo.insert! call sites plus 6 delete_all call sites (2 modules x 3 schemas) in transaction_live_test.exs got repo_opts() appended — not just the two clusters the plan called out by name — because every Ecto call in the file targets a Threadline-owned schema, matching the plan's literal instruction (\"for every Ecto call in this file that names a Threadline-owned schema module\")."
  - "The new guard module is test-only (no lib/ or config/ change), so it landed as a single test(198-08) commit rather than a test/feat pair — see TDD Gate Compliance note below."

requirements-completed: [GREEN-04]

coverage:
  - id: D1
    description: "transaction_live_test.exs (14 tests, 2 modules) passes against a threadline_test database with no schema search parameter, using only StorageSchemaCase.repo_opts()"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/transaction_live_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Threadline.StorageSchemaMaskContractTest — D-02 mask-regression guard with a demonstrated red-then-green non-vacuity proof"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test test/threadline/storage_schema_prefix_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Port recipe for the remaining 14 defective files is proven end-to-end and written down for 198-12"
    verification: []
    human_judgment: true
    rationale: "The recipe's correctness for the other 14 files can only be confirmed when 198-12 applies it — this SUMMARY records the exact shape but a human/future-plan judgment call decides whether any of the 14 files need the storage_schema \\\\ \"threadline\" parameterization variant actor_live_test.exs used."

duration: 22min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 08: Storage-Schema Mask Tracer + D-02 Guard Summary

**Ported transaction_live_test.exs to `StorageSchemaCase.repo_opts()` (81→67 full-suite failures, exactly −14) and landed a behaviourally-armed D-02 mask-regression guard that goes RED when a forbidden default-prefix callback is reintroduced.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-08-28T03:37:00Z (approx)
- **Completed:** 2026-08-28T03:59:00Z (approx)
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Ported all 28 Ecto call sites in `test/threadline/operator_surface/transaction_live_test.exs` (both `TransactionLiveTest` and `TransactionLiveScopedTest` modules) to append `Threadline.StorageSchemaCase.repo_opts()` as the trailing opts argument, and added `import Threadline.StorageSchemaCase` to both modules (neither uses `Threadline.DataCase`, so the helper was not in scope before).
- File goes from 14 failures to 0 failures in isolation; full suite dropped from 81→67 failures (exactly −14), confirming no other file was affected and no regression was introduced.
- Wrote the port recipe as the reusable pattern for 198-12 (see "Port Recipe for 198-12" below).
- Added `Threadline.StorageSchemaMaskContractTest` (4 new tests) to `test/threadline/storage_schema_prefix_contract_test.exs`, as a third sibling module alongside the two pre-existing ones (both left unmodified).
- Demonstrated the guard's non-vacuity live: temporarily added a `default_options/1` callback returning `[prefix: "threadline"]` to `test/support/repo.ex`, observed 2 of the 4 new tests go RED with exactly the expected failure messages, then reverted and confirmed all 9 tests (5 existing + 4 new) GREEN again. `git status --porcelain test/support/repo.ex` is clean at task end.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end — one defective test file green through repo_opts/0** - `7b4a4aaf` (fix)
2. **Task 2: Make D-02 executable — a non-vacuous mask-regression guard** - `1022b378` (test)

**Plan metadata:** commit pending (this SUMMARY + REQUIREMENTS.md)

## Files Created/Modified

- `test/threadline/operator_surface/transaction_live_test.exs` — added `import Threadline.StorageSchemaCase` to both modules; appended `repo_opts()` to all 3 `delete_all` calls and all 25 `insert!` calls (20 multi-line + 5 single-line-helper) across both modules
- `test/threadline/storage_schema_prefix_contract_test.exs` — appended `Threadline.StorageSchemaMaskContractTest` (4 tests: behavioural raise, positive-control success, `default_options/1` source refutation, `config/*.exs` search_path glob refutation)

## Port Recipe for 198-12

Recorded here because 198-12 depends on it, per the plan's instruction:

1. **Import**: if the module `use ExUnit.Case` directly (not `Threadline.DataCase`), add `import Threadline.StorageSchemaCase` to the module body. `Threadline.DataCase` already imports it (`test/support/data_case.ex:21`), so this step is a no-op for `DataCase`-based modules.
2. **Which call shapes take `repo_opts()`:**
   - `Repo.delete_all(SchemaModule)` → `Repo.delete_all(SchemaModule, repo_opts())`
   - `repo.insert!(SchemaModule.changeset(attrs))` (multi-line, parenthesized) → append `,\n  repo_opts()` before the closing paren of `insert!(`, keeping the changeset expression's own closing paren/brace untouched
   - `Repo.insert!(SchemaModule.changeset(Map.merge(defaults, attrs)))` (single-line) → append `, repo_opts()` inline
3. **Which call shapes do NOT take it:** none in this file — every Ecto call here targets a Threadline-owned schema (`AuditTransaction`, `AuditChange`, `Threadline.Semantics.AuditAction`). If a future file has calls against non-Threadline-owned schemas (e.g. the `FakeUser` schema in this same file, which is never queried directly), leave those untouched.
4. **No `storage_schema \\ "threadline"` parameterization** unless a call site in that specific file actually needs a non-default schema — verified this file did not; `repo_opts()` with no argument was correct and smaller. Contrast with `actor_live_test.exs`, which does parameterize because its tests exercise both `"threadline"` and `"audit"` schemas.
5. **Do not touch** `config/test.exs`, `test/support/repo.ex`, or any `lib/` schema module. D-02 forbids all three routes; Task 2's guard now makes that prohibition executable.
6. **Verify** with `mix test <file>` (file-local 0 failures) and `mix test` (full-suite delta matches the file's known failure count exactly).

## Decisions Made

- **Blanket `repo_opts()` application, not just the two named clusters.** The plan's `<action>` text calls out two clusters by line number ("the two known clusters are the `delete_all` calls... and the `Repo.insert!` seeds at `:615` and `:631`") but its governing instruction is "for every Ecto call in this file that names a Threadline-owned schema module... append `repo_opts()`." Since every insert!/delete_all in this file targets `AuditTransaction`, `AuditChange`, or `AuditAction`, all 28 call sites were changed, not just the 4 the plan named by line. This is the correct reading of the plan's own comprehensive instruction and was confirmed by the file going from 14→0 failures (a partial port would have left some tests red).
- **Single test-only commit for Task 2, not a test/feat pair.** The guard is pure test code with zero `lib/` implementation — there is no "GREEN" implementation commit to make, because the behavior being guarded (unprefixed reads raise `undefined_table`) already exists in the shipped code. The RED/GREEN demonstration required by the acceptance criteria was performed live against `test/support/repo.ex` (temporarily reintroducing the forbidden callback, observing failure, reverting), not via a missing-then-present production commit. This is documented explicitly below under TDD Gate Compliance rather than silently deviating from the stated commit pattern.

## TDD Gate Compliance

Task 2 carries `tdd="true"` and a `<behavior>` block, so it is nominally subject to the RED→GREEN→REFACTOR gate sequence. In this case:

- **No `feat(198-08)` commit exists**, because Task 2 makes zero `lib/` changes — the behavior under test (an unprefixed read raising `undefined_table`) is pre-existing shipped behavior, not new implementation. There is nothing to "make pass" that wasn't already passing.
- **The RED proof was performed as a live rehearsal, not a git-history RED commit.** Per the task's own acceptance criteria ("temporarily add the forbidden repo options callback... observe the new module go RED, then `git checkout -- test/support/repo.ex`"), the RED state was demonstrated by editing `test/support/repo.ex` outside version control, running the suite, and reverting — never committed. Verbatim output below.
- This is a deliberate reading of an ambiguous plan shape (a "TDD" guard/contract test with no implementation delta), not a silent skip. If a stricter interpretation is wanted, 198-12 or a future audit can require guard-test plans to declare `tdd="false"` explicitly when no `feat` commit is expected.

**Verbatim RED output** (repo.ex temporarily modified to add `def default_options(_operation), do: [prefix: "threadline"]`):

```
  1) test reading an audit table through Threadline.Test.Repo with NO options raises undefined_table (D-02 teeth) (Threadline.StorageSchemaMaskContractTest)
     test/threadline/storage_schema_prefix_contract_test.exs:175
     Expected exception Postgrex.Error but nothing was raised
     code: assert_raise Postgrex.Error, ~r/undefined_table/, fn ->
     stacktrace:
       test/threadline/storage_schema_prefix_contract_test.exs:176: (test)

  2) test test/support/repo.ex declares no options callback that could inject a default prefix (D-02) (Threadline.StorageSchemaMaskContractTest)
     test/threadline/storage_schema_prefix_contract_test.exs:206
     D-02: test/support/repo.ex must not define default_options/1 — an Ecto.Repo default_options/1 callback is exactly the route by which a default `prefix:` could be silently injected into every query, re-hiding the defect class this phase exists to retire.
     code: refute source =~ ~r/def(p)?\s+default_options\b/,
     stacktrace:
       test/threadline/storage_schema_prefix_contract_test.exs:209: (test)

9 tests, 2 failures
```

**Verbatim GREEN output** after `cp /tmp/repo.ex.bak test/support/repo.ex`:

```
9 tests, 0 failures
```

`git status --porcelain test/support/repo.ex` was empty afterward.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Ran `mix deps.get` before the first test run**
- **Found during:** Task 1 (initial precondition/verify attempt)
- **Issue:** `mix test` failed immediately with "the dependency is not available, run mix deps.get" for every listed dep — the worktree checkout had no `deps/` populated.
- **Fix:** Ran `mix deps.get`, which resolved and fetched all listed Hex packages (Found packages with security advisories notice is pre-existing/unrelated to this plan's scope).
- **Files modified:** none tracked (deps/ is gitignored, mix.lock unchanged)
- **Verification:** `mix test test/threadline/operator_surface/transaction_live_test.exs` then ran and reported the expected 14 pre-fix failures.
- **Committed in:** N/A (no file changes to commit; environment setup only)

---

**Total deviations:** 1 auto-fixed (1 blocking — environment setup, package-manager install of already-declared deps, not a new/unverified package per the Rule 3 exclusion)
**Impact on plan:** No scope creep. Required to run any test in this worktree.

## Baseline Number Discrepancy (recorded per plan instruction, not silently reconciled)

The plan's frontmatter and `<verification>` block state a "recorded 80 baseline" and expect the post-Task-1 failure count to be "66 (80 minus this file's 14)." The actually measured baseline in this worktree, before any change, was **81 failures / 1380 tests** (`mix test` run before Task 1). After Task 1: **67 failures / 1380 tests** — a drop of exactly 14, matching the plan's required delta, but the absolute numbers are both off by +1 from the plan's stated 80/66. After Task 2 (4 new tests added): **67 failures / 1384 tests**, stable across two repeat runs (a single run showed 71 — see Issues Encountered below, confirmed as pre-existing flake, not attributable to this plan's changes).

This is recorded as a measured discrepancy, not corrected retroactively — the plan's acceptance criteria ("drop by exactly 14... recorded before/after numbers") are satisfied by the measured delta regardless of the absolute baseline's off-by-one against the plan's stated figure.

## Issues Encountered

- One `mix test` run (the first full-suite run after Task 2's commit) reported 71 failures instead of the stable 67 — `timeline_live_test.exs:956` was implicated. Two immediate re-runs both returned to the stable 67-failure count with no code changes in between, confirming this was a pre-existing order/timing flake (consistent with the project's documented retention-pruner/telemetry flake history in `CONTRIBUTING.md` "Deterministic tests"), not a regression introduced by this plan. Not investigated further — out of this plan's scope (transaction_live_test.exs and the storage-schema guard only).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The port recipe above is ready for 198-12 to apply mechanically to the remaining 14 defective files.
- The D-02 mask guard is live and will fail CI/local runs if the forbidden `search_path` or `default_options/1` prefix shortcut is ever reintroduced, closing the gap TRIAGE incorrectly claimed was already covered.
- `mix test` currently reports 67 failures (was 81 before this plan) across the full suite — the remaining 67 are the 14 files' worth minus this one, tracked for 198-12.
- Carried-forward debt (CR-03, CR-05) recorded in the plan is unchanged by this plan and remains deliberately out of scope.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
