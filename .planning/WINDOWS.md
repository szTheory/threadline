---
schema_version: 1
open_count: 7
waived_count: 0
fixed_count: 1
total_count: 8
last_updated: 2026-08-28T17:31:39.078Z
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
  }
]
````
