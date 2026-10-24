---
phase: 233-lookup-return-shapes
plan: 02
subsystem: api
tags: [ecto, elixir, lookup, error-handling, liveview]

requires:
  - phase: 233-lookup-return-shapes
    provides: "Plan 01's Threadline.Query.TransactionLookup (validate_opts!/2, resolve_id/1, fetch_row/2) and Threadline.NotFoundError"
provides:
  - "Threadline.Query.TransactionLookup.fetch/2 (hidden): row-first existence check plus a second scoped changes read, reusing the hydrated row — the shared base transaction_context/2 and incident_bundle/2 now both build on"
  - "Threadline.transaction_context/2 returning {:ok, %LinkedTransaction{}} | {:error, :not_found}, plus transaction_context!/2"
  - "Threadline.incident_bundle/2 rebuilt on the same shared fetch (dropping the separate Query.audit_transaction/2 + Query.audit_changes_for_transaction/2 calls and a redundant hydrate_actions pass), plus incident_bundle!/2"
  - "Scope-and-existence parity proven across all three single-subject lookups (audit_transaction, transaction_context, incident_bundle): identical not-found/retention/scope-rejection behavior and byte-equal bang messages"
affects: [233-03-call-site-migration-and-guides, 233-04-fail-closed-scope]

actuals:
  tokens: 8820
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Shared row-first fetch (Threadline.Query.TransactionLookup.fetch/2): existence decided once by fetch_row/2 (surface: :transaction_header), changes read as an independent second query (surface: :transaction, [ac, at] binding), each change stamped with the already-hydrated row via %{change | transaction: row} instead of a second preload or hydrate_actions pass"
    - "Two independent READ COMMITTED reads, never wrapped in repo.transaction/1 — a concurrent retention delete between them is a valid state (row plus fewer or zero changes), not a race to guard against"

key-files:
  modified:
    - lib/threadline/query/transaction_lookup.ex
    - lib/threadline/investigation.ex
    - lib/threadline.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - test/threadline/transaction_lookup_test.exs
    - test/threadline/investigation_test.exs
    - test/threadline/storage_schema_integration_test.exs
    - test/threadline/query_test.exs
    - test/threadline/query/action_hydration_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs

key-decisions:
  - "transaction_context/2 and incident_bundle/2 both call the same TransactionLookup.fetch/2 — one row-first existence check, one independent changes read scoped with a hardcoded surface: :transaction ([ac, at] binding), never caller-relabelable since :surface/:params/:preload are rejected by the existing allowlist."
  - "Each returned change is stamped with the row already fetched (%{change | transaction: row}) rather than repo.preload or a second hydrate_actions call — this is what keeps incident_bundle/2 at <= 3 total queries (<= 2 when action_id is nil)."
  - "Removed the now-unused Threadline.Investigation.linked_transaction/1 private helper — transaction_context/2 no longer derives the transaction from its changes, so an existing zero-change transaction is found instead of looking missing."
  - "TransactionLive's mount drops surface: :transaction / params: %{transaction_id: id} from its Threadline.incident_bundle/2 call — those options are now rejected by the facade's allowlist, and the LiveView never needed to pass them since the surface is hardcoded internally."

requirements-completed: [API-06]

coverage:
  - id: D1
    description: "Threadline.transaction_context/2 returns {:ok, %LinkedTransaction{}} for an existing/visible transaction (including zero-change transactions) and {:error, :not_found} for missing, scope-filtered, or malformed-binary ids, built on the shared row-first fetch"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#transaction_context/2 and transaction_context!/2"
        status: pass
      - kind: unit
        ref: "test/threadline/investigation_test.exs#transaction_context/2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Threadline.transaction_context!/2 and Threadline.incident_bundle!/2 return the bare struct on success and raise Threadline.NotFoundError (resource: :audit_transaction) on absence"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#transaction_context/2 and transaction_context!/2"
        status: pass
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#incident_bundle/2 and incident_bundle!/2"
        status: pass
    human_judgment: false
  - id: D3
    description: "incident_bundle/2 shares the same fetch, stays at or under 3 repo queries (2 when action_id is nil), and matches transaction_context/audit_transaction on zero-change-via-retention and scope-rejection behavior, with byte-equal bang messages"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#query count"
        status: pass
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#zero-change transactions via retention"
        status: pass
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#scope parity across lookups"
        status: pass
    human_judgment: false
  - id: D4
    description: "TransactionLive renders the existing not-found state (not a crash) for a malformed transaction id, and passes only repo:/scope:/scope_query_fn: to Threadline.incident_bundle/2"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/transaction_live_test.exs#renders the not-found state for a malformed transaction id"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-10-04
status: complete
---

# Phase 233 Plan 02: Facade Lookups and Bangs Summary

