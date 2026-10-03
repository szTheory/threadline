# Phase 225 suite-time baseline (SUITE-01)

Measured at the milestone base `dd780e68`, before any Phase 225 suite change. Every figure on this page cites the run or command that produced it; `tools/check-citations.py` enforces that.

## CI before (the comparator)

The CI comparator for SUITE-02's gate (D-13) is the `Run tests` **step** duration per lane, from run 36730596489.

The billed runner-minutes figure below is a **proxy**, not real billed time (D-14a), from run 36730596489.

GitHub's timing API returns zero billable time for this public repo, confirmed live against run 36730596489.

The proxy is the sum of `ceil(job_seconds / 60)` over the three `Build and test (…)` jobs of run 36730596489 (D-14a). Job totals appear only as context (D-13).

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache | Source |
|---|---|---|---|---|---|
| min | 340 | 6 | 288 | hit | run 36730596489 |
| current | 476 | 8 | 291 | hit | run 36730596489 |
| latest | 321 | 6 | 267 | hit | run 36730596489 |
| **total** | | **20** | | | run 36730596489 |

This table (run 36730596489) was produced by:

```
python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36730596489 --cache-state
```

The same script's `--compare` mode (D-14a) is the only formula used to grade the after figures in a later plan, against run 36730596489 as the before run, so the before/after formula cannot drift between citations.

## Local detail (local, not the CI comparator)

HEAD at measurement time is `65d721c0` (run `git rev-parse --short HEAD`).

`git diff --quiet caabf12c -- lib test config mix.exs bin .github` exits 0, proving no Phase 225 suite change under those paths before these measurements.

The slowest-modules and slowest-tests rankings below were produced by `mix test --slowest 50 --slowest-modules 10`, which accepts both flags together on the local Elixir 1.17.3 toolchain.

Top 10 slowest modules, from `mix test --slowest 50 --slowest-modules 10`:

```
Top 10 slowest (128.1s), 74.9% of total time:

Threadline.PlaywrightFailFastContractTest (28804.9ms)
 [test/threadline/playwright_fail_fast_contract_test.exs]
Threadline.OperatorSurface.StressRouterTest (25798.4ms)
 [test/threadline/operator_surface/stress_router_test.exs]
Threadline.PublicSurfaceContractTest (16841.8ms)
 [test/threadline/public_surface_contract_test.exs]
Threadline.PlanningIndependenceContractTest (13562.1ms)
 [test/threadline/planning_independence_contract_test.exs]
Threadline.CleanCheckoutContractTest (13361.1ms)
 [test/threadline/clean_checkout_contract_test.exs]
Threadline.BrowserFullProjectsContractTest (10352.4ms)
 [test/threadline/browser_full_projects_contract_test.exs]
Threadline.RepoHygieneGuardTest (5241.4ms)
 [test/threadline/repo_hygiene_guard_test.exs]
Threadline.DepsAuditGateTest (4918.4ms)
 [test/threadline/deps_audit_gate_test.exs]
Threadline.DialyzerSliceContractTest (4756.0ms)
 [test/threadline/dialyzer_slice_contract_test.exs]
Threadline.ReleaseArtifactContractTest (4488.3ms)
 [test/threadline/release_artifact_contract_test.exs]

10 properties, 2583 tests, 0 failures, 3 excluded
```

Top 50 slowest tests, from `mix test --slowest 50 --slowest-modules 10`:

