---
phase: 218-ci-economy-remove-waste
plan: 06
subsystem: ci
status: complete
tags: [ci, flake-detection, github-actions, econ-01, econ-02]
requires: ["218-02", "218-05"]
provides:
  - "per-classification Flake Detection issue text driven by the classifier's reason"
  - "step `Close the flake tracking issue on a passing run` (upsert-ci-issue --close on pass only)"
  - "OS-family runner-context guard over every workflow"
affects: ["218-07", "218-08"]
tech-stack:
  added: []
  patterns:
    - "reporting_violations/1 list-of-violations helper with mutation controls, same shape as lane_shape_violations/1"
    - "needle assembled at runtime so the test file cannot match the sentence it forbids"
key-files:
  created: []
  modified:
    - .github/workflows/flake-detection.yml
    - test/threadline/flake_classifier_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
decisions:
  - "Only classification == 'pass' closes the flake tracking issue; skip, inconclusive, broken-upstream and unknown never close it"
  - "The inconclusive headline reports the clean-iteration count (headers minus one), matching the classifier's reason, not the raw header count"
  - "A broken-upstream issue body says no log artifact was uploaded, since the suite did not run"
metrics:
  duration: "about 10 min"
  completed: 2026-09-27
  tasks: 2
  files: 3
actuals:
  tokens: 3521
  tasks: 2
  commits: 3
plan_head_before: c2e75da72f08c312a9df9cd2f52ff17a630c21ca
plan_head_after: 56c77db3c6e5bb6602b7c9d65e3243f1344f9392
---

# Phase 218 Plan 06: Truthful flake issue text, close on pass, and an all-workflow OS-family guard Summary

The Flake Detection tracking issue now reports the cause the classifier found. `inconclusive` and `broken-upstream` each have their own text, and the unknown arm prints `Reason: ${REASON}` instead of the old fixed claim that no seed header was found. A `pass`, and only a `pass`, closes the issue through `bin/upsert-ci-issue --close`. The OS-family cache-key guard in the parity test now scans every workflow, not only ci.yml.

## What was built

**Task 1 (tracer), commit 57f91d17.** `flake-detection.yml`:
- The issue step takes `REASON: ${{ steps.classify.outputs.reason }}` and adds a `- Reason: ${REASON}` bullet.
- **`inconclusive)` arm.** Headline: the budget ran out after N clean iterations with no failure. Detail: this is not a flake report; re-measure the per-iteration time and resize the repeat count or the budget.
- **`broken-upstream)` arm.** Headline: ci.yml is red on this SHA, so the flake suite was not run. Detail: fix CI first, and the next weekly or dispatched run re-checks.
- **`*)` arm.** It states that the classification is unknown and prints the reason. The old sentence is gone.
- **Log note.** The pointer to the `flake-detection-log` artifact is now a variable. The broken-upstream arm swaps it for "no artifact was uploaded", because a gated-off run uploads nothing.
- **Close step.** New step `Close the flake tracking issue on a passing run`:
  - condition `if: always() && steps.classify.outputs.classification == 'pass'`;
  - `TITLE_PREFIX` and `LABEL: ci-flake` copied from the issue step, so the close matches #36 rather than printing `action=none` (the 218-02 hand-off);
  - a one-line body built with `mktemp` and a trap;
  - `bin/upsert-ci-issue --close --marker "$TITLE_PREFIX" --label "$LABEL" --body-file "$body_file"`.
- **Test 5** gains `reporting_violations/1`, a live test, and three mutation controls:
  - the old sentence re-inserted;
  - the close condition loosened to `always()`;
  - the close step pointed at the wrong label.
  Each control asserts `refute mutated == yaml` first.

**Task 2 (TDD), RED 597ccd5a, GREEN 56c77db3.** The test "no workflow names the OS-family runner context, comments included" loops `for {path, yaml} <- all_workflows()`. It runs the two existing ci.yml controls plus a new control that injects `# e.g. <OS-family context>` into the flake-detection.yml entry. Each control asserts that the errors name that exact path. `toolchain_contract_errors(all_workflows())` and the cache-key content check are unchanged. The D-05 key shape from 0ed0a5c5 was not re-edited.

