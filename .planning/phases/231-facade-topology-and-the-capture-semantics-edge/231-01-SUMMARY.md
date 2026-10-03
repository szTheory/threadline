---
phase: 231-facade-topology-and-the-capture-semantics-edge
plan: 01
subsystem: database
tags: [ecto, postgres, api-surface, deprecation]

requires:
  - phase: none
    provides: "230 (prior phase) — no direct dependency; this plan edits capture/semantics schemas and the exploration-layer query/investigation modules directly"
provides:
  - "Threadline.Query.hydrate_actions/3 — hidden, batched replacement for the removed capture/semantics Ecto associations"
  - "AuditTransaction with no belongs_to :action (explicit action_id + virtual action field)"
  - "AuditAction with no has_many :transactions"
  - "Deprecated but working :preload shim for :action / transaction: :action on the two public Query functions"
affects: ["232 (retiring other internal helper names)", "233 (lookup return shapes)", "234 (typespec/doc gate)"]

actuals:
  tokens: 7927
  tasks: 3
  commits: 6
  plan_head_before: 81a96044fd20934624edb7f3a859d416dc7a4b6e
  plan_head_after: c382a93709a47932bed0beef768e1566bac3f25b

tech-stack:
  added: []
  patterns:
    - "Hidden @doc false batched hydrate helper replacing a direct Ecto association (dedupe ids, one WHERE id IN query, thread storage_opts/2)"
    - "Deprecated public option: extract the deprecated key before validation, warn once via IO.warn, delegate the remainder to the existing code path, then hydrate separately"

key-files:
  created:
    - test/threadline/query/action_hydration_test.exs
    - test/threadline/capture_semantics_boundary_test.exs
  modified:
    - lib/threadline/query.ex
    - lib/threadline/investigation.ex
    - lib/threadline/capture/audit_transaction.ex
    - lib/threadline/semantics/audit_action.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - test/threadline/query_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - CHANGELOG.md

key-decisions:
  - "hydrate_actions/3 lives inside query.ex (not a separate submodule) — it is small and sits next to the storage_opts/2 pattern it reuses"
  - "Internal call sites (Investigation.transaction_context/2, incident_bundle/2) strip :preload from caller opts and call Query.hydrate_actions/3 directly, never routing through the now-deprecated public :preload shim, so internal reads never emit the deprecation warning"
  - "The deprecation warning is IO.warn/1, matching D-10's 'Claude's discretion, runtime analogue of @deprecated'"

requirements-completed: [API-07]

coverage:
  - id: D1
    description: "AuditTransaction and AuditAction declare no Ecto association to each other; AuditTransaction keeps an explicit action_id field and a virtual action field"
    requirement: "API-07"
    verification:
      - kind: unit
        ref: "test/threadline/capture_semantics_boundary_test.exs#AuditTransaction declares no :action association"
        status: pass
      - kind: unit
        ref: "test/threadline/capture_semantics_boundary_test.exs#AuditAction declares no :transactions association"
        status: pass
    human_judgment: false
  - id: D2
    description: "Threadline.Query.hydrate_actions/3 batches .action hydration in exactly one query, dedupes, preserves order, honors the storage-schema prefix, and raises when an AuditChange's :transaction is not preloaded"
    requirement: "API-07"
    verification:
      - kind: unit
        ref: "test/threadline/query/action_hydration_test.exs#hydrate_actions/3"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every internal :action reader (preload_investigation_context/3, transaction_context/2, incident_bundle/2, TimelineLive.preload_visible_context/3, TransactionLive.mount/3) hydrates through hydrate_actions/3 with every pre-existing .action assertion unchanged"
    requirement: "API-07"
    verification:
      - kind: unit
        ref: "test/threadline/investigation_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/storage_schema_integration_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/live/timeline_live_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/transaction_live_test.exs"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/threadline.incident_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "Public :preload values naming :action keep working with exactly one deprecation warning per call; a nested key under :action raises ArgumentError before any repo.preload call; internal call paths stay silent"
    requirement: "API-07"
    verification:
      - kind: unit
        ref: "test/threadline/query/action_hydration_test.exs#deprecated :action preload"
        status: pass
    human_judgment: false
  - id: D5
    description: "CHANGELOG documents the NotLoaded -> nil breaking change and the :preload deprecation; no migration/trigger_sql/priv file changed"
    requirement: "API-07"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
      - kind: other
        ref: "git diff --quiet 0e5eda11 -- lib/threadline/capture/migration.ex lib/threadline/semantics/migration.ex lib/threadline/capture/trigger_sql.ex priv"
        status: pass
    human_judgment: false

