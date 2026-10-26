---
phase: 233-lookup-return-shapes
plan: 01
subsystem: api
tags: [ecto, elixir, lookup, error-handling, plug]

requires:
  - phase: 232-consolidated-reads-deprecations-and-the-bounded-default
    provides: per-function option allowlist pattern (ArgumentError on unknown keys), deprecation-delegate conventions
provides:
  - "Threadline.Query.TransactionLookup (hidden): validate_opts!/2, resolve_id/1, fetch_row/2 — the one shared existence check Plans 02/03 build transaction_context/incident_bundle on"
  - "Threadline.audit_transaction/2 on the facade: {:ok, %AuditTransaction{}} | {:error, :not_found}, .action always hydrated"
  - "Threadline.audit_transaction!/2 raising the new Threadline.NotFoundError"
  - "Threadline.NotFoundError: public, grouped, Plug.Exception-mapped (404), moduledoc'd exception"
affects: [233-02-facade-lookups-and-bangs, 233-03-call-site-migration-and-guides, 233-04-fail-closed-scope]

actuals:
  tokens: 5740
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Shared hidden existence fetch (Threadline.Query.TransactionLookup.fetch_row/2): row-first, scope-surfaced (hardcoded surface: :transaction_header, never caller-relabelled), hydrate .action unconditionally, no rescue around the repo call"
    - "Public NotFoundError exception pattern: defexception [:resource, :id] + defimpl Plug.Exception, message built only from resource + inspect(id), never row data"

key-files:
  created:
    - lib/threadline/query/transaction_lookup.ex
    - lib/threadline/not_found_error.ex
    - test/threadline/transaction_lookup_test.exs
    - test/threadline/not_found_error_test.exs
  modified:
    - lib/threadline.ex
    - mix.exs
    - test/threadline/public_surface_contract_test.exs
    - test/partition_weights.txt

key-decisions:
  - "D-09/D-10: existence decided by Threadline.Query.TransactionLookup.fetch_row/2 alone, scoped with a hardcoded surface: :transaction_header (single [at] binding) and params built internally — :surface/:params/:preload are rejected by the option allowlist, so a caller cannot relabel the binding shape or leak existence across tenants."
  - "D-15: no rescue around the repo call in fetch_row/2 — an invalid :storage_schema still raises ArgumentError and a nonexistent schema still raises Postgrex's undefined_table; only a genuinely absent/scope-filtered row becomes :not_found."
  - "D-17: Threadline.NotFoundError's message is built only from resource and inspect(id); proven byte-equal between a scope-rejected row and a genuinely missing row in the same test, with a negative assertion that a distinctive row value never appears in the message."

requirements-completed: [API-06]

coverage:
  - id: D1
    description: "Threadline.audit_transaction/2 returns {:ok, txn} for an existing/visible row and {:error, :not_found} for missing, scope-filtered, or malformed-binary ids, via the shared hidden fetch"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#audit_transaction/2"
        status: pass
    human_judgment: false
  - id: D2
    description: "Threadline.audit_transaction!/2 raises Threadline.NotFoundError on absence, returns the bare struct on success, and leaks nothing but the caller's id"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/transaction_lookup_test.exs#audit_transaction!/2"
        status: pass
      - kind: unit
        ref: "test/threadline/not_found_error_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Threadline.NotFoundError is public, grouped under Core API, carries since: 1.0.0, and implements Plug.Exception (404, no actions)"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/public_surface_contract_test.exs#Threadline.NotFoundError is visible, grouped, and carries since 1.0.0"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-10-04
status: complete
---

# Phase 233 Plan 01: Shared Existence Fetch and audit_transaction/! Summary

**Threadline.audit_transaction/2 and audit_transaction!/2 on the facade, built on one hidden hardcoded-surface row fetch, plus the new public Threadline.NotFoundError (404-mapped via Plug.Exception).**

## Performance

- **Duration:** 55 min
- **Started:** 2026-10-04T00:00:00Z
- **Completed:** 2026-10-04T00:55:00Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- New hidden module `Threadline.Query.TransactionLookup` with `validate_opts!/2`, `resolve_id/1`, `fetch_row/2` — the single existence check every transaction lookup in this phase shares
- `Threadline.audit_transaction/2` on the facade returning `{:ok, %AuditTransaction{}} | {:error, :not_found}`, with `.action` always hydrated and a malformed-binary id treated as not-found rather than a 500
- New public `Threadline.NotFoundError` exception implementing `Plug.Exception` (404), plus `Threadline.audit_transaction!/2` that raises it
- Option allowlist (`:repo`, `:storage_schema`, `:scope`, `:scope_query_fn`) enforced on both the plain and bang forms; `:surface`, `:params`, and `:preload` all raise

## Task Commits

