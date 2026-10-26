---
phase: 233-lookup-return-shapes
plan: 04
subsystem: api
tags: [ecto, elixir, security, scoping, docs, changelog]

requires:
  - phase: 233-lookup-return-shapes
    provides: "Plan 01-03's shared TransactionLookup (fetch_row/2, fetch/2, scoped_row/4) and the final audit_transaction/2,!/2, transaction_context/2,!/2, incident_bundle/2,!/2 facade specs — every one of those read paths goes through Scope.apply/2"
provides:
  - "Threadline.Query.Scope.apply/2 fails closed: a non-nil :scope with no 3-arity :scope_query_fn, or any non-3-arity :scope_query_fn, raises ArgumentError without ever echoing the scope value"
  - "test/threadline/query/scope_fail_closed_test.exs: a matrix proving every scoped read (timeline, timeline_page, row_history list/cursor, actor_history, actor_window, correlation_bundle, audit_changes_for_transaction, audit_transaction, transaction_context, incident_bundle, export_csv, export_json) and the three bangs raise on misconfiguration and stay unscoped (fn never called) on a deliberate nil scope"
  - "Operator-surface coverage: a LiveView mount with a scope and no scope_query_fn crashes instead of rendering unscoped rows; authorize_fn :ok with a scope_query_fn configured still renders unscoped; the export controller raises instead of streaming unscoped rows"
  - "Reference app scope_operator_query/3 catch-all denies (where(query, [], false)) instead of falling through unscoped"
  - "guides/integration-contracts.md \"Scope surfaces and fail-closed rules\" subsection naming every surface/binding including :transaction_header's single [at] binding"
  - "CHANGELOG Unreleased Breaking changes bullet for the fail-closed scope break"
affects: []

actuals:
  tokens: 7500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Scope.apply/2's cond now orders the wrong-arity check before the nil-scope check, so a wrong-arity scope_query_fn always raises regardless of :scope — a bad function is a wiring mistake independent of whether a scope happens to be nil that call."
    - "Fail-closed matrix tests use a marker fn (sends itself a message, returns the query unchanged) to assert both 'the fn fires and filters' and 'the fn is never called on a deliberate nil scope' from the same helper."
    - "Catching a LiveView mount's crash from a Task.async'd query requires catch_exit/1 around the second (post-redirect) live/2 call, not assert_raise — the Task crash reaches the test process as a linked exit signal, not a normal raise."

key-files:
  modified:
    - lib/threadline/query/scope.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - test/partition_weights.txt
    - guides/integration-contracts.md
    - CHANGELOG.md
  created:
    - test/threadline/query/scope_fail_closed_test.exs

key-decisions:
  - "A :scope_query_fn that is not 3-arity raises ArgumentError even when :scope is nil — checked first in the cond, ahead of the nil-scope branch — because a malformed function is always a wiring mistake, never a legitimate configuration, regardless of whether this particular call happens to carry a scope."
  - "The ArgumentError message for a scope-without-fn never interpolates the scope value (only names the missing-fn problem and names :scope_query_fn / scope: nil as the fix); a test asserts a distinctive scope value never appears in the raised message."
  - "The example app's :transaction_header scope clause already existed from Plan 03 — only the final catch-all needed tightening from a transparent pass-through to a deny-all where(query, [], false), since Threadline.OperatorSurface.Router's :where/3 import (not :where/2) is what the example app has in scope."
  - "LiveView mount-crash assertions use catch_exit/1 on the second (post-canonicalization push_patch) live/2 call, matching the existing mount_audit redirect-follow idiom used throughout timeline_live_test.exs, rather than assert_raise, because the scoped query executes inside a linked Task.async and its crash propagates to the caller as a process exit, not a raise the calling frame can catch directly."

requirements-completed: [API-06]

