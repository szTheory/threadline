---
phase: 246-debt-closeout-and-critic-retirement
plan: 05
subsystem: ci-self-tests
tags: [debt, contract-tests, deps-health, ruleset, cache-key]
status: complete
requires: ["246-04"]
provides:
  - "required_context_hits/2 ruleset guard with negative control (215 WR-04)"
  - "five D-16 findings fixed plus 216 IN-01 fixed (not waived)"
affects: ["246-06 debt register rows for 215 WR-04/05/06, IN-03, 223 IN-01, 216 IN-01"]
tech-stack:
  added: []
  patterns: ["absence check paired with an in-test negative control", "mutation-checked doc wording assertions"]
key-files:
  created: []
  modified:
    - test/threadline/deps_health_doc_contract_test.exs
    - test/threadline/deps_audit_gate_test.exs
    - test/threadline/deps_health_report_test.exs
    - test/threadline/repo_hygiene_contract_test.exs
    - test/threadline/changelog_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
decisions:
  - "216 IN-01 fixed within D-17 (+14 net lines, 1 file), so the 246-06 register row is closed, not waived"
  - "215 IN-03's ci-required needs test removed because needs: cannot name a job in another workflow file; the WR-04 ruleset guard is the real non-required check"
metrics:
  duration: 5min
  completed: 2026-10-25
actuals:
  tokens: 2950
  tasks: 3
  commits: 6
plan_head_before: 404c33ee20f4a87c61f81ac2323f8a1601ef6c02
plan_head_after: 46efd9d42c9b95ac0045b782ea81c9c819eb943b
---

# Phase 246 Plan 05: D-16 CI self-test fixes Summary

The deps-health ruleset guard is now real: it decodes `.github/rulesets/main.json`, compares the `required_status_checks` contexts with the deps-health job `name:` read from the workflow through YamlElixir, and has a negative control. Four more vacuous or loose 215/223 assertions were tightened or deleted, and 216 IN-01 (the cache-key runner label was never compared with `runs-on`) was fixed within the D-17 cap. Six `test:` commits, all outside the critic removal range.

## Commits and D-17 numstat

| Finding | Commit | Files | +/- | Net | D-17 |
|---|---|---|---|---|---|
| 215 WR-04 | f29a40bf | deps_health_doc_contract_test.exs | +26 / -4 | +22 | ok (1 file) |
| 215 WR-05 | 1df4c803 | deps_health_doc_contract_test.exs | +16 / -3 | +13 | ok (1 file) |
| 215 WR-06 | f9764172 | deps_audit_gate_test.exs | +12 / -6 | +6 | ok (1 file) |
| 215 IN-03 | 9ff63692 | deps_health_doc_contract_test.exs, deps_health_report_test.exs | +0 / -22 | -22 | ok (2 files) |
| 223 IN-01 | 6e439225 | repo_hygiene_contract_test.exs, changelog_contract_test.exs | +20 / -0 | +20 | ok (2 files, 2 new tests in separate modules) |
| 216 IN-01 | 46efd9d4 | ci_workflow_parity_contract_test.exs | +17 / -3 | +14 | ok (1 file), **fixed, not waived** |

None of the commits touch `.github/`, `bin/`, a critic file, or a dependency (`git diff --name-only f29a40bf^ HEAD -- .github bin` is empty). None carry a `Removal-Slice:` trailer.

## What changed per finding

- **WR-04:** new pure `required_context_hits/2` that fails closed (`flunk`) when the ruleset has no required contexts. The live check asserts a non-empty job name and `[]` hits. The negative control appends `%{"context" => job_name, "integration_id" => 15_368}` through an `Access.filter` path, asserts the copy differs, and asserts it yields `[job_name]`. TDD RED was shown with the helper stubbed to `[]` (1 failure), then GREEN.
- **WR-05:** `lockfiles/0` derives from `canonical_dir_line!(@verify_deps_audit)` (`. bench examples/threadline_phoenix` maps to the three former literals) and asserts `length >= 3`.
- **WR-06:** the Hex-floor test now asserts the logged command column `== ["hex.info"]` and `refute log =~ "deps.unlock"`. The refute's negative control already exists: the clean-run test asserts that the same fake mix logs `deps.unlock --check-unused`. The canonical-dirs test compares the full path list with `==` (`real_root` comes from `Path.expand`, so it passes as-is on macOS). `pwds` / `_ = pwds` are gone.
- **IN-03:** deleted `refute after_report == nil` and its now-unused split binding (no warning under `--warnings-as-errors`). Deleted the ci-required `needs:` test. It could never fail, because `needs:` cannot reference a job in another workflow file.
- **223 IN-01:** each new assertion was mutation-checked against a reworded scratch CONTRIBUTING.md and failed every time: D-18 "file or folder", D-06 "must land under", and the unbackticked override. CONTRIBUTING.md was then restored with a path-scoped checkout. The live wording matched the planned strings exactly.
- **216 IN-01:** `job_toolchain_errors/2` reads the job's `runs-on:` and passes it to `cache_key_errors/4`. The new `runner_label_errors/3` requires a BEAM-keyed cache `key:` to start with `runs_on <> "-"`, which also covers the `${{ matrix.runner }}` form. Beam-independent and `cache-primary-key` save steps stay exempt, as they were. The mutation control `runs-on: ubuntu-26.04` with the key unchanged was added to the verify-format controls. With the check stubbed out, that control fails alone (1 failure), which proves it depends on the new check.

## Verification

- Task 1: `mix test test/threadline/deps_health_doc_contract_test.exs` gave 25 tests, 0 failures. The tracer gate re-run passed.
- Task 2: `mix compile --warnings-as-errors` passed, and the five files gave 186 tests, 0 failures. `bash -n bin/verify-deps-audit && bin/verify-deps-audit --self-test` exited 0.
- Task 3: `mix test test/threadline/ci_workflow_parity_contract_test.exs` gave 51 tests, 0 failures.
- `mix verify.credo`: no issues. `mix format --check-formatted`: clean.
- The tests ran against the existing local test DB with no connection errors, so no ephemeral postgres was started.

## Deviations from Plan

- **IN-03 binding:** instead of renaming the unused `[_, after_report]` binding, I deleted the duplicate split line outright. The remaining `[before_report, _]` match still raises if the string is absent. Same result, fewer lines.
- **WR-04 control shape:** I compacted it to a single `update_in` path, which took the net count from +30 to +22 so it sits under the cap with room to spare.

Otherwise the plan ran as written. STATE.md and ROADMAP.md were not touched, and WINDOWS.md was not touched.

## Known Stubs

None.

## Self-Check: PASSED

- All six modified test files exist and are committed.
- f29a40bf, 1df4c803, f9764172, 9ff63692, 6e439225 and 46efd9d4 are all ancestors of HEAD.
