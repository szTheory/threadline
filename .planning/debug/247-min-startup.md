# 247 min P3 pre-first-module delay

**Scope:** Read-only root-cause investigation of recurring min-lane partition 3 `boot_ms` before the first ExUnit `:module_started` event. No tracked source/config or fixtures were changed.

## Recommendation

Keep source, async annotations, assignment, weights, and thresholds unchanged. The scratch fixture extraction moved work from P3's require phase into the serial project compile and did not pay off: it saved only 0.400 s from the exact P3 require profile, while the dependency-warm project compile grew by 1.531 s. The combined cold project-compile-plus-P3-require result worsened by 1.131 s. The native min-toolchain P3 boot was 3.749 s, still far below the repeated CI 17.2–22.7 s. A single bounded CI min-lane phase trace is the next useful step; no source optimization is justified by this evidence.

The all-sync assignment can still affect what `boot_ms` measures if ExUnit begins async modules during file loading. It does not explain the full CI delay in the native min environment. Treat `boot_ms` as VM start to first module, not pure VM/application/database startup.

## Evidence

- The five captured min runs show P3 `boot_ms` 17.227–22.723 s while P1/P2/P4 are 1.906–4.635 s. P3 is the same 31-file assignment in each run. Captures are under `/tmp/threadline-247-b4-artifacts/{40448573344,40449332597,40450141708,40450801580,40451533079}/partition-timings-min-*/`.
- The same commit's min lane pins Elixir 1.15.8 / OTP 26.2.5.21 on Ubuntu 24.04; the local host has no native install, but the cached ARM64 container image provided the exact toolchain. Current and latest P3 timings from run 40450801580 are 3.213 s and 1.966 s respectively. See `.github/workflows/ci.yml:636-655`.
- `bin/ci-test-partitions` does a serial `mix compile` before launching partition VMs, then runs each selected file set with `mix test --no-compile --no-deps-check` (`bin/ci-test-partitions:850-910`). Thus the partition invocation does not recompile the application, but its test files still require/compile at runtime.
- Exact min Mix task documentation in the container exposes `--profile-require time` and says it skips test execution. The image does not include Mix source files, so exact-version internals for async module starts versus the require barrier remain unverified.
- The test helper's actual DB/startup work is explicit: `storage_up`, Repo start, `SHOW client_min_messages`, migration, then application stop/restart (`test/test_helper.exs:37-99`).
- Exact captured P3 run on this host: 31 files, 397 tests, 3 properties, 0 failures, 45.0 s ExUnit sync; `boot_ms=2269`, `wall_ms=45683`, against an initially absent disposable `threadline_testboot247` database on local Postgres container port 58082. This makes a fixed 17–20 s helper/migration cost unlikely on this host, but does not rule out slower CI database behavior.
- The exact min-toolchain scratch P3 `--profile-require time` run reported 2.554 s for 118 modules; `timeline_live_test.exs` took 1.508 s. A normal P3 run reported `boot_ms=3749`, `wall_ms=61088`, 397 tests / 3 properties. Helper markers measured 112 ms from helper entry to completion: storage_up 55 ms, Repo start 6 ms, SHOW 20 ms, migrations 23 ms, application stop/restart 1 ms. Eight tests failed only because the minimal image lacked Git and `.git`; the boot timing is valid but the test result is not.
- A scratch-only fixture extraction moved the first 294 lines of `timeline_live_test.exs` into guarded `test/support/timeline_live_fixtures.ex`. It preserved modules and assertions. Exact P3 require fell to 2.154 s for 89 modules; the timeline file fell to 576 ms, for a 400 ms net P3 require saving.
- With dependency artifacts warm, the clean Threadline project compile was 4.914 s baseline and 6.445 s extracted (+1.531 s). A subsequent warm compile was 432 ms baseline and 433 ms extracted. Thus cold project compile + P3 require was 7.468 s baseline vs. 8.599 s extracted (+1.131 s). Full clean compile including dependencies measured 31.639 s baseline vs. 34.832 s extracted; use the dependency-warm project comparison for the fixture decision because full dependency/NIF work varies.
- The native ARM64 exact-min image does not reproduce the CI interval. CI min is Ubuntu 24.04 AMD64. AMD64 emulation was not run; local native performance is diagnostic only.
- A four-partition run started before the sibling FK edits were reported was stopped immediately. Its partial log is invalid comparative evidence and is not used here.
- Exact-toolchain compatibility follow-up used the final current files from commit `714b4dbb90b7509e0858977bd4d4fea3b20f0de5`; all four copied files byte-matched `git show` before testing: `test/partition_colocate.txt`, `test/threadline/ci_topology_contract_test.exs`, `test/threadline/retention/pruner_test.exs`, and `test/threadline/storage/local_test.exs`.
- Targeted native-min run covered the seven authorized files: `ci_topology_contract_test`, `storage/local_test`, `export/orchestrator_test`, `export/cleanup_test`, operator-surface `export_controller_test`, `retention/pruner_test`, and `row_history_live_test`. Result: 100 tests, 0 failures, seed 776257, 5.3 s (1.7 s async, 3.5 s sync). It used unique DB `threadline_testbootlinuxrecovery` on the disposable PostgreSQL 16 container, with Elixir 1.15.8 / OTP 26.2.5.21 native ARM64. Git/JQ were installed only inside the ephemeral test container because the topology test's candidate parser invokes them. This verifies the selected paths on the min Elixir/OTP pair, but does not cover CI's AMD64 architecture or PostgreSQL 15.
- Exact min profiler output was `[profile] Finished compilation cycle of 118 modules in 2554ms`, then `[profile] Finished group pass check of 118 modules in 64ms`, followed by the CLI diagnostic `Paths given to "mix test" did not match any directory/file: ...`; captured Mix exit status was 1 even though profile data was emitted and test execution was intentionally skipped.

## Concrete next profiling loop

1. In one min CI run, add temporary timestamps around serial `mix compile` and test-helper boundaries: `storage_up`, Repo start, `SHOW`, migrations, application stop/restart, and helper completion.
2. Run the exact P3 file list with `--profile-require time` in a diagnostic invocation; compare per-file require time with normal first-module `boot_ms`. The profile mode skips test execution.
3. In the same normal four-partition run, record P1–P4 compile, helper, require, first-module, and wall-minus-boot timings. Preserve the exact assignment and Elixir/OTP/runner image.
4. Use those phase deltas to identify a fix only if one path explains the CI residual. Native ARM64 results alone do not identify the AMD64 CI cause.

## Limits

The local container used the exact min toolchain but native ARM64, whereas CI min is AMD64. The aborted four-VM run is invalid. The normal P3 timing probe's test result is invalidated by missing Git. No CI source instrumentation was added, no workflow was dispatched, and no acceptance threshold is recommended from local machine speed.