1. **Task 1: Tracer — Threadline.audit_transaction/2 through the hidden scoped row fetch, end to end** - `b8f49e3a` (feat)
2. **Task 2: Threadline.NotFoundError, audit_transaction!/2, public-surface pin and partition weights** - `e2e3c6a1` (feat)
3. **Post-handoff fix: drop planning-vocabulary ids from a lib/ comment** - `daa1b360` (fix)

**Plan metadata:** pending (this commit)

_Note: both tasks were `tdd="true"`; each commit carries its RED test file plus the GREEN implementation as one task-scoped commit per the plan's instructions, not separate RED/GREEN commits._

## Files Created/Modified
- `lib/threadline/query/transaction_lookup.ex` - hidden shared existence fetch (`validate_opts!/2`, `resolve_id/1`, `fetch_row/2`)
- `lib/threadline/not_found_error.ex` - public `Threadline.NotFoundError` + `Plug.Exception` impl
- `lib/threadline.ex` - `audit_transaction/2` and `audit_transaction!/2` added to the facade
- `mix.exs` - `Threadline.NotFoundError` added to the "Core API" docs group
- `test/threadline/transaction_lookup_test.exs` - new, covers both facade functions
- `test/threadline/not_found_error_test.exs` - new, covers message/status/actions
- `test/threadline/public_surface_contract_test.exs` - pin test for `Threadline.NotFoundError`
- `test/partition_weights.txt` - weight entries for both new test files

## Decisions Made
- Hardcoded `surface: :transaction_header` and `params: %{transaction_id: id}` inside `fetch_row/2` rather than accepting them from `opts` — this is what makes `:surface`/`:params` rejectable by the allowlist without weakening the scope contract (D-10, D-13).
- `fetch_row/2` does not call `validate_opts!/2` itself; each facade caller validates first with its own function name in the error message, keeping the hidden fetch name-agnostic for Plans 02/03.
- No `rescue` anywhere in the new module, per D-15 — a misconfigured `:storage_schema` must stay loud.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dropped planning-vocabulary decision ids from a lib/ comment**
- **Found during:** Post-Task-2 self-check (grep for `D-[0-9]`, `Phase 233`, `API-06` under `lib/`)
- **Issue:** `lib/threadline/query/transaction_lookup.ex`'s `fetch_row/2` doc comment named internal decision ids (`D-14`, `D-15`, `D-19`), violating the project's "no planning vocabulary in lib/" rule (D-21 / CLAUDE.md).
- **Fix:** Reworded the comment to explain the same hydration/no-rescue/no-telemetry behavior without the decision ids.
- **Files modified:** `lib/threadline/query/transaction_lookup.ex`
- **Verification:** `grep -rn "D-[0-9]\{2\}\|Phase 233\|API-06" lib/ guides/ CHANGELOG.md` returns nothing; `mix compile --warnings-as-errors` and `mix test test/threadline/transaction_lookup_test.exs` still pass.
- **Committed in:** `daa1b360`

---

**Total deviations:** 1 auto-fixed (1 bug — self-caught before handoff).
**Impact on plan:** Comment-only fix; no behavior change. No scope creep.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

`Threadline.Query.TransactionLookup.fetch_row/2` and `validate_opts!/2` are ready for Plan 02 to build `transaction_context/2`, `incident_bundle/2`, and their `!` siblings on top of. `Threadline.NotFoundError` is ready for reuse with `resource: :audit_transaction` from those two lookups as well.

Not run in this plan (deferred to phase-level verification after all four plans land): the wave-gate `mix ci.all`, and the D-20 fail-closed `Scope.apply/2` work (Plan 04) — this plan's scope fns are written to the pre-existing fail-open behavior and will need no changes once D-20 lands, since every scope fn here already has an explicit `:transaction_header` clause.

---
*Phase: 233-lookup-return-shapes*
*Completed: 2026-10-04*

## Self-Check: PASSED

- All `key-files.created` present on disk.
- All three commits (`b8f49e3a`, `e2e3c6a1`, `daa1b360`) found in `git log`.
- All `<acceptance_criteria>` from both tasks re-verified (greps + both `<verify>` commands per task) — pass.
- Plan-level `<verification>` re-run: `mix test test/threadline/transaction_lookup_test.exs test/threadline/not_found_error_test.exs test/threadline/public_surface_contract_test.exs test/threadline/ci_topology_contract_test.exs` (93 tests, 0 failures), `mix test test/threadline/source_size_contract_test.exs` (18 tests, 0 failures), `mix compile --warnings-as-errors`, `mix verify.credo` (0 issues), `MIX_ENV=dev mix docs --warnings-as-errors` — all exit 0.
- Wave gate `mix ci.all` not run in this plan (deferred to phase-level verification; see Next Phase Readiness).
