---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 1
total_count: 3
last_updated: 2026-08-28T14:32:17.826Z
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
  }
]
````
