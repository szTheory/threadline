---
phase: 218-ci-economy-remove-waste
fixed_at: 2026-09-27T00:00:00Z
review_path: .planning/phases/218-ci-economy-remove-waste/218-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 218: Code Review Fix Report

**Fixed at:** 2026-09-27
**Source review:** .planning/phases/218-ci-economy-remove-waste/218-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (WR-01..WR-06; there were no critical findings)
- Fixed: 6. WR-03 was fixed only as far as locked decision D-04 allows; the gate behaviour it asked to change is recorded as a partial skip below.
- Skipped: 0 whole findings.
- Info findings IN-01..IN-05 were left alone. No warning fix covered one.

Where it ran: every fix was edited, tested and committed in the main checkout on
`milestone/v1.43`, with no worktree. All verification gates below also ran in the main
checkout, so they can be reproduced from this tree.

## Fixed Issues

### WR-01: Flake Detection writes a malformed GITHUB_OUTPUT line on the zero-header paths

**Files modified:** `.github/workflows/flake-detection.yml`, `test/threadline/flake_classifier_contract_test.exs`
**Commit:** 955afd33
**Applied fix:** The classify step now runs `grep -c ... ) || true`, then `${iterations:-0}`, then a bash `=~` integer guard. The old form was `|| echo 0`, which added a second bare `0` line. New contract row (Test 1e) runs the committed classify step body under `bash --noprofile --norc -eo pipefail` against four log shapes: zero headers with exit 2, empty with exit 124, a missing log, and three headers. It asserts exactly one `iterations=` line and no line without `=`.
**RED:** `zero-header log, suite never started: malformed lines ["classification=unknown", "reason=no suite header found in the log", "iterations=0", "0"]`

### WR-02: `inconclusive` discards a failure seen in the cut-off iteration, and treats every exit 137 as a budget expiry

**Files modified:** `bin/classify-flake-run`, `.github/workflows/flake-detection.yml`, `test/threadline/flake_classifier_contract_test.exs`, `CONTRIBUTING.md`
**Commit:** 9a33d54a
**Applied fix:**
- **Failure in the cut-off iteration.** On exit 124 or 137, the classifier scans the log for ExUnit failure evidence: an `N) test|doctest|property` entry, or a non-zero `failures`/`invalid` summary. If it finds any, it classifies `broken` (1 header) or `flaky` (2 or more) rather than `inconclusive`.
- **Exit 137.** The repeat step now records `elapsed_s=$SECONDS`. The classify step passes `ELAPSED_S` and `BUDGET_S: "3300"`, and a contract assertion ties `BUDGET_S` to the `55m` `timeout(1)` literal. Exit 137 counts as a budget kill only when `ELAPSED_S >= BUDGET_S`. An earlier kill, or a 137 without elapsed evidence, is `unknown` with a stated reason.
- **Tests and docs.** Test 1f adds seven rows: cut-off failure (flaky), first-iteration cut-off failure (broken), a summary line alone, a clean-summary control that stays inconclusive, 137 under budget, 137 with no evidence, and the workflow wiring. The existing 137 row now supplies elapsed evidence. The CONTRIBUTING outcome list and the classifier header describe both rules.

This changes classification logic, so it needs human verification: confirm the failure-evidence regex against a real ExUnit failure transcript on CI.
**RED:** 6 of the 7 new rows failed. Every new row classified `inconclusive`, for example `reason=budget exhausted after 1 clean iteration(s); iteration 2 was cut off by the time budget` for a log with `2460 tests, 1 failure`, and the wiring row failed because the workflow did not yet record `elapsed_s`. The seventh row, the clean-summary control, passed before and after the fix.

### WR-03: `broken-upstream` blocks the flake lane on explicit dispatch

**Files modified:** `bin/ci-sha-gate`, `.github/workflows/flake-detection.yml`, `test/threadline/ci_sha_gate_contract_test.exs`
**Commit:** 80b73d9f
**Applied fix:**
- **Header now matches D-03 and D-04.** The script header no longer says "workflow_dispatch and push never skip". It now says that dispatch and push never take the D-03 green-SHA skip, and that `broken-upstream` is not event-scoped (D-04). So a dispatch on a SHA whose ci.yml is red with no green re-run reports `broken-upstream`, and the header says to re-run ci.yml green to soak it.
- **Behaviour table and gate comment.** The behaviour-table row now reads "(any event)". The Flake Detection gate comment now says "broken-upstream applies to every event, dispatch included (D-04)" and no longer claims "dispatch always runs".
- **Contract pin.** A new test pins both texts.
- **Browser-full unchanged.** browser-full.yml's "push and dispatch always run" wording is accurate there, because that gate passes no `--upstream`.

