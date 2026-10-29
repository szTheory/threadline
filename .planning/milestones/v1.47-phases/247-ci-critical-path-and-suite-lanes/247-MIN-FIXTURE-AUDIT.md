# Phase 247 Plan 26: Min-lane fixture audit (D-25(a))

**Head replayed:** `6c5dc51441c9dde44b9647d6b12e7729226f040b` (milestone/v1.47).
**Toolchain:** `hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824`
(Elixir 1.15.8, OTP 26.2.5.21), against an ephemeral `postgres:15` (15.18) on a
private Docker network. This matches CI's min-lane toolchain and PostgreSQL major
(ci.yml matrix `lane: min`, `pg: "15"`). It ran on the local arm64 architecture,
not CI's AMD64 Ubuntu 24.04 runner.

**Method.** The source was a `git archive` of the head, extracted into scratch
(`<scratch>/src`) and mounted read-only into the min container. Inside the
container it was copied to a container-local work tree with its own `_build`
and `deps`. The live worktree was never mounted read-write. `git` and `jq` were
installed with apt only inside the disposable container. The copy was
snapshotted as a single local git commit, because
`clean_checkout_contract_test.exs`, which is in the P3 list, needs a real git
work tree. Each invocation used `DB_HOST=<pg15 container> DB_PORT=5432` and its
own `MIX_TEST_PARTITION` (so its own `threadline_test<id>` database). The file
lists are the failed runs' own `partition-<i>.files` from the
`partition-logs-min-<run>` artifacts. Every failing test and seed was confirmed
in the ANSI-stripped `partition-<i>.log`.

## Failure 1: run 40452150109, P3, seed 675682 (FK on audit_changes_transaction_id_fkey)

- **Failing test:** `test/threadline/operator_surface/live/row_history_live_test.exs:361`
  (`RowHistoryLiveScopedTest`). CI result: 397 tests, 1 failure, 1 excluded.
- **Mechanism:** `PrunerTest` "trigger persists one run before acknowledgement
  and permits a later deliberate run" could return while the second accepted
  run's worker, started with unlinked `Task.start`, was still alive. That worker
  ran `Retention.purge` with `delete_empty_transactions: true`, which deletes
  every childless AuditTransaction. The row-history fixture commits two parent
  AuditTransactions before their AuditChanges. A purge between those statements
  removes the parent, and the child insert fails the foreign key.
- **Fix:** 714b4dbb. Workers start under a test-owned `Task.Supervisor`, which
  ExUnit stops at test exit.
- **Regression oracle:** `test/threadline/retention/pruner_test.exs:107`. Its
  advisory-lock-held assertion (line 143) requires the accepted worker to be a
  child of the test supervisor.
- **Exact replay** (31 files, list sha256 `b463e6de…ed48`): 397 tests, 3
  properties, 0 failures, 1 excluded, exit 0, 36 s wall. The test and exclusion
  counts match the CI partition.
- **Negative control:** in a fresh copy, only `task_start` was changed to
  `&Task.start(&1)`. `pruner_test.exs --seed 675682` gave 9 tests and 1 failure,
  "the accepted worker must belong to the test supervisor". After restoring the
  file: 9 tests, 0 failures.
- **Natural reproduction:** `pruner_test.exs` was reset to its contents at B4
  head `02d115a3` (no fix), and the exact P3 list ran with seed 675682 three
  times. All three were green (397 tests, 0 failures). This does not weaken the
  diagnosis. The race needs CI's scheduler timing, and the advisory-lock
  regression plus the controlled worker-lifecycle probe in
  `.planning/debug/247-row-history-fk.md` are the deterministic oracle.

## Failure 2: run 40452833440, P1, seed 856063 (export directory removal)

- **Failing test:** `test/threadline/export/orchestrator_test.exs:239`. Setup
  line 177's `File.rm_rf!("priv/threadline_exports")` failed with "file already
  exists". CI result: 532 tests, 1 failure.
- **Mechanism:** `Threadline.Storage.Local` writes to one `priv/threadline_exports`
  directory inside the checkout, which all partition VMs share. `OrchestratorTest`
  and `LocalTest` remove it in setup, and `CleanupTest` and `ExportControllerTest`
  write into it. The captured min assignment put these four files in P1, P2 and
  P4, so one VM could recreate files while another was removing the tree.
- **Fix:** 136bb932. All four files form one colocation group in
  `test/partition_colocate.txt`, and `LocalTest` is synchronous.
- **Regression oracle:** `test/threadline/ci_topology_contract_test.exs:264`.
  It runs the production runner over copies of the four real files with a
  rendezvous shared-root claim. Grouped, it must pass. Split, it must report
  `export fixture overlap`.
- **Exact replay** (36 files, list sha256 `2bb15856…9ed09519`): 532 tests, 3
  properties, 0 failures, exit 0, 27 s wall. The test count matches the CI
  partition.
- **Export group plus topology** (four export files and
  `ci_topology_contract_test.exs`, seed 856063): 81 tests, 0 failures, exit 0.
- **Negative control:** in a fresh copy, only the export colocation line was
  deleted. `ci_topology_contract_test.exs:264` gave 31 tests, 1 failure, 30
  excluded, with three partition processes reporting `export fixture overlap`.
  After restoring the file: 31 tests, 0 failures, 30 excluded.
- **Natural reproduction:** not attempted. The plan caps natural attempts to the
  P3 FK case. The exact syscall interleaving of the CI failure was never
  recorded, so the deterministic rendezvous control is the proof of mechanism.

## Sibling sweep (classes A, B and C)

Every search command and its full result list is in the JSON `searches` array.
Every result file has a verdict in `sweep`.

**Class A (processes that outlive their test): one new hazard, fixed.** The
seeded grep found seven sites, all safe. Two of them are the 714b4dbb seam,
and the two unlinked lock holders release and assert `:DOWN` before their tests
return. Grep cannot see workers that product code starts, so the search was
widened in two ways. A grep listed every Pruner start in test code. A
scratch-only ExUnit formatter then ran the whole default suite on the min
toolchain and listed every live Task at each `:test_finished` event.

The probe found two Pruner workers alive, mid-query, after
`RetentionHistoryLiveTest`'s prune tests. Like PrunerTest before 714b4dbb, that
module started the Pruner with its default unlinked `Task.start` seam. Its
orphan sweep can delete the temporarily childless AuditTransaction of any later
test in the same partition. In both B4 runs this file sat in P1 and the
row-history victim in P3, but the runner places files by weight, so they can
meet.

- **RED** (14badb2c): a lock-held regression requires the accepted worker to be
  a child of a test-owned `Task.Supervisor`. It failed on that assertion on the
  min toolchain, and the classifier verdict was `RED_EVIDENCE_OK`.
