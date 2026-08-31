---
schema_version: 1
open_count: 22
waived_count: 0
fixed_count: 1
total_count: 23
last_updated: 2026-08-30T21:30:00.000Z
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
    "description": "GREEN-07 not verified this run — local commits unpushed by explicit orchestrator constraint; origin/main CI still red on last observed run 33138291361",
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
    "description": "CORRECTS entry #10: root cause established (plan 198-28 Task 3) — NOT a demo-seed content change (demo/seed/exports.ex was not touched by any plan this round). Actual cause: fix(198-25) commit e6f3cd5d changed the completed-expired export job's rendered label from Expired to Export expired (lowercase e), breaking this test's /Expired|File unavailable/ regex (capital E). Still out of scope for 198-28's declared files; needs follow-up plan to update the regex/assertion to match the corrected canonical copy.",
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
  }
]
````