`grep -c 'all_workflows()' test/threadline/ci_workflow_parity_contract_test.exs`: **3 before, 6 after**.

## TDD evidence

**RED** (597ccd5a). The widened test ran against an aggregator that kept the old ci.yml-only scope (`Map.take(..., [".github/workflows/ci.yml"])`). Both ci.yml controls passed. The target test then failed on the flake-detection.yml control's assertion:

```
  1) test toolchain pin contract no workflow names the OS-family runner context, comments included (Threadline.CIWorkflowParityContractTest)
     test/threadline/ci_workflow_parity_contract_test.exs:733
     OS-family context named only in a flake-detection.yml comment mutation must make the OS-family context check fail for .github/workflows/flake-detection.yml, got []

23 tests, 1 failure
```

**GREEN** (56c77db3). With the aggregator widened to every entry: `23 tests, 0 failures`.

## Verification

- `mix test test/threadline/flake_classifier_contract_test.exs test/threadline/ci_issue_upsert_contract_test.exs`: 32 tests, 0 failures.
- `mix test test/threadline/ci_workflow_parity_contract_test.exs`: 23 tests, 0 failures.
- Full `mix test` at 56c77db3: `9 properties, 2440 tests, 0 failures, 3 excluded`.
- `actionlint -shellcheck=`: clean. Full `actionlint` (with shellcheck) reports nothing for flake-detection.yml. It still flags four existing style/warning findings in release.yml, which this plan did not touch.
- `mix verify.format`: exit 0. `mix verify.credo`: no issues.
- Acceptance greps on flake-detection.yml:
  - `header was found`: 0;
  - `upsert-ci-issue --close`: 1;
  - `^ +(inconclusive|broken-upstream)\)`: 2;
  - `steps.classify.outputs.classification == 'pass'`: 1.
- Task 1's commit contains exactly the two planned files. The Task 2 RED and GREEN commits each contain only the parity test file.
- Tracer gate: `<verify>` passed on the committed Task 1 content before Task 2 started.

## Deviations from Plan

1. **[Rule 1 - Bug] Inconclusive headline count.** The plan's wording ("after ITERATIONS clean iteration(s)") would print the header count, which is one more than the clean count, because the last iteration whose header printed was cut off (218-05 decision). The headline therefore uses `$((ITERATIONS > 0 ? ITERATIONS - 1 : 0))`, which matches the classifier's reason string. Commit 57f91d17.
2. **[Rule 1 - Bug] Two misleading labels in the issue body.**
   - The bullet "Completed iterations before failure" was wrong for every outcome, since it shows the header count. It now reads "Suite headers seen".
   - The artifact pointer was false for broken-upstream. It is now a per-arm note.
   Commit 57f91d17.
3. **Stale wording fixed in the file being edited.**
   - The workflow header bullet "no failure at all creates and updates nothing" now says a pass closes the open issue, and names inconclusive and broken-upstream.
   - The label description lists all five non-pass outcomes.
4. **Extra control.** Besides the two controls the plan asked for, Test 5 adds a wrong-label control on the close step, because a mismatched LABEL is the exact failure 218-02 warned about.
5. **RED commit for a test-only task.** Task 2 is TDD, and the live repo already has no OS-family context. The RED therefore pins the old ci.yml-only scope in the aggregator, so the new flake-detection.yml control fails on its assertion. As a result there are three commits, not the two the plan's task list implies.

## Hand-offs

- No pushes, PRs, workflow dispatches or GitHub writes were made. The close path first runs for real on the 218-08 dispatch after the maintainer push. If that run classifies `pass`, it should close #36 with `action=close`.
- **ECON-01 is complete with this plan.** Its last clause (the report no longer falsely claims a missing header) landed in 57f91d17.

## Threat surface

- **T-218-16:** the close step runs only on `pass`, and the loosened-condition control turns Test 5 red. The close comment names the SHA, event and run URL.
- **T-218-17:** `REASON` comes from `bin/classify-flake-run`'s fixed strings. The body reaches `gh` only as a file argument.

No new security surface beyond the register.

## Self-Check: PASSED
