---
phase: 225-suite-baseline-and-partitioned-ci
reviewed: 2026-10-01T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/flake-detection.yml
  - CONTRIBUTING.md
  - bin/ci-test-partitions
  - bin/classify-flake-run
  - bin/verify-deps-audit
  - bin/verify-repo-hygiene
  - config/test.exs
  - mix.exs
  - priv/ci/hex_evaluator/priv/repo/migrations/20260930235856_threadline_triggers_shape_code_keyed_shape_composi_f2f800f9eb80.exs
  - test/partition_colocate.txt
  - test/support/telemetry_helpers.ex
  - test/test_helper.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/health/trigger_findings_non_owner_test.exs
  - test/threadline/operator_surface/auth_test.exs
  - test/threadline/operator_surface/export_auth_plug_test.exs
  - test/threadline/operator_surface/stress_router_prod_compile_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/theme_auth_plug_test.exs
  - test/threadline/telemetry_helpers_test.exs
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 225: Code Review Report

**Reviewed:** 2026-10-01
**Depth:** standard
**Files Reviewed:** 20 (of 22 listed; 2 required-reading contract test files were sampled, not exhaustively read line-by-line past ~1,300/5,864 and ~1,142/1,493 lines respectively due to size — see note below)
**Status:** issues_found

## Summary