coverage:
  - id: D1
    description: "Threadline.Query.Scope.apply/2 raises ArgumentError for a non-nil :scope with no 3-arity fn and for any non-3-arity fn, without ever interpolating the scope value; a nil scope stays the only branch returning the query unchanged"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/query/scope_fail_closed_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every scoped read and both operator-surface transports (LiveView mount, export controller) fail closed on a misconfigured scope; a nil scope with a configured fn reads unscoped and never calls the fn"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/query/scope_fail_closed_test.exs, test/threadline/operator_surface/live/timeline_live_test.exs, test/threadline/operator_surface/controllers/export_controller_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The reference app's scope_operator_query/3 denies unrecognized scopes instead of falling through unscoped"
    requirement: API-06
    verification:
      - kind: unit
        ref: "mix verify.example"
        status: pass
      - kind: other
        ref: "grep -n \"def scope_operator_query(query, _scope, _context), do: query\" examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex (expected: no match)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The guide names every scope surface/binding including :transaction_header, states the fail-closed rules, and warns about a permissive catch-all; the CHANGELOG records the break with required action"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/integration_contracts_doc_contract_test.exs, test/threadline/changelog_contract_test.exs, test/threadline/facade_only_references_contract_test.exs"
        status: pass
      - kind: other
        ref: "bash -c 'grep -q \":transaction_header\" guides/integration-contracts.md && grep -q \"where(query, false)\" guides/integration-contracts.md && grep -q \"scope_query_fn\" CHANGELOG.md'"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix ci.all is green at phase close"
    requirement: API-06
    verification:
      - kind: other
        ref: "mix ci.all (32 properties, 2952 ExUnit tests, 0 failures; Dialyzer passed; browser lane 318 passed/26 skipped — matches the committed CI-mode baseline)"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-10-04
status: complete
---

# Phase 233 Plan 04: Fail-Closed Scope.apply/2 and Phase Close Summary

**Threadline.Query.Scope.apply/2 now raises ArgumentError instead of silently reading every tenant's rows whenever a scope is given without a usable 3-arity scope_query_fn, proven across every scoped read and both operator-surface transports, with the reference app's catch-all tightened to deny and the break documented.**

## Performance

- **Duration:** ~55 min
- **Tasks:** 3/3
- **Files modified:** 7, created: 1

## Accomplishments

- `lib/threadline/query/scope.ex`'s `apply/2` fails closed: a `:scope_query_fn` that is not a 3-arity function always raises `ArgumentError` (checked first, regardless of `:scope`); a non-nil `:scope` with no function raises `ArgumentError` naming `:scope_query_fn` / `scope: nil` as the fix and never echoing the scope value; a `nil` scope is the only remaining pass-through — the host's explicit unscoped authorization — and the function is never called when scope is `nil`.
- `test/threadline/query/scope_fail_closed_test.exs` (new, 21 tests) proves the rule through `timeline/2` directly (Task 1, tracer) and then across every other scoped read: `timeline_page/2`, `row_history/3` (list and `cursor: :start`), `actor_history/2`, `actor_window/3`, `correlation_bundle/3`, `audit_changes_for_transaction/2`, `audit_transaction/2`, `transaction_context/2`, `incident_bundle/2`, `export_csv/2`, `export_json/2`, plus the three `!` bangs (`audit_transaction!/2`, `transaction_context!/2`, `incident_bundle!/2`) raising `ArgumentError` — not `NotFoundError` — for the same misconfiguration.
- Operator-surface coverage added to the existing test files rather than a new router/endpoint pattern: `timeline_live_test.exs` gained a router+endpoint where `authorize_fn` returns a scope with no `scope_query_fn` configured (the mount crashes via a linked `Task.async` exit, caught with `catch_exit/1`) and a second router+endpoint where `authorize_fn` returns `:ok` with a `scope_query_fn` still configured (renders unscoped, fn never called — proven with a deny-all marker fn). `export_controller_test.exs` gained the matching case for the HTTP export path (raises instead of streaming a 200 with unscoped rows).
- The reference app's `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` `scope_operator_query/3` final clause changed from a transparent `do: query` pass-through to `do: where(query, [], false)` — a scope none of the earlier clauses recognize now reads nothing. The `:transaction_header` clause itself already existed from Plan 03.
- `guides/integration-contracts.md` gained a "Scope surfaces and fail-closed rules" subsection: a table of all six surfaces (`:timeline`, `:transaction`, `:export`, `:row_history`, `:actor_history`, `:transaction_header`) and their binding shapes, the three fail-closed rules, and a warning that a permissive catch-all leaks another tenant's `:transaction_header` row. The existing "pair it with `scope_query_fn`" sentence was reworded to say a returned scope *requires* one, while keeping every phrase the doc-contract test pins.
- `CHANGELOG.md` Unreleased → Breaking changes gained one bullet naming every affected read and the required action (pair a non-nil scope with a 3-arity fn, or pass `scope: nil`; end `scope_query_fn` with a deny-all clause).
- Phase-close gate: `mix ci.all` is green — 32 properties / 2952 ExUnit tests / 0 failures, Dialyzer passed cleanly (no PLT rebuild needed), browser lane 318 passed / 26 skipped (matches the committed CI-mode baseline exactly, no new or missing failures).

