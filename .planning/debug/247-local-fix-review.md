# 247 Local Fix Review

**Scope:** Diff from `HEAD` for `test/partition_colocate.txt`,
`test/threadline/storage/local_test.exs`,
`test/threadline/ci_topology_contract_test.exs`, and
`test/threadline/retention/pruner_test.exs`.

The colocation change and test-owned retention worker supervisor address the
reported shared-filesystem and worker-lifetime hazards. I found no confirmed
defect in the reviewed source changes. I also read
`.planning/debug/247-export-fixture-isolation.md` and
`.planning/debug/247-row-history-fk.md`; both notes distinguish local evidence
from the outstanding production partitioned gate, and the FK note records its
root cause, fix, and local verification.

## Finding Reassessment

The initial concern that the topology harness read the wrong log directory was
incorrect. `CI_TEST_PARTITIONS_LOG_DIR` is `Path.join(dir, "logs")`, and the
production runner's working directory is the copied project root `dir`, so its
relative `logs/partition-*.files` glob resolves to the supplied log directory.
The focused test at `test/threadline/ci_topology_contract_test.exs:264` passed
locally with a unique `MIX_TEST_PARTITION` and the requested test database:
`31 tests, 0 failures, 30 excluded` (0.8 s). This exercises both the grouped
case and the removed-colocation negative control. The finding is withdrawn.

I reviewed the finalized Pruner change, including the long startup timer,
post-seam timer arming, and lock-held worker-ownership assertion. The helper
starts the GenServer with a long timer, replaces its task start function and
interval, then schedules the requested short timer; the short scheduled test
therefore cannot dispatch before test-owned workers are installed. The
advisory-lock assertion isolates the second accepted run's worker after the
first run has reached terminal state. I found no confirmed correctness or
coverage defect in this change. The updated FK journal records the local
reproduction, fix-site revert check, neighboring-test runs, and explicitly
leaves the original P3 gate to the parent.

Final focused validation against the isolated local database:

- Topology regression: 31 tests, 0 failures, 30 excluded (0.8 s).
- Pruner and row-history tests, seed 675682: 19 tests, 0 failures (1.6 s).

## Review Limits

No production-source change or phase-level CI success is inferred from the
local evidence. The full production partitioned gate remains outstanding.

## Temporary CI Diagnostic Patch Review

**Scope:** Temporary diff only for `.github/workflows/ci.yml`,
`test/test_helper.exs`, and `test/support/startup-profile.files`.

**Result:** No confirmed defects found.

The startup trace is enabled only on the `min` lane's existing `Run tests`
step, via an environment variable inherited by its partition processes. It
emits fixed phase names, partition IDs, and VM wall-clock milliseconds; it does
not include application data or credentials. The existing lane matrix, test
step, self-test, timeout, thresholds, and weights are unchanged. The profile
step is also min-only, bounded by a two-minute timeout, records its exit status,
requires the compilation-cycle marker, rejects compilation errors, and accepts
the known Elixir 1.15 path diagnostic only with the profile output present. The
artifact is min-only, uniquely named by run ID, retained for 14 days, and uses
the repository's existing pinned upload-artifact action under `contents: read`
permissions.

I compared the 31 entries in `test/support/startup-profile.files` against the
P3 rows in `/tmp/threadline-247-current-min-assignment.tsv`; they match exactly.
The captured partition assignments are copied alongside the helper trace and
profile output, preserving enough context to distinguish the frozen P3 inputs
from the normal run's assignment. This remains temporary diagnostic evidence;
it does not establish a production gate result.

No test or CI workflow was run for this diagnostic-only review.
