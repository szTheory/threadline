---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
artifact: residual-ci
created: 2026-06-20
status: inherited-non-blocking
---

# Phase 180 Residual CI Classification

## Command

`mix ci.all`

## Current Result

`mix ci.all` exits non-zero, but Phase 180-owned regressions were fixed before closeout.

| Suite | Result | Classification |
|-------|--------|----------------|
| Root | 1120 tests, 1 failure, 1 excluded | Inherited non-blocking |
| Example | 95 tests, 7 failures | Inherited non-blocking |

## Phase 180-Owned Failures Fixed During Closeout

`mix ci.all` initially exposed six root failures in `test/threadline/operator_surface/live/retention_history_live_test.exs`. The failures were caused by Plan 180-01's intentional retention modal focus fix: the destructive prune form is mounted only after the modal opens, while older tests expected the form in the initial page HTML.

Fix:

- Tests now assert the prune form is not initially mounted.
- Tests open the `Run retention prune` modal through the CTA before asserting or submitting `form[phx-submit=prune_now]`.
- Focused verification passed: `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` -> 15 tests, 0 failures.
- Expanded guardrail verification passed: 189 tests, 0 failures.

## Inherited Residuals

These match the Phase 179 residual failure families and are outside A11Y-01, A11Y-02, MOTION-01, and MOTION-02.

| File/Test | Current Shape | Phase 179 Baseline |
|-----------|---------------|--------------------|
| `test/threadline/v1_23_charter_doc_contract_test.exs:15` | `PROJECT.md` does not contain older "has now opened milestone..." wording. | Listed in `179-VERIFICATION.md` and `deferred-items.md`. |
| `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` | No hero #4521 close transaction found for evidence walkthrough. | Listed in Phase 179 residuals. |
| `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs:215` | Expected hard-delete timestamp/evidence missing for #4518. | Listed in Phase 179 residuals. |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:40` | No #4521 close transaction for `ticket_replied_and_closed`. | Listed in Phase 179 residuals. |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:70` | No #4521 close transaction for redacted reply insert. | Listed in Phase 179 residuals. |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:105` | Leaving-agent audit transaction count is 0 instead of 12. | Listed in Phase 179 residuals. |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:156` | No #4518 delete incident row found at expected timestamp. | Listed in Phase 179 residuals. |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:269` | No `org_memberships` actor attribution row found. | Listed in Phase 179 residuals. |

One prior run also produced a timeout in `test/mix/tasks/threadline_evidence_show_example_test.exs:20` during demo seed setup. The final closeout run did not reproduce that timeout; it remains part of the inherited example seed/walkthrough instability family already recorded by Phase 179.

## Classification

No current `mix ci.all` failure is owned by Phase 180 after the retention test repair. The remaining failures are inherited documentation/demo-seed contract failures, unchanged in ownership from Phase 179, and do not contradict the Phase 180 accessibility, APG, motion, guardrail, screenshot, or adversarial evidence.