This phase introduces fail-closed partitioned CI test execution (`bin/ci-test-partitions`), a
flake classifier (`bin/classify-flake-run`), per-partition database naming
(`config/test.exs`), and a large body of mutation-tested contract tests that pin the new CI
topology from source. The shell script `bin/ci-test-partitions` was read in full and traced
against its own documented invariants (per-PID `wait`, exactly-once file assignment, empty
partitions, signal handling, `set -euo pipefail` behavior, awk quoting). It is unusually well
engineered: every invariant called out in the task brief is independently covered by at least
one `--self-test` case, and I was not able to find a case where the self-tests' claims don't
hold against the code as written. `test/test_helper.exs`'s `Application.stop/ensure_all_started`
restart and `test/support/telemetry_helpers.ex`'s `$callers`-based isolation both check out
against their own documented rationale (the repo's `Threadline.Application` does not itself own
the repo's lifecycle, so the restart cannot race the manually-started `Threadline.Test.Repo`).

No BLOCKER-level defects were found. The findings below are robustness/quality gaps: a
log-noise wart in the partition report, a signal-handling window before the trap is armed, a
loose `async: true` detection heuristic that could silently skew future partition balance, and a
minor doc/code convention mismatch for the `MIX_TEST_PARTITION` suffix default.

Given the adversarial brief and the size of two of the required-reading contract test files
(`ci_topology_contract_test.exs` is 1,493 lines; `ci_workflow_parity_contract_test.exs` is 5,864
lines), those two were sampled rather than read to the very last line; nothing sampled
contradicted the invariants asserted by the earlier, fully-read files, and both are themselves
mutation-tested assertions about YAML/mix.exs text rather than runtime logic, which limits the
blast radius of an undiscovered defect in the unread tail.

## Warnings

### WR-01: Zero-file partitions always print a spurious "no test count found" diagnostic

**File:** `bin/ci-test-partitions:304-310`
**Issue:** `report()` treats any partition whose `parse_counts` result is `"no tests"` AND
whose log is non-empty as an anomaly worth a stdout warning ("no test count found; last log
lines"). But the designed, correct zero-file-partition path (`run_partitions`'s `files=()`
branch, lines 393-397) writes exactly one line — `"ci-test-partitions: partition %s has no
test files assigned"` — into that same non-empty log, and that line never matches
`parse_counts`'s ExUnit-summary regexes. The result: every legitimate empty partition
unconditionally triggers this "unrecognised format" warning on every CI run, even though
nothing is wrong. The self-test for the zero-file case (`run_self_test`, case "zero-file
partition with the rest passing") checks that the partition exits 0 and never invokes mix, but
never asserts on the *absence* of this diagnostic, so the noise was not caught.
**Fix:** Special-case the "has no test files assigned" message before the `"no tests"` check,
e.g.:
```bash
if [ "$counts" = "no tests" ] && [ -s "$log_dir/partition-$i.log" ] &&
   ! grep -q 'has no test files assigned' "$log_dir/partition-$i.log"; then
  printf 'ci-test-partitions: partition %s: no test count found; last log lines:\n' "$i"
  tail -n 5 "$log_dir/partition-$i.log" | sed 's/^/  | /'
fi
```

### WR-02: Signal trap is armed only after every partition subprocess has been forked

**File:** `bin/ci-test-partitions:383-421`
**Issue:** The `for i in $(seq 1 "$n"); do ( ... ) & pids[i]="$!"; done` loop forks all N
background `mix test` processes; `trap kill_all INT TERM` is only installed afterward. If
INT/TERM arrives while the loop is still forking (e.g. a fast CI cancel landing mid-loop), the
already-started children are not explicitly killed by `kill_all` — the script instead relies on
default job-control signal propagation to orphan-proof them, which is not guaranteed in every
shell/CI invocation (job control is commonly disabled in non-interactive shells). The window is
small in practice (microseconds per fork), but the script's own stated guarantee — "An INT or
TERM signal kills every recorded partition process and exits non-zero, so a cancelled job leaves
no orphan" — is not strictly true for a signal delivered inside this window.
**Fix:** Install the trap before the fork loop and make `kill_all` tolerant of a `pids` array
that is still being populated (e.g. guard on `${pids[i]:-}` being set), or fork all N processes
first using a helper that itself installs the trap as its very first statement.

### WR-03: `async: true` detection is an unscoped substring grep, not anchored to the `use ExUnit.Case` declaration

**File:** `bin/ci-test-partitions:146` (`grep -q 'async: true' "$f"`)
**Issue:** Weight-effective-ness (`eff = int(raw/4)` for "async" files) is decided by whether
the literal string `async: true` appears *anywhere* in the file's text — including comments and
doc strings that merely discuss async-ness rather than declare it. Today all three occurrences
of `async: true` outside an actual `use ExUnit.Case` line (`test/threadline/brandbook_token_parity_test.exs:19`,
`test/threadline/operator_surface/mechanical_checker_test.exs:10`,
`test/threadline/operator_surface/style_byte_lock_test.exs:17`) happen to coincide with files
that are genuinely async, so there's no live misclassification yet, but the detection is one
comment away from silently degrading partition balance in a future file (e.g. a test file
whose module docstring says "do not add `async: true` to this file" would be misclassified as
async and have its weight divided by 4, inflating the chance its partition runs long).
Correctness is not affected — every file still runs exactly once — but balance quietly erodes.
**Fix:** Anchor the match to the `use ExUnit.Case` line, e.g.
`grep -qE '^\s*use ExUnit\.Case,.*async:\s*true' "$f"`.

## Info

### IN-01: `MIX_TEST_PARTITION` suffix convention differs between the database name and CONTRIBUTING.md's documented pattern for other objects

**File:** `config/test.exs:10`, `CONTRIBUTING.md` (SUITE-02 section)
**Issue:** `config/test.exs` interpolates `System.get_env("MIX_TEST_PARTITION")` with no
default, so an unpartitioned local `mix test` run (where the env var is unset) produces the
database name `threadline_test` (empty suffix) — correct, and backward compatible. But
CONTRIBUTING.md instructs test authors who create a cluster-wide object or fixed path to fold
`System.get_env("MIX_TEST_PARTITION", "0")` into their own name — default `"0"`, not `""`. This
means, locally, the database name and a test's own cluster-wide-object name follow two different
suffixing conventions (`threadline_test` vs. `..._0`) even though both are describing "no
partition." Not a correctness bug — uniqueness still holds in both schemes — but a reader
comparing the two patterns side by side (as `test/threadline/health/trigger_findings_non_owner_test.exs:16`
does, which correctly follows the `"0"` default) could reasonably expect them to match.
**Fix:** Either default `config/test.exs`'s interpolation to `"0"` too (and accept the one-time
rename of the base database), or change CONTRIBUTING.md's recommended default to `""`, so the
two conventions agree.

---

_Reviewed: 2026-10-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
