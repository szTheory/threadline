---
phase: "232"
status: passed
verified: "2026-10-07"
source_commit: "81287560"
---

# Phase 232 — Current-source Regression Gate

All six plans were already complete. Source changes after the original report
made its fingerprint stale, so execution resumed at the verification gates.

## Current Evidence

| Gate | Result |
|------|--------|
| `mix ci.all` | Exit 0: root 3,047 tests and 32 properties, zero failures; example 132 tests, zero failures; Dialyzer clean; live Dialyzer slice passed; browser 318 passed, 26 expected skips |
| `MIX_ENV=test mix compile --warnings-as-errors --force` | Exit 0 |
| `mix verify.test --warnings-as-errors` | Exit 0: 3,047 tests and 32 properties, zero failures, 3 documented exclusions |
| Deprecation, facade naming and public-surface focused tests | 85 tests, zero failures after the documentation correction |
| `mix verify.format` | Exit 0 |
| `MIX_ENV=dev mix docs --warnings-as-errors` | Exit 0 |
| Phase-specific validation audit | Existing behavioral tests cover all five requirement IDs; no new tests needed |
| Independent code review | Clean after correcting the deprecated call's documented filter precedence |
| Security review | All 19 distinct planned threats closed; no new accepted risks |

The first `mix ci.all` attempt stopped when the workspace sandbox prevented Hex
from persisting its cache. The same canonical command passed with cache access.
Both complete-suite commands ran under a 600-second bound and exited normally.

## Prior-phase Coverage

Phase 231 is the only earlier phase in this milestone. Its verification report
names these 11 existing regression files; the canonical root/example suites
executed them along with the rest of the project:

- `examples/threadline_phoenix/test/threadline_phoenix/incident_replay_safety_test.exs`
- `test/mix/tasks/threadline.incident_test.exs`
- `test/threadline/capture_semantics_boundary_test.exs`
- `test/threadline/facade_only_references_contract_test.exs`
- `test/threadline/investigation_test.exs`
- `test/threadline/operator_surface/live/timeline_live_test.exs`
- `test/threadline/operator_surface/transaction_live_test.exs`
- `test/threadline/public_surface_contract_test.exs`
- `test/threadline/query/action_hydration_test.exs`
- `test/threadline/query_test.exs`
- `test/threadline/storage_schema_integration_test.exs`

## Scope Notes

The code-review resolver used a disclosed 123-file phase-range fallback. The
only resulting correction changed prose to match the approved legacy
filters-first behavior; runtime behavior and public API signatures are unchanged.

The visual-design hook is outside this API phase's scope and the repository's
operator-UI design constraint. Affected LiveView behavior was verified by
automated integration tests, with browser regression coverage from `mix ci.all`.
No human verification is outstanding.