```
  * test production CI config is exercised by a clean seven-case behavioral smoke (Threadline.PlaywrightFailFastContractTest) (28804.9ms) [test/threadline/playwright_fail_fast_contract_test.exs:7]
  * test all 12 baseline-cohort group stories render without error across the matrix (Threadline.OperatorSurface.StressRouterTest) (14382.4ms) [test/threadline/operator_surface/stress_router_test.exs:493]
  * test all local, external, and module-doc subjects have one exact owner (Threadline.PublicSurfaceContractTest) (11419.5ms) [test/threadline/public_surface_contract_test.exs:332]
  * test every ledger story is listed and direct navigation renders preview or reserved placeholder (Threadline.OperatorSurface.StressRouterTest) (10419.1ms) [test/threadline/operator_surface/stress_router_test.exs:459]
  * test committed checkout verifier proves exact committed HEAD stays clean while reviewed controls remain trackable (Threadline.CleanCheckoutContractTest) (8599.0ms) [test/threadline/clean_checkout_contract_test.exs:255]
  * test restoration failure retains the clone and reports its quarantine (Threadline.PlanningIndependenceContractTest) (3761.0ms) [test/threadline/planning_independence_contract_test.exs:99]
  * test symlink replacement is rejected without touching the outside target or caller (Threadline.PlanningIndependenceContractTest) (3204.4ms) [test/threadline/planning_independence_contract_test.exs:126]
  * test aggregate failure restores planning before contained cleanup (Threadline.PlanningIndependenceContractTest) (3165.9ms) [test/threadline/planning_independence_contract_test.exs:45]
  * test committed checkout verifier forced verifier failure cleans only its clone child and preserves caller state (Threadline.CleanCheckoutContractTest) (3158.0ms) [test/threadline/clean_checkout_contract_test.exs:276]
  * test certifies exact committed HEAD with planning absent and preserves caller state (Threadline.PlanningIndependenceContractTest) (3136.4ms) [test/threadline/planning_independence_contract_test.exs:7]
  * test live repo partition the env-gated light project is never output (Threadline.BrowserFullProjectsContractTest) (1266.9ms) [test/threadline/browser_full_projects_contract_test.exs:208]
  * test the verifier delegates to this script classic protection falls back to branch metadata when REST denies the Actions token (Threadline.BranchProtectionComparisonContractTest) (1211.4ms) [test/threadline/branch_protection_comparison_contract_test.exs:271]
  * property a random chain of 1-4 runs rolls back to zero new orphaned capture functions (Threadline.Capture.TriggerRerunPropertyTest) (1153.2ms) [test/threadline/capture/trigger_rerun_property_test.exs:23]
  * test deps-only build cache contract control: every build cache fault is red on the live tree, each with its own rule (Threadline.CIWorkflowParityContractTest) (1026.9ms) [test/threadline/ci_workflow_parity_contract_test.exs:2478]
  * test mutation controls removing refute-capture's dependencies declaration turns the contract red (Threadline.BrowserFullProjectsContractTest) (1025.0ms) [test/threadline/browser_full_projects_contract_test.exs:317]
  * test cross-origin and ambiguous login-looking redirects fail before Playwright (Threadline.E2ePreflightContractTest) (1018.8ms) [test/threadline/e2e_preflight_contract_test.exs:35]
  * test relative and same-origin login redirects pass with normalized default ports (Threadline.E2ePreflightContractTest) (964.3ms) [test/threadline/e2e_preflight_contract_test.exs:8]
  * test live repo partition Browser-full executes a ci.yml project only through a declared dependencies edge (Threadline.BrowserFullProjectsContractTest) (952.4ms) [test/threadline/browser_full_projects_contract_test.exs:161]
  * test the verifier delegates to this script classic protection treats only HTTP 404 as absent and fails closed otherwise (Threadline.BranchProtectionComparisonContractTest) (819.3ms) [test/threadline/branch_protection_comparison_contract_test.exs:222]
  * test safe temp-tree cleanup rejects every registered linked worktree root without mutating or unregistering it (Threadline.CleanCheckoutContractTest) (813.3ms) [test/threadline/clean_checkout_contract_test.exs:140]
  * test deps-only build cache contract control: every build cache fault is red on the hybrid map (live workflows, fixture ci.yml) (Threadline.CIWorkflowParityContractTest) (798.5ms) [test/threadline/ci_workflow_parity_contract_test.exs:2650]
  * test irreducible residue requires an exact tuple, rationale, and removal trigger (Threadline.DialyzerSliceContractTest) (783.1ms) [test/threadline/dialyzer_slice_contract_test.exs:71]
  * test live repo partition ci and browser-full partition the config: union is the config, intersection is empty (Threadline.BrowserFullProjectsContractTest) (777.0ms) [test/threadline/browser_full_projects_contract_test.exs:132]
  * test each CI Coverage row names the lane that actually runs the project (Threadline.CiCoverageDocContractTest) (738.7ms) [test/threadline/ci_coverage_doc_contract_test.exs:105]
  * test --self-test runs its ten cases and exits 0 (Threadline.RepoHygieneGuardTest) (703.5ms) [test/threadline/repo_hygiene_guard_test.exs:739]
  * test findings gate — OS-level exit status (D-17) exits 0 when the same table's trigger is enabled (clean negative control) (Threadline.VerifyCoverageTaskTest) (696.7ms) [test/threadline/verify_coverage_task_test.exs:103]
  * test the same run without a truncation exits zero (Threadline.Capture.NoticeGuardCanaryTest) (667.2ms) [test/threadline/capture/notice_guard_canary_test.exs:29]
  * test 2xx requires both operator shell markers (Threadline.E2ePreflightContractTest) (629.5ms) [test/threadline/e2e_preflight_contract_test.exs:83]
  * test API errors and malformed JSON fail without fallback invocations (Threadline.MainCiObserverContractTest) (565.2ms) [test/threadline/main_ci_observer_contract_test.exs:139]
  * test the entire readable archive is free of planning vocabulary (Threadline.ReleaseArtifactContractTest) (536.9ms) [test/threadline/release_artifact_contract_test.exs:311]
  * test live repo partition default output is one sorted --project flag per browser-full project (Threadline.BrowserFullProjectsContractTest) (524.9ms) [test/threadline/browser_full_projects_contract_test.exs:126]
  * test real prod Mix.env macro path fails closed without the stress_env hook (Threadline.OperatorSurface.StressRouterTest) (517.8ms) [test/threadline/operator_surface/stress_router_test.exs:281]
  * test live repo partition every stated prerequisite of a Browser-full project is a declared dependencies edge (Threadline.BrowserFullProjectsContractTest) (505.0ms) [test/threadline/browser_full_projects_contract_test.exs:204]
  * test an undrained truncation notice makes mix test exit non-zero (Threadline.Capture.NoticeGuardCanaryTest) (491.1ms) [test/threadline/capture/notice_guard_canary_test.exs:20]
  * test all packaged source uses durable vocabulary (Threadline.ReleaseArtifactContractTest) (487.6ms) [test/threadline/release_artifact_contract_test.exs:292]
  * test module_visibility_seed remains a nonempty bounded visibility owner (Threadline.PublicSurfaceContractTest) (483.4ms) [test/threadline/public_surface_contract_test.exs:232]
  * test Phoenix-style lowercase and mixed-case Location headers are accepted (Threadline.E2ePreflightContractTest) (483.1ms) [test/threadline/e2e_preflight_contract_test.exs:23]
  * test source_vocab_operator_live_records is an exact nonempty archive source owner (Threadline.ReleaseArtifactContractTest) (479.4ms) [test/threadline/release_artifact_contract_test.exs:272]
  * test source_vocab_operator_live_forms is an exact nonempty archive source owner (Threadline.ReleaseArtifactContractTest) (464.0ms) [test/threadline/release_artifact_contract_test.exs:272]
  * test source_vocab_operator_infrastructure is an exact nonempty archive source owner (Threadline.ReleaseArtifactContractTest) (464.0ms) [test/threadline/release_artifact_contract_test.exs:272]
  * test usage an unknown argument exits 2 (Threadline.BrowserFullProjectsContractTest) (462.6ms) [test/threadline/browser_full_projects_contract_test.exs:229]
  * test built Hex archive excludes repository evidence (Threadline.ReleaseArtifactContractTest) (436.1ms) [test/threadline/release_artifact_contract_test.exs:140]
  * test source_vocab_core_query_policy is an exact nonempty archive source owner (Threadline.ReleaseArtifactContractTest) (433.1ms) [test/threadline/release_artifact_contract_test.exs:272]
  * test findings gate — OS-level exit status (D-17) exits 1 when the findings-gated table's trigger is disabled (Threadline.VerifyCoverageTaskTest) (418.4ms) [test/threadline/verify_coverage_task_test.exs:77]
  * test mix threadline.verify_coverage exits 0 when expected canary table is covered (Threadline.VerifyCoverageTaskTest) (415.4ms) [test/threadline/verify_coverage_task_test.exs:21]
  * test source_vocab_core_runtime is an exact nonempty archive source owner (Threadline.ReleaseArtifactContractTest) (400.4ms) [test/threadline/release_artifact_contract_test.exs:272]
  * test mix threadline.verify_coverage exits 1 when expected table lacks trigger (SC1) (Threadline.VerifyCoverageTaskTest) (399.0ms) [test/threadline/verify_coverage_task_test.exs:36]
  * test built Hex archive excludes maintainer-only tooling (Threadline.ReleaseArtifactContractTest) (396.5ms) [test/threadline/release_artifact_contract_test.exs:197]
  * test the bot-owned generated changelog is never adopter surface (Threadline.ReleaseArtifactContractTest) (389.0ms) [test/threadline/release_artifact_contract_test.exs:232]
  * test module_visibility_domain_tail remains a nonempty bounded visibility owner (Threadline.PublicSurfaceContractTest) (388.9ms) [test/threadline/public_surface_contract_test.exs:232]
```

