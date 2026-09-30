---
phase: 218-ci-economy-remove-waste
reviewed: 2026-09-27T00:00:00Z
depth: standard
files_reviewed: 31
files_reviewed_list:
  - .github/workflows/branch-protection.yml
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/community-health.yml
  - .github/workflows/deps-health.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - CONTRIBUTING.md
  - bin/browser-full-projects
  - bin/ci-sha-gate
  - bin/classify-flake-run
  - bin/upsert-ci-issue
  - bin/verify-dialyzer-slice
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - guides/upgrade-path.md
  - mix.exs
  - scripts/ci/README.md
  - test/test_helper.exs
  - test/threadline/browser_full_projects_contract_test.exs
  - test/threadline/ci_all_dedup_contract_test.exs
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_issue_upsert_contract_test.exs
  - test/threadline/ci_sha_gate_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/deps_health_doc_contract_test.exs
  - test/threadline/dialyzer_slice_contract_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/upgrade_path_doc_contract_test.exs
  - test/threadline/zero_skips_contract_test.exs
findings:
  critical: 0
  warning: 6
  info: 5
  total: 11
status: issues_found
---

# Phase 218: Code Review Report

**Reviewed:** 2026-09-27
**Depth:** standard
**Files Reviewed:** 31
**Status:** issues_found

## Summary

I reviewed the phase-218 diff (`git diff 2160754d HEAD`) for all 31 files. I also
read the parts of `bin/verify-bump-rehearsal` and
`test/threadline/operator_surface/mechanical_checker_test.exs` that the removal
justifications depend on.

The core safety properties hold:

- **`bin/ci-sha-gate`.** It fails open to `run` on any gh, jq or count error. `skip` is reachable only from `schedule` plus an own-workflow success on the exact `head_sha`, and `--sha` and `--workflow` are validated before any URL is built.
- **`bin/verify-dialyzer-slice`.** It fails closed on a `:dialyzer.run error:` line or when the completion-marker count is not exactly 1.
- **`bin/upsert-ci-issue --close`.** It never closes on ambiguity, and it validates the issue number before use.
- **Removed jobs.** Each of the three has a dominator on the same triggers:
  - `mechanical_checker_test.exs` is untagged and runs in `verify-test`.
  - `verify.release` builds docs with `--warnings-as-errors` and runs `hex.build`.
  - `verify-hex-evaluator` compiles and tests the tarball.
- **ECON-03 guard.** It exports only the boolean `secrets.RELEASE_PLEASE_TOKEN != ''` and never queries runs.
- **Workflow permissions.** They are least-privilege. `actions: read` and `issues: write` are job-scoped.
- **Shell injection.** No `${{ }}` expression that carries attacker-controlled text reaches a `run:` body.

I found no blocker. The defects are in the reporting paths:

- The Flake Detection `iterations` derivation writes a malformed `GITHUB_OUTPUT` on exactly the zero-header path the new classifier added.
- The classifier throws away failure evidence in a timed-out iteration, and it treats every exit 137 as a budget expiry.
- `broken-upstream` suppresses the flake lane, even on an explicit dispatch, in the situation where the lane is most useful.
- Two contract pins are weaker than their messages claim:
  - The rehearsal-to-`verify.release` link is not pinned.
  - The close-step marker is compared to a literal, not to the open step.
- The Browser-full partition is only syntactic.

## Warnings

### WR-01: Flake Detection writes a malformed GITHUB_OUTPUT line on the zero-header paths

**File:** `.github/workflows/flake-detection.yml:163-168`

**Issue:** `iterations=$(grep -c 'Running ExUnit with seed:' flake-detection.log 2>/dev/null || echo 0)` goes wrong when the log exists but contains no header. `grep -c` prints `0` and exits 1, so `|| echo 0` prints a second `0`, and `iterations` becomes `"0\n0"`. I reproduced this locally.

The guard `printf '%s' "$iterations" | grep -Eq '^[0-9]+$'` still passes, because `grep` matches line by line. The step then appends `iterations=0` followed by a bare `0` line to `$GITHUB_OUTPUT`. The runner rejects a line without `=` ("Invalid format"), so the Classify step fails and its outputs are unreliable.

This path is reached exactly by the cases 218-05 added or kept:

- a `timeout(1)` expiry before the suite starts (the classifier's "timed out before the suite started" row);
- a `test_helper.exs` raise, or a compile error inside `mix verify.flake` (the UNKNOWN row).

The UNKNOWN report the lane exists to file then shows up as a failed Classify step. The classification token in the issue may be empty or lost.

**Fix:**
```bash
iterations=$(grep -c 'Running ExUnit with seed:' flake-detection.log 2>/dev/null) || true
iterations=${iterations:-0}
if ! [[ "$iterations" =~ ^[0-9]+$ ]]; then iterations=0; fi
```
Add a classifier-contract row for this: a log file with zero headers must produce exactly one `iterations=` line.

### WR-02: `inconclusive` discards a failure seen in the cut-off iteration, and it treats every exit 137 as a budget expiry

**File:** `bin/classify-flake-run:108-119`

**Issue:** Exit 124 or 137 with at least one header always classifies as `inconclusive`, and the reason text says "budget exhausted after N clean iteration(s)". Two cases break that claim:

1. ExUnit's CLI formatter prints each failure as its test finishes. A test can fail inside the iteration the budget cuts off, and `--repeat-until-failure` would have stopped after that iteration. The log then contains a real failure, but the run is filed as "not a flake report ... resize the budget". That is a flaky or broken suite being reported as a sizing problem, the same mislabeling D-35 forbids in the other direction.
2. Exit 137 means SIGKILL from any source, not only `timeout --kill-after`. An OOM-killed BEAM (a genuine suite defect) also exits 137 through `timeout` and is classified `inconclusive`.

**Fix:** Before choosing `inconclusive`, scan the log for ExUnit failure entries, for example `^\s+[0-9]+\) test ` or a `, [1-9][0-9]* failures?` summary line. If one is found, classify `flaky` (headers >= 2) or `broken` (headers == 1). Distinguish a real budget expiry from other kills by recording the elapsed wall time in the workflow step, and only map 137 to `inconclusive` when the elapsed time is at or over the budget. Add table rows for "124 with a failure line in the cut-off iteration" and "137 well under budget".

### WR-03: `broken-upstream` blocks the flake lane on explicit dispatch, and whenever ci.yml is red for any reason

**File:** `bin/ci-sha-gate:26-30, 106-115`; `.github/workflows/flake-detection.yml:89`

**Issue:** The script header says "workflow_dispatch and push never skip: an explicit request ... must produce a real run". However, the upstream check is not event-scoped. On `workflow_dispatch`, a red ci.yml on the SHA returns `broken-upstream`, and the suite never runs. The contract test pins this at `ci_sha_gate_contract_test.exs:106`.

A red ci.yml on `main` with no re-run is the typical symptom of an intermittent test. That is exactly when a maintainer dispatches Flake Detection, and the gate refuses. The check also counts any ci.yml failure (an `verify-deps-audit` advisory, a hex.pm outage in `verify-hex-evaluator`, `verify-repo-hygiene`) as "the suite is broken". None of those says anything about the flake suite.

**Fix:** Scope `broken-upstream` to `schedule`, as `skip` already is, so that a dispatch always runs:
```bash
if [ "$decision" = "run" ] && [ -n "$upstream" ] && [ "$event" = "schedule" ]; then
```
Update the contract row at line 106 to expect `run` for dispatch. Optionally, narrow the upstream signal to the `verify-test` job's conclusion rather than the workflow's.

### WR-04: The removed-docs and removed-tarball dominance contract does not pin the rehearsal-to-`verify.release` link

**File:** `test/threadline/ci_topology_contract_test.exs:995-1050`

**Issue:** The dominance proof chains four facts:

1. The `verify-bump-rehearsal` job runs `mix verify.bump_rehearsal`. This is pinned.
2. The alias invokes `bin/verify-bump-rehearsal`. This is pinned at line 767.
3. `bin/verify-bump-rehearsal` runs `mix verify.release`. This is **not pinned**.
4. `verify_release/1` contains the docs build and `hex.build`. This is pinned.

The failure message at line 1027 asserts "which runs verify.release" with no check behind it. If someone edits `bin/verify-bump-rehearsal:452` (the `run_gate "mix verify.release at $NEXT" mix verify.release` line), every pin stays green. The ExDoc and `hex.build` proofs for the removed `verify-docs` and `verify-hex-package` jobs then silently disappear from per-PR CI.

The rehearsal's `&&` chain also means docs are built only when the doc-contract and changelog gates pass first. That is acceptable, but it is worth stating in the CONTRIBUTING bullet.

**Fix:** Add a check to `dominance_errors/2` that `bin/verify-bump-rehearsal` contains an uncommented `run_gate ... mix verify.release` line. Add a mutation control that removes it.

### WR-05: The Browser-full partition treats any `--project` text in a ci.yml `run:` body as "CI runs it"

**File:** `bin/browser-full-projects:247-260`

**Issue:** `ci_projects/2` collects every `--project` flag found in any ci.yml `run:` body and ignores every condition that controls whether that body executes:

- a step-level `if:` (for example `if: matrix.lane == 'current'` or `if: github.event_name == 'schedule'`, which never fires in ci.yml);
- a job-level `if:`;
- text inside an `echo` or heredoc.

A project that ends up there is removed from Browser-full, but it does not run on PR or push. It then runs nowhere, and the partition contract, which compares set text, stays green. This is the exact "runs nowhere" failure D-07 was written to prevent. Today, the flags sit in unconditional steps of unconditional jobs, so the live repo is correct. The guarantee is weaker than the CONTRIBUTING wording "a newly added project cannot end up running nowhere".

**Fix:** When collecting run bodies, also capture the enclosing step's and job's `if:`. Either refuse (exit 1) when a `--project`-bearing step or job carries any `if:`, or exclude those flags from the CI set. Add a mutation control that puts `if: github.event_name == 'schedule'` on the `verify-example-browser` run step and expects a non-zero exit or the project in the Browser-full output.

### WR-06: The close-step marker pins compare against a literal, not against the open step, and deps-health has no pin

**File:** `test/threadline/browser_full_projects_contract_test.exs:472-475`; `test/threadline/flake_classifier_contract_test.exs:526-528`; `test/threadline/deps_health_doc_contract_test.exs:200-222`

**Issue:** The assertion message reads "close step must use the issue step's TITLE_PREFIX and LABEL". The check, however, only matches the close step against a hard-coded string. If someone changes the open step's `TITLE_PREFIX` or `LABEL`, for example renaming the Browser-full title, the test stays green. The close step then finds nothing (`action=none`) and tracking issues stop closing, which is the #28/#36 failure mode ECON-02 fixed.

`deps_health_doc_contract_test.exs` checks only the close step's `if:`, so its marker and label are not compared at all.

**Fix:** Extract `TITLE_PREFIX` and `LABEL` from both the open step and the close step of each workflow, and assert that they are equal. Add a mutation control that changes only the open step's prefix.

## Info

### IN-01: Step outputs are interpolated with `${{ }}` directly into `run:` bodies

**File:** `.github/workflows/flake-detection.yml:289`; `.github/workflows/deps-health.yml` (the "Fail the job" step)

**Issue:** `${{ steps.classify.outputs.classification }}` and `${{ steps.report.outputs.classification }}` are spliced into shell text. Today the values come from fixed token sets, so this is not exploitable. It is still the pattern the rest of these workflows avoid by passing values through `env:`.

**Fix:** Pass the values through `env: CLASSIFICATION: ...` and reference `"$CLASSIFICATION"` in the body.

### IN-02: `--close` matching is a bare title prefix with no delimiter

**File:** `bin/upsert-ci-issue:47`

**Issue:** `startswith("Dependency health")` also matches a human-filed `ci-deps` issue titled, for example, "Dependency health policy discussion". With one automation issue open, that yields two matches. Close mode then dies with "ambiguous" and turns a clean deps-health run red. With no automation issue open, the close step closes the human's issue.

**Fix:** Match `startswith($marker + ":")` or an exact-title shape per lane, or add a hidden body marker, such as an HTML comment, and filter on it.

### IN-03: Stale cross-reference in the Browser-full cron comment

**File:** `.github/workflows/browser-full.yml:31-32`

**Issue:** The comment says "offset from Flake Detection's 07:00 so the two heavy scheduled lanes do not contend". Flake Detection now runs only on Mondays, so the nightly-contention rationale no longer applies six days a week.

**Fix:** Reword the comment to reflect the weekly flake cadence.

### IN-04: The zero-skips test still asserts ExUnit's live exclude list, which Mix CLI filters rewrite

**File:** `test/threadline/zero_skips_contract_test.exs:74-86`

**Issue:** `test_helper.exs` now writes `:default_test_excludes` precisely because `mix test file:LINE` and `--only` rewrite ExUnit's exclude list. This test still asserts `ExUnit.configuration()[:exclude] == expected` first. Running it by line (`mix test test/threadline/zero_skips_contract_test.exs:74`) therefore fails spuriously. This is pre-existing, but the new app-env key makes the first assertion redundant.

**Fix:** Assert only against `Application.fetch_env!(:threadline, :default_test_excludes)`, or skip the live-list comparison when `:test` is in the exclude list.

### IN-05: `refute-capture`'s new dependency regenerates committed scorecards on local targeted runs

**File:** `examples/threadline_phoenix/e2e/playwright.config.ts:87`

**Issue:** `dependencies: ["tier-a-capture"]` is correct for Browser-full. However, any local `--project=refute-capture` run now also runs `tier-a-capture`, which rewrites `test/fixtures/operator_surface/scorecards/`. A developer who re-captures refute poles can end up with a dirty tree of committed evidence they did not intend to change.

**Fix:** Mention this in the config comment and in CONTRIBUTING's capture-lane notes. Alternatively, make the refute spec create the cell directories it needs, so that no execution dependency is required.

---

_Reviewed: 2026-09-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