- **GREEN** (d4688d58, comment reworded in eed59aa2): the test-owned supervisor
  is injected into the `task_start` seam. The file then passes 30/0.
- **Controls:** reverting the seam to `Task.start` gives 30 tests, 1 failure;
  restoring it gives 30/0. After the fix, the whole-suite probe found zero live
  workers across 3384 tests.

**Class B (checkout-shared paths written from different partitions): no new
hazard.** The checkout-root grep produced 114 results in 61 files. Three further
checks covered the rest:

- **All 335 `File.*` mutation sites, by hand:** every destination outside the
  checkout is a unique temp root. The in-checkout destinations are the export
  root, gitignored `_build/`, and one root sentinel. Colocation group 1 already
  owns that sentinel.
- **Export-root probe:** each of 30 candidate files was run alone with the
  export root removed. Only the four files in the 136bb932 group recreated it.
- **Nested `mix` shell-outs:** they change only `.mix/.mix_test_failures` in
  `_build`. No beam is rebuilt.

**Class C (unsandboxed deletes in async modules): no hazard.** The file-level
intersection found ten files. Eight are the English word "truncate" in prose.
One is scanner fixture strings. In the tenth, `storage_schema_prefix_contract_test.exs`,
the deletes belong to its second module, which is `async: false`. A
module-level scan, including deletes reached through test/support helpers,
found no async module that deletes rows.

**Gates.** On postgres:16, `mix verify.format`, `mix verify.credo` (0 issues)
and `mix verify.test` (3384 tests, 32 properties, 0 failures, 3 excluded) all
pass. After the fixes, the three min-toolchain replays on postgres:15 stay
green: P3 397/0, P1 533/0 (one more test than CI, from the new regression) and
the export group 81/0. The test diff against origin/main adds no masking line.
Its two removed `assert` lines are 714b4dbb re-indentations, and it adds no
timing line. No async flag changed.