## Task Commits

1. **Task 1: Tracer — fail-closed Scope.apply/2 proven through Threadline.timeline/2, then the existing suite reconciled** - `5469f8de` (test)
2. **Task 2: Fail-closed matrix on every scoped read and the operator surface; tighten the example catch-all** - `b22cd02a` (test)
3. **Task 3: Integration-contracts guide, CHANGELOG breaking entry, phase-close gate** - `5432f72e` (docs)

**Plan metadata:** pending (this SUMMARY's commit)

## Files Created/Modified

- `lib/threadline/query/scope.ex` - `apply/2` reordered into a fail-closed `cond`: wrong-arity fn raises first, then non-nil scope with no fn raises, then nil scope passes through unchanged, then the fn is called
- `test/threadline/query/scope_fail_closed_test.exs` (new) - the full fail-closed matrix: Task 1's tracer cases via `timeline/2`, Task 2's per-read matrix, and the three bang-raises-ArgumentError cases
- `test/threadline/operator_surface/live/timeline_live_test.exs` - two new router/endpoint pairs (`ScopeNoFnRouter`/`Endpoint`, `NilScopeWithFnRouter`/`Endpoint`) and two new test modules covering the mount-crash and nil-scope-stays-unscoped cases
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - one new router/endpoint pair and test module covering the export-controller misconfiguration case
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - `scope_operator_query/3` catch-all tightened to deny-all
- `test/partition_weights.txt` - weight entry for the new test file
- `guides/integration-contracts.md` - reworded scope-requirement sentence + new "Scope surfaces and fail-closed rules" subsection
- `CHANGELOG.md` - Breaking changes bullet for the fail-closed scope break

## Deviations from Plan

None — plan executed as written. Two implementation details were left to discretion per the plan's "Claude's Discretion" section and are recorded above: the exact `ArgumentError` wording, and routing the operator-surface/export-controller test cases into the existing test files (as the plan explicitly permitted) rather than a dedicated new test file, since the LiveView and controller test harness (routers, endpoints, `OperatorSurfaceCase`) could not be reached cleanly from `scope_fail_closed_test.exs`.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None — this plan closes threat T-233-13 (critical, fail-open `Scope.apply/2`), T-233-14 (high, permissive example catch-all), and T-233-15 (medium, scope value in error message), all per the plan's `<threat_model>`. No new surface was introduced.

## Self-Check: PASSED

- `lib/threadline/query/scope.ex` exists and contains two `raise ArgumentError` call sites — confirmed.
- `test/threadline/query/scope_fail_closed_test.exs` exists (21 tests, 0 failures on last run) — confirmed.
- Commits `5469f8de`, `b22cd02a`, `5432f72e` all present in `git log --oneline` — confirmed.
- All three plan-level `<acceptance_criteria>` lists re-verified: scope.ex has two raise sites and no `inspect(scope)`; the test file references every listed function name; the example router's old catch-all string is absent; `test/partition_weights.txt` has the new line; the guide contains `:transaction_header`, `[at]`, `ArgumentError`, `where(query, false)`; the CHANGELOG bullet contains `:scope_query_fn`, `ArgumentError`, `Required action:`; `grep -rnE "D-[0-9]{2}|API-06|Phase 233" lib guides CHANGELOG.md` prints nothing.
- Plan-level `<verification>` re-run: `mix test test/threadline/query/scope_fail_closed_test.exs test/threadline/operator_surface test/threadline/integration_contracts_doc_contract_test.exs test/threadline/changelog_contract_test.exs` exits 0; `mix compile --warnings-as-errors`, `MIX_ENV=test mix compile --warnings-as-errors --force`, `mix verify.credo`, `mix verify.example` all exit 0; `mix ci.all` exits 0.
