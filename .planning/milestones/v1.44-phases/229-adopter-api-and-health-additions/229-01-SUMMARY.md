---
phase: 229-adopter-api-and-health-additions
plan: 01
subsystem: api
tags: [ecto, postgres, query, limit]

# Dependency graph
requires: []
provides:
  - "Threadline.history/3 :limit option (QRY-01, QRY-02)"
  - "Threadline.Query.HistoryLimit private module (validate!/1, apply/2)"
  - "phase 229's before suite wall clock (D-28), half of evidence/SC5-wallclock.md"
affects: [229-02, 229-03, 229-04, 230-rebalance-net-suite-check-and-0-12-0]

# Actuals (#2632)
actuals:
  tokens: 5189
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Validate before any DB access, then cap with limit/2 as the final query stage (mirrors Threadline.Evidence's validate_limit!/maybe_limit shape)"
    - "Independent oracle for ordering/property tests: raw SQL against StorageSchema.table(...), never through the function under test's own query-building helpers"

key-files:
  created:
    - lib/threadline/query/history_limit.ex
    - .planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md
  modified:
    - lib/threadline/query.ex
    - lib/threadline.ex
    - CHANGELOG.md
    - test/threadline/query_test.exs
    - test/threadline/query/as_of_property_test.exs

key-decisions:
  - "Extracted validate!/1 and apply/2 into a new private Threadline.Query.HistoryLimit module (not a deviation from the plan — a hard source-size-contract fix) after the inline doc + helper additions pushed lib/threadline/query.ex to 811 lines, 11 over the repo's 800-line ceiling"
  - "Oracle correctness for jsonb params: Postgrex's jsonb extension JSON-encodes the Elixir term it receives; pre-encoding table_pk with Jason.encode!/1 before binding double-encodes it into a scalar JSON string, so the oracle passes the map value directly as the bind param"

requirements-completed: [QRY-01, QRY-02]

coverage:
  - id: D1
    description: "Threadline.history/3 accepts limit: n, capping to the n most recent changes (captured_at desc, id desc); validated before any DB access; nil is unbounded"
    requirement: "QRY-01"
    verification:
      - kind: unit
        ref: "test/threadline/query_test.exs#history/3 :limit caps to the n most recent changes and rejects invalid values"
        status: pass
      - kind: unit
        ref: "test/threadline/query_test.exs#history/3 :limit against an independent oracle, boundary + tie adjacency (QRY-01/QRY-02)"
        status: pass
      - kind: unit
        ref: "test/threadline/query_test.exs#history/3 :limit rejection cases raise with the exact message"
        status: pass
      - kind: unit
        ref: "test/threadline/query_test.exs#history/3 :limit validation precedes row-key matching (garbage id + invalid limit)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The no-:limit default stays byte-identical/unchanged (unbounded), including under scope_query_fn, ties, and the empty case, proven against an independent oracle plus a DB property"
    requirement: "QRY-02"
    verification:
      - kind: unit
        ref: "test/threadline/query_test.exs#history/3 :limit plus scope: the cap counts only in-scope rows"
        status: pass
      - kind: unit
        ref: "test/threadline/query_test.exs#history/3 :limit on an empty history returns [] for no limit, nil, and limit: 1"
        status: pass
      - kind: integration
        ref: "test/threadline/query/as_of_property_test.exs#property history(limit: n) equals Enum.take(history(), n) for every n in 1..length+2"
        status: pass
    human_judgment: false

duration: 29min
completed: 2026-10-02
status: complete
---

# Phase 229 Plan 01: Threadline.history/3 :limit Summary

**Capped `Threadline.history/3` via `Threadline.Query.HistoryLimit` (validate before any DB access, LIMIT applied after both order_by's and the scope predicate), proven against an independent oracle and a DB-backed prefix property, with the before half of the phase's suite wall-clock evidence recorded first.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-10-02T16:18:00Z
- **Completed:** 2026-10-02T16:47:00Z
- **Tasks:** 3 completed
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments
- `Threadline.history/3` and `Threadline.Query.history/3` accept an optional `:limit`, validated before any DB access (`nil` unbounded; `0`, negatives, floats, strings, booleans raise `ArgumentError` with the exact `Threadline.Evidence`-style message)
- The cap is applied as the query's final `LIMIT`, after both `order_by` clauses and the `scope_query_fn` predicate, so it counts only in-scope rows
- Full example-test matrix against an independent, non-reused oracle (raw SQL against `StorageSchema.table("audit_changes")`, sorted in Elixir with `DateTime.compare` — never through `where_row`/`history_query`), covering boundary, `captured_at` tie adjacency, scope interaction, all five rejection shapes, empty history, and validation-before-row-key-matching
- A second `as_of_property_test.exs` property: `history(limit: n) == Enum.take(history(), n)` for every `n` in `1..length+2`, reusing `history_gen/0` and `PropertyRuns.db(20)` — no new generator or table
- Both `@docs` (`lib/threadline.ex`, `lib/threadline/query.ex`) and the CHANGELOG document `:limit` as additive with the default unchanged
- Phase 229's "before" suite wall clock recorded in `evidence/SC5-wallclock.md` before any `lib/`/`test/` change, cited against the phase-225 partitioned-CI baseline (run 36730596489)

## Task Commits

1. **Task 1: Tracer — before wall clock + wire limit: n end-to-end** - `352aa42b` (feat)
2. **Task 2: Full :limit example matrix + prefix property** - `27212202` (test)
3. **Task 3: Document :limit in both @docs and CHANGELOG** - `ebbd2341` (docs)

_No TDD tasks in this plan; each task is a single atomic commit._

## Files Created/Modified
- `lib/threadline/query.ex` — `history/3` validates `:limit` first; `history_query/3` applies `HistoryLimit.apply/2` after both `order_by`s; Options doc + example
- `lib/threadline/query/history_limit.ex` — new private module: `validate!/1`, `apply/2` (extracted to keep `query.ex` at the 800-line source-size ceiling)
- `lib/threadline.ex` — public `history/3` `:limit` Options bullet
- `CHANGELOG.md` — `### Added` bullet: additive, default unchanged
- `test/threadline/query_test.exs` — tracer test, independent-oracle boundary/tie-adjacency test, scope test, 5 rejection tests, precedence test, empty-history test
- `test/threadline/query/as_of_property_test.exs` — second property (`:limit` prefix contract) + moduledoc paragraph
- `.planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md` — before wall clock (3 `mix test` runs, 1 `mix verify.test_partitioned`, phase-225 baseline comparator)

## Decisions Made
- Mirror `Threadline.Evidence.validate_limit!/1`'s exact message wording for `:limit`'s `ArgumentError`, but accept `nil` (Evidence rejects it) so `limit: opts[:limit]` pass-through stays valid, per locked decision D-01.
- Extract the new validation/cap functions into `Threadline.Query.HistoryLimit` (a sibling to the existing `Query.{Cursors, RowKey, Scope}` private submodules) rather than trimming the public `@doc` prose, once the doc + helper additions pushed `query.ex` to 811 lines — 11 over the repo's hard 800-line ceiling (`source_size_contract_test.exs`). This is a Rule 3 blocking-issue auto-fix, not a plan deviation: the plan's `executor_safety` block states the 800-line ceiling as a hard constraint, and the fix is a clean module split with no behavior change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] `lib/threadline/query.ex` exceeded the 800-line source-size ceiling**
- **Found during:** Task 3, while running the plan's own acceptance check (`mix test test/threadline/source_size_contract_test.exs test/threadline/release_artifact_contract_test.exs`)
- **Issue:** The `:limit` doc/example additions (Task 1) plus the Options/scope-interaction prose (Task 3) pushed `lib/threadline/query.ex` to 811 lines; `source_size_contract_test.exs` allows no exception for this file.
- **Fix:** Extracted `validate_history_limit!/1` and `maybe_limit/2` into a new `lib/threadline/query/history_limit.ex` (`@moduledoc false`, `validate!/1` + `apply/2`, matching the sibling `Cursors`/`RowKey`/`Scope` pattern), and tightened the `:limit` Options bullet / scope-interaction sentence to fit the same information in fewer lines. Final line count: exactly 800.
- **Files modified:** `lib/threadline/query.ex`, `lib/threadline/query/history_limit.ex` (new)
- **Verification:** `mix test test/threadline/source_size_contract_test.exs test/threadline/release_artifact_contract_test.exs` exits 0; `mix verify.credo` clean; `mix test` (full suite) 32 properties, 2709 tests, 0 failures, 3 excluded
- **Committed in:** `ebbd2341` (part of Task 3's commit)

---

**Total deviations:** 1 auto-fixed (Rule 3)
**Impact on plan:** No scope creep — a module split required by a pre-existing repo-wide hard constraint, with identical public behavior and docs content.

## Issues Encountered
- Jason-encoding `table_pk` before binding it as a `$n::jsonb` query parameter in the independent oracle double-encoded the value into a JSON string scalar (Postgrex's jsonb extension already JSON-encodes the Elixir term it receives), so the oracle's `WHERE table_pk = $2::jsonb` matched nothing. Fixed by passing the raw Elixir map as the bind parameter instead of a pre-encoded string.
- Running a second, unrelated `mix test` invocation concurrently against the same non-sandboxed local Postgres while a background full-suite run was in flight produced 5 transient failures in `as_of_property_test.exs`'s new property (cross-run interference on the shared `asof_prop_rows` fixture table — this repo's DataCase does not use the SQL Sandbox). A subsequent clean, non-concurrent `mix test` run was 0 failures (32 properties, 2709 tests, 3 excluded), confirming no real regression.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Plan 02 (`--strict`), plan 03 (`--all-schemas`), and plan 04 (`legacy_key_findings/1` + the after half of `evidence/SC5-wallclock.md`) can proceed independently; none depends on this plan's `:limit` work. The full local suite is green (32 properties, 2709 tests, 0 failures, 3 excluded) and `mix verify.credo` / `mix docs` are clean on top of this plan's commits.

---
*Phase: 229-adopter-api-and-health-additions*
*Completed: 2026-10-02*

## Self-Check: PASSED

- `lib/threadline/query/history_limit.ex` exists
- `.planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md` exists
- Commits `352aa42b`, `27212202`, `ebbd2341` all found in `git log --oneline --all`