duration: 70min
completed: 2026-10-03
status: complete
---

# Phase 231 Plan 01: Facade Topology and the Capture/Semantics Edge Summary

**Dropped the `AuditTransaction belongs_to :action` / `AuditAction has_many :transactions` Ecto associations and replaced `.action` hydration with a hidden, batched `Threadline.Query.hydrate_actions/3`, keeping every reader's `.action` shape (including the deprecated public `:preload` path) working.**

## Performance

- **Duration:** 70 min
- **Started:** 2026-10-03T13:57:00Z
- **Completed:** 2026-10-03T15:07:00Z
- **Tasks:** 3 completed
- **Files modified:** 11 (2 new test files, 9 modified)

## Accomplishments

- `Threadline.Query.hydrate_actions/3` (`@doc false`): accepts `nil`, a single `AuditTransaction`/`AuditChange`, or a list of either; dedupes non-nil `action_id`s; issues exactly one `WHERE id IN ^ids` query against `audit_actions`; threads `storage_opts/2` so the caller-selected storage schema is honored; raises `ArgumentError` when an `AuditChange`'s `:transaction` is not preloaded.
- `AuditTransaction` no longer declares `belongs_to :action` — it declares an explicit `field(:action_id, :binary_id)` plus a virtual `field(:action, :any, default: nil)`; `AuditAction` no longer declares `has_many :transactions`. `@type t` stays a bare `%__MODULE__{}`. No migration, trigger SQL, or `priv/` file changed.
- Every internal `:action` reader (`preload_investigation_context/3`, `Investigation.transaction_context/2`, `Investigation.incident_bundle/2`, `TimelineLive.preload_visible_context/3`, `TransactionLive.mount/3`) now routes through `hydrate_actions/3` directly — never through the deprecated public `:preload` path — with every pre-existing `.action` assertion passing unchanged.
- Public `:preload` values naming `:action` (`audit_transaction/2`'s bare `:action` / `[:action, ...]`, `audit_changes_for_transaction/2`'s `transaction: :action` / `transaction: [:action, ...]`) still work, still hydrate `.action`, and now emit exactly one `IO.warn` deprecation message per call naming `Threadline.transaction_context/2` and `Threadline.incident_bundle/2` as the replacement. A nested key under `:action` (e.g. `action: :x`) raises `ArgumentError` before any `repo.preload` call.
- CHANGELOG.md's "Unreleased — highlights" section gained a "### Breaking changes" entry (un-hydrated `.action` is now `nil`, not `%Ecto.Association.NotLoaded{}`) and a "### Deprecations" entry for the `:preload` shim.

## Task Commits

Each task was committed as a RED test commit followed by a GREEN implementation commit (TDD):

1. **Task 1: Tracer — hidden hydrate helper wired through `preload_investigation_context` end-to-end**
   - `a540f171` `test(231-01): add failing coverage for Query.hydrate_actions/3`
   - `1c72cf50` `feat(231-01): implement Query.hydrate_actions/3 as the hidden action hydrate helper`
2. **Task 2: Drop both associations and switch every remaining internal `:action` site to the helper**
   - `e5ace322` `test(231-01): add failing boundary test for dropped capture/semantics associations`
   - `45592663` `feat(231-01): drop capture/semantics associations, route internal readers through hydrate_actions/3`
3. **Task 3: Deprecation shim for public `:preload` values naming the action, plus CHANGELOG**
   - `d13fdd2a` `test(231-01): add failing coverage for the deprecated :action preload shim`
   - `c382a937` `feat(231-01): add deprecated :action preload shim and CHANGELOG entry`

**Plan metadata:** (this commit)

_Note: every task followed RED → GREEN; no REFACTOR commit was needed — each GREEN implementation was already the minimal, final shape._

## Files Created/Modified

