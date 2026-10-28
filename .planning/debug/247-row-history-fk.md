---
status: verifying
trigger: "Local CI run 40452150109 minimum job 122017125177, P3 seed 675682, row_history_live_test.exs:361: support_txn and admin_txn inserted at 365–366, child support insert at 368 fails audit_changes_transaction_id_fkey because parent is missing."
created: 2026-10-27
updated: 2026-10-27
---

## Current Focus

bug_class: Heisenbug / concurrency
hypothesis: Confirmed. PrunerTest ends after accepting a second run but before its unlinked Task.start worker exits; that worker can later delete RowHistoryLiveScopedTest's temporarily childless parent.
test: Completed. An advisory-lock regression test requires the accepted worker to be test-supervised and alive while blocked; it failed on a temporary Task.start revert and passed after reapplication. PrunerTest and RowHistoryLiveTest passed together across six seeds, then four more after closing the short-timer startup window.
expecting: Parent's full production partitioned gate confirms the fix within the original 31-file P3 assignment.
next_action: Parent runs the production partitioned gate after merging other local fixes; compare P3 result to CI failure and keep this journal if anything recurs.

ranked_hypotheses_before_probes:
  1: "Code/concurrency: Pruner's unlinked Task.start worker persists after its test and orphan cleanup deletes the childless parent; predict ordered purge reproduces exact FK and no-purge does not."
  2: "Config/environment: nested Mix invocation or unpartitioned process targets the same DB despite MIX_TEST_PARTITION; predict current_database differs from threadline_testfk247 or another process uses it."
  3: "Config/code: global storage_schema changes between the two inserts; predict repo_opts resolves a different prefix for parent and child."
  4: "Data/code: generated transaction id or returned struct does not name the stored parent; predict Repo.get immediately after insert is nil without any intervening cleanup."
and_gate: "Yes: the FK race requires an asynchronous global orphan sweep AND a parent/child fixture split across separate committed statements. Either condition alone is insufficient."
reasoning_checkpoint:
  hypothesis: "A pruner worker that outlives PrunerTest deletes a newly inserted childless AuditTransaction in a later row-history test because workers are Task.start-unlinked and PrunerTest can return after a run is only accepted."
  confirming_evidence:
    - "P3 assignment includes both PrunerTest and RowHistoryLiveScopedTest; the latter inserts two committed parents before any child."
    - "Controlled probe stopped the pruner GenServer while its worker remained alive, then released its advisory lock; the worker deleted a fresh parent and child insert failed the exact audit_changes_transaction_id_fkey."
    - "PrunerTest's later deliberate run assertion waits only for RetentionRun count==2, not worker completion."
  falsification_test: "If all PrunerTest workers are drained before teardown but the same P3 narrow run still produces the FK failure, or if no worker is alive after the accepted-run test, this diagnosis is incomplete."
  fix_rationale: "Running PrunerTest workers under its ExUnit-owned Task.Supervisor makes them terminate synchronously before the next test and before on_exit restores retention config, removing the cross-test destructive actor. The row-history fixture then owns its database state for its full test."
  blind_spots: "The original CI run has no worker PID trace, and other P3 tests could start destructive background work; local timing may differ from CI."
  candidate_causes:
    - "code/concurrency: unlinked Task.start worker lifecycle exceeds its test."
    - "config/environment: partition database collision or storage schema mutation."
    - "data: returned transaction ID might not match stored parent."
  and_gate: "yes — worker overlap plus a temporarily childless committed parent are both necessary for this FK path."

## Symptoms

expected: The support and admin AuditTransactions remain visible when their AuditChanges are inserted.
actual: In the P3 minimum job, the support AuditChange insert reported its transaction_id parent missing.
errors: audit_changes_transaction_id_fkey
reproduction: CI minimum job 122017125177, seed 675682, scoped row_history_live_test.exs:361; local reproduction pending.
started: observed in run 40452150109.

## Eliminated

- hypothesis: "The inserted AuditTransaction ID is stale or not persisted before its AuditChange insert."
  evidence: "In the controlled probe, Repo.get found the parent immediately after insertion using the returned ID; it vanished only after a retention orphan sweep."
  timestamp: 2026-10-27
- hypothesis: "Parent and child default to different storage schema prefixes in the failing fixture."
  evidence: "The local test repo resolved prefix threadline for both operations; the ordered purge alone changed the outcome without changing prefix."
  timestamp: 2026-10-27

## Evidence

- timestamp: 2026-10-27
  checked: CI P3 failure log and exact row-history test
  found: Both parents were inserted as independent Repo calls at lines 365–366, then the support child insert failed at line 368 with audit_changes_transaction_id_fkey. The scoped test passes alone with seed 675682 in a unique local partition.
  implication: The failure is intermittent and requires a cross-statement disturbance; the isolated test is a green control.