Three plain `mix test` timing runs, sequential, each with a prior `MIX_ENV=test mix compile` excluded from the timed window (nothing to compile on runs 2 and 3, since run 1's compile already brought `_build` up to date):

| Run | Finished in | Async | Sync | Counts | real (s) | Median | Source |
|---|---|---|---|---|---|---|---|
| 1 | 135.1s | 15.9s | 119.1s | 10 properties, 2583 tests, 0 failures, 3 excluded | 135.82 | | `mix test` |
| 2 | 151.8s | 16.4s | 135.4s | 10 properties, 2583 tests, 0 failures, 3 excluded | 152.51 | | `mix test` |
| 3 | 137.0s | 16.9s | 120.1s | 10 properties, 2583 tests, 0 failures, 3 excluded | 137.76 | median | `mix test` |

Finished in 135.1 seconds (15.9s async, 119.1s sync), run 1 of `mix test` (timed with `/usr/bin/time -p`).

Finished in 151.8 seconds (16.4s async, 135.4s sync), run 2 of `mix test` (timed with `/usr/bin/time -p`).

Finished in 137.0 seconds (16.9s async, 120.1s sync), run 3 of `mix test` (timed with `/usr/bin/time -p`) — this is the median run by `Finished in` total (135.1 < 137.0 < 151.8).

D-03 partition check (`mix test --slowest 50 --slowest-modules 10`, `/usr/bin/time -p mix test` run 3): the median run's `Finished in` total is T = 137.0 s; the slowest module (Threadline.PlaywrightFailFastContractTest) is M = 28.8 s (28804.9ms). T / 3 = 45.7 s. M (28.8 s) does not exceed T / 3 (45.7 s), so N = 3 confirmed by measurement.

Phase-narrowing note (D-15): SUITE-03 is narrowed to exactly three files (`test/threadline/operator_surface/auth_test.exs`, `export_auth_plug_test.exs`, `theme_auth_plug_test.exs`); the wording is already updated in REQUIREMENTS.md and ROADMAP.md, per this phase's own CONTEXT.md (D-15).

## Historical cross-checks (not comparators)

Flake Detection run 36359135268 (cold first run 268.3 s, repeats 206.2-213.5 s) predates the milestone base and appears here only as a labelled historical cross-check (D-13), not a before/after comparator.

The dd780e68 local `mix test` runs are cited from 224-EVIDENCE.md's "Suite wall clock (SUITE-06)" table rather than re-measured: base run 1 231.0 s (44.7s async, 186.3s sync), base run 2 243.2 s (34.4s async, 208.8s sync) (`.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md`). That table's own note records local swings of about 55 s between head and base runs caused by unrelated concurrent local processes, which is why no additional worktree re-measurement at dd780e68 was performed in this plan (D-14).