**RED:** `the header must not claim a dispatch always runs: D-04 applies broken-upstream to every event`, and `refute comment =~ "dispatch always runs"` failed.
**Partial skip (locked decision):** the reviewer asked to scope `broken-upstream` to `schedule` so that a dispatch always runs, and optionally to narrow the upstream signal to the `verify-test` job. Neither was applied. D-04 in 218-CONTEXT.md reads "A red CI on the same SHA exits `broken-upstream`" with no event scope, and ROADMAP criterion 1 and REQUIREMENTS ECON-01 say the same. D-03 defines only the green-SHA skip and says nothing about dispatch. The existing contract row that expects `broken-upstream` on `workflow_dispatch` is kept. Changing that behaviour, or narrowing "red CI" to one job, is a scope decision for the maintainer.

### WR-04: The removed-docs and removed-tarball dominance contract does not pin the rehearsal-to-`verify.release` link

**Files modified:** `test/threadline/ci_topology_contract_test.exs`, `CONTRIBUTING.md`
**Commit:** b8239944
**Applied fix:** `dominance_errors/3` now takes `bin/verify-bump-rehearsal` and requires an uncommented `run_gate "..." mix verify.release` line. Two new mutation controls cover the gate line removed and the gate line commented out. The CONTRIBUTING `verify-docs` bullet now states that the rehearsal chains its gates (docs build only after the doc-contract and changelog gates pass) and names the new pin.
**RED:** `verify.release gate removed from the rehearsal mutation must make the dominance contract fail`

### WR-05: The Browser-full partition treats any `--project` text in a ci.yml `run:` body as "CI runs it"

**Files modified:** `bin/browser-full-projects`, `test/threadline/browser_full_projects_contract_test.exs`, `CONTRIBUTING.md`
**Commit:** 6e7d8f91
**Applied fix:**
- **Refuse conditional flags.** `ci_projects/2` now records each run body's line and key column. It exits 1 when a `--project`-bearing body sits in a step with a step-level `if:` or a job with a job-level `if:`, naming the step line or job and the projects.
- **Count only command arguments.** A flag counts only as an argument of a `mix`/`npx` command (at line start or after `&&`, `||` or `;`, with backslash continuations joined), so `echo` text never counts.
- **Live repo unchanged.** The output is still the four Browser-full projects.
- **Tests and docs.** Five new controls: step `if:` exits 1, job `if:` exits 1, an unrelated conditional step leaves the output unchanged, echo text leaves it unchanged, and a backslash-continued command still counts. The script header and CONTRIBUTING describe the rule.

**RED:** the step-if, job-if and echo controls failed. The other two passed before and after, as controls should.

### WR-06: The close-step marker pins compare against a literal, not the open step, and deps-health has no pin

**Files modified:** `test/support/ci_issue_pairing.ex` (new), `test/threadline/flake_classifier_contract_test.exs`, `test/threadline/browser_full_projects_contract_test.exs`, `test/threadline/deps_health_doc_contract_test.exs`
**Commit:** 7b50e442
**Applied fix:** New shared helper `Threadline.Test.CiIssuePairing.violations/3`. It extracts `TITLE_PREFIX` and `LABEL` from both the open and the close step, and requires them to be equal. It also requires that the open step passes `--marker "$TITLE_PREFIX"` and `--label "$LABEL"`, and the close step passes `--close --marker "$TITLE_PREFIX" --label "$LABEL"`. The flake and Browser-full literal checks were replaced with it, and deps-health gained the pin. Each lane has an open-step-only rename control for the prefix and the label. The helper is a new file because three test modules need the same check.
**RED:** `renaming only the open step (TITLE_PREFIX: "Flake Detection: suite") must fail the contract` and `renaming only the open step (TITLE_PREFIX: "Browser-full is failing") must fail the contract`. deps-health had no marker pin to go red, so its new rename control is what proves the pin catches a rename.

## Verification (main checkout, after all fixes)

- `mix test`: 9 properties, 2488 tests, 0 failures, 3 excluded
- `actionlint -shellcheck=`: exit 0
- `mix verify.format`: exit 0
- `mix verify.credo`: 4176 mods/funs, no issues
- `bin/verify-repo-hygiene`: 4022 tracked text files clean, exit 0

---

_Fixed: 2026-09-27_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
