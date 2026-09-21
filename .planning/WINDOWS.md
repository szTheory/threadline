---
schema_version: 1
open_count: 58
waived_count: 0
fixed_count: 4
total_count: 62
last_updated: 2026-09-21T00:00:00.000Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 198 | unrun-verify | .github/workflows/flake-detection.yml |  | GREEN-11: the two-dispatch dedup demonstration (two runs writing to one ci-flake issue) could not be run -- workflow_dispatch requires the workflow on the remote default branch and plan 198-06 is forbidden to push. Classifier logic proven locally against four real captured logs; the live dedup path is unrun. | open |  | 2026-08-28T02:00:11.304Z |  |
| 2 | 198 | deviation | test/threadline/phase06_nyquist_ci_contract_test.exs |  | Pre-existing CONTRIBUTING.md List 1 drift (only-in-jobs=[verify-capture, verify-mechanical]) leaves this file red. Deferred and explicitly unowned in 198-TRIAGE.md; out of 198-06 scope, not auto-fixed. | fixed |  | 2026-08-28T02:00:18.816Z | 2026-08-28T14:32:17.826Z |
| 3 | 198 | deviation | .planning/phases/198-green-bringup/deferred-items.md |  | mix ci.all fails at verify.example (examples/threadline_phoenix DemoContractTest) - pre-existing, unrelated to storage_schema defect class, out of 198-12 scope | open |  | 2026-08-28T14:31:57.746Z |  |
| 4 | 198 | deviation | .planning/phases/198-green-bringup/198-13-SUMMARY.md |  | GREEN-07 not verified this run — local commits unpushed by explicit orchestrator constraint; origin/main CI still red on last observed run 33138291361 | open |  | 2026-08-28T14:45:38.316Z |  |
| 5 | 198 | deviation | .github/workflows/branch-protection.yml | 27 | CR-03 (WARNING, carried-forward): permissions: contents: read means the classic-protection-not-stacking check (block c) can't distinguish a real 403 (no admin scope) from a genuine absence, so it is unfalsifiable in CI; passed locally only because the operator token carries admin. | open |  | 2026-08-28T14:45:45.225Z |  |
| 6 | 198 | deviation | bin/verify-branch-protection | 95 | CR-04 (WARNING, carried-forward): the check-runs API call (block b) needs checks: read, same missing-scope root cause as CR-03; any API failure yields an empty EMITTED_COUNT which the pipeline treats as pass. Fails closed today so benign, but rests on the same fragile foundation. | open |  | 2026-08-28T14:45:47.085Z |  |
| 7 | 198 | deviation | .github/rulesets/main.json |  | CR-05 (WARNING, carried-forward): the checked-in ruleset snapshot is never diffed against live GitHub state, so a bypass_actor added via the UI or enforcement flipped to evaluate would pass all three verify-branch-protection blocks silently -- directly undermines the accepted merge lock predicated on bypass_actors: []. | open |  | 2026-08-28T14:45:48.828Z |  |
| 8 | 198 | deviation | .planning/phases/198-green-bringup/198-17-SUMMARY.md |  | verify.example_browser (desktop-chromium+mobile-chromium, full/unbounded) surfaces 28 pre-existing failures across 14 unrelated tests (find-mobile, phase-135/173/175/177-uat, screenshot-regression, screenshots, register) that CI's maxFailures:5 ceiling was masking -- previously invisible because the ceiling always aborted at the first 5. Unrelated to and not caused by this plan's 2-line fix (198-17); out of 198-17 scope; needs a follow-up gap-closure plan before the browser lane's next CI run can conclude success. | open |  | 2026-08-28T17:31:39.078Z |  |
| 9 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 655 | New discovery (plan 198-27): mobile-chromium-only focus flake on #stress-dropdown-button (opens stress rendered widgets test), out of scope for 198-27's declared files, unassigned cluster, needs follow-up diagnosis | open |  | 2026-08-28T22:34:01.414Z |  |
| 10 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 565 | New discovery (plan 198-28 post-merge re-validation): Exports queue Expired/File-unavailable text not found on both projects, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis | open |  | 2026-08-28T23:00:49.827Z |  |
| 11 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 38 | New discovery (plan 198-28 post-merge re-validation): exports dense state Expired/File-unavailable text not found on both projects, same shape as operator-accessibility.spec.ts:565 discovery, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis | open |  | 2026-08-28T23:00:55.589Z |  |
| 12 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 565 | CORRECTS entry #10: root cause established (plan 198-28 Task 3) — NOT a demo-seed content change (demo/seed/exports.ex was not touched by any plan this round). Actual cause: fix(198-25) commit e6f3cd5d changed the completed-expired export job's rendered label from Expired to Export expired (lowercase e), breaking this test's /Expired\|File unavailable/ regex (capital E). Still out of scope for 198-28's declared files; needs follow-up plan to update the regex/assertion to match the corrected canonical copy. | open |  | 2026-08-28T23:20:26.077Z |  |
| 13 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 38 | CORRECTS entry #11: same root cause as entry #12 (fix(198-25) commit e6f3cd5d's Expired to Export expired label change broke this file's /Expired\|File unavailable/ regex, capital E). Not a seed-content change. Still out of scope for 198-28's declared files; needs follow-up plan to update the assertion. | open |  | 2026-08-28T23:20:32.409Z |  |
| 14 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 108 | dense Timeline screenshot (both projects) left open per plan 198-28's Task 2 decision (no baseline regeneration). Diff spans the whole page layout (header + rows), not a single volatile field; visually consistent with the baseline predating multiple accumulated UI changes across prior phases, not this round's changes. Not maskable. See .planning/audits/198-round4-playwright.md cluster reconciliation. | open |  | 2026-08-28T23:20:39.892Z |  |
| 15 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 115 | row-history drawer screenshot (both projects) left open per plan 198-28's Task 2 decision. Genuinely improved: locator was fixed from the full-viewport drawer container to the bounded .tl-drawer panel (desktop diff dropped from ratio 0.53 to 0.19, width now matches), but a residual height/content diff remains, not resolvable without baseline regeneration. See .planning/audits/198-round4-playwright.md. | open |  | 2026-08-28T23:20:46.296Z |  |
| 16 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 127 | Exports screenshot (both projects) left open per plan 198-28's Task 2 decision. The getByRole assertion-rot cause was fixed (exact: true); the residual screenshot diff is a legitimate, already-shipped visual change from this round's own fix(198-25) e6f3cd5d (Expired -> Export expired label), which Task 2 explicitly forbids resolving via baseline regeneration. See .planning/audits/198-round4-playwright.md. | open |  | 2026-08-28T23:20:53.239Z |  |
| 17 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 136 | Retention screenshot (both projects) left open per plan 198-28's Task 2 decision. Diff render shows a different retention-run row count/order between expected and received -- seeded retention-run history that varies with real pruner execution timing, not a single volatile field a mask locator can cover. Not resolvable without a seed-determinism fix (architectural, out of scope) or baseline regeneration (forbidden). See .planning/audits/198-round4-playwright.md. | open |  | 2026-08-28T23:20:59.854Z |  |
| 18 | 198 | deviation | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs | 56 | CI-only ExUnit.TimeoutError (60000ms) at demo_reset_test.exs:69 -- System.cmd shells out to a MIX_ENV=prod mix demo.reset that must cold-compile the example app and deps before reaching the DEMO_ALLOW_RESET guard, with no @tag timeout budget. Sole blocker between current state and GREEN-04 on measured CI run 33253587315. Passes locally (warm _build/prod, 109 tests 0 failures). Not fixed in 198-29 (documentation-only files_modified); candidate for a round-5 plan. | open |  | 2026-08-29T13:12:34.726Z |  |
| 19 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts | 577 | Un-inventoried CI-only Playwright failure on run 33253587315: getByRole('heading', {name: 'Row history', exact: true}) not found at operator-responsive-mobile-first.spec.ts:475 (helper), reached from :587/:584. Appears in no row of .planning/audits/198-round4-playwright.md (grep -c returns 0). Root cause NOT established -- diagnosis requires source outside 198-29's documentation-only files_modified. Candidate for a round-5 plan. | open |  | 2026-08-29T13:12:40.719Z |  |
| 20 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | 565 | SETTLES entry #10/#12 (round 5): plan 198-31 fixed the /Expired\|File unavailable/ regex, re-anchoring it to /Export expired\|File unavailable/ (commit 82a517a0), matching the canonical Presentation.export_status_label/2 copy. Local re-run passed both projects (198-31-SUMMARY.md). Not a demo-seed content change; entries #10/#12's original text is unmodified per this ledger's append-only rule. | open |  | 2026-08-30T21:16:10.521Z |  |
| 21 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 38 | SETTLES entry #11/#13 (round 5): plan 198-31 fixed the /Expired\|File unavailable/ regex, re-anchoring it to /Export expired\|File unavailable/ (commit 82a517a0), same cause and fix as entry #20 (accessibility spec). Local re-run passed both projects (198-31-SUMMARY.md). Entries #11/#13's original text is unmodified per this ledger's append-only rule. | open |  | 2026-08-30T21:16:16.948Z |  |
| 22 | 198 | deviation | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs | 56 | SETTLES entry #18 (round 5): plan 198-30 moved the cold MIX_ENV=prod mix compile out of the per-test ExUnit timeout budget into a setup_all block (commit 1fe99275), eliminating the 60000ms ExUnit.TimeoutError this entry recorded. Measured cold compile=30.3s, warm=0.73s, warm guard-only mix demo.reset=0.748s (comfortably inside the 60000ms default; no @tag timeout: needed). Local mix verify.example = 109/0 twice, per D-01 a readiness signal only -- the measured-CI re-run is plan 198-37's concern, not proven closed here. Entry #18's original text is unmodified per this ledger's append-only rule. | open |  | 2026-08-30T21:16:24.387Z |  |
| 23 | 198 | deviation | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts | 577 | SETTLES entry #19 (round 5): plan 198-31 established the cause (the shared expectOperatorChrome helper's mobile-nav-toggle click firing the row-history drawer's own phx-click-away, row_history_component.ex, dismissing the drawer and navigating away before the Row history heading assertion runs), confirmed by direct standalone reproduction outside the harness, and fixed at cause test-side with a scoped exerciseMobileNav opt-out for the row-history route (commit 887198c6). This was a fix at cause, not an honest halt -- no lib/ file was touched. Local re-run passed both projects across 3 repeated runs (.planning/audits/198-round5-playwright.md, 198-31-SUMMARY.md coverage D2). Entry #19's original text is unmodified per this ledger's append-only rule. | open |  | 2026-08-30T21:16:31.136Z |  |
| 24 | 198 | deviation | .planning/STATE.md |  | state.advance-plan parsed legacy body position and required reconciliation to Plan 53 of 55 | open |  | 2026-09-09T22:11:55.348Z |  |
| 25 | 198 | deviation | .planning/STATE.md |  | Canonical state.advance-plan incremented stale prose position to 2 of 65; reconciled prose to structured 66 of 66 progress | open |  | 2026-09-10T22:19:12.757Z |  |
| 26 | 199 | deviation | test/threadline/operator_surface/operator_surface_fixture_contract_test.exs |  | Plan verify used unsupported mix test -x flag; execution used --max-failures 1 for RED and the unmodified targeted command for final GREEN verification | open |  | 2026-09-11T04:40:32.551Z |  |
| 27 | 199 | deviation | .planning/ROADMAP.md |  | roadmap.update-plan-progress could not write the legacy Phase 199 0/TBD row; executor reconciled the checklist and progress row to 4/14 In Progress from live PLAN/SUMMARY counts | open |  | 2026-09-11T04:42:10.923Z |  |
| 28 | 199 | deviation | test/threadline/removed_artifact_contract_test.exs |  | Plan 199-09 verify used unsupported mix test -x flag; execution used the same focused file list without -x for valid RED/GREEN and final verification | open |  | 2026-09-11T04:53:19.815Z |  |
| 29 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-09 roadmap.update-plan-progress could not write the Phase 199 plan checklist/progress row; executor reconciled both to 5/14 In Progress from live PLAN/SUMMARY counts | open |  | 2026-09-11T04:56:33.631Z |  |
| 30 | 199 | deviation | test/threadline/clean_checkout_contract_test.exs |  | Plan 199-10 replaced unsupported mix test -x verification syntax with --max-failures 1 on the installed Mix version | open |  | 2026-09-11T05:08:59.068Z |  |
| 31 | 199 | deviation | bench/audit_capture_bench.exs |  | Plan 199-10 formatted newly-owned benchmark entrypoints when child-aware formatter coverage exposed drift | open |  | 2026-09-11T05:08:59.148Z |  |
| 32 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-10 roadmap.update-plan-progress could not write the legacy Phase 199 plan checklist/progress row; executor reconciled both to 6/14 In Progress from live PLAN/SUMMARY counts | open |  | 2026-09-11T05:11:30.303Z |  |
| 33 | 199 | deviation | .planning/ROADMAP.md |  | roadmap.update-plan-progress could not edit the legacy Phase 199 layout; reconciled eight summary-backed plans manually | open |  | 2026-09-11T14:19:51.495Z |  |
| 34 | 199 | todo | examples/threadline_phoenix/e2e/critic/label.ts | 708 | Pre-existing pair-label token wiring remains unimplemented outside Plan 199-05 filesystem scope | open |  | 2026-09-11T14:38:01.325Z |  |
| 35 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-05 roadmap.update-plan-progress could not write the legacy Phase 199 layout; executor reconciled the checklist and progress row to 9/14 from live summaries | open |  | 2026-09-11T14:38:55.777Z |  |
| 36 | 199 | deviation | .planning/ROADMAP.md |  | roadmap.update-plan-progress returned missing_phase_details; Plan 199-11 and 11/14 progress were reconciled manually | open |  | 2026-09-11T15:05:01.279Z |  |
| 37 | 199 | deviation | test/fixtures/operator_surface/critic-scores/.gitkeep |  | Created the exact critic-scores destination parent after the fifth literal git mv initially found it absent. | open |  | 2026-09-11T15:27:46.709Z |  |
| 38 | 199 | deviation | test/threadline/operator_surface/operator_surface_fixture_contract_test.exs |  | Adapted the live corpus validator to mechanical_floors, synthetic-set non-vacuity, suffixed scorecards, and veto-ordering semantics. | open |  | 2026-09-11T15:27:46.846Z |  |
| 39 | 199 | deviation | .planning/phases/199-decouple/199-08-PLAN.md |  | Replaced unsupported mix test -x verification flag with --max-failures 1. | open |  | 2026-09-11T15:27:46.980Z |  |
| 40 | 199 | deviation | .planning/refute/transcripts/refute.veto-ordering.off-token-accent.json |  | Restored pre-existing untracked scorecard and refute outputs moved physically by directory git mv to their original planning paths. | open |  | 2026-09-11T15:27:47.126Z |  |
| 41 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-08 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the checklist and summary-backed progress row to 12/14. | open |  | 2026-09-11T15:30:08.403Z |  |
| 42 | 199 | unmet-truth | test/threadline/dialyzer_ignore_contract_test.exs | 32 | Full-build Dialyzer remains red because the sealed 22-file warning-origin set exceeds Plan 199-13's 14-file authority | open |  | 2026-09-11T15:42:53.646Z |  |
| 43 | 199 | unrun-verify | .planning/phases/199-decouple/199-13-PLAN.md |  | Task 2 unused-filter verification was not run because Task 1 tripped the mandatory re-planning gate | open |  | 2026-09-11T15:42:53.810Z |  |
| 44 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-13 roadmap.update-plan-progress returned missing_phase_details; executor marked the plan halted and Plan 199-14 blocked without increasing the 12/14 complete count. | open |  | 2026-09-11T15:43:16.489Z |  |
| 45 | 199 | deviation | .planning/ROADMAP.md | 510 | roadmap.update-plan-progress could not update Phase 199; Plan 199-15 checklist row was marked manually. | open |  | 2026-09-11T18:05:30.592Z |  |
| 46 | 199 | deviation | .planning/STATE.md |  | state.advance-plan used stale pre-replan 14-plan position; executor reconciled Current Position to runnable Plan 16 of 21 after Plan 199-15 completion. | open |  | 2026-09-11T18:06:20.458Z |  |
| 47 | 199 | deviation | .planning/phases/199-decouple/199-17-SUMMARY.md |  | Temporary named Node tests were required to make source-verifier RED evidence machine-classifiable. | open |  | 2026-09-11T18:46:58.670Z |  |
| 48 | 199 | deviation | .planning/ROADMAP.md |  | Roadmap progress required manual reconciliation after the SDK returned missing_phase_details. | open |  | 2026-09-11T18:46:58.760Z |  |
| 49 | 199 | deviation | .planning/ROADMAP.md |  | Reconciled Phase 199 Plan 19 roadmap progress manually after roadmap.update-plan-progress returned missing_phase_details | open |  | 2026-09-11T19:27:17.503Z |  |
| 50 | 199 | deviation | .github/workflows/ci.yml |  | Temporary exact measurement-branch push trigger added for the cold run and removed after evidence collection | open |  | 2026-09-11T20:29:40.961Z |  |
| 51 | 199 | deviation | test/threadline/ci_topology_contract_test.exs |  | Tracer workflow-header matcher corrected to follow the established two-line roster contract | open |  | 2026-09-11T20:29:41.049Z |  |
| 52 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-14 roadmap progress and next-plan position reconciled manually after roadmap.update-plan-progress returned missing_phase_details | open |  | 2026-09-11T20:30:32.770Z |  |
| 53 | 199 | deviation | test/threadline/main_ci_observer_contract_test.exs |  | Plan 199-21 formatted two pre-existing contract files exposed by the planning-free aggregate format gate. | open |  | 2026-09-11T21:44:55.050Z |  |
| 54 | 199 | deviation | test/threadline/removed_artifact_contract_test.exs |  | Plan 199-21 removed hidden physical planning dereferences and supplied clean-clone npm/dev-PLT prerequisites required by the exact aggregate. | open |  | 2026-09-11T21:44:55.155Z |  |
| 55 | 199 | deviation | mix.exs |  | Plan 199-21 aligned local aggregate Dialyzer environment and browser projects with the committed CI topology. | open |  | 2026-09-11T21:44:55.260Z |  |
| 56 | 199 | deviation | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | 130 | Plan 199-21 fixed cross-scroll-state browser geometry sampling without relaxing the ordering assertion. | open |  | 2026-09-11T21:44:55.367Z |  |
| 57 | 199 | deviation | .planning/ROADMAP.md |  | Plan 199-21 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the final checklist and 21/21 completion row manually. | open |  | 2026-09-11T21:45:35.919Z |  |
| 58 | 200 | deviation | test/threadline/guide_graph_contract_test.exs |  | Guide graph resolver omitted repository-local resources and underscores in normalized anchors | fixed |  | 2026-09-12T11:57:02.663Z | 2026-09-12T11:57:17.853Z |
| 59 | 200 | deviation | guides/getting-started-saas.md |  | Adopt landing omitted three assigned guide routes required by the exact graph | fixed |  | 2026-09-12T11:57:02.743Z | 2026-09-12T11:57:17.929Z |
| 60 | 200 | deviation | mix.exs |  | Generated ExDoc did not ship the README theme-aware logo assets | fixed |  | 2026-09-12T11:57:02.821Z | 2026-09-12T11:57:18.005Z |
| 61 | 200 | unrun-verify | lib/threadline/operator_surface/mechanical_checker.ex | 729 | Repository-wide verify.format is blocked by a pre-existing formatting defect from Plan 200-16; Plan 200-13 owned files pass format checks | open |  | 2026-09-12T12:02:55.570Z |  |
| 62 | 201 | deviation | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | 108 | Plan 201-05 gate amendment: the browser lane's 8 screenshot-regression failures (cases 108 dense-Timeline, 115 row-history, 136 Exports, 145 Retention, each on desktop-chromium and mobile-chromium) are PROVEN pre-existing, not a Phase 201 regression. Measured both ways: at phase HEAD the lane is 82 passed / 8 failed, and with Phase 201's five LiveView modules reverted to fecfe684 the identical 8 fail and the same 2 Home cases pass. Phase 201's entire production delta is 21 deleted data-earned-flow/data-persona/data-jtbd attribute lines and nothing else, which cannot alter raster output. Baselines last written in 180-04 (799c7d6e) and left byte-identical (hashes sealed in .planning/audits/201-rendered-output-evidence.md). The plan's original verify clause demanded a fully green lane, unsatisfiable without the baseline regeneration the same plan prohibits; it is amended to an exact non-regression gate pinning this 8-failure set, Home passing, immutable PNG hashes, and all 82 behavior/a11y/responsive cases green. Supersedes nothing; complements open entries 8, 14, 15. Also corrected: the clause invoked `playwright test` directly, which starts no app server and yields 45 spurious ~50ms invalid-URL failures; the lane must run via mix verify.example_browser / run-e2e.sh. | open |  | 2026-09-21T00:00:00.000Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "198",
    "file": ".github/workflows/flake-detection.yml",
    "line": null,
    "description": "GREEN-11: the two-dispatch dedup demonstration (two runs writing to one ci-flake issue) could not be run -- workflow_dispatch requires the workflow on the remote default branch and plan 198-06 is forbidden to push. Classifier logic proven locally against four real captured logs; the live dedup path is unrun.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T02:00:11.304Z",
    "resolved_at": null
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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T14:31:57.746Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/phases/198-green-bringup/198-13-SUMMARY.md",
    "line": null,
    "description": "GREEN-07 not verified this run \u2014 local commits unpushed by explicit orchestrator constraint; origin/main CI still red on last observed run 33138291361",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T14:45:38.316Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "198",
    "file": ".github/workflows/branch-protection.yml",
    "line": 27,
    "description": "CR-03 (WARNING, carried-forward): permissions: contents: read means the classic-protection-not-stacking check (block c) can't distinguish a real 403 (no admin scope) from a genuine absence, so it is unfalsifiable in CI; passed locally only because the operator token carries admin.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T14:45:45.225Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "198",
    "file": "bin/verify-branch-protection",
    "line": 95,
    "description": "CR-04 (WARNING, carried-forward): the check-runs API call (block b) needs checks: read, same missing-scope root cause as CR-03; any API failure yields an empty EMITTED_COUNT which the pipeline treats as pass. Fails closed today so benign, but rests on the same fragile foundation.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T14:45:47.085Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "198",
    "file": ".github/rulesets/main.json",
    "line": null,
    "description": "CR-05 (WARNING, carried-forward): the checked-in ruleset snapshot is never diffed against live GitHub state, so a bypass_actor added via the UI or enforcement flipped to evaluate would pass all three verify-branch-protection blocks silently -- directly undermines the accepted merge lock predicated on bypass_actors: [].",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T14:45:48.828Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/phases/198-green-bringup/198-17-SUMMARY.md",
    "line": null,
    "description": "verify.example_browser (desktop-chromium+mobile-chromium, full/unbounded) surfaces 28 pre-existing failures across 14 unrelated tests (find-mobile, phase-135/173/175/177-uat, screenshot-regression, screenshots, register) that CI's maxFailures:5 ceiling was masking -- previously invisible because the ceiling always aborted at the first 5. Unrelated to and not caused by this plan's 2-line fix (198-17); out of 198-17 scope; needs a follow-up gap-closure plan before the browser lane's next CI run can conclude success.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T17:31:39.078Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 655,
    "description": "New discovery (plan 198-27): mobile-chromium-only focus flake on #stress-dropdown-button (opens stress rendered widgets test), out of scope for 198-27's declared files, unassigned cluster, needs follow-up diagnosis",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T22:34:01.414Z",
    "resolved_at": null
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 565,
    "description": "New discovery (plan 198-28 post-merge re-validation): Exports queue Expired/File-unavailable text not found on both projects, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:00:49.827Z",
    "resolved_at": null
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 38,
    "description": "New discovery (plan 198-28 post-merge re-validation): exports dense state Expired/File-unavailable text not found on both projects, same shape as operator-accessibility.spec.ts:565 discovery, likely seed-state shape changed by 198-25's exports seed rewrite; out of scope for 198-28's declared files, unassigned cluster, needs follow-up diagnosis",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:00:55.589Z",
    "resolved_at": null
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 565,
    "description": "CORRECTS entry #10: root cause established (plan 198-28 Task 3) \u2014 NOT a demo-seed content change (demo/seed/exports.ex was not touched by any plan this round). Actual cause: fix(198-25) commit e6f3cd5d changed the completed-expired export job's rendered label from Expired to Export expired (lowercase e), breaking this test's /Expired|File unavailable/ regex (capital E). Still out of scope for 198-28's declared files; needs follow-up plan to update the regex/assertion to match the corrected canonical copy.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:26.077Z",
    "resolved_at": null
  },
  {
    "id": 13,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 38,
    "description": "CORRECTS entry #11: same root cause as entry #12 (fix(198-25) commit e6f3cd5d's Expired to Export expired label change broke this file's /Expired|File unavailable/ regex, capital E). Not a seed-content change. Still out of scope for 198-28's declared files; needs follow-up plan to update the assertion.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:32.409Z",
    "resolved_at": null
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 108,
    "description": "dense Timeline screenshot (both projects) left open per plan 198-28's Task 2 decision (no baseline regeneration). Diff spans the whole page layout (header + rows), not a single volatile field; visually consistent with the baseline predating multiple accumulated UI changes across prior phases, not this round's changes. Not maskable. See .planning/audits/198-round4-playwright.md cluster reconciliation.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:39.892Z",
    "resolved_at": null
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 115,
    "description": "row-history drawer screenshot (both projects) left open per plan 198-28's Task 2 decision. Genuinely improved: locator was fixed from the full-viewport drawer container to the bounded .tl-drawer panel (desktop diff dropped from ratio 0.53 to 0.19, width now matches), but a residual height/content diff remains, not resolvable without baseline regeneration. See .planning/audits/198-round4-playwright.md.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:46.296Z",
    "resolved_at": null
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 127,
    "description": "Exports screenshot (both projects) left open per plan 198-28's Task 2 decision. The getByRole assertion-rot cause was fixed (exact: true); the residual screenshot diff is a legitimate, already-shipped visual change from this round's own fix(198-25) e6f3cd5d (Expired -> Export expired label), which Task 2 explicitly forbids resolving via baseline regeneration. See .planning/audits/198-round4-playwright.md.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:53.239Z",
    "resolved_at": null
  },
  {
    "id": 17,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 136,
    "description": "Retention screenshot (both projects) left open per plan 198-28's Task 2 decision. Diff render shows a different retention-run row count/order between expected and received -- seeded retention-run history that varies with real pruner execution timing, not a single volatile field a mask locator can cover. Not resolvable without a seed-determinism fix (architectural, out of scope) or baseline regeneration (forbidden). See .planning/audits/198-round4-playwright.md.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T23:20:59.854Z",
    "resolved_at": null
  },
  {
    "id": 18,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs",
    "line": 56,
    "description": "CI-only ExUnit.TimeoutError (60000ms) at demo_reset_test.exs:69 -- System.cmd shells out to a MIX_ENV=prod mix demo.reset that must cold-compile the example app and deps before reaching the DEMO_ALLOW_RESET guard, with no @tag timeout budget. Sole blocker between current state and GREEN-04 on measured CI run 33253587315. Passes locally (warm _build/prod, 109 tests 0 failures). Not fixed in 198-29 (documentation-only files_modified); candidate for a round-5 plan.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-29T13:12:34.726Z",
    "resolved_at": null
  },
  {
    "id": 19,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts",
    "line": 577,
    "description": "Un-inventoried CI-only Playwright failure on run 33253587315: getByRole('heading', {name: 'Row history', exact: true}) not found at operator-responsive-mobile-first.spec.ts:475 (helper), reached from :587/:584. Appears in no row of .planning/audits/198-round4-playwright.md (grep -c returns 0). Root cause NOT established -- diagnosis requires source outside 198-29's documentation-only files_modified. Candidate for a round-5 plan.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-29T13:12:40.719Z",
    "resolved_at": null
  },
  {
    "id": 20,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
    "line": 565,
    "description": "SETTLES entry #10/#12 (round 5): plan 198-31 fixed the /Expired|File unavailable/ regex, re-anchoring it to /Export expired|File unavailable/ (commit 82a517a0), matching the canonical Presentation.export_status_label/2 copy. Local re-run passed both projects (198-31-SUMMARY.md). Not a demo-seed content change; entries #10/#12's original text is unmodified per this ledger's append-only rule.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:10.521Z",
    "resolved_at": null
  },
  {
    "id": 21,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 38,
    "description": "SETTLES entry #11/#13 (round 5): plan 198-31 fixed the /Expired|File unavailable/ regex, re-anchoring it to /Export expired|File unavailable/ (commit 82a517a0), same cause and fix as entry #20 (accessibility spec). Local re-run passed both projects (198-31-SUMMARY.md). Entries #11/#13's original text is unmodified per this ledger's append-only rule.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:16.948Z",
    "resolved_at": null
  },
  {
    "id": 22,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs",
    "line": 56,
    "description": "SETTLES entry #18 (round 5): plan 198-30 moved the cold MIX_ENV=prod mix compile out of the per-test ExUnit timeout budget into a setup_all block (commit 1fe99275), eliminating the 60000ms ExUnit.TimeoutError this entry recorded. Measured cold compile=30.3s, warm=0.73s, warm guard-only mix demo.reset=0.748s (comfortably inside the 60000ms default; no @tag timeout: needed). Local mix verify.example = 109/0 twice, per D-01 a readiness signal only -- the measured-CI re-run is plan 198-37's concern, not proven closed here. Entry #18's original text is unmodified per this ledger's append-only rule.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:24.387Z",
    "resolved_at": null
  },
  {
    "id": 23,
    "kind": "deviation",
    "phase": "198",
    "file": "examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts",
    "line": 577,
    "description": "SETTLES entry #19 (round 5): plan 198-31 established the cause (the shared expectOperatorChrome helper's mobile-nav-toggle click firing the row-history drawer's own phx-click-away, row_history_component.ex, dismissing the drawer and navigating away before the Row history heading assertion runs), confirmed by direct standalone reproduction outside the harness, and fixed at cause test-side with a scoped exerciseMobileNav opt-out for the row-history route (commit 887198c6). This was a fix at cause, not an honest halt -- no lib/ file was touched. Local re-run passed both projects across 3 repeated runs (.planning/audits/198-round5-playwright.md, 198-31-SUMMARY.md coverage D2). Entry #19's original text is unmodified per this ledger's append-only rule.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-30T21:16:31.136Z",
    "resolved_at": null
  },
  {
    "id": 24,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "state.advance-plan parsed legacy body position and required reconciliation to Plan 53 of 55",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-09T22:11:55.348Z",
    "resolved_at": null
  },
  {
    "id": 25,
    "kind": "deviation",
    "phase": "198",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "Canonical state.advance-plan incremented stale prose position to 2 of 65; reconciled prose to structured 66 of 66 progress",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-10T22:19:12.757Z",
    "resolved_at": null
  },
  {
    "id": 26,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs",
    "line": null,
    "description": "Plan verify used unsupported mix test -x flag; execution used --max-failures 1 for RED and the unmodified targeted command for final GREEN verification",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T04:40:32.551Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 27,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "roadmap.update-plan-progress could not write the legacy Phase 199 0/TBD row; executor reconciled the checklist and progress row to 4/14 In Progress from live PLAN/SUMMARY counts",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T04:42:10.923Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 28,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/removed_artifact_contract_test.exs",
    "line": null,
    "description": "Plan 199-09 verify used unsupported mix test -x flag; execution used the same focused file list without -x for valid RED/GREEN and final verification",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T04:53:19.815Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 29,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-09 roadmap.update-plan-progress could not write the Phase 199 plan checklist/progress row; executor reconciled both to 5/14 In Progress from live PLAN/SUMMARY counts",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T04:56:33.631Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 30,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/clean_checkout_contract_test.exs",
    "line": null,
    "description": "Plan 199-10 replaced unsupported mix test -x verification syntax with --max-failures 1 on the installed Mix version",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T05:08:59.068Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 31,
    "kind": "deviation",
    "phase": "199",
    "file": "bench/audit_capture_bench.exs",
    "line": null,
    "description": "Plan 199-10 formatted newly-owned benchmark entrypoints when child-aware formatter coverage exposed drift",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T05:08:59.148Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 32,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-10 roadmap.update-plan-progress could not write the legacy Phase 199 plan checklist/progress row; executor reconciled both to 6/14 In Progress from live PLAN/SUMMARY counts",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T05:11:30.303Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 33,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "roadmap.update-plan-progress could not edit the legacy Phase 199 layout; reconciled eight summary-backed plans manually",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T14:19:51.495Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 34,
    "kind": "todo",
    "phase": "199",
    "file": "examples/threadline_phoenix/e2e/critic/label.ts",
    "line": 708,
    "description": "Pre-existing pair-label token wiring remains unimplemented outside Plan 199-05 filesystem scope",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T14:38:01.325Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 35,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-05 roadmap.update-plan-progress could not write the legacy Phase 199 layout; executor reconciled the checklist and progress row to 9/14 from live summaries",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T14:38:55.777Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 36,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "roadmap.update-plan-progress returned missing_phase_details; Plan 199-11 and 11/14 progress were reconciled manually",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:05:01.279Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 37,
    "kind": "deviation",
    "phase": "199",
    "file": "test/fixtures/operator_surface/critic-scores/.gitkeep",
    "line": null,
    "description": "Created the exact critic-scores destination parent after the fifth literal git mv initially found it absent.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:27:46.709Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 38,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs",
    "line": null,
    "description": "Adapted the live corpus validator to mechanical_floors, synthetic-set non-vacuity, suffixed scorecards, and veto-ordering semantics.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:27:46.846Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 39,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/phases/199-decouple/199-08-PLAN.md",
    "line": null,
    "description": "Replaced unsupported mix test -x verification flag with --max-failures 1.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:27:46.980Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 40,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/refute/transcripts/refute.veto-ordering.off-token-accent.json",
    "line": null,
    "description": "Restored pre-existing untracked scorecard and refute outputs moved physically by directory git mv to their original planning paths.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:27:47.126Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 41,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-08 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the checklist and summary-backed progress row to 12/14.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:30:08.403Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 42,
    "kind": "unmet-truth",
    "phase": "199",
    "file": "test/threadline/dialyzer_ignore_contract_test.exs",
    "line": 32,
    "description": "Full-build Dialyzer remains red because the sealed 22-file warning-origin set exceeds Plan 199-13's 14-file authority",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:42:53.646Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 43,
    "kind": "unrun-verify",
    "phase": "199",
    "file": ".planning/phases/199-decouple/199-13-PLAN.md",
    "line": null,
    "description": "Task 2 unused-filter verification was not run because Task 1 tripped the mandatory re-planning gate",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:42:53.810Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 44,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-13 roadmap.update-plan-progress returned missing_phase_details; executor marked the plan halted and Plan 199-14 blocked without increasing the 12/14 complete count.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T15:43:16.489Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 45,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": 510,
    "description": "roadmap.update-plan-progress could not update Phase 199; Plan 199-15 checklist row was marked manually.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T18:05:30.592Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 46,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/STATE.md",
    "line": null,
    "description": "state.advance-plan used stale pre-replan 14-plan position; executor reconciled Current Position to runnable Plan 16 of 21 after Plan 199-15 completion.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T18:06:20.458Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 47,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/phases/199-decouple/199-17-SUMMARY.md",
    "line": null,
    "description": "Temporary named Node tests were required to make source-verifier RED evidence machine-classifiable.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T18:46:58.670Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 48,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Roadmap progress required manual reconciliation after the SDK returned missing_phase_details.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T18:46:58.760Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 49,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Reconciled Phase 199 Plan 19 roadmap progress manually after roadmap.update-plan-progress returned missing_phase_details",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T19:27:17.503Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 50,
    "kind": "deviation",
    "phase": "199",
    "file": ".github/workflows/ci.yml",
    "line": null,
    "description": "Temporary exact measurement-branch push trigger added for the cold run and removed after evidence collection",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T20:29:40.961Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 51,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/ci_topology_contract_test.exs",
    "line": null,
    "description": "Tracer workflow-header matcher corrected to follow the established two-line roster contract",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T20:29:41.049Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 52,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-14 roadmap progress and next-plan position reconciled manually after roadmap.update-plan-progress returned missing_phase_details",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T20:30:32.770Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 53,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/main_ci_observer_contract_test.exs",
    "line": null,
    "description": "Plan 199-21 formatted two pre-existing contract files exposed by the planning-free aggregate format gate.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T21:44:55.050Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 54,
    "kind": "deviation",
    "phase": "199",
    "file": "test/threadline/removed_artifact_contract_test.exs",
    "line": null,
    "description": "Plan 199-21 removed hidden physical planning dereferences and supplied clean-clone npm/dev-PLT prerequisites required by the exact aggregate.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T21:44:55.155Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 55,
    "kind": "deviation",
    "phase": "199",
    "file": "mix.exs",
    "line": null,
    "description": "Plan 199-21 aligned local aggregate Dialyzer environment and browser projects with the committed CI topology.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T21:44:55.260Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 56,
    "kind": "deviation",
    "phase": "199",
    "file": "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts",
    "line": 130,
    "description": "Plan 199-21 fixed cross-scroll-state browser geometry sampling without relaxing the ordering assertion.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T21:44:55.367Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 57,
    "kind": "deviation",
    "phase": "199",
    "file": ".planning/ROADMAP.md",
    "line": null,
    "description": "Plan 199-21 roadmap.update-plan-progress returned missing_phase_details; executor reconciled the final checklist and 21/21 completion row manually.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-11T21:45:35.919Z",
    "resolved_at": null,
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
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-12T12:02:55.570Z",
    "resolved_at": null,
    "milestone": "v1.41"
  },
  {
    "id": 62,
    "kind": "deviation",
    "phase": "201",
    "file": "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts",
    "line": 108,
    "description": "Plan 201-05 gate amendment: the browser lane's 8 screenshot-regression failures (cases 108 dense-Timeline, 115 row-history, 136 Exports, 145 Retention, each on desktop-chromium and mobile-chromium) are PROVEN pre-existing, not a Phase 201 regression. Measured both ways: at phase HEAD the lane is 82 passed / 8 failed, and with Phase 201's five LiveView modules reverted to fecfe684 the identical 8 fail and the same 2 Home cases pass. Phase 201's entire production delta is 21 deleted data-earned-flow/data-persona/data-jtbd attribute lines and nothing else, which cannot alter raster output. Baselines last written in 180-04 (799c7d6e) and left byte-identical (hashes sealed in .planning/audits/201-rendered-output-evidence.md). The plan's original verify clause demanded a fully green lane, unsatisfiable without the baseline regeneration the same plan prohibits; it is amended to an exact non-regression gate pinning this 8-failure set, Home passing, immutable PNG hashes, and all 82 behavior/a11y/responsive cases green. Supersedes nothing; complements open entries 8, 14, 15. Also corrected: the clause invoked `playwright test` directly, which starts no app server and yields 45 spurious ~50ms invalid-URL failures; the lane must run via mix verify.example_browser / run-e2e.sh.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-21T00:00:00.000Z",
    "resolved_at": null,
    "milestone": "v1.41"
  }
]
````
