---
schema_version: 1
open_count: 0
waived_count: 40
fixed_count: 27
total_count: 67
last_updated: 2026-10-26T00:37:07.965Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 198 | unrun-verify | .github/workflows/flake-detection.yml |  | GREEN-11: the two-dispatch dedup demonstration (two runs writing to one ci-flake issue) could not be run -- workflow_dispatch requires the workflow on the remote default branch and plan 198-06 is forbidden to push. Classifier logic proven locally against four real captured logs; the live dedup path is unrun. | fixed |  | 2026-08-28T02:00:11.304Z | 2026-10-26T00:36:45.519Z |
| 2 | 198 | deviation | test/threadline/phase06_nyquist_ci_contract_test.exs |  | Pre-existing CONTRIBUTING.md List 1 drift (only-in-jobs=[verify-capture, verify-mechanical]) leaves this file red. Deferred and explicitly unowned in 198-TRIAGE.md; out of 198-06 scope, not auto-fixed. | fixed |  | 2026-08-28T02:00:18.816Z | 2026-08-28T14:32:17.826Z |
| 3 | 198 | deviation | .planning/phases/198-green-bringup/deferred-items.md |  | mix ci.all fails at verify.example (examples/threadline_phoenix DemoContractTest) - pre-existing, unrelated to storage_schema defect class, out of 198-12 scope | fixed |  | 2026-08-28T14:31:57.746Z | 2026-10-26T00:37:03.743Z |
| 4 | 198 | deviation | .planning/phases/198-green-bringup/198-13-SUMMARY.md |  | GREEN-07 not verified this run — local commits unpushed by explicit orchestrator constraint; origin/main CI still red on last observed run 33138291361 | fixed |  | 2026-08-28T14:45:38.316Z | 2026-10-26T00:37:03.814Z |
| 5 | 198 | deviation | .github/workflows/branch-protection.yml | 27 | CR-03 (WARNING, carried-forward): permissions: contents: read means the classic-protection-not-stacking check (block c) can't distinguish a real 403 (no admin scope) from a genuine absence, so it is unfalsifiable in CI; passed locally only because the operator token carries admin. | fixed |  | 2026-08-28T14:45:45.225Z | 2026-10-26T00:37:03.883Z |
| 6 | 198 | deviation | bin/verify-branch-protection | 95 | CR-04 (WARNING, carried-forward): the check-runs API call (block b) needs checks: read, same missing-scope root cause as CR-03; any API failure yields an empty EMITTED_COUNT which the pipeline treats as pass. Fails closed today so benign, but rests on the same fragile foundation. | fixed |  | 2026-08-28T14:45:47.085Z | 2026-10-26T00:37:03.956Z |
| 7 | 198 | deviation | .github/rulesets/main.json |  | CR-05 (WARNING, carried-forward): the checked-in ruleset snapshot is never diffed against live GitHub state, so a bypass_actor added via the UI or enforcement flipped to evaluate would pass all three verify-branch-protection blocks silently -- directly undermines the accepted merge lock predicated on bypass_actors: []. | waived | routed to v1.48 per 246-DEBT-REGISTER.md#W7 | 2026-08-28T14:45:48.828Z | 2026-10-26T00:37:04.029Z |
| 8 | 198 | deviation | .planning/phases/198-green-bringup/198-17-SUMMARY.md |  | verify.example_browser (desktop-chromium+mobile-chromium, full/unbounded) surfaces 28 pre-existing failures across 14 unrelated tests (find-mobile, phase-135/173/175/177-uat, screenshot-regression, screenshots, register) that CI's maxFailures:5 ceiling was masking -- previously invisible because the ceiling always aborted at the first 5. Unrelated to and not caused by this plan's 2-line fix (198-17); out of 198-17 scope; needs a follow-up gap-closure plan before the browser lane's next CI run can conclude success. | fixed |  | 2026-08-28T17:31:39.078Z | 2026-10-26T00:37:04.102Z |
| 9 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 655 | New discovery (plan 198-27): mobile-chromium-only focus flake on #stress-dropdown-button (opens stress rendered widgets test), out of scope for 198-27's declared files, unassigned cluster, needs follow-up diagnosis | waived | Not reproduced: the browser lane has run at exactly the 8 screenshot failures since phase 201, with this test passing on both projects (246-DEBT-REGISTER.md#W9) | 2026-08-28T22:34:01.414Z | 2026-10-26T00:37:04.175Z |
| 10 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 565 | New discovery (plan 198-28 post-merge re-validation): Exports queue Expired/File-unavailable text not found on both projects, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis | fixed |  | 2026-08-28T23:00:49.827Z | 2026-10-26T00:37:04.249Z |
| 11 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 38 | New discovery (plan 198-28 post-merge re-validation): exports dense state Expired/File-unavailable text not found on both projects, same shape as operator-accessibility.spec.ts:565 discovery, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis | fixed |  | 2026-08-28T23:00:55.589Z | 2026-10-26T00:37:04.328Z |
| 12 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 565 | CORRECTS entry #10: root cause established (plan 198-28 Task 3) — NOT a demo-seed content change (demo/seed/exports.ex was not touched by any plan this round). Actual cause: fix(198-25) commit e6f3cd5d changed the completed-expired export job's rendered label from Expired to Export expired (lowercase e), breaking this test's /Expired\|File unavailable/ regex (capital E). Still out of scope for 198-28's declared files; needs follow-up plan to update the regex/assertion to match the corrected canonical copy. | fixed |  | 2026-08-28T23:20:26.077Z | 2026-10-26T00:37:04.410Z |
| 13 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 38 | CORRECTS entry #11: same root cause as entry #12 (fix(198-25) commit e6f3cd5d's Expired to Export expired label change broke this file's /Expired\|File unavailable/ regex, capital E). Not a seed-content change. Still out of scope for 198-28's declared files; needs follow-up plan to update the assertion. | fixed |  | 2026-08-28T23:20:32.409Z | 2026-10-26T00:37:04.482Z |
| 14 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 108 | dense Timeline screenshot (both projects) left open per plan 198-28's Task 2 decision (no baseline regeneration). Diff spans the whole page layout (header + rows), not a single volatile field; visually consistent with the baseline predating multiple accumulated UI changes across prior phases, not this round's changes. Not maskable. See .planning/audits/198-round4-playwright.md cluster reconciliation. | waived | routed to SEED-008 per 246-DEBT-REGISTER.md#W14 | 2026-08-28T23:20:39.892Z | 2026-10-26T00:37:04.559Z |
| 15 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 115 | row-history drawer screenshot (both projects) left open per plan 198-28's Task 2 decision. Genuinely improved: locator was fixed from the full-viewport drawer container to the bounded .tl-drawer panel (desktop diff dropped from ratio 0.53 to 0.19, width now matches), but a residual height/content diff remains, not resolvable without baseline regeneration. See .planning/audits/198-round4-playwright.md. | waived | routed to SEED-008 per 246-DEBT-REGISTER.md#W15 | 2026-08-28T23:20:46.296Z | 2026-10-26T00:37:04.631Z |
| 16 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 127 | Exports screenshot (both projects) left open per plan 198-28's Task 2 decision. The getByRole assertion-rot cause was fixed (exact: true); the residual screenshot diff is a legitimate, already-shipped visual change from this round's own fix(198-25) e6f3cd5d (Expired -> Export expired label), which Task 2 explicitly forbids resolving via baseline regeneration. See .planning/audits/198-round4-playwright.md. | waived | routed to SEED-008 per 246-DEBT-REGISTER.md#W16 | 2026-08-28T23:20:53.239Z | 2026-10-26T00:37:04.704Z |
| 17 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 136 | Retention screenshot (both projects) left open per plan 198-28's Task 2 decision. Diff render shows a different retention-run row count/order between expected and received -- seeded retention-run history that varies with real pruner execution timing, not a single volatile field a mask locator can cover. Not resolvable without a seed-determinism fix (architectural, out of scope) or baseline regeneration (forbidden). See .planning/audits/198-round4-playwright.md. | waived | routed to SEED-008 per 246-DEBT-REGISTER.md#W17 | 2026-08-28T23:20:59.854Z | 2026-10-26T00:37:04.777Z |
| 18 | 198 | deviation | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs | 56 | CI-only ExUnit.TimeoutError (60000ms) at demo_reset_test.exs:69 -- System.cmd shells out to a MIX_ENV=prod mix demo.reset that must cold-compile the example app and deps before reaching the DEMO_ALLOW_RESET guard, with no @tag timeout budget. Sole blocker between current state and GREEN-04 on measured CI run 33253587315. Passes locally (warm _build/prod, 109 tests 0 failures). Not fixed in 198-29 (documentation-only files_modified); candidate for a round-5 plan. | fixed |  | 2026-08-29T13:12:34.726Z | 2026-10-26T00:37:04.848Z |
| 19 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts | 577 | Un-inventoried CI-only Playwright failure on run 33253587315: getByRole('heading', {name: 'Row history', exact: true}) not found at operator-responsive-mobile-first.spec.ts:475 (helper), reached from :587/:584. Appears in no row of .planning/audits/198-round4-playwright.md (grep -c returns 0). Root cause NOT established -- diagnosis requires source outside 198-29's documentation-only files_modified. Candidate for a round-5 plan. | fixed |  | 2026-08-29T13:12:40.719Z | 2026-10-26T00:37:04.920Z |
| 20 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 565 | SETTLES entry #10/#12 (round 5): plan 198-31 fixed the /Expired\|File unavailable/ regex, re-anchoring it to /Export expired\|File unavailable/ (commit 82a517a0), matching the canonical Presentation.export_status_label/2 copy. Local re-run passed both projects (198-31-SUMMARY.md). Not a demo-seed content change; entries #10/#12's original text is unmodified per this ledger's append-only rule. | fixed |  | 2026-08-30T21:16:10.521Z | 2026-10-26T00:37:04.993Z |
| 21 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 38 | SETTLES entry #11/#13 (round 5): plan 198-31 fixed the /Expired\|File unavailable/ regex, re-anchoring it to /Export expired\|File unavailable/ (commit 82a517a0), same cause and fix as entry #20 (accessibility spec). Local re-run passed both projects (198-31-SUMMARY.md). Entries #11/#13's original text is unmodified per this ledger's append-only rule. | fixed |  | 2026-08-30T21:16:16.948Z | 2026-10-26T00:37:05.071Z |
| 22 | 198 | deviation | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs | 56 | SETTLES entry #18 (round 5): plan 198-30 moved the cold MIX_ENV=prod mix compile out of the per-test ExUnit timeout budget into a setup_all block (commit 1fe99275), eliminating the 60000ms ExUnit.TimeoutError this entry recorded. Measured cold compile=30.3s, warm=0.73s, warm guard-only mix demo.reset=0.748s (comfortably inside the 60000ms default; no @tag timeout: needed). Local mix verify.example = 109/0 twice, per D-01 a readiness signal only -- the measured-CI re-run is plan 198-37's concern, not proven closed here. Entry #18's original text is unmodified per this ledger's append-only rule. | fixed |  | 2026-08-30T21:16:24.387Z | 2026-10-26T00:37:05.142Z |
| 23 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts | 577 | SETTLES entry #19 (round 5): plan 198-31 established the cause (the shared expectOperatorChrome helper's mobile-nav-toggle click firing the row-history drawer's own phx-click-away, row_history_component.ex, dismissing the drawer and navigating away before the Row history heading assertion runs), confirmed by direct standalone reproduction outside the harness, and fixed at cause test-side with a scoped exerciseMobileNav opt-out for the row-history route (commit 887198c6). This was a fix at cause, not an honest halt -- no lib/ file was touched. Local re-run passed both projects across 3 repeated runs (.planning/audits/198-round5-playwright.md, 198-31-SUMMARY.md coverage D2). Entry #19's original text is unmodified per this ledger's append-only rule. | fixed |  | 2026-08-30T21:16:31.136Z | 2026-10-26T00:37:05.212Z |
| 24 | 198 | deviation | .planning/STATE.md |  | state.advance-plan parsed legacy body position and required reconciliation to Plan 53 of 55 | waived | Obsolete process record: a GSD bookkeeping reconciliation for a closed phase; no code defect (246-DEBT-REGISTER.md#W24) | 2026-09-09T22:11:55.348Z | 2026-10-26T00:37:05.283Z |
| 25 | 198 | deviation | .planning/STATE.md |  | Canonical state.advance-plan incremented stale prose position to 2 of 65; reconciled prose to structured 66 of 66 progress | waived | Obsolete process record: a GSD bookkeeping reconciliation for a closed phase; no code defect (246-DEBT-REGISTER.md#W25) | 2026-09-10T22:19:12.757Z | 2026-10-26T00:37:05.360Z |
| 26 | 199 | deviation | test/threadline/operator_surface/operator_surface_fixture_contract_test.exs |  | Plan verify used unsupported mix test -x flag; execution used --max-failures 1 for RED and the unmodified targeted command for final GREEN verification | waived | Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W26) | 2026-09-11T04:40:32.551Z | 2026-10-26T00:37:05.437Z |
| 27 | 199 | deviation | .planning/ROADMAP.md |  | roadmap.update-plan-progress could not write the legacy Phase 199 0/TBD row; executor reconciled the checklist and progress row to 4/14 In Progress from live PLAN/SUMMARY counts | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W27) | 2026-09-11T04:42:10.923Z | 2026-10-26T00:37:05.508Z |
| 28 | 199 | deviation | test/threadline/removed_artifact_contract_test.exs |  | Plan 199-09 verify used unsupported mix test -x flag; execution used the same focused file list without -x for valid RED/GREEN and final verification | waived | Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W28) | 2026-09-11T04:53:19.815Z | 2026-10-26T00:37:05.579Z |
| 29 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-09 roadmap.update-plan-progress could not write the Phase 199 plan checklist/progress row; executor reconciled both to 5/14 In Progress from live PLAN/SUMMARY counts | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W29) | 2026-09-11T04:56:33.631Z | 2026-10-26T00:37:05.649Z |
| 30 | 199 | deviation | test/threadline/clean_checkout_contract_test.exs |  | Plan 199-10 replaced unsupported mix test -x verification syntax with --max-failures 1 on the installed Mix version | waived | Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W30) | 2026-09-11T05:08:59.068Z | 2026-10-26T00:37:05.720Z |
| 31 | 199 | deviation | bench/audit_capture_bench.exs |  | Plan 199-10 formatted newly-owned benchmark entrypoints when child-aware formatter coverage exposed drift | fixed |  | 2026-09-11T05:08:59.148Z | 2026-10-26T00:37:05.795Z |
| 32 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-10 roadmap.update-plan-progress could not write the legacy Phase 199 plan checklist/progress row; executor reconciled both to 6/14 In Progress from live PLAN/SUMMARY counts | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W32) | 2026-09-11T05:11:30.303Z | 2026-10-26T00:37:05.868Z |
| 33 | 199 | deviation | .planning/ROADMAP.md |  | roadmap.update-plan-progress could not edit the legacy Phase 199 layout; reconciled eight summary-backed plans manually | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W33) | 2026-09-11T14:19:51.495Z | 2026-10-26T00:37:05.941Z |
| 34 | 199 | todo | examples/threadline_phoenix/e2e/critic/label.ts | 708 | Pre-existing pair-label token wiring remains unimplemented outside Plan 199-05 filesystem scope | waived | Obsolete with DEBT-02: critic/label.ts was deleted in C2 (246-DEBT-REGISTER.md#W34) | 2026-09-11T14:38:01.325Z | 2026-10-26T00:37:06.013Z |
| 35 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-05 roadmap.update-plan-progress could not write the legacy Phase 199 layout; executor reconciled the checklist and progress row to 9/14 from live summaries | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W35) | 2026-09-11T14:38:55.777Z | 2026-10-26T00:37:06.084Z |
| 36 | 199 | deviation | .planning/ROADMAP.md |  | roadmap.update-plan-progress returned missing_phase_details; Plan 199-11 and 11/14 progress were reconciled manually | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W36) | 2026-09-11T15:05:01.279Z | 2026-10-26T00:37:06.155Z |
| 37 | 199 | deviation | test/fixtures/operator_surface/critic-scores/.gitkeep |  | Created the exact critic-scores destination parent after the fifth literal git mv initially found it absent. | waived | Obsolete with DEBT-02: the critic-scores directory was deleted in C4 (246-DEBT-REGISTER.md#W37) | 2026-09-11T15:27:46.709Z | 2026-10-26T00:37:06.225Z |
| 38 | 199 | deviation | test/threadline/operator_surface/operator_surface_fixture_contract_test.exs |  | Adapted the live corpus validator to mechanical_floors, synthetic-set non-vacuity, suffixed scorecards, and veto-ordering semantics. | waived | Obsolete with DEBT-02: the mechanical floor and scorecard corpus were removed in C3b and C4 (246-DEBT-REGISTER.md#W38) | 2026-09-11T15:27:46.846Z | 2026-10-26T00:37:06.298Z |
| 39 | 199 | deviation | .planning/phases/199-decouple/199-08-PLAN.md |  | Replaced unsupported mix test -x verification flag with --max-failures 1. | waived | Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W39) | 2026-09-11T15:27:46.980Z | 2026-10-26T00:37:06.370Z |
| 40 | 199 | deviation | .planning/refute/transcripts/refute.veto-ordering.off-token-accent.json |  | Restored pre-existing untracked scorecard and refute outputs moved physically by directory git mv to their original planning paths. | waived | Obsolete with DEBT-02: the refute corpus is gone and .planning/refute no longer exists (246-DEBT-REGISTER.md#W40) | 2026-09-11T15:27:47.126Z | 2026-10-26T00:37:06.443Z |
| 41 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-08 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the checklist and summary-backed progress row to 12/14. | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W41) | 2026-09-11T15:30:08.403Z | 2026-10-26T00:37:06.520Z |
| 42 | 199 | unmet-truth | test/threadline/dialyzer_ignore_contract_test.exs | 32 | Full-build Dialyzer remains red because the sealed 22-file warning-origin set exceeds Plan 199-13's 14-file authority | fixed |  | 2026-09-11T15:42:53.646Z | 2026-10-26T00:37:06.604Z |
| 43 | 199 | unrun-verify | .planning/phases/199-decouple/199-13-PLAN.md |  | Task 2 unused-filter verification was not run because Task 1 tripped the mandatory re-planning gate | waived | Obsolete process record: the re-planned 199 plans ran and the phase verified 40/40 (246-DEBT-REGISTER.md#W43) | 2026-09-11T15:42:53.810Z | 2026-10-26T00:37:06.679Z |
| 44 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-13 roadmap.update-plan-progress returned missing_phase_details; executor marked the plan halted and Plan 199-14 blocked without increasing the 12/14 complete count. | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W44) | 2026-09-11T15:43:16.489Z | 2026-10-26T00:37:06.751Z |
| 45 | 199 | deviation | .planning/ROADMAP.md | 510 | roadmap.update-plan-progress could not update Phase 199; Plan 199-15 checklist row was marked manually. | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W45) | 2026-09-11T18:05:30.592Z | 2026-10-26T00:37:06.824Z |
| 46 | 199 | deviation | .planning/STATE.md |  | state.advance-plan used stale pre-replan 14-plan position; executor reconciled Current Position to runnable Plan 16 of 21 after Plan 199-15 completion. | waived | Obsolete process record: a GSD bookkeeping reconciliation for a closed phase (246-DEBT-REGISTER.md#W46) | 2026-09-11T18:06:20.458Z | 2026-10-26T00:37:06.896Z |
| 47 | 199 | deviation | .planning/phases/199-decouple/199-17-SUMMARY.md |  | Temporary named Node tests were required to make source-verifier RED evidence machine-classifiable. | waived | Obsolete process record: throwaway RED scaffolding; the slice verifier is contract-tested at HEAD (246-DEBT-REGISTER.md#W47) | 2026-09-11T18:46:58.670Z | 2026-10-26T00:37:06.967Z |
| 48 | 199 | deviation | .planning/ROADMAP.md |  | Roadmap progress required manual reconciliation after the SDK returned missing_phase_details. | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W48) | 2026-09-11T18:46:58.760Z | 2026-10-26T00:37:07.038Z |
| 49 | 199 | deviation | .planning/ROADMAP.md |  | Reconciled Phase 199 Plan 19 roadmap progress manually after roadmap.update-plan-progress returned missing_phase_details | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W49) | 2026-09-11T19:27:17.503Z | 2026-10-26T00:37:07.108Z |
| 50 | 199 | deviation | .github/workflows/ci.yml |  | Temporary exact measurement-branch push trigger added for the cold run and removed after evidence collection | waived | Obsolete process record: the trigger was removed after evidence collection (246-DEBT-REGISTER.md#W50) | 2026-09-11T20:29:40.961Z | 2026-10-26T00:37:07.179Z |
| 51 | 199 | deviation | test/threadline/ci_topology_contract_test.exs |  | Tracer workflow-header matcher corrected to follow the established two-line roster contract | waived | Obsolete process record: an in-plan correction, already applied (246-DEBT-REGISTER.md#W51) | 2026-09-11T20:29:41.049Z | 2026-10-26T00:37:07.251Z |
| 52 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-14 roadmap progress and next-plan position reconciled manually after roadmap.update-plan-progress returned missing_phase_details | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W52) | 2026-09-11T20:30:32.770Z | 2026-10-26T00:37:07.322Z |
| 53 | 199 | deviation | test/threadline/main_ci_observer_contract_test.exs |  | Plan 199-21 formatted two pre-existing contract files exposed by the planning-free aggregate format gate. | fixed |  | 2026-09-11T21:44:55.050Z | 2026-10-26T00:37:07.393Z |
| 54 | 199 | deviation | test/threadline/removed_artifact_contract_test.exs |  | Plan 199-21 removed hidden physical planning dereferences and supplied clean-clone npm/dev-PLT prerequisites required by the exact aggregate. | waived | Obsolete process record: an in-plan change, already applied (246-DEBT-REGISTER.md#W54) | 2026-09-11T21:44:55.155Z | 2026-10-26T00:37:07.462Z |
| 55 | 199 | deviation | mix.exs |  | Plan 199-21 aligned local aggregate Dialyzer environment and browser projects with the committed CI topology. | waived | Obsolete process record: an in-plan change, already applied (246-DEBT-REGISTER.md#W55) | 2026-09-11T21:44:55.260Z | 2026-10-26T00:37:07.533Z |
| 56 | 199 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 130 | Plan 199-21 fixed cross-scroll-state browser geometry sampling without relaxing the ordering assertion. | fixed |  | 2026-09-11T21:44:55.367Z | 2026-10-26T00:37:07.603Z |
| 57 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-21 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the final checklist and 21/21 completion row manually. | waived | Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W57) | 2026-09-11T21:45:35.919Z | 2026-10-26T00:37:07.675Z |
| 58 | 200 | deviation | test/threadline/guide_graph_contract_test.exs |  | Guide graph resolver omitted repository-local resources and underscores in normalized anchors | fixed |  | 2026-09-12T11:57:02.663Z | 2026-09-12T11:57:17.853Z |
| 59 | 200 | deviation | guides/getting-started-saas.md |  | Adopt landing omitted three assigned guide routes required by the exact graph | fixed |  | 2026-09-12T11:57:02.743Z | 2026-09-12T11:57:17.929Z |
| 60 | 200 | deviation | mix.exs |  | Generated ExDoc did not ship the README theme-aware logo assets | fixed |  | 2026-09-12T11:57:02.821Z | 2026-09-12T11:57:18.005Z |
| 61 | 200 | unrun-verify | lib/threadline/operator_surface/mechanical_checker.ex | 729 | Repository-wide verify.format is blocked by a pre-existing formatting defect from Plan 200-16; Plan 200-13 owned files pass format checks | waived | Obsolete with DEBT-02: mechanical_checker.ex was deleted in C3b (246-DEBT-REGISTER.md#W61) | 2026-09-12T12:02:55.570Z | 2026-10-26T00:37:07.745Z |
| 62 | 201 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 108 | Plan 201-05 gate amendment: the browser lane's 8 screenshot-regression failures (cases 108 dense-Timeline, 115 row-history, 136 Exports, 145 Retention, each on desktop-chromium and mobile-chromium) are PROVEN pre-existing, not a Phase 201 regression. Measured both ways: at phase HEAD the lane is 82 passed / 8 failed, and with Phase 201's five LiveView modules reverted to fecfe684 the identical 8 fail and the same 2 Home cases pass. Phase 201's entire production delta is 21 deleted data-earned-flow/data-persona/data-jtbd attribute lines and nothing else, which cannot alter raster output. Baselines last written in 180-04 (799c7d6e) and left byte-identical (hashes sealed in .planning/audits/201-rendered-output-evidence.md). The plan's original verify clause demanded a fully green lane, unsatisfiable without the baseline regeneration the same plan prohibits; it is amended to an exact non-regression gate pinning this 8-failure set, Home passing, immutable PNG hashes, and all 82 behavior/a11y/responsive cases green. Supersedes nothing; complements open entries 8, 14, 15. Also corrected: the clause invoked `playwright test` directly, which starts no app server and yields 45 spurious ~50ms invalid-URL failures; the lane must run via mix verify.example_browser / run-e2e.sh. | waived | routed to SEED-008 per 246-DEBT-REGISTER.md#W62 | 2026-09-21T00:00:00.000Z | 2026-10-26T00:37:07.820Z |
| 63 | 202 | unrun-verify | .planning/phases/202-release-0-10-0/202-05-PLAN.md |  | Plan 202-05 holds at Task 1: mix ci.all and mix verify.release both RED at 0.9.0; three born-red causes (dialyzer MixProject unknown_function, 29 mix docs warnings, hardcoded ~> 0.9.0 in release_artifact_contract_test.exs:345) block the publish | fixed |  | 2026-09-22T15:39:03.519Z | 2026-10-26T00:37:07.893Z |
| 64 | 235 | deviation | guides/getting-started-saas.md |  | Adopt landing links added to route the stability and supported-table guides into the tested guide graph. | waived | Obsolete process record: an in-plan doc change, already applied (246-DEBT-REGISTER.md#W64) | 2026-10-07T00:50:08.368Z | 2026-10-26T00:37:07.965Z |
| 65 | 243 | skipped-test | examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts | 434 | Legacy reference capture is skipped in receipt-bound evidence mode to keep accepted Phase 238 snapshots read-only. | waived | Intentional read-only evidence mode skips the legacy snapshot recapture; fresh route-capture produced the required full-shell evidence. | 2026-10-11T03:34:46.995Z | 2026-10-11T03:35:02.460Z |
| 66 | 243 | deviation | examples/threadline_phoenix/e2e/support/operator-candidate-review.ts |  | Historical generated asset drift is disclosed while candidate local assets remain strictly verified. | fixed |  | 2026-10-11T03:34:47.109Z | 2026-10-11T03:35:02.236Z |
| 67 | 243 | deviation | test/partition_weights.txt |  | Candidate identity now includes the required sorted CI partition-weight inventory. | fixed |  | 2026-10-11T03:34:47.219Z | 2026-10-11T03:35:02.350Z |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "198",
    "file": ".github/workflows/flake-detection.yml",
    "line": null,
    "description": "GREEN-11: the two-dispatch dedup demonstration (two runs writing to one ci-flake issue) could not be run -- workflow_dispatch requires the workflow on the remote default branch and plan 198-06 is forbidden to push. Classifier logic proven locally against four real captured logs; the live dedup path is unrun.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T02:00:11.304Z",
    "resolved_at": "2026-10-26T00:36:45.519Z"
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "198",
    "file": "test/threadline/phase06_nyquist_ci_contract_test.exs",
    "line": null,
    "description": "Pre-existing CONTRIBUTING.md List 1 drift (only-in-jobs=[verify-capture, verify-mechanical]) leaves this file red. Deferred and explicitly unowned in 198-TRIAGE.md; out of 198-06 scope, not auto-fixed.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T02:00:18.816Z",
    "resolved_at": "2026-08-28T14:32:17.826Z"
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/phases/198-green-bringup/deferred-items.md",
    "line": null,
    "description": "mix ci.all fails at verify.example (examples/threadline_phoenix DemoContractTest) - pre-existing, unrelated to storage_schema defect class, out of 198-12 scope",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T14:31:57.746Z",
    "resolved_at": "2026-10-26T00:37:03.743Z"
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/phases/198-green-bringup/198-13-SUMMARY.md",
    "line": null,
    "description": "GREEN-07 not verified this run — local commits unpushed by explicit orchestrator constraint; origin/main CI still red on last observed run 33138291361",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T14:45:38.316Z",
    "resolved_at": "2026-10-26T00:37:03.814Z"
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "198",
    "file": ".github/workflows/branch-protection.yml",
    "line": 27,
    "description": "CR-03 (WARNING, carried-forward): permissions: contents: read means the classic-protection-not-stacking check (block c) can't distinguish a real 403 (no admin scope) from a genuine absence, so it is unfalsifiable in CI; passed locally only because the operator token carries admin.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T14:45:45.225Z",
    "resolved_at": "2026-10-26T00:37:03.883Z"
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "198",
    "file": "bin/verify-branch-protection",
    "line": 95,
    "description": "CR-04 (WARNING, carried-forward): the check-runs API call (block b) needs checks: read, same missing-scope root cause as CR-03; any API failure yields an empty EMITTED_COUNT which the pipeline treats as pass. Fails closed today so benign, but rests on the same fragile foundation.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T14:45:47.085Z",
    "resolved_at": "2026-10-26T00:37:03.956Z"
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "198",
    "file": ".github/rulesets/main.json",
    "line": null,
    "description": "CR-05 (WARNING, carried-forward): the checked-in ruleset snapshot is never diffed against live GitHub state, so a bypass_actor added via the UI or enforcement flipped to evaluate would pass all three verify-branch-protection blocks silently -- directly undermines the accepted merge lock predicated on bypass_actors: [].",
    "status": "waived",
    "reason": "routed to v1.48 per 246-DEBT-REGISTER.md#W7",
    "recorded_at": "2026-08-28T14:45:48.828Z",
    "resolved_at": "2026-10-26T00:37:04.029Z"
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/phases/198-green-bringup/198-17-SUMMARY.md",
    "line": null,
    "description": "verify.example_browser (desktop-chromium+mobile-chromium, full/unbounded) surfaces 28 pre-existing failures across 14 unrelated tests (find-mobile, phase-135/173/175/177-uat, screenshot-regression, screenshots, register) that CI's maxFailures:5 ceiling was masking -- previously invisible because the ceiling always aborted at the first 5. Unrelated to and not caused by this plan's 2-line fix (198-17); out of 198-17 scope; needs a follow-up gap-closure plan before the browser lane's next CI run can conclude success.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T17:31:39.078Z",
    "resolved_at": "2026-10-26T00:37:04.102Z"
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 655,
    "description": "New discovery (plan 198-27): mobile-chromium-only focus flake on #stress-dropdown-button (opens stress rendered widgets test), out of scope for 198-27's declared files, unassigned cluster, needs follow-up diagnosis",
    "status": "waived",
    "reason": "Not reproduced: the browser lane has run at exactly the 8 screenshot failures since phase 201, with this test passing on both projects (246-DEBT-REGISTER.md#W9)",
    "recorded_at": "2026-08-28T22:34:01.414Z",
    "resolved_at": "2026-10-26T00:37:04.175Z"
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 565,
    "description": "New discovery (plan 198-28 post-merge re-validation): Exports queue Expired/File-unavailable text not found on both projects, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T23:00:49.827Z",
    "resolved_at": "2026-10-26T00:37:04.249Z"
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 38,
    "description": "New discovery (plan 198-28 post-merge re-validation): exports dense state Expired/File-unavailable text not found on both projects, same shape as operator-accessibility.spec.ts:565 discovery, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T23:00:55.589Z",
    "resolved_at": "2026-10-26T00:37:04.328Z"
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 565,
    "description": "CORRECTS entry #10: root cause established (plan 198-28 Task 3) — NOT a demo-seed content change (demo/seed/exports.ex was not touched by any plan this round). Actual cause: fix(198-25) commit e6f3cd5d changed the completed-expired export job's rendered label from Expired to Export expired (lowercase e), breaking this test's /Expired|File unavailable/ regex (capital E). Still out of scope for 198-28's declared files; needs follow-up plan to update the regex/assertion to match the corrected canonical copy.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:26.077Z",
    "resolved_at": "2026-10-26T00:37:04.410Z"
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 38,
    "description": "CORRECTS entry #11: same root cause as entry #12 (fix(198-25) commit e6f3cd5d's Expired to Export expired label change broke this file's /Expired|File unavailable/ regex, capital E). Not a seed-content change. Still out of scope for 198-28's declared files; needs follow-up plan to update the assertion.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:32.409Z",
    "resolved_at": "2026-10-26T00:37:04.482Z"
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 108,
    "description": "dense Timeline screenshot (both projects) left open per plan 198-28's Task 2 decision (no baseline regeneration). Diff spans the whole page layout (header + rows), not a single volatile field; visually consistent with the baseline predating multiple accumulated UI changes across prior phases, not this round's changes. Not maskable. See .planning/audits/198-round4-playwright.md cluster reconciliation.",
    "status": "waived",
    "reason": "routed to SEED-008 per 246-DEBT-REGISTER.md#W14",
    "recorded_at": "2026-08-28T23:20:39.892Z",
    "resolved_at": "2026-10-26T00:37:04.559Z"
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 115,
    "description": "row-history drawer screenshot (both projects) left open per plan 198-28's Task 2 decision. Genuinely improved: locator was fixed from the full-viewport drawer container to the bounded .tl-drawer panel (desktop diff dropped from ratio 0.53 to 0.19, width now matches), but a residual height/content diff remains, not resolvable without baseline regeneration. See .planning/audits/198-round4-playwright.md.",
    "status": "waived",
    "reason": "routed to SEED-008 per 246-DEBT-REGISTER.md#W15",
    "recorded_at": "2026-08-28T23:20:46.296Z",
    "resolved_at": "2026-10-26T00:37:04.631Z"
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 127,
    "description": "Exports screenshot (both projects) left open per plan 198-28's Task 2 decision. The getByRole assertion-rot cause was fixed (exact: true); the residual screenshot diff is a legitimate, already-shipped visual change from this round's own fix(198-25) e6f3cd5d (Expired -> Export expired label), which Task 2 explicitly forbids resolving via baseline regeneration. See .planning/audits/198-round4-playwright.md.",
    "status": "waived",
    "reason": "routed to SEED-008 per 246-DEBT-REGISTER.md#W16",
    "recorded_at": "2026-08-28T23:20:53.239Z",
    "resolved_at": "2026-10-26T00:37:04.704Z"
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 136,
    "description": "Retention screenshot (both projects) left open per plan 198-28's Task 2 decision. Diff render shows a different retention-run row count/order between expected and received -- seeded retention-run history that varies with real pruner execution timing, not a single volatile field a mask locator can cover. Not resolvable without a seed-determinism fix (architectural, out of scope) or baseline regeneration (forbidden). See .planning/audits/198-round4-playwright.md.",
    "status": "waived",
    "reason": "routed to SEED-008 per 246-DEBT-REGISTER.md#W17",
    "recorded_at": "2026-08-28T23:20:59.854Z",
    "resolved_at": "2026-10-26T00:37:04.777Z"
  },
  {
    "id": 18,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs",
    "line": 56,
    "description": "CI-only ExUnit.TimeoutError (60000ms) at demo_reset_test.exs:69 -- System.cmd shells out to a MIX_ENV=prod mix demo.reset that must cold-compile the example app and deps before reaching the DEMO_ALLOW_RESET guard, with no @tag timeout budget. Sole blocker between current state and GREEN-04 on measured CI run 33253587315. Passes locally (warm _build/prod, 109 tests 0 failures). Not fixed in 198-29 (documentation-only files_modified); candidate for a round-5 plan.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-29T13:12:34.726Z",
    "resolved_at": "2026-10-26T00:37:04.848Z"
  },
  {
    "id": 19,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts",
    "line": 577,
    "description": "Un-inventoried CI-only Playwright failure on run 33253587315: getByRole('heading', {name: 'Row history', exact: true}) not found at operator-responsive-mobile-first.spec.ts:475 (helper), reached from :587/:584. Appears in no row of .planning/audits/198-round4-playwright.md (grep -c returns 0). Root cause NOT established -- diagnosis requires source outside 198-29's documentation-only files_modified. Candidate for a round-5 plan.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-29T13:12:40.719Z",
    "resolved_at": "2026-10-26T00:37:04.920Z"
  },
  {
    "id": 20,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 565,
    "description": "SETTLES entry #10/#12 (round 5): plan 198-31 fixed the /Expired|File unavailable/ regex, re-anchoring it to /Export expired|File unavailable/ (commit 82a517a0), matching the canonical Presentation.export_status_label/2 copy. Local re-run passed both projects (198-31-SUMMARY.md). Not a demo-seed content change; entries #10/#12's original text is unmodified per this ledger's append-only rule.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:10.521Z",
    "resolved_at": "2026-10-26T00:37:04.993Z"
  },
  {
    "id": 21,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 38,
    "description": "SETTLES entry #11/#13 (round 5): plan 198-31 fixed the /Expired|File unavailable/ regex, re-anchoring it to /Export expired|File unavailable/ (commit 82a517a0), same cause and fix as entry #20 (accessibility spec). Local re-run passed both projects (198-31-SUMMARY.md). Entries #11/#13's original text is unmodified per this ledger's append-only rule.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:16.948Z",
    "resolved_at": "2026-10-26T00:37:05.071Z"
  },
  {
    "id": 22,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs",
    "line": 56,
    "description": "SETTLES entry #18 (round 5): plan 198-30 moved the cold MIX_ENV=prod mix compile out of the per-test ExUnit timeout budget into a setup_all block (commit 1fe99275), eliminating the 60000ms ExUnit.TimeoutError this entry recorded. Measured cold compile=30.3s, warm=0.73s, warm guard-only mix demo.reset=0.748s (comfortably inside the 60000ms default; no @tag timeout: needed). Local mix verify.example = 109/0 twice, per D-01 a readiness signal only -- the measured-CI re-run is plan 198-37's concern, not proven closed here. Entry #18's original text is unmodified per this ledger's append-only rule.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:24.387Z",
    "resolved_at": "2026-10-26T00:37:05.142Z"
  },
  {
    "id": 23,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts",
    "line": 577,
    "description": "SETTLES entry #19 (round 5): plan 198-31 established the cause (the shared expectOperatorChrome helper's mobile-nav-toggle click firing the row-history drawer's own phx-click-away, row_history_component.ex, dismissing the drawer and navigating away before the Row history heading assertion runs), confirmed by direct standalone reproduction outside the harness, and fixed at cause test-side with a scoped exerciseMobileNav opt-out for the row-history route (commit 887198c6). This was a fix at cause, not an honest halt -- no lib/ file was touched. Local re-run passed both projects across 3 repeated runs (.planning/audits/198-round5-playwright.md, 198-31-SUMMARY.md coverage D2). Entry #19's original text is unmodified per this ledger's append-only rule.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:31.136Z",
    "resolved_at": "2026-10-26T00:37:05.212Z"
  },
  {
    "id": 24,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "state.advance-plan parsed legacy body position and required reconciliation to Plan 53 of 55",
    "status": "waived",
    "reason": "Obsolete process record: a GSD bookkeeping reconciliation for a closed phase; no code defect (246-DEBT-REGISTER.md#W24)",
    "recorded_at": "2026-09-09T22:11:55.348Z",
    "resolved_at": "2026-10-26T00:37:05.283Z"
  },
  {
    "id": 25,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Canonical state.advance-plan incremented stale prose position to 2 of 65; reconciled prose to structured 66 of 66 progress",
    "status": "waived",
    "reason": "Obsolete process record: a GSD bookkeeping reconciliation for a closed phase; no code defect (246-DEBT-REGISTER.md#W25)",
    "recorded_at": "2026-09-10T22:19:12.757Z",
    "resolved_at": "2026-10-26T00:37:05.360Z"
  },
  {
    "id": 26,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs",
    "line": null,
    "description": "Plan verify used unsupported mix test -x flag; execution used --max-failures 1 for RED and the unmodified targeted command for final GREEN verification",
    "status": "waived",
    "reason": "Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W26)",
    "recorded_at": "2026-09-11T04:40:32.551Z",
    "resolved_at": "2026-10-26T00:37:05.437Z",
    "milestone": "v1.41"
  },
  {
    "id": 27,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "roadmap.update-plan-progress could not write the legacy Phase 199 0/TBD row; executor reconciled the checklist and progress row to 4/14 In Progress from live PLAN/SUMMARY counts",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W27)",
    "recorded_at": "2026-09-11T04:42:10.923Z",
    "resolved_at": "2026-10-26T00:37:05.508Z",
    "milestone": "v1.41"
  },
  {
    "id": 28,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/removed_artifact_contract_test.exs",
    "line": null,
    "description": "Plan 199-09 verify used unsupported mix test -x flag; execution used the same focused file list without -x for valid RED/GREEN and final verification",
    "status": "waived",
    "reason": "Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W28)",
    "recorded_at": "2026-09-11T04:53:19.815Z",
    "resolved_at": "2026-10-26T00:37:05.579Z",
    "milestone": "v1.41"
  },
  {
    "id": 29,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-09 roadmap.update-plan-progress could not write the Phase 199 plan checklist/progress row; executor reconciled both to 5/14 In Progress from live PLAN/SUMMARY counts",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W29)",
    "recorded_at": "2026-09-11T04:56:33.631Z",
    "resolved_at": "2026-10-26T00:37:05.649Z",
    "milestone": "v1.41"
  },
  {
    "id": 30,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/clean_checkout_contract_test.exs",
    "line": null,
    "description": "Plan 199-10 replaced unsupported mix test -x verification syntax with --max-failures 1 on the installed Mix version",
    "status": "waived",
    "reason": "Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W30)",
    "recorded_at": "2026-09-11T05:08:59.068Z",
    "resolved_at": "2026-10-26T00:37:05.720Z",
    "milestone": "v1.41"
  },
  {
    "id": 31,
    "kind": "deviation",
    "phase": "199",
    "file": "bench/audit_capture_bench.exs",
    "line": null,
    "description": "Plan 199-10 formatted newly-owned benchmark entrypoints when child-aware formatter coverage exposed drift",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T05:08:59.148Z",
    "resolved_at": "2026-10-26T00:37:05.795Z",
    "milestone": "v1.41"
  },
  {
    "id": 32,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-10 roadmap.update-plan-progress could not write the legacy Phase 199 plan checklist/progress row; executor reconciled both to 6/14 In Progress from live PLAN/SUMMARY counts",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W32)",
    "recorded_at": "2026-09-11T05:11:30.303Z",
    "resolved_at": "2026-10-26T00:37:05.868Z",
    "milestone": "v1.41"
  },
  {
    "id": 33,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "roadmap.update-plan-progress could not edit the legacy Phase 199 layout; reconciled eight summary-backed plans manually",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W33)",
    "recorded_at": "2026-09-11T14:19:51.495Z",
    "resolved_at": "2026-10-26T00:37:05.941Z",
    "milestone": "v1.41"
  },
  {
    "id": 34,
    "kind": "todo",
    "phase": "199",
    "file": "examples/threadline_phoenix/e2e/critic/label.ts",
    "line": 708,
    "description": "Pre-existing pair-label token wiring remains unimplemented outside Plan 199-05 filesystem scope",
    "status": "waived",
    "reason": "Obsolete with DEBT-02: critic/label.ts was deleted in C2 (246-DEBT-REGISTER.md#W34)",
    "recorded_at": "2026-09-11T14:38:01.325Z",
    "resolved_at": "2026-10-26T00:37:06.013Z",
    "milestone": "v1.41"
  },
  {
    "id": 35,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-05 roadmap.update-plan-progress could not write the legacy Phase 199 layout; executor reconciled the checklist and progress row to 9/14 from live summaries",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W35)",
    "recorded_at": "2026-09-11T14:38:55.777Z",
    "resolved_at": "2026-10-26T00:37:06.084Z",
    "milestone": "v1.41"
  },
  {
    "id": 36,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "roadmap.update-plan-progress returned missing_phase_details; Plan 199-11 and 11/14 progress were reconciled manually",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W36)",
    "recorded_at": "2026-09-11T15:05:01.279Z",
    "resolved_at": "2026-10-26T00:37:06.155Z",
    "milestone": "v1.41"
  },
  {
    "id": 37,
    "kind": "deviation",
    "phase": "199",
    "file": "test/fixtures/operator_surface/critic-scores/.gitkeep",
    "line": null,
    "description": "Created the exact critic-scores destination parent after the fifth literal git mv initially found it absent.",
    "status": "waived",
    "reason": "Obsolete with DEBT-02: the critic-scores directory was deleted in C4 (246-DEBT-REGISTER.md#W37)",
    "recorded_at": "2026-09-11T15:27:46.709Z",
    "resolved_at": "2026-10-26T00:37:06.225Z",
    "milestone": "v1.41"
  },
  {
    "id": 38,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs",
    "line": null,
    "description": "Adapted the live corpus validator to mechanical_floors, synthetic-set non-vacuity, suffixed scorecards, and veto-ordering semantics.",
    "status": "waived",
    "reason": "Obsolete with DEBT-02: the mechanical floor and scorecard corpus were removed in C3b and C4 (246-DEBT-REGISTER.md#W38)",
    "recorded_at": "2026-09-11T15:27:46.846Z",
    "resolved_at": "2026-10-26T00:37:06.298Z",
    "milestone": "v1.41"
  },
  {
    "id": 39,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/phases/199-decouple/199-08-PLAN.md",
    "line": null,
    "description": "Replaced unsupported mix test -x verification flag with --max-failures 1.",
    "status": "waived",
    "reason": "Obsolete process record: the plan command was corrected at execution time; no code defect (246-DEBT-REGISTER.md#W39)",
    "recorded_at": "2026-09-11T15:27:46.980Z",
    "resolved_at": "2026-10-26T00:37:06.370Z",
    "milestone": "v1.41"
  },
  {
    "id": 40,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/refute/transcripts/refute.veto-ordering.off-token-accent.json",
    "line": null,
    "description": "Restored pre-existing untracked scorecard and refute outputs moved physically by directory git mv to their original planning paths.",
    "status": "waived",
    "reason": "Obsolete with DEBT-02: the refute corpus is gone and .planning/refute no longer exists (246-DEBT-REGISTER.md#W40)",
    "recorded_at": "2026-09-11T15:27:47.126Z",
    "resolved_at": "2026-10-26T00:37:06.443Z",
    "milestone": "v1.41"
  },
  {
    "id": 41,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-08 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the checklist and summary-backed progress row to 12/14.",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W41)",
    "recorded_at": "2026-09-11T15:30:08.403Z",
    "resolved_at": "2026-10-26T00:37:06.520Z",
    "milestone": "v1.41"
  },
  {
    "id": 42,
    "kind": "unmet-truth",
    "phase": "199",
    "file": "test/threadline/dialyzer_ignore_contract_test.exs",
    "line": 32,
    "description": "Full-build Dialyzer remains red because the sealed 22-file warning-origin set exceeds Plan 199-13's 14-file authority",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T15:42:53.646Z",
    "resolved_at": "2026-10-26T00:37:06.604Z",
    "milestone": "v1.41"
  },
  {
    "id": 43,
    "kind": "unrun-verify",
    "phase": "199",
    "file": ".planning/phases/199-decouple/199-13-PLAN.md",
    "line": null,
    "description": "Task 2 unused-filter verification was not run because Task 1 tripped the mandatory re-planning gate",
    "status": "waived",
    "reason": "Obsolete process record: the re-planned 199 plans ran and the phase verified 40/40 (246-DEBT-REGISTER.md#W43)",
    "recorded_at": "2026-09-11T15:42:53.810Z",
    "resolved_at": "2026-10-26T00:37:06.679Z",
    "milestone": "v1.41"
  },
  {
    "id": 44,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-13 roadmap.update-plan-progress returned missing_phase_details; executor marked the plan halted and Plan 199-14 blocked without increasing the 12/14 complete count.",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W44)",
    "recorded_at": "2026-09-11T15:43:16.489Z",
    "resolved_at": "2026-10-26T00:37:06.751Z",
    "milestone": "v1.41"
  },
  {
    "id": 45,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": 510,
    "description": "roadmap.update-plan-progress could not update Phase 199; Plan 199-15 checklist row was marked manually.",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W45)",
    "recorded_at": "2026-09-11T18:05:30.592Z",
    "resolved_at": "2026-10-26T00:37:06.824Z",
    "milestone": "v1.41"
  },
  {
    "id": 46,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "state.advance-plan used stale pre-replan 14-plan position; executor reconciled Current Position to runnable Plan 16 of 21 after Plan 199-15 completion.",
    "status": "waived",
    "reason": "Obsolete process record: a GSD bookkeeping reconciliation for a closed phase (246-DEBT-REGISTER.md#W46)",
    "recorded_at": "2026-09-11T18:06:20.458Z",
    "resolved_at": "2026-10-26T00:37:06.896Z",
    "milestone": "v1.41"
  },
  {
    "id": 47,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/phases/199-decouple/199-17-SUMMARY.md",
    "line": null,
    "description": "Temporary named Node tests were required to make source-verifier RED evidence machine-classifiable.",
    "status": "waived",
    "reason": "Obsolete process record: throwaway RED scaffolding; the slice verifier is contract-tested at HEAD (246-DEBT-REGISTER.md#W47)",
    "recorded_at": "2026-09-11T18:46:58.670Z",
    "resolved_at": "2026-10-26T00:37:06.967Z",
    "milestone": "v1.41"
  },
  {
    "id": 48,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Roadmap progress required manual reconciliation after the SDK returned missing_phase_details.",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W48)",
    "recorded_at": "2026-09-11T18:46:58.760Z",
    "resolved_at": "2026-10-26T00:37:07.038Z",
    "milestone": "v1.41"
  },
  {
    "id": 49,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Reconciled Phase 199 Plan 19 roadmap progress manually after roadmap.update-plan-progress returned missing_phase_details",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W49)",
    "recorded_at": "2026-09-11T19:27:17.503Z",
    "resolved_at": "2026-10-26T00:37:07.108Z",
    "milestone": "v1.41"
  },
  {
    "id": 50,
    "kind": "deviation",
    "phase": "199",
    "file": ".github/workflows/ci.yml",
    "line": null,
    "description": "Temporary exact measurement-branch push trigger added for the cold run and removed after evidence collection",
    "status": "waived",
    "reason": "Obsolete process record: the trigger was removed after evidence collection (246-DEBT-REGISTER.md#W50)",
    "recorded_at": "2026-09-11T20:29:40.961Z",
    "resolved_at": "2026-10-26T00:37:07.179Z",
    "milestone": "v1.41"
  },
  {
    "id": 51,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/ci_topology_contract_test.exs",
    "line": null,
    "description": "Tracer workflow-header matcher corrected to follow the established two-line roster contract",
    "status": "waived",
    "reason": "Obsolete process record: an in-plan correction, already applied (246-DEBT-REGISTER.md#W51)",
    "recorded_at": "2026-09-11T20:29:41.049Z",
    "resolved_at": "2026-10-26T00:37:07.251Z",
    "milestone": "v1.41"
  },
  {
    "id": 52,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-14 roadmap progress and next-plan position reconciled manually after roadmap.update-plan-progress returned missing_phase_details",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W52)",
    "recorded_at": "2026-09-11T20:30:32.770Z",
    "resolved_at": "2026-10-26T00:37:07.322Z",
    "milestone": "v1.41"
  },
  {
    "id": 53,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/main_ci_observer_contract_test.exs",
    "line": null,
    "description": "Plan 199-21 formatted two pre-existing contract files exposed by the planning-free aggregate format gate.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T21:44:55.050Z",
    "resolved_at": "2026-10-26T00:37:07.393Z",
    "milestone": "v1.41"
  },
  {
    "id": 54,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/removed_artifact_contract_test.exs",
    "line": null,
    "description": "Plan 199-21 removed hidden physical planning dereferences and supplied clean-clone npm/dev-PLT prerequisites required by the exact aggregate.",
    "status": "waived",
    "reason": "Obsolete process record: an in-plan change, already applied (246-DEBT-REGISTER.md#W54)",
    "recorded_at": "2026-09-11T21:44:55.155Z",
    "resolved_at": "2026-10-26T00:37:07.462Z",
    "milestone": "v1.41"
  },
  {
    "id": 55,
    "kind": "deviation",
    "phase": "199",
    "file": "mix.exs",
    "line": null,
    "description": "Plan 199-21 aligned local aggregate Dialyzer environment and browser projects with the committed CI topology.",
    "status": "waived",
    "reason": "Obsolete process record: an in-plan change, already applied (246-DEBT-REGISTER.md#W55)",
    "recorded_at": "2026-09-11T21:44:55.260Z",
    "resolved_at": "2026-10-26T00:37:07.533Z",
    "milestone": "v1.41"
  },
  {
    "id": 56,
    "kind": "deviation",
    "phase": "199",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 130,
    "description": "Plan 199-21 fixed cross-scroll-state browser geometry sampling without relaxing the ordering assertion.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-11T21:44:55.367Z",
    "resolved_at": "2026-10-26T00:37:07.603Z",
    "milestone": "v1.41"
  },
  {
    "id": 57,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-21 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the final checklist and 21/21 completion row manually.",
    "status": "waived",
    "reason": "Obsolete process record: roadmap bookkeeping for an archived phase (246-DEBT-REGISTER.md#W57)",
    "recorded_at": "2026-09-11T21:45:35.919Z",
    "resolved_at": "2026-10-26T00:37:07.675Z",
    "milestone": "v1.41"
  },
  {
    "id": 58,
    "kind": "deviation",
    "phase": "200",
    "file": "test/threadline/guide_graph_contract_test.exs",
    "line": null,
    "description": "Guide graph resolver omitted repository-local resources and underscores in normalized anchors",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-12T11:57:02.663Z",
    "resolved_at": "2026-09-12T11:57:17.853Z",
    "milestone": "v1.41"
  },
  {
    "id": 59,
    "kind": "deviation",
    "phase": "200",
    "file": "guides/getting-started-saas.md",
    "line": null,
    "description": "Adopt landing omitted three assigned guide routes required by the exact graph",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-12T11:57:02.743Z",
    "resolved_at": "2026-09-12T11:57:17.929Z",
    "milestone": "v1.41"
  },
  {
    "id": 60,
    "kind": "deviation",
    "phase": "200",
    "file": "mix.exs",
    "line": null,
    "description": "Generated ExDoc did not ship the README theme-aware logo assets",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-12T11:57:02.821Z",
    "resolved_at": "2026-09-12T11:57:18.005Z",
    "milestone": "v1.41"
  },
  {
    "id": 61,
    "kind": "unrun-verify",
    "phase": "200",
    "file": "lib/threadline/operator_surface/mechanical_checker.ex",
    "line": 729,
    "description": "Repository-wide verify.format is blocked by a pre-existing formatting defect from Plan 200-16; Plan 200-13 owned files pass format checks",
    "status": "waived",
    "reason": "Obsolete with DEBT-02: mechanical_checker.ex was deleted in C3b (246-DEBT-REGISTER.md#W61)",
    "recorded_at": "2026-09-12T12:02:55.570Z",
    "resolved_at": "2026-10-26T00:37:07.745Z",
    "milestone": "v1.41"
  },
  {
    "id": 62,
    "kind": "deviation",
    "phase": "201",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 108,
    "description": "Plan 201-05 gate amendment: the browser lane's 8 screenshot-regression failures (cases 108 dense-Timeline, 115 row-history, 136 Exports, 145 Retention, each on desktop-chromium and mobile-chromium) are PROVEN pre-existing, not a Phase 201 regression. Measured both ways: at phase HEAD the lane is 82 passed / 8 failed, and with Phase 201's five LiveView modules reverted to fecfe684 the identical 8 fail and the same 2 Home cases pass. Phase 201's entire production delta is 21 deleted data-earned-flow/data-persona/data-jtbd attribute lines and nothing else, which cannot alter raster output. Baselines last written in 180-04 (799c7d6e) and left byte-identical (hashes sealed in .planning/audits/201-rendered-output-evidence.md). The plan's original verify clause demanded a fully green lane, unsatisfiable without the baseline regeneration the same plan prohibits; it is amended to an exact non-regression gate pinning this 8-failure set, Home passing, immutable PNG hashes, and all 82 behavior/a11y/responsive cases green. Supersedes nothing; complements open entries 8, 14, 15. Also corrected: the clause invoked `playwright test` directly, which starts no app server and yields 45 spurious ~50ms invalid-URL failures; the lane must run via mix verify.example_browser / run-e2e.sh.",
    "status": "waived",
    "reason": "routed to SEED-008 per 246-DEBT-REGISTER.md#W62",
    "recorded_at": "2026-09-21T00:00:00.000Z",
    "resolved_at": "2026-10-26T00:37:07.820Z",
    "milestone": "v1.41"
  },
  {
    "id": 63,
    "kind": "unrun-verify",
    "phase": "202",
    "file": ".planning/phases/202-release-0-10-0/202-05-PLAN.md",
    "line": null,
    "description": "Plan 202-05 holds at Task 1: mix ci.all and mix verify.release both RED at 0.9.0; three born-red causes (dialyzer MixProject unknown_function, 29 mix docs warnings, hardcoded ~> 0.9.0 in release_artifact_contract_test.exs:345) block the publish",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-09-22T15:39:03.519Z",
    "resolved_at": "2026-10-26T00:37:07.893Z",
    "milestone": "v1.41"
  },
  {
    "id": 64,
    "kind": "deviation",
    "phase": "235",
    "file": "guides/getting-started-saas.md",
    "line": null,
    "description": "Adopt landing links added to route the stability and supported-table guides into the tested guide graph.",
    "status": "waived",
    "reason": "Obsolete process record: an in-plan doc change, already applied (246-DEBT-REGISTER.md#W64)",
    "recorded_at": "2026-10-07T00:50:08.368Z",
    "resolved_at": "2026-10-26T00:37:07.965Z",
    "milestone": "v1.45"
  },
  {
    "id": 65,
    "kind": "skipped-test",
    "phase": "243",
    "file": "examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts",
    "line": 434,
    "description": "Legacy reference capture is skipped in receipt-bound evidence mode to keep accepted Phase 238 snapshots read-only.",
    "status": "waived",
    "reason": "Intentional read-only evidence mode skips the legacy snapshot recapture; fresh route-capture produced the required full-shell evidence.",
    "recorded_at": "2026-10-11T03:34:46.995Z",
    "resolved_at": "2026-10-11T03:35:02.460Z",
    "milestone": "v1.46"
  },
  {
    "id": 66,
    "kind": "deviation",
    "phase": "243",
    "file": "examples/threadline_phoenix/e2e/support/operator-candidate-review.ts",
    "line": null,
    "description": "Historical generated asset drift is disclosed while candidate local assets remain strictly verified.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-11T03:34:47.109Z",
    "resolved_at": "2026-10-11T03:35:02.236Z",
    "milestone": "v1.46"
  },
  {
    "id": 67,
    "kind": "deviation",
    "phase": "243",
    "file": "test/partition_weights.txt",
    "line": null,
    "description": "Candidate identity now includes the required sorted CI partition-weight inventory.",
    "status": "fixed",
    "reason": "",
    "recorded_at": "2026-10-11T03:34:47.219Z",
    "resolved_at": "2026-10-11T03:35:02.350Z",
    "milestone": "v1.46"
  }
]
````