**transaction_context/2 and incident_bundle/2 now share one row-first fetch (Threadline.Query.TransactionLookup.fetch/2), both gained `!` siblings, and incident_bundle stays at or under 3 queries while finding zero-change transactions that used to look missing.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-10-03T23:54:00Z
- **Completed:** 2026-10-04T00:29:10Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- `Threadline.Query.TransactionLookup.fetch/2` — the shared row-first fetch behind both `transaction_context/2` and `incident_bundle/2`: one existence check (`fetch_row/2`), one independent changes read scoped `surface: :transaction`, changes stamped with the already-hydrated row (no second preload/hydrate pass)
- `Threadline.transaction_context/2` now returns `{:ok, %LinkedTransaction{}} | {:error, :not_found}` instead of a struct with `transaction: nil`; an existing transaction with zero changes is now found rather than looking missing
- `Threadline.transaction_context!/2` and `Threadline.incident_bundle!/2` added, both raising `Threadline.NotFoundError` (`resource: :audit_transaction`) on absence
- `incident_bundle/2` rebuilt on the shared fetch, dropping the old separate `Query.audit_transaction/2` + `Query.audit_changes_for_transaction/2` calls and a redundant second `hydrate_actions` pass — proven at or under 3 repo queries (2 when `action_id` is nil)
- Scope-and-existence parity proven across all three single-subject lookups: a transaction whose only change is purged with `delete_empty_transactions: false` still returns `{:ok, _}` with `changes: []` from `audit_transaction/2`, `transaction_context/2`, and `incident_bundle/2` alike; a row-rejecting scope fn produces byte-equal bang messages to the same id after the row is deleted, across all three
- `TransactionLive`'s mount drops `surface:`/`params:` from its `incident_bundle/2` call (now rejected by the allowlist) and renders the existing not-found state for a malformed transaction id instead of crashing

## Task Commits

1. **Task 1: Tracer — transaction_context/2 returns the tuple through TransactionLookup.fetch/2, with its bang** - `ae5595b4` (feat)
2. **Task 2: incident_bundle/2 on the shared fetch, incident_bundle!/2, query count, zero-change via retention, scope parity across all three** - `a68981b0` (feat)
3. **Task 3: TransactionLive renders not-found for a malformed id; example app stays green** - `224554d6` (test)

**Plan metadata:** pending (this commit)

_Note: Tasks 1 and 2 were `tdd="true"`; each commit carries its RED test additions plus the GREEN implementation as one task-scoped commit, per the plan's instructions, not separate RED/GREEN commits. Task 3 is test-only (no `lib/` behavior change), committed as `test`._

## Files Created/Modified
- `lib/threadline/query/transaction_lookup.ex` - added `fetch/2`, the shared row-first existence-plus-changes read
- `lib/threadline/investigation.ex` - `transaction_context/2` and `incident_bundle/2` rewritten on `TransactionLookup.fetch/2`; removed the now-unused `linked_transaction/1`
- `lib/threadline.ex` - rewrote `transaction_context/2`/`incident_bundle/2` docs and specs, added `transaction_context!/2` and `incident_bundle!/2`, updated the "Reading audit data" moduledoc paragraph
- `lib/threadline/operator_surface/live/transaction_live.ex` - mount drops `surface:`/`params:` from its `Threadline.incident_bundle/2` call
- `test/threadline/transaction_lookup_test.exs` - new describes for `transaction_context/2,!/2`, `incident_bundle/2,!/2`, query count, retention zero-change parity, and scope parity across all three lookups
- `test/threadline/investigation_test.exs` - migrated `transaction_context/2` assertions to the tuple shape
- `test/threadline/storage_schema_integration_test.exs` - migrated one `transaction_context/2` call site to the tuple shape
- `test/threadline/query_test.exs` - migrated one `transaction_context/2` pattern match to the tuple shape
- `test/threadline/query/action_hydration_test.exs` - migrated `transaction_context/2` call and dropped `surface:`/`params:` from an `incident_bundle/2` call
- `test/threadline/operator_surface/transaction_live_test.exs` - added the malformed-id not-found render test

## Decisions Made
- Shared `TransactionLookup.fetch/2` reuses the hydrated row for every returned change (`%{change | transaction: row}`) instead of preloading or re-hydrating actions a second time — the mechanism that keeps `incident_bundle/2` at or under 3 queries.
- Removed `Threadline.Investigation.linked_transaction/1`: it derived "the transaction" from the first linked change, which is exactly the bug this plan fixes (a zero-change transaction looked missing). The shared fetch makes the row authoritative instead.
- Left `transaction_context/2`/`incident_bundle/2` without a new `@doc since: "1.0.0"` tag (added one only to the two new bangs, matching the plan's D-08 instruction) — their return shape changed but they are not new functions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

All four single-subject lookups (`audit_transaction/2`, `transaction_context/2`, `incident_bundle/2`, and their bangs) now share one existence-and-changes fetch with proven scope/retention parity. Plan 03 can migrate remaining call sites (mix task, example app controller already match the tuple shape per the Plan 02 interfaces note) and update guides/CHANGELOG. Plan 04's fail-closed `Scope.apply/2` work needs no changes here — every scope fn written in this plan already has explicit `:transaction_header`/`:transaction` clauses, consistent with Plan 01's note.

Not run in this plan (deferred to phase-level verification after all plans land, per Plan 01's precedent): the wave-gate `mix ci.all`.

---
*Phase: 233-lookup-return-shapes*
*Completed: 2026-10-04*

## Self-Check: PASSED

- All `key-files.modified` present on disk (no new files created this plan).
- All three commits (`ae5595b4`, `a68981b0`, `224554d6`) found in `git log`.
- All `<acceptance_criteria>` from all three tasks re-verified (greps + each task's `<verify>` commands) — pass.
- Plan-level `<verification>` re-run: `mix test test/threadline/transaction_lookup_test.exs test/threadline/investigation_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/query_test.exs test/threadline/query/action_hydration_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/retention_test.exs` (180 tests, 0 failures), `mix test test/threadline/source_size_contract_test.exs` (18 tests, 0 failures), `mix compile --warnings-as-errors`, `mix verify.credo` (0 issues), `mix verify.example` (130 tests, 0 failures) — all exit 0.
- Wave gate `mix ci.all` not run in this plan (deferred to phase-level verification, matching Plan 01's precedent).