<!-- MIN-FIXTURE-AUDIT-JSON-BEGIN -->
{
  "schema": "threadline.phase247-min-fixture-audit/1",
  "head": "6c5dc51441c9dde44b9647d6b12e7729226f040b",
  "toolchain": {
    "image": "hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824",
    "image_digest": "sha256:bcead3678dec8be86c3d8b93236e4b9c685f2a30472e71aeb972a834ef05b5fb",
    "image_id": "sha256:34238960354603d7bbe04d55c0c67a5c9b03e1366f3511614ca6357d74a6650b",
    "architecture": "arm64",
    "ci_architecture": "amd64",
    "elixir": "1.15.8",
    "otp": "26.2.5.21",
    "postgres": "15",
    "postgres_server": "15.18",
    "postgres_image_digest": "postgres@sha256:1b92e7a80c021647bf70f5d3eb66066a998e4f5cf43c07bb9dc9f729782cf88e",
    "source": "git archive of head into scratch, read-only mount, container-local _build/deps, one local snapshot commit for git-dependent tests; git+jq via apt inside the disposable container"
  },
  "failures": [
    {
      "run_id": 40452150109,
      "job_id": 122017125177,
      "partition": 3,
      "seed": 675682,
      "test": "test/threadline/operator_surface/live/row_history_live_test.exs:361",
      "ci_result": {
        "tests": 397,
        "failures": 1,
        "excluded": 1
      },
      "mechanism": "PrunerTest's second accepted run kept an unlinked Task.start worker alive past test exit; its Retention.purge orphan sweep (delete_empty_transactions) deleted RowHistoryLiveScopedTest's committed childless AuditTransaction before its AuditChange insert, failing audit_changes_transaction_id_fkey.",
      "fix_commit": "714b4dbb",
      "regression_test": "test/threadline/retention/pruner_test.exs:107",
      "partition_list_files": 31,
      "partition_list_sha256": "b463e6de62299f01f1159184b1b7b14b5482f1b02f4a6d045e59f91c4f01ed48",
      "replay": {
        "files": 31,
        "tests": 397,
        "properties": 3,
        "failures": 0,
        "excluded": 1,
        "exit": 0,
        "seed": 675682,
        "wall_s": 36
      },
      "negative_control": {
        "mutation": "pruner_test.exs task_start: &Task.Supervisor.start_child(@worker_supervisor, &1) -> &Task.start(&1)",
        "command": "mix test test/threadline/retention/pruner_test.exs --seed 675682",
        "red_tests": 9,
        "red_failures": 1,
        "red_signal": "the accepted worker must belong to the test supervisor",
        "restored_tests": 9,
        "restored_failures": 0
      },
      "natural_repro_attempts": [
        {
          "attempt": 1,
          "pruner_test_at": "02d115a32e4479f353d284c04fc838ba58938d16",
          "tests": 397,
          "failures": 0,
          "exit": 0,
          "wall_s": 29
        },
        {
          "attempt": 2,
          "pruner_test_at": "02d115a32e4479f353d284c04fc838ba58938d16",
          "tests": 397,
          "failures": 0,
          "exit": 0,
          "wall_s": 26
        },
        {
          "attempt": 3,
          "pruner_test_at": "02d115a32e4479f353d284c04fc838ba58938d16",
          "tests": 397,
          "failures": 0,
          "exit": 0,
          "wall_s": 26
        }
      ],
      "evidence_limit": "Natural reproduction stayed green locally; the deterministic oracle is the advisory-lock ownership regression plus the controlled worker-lifecycle probe in .planning/debug/247-row-history-fk.md."
    },
    {
      "run_id": 40452833440,
      "job_id": 122019295198,
      "partition": 1,
      "seed": 856063,
      "test": "test/threadline/export/orchestrator_test.exs:239",
      "ci_result": {
        "tests": 532,
        "failures": 1,
        "excluded": 0
      },
      "mechanism": "Threadline.Storage.Local resolves one checkout-shared priv/threadline_exports directory; OrchestratorTest and LocalTest rm_rf it in setup while CleanupTest and ExportControllerTest write into it, and the min assignment placed these four files in partitions 1, 2 and 4, so concurrent VMs raced on one tree.",
      "fix_commit": "136bb932",
      "regression_test": "test/threadline/ci_topology_contract_test.exs:264",
      "partition_list_files": 36,
      "partition_list_sha256": "2bb15856bd3c0188e659446e977fa366444095eaf1e345b7d80dd7d79ed09519",
      "replay": {
        "files": 36,
        "tests": 532,
        "properties": 3,
        "failures": 0,
        "excluded": 0,
        "exit": 0,
        "seed": 856063,
        "wall_s": 27
      },
      "export_group_replay": {
        "files": 5,
        "tests": 81,
        "failures": 0,
        "exit": 0,
        "seed": 856063,
        "wall_s": 2
      },
      "negative_control": {
        "mutation": "deleted the export colocation line from test/partition_colocate.txt",
        "command": "mix test test/threadline/ci_topology_contract_test.exs:264 --seed 856063",
        "red_tests": 31,
        "red_failures": 1,
        "red_signal": "export fixture overlap",
        "restored_tests": 31,
        "restored_failures": 0
      },
      "natural_repro_attempts": [],
      "evidence_limit": "The CI failure's exact syscall interleaving was never recorded; the deterministic rendezvous control proves the mechanism."
    }
  ],
  "searches": [
    {
      "class": "A",
      "command": "grep -rnE 'Task\\.start\\(|(^|[^_.a-zA-Z])spawn\\(|GenServer\\.start\\(|Task\\.Supervisor\\.start_child|Agent\\.start\\(|Process\\.spawn\\(|:proc_lib\\.spawn\\(' test/ --include='*.ex' --include='*.exs'",
      "results": [
        "test/threadline/capture/notice_guard_test.exs:34",
        "test/threadline/retention/pruner_test.exs:53",
        "test/threadline/health/legacy_key_findings_test.exs:217",
        "test/threadline/operator_surface/coverage_mix_test.exs:794",
        "test/threadline/operator_surface/live/retention_history_live_test.exs:67",
        "test/threadline/telemetry_helpers_test.exs:29",
        "test/threadline/application_test.exs:72",
        "test/support/partition_monitor.ex:70"
      ],
      "widenings": [
        {
          "command": "grep -rnE '\\{(Threadline\\.Retention\\.)?Pruner,|Pruner\\.start_link' test/ --include='*.ex' --include='*.exs'",
          "results": [
            "test/threadline/retention/pruner_test.exs:45",
            "test/threadline/operator_surface/live/retention_history_live_test.exs:61"
          ]
        },
        {
          "command": "whole default suite on the min toolchain (seed 675682, then 856063 after the fix) with a scratch-only ExUnit formatter that lists every live Task process and Threadline.Export.TaskSupervisor child at each :test_finished event",
          "results": [
            "test/threadline/operator_surface/live/retention_history_live_test.exs:61"
          ],
          "observed": "before fix: 2 rows, both Threadline.Retention.Pruner worker Tasks in prim_inet recv after RetentionHistoryLiveTest prune tests; after fix: 0 rows across 3384 tests"
        }
      ]
    },
    {
      "class": "B",
      "command": "grep -rnE '\"(priv|tmp|_build|deps)(/|\")|Application\\.app_dir|:code\\.priv_dir|File\\.cwd!?\\(\\)|Mix\\.Project\\.project_file' test/ --include='*.ex' --include='*.exs' | grep -vE '^\\S+:\\s*#'",
      "results": [
        "test/threadline/audit_indexing_doc_contract_test.exs:5",
        "test/threadline/hex_pin_contract_test.exs:21",
        "test/threadline/upgrade_backfill_test.exs:512",
        "test/threadline/upgrade_backfill_test.exs:834",
        "test/threadline/getting_started_saas_doc_contract_test.exs:8",
        "test/threadline/dialyzer_slice_contract_test.exs:123",
        "test/threadline/dialyzer_slice_contract_test.exs:128",
        "test/threadline/dialyzer_slice_contract_test.exs:261",
        "test/threadline/dialyzer_slice_contract_test.exs:266",
        "test/threadline/ignore_advisories_contract_test.exs:205",
        "test/threadline/ignore_advisories_contract_test.exs:213",
        "test/threadline/public_surface_contract_test.exs:781",
        "test/threadline/capture/trigger_rerun_test.exs:227",
        "test/threadline/capture/trigger_rerun_test.exs:440",
        "test/threadline/capture/legacy_function_upgrade_test.exs:366",
        "test/threadline/capture/legacy_trigger_regeneration_test.exs:230",
        "test/threadline/capture/notice_guard_canary_test.exs:4",
        "test/threadline/capture/notice_guard_canary_test.exs:14",
        "test/threadline/capture/legacy_trigger_pk_fallback_test.exs:383",
        "test/threadline/deps_health_doc_contract_test.exs:37",
        "test/threadline/changelog_contract_test.exs:25",
        "test/threadline/upgrade_rollback_test.exs:258",
        "test/threadline/upgrade_rollback_test.exs:268",
        "test/threadline/upgrade_rollback_test.exs:373",
        "test/threadline/property_scale_contract_test.exs:36",
        "test/threadline/retry_network_contract_test.exs:14",
        "test/threadline/retry_network_contract_test.exs:44",
        "test/threadline/retry_network_contract_test.exs:1093",
        "test/threadline/browser_full_projects_contract_test.exs:153",
        "test/threadline/browser_full_projects_contract_test.exs:207",
        "test/threadline/browser_full_projects_contract_test.exs:214",
        "test/threadline/browser_full_projects_contract_test.exs:393",
        "test/threadline/browser_full_projects_contract_test.exs:410",
        "test/threadline/deps_audit_gate_test.exs:242",
        "test/threadline/deps_audit_gate_test.exs:562",
        "test/threadline/cloak_advisory_reachability_contract_test.exs:13",
        "test/threadline/cloak_advisory_reachability_contract_test.exs:95",
        "test/threadline/release_control_plane_contract_test.exs:4",
        "test/threadline/ci_workflow_parity_contract_test.exs:6",
        "test/threadline/ci_workflow_parity_contract_test.exs:4074",
        "test/threadline/ci_workflow_parity_contract_test.exs:4223",
        "test/threadline/ci_workflow_parity_contract_test.exs:4232",
        "test/threadline/ci_workflow_parity_contract_test.exs:4651",
        "test/threadline/ci_workflow_parity_contract_test.exs:4768",
        "test/threadline/ci_workflow_parity_contract_test.exs:4779",
        "test/threadline/ci_workflow_parity_contract_test.exs:5505",
        "test/threadline/ci_workflow_parity_contract_test.exs:5506",
        "test/threadline/ci_workflow_parity_contract_test.exs:5508",
        "test/threadline/ci_workflow_parity_contract_test.exs:5802",
        "test/threadline/ci_workflow_parity_contract_test.exs:5865",
        "test/threadline/mix/trigger_migration_test.exs:10",
        "test/threadline/mix/migrations_path_test.exs:35",
        "test/threadline/mix/migrations_path_test.exs:39",
        "test/threadline/mix/migrations_path_test.exs:59",
        "test/threadline/mix/migrations_path_test.exs:65",
        "test/threadline/mix/migrations_path_test.exs:71",
        "test/threadline/mix/migrations_path_test.exs:77",
        "test/threadline/mix/migrations_path_test.exs:86",
        "test/threadline/mix/migrations_path_test.exs:94",
        "test/threadline/mix/migrations_path_test.exs:107",
        "test/threadline/example_phoenix_readme_contract_test.exs:5",
        "test/threadline/operator_surface/ui_form_policy_contract_test.exs:38",
        "test/threadline/operator_surface/controllers/export_controller_test.exs:503",
        "test/threadline/verify_coverage_task_test.exs:26",
        "test/threadline/verify_coverage_task_test.exs:47",
        "test/threadline/verify_coverage_task_test.exs:94",
        "test/threadline/verify_coverage_task_test.exs:114",
        "test/threadline/optional_deps_contract_test.exs:28",
        "test/threadline/storage/local_test.exs:6",
        "test/threadline/dep_floor_guard_test.exs:22",
        "test/threadline/dep_floor_guard_test.exs:27",
        "test/threadline/dep_floor_guard_test.exs:30",
        "test/threadline/integrations/sigra_doc_contract_test.exs:5",
        "test/threadline/integrations/phx_gen_auth_doc_contract_test.exs:5",
        "test/threadline/production_checklist_doc_contract_test.exs:5",
        "test/threadline/repo_hygiene_contract_test.exs:21",
        "test/threadline/flake_classifier_contract_test.exs:30",
        "test/threadline/persona_routing_doc_contract_test.exs:15",
        "test/threadline/guides/upgrade_path_contract_test.exs:6",
        "test/threadline/exploration_routing_doc_contract_test.exs:6",
        "test/threadline/ci_topology_contract_test.exs:5",
        "test/threadline/ci_topology_contract_test.exs:367",
        "test/threadline/ci_topology_contract_test.exs:722",
        "test/threadline/ci_topology_contract_test.exs:730",
        "test/threadline/performance_doc_contract_test.exs:6",
        "test/threadline/ci_token_permissions_contract_test.exs:47",
        "test/threadline/release_artifact_contract_test.exs:413",
        "test/threadline/health_findings_doc_contract_test.exs:19",
        "test/threadline/export/orchestrator_test.exs:13",
        "test/threadline/deps_health_report_test.exs:29",
        "test/threadline/deps_audit_contract_test.exs:21",
        "test/threadline/query/row_key_legacy_test.exs:210",
        "test/threadline/ci_action_runtime_contract_test.exs:6",
        "test/threadline/support_playbook_doc_contract_test.exs:6",
        "test/threadline/dependabot_config_contract_test.exs:48",
        "test/threadline/facade_only_references_contract_test.exs:12",
        "test/threadline/ci_action_pin_contract_test.exs:54",
        "test/threadline/ci_coverage_doc_contract_test.exs:47",
        "test/threadline/repo_contract_scope_contract_test.exs:47",
        "test/mix/tasks/threadline/gen_row_history_index_test.exs:13",
        "test/mix/tasks/threadline/install_test.exs:52",
        "test/mix/tasks/threadline/install_test.exs:288",
        "test/mix/tasks/threadline/gen_triggers_test.exs:10",
        "test/mix/tasks/threadline/gen_triggers_test.exs:12",
        "test/mix/tasks/threadline/gen_triggers_test.exs:16",
        "test/mix/tasks/threadline/gen_triggers_test.exs:320",
        "test/mix/tasks/threadline/gen_triggers_test.exs:333",
        "test/mix/tasks/threadline/gen_triggers_test.exs:349",
        "test/mix/tasks/threadline/gen_triggers_test.exs:356",
        "test/mix/tasks/threadline/gen_triggers_test.exs:369",
        "test/mix/tasks/threadline/gen_triggers_test.exs:388",
        "test/support/custom_priv_repo.ex:4",
        "test/support/migration_harness.ex:20",
        "test/support/getting_started_fixtures.ex:4"
      ],
      "widenings": [
        {
          "command": "grep -rnE 'File\\.(rm_rf|rm|write|mkdir_p|mkdir|cp|cp_r|rename|touch|ln_s)!?\\(' test/ --include='*.ex' --include='*.exs' (335 sites in 57 files); each destination root resolved from its assignment (scripted first pass, then read by hand); results = sites whose destination is inside the checkout",
          "results": [
            "test/threadline/export/orchestrator_test.exs:177",
            "test/threadline/storage/local_test.exs:11",
            "test/threadline/storage/local_test.exs:83",
            "test/threadline/operator_surface/controllers/export_controller_test.exs:505",
            "test/threadline/operator_surface/controllers/export_controller_test.exs:524",
            "test/threadline/operator_surface/controllers/export_controller_test.exs:624",
            "test/threadline/operator_surface/controllers/export_controller_test.exs:651",
            "test/threadline/operator_surface/controllers/export_controller_test.exs:766",
            "test/threadline/operator_surface/controllers/export_controller_test.exs:767",
            "test/threadline/clean_checkout_contract_test.exs:91",
            "test/threadline/clean_checkout_contract_test.exs:95",
            "test/threadline/dialyzer_slice_contract_test.exs:133",
            "test/threadline/dialyzer_slice_contract_test.exs:138",
            "test/threadline/dialyzer_slice_contract_test.exs:271",
            "test/threadline/dialyzer_slice_contract_test.exs:276"
          ]
        },
        {
          "command": "for each test file matching grep -rlE 'Storage\\.Local|\\bLocal\\.(put|delete|path|get)|Export\\.Orchestrator|Orchestrator\\.|Export\\.CleanupTask|CleanupTask|ExportJob|/exports|threadline_exports|Export\\.(run|start|create|enqueue)|ExportQueue' test/ --include='*_test.exs' (30 files): remove priv/threadline_exports, run the file alone on the min toolchain, report whether Storage.Local recreated the root",
          "results": [
            "test/threadline/export/cleanup_test.exs",
            "test/threadline/export/orchestrator_test.exs",
            "test/threadline/operator_surface/controllers/export_controller_test.exs",
            "test/threadline/storage/local_test.exs"
          ]
        },
        {
          "command": "for each writer-candidate shell-out (notice_guard_canary, verify_coverage_task, ci_coverage_doc): run the file alone on the min toolchain, then find _build deps -newer <marker>",
          "results": [
            "_build/test/lib/threadline/.mix/.mix_test_failures only"
          ]
        },
        {
          "command": "grep -rhoE '\"[A-Za-z0-9_.-]+#\\{System\\.unique_integer' test/ | sort | uniq -c, then grep -rlF each prefix",
          "results": [
            "github-output-: flake_classifier_contract_test.exs (under ExUnit tmp_dir) and deps_health_report_test.exs (under System.tmp_dir); different parents, no collision"
          ]
        }
      ]
    },
    {
      "class": "C",
      "command": "comm -12 <(grep -rlE 'async: true' test/ --include='*.ex' --include='*.exs' | sort) <(grep -rliE 'delete_all\\(|TRUNCATE|DELETE FROM' test/ --include='*.ex' --include='*.exs' | sort), then grep -niE 'delete_all\\(|TRUNCATE|DELETE FROM' on each hit",
      "results": [
        "test/threadline/deps_health_report_test.exs:710",
        "test/threadline/guides/table_shapes_contract_test.exs:27",
        "test/threadline/operator_surface/component_contract_test.exs:421",
        "test/threadline/operator_surface/exports/filename_test.exs:23",
        "test/threadline/operator_surface/exports_doc_contract_test.exs:250",
        "test/threadline/operator_surface/presentation_test.exs:165",
        "test/threadline/operator_surface/presentation_test.exs:186",
        "test/threadline/operator_surface/presentation_test.exs:192",
        "test/threadline/operator_surface/presentation_test.exs:203",
        "test/threadline/operator_surface/presentation_test.exs:204",
        "test/threadline/operator_surface/presentation_test.exs:207",
        "test/threadline/operator_surface/presentation_test.exs:208",
        "test/threadline/operator_surface/presentation_test.exs:240",
        "test/threadline/operator_surface/presentation_test.exs:247",
        "test/threadline/operator_surface/presentation_test.exs:255",
        "test/threadline/operator_surface/presentation_test.exs:287",
        "test/threadline/operator_surface/style_contract_test.exs:161",
        "test/threadline/operator_surface/ui_test.exs:705",
        "test/threadline/operator_surface/ui_test.exs:729",
        "test/threadline/operator_surface/ui_test.exs:740",
        "test/threadline/operator_surface/ui_test.exs:742",
        "test/threadline/storage_schema_call_site_contract_test.exs:267",
        "test/threadline/storage_schema_call_site_contract_test.exs:273",
        "test/threadline/storage_schema_call_site_contract_test.exs:292",
        "test/threadline/storage_schema_call_site_contract_test.exs:301",
        "test/threadline/storage_schema_call_site_contract_test.exs:317",
        "test/threadline/storage_schema_call_site_contract_test.exs:387",
        "test/threadline/storage_schema_call_site_contract_test.exs:395",
        "test/threadline/storage_schema_call_site_contract_test.exs:402",
        "test/threadline/storage_schema_call_site_contract_test.exs:411",
        "test/threadline/storage_schema_call_site_contract_test.exs:416",
        "test/threadline/storage_schema_prefix_contract_test.exs:64"
      ],
      "widenings": [
        {
          "command": "module-level scan: for every defmodule block with `use ..., async: true`, list delete_all(/TRUNCATE/DELETE FROM/clean_storage_schema(s)!/DbProperty cleanup/Repo.delete(/DROP TABLE|SCHEMA calls (catches deletes reached through test/support helpers)",
          "results": [
            "no async: true module deletes rows; every hit is a 'truncate' string or a scanner fixture string"
          ]
        },
        {
          "command": "grep -rlE 'Retention\\.purge|Pruner|Retention\\.run|CleanupTask\\.|Export\\.cleanup|purge\\(' test/ --include='*_test.exs', then the async flag of each file",
          "results": [
            "async: true hits are doc/route contracts with no DB access (code_walkthrough_doc_contract_test, how_threadline_works_doc_contract_test, router_test); all purge/cleanup callers are async: false"
          ]
        }
      ]
    }
  ],
  "sweep": [
    {
      "file": "test/threadline/capture/notice_guard_test.exs",
      "line": 34,
      "class": "A",
      "verdict": "safe",
      "reason": "The spawned process runs one read-only SELECT, sends :recorded and blocks on :take; the test sends :take and asserts {:taken, _}, so the process ends before the test returns. No DB write and no filesystem access."
    },
    {
      "file": "test/threadline/retention/pruner_test.exs",
      "line": 53,
      "class": "A",
      "verdict": "safe",
      "reason": "This is the 714b4dbb fix itself: accepted workers start under the test-owned Task.Supervisor (regression pruner_test.exs:107; Task 1 negative control red 1 / restored 0)."
    },
    {
      "file": "test/threadline/health/legacy_key_findings_test.exs",
      "line": 217,
      "class": "A",
      "verdict": "safe",
      "reason": "The unlinked lock holder holds ACCESS EXCLUSIVE on audit_changes only inside the test. On the passing path the test sends :release and asserts the holder's :DOWN before returning, so it holds no lock past its own :release. It can outlive only an already-failed test (5 s self-release), which cannot turn a green run red. Module is async: false; the outlive probe saw no Task alive after this test."
    },
    {
      "file": "test/threadline/operator_surface/coverage_mix_test.exs",
      "line": 794,
      "class": "A",
      "verdict": "safe",
      "reason": "Same lock-holder shape as legacy_key_findings_test: :release then an asserted :DOWN before the test returns; it can outlive only an already-failed test (5 s self-release). Module is async: false; the outlive probe saw no Task alive after this test."
    },
    {
      "file": "test/threadline/operator_surface/live/retention_history_live_test.exs",
      "line": 67,
      "class": "A",
      "verdict": "safe",
      "reason": "This is the 247-26 fix seam itself (d4688d58): accepted prune workers start under the test-owned Task.Supervisor; see the class A hazard entry for line 61."
    },
    {
      "file": "test/threadline/telemetry_helpers_test.exs",
      "line": 29,
      "class": "A",
      "verdict": "safe",
      "reason": "Bare spawn only executes a :telemetry event and sends :emitted; it touches no DB or filesystem, and the test awaits :emitted before returning."
    },
    {
      "file": "test/threadline/application_test.exs",
      "line": 72,
      "class": "A",
      "verdict": "safe",
      "reason": "The spawned starter calls Threadline.Application.start/2. The second instance's named children collide with the running application, so it returns {:error, {:shutdown, {:failed_to_start_child, Threadline.Export.TaskSupervisor, {:already_started, _}}}} (observed on the min toolchain) and starts no Pruner (retention is disabled in config/test.exs) and no CleanupTask; the spawned process then exits normally. Module is async: false."
    },
    {
      "file": "test/support/partition_monitor.ex",
      "line": 70,
      "class": "A",
      "verdict": "safe",
      "reason": "CI monitor, not a fixture"
    },
    {
      "file": "test/threadline/retention/pruner_test.exs",
      "line": 45,
      "class": "A",
      "verdict": "safe",
      "reason": "Pruner started with a 24 h startup timer; the task_start seam is replaced with the test-owned Task.Supervisor before any short timer is armed (714b4dbb)."
    },
    {
      "file": "test/threadline/operator_surface/live/retention_history_live_test.exs",
      "line": 61,
      "class": "A",
      "verdict": "hazard",
      "reason": "start_supervised Pruner kept its default unlinked Task.start worker seam. The 'Prune now' tests return once a RetentionRun row exists, while the accepted worker is still purging: the outlive probe saw two such workers alive in prim_inet recv after :test_finished (seed 675682). Their Retention.purge orphan sweep (delete_empty_transactions: true) deletes any temporarily childless AuditTransaction that a later sync test in the same partition commits before its AuditChanges, which is the B4 P3 mechanism. In both B4 runs this file sat in P1 and the row-history victim in P3, but assignment is weight-driven and Plan 27 re-ingests weights. Fixed in test code by injecting a test-owned Task.Supervisor into the task_start seam.",
      "fix_commits": [
        "14badb2c",
        "d4688d58",
        "eed59aa2"
      ],
      "regression_test": "test/threadline/operator_surface/live/retention_history_live_test.exs:730",
      "red_evidence": {
        "verdict": "RED_EVIDENCE_OK",
        "reason": "target_test_failed",
        "format": "tap",
        "toolchain": "1.15.8/26.2.5.21/postgres:15"
      },
      "negative_control": {
        "mutation": "retention_history_live_test.exs task_start: &Task.Supervisor.start_child(@worker_supervisor, &1) -> &Task.start(&1)",
        "command": "mix test test/threadline/operator_surface/live/retention_history_live_test.exs --seed 675682",
        "red_tests": 30,
        "red_failures": 1,
        "red_signal": "the accepted retention worker must belong to the test supervisor",
        "restored_tests": 30,
        "restored_failures": 0
      },
      "probe": {
        "before_fix_rows": 2,
        "after_fix_rows": 0,
        "after_fix_suite": "3384 tests, whole default suite, seed 856063"
      }
    },
    {
      "file": "test/mix/tasks/threadline/gen_row_history_index_test.exs",
      "line": 13,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        13
      ]
    },
    {
      "file": "test/mix/tasks/threadline/gen_triggers_test.exs",
      "line": 10,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path. @legacy_fixture and @repo_root are copy sources only.",
      "result_lines": [
        10,
        12,
        16,
        320,
        333,
        349,
        356,
        369,
        388
      ]
    },
    {
      "file": "test/mix/tasks/threadline/install_test.exs",
      "line": 52,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        52,
        288
      ]
    },
    {
      "file": "test/support/custom_priv_repo.ex",
      "line": 4,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        4
      ]
    },
    {
      "file": "test/support/getting_started_fixtures.ex",
      "line": 4,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        4
      ]
    },
    {
      "file": "test/support/migration_harness.ex",
      "line": 20,
      "class": "B",
      "verdict": "safe",
      "reason": "Runs Gen.Triggers under File.cd!(tmp) with a unique System.tmp_dir root; every caller module is async: false (DataCase default or explicit), so the VM-global cwd change cannot race another module.",
      "result_lines": [
        20
      ]
    },
    {
      "file": "test/threadline/audit_indexing_doc_contract_test.exs",
      "line": 5,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        5
      ]
    },
    {
      "file": "test/threadline/browser_full_projects_contract_test.exs",
      "line": 153,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes only under ExUnit tmp_dir (tmp/<module>/<test>, one partition per module); \"deps\" is a CLI argument string.",
      "result_lines": [
        153,
        207,
        214,
        393,
        410
      ]
    },
    {
      "file": "test/threadline/capture/legacy_function_upgrade_test.exs",
      "line": 366,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        366
      ]
    },
    {
      "file": "test/threadline/capture/legacy_trigger_pk_fallback_test.exs",
      "line": 383,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        383
      ]
    },
    {
      "file": "test/threadline/capture/legacy_trigger_regeneration_test.exs",
      "line": 230,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        230
      ]
    },
    {
      "file": "test/threadline/capture/notice_guard_canary_test.exs",
      "line": 4,
      "class": "B",
      "verdict": "safe",
      "reason": "Shells out to `mix test priv/ci/notice_guard_canary.exs` in the checkout. An instrumented run showed the only _build change is .mix/.mix_test_failures, which every partition's own mix test writes and only --failed reads; no recompile and no beam rewrite.",
      "result_lines": [
        4,
        14
      ]
    },
    {
      "file": "test/threadline/capture/trigger_rerun_test.exs",
      "line": 227,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        227,
        440
      ]
    },
    {
      "file": "test/threadline/changelog_contract_test.exs",
      "line": 25,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        25
      ]
    },
    {
      "file": "test/threadline/ci_action_pin_contract_test.exs",
      "line": 54,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        54
      ]
    },
    {
      "file": "test/threadline/ci_action_runtime_contract_test.exs",
      "line": 6,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        6
      ]
    },
    {
      "file": "test/threadline/ci_coverage_doc_contract_test.exs",
      "line": 47,
      "class": "B",
      "verdict": "safe",
      "reason": "Runs bin/browser-full-projects --list, read-only; an instrumented run showed no checkout write besides .mix/.mix_test_failures.",
      "result_lines": [
        47
      ]
    },
    {
      "file": "test/threadline/ci_token_permissions_contract_test.exs",
      "line": 47,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        47
      ]
    },
    {
      "file": "test/threadline/ci_topology_contract_test.exs",
      "line": 5,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes only under ExUnit tmp_dir or unique System.tmp_dir projects; the production runner runs with cd: <copy> and an explicit CI_TEST_PARTITIONS_LOG_DIR, never the checkout's tmp/ci-test-partitions. tmp/ci-test-partitions literals are workflow assertions.",
      "result_lines": [
        5,
        367,
        722,
        730
      ]
    },
    {
      "file": "test/threadline/ci_workflow_parity_contract_test.exs",
      "line": 6,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        6,
        4074,
        4223,
        4232,
        4651,
        4768,
        4779,
        5505,
        5506,
        5508,
        5802,
        5865
      ]
    },
    {
      "file": "test/threadline/cloak_advisory_reachability_contract_test.exs",
      "line": 13,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        13,
        95
      ]
    },
    {
      "file": "test/threadline/dep_floor_guard_test.exs",
      "line": 22,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        22,
        27,
        30
      ]
    },
    {
      "file": "test/threadline/dependabot_config_contract_test.exs",
      "line": 48,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        48
      ]
    },
    {
      "file": "test/threadline/deps_audit_contract_test.exs",
      "line": 21,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        21
      ]
    },
    {
      "file": "test/threadline/deps_audit_gate_test.exs",
      "line": 242,
      "class": "B",
      "verdict": "safe",
      "reason": "Fixture writes go under unique System.tmp_dir roots; @real_root is a copy source. The script under test writes SARIF into the gitignored checkout tmp/ through mktemp -d (unique per call) and removes its own directory, so partitions cannot collide.",
      "result_lines": [
        242,
        562
      ]
    },
    {
      "file": "test/threadline/deps_health_doc_contract_test.exs",
      "line": 37,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        37
      ]
    },
    {
      "file": "test/threadline/deps_health_report_test.exs",
      "line": 29,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path. @repo_root is a copy source only.",
      "result_lines": [
        29
      ]
    },
    {
      "file": "test/threadline/dialyzer_slice_contract_test.exs",
      "line": 123,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes under _build/dialyzer-slice-contract/<System.unique_integer>: gitignored, and this file runs in exactly one partition VM, so the per-VM unique integer cannot collide; the parent directory is never removed.",
      "result_lines": [
        123,
        128,
        261,
        266
      ]
    },
    {
      "file": "test/threadline/example_phoenix_readme_contract_test.exs",
      "line": 5,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        5
      ]
    },
    {
      "file": "test/threadline/exploration_routing_doc_contract_test.exs",
      "line": 6,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        6
      ]
    },
    {
      "file": "test/threadline/export/orchestrator_test.exs",
      "line": 13,
      "class": "B",
      "verdict": "safe",
      "reason": "Shared Storage.Local root priv/threadline_exports (B4 failure 2). Confirmed hazard already fixed by 136bb932: export colocation group plus regression ci_topology_contract_test.exs:264 (Task 1 negative control red 1 / restored 0).",
      "result_lines": [
        13
      ]
    },
    {
      "file": "test/threadline/facade_only_references_contract_test.exs",
      "line": 12,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        12
      ]
    },
    {
      "file": "test/threadline/flake_classifier_contract_test.exs",
      "line": 30,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes only under ExUnit tmp_dir with unique names; @repo_root/bin is only a symlink source.",
      "result_lines": [
        30
      ]
    },
    {
      "file": "test/threadline/getting_started_saas_doc_contract_test.exs",
      "line": 8,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        8
      ]
    },
    {
      "file": "test/threadline/guides/upgrade_path_contract_test.exs",
      "line": 6,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        6
      ]
    },
    {
      "file": "test/threadline/health_findings_doc_contract_test.exs",
      "line": 19,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        19
      ]
    },
    {
      "file": "test/threadline/hex_pin_contract_test.exs",
      "line": 21,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        21
      ]
    },
    {
      "file": "test/threadline/ignore_advisories_contract_test.exs",
      "line": 205,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        205,
        213
      ]
    },
    {
      "file": "test/threadline/integrations/phx_gen_auth_doc_contract_test.exs",
      "line": 5,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        5
      ]
    },
    {
      "file": "test/threadline/integrations/sigra_doc_contract_test.exs",
      "line": 5,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        5
      ]
    },
    {
      "file": "test/threadline/mix/migrations_path_test.exs",
      "line": 35,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        35,
        39,
        59,
        65,
        71,
        77,
        86,
        94,
        107
      ]
    },
    {
      "file": "test/threadline/mix/trigger_migration_test.exs",
      "line": 10,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path. @hex_evaluator_fixture is a copy source only.",
      "result_lines": [
        10
      ]
    },
    {
      "file": "test/threadline/operator_surface/controllers/export_controller_test.exs",
      "line": 503,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes the shared Storage.Local root through :code.priv_dir; already fixed by 136bb932 (export colocation group).",
      "result_lines": [
        503
      ]
    },
    {
      "file": "test/threadline/operator_surface/ui_form_policy_contract_test.exs",
      "line": 38,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        38
      ]
    },
    {
      "file": "test/threadline/optional_deps_contract_test.exs",
      "line": 28,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        28
      ]
    },
    {
      "file": "test/threadline/performance_doc_contract_test.exs",
      "line": 6,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        6
      ]
    },
    {
      "file": "test/threadline/persona_routing_doc_contract_test.exs",
      "line": 15,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        15
      ]
    },
    {
      "file": "test/threadline/production_checklist_doc_contract_test.exs",
      "line": 5,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        5
      ]
    },
    {
      "file": "test/threadline/property_scale_contract_test.exs",
      "line": 36,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        36
      ]
    },
    {
      "file": "test/threadline/public_surface_contract_test.exs",
      "line": 781,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        781
      ]
    },
    {
      "file": "test/threadline/query/row_key_legacy_test.exs",
      "line": 210,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        210
      ]
    },
    {
      "file": "test/threadline/release_artifact_contract_test.exs",
      "line": 413,
      "class": "B",
      "verdict": "safe",
      "reason": "Unpacks under a unique System.tmp_dir root; `mix hex.build --unpack` staging in the checkout root is already owned by colocation group 1 (all three members async: false).",
      "result_lines": [
        413
      ]
    },
    {
      "file": "test/threadline/release_control_plane_contract_test.exs",
      "line": 4,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        4
      ]
    },
    {
      "file": "test/threadline/repo_contract_scope_contract_test.exs",
      "line": 47,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        47
      ]
    },
    {
      "file": "test/threadline/repo_hygiene_contract_test.exs",
      "line": 21,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes only under ExUnit tmp_dir; @repo_root is read.",
      "result_lines": [
        21
      ]
    },
    {
      "file": "test/threadline/retry_network_contract_test.exs",
      "line": 14,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path. The \"tmp\" name is joined under the unique root.",
      "result_lines": [
        14,
        44,
        1093
      ]
    },
    {
      "file": "test/threadline/storage/local_test.exs",
      "line": 6,
      "class": "B",
      "verdict": "safe",
      "reason": "Shared Storage.Local root; already fixed by 136bb932 (export colocation group, module async: false). The :83 symlink lives inside that root and is removed on_exit.",
      "result_lines": [
        6
      ]
    },
    {
      "file": "test/threadline/support_playbook_doc_contract_test.exs",
      "line": 6,
      "class": "B",
      "verdict": "safe",
      "reason": "Names a checkout path only to read files or to assert on literals (no File mutation call and no checkout-writing shell-out in the file); it cannot write a shared path.",
      "result_lines": [
        6
      ]
    },
    {
      "file": "test/threadline/upgrade_backfill_test.exs",
      "line": 512,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        512,
        834
      ]
    },
    {
      "file": "test/threadline/upgrade_rollback_test.exs",
      "line": 258,
      "class": "B",
      "verdict": "safe",
      "reason": "All writes resolve under a per-run unique root (System.tmp_dir plus System.unique_integer, or ExUnit tmp_dir); the checkout-relative names it carries (priv/repo/migrations and similar) are joined under that root or File.cd!'d into it inside an async: false module. No partition shares the path.",
      "result_lines": [
        258,
        268,
        373
      ]
    },
    {
      "file": "test/threadline/verify_coverage_task_test.exs",
      "line": 26,
      "class": "B",
      "verdict": "safe",
      "reason": "Shells out to `mix threadline.verify_coverage` in the checkout. An instrumented run showed the only _build change is .mix/.mix_test_failures; no recompile and no beam rewrite.",
      "result_lines": [
        26,
        47,
        94,
        114
      ]
    },
    {
      "file": "test/threadline/clean_checkout_contract_test.exs",
      "line": 91,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes the non-ignored .safe-temp-tree-caller-sentinel at the checkout root (removed on_exit). Its only `git status --untracked-files=all` readers are this module and planning_independence_contract_test, both in colocation group 1 and async: false, so no concurrent reader exists. No other test writes non-ignored checkout paths.",
      "result_lines": [
        91,
        95
      ]
    },
    {
      "file": "test/threadline/export/cleanup_test.exs",
      "line": null,
      "class": "B",
      "verdict": "safe",
      "reason": "Writes the shared Storage.Local root through product code (its :storage_dir option does not redirect Local); already fixed by 136bb932 (export colocation group)."
    },
    {
      "file": "test/threadline/deps_health_report_test.exs",
      "line": 710,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        710
      ]
    },
    {
      "file": "test/threadline/guides/table_shapes_contract_test.exs",
      "line": 27,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        27
      ]
    },
    {
      "file": "test/threadline/operator_surface/component_contract_test.exs",
      "line": 421,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        421
      ]
    },
    {
      "file": "test/threadline/operator_surface/exports/filename_test.exs",
      "line": 23,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        23
      ]
    },
    {
      "file": "test/threadline/operator_surface/exports_doc_contract_test.exs",
      "line": 250,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        250
      ]
    },
    {
      "file": "test/threadline/operator_surface/presentation_test.exs",
      "line": 165,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        165,
        186,
        192,
        203,
        204,
        207,
        208,
        240,
        247,
        255,
        287
      ]
    },
    {
      "file": "test/threadline/operator_surface/style_contract_test.exs",
      "line": 161,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        161
      ]
    },
    {
      "file": "test/threadline/operator_surface/ui_test.exs",
      "line": 705,
      "class": "C",
      "verdict": "safe",
      "reason": "Case-insensitive match is the English word 'truncate' in a string, comment or function name; the module has no DB access.",
      "result_lines": [
        705,
        729,
        740,
        742
      ]
    },
    {
      "file": "test/threadline/storage_schema_call_site_contract_test.exs",
      "line": 267,
      "class": "C",
      "verdict": "safe",
      "reason": "delete_all( occurrences are source-text fixtures passed to a call-site scanner; this async module performs no database mutation.",
      "result_lines": [
        267,
        273,
        292,
        301,
        317,
        387,
        395,
        402,
        411,
        416
      ]
    },
    {
      "file": "test/threadline/storage_schema_prefix_contract_test.exs",
      "line": 64,
      "class": "C",
      "verdict": "safe",
      "reason": "The async: true module (StorageSchemaPrefixContractTest) reads schema metadata and source files only. The real deletes, including the unscoped clean_storage_schemas!/2 path into test/support/storage_schema_case.ex:343, belong to the second module in the file, StorageSchemaCaseContractTest, which is async: false; line 64 is scoped to the row the test inserted.",
      "result_lines": [
        64
      ]
    }
  ],
  "masking_review": {
    "diff_base": "02d115a32e4479f353d284c04fc838ba58938d16",
    "hard_gate_added_mask_lines": 0,
    "removed_assertions": [
      {
        "file": "test/threadline/retention/pruner_test.exs",
        "line_text": "assert :ok = Pruner.trigger()",
        "justification": "Moved, not removed (714b4dbb): the same `assert :ok = Pruner.trigger()` is re-added one indent deeper inside with_advisory_lock_held/3, and a stronger worker-ownership assertion follows it."
      },
      {
        "file": "test/threadline/retention/pruner_test.exs",
        "line_text": "assert_eventually(",
        "justification": "Moved, not removed (714b4dbb): the identical assert_eventually on RetentionRun count == 2, with the same default 2 s timeout and message, is re-added inside the lock-held block."
      }
    ],
    "added_timing": [],
    "review_only": [
      "Semantically weaker matchers (assert x != nil replacing an exact match, =~ replacing ==): the full test diff was read; none was introduced.",
      "Narrower pattern matches or dropped pattern fields: none introduced; the added assertions are new checks, and the moved ones are byte-identical apart from indentation.",
      "Implicit wait lengthening through assert_eventually :timeout/:interval options or helper defaults: none added; the new assert_eventually calls use the 2 s default, and test/support is unchanged.",
      "Tests made unreachable (early return, conditional body, removed test block, guards on env): none; the test diff only adds one test and wraps existing statements.",
      "Fixture or seed weakening (fewer inserted rows, smaller property runs): none; property scale, fixtures and partition weights are unchanged by this plan."
    ]
  },
  "gates": {
    "verify.format": {
      "exit": 0,
      "command": "DB_HOST=127.0.0.1 DB_PORT=$THREADLINE_PG_PORT mix verify.format"
    },
    "verify.credo": {
      "exit": 0,
      "issues": 0,
      "files": 441,
      "command": "DB_HOST=127.0.0.1 DB_PORT=$THREADLINE_PG_PORT mix verify.credo"
    },
    "verify.test": {
      "exit": 0,
      "tests": 3384,
      "properties": 32,
      "failures": 0,
      "excluded": 3,
      "seed": 318628,
      "wall_s": 183,
      "postgres": "postgres (PostgreSQL) 16.14 (Debian 16.14-1.pgdg13+1)",
      "command": "DB_HOST=127.0.0.1 DB_PORT=$THREADLINE_PG_PORT mix verify.test"
    },
    "min_replays_after_fixes": {
      "head": "eed59aa2c1a229a117a737f0be2f06abc1b8ffeb",
      "p3_40452150109": {
        "tests": 397,
        "failures": 0,
        "excluded": 1,
        "seed": 675682,
        "exit": 0
      },
      "p1_40452833440": {
        "tests": 533,
        "failures": 0,
        "seed": 856063,
        "exit": 0,
        "note": "one more test than CI because P1 holds retention_history_live_test.exs, which gained the regression"
      },
      "export_group_plus_topology": {
        "tests": 81,
        "failures": 0,
        "seed": 856063,
        "exit": 0
      }
    }
  },
  "async_flips": []
}
<!-- MIN-FIXTURE-AUDIT-JSON-END -->