- timestamp: 2026-10-27
  checked: test helper, test config, retention implementation, and P3 assignment
  found: Tests use a real unsandboxed DB; P3 contains PrunerTest. Pruner launches workers with unlinked Task.start, and Retention.purge deletes every currently childless AuditTransaction when delete_empty_transactions is true, independent of occurred_at.
  implication: A worker that outlives its initiating test can remove parents between fixture inserts; this is a candidate pending direct reproduction.
- timestamp: 2026-10-27
  checked: /private/tmp/threadline-fk247-probe.exs via MIX_ENV=test MIX_TEST_PARTITION=fk247 mix run
  found: current_database() was threadline_testfk247 and repo prefix was threadline. The parent was visible immediately after insertion. Explicit Retention.purge removed it, and the subsequent child insert failed audit_changes_transaction_id_fkey exactly.
  implication: Orphan sweep is a red-capable deterministic feedback loop for this FK mechanism. A wrong returned ID or default schema mismatch is contradicted in this controlled case.
- timestamp: 2026-10-27
  checked: /private/tmp/threadline-fk247-worker-lifecycle.exs via MIX_ENV=test MIX_TEST_PARTITION=fk247 mix run
  found: A pruner worker remained alive after GenServer.stop(pruner). After release of an advisory lock, that worker deleted a freshly inserted childless parent and the child insert failed the exact CI foreign key constraint.
  implication: An accepted run can outlive the pruner test supervisor and mutate a subsequent test's fixture; PrunerTest must await spawned workers at teardown.
- timestamp: 2026-10-27
  checked: PrunerTest worker PID instrumentation at teardown, P3 seed 675682
  found: The test "trigger persists one run before acknowledgement and permits a later deliberate run" had 2 tracked workers, 1 still alive at test exit; all other PrunerTest cases had 0 alive. With a Task.Supervisor, that test had 1 active child at test end and its supervisor was gone before on_exit restored config. Temporary instrumentation was removed.
  implication: This exact test leaked the destructive task; ExUnit's per-test supervisor now owns its lifetime.
- timestamp: 2026-10-27
  checked: Fix-site revert/reapply against line-98 regression test
  found: With task_start temporarily changed back to Task.start, the regression failed "the accepted worker must belong to the test supervisor" (9 tests, 1 failure, 8 excluded). Reapplying Task.Supervisor.start_child restored 9 tests, 0 failures, 8 excluded.
  implication: The regression test detects removal of the lifecycle fix and confirms the fix site controls its oracle.
- timestamp: 2026-10-27
  checked: Final narrow validation and formatting
  found: PrunerTest plus RowHistoryLiveTest passed 19 tests with 0 failures for seeds 675682 and 1–5 after the regression assertion was added. `mix format --check-formatted test/threadline/retention/pruner_test.exs`, `git diff --check`, and debug-log cleanup check passed.
  implication: The modified test harness preserves nearby behavior locally; the original 31-file CI partition remains a separate gate owned by the parent agent.
- timestamp: 2026-10-27
  checked: Scheduled worker startup window
  found: One PrunerTest uses a 10 ms timer. The helper now starts Pruner with a long initial timer, injects Task.Supervisor.start_child, then arms the requested timer. The same 19 adjacent tests passed for seeds 675682 and 1–3 after this change; format and diff checks passed.
  implication: A slow CI scheduler cannot fire that test's first prune before worker ownership is installed.

## Resolution

root_cause: "PrunerTest's second accepted run can still have an unlinked Task.start worker at test exit. A later RowHistoryLiveScopedTest commits empty AuditTransactions before inserting AuditChanges; the orphan sweep can delete a parent between those statements, causing audit_changes_transaction_id_fkey."
fix: "Start a Task.Supervisor under PrunerTest's ExUnit test supervisor and inject Task.Supervisor.start_child into the existing pruner task_start seam; arm short scheduled runs only after injection; strengthen the second accepted-run test with an advisory-lock assertion that its worker is test-owned."
oracle_type: derived
verification:
  target_test: {result: pass, command: "mix test test/threadline/retention/pruner_test.exs:98 --seed 675682"}
  mutation_check: {result: skipped, reason_if_skipped: "Stryker is not configured for this Elixir project; manual fix-site revert was killed by the regression test."}
  no_op_deletion: {result: pass, deletion_justified_by_rca: false}
  adjacent_tests: {result: pass, suites_run: ["PrunerTest + RowHistoryLiveTest, 19 tests x 10 seeds before regression assertion, x 6 seeds after assertion, x 4 seeds after timer hardening; all 0 failures"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true}
  guardrail_verdict: accepted
  limitation: "The original 31-file P3 partition and full production partitioned gate were not run by this agent."
files_changed: [test/threadline/retention/pruner_test.exs]