- `lib/threadline/query.ex` — `hydrate_actions/3` (new, `@doc false`); `preload_investigation_context/3` rewritten to preload only `:transaction` then hydrate; `audit_transaction/2` and `audit_changes_for_transaction/2` gained the `:action`-preload deprecation shim (`extract_action_preload/1`, `extract_transaction_action_preload/1`, `extract_nested_transaction_action/2`, `maybe_warn_deprecated_action_preload/1`)
- `lib/threadline/investigation.ex` — `transaction_context/2` and `incident_bundle/2` strip `:preload` from caller opts and call `Query.hydrate_actions/3` directly
- `lib/threadline/capture/audit_transaction.ex` — `belongs_to(:action, ...)` replaced with `field(:action_id, :binary_id)` + virtual `field(:action, :any, default: nil)`; moduledoc "Relationships" section rewritten
- `lib/threadline/semantics/audit_action.ex` — `has_many(:transactions, ...)` removed
- `lib/threadline/operator_surface/live/timeline_live.ex` — `preload_visible_context/3` preloads `:transaction` then hydrates via `Threadline.Query.hydrate_actions/3`
- `lib/threadline/operator_surface/live/transaction_live.ex` — `mount/3` drops the now-redundant `preload: :action` option
- `test/threadline/query/action_hydration_test.exs` (new) — `hydrate_actions/3` behavior (8 tests) + deprecated `:action` preload shim (9 tests)
- `test/threadline/capture_semantics_boundary_test.exs` (new) — association-absence tests (SC3, D-13 mutation control target)
- `test/threadline/query_test.exs` — literal-source assertion updated to the new `preload_investigation_context/3` body
- `test/threadline/operator_surface/live/timeline_live_test.exs` — literal-source assertion updated to the new `preload_visible_context/3` body
- `CHANGELOG.md` — "Unreleased — highlights" gained Breaking changes + Deprecations entries

## D-13 Mutation Control Record

Per Task 2's acceptance criteria, re-adding the removed association was proven to turn the boundary test red:

```
$ (reverted field(:action_id, :binary_id) / field(:action, :any, ...) back to
   belongs_to(:action, Threadline.Semantics.AuditAction) in
   lib/threadline/capture/audit_transaction.ex)
$ mix test test/threadline/capture_semantics_boundary_test.exs
...
  1) test ... AuditTransaction keeps an explicit :action_id field and a virtual :action field
     Assertion with in failed
     code:  assert :action in AuditTransaction.__schema__(:virtual_fields)
     left:  :action
     right: []

  2) test ... AuditTransaction declares no :action association
     Refute with in failed
     code:  refute :action in AuditTransaction.__schema__(:associations)
     left:  :action
     right: [:action, :changes]

4 tests, 2 failures
```

Restored to `field(:action_id, :binary_id)` + virtual `field(:action, :any, default: nil)` and reconfirmed green (`4 tests, 0 failures`).

## Decisions Made

- `hydrate_actions/3` stays inside `query.ex` rather than a new submodule — it is small, reuses `storage_opts/2`'s exact threading pattern, and keeps the existing `@doc false` precedent in one file.
- Internal callers (`Investigation.transaction_context/2`, `incident_bundle/2`) call `Query.hydrate_actions/3` directly instead of routing through the public, now-deprecated `:preload` shim — this was the one ambiguity 231-PATTERNS.md flagged between D-09 and D-10, resolved in favor of "internal sites never trip their own deprecation warning."
- Deprecation mechanism: `IO.warn/1`, per D-10's "Claude's discretion... runtime analogue of the `@deprecated` compile warning."

## Deviations from Plan

None - plan executed exactly as written. The one noted risk from 231-PATTERNS.md (D-09/D-10 internal-vs-public-shim collision) was resolved as flagged in the plan's own guidance (internal sites call the hidden helper directly) and is recorded above as a decision, not a deviation.

## Known Stubs

None — no stub patterns introduced. All hydrate paths read real `audit_actions` rows.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- API-07 is satisfied: capture and semantics schemas carry no cross-layer Ecto association, every internal and public `.action` reader hydrates through the same hidden helper, and the deprecated `:preload` path is covered by tests and documented in the CHANGELOG.
- `lib/threadline/capture/migration.ex`, `lib/threadline/semantics/migration.ex`, `lib/threadline/capture/trigger_sql.ex`, and `priv/` are untouched (verified via `git diff --quiet` against the phase base `0e5eda11`), so Plan 02/03 (API-04: hiding `Threadline.Query`/`Threadline.Investigation` from docs) can proceed without any capture/semantics schema conflict.
- Ready for 231-02.

---
*Phase: 231-facade-topology-and-the-capture-semantics-edge*
*Completed: 2026-10-03*
