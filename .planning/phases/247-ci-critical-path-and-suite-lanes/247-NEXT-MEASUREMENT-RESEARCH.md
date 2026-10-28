# Phase 247 next measurement — research

**Date:** 2026-10-27
**Purpose:** Define one bounded local experiment for the unresolved minimum-lane startup observation. This is research input, not a new CI authorization or acceptance measurement.

## Recommendation

Run one disposable synthetic ExUnit experiment against the exact Elixir 1.15.8 / OTP 26 toolchain. Use the real `ExUnit.async_run()` → `Kernel.ParallelCompiler.require(...)` → `ExUnit.await_run()` order, with a controlled 2-second loader barrier between an identical canary module's registration and the `modules_loaded` signal. Compare only the canary's `async: true` versus `async: false` metadata; keep its test body, file count, helper, VM, and barrier fixed. Record the module registration, barrier release, first `:module_started`, and suite finish timestamps. Add a pre-ExUnit 2-second delay control and a 2-second `setup_all` delay control. This avoids touching real suite async flags, DBs, CI, or weights while directly testing the scheduling/barrier behavior that the earlier call-graph review missed.

This tests whether async registration can move `boot_ms` earlier than the all-files-loaded barrier and whether the formatter timestamp is sensitive to the injected delay. It does not identify the cause of the historical CI 17–22 second delay or reproduce GitHub-hosted AMD64 timing. The 31-file all-sync B4 assignment and 36-file/8-async diagnostic assignment are different workloads and can also expose different first-module boundaries; their observed runs are not a causal A/B. Preserve weights, async factor, assignment, ratio threshold, and CI status until separate evidence and authorized main measurements support changes.

## Facts from the repository and completed diagnostic

- The approved run was a single off-main workflow dispatch: run `40504321590`, diagnostic head `8177d00d74b03527c2b14bbb0ef17f6c5895b464`, 17/17 jobs successful, budget 1/1 used. Its results are not a fifth B4 success or a main acceptance sample. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-DIAGNOSTIC-RUN.md`; `.planning/phases/247-ci-critical-path-and-suite-lanes/247-DIAGNOSTIC-EVIDENCE.json`]
- The old B4 min P3 was 31 all-sync files with `boot_ms` 17.2–22.7 s. In the diagnostic, P3 had 36 files including 8 async files; the four min `boot_ms` values were 1.598–2.239 s. The changed assignment and source fixtures confound before/after inference. [VERIFIED: same diagnostic artifacts]
- In min P3, helper work ended at 1.377 s and first `:module_started` was at 1.598 s (221 ms later). The separate frozen-file profile reported 118 modules compiled in 3.327 s (3.288 s attributed to the timeline fixture). These measurements came from different execution modes/order and do not measure one additive interval; the profile is not evidence that those 3.288 s occurred before the event in the normal run. Elixir 1.15.8 `--profile-require time` does not execute tests; its profile-mode exit/path diagnostic is not a suite result. All frozen paths were present. [VERIFIED: diagnostic run and evidence; [Mix 1.15.3 `mix test` docs](https://mix.hexdocs.pm/1.15.3/Mix.Tasks.Test.html) says profile-require is debugging-only and skips suite execution]
- The monitor defines `boot_ms` as VM wall time at the first `:module_started`; `wall_ms` is VM wall time at `:suite_finished`. It reads `:erlang.statistics(:wall_clock)`. [VERIFIED: `test/support/partition_monitor.ex` lines 18–23, 349–351]
- CI's partition runner performs a serial `mix compile` before launching partition BEAMs, then uses `mix test --no-compile --no-deps-check`; test files still load in each test VM. The investigation should therefore separate project compile from test-file require/load, and must not accidentally benchmark a clean compile as if it were partition startup. [VERIFIED: `bin/ci-test-partitions` lines 780–910; `.planning/debug/247-min-startup.md`]
- The agreed phase gates remain ≤9-minute median main `ci.yml` wall and partition ratio ≤1.15 over three runs per lane. D-12 makes the ratio a warning, not a hard per-run gate. D-02 sequences observation/measurement on main after landing; this local experiment cannot close those gates. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-CONTEXT.md`, D-02, D-08, D-11, D-12]

## Official runtime/source findings

- Mix 1.15.8's `Mix.Tasks.Test` starts the app and loads `test_helper.exs`, then calls `CT.require_and_run(...)`. The callee matters: `Mix.Compilers.Test.require_and_run/4` starts `ExUnit.async_run()` **before** invoking `Kernel.ParallelCompiler.require/2`, then calls `ExUnit.await_run/1` after require completes. [CITED: [Elixir v1.15.8 Mix.Tasks.Test source](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/mix/lib/mix/tasks/test.ex); [Elixir v1.15.8 Mix.Compilers.Test source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/mix/lib/mix/compilers/test.ex), lines 47–80]
- ExUnit's `ExUnit.Case.__after_compile__/2` registers each compiled case with `ExUnit.Server.add_async_module/1` or `add_sync_module/1`. `ExUnit.Runner.async_loop/3` can take and start async modules as they register; `ExUnit.Server` holds a pending `take_async_modules` call and releases registered async cases before `modules_loaded` is signaled. Sync cases are returned only after the loaded barrier. `module_started` occurs inside `run_module/2`. [CITED: [Elixir v1.15.8 ExUnit.Case source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/case.ex); [ExUnit.Runner source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/runner.ex); [ExUnit.Server source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/server.ex)]
- Corrected interpretation: `boot_ms` is VM-relative wall time to the first formatter receipt of `:module_started`. It includes startup/helper and the time until the first module is registered and scheduled. For an async module, that can happen **during parallel test-file compilation/loading**; for an all-sync set, first module execution is held until the test loader signals all modules loaded. Therefore async-vs-sync assignment can shift this metric's boundary even when it does not change the preceding source's compile duration. This is a direct consequence of the 1.15.8 caller/callee/server/runner ordering, not proof that this caused the historic 17–22 s values. [CITED: versioned sources above; repository definition `test/support/partition_monitor.ex` lines 20–22, 77–82]
- The observed helper-end 1.377 s → first event 1.598 s is a 221 ms interval in the diagnostic's mixed assignment. It does not contradict the 3.288 s timeline require profile: profile mode uses a different path that skips ExUnit execution, and that profile was separately run after the normal suite. No sum or subtraction across those measurements is valid. [VERIFIED: diagnostic artifacts and 1.15.8 Mix source]
- The 1.15 ExUnit docs specify async modules run concurrently with other modules, while tests inside a module run serially. `--max-cases 1` caps execution concurrency but does not remove async module registration or the load barrier; it is therefore not a sufficient oracle for whether an async module starts before `modules_loaded`. Do not use it as the A/B variable for this boundary question. `--trace` additionally changes timeout behavior and is not an appropriate measurement mode. [CITED: [ExUnit v1.15.8 source/docs](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit.ex); [ExUnit.Runner](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/runner.ex)]
- The OTP `wall_clock` statistic is elapsed real time; `runtime` is summed scheduler/runtime time and can exceed wall time. If scheduler utilization is sampled, OTP documents enabling `scheduler_wall_time` across both samples and using it only as a relative utilization measure. Do not substitute CPU runtime for the existing wall-time acceptance metric. [CITED: [Erlang/OTP ERTS `erlang` docs](https://www.erlang.org/docs/28/apps/erts/erlang.html)]
- Repeated measurements and balancing order reduce exposure to noise and time-varying host state. LLVM recommends repeated runs and reducing system noise; Google Benchmark documents repetitions/statistics and randomized interleaving as ways to reduce run-to-run state effects. Adapt these principles to a paired ABBA schedule, but do not claim statistical significance from five pairs. [CITED: [LLVM Benchmarking tips](https://llvm.org/docs/Benchmarking.html), [Google Benchmark user guide](https://github.com/google/benchmark/blob/main/docs/user_guide.md)]

## Bounded experiment protocol

### Fixed inputs

1. Use exact Elixir 1.15.8 / OTP 26.2.5.21. Record runtime versions, architecture, `sha256` of the temporary harness files and both generated canary variants, and `git status --porcelain` before/after to prove the worktree stayed untouched. The only A/B source difference is the `async: true` versus `async: false` case option; preserve identical test body, module identity, file bytes otherwise, helper, and formatter.
2. Generate a tiny standalone harness in a private temp directory; it has no DB, app dependencies, or external packages. Configure ExUnit with a formatter that records `:erlang.statistics(:wall_clock)` at `:module_started` and `:suite_finished`. Start ExUnit with `autorun: false`, call `ExUnit.async_run()`, invoke `Kernel.ParallelCompiler.require([canary_path], [])`, hold the loader at a controlled 2,000 ms barrier, then call `ExUnit.await_run(task)` (which signals `modules_loaded(false)`). This exercises the 1.15.8 async-runner/compiler/loaded-barrier sequence without changing real project test flags.
3. Use a fixed file order, fixed source hashes, one VM per observation and one host/container. Run five balanced pairs (A/B, B/A, A/B, B/A, A/B), where A is async and B is sync. Record barrier-start/release, first module, suite finish, exit status and exact command. Run one unscored warmup first; keep image and filesystem cache state warm and unchanged, no concurrent build/tests, and record host/CPU limits. If using AMD64 emulation from the ARM64 host, report only the within-host timing oracle; do not transfer elapsed-time magnitudes to hosted AMD64 CI. A native ARM64 repetition is a separate cohort, never pooled.
4. Add two controls to this same harness: (a) insert 2,000 ms before `ExUnit.start()` to verify both A/B boot measurements move by 1,750–2,250 ms; (b) add 2,000 ms `setup_all` sleep to the canary after `module_started`, verifying suite wall moves by 1,750–2,250 ms while boot moves by at most 250 ms. Keep control source separate and hash it. These controls validate formatter timing and distinguish pre-event from post-event work.
5. Do not run the real 36-file suite ten times, toggle `async` in real shared-DB tests, run another CI dispatch, or use profile-require as an A/B arm. `--profile-require time` bypasses `ExUnit.async_run()` in this Mix version and thus cannot test the scheduling boundary; the prior standalone profile remains a non-comparable compile diagnostic.

Suggested disposable harness invocation shape (one generated source variant per arm; this is not a project `mix test` command):

```bash
elixir -r tmp/next-measurement/timing_formatter.exs \
  -e 'ExUnit.start(autorun: false, formatters: [Threadline.MeasurementFormatter]); task = ExUnit.async_run(); Kernel.ParallelCompiler.require(["tmp/next-measurement/canary_async.exs"], []); Process.sleep(2_000); ExUnit.await_run(task)'
```

The sync arm changes only the required canary filename. In the actual harness, use a dedicated script instead of shelling through opaque `-e` text so event timestamps and statuses are machine-readable; the one-line example only shows the no-dependency entry point. The injected pause is a deterministic pre-`modules_loaded` barrier, not a claim about how long real compiler work takes.

### Pre-registered decision rules

| Observation | Interpretation / next action |
|---|---|
| Async arm's first module occurs before barrier release by ≥1,500 ms in all 5 pairs; sync arm's first module occurs 1,750–2,250 ms after barrier start; pre-helper and setup_all controls meet bounds | **Green for the documented ExUnit boundary behavior and `boot_ms` sensitivity.** This establishes only that async assignment can shift the first-module boundary relative to remaining load; it does not explain which event caused the historic CI delay. |
| Async and sync arms both wait for the barrier, or first-module timestamps do not distinguish the arms while controls pass | **Red for this harness's proposed async-before-barrier effect.** Inspect exact 1.15.8 module registration/runner protocol and formatter event ordering; do not generalize to project startup or change real assignments. |
| Pre-helper control fails to move both boot measurements by 1,750–2,250 ms, setup_all moves boot by >250 ms, or event order violates the captured barrier timestamps | **Measurement invalid.** Correct formatter/start-boundary instrumentation before drawing conclusions; do not use a threshold to explain CI. |
| A/B effect is inconsistent across pairs or either arm has MAD >250 ms | **Inconclusive harness run.** Preserve raw rows and stop; do not add runs until the source of variation is understood and a new run cap is explicitly planned. |
| Controls and A/B are clean | This validates a mechanism and metric boundary only. **Historical CI cause remains unproven**; do not refit weight, factor, assignment, or threshold and do not claim the delay is cured. |

The 250 ms noise tolerance and 1,500–2,250 ms event windows are **proposed decision bounds**, derived from the explicit 2,000 ms pause and meant to catch boundary/order mistakes. They are not estimates of runner noise or claims about CI performance. Five pairs are a bounded semantic experiment, not a substitute for phase acceptance cohorts.

## Adversarial review and scope boundary

- **Elixir runtime/compiler:** `ExUnit.async_run` starts the runner before parallel test-file require. Async case registration can unblock it before all files finish compiling; sync cases wait for the `modules_loaded` barrier. The profile-require branch bypasses this runner path, so its 3.327 s/118-module result cannot be added to or substituted for normal `boot_ms`.
- **OS scheduler / architecture:** Capture architecture, CPU quota, host load and cache/order state. VM scheduler utilization may explain delays after the runner starts; it cannot retroactively turn `boot_ms` into test execution time. Container emulation changes timing and should be treated as a platform limitation.
- **SRE / measurement validity:** Preserve raw per-run values and hashes, not only medians. Define invalid-run criteria before sampling. A single successful CI diagnostic cannot demonstrate stability; retries are disallowed under the existing one-dispatch decision.
- **Security / operator DX:** Keep the harness in a disposable temp directory, restrictive permissions, no environment dumps, no secrets or raw process environments in output. Produce a small TSV/Markdown record with image digest and hashes; do not upload CI artifacts or mutate the immutable diagnostic branch.
- **Semver / dependencies:** Add no package or benchmark dependency. Use only Elixir/OTP, existing shell/runner/formatter, and standard tools already present. Keep Elixir 1.15.8 compatibility; do not use newer `--repeat-until-failure` (introduced 1.17) or newer Mix options as the experiment primitive.
- **Cross-decision coherence:** Keep D-11's cost-model refit and D-12's 1.15 warning policy separate from this startup probe. Use per-file existing artifacts to model body/load costs; do not re-fit async factor from one diagnostic. Any acceptance claim still requires the ordered main runs in D-02/D-08/D-12 and a separate CI budget decision.

### Angles checked; not worth pursuing now

- **Replay 31-file B4 versus 36-file diagnostic head:** rejected as a causal comparison because file inventory, source fixtures, and async mix changed.
- **Another full CI dispatch, PR, or hosted benchmark:** outside the consumed 1/1 authorization; one changed-head result is insufficient and another hosted sample cannot isolate a variable.
- **`--max-cases 1` as the load-barrier control:** rejected because it limits number of concurrently running async modules but does not make them sync or defer registration until all files are loaded; weak oracle for the question.
- **`--trace` as the sync control:** rejected because it changes concurrency, reporting, and test timeout behavior (timeouts become infinite), confounding the measurement and weakening hang behavior.
- **Only profile-require:** insufficient; its Mix code path never calls `ExUnit.async_run()` and skips execution, so it cannot validate runtime scheduling or the first-module boundary.
- **Microbenchmark framework / third-party profiler / custom perf counters:** not justified for a one-off 1–2 second boundary question; adds dependency/tool variance and analysis overhead. OTP scheduler stats are optional diagnostics, not a replacement for measured wall time.
- **Native ARM versus emulated AMD64 as a cross-comparison:** not a valid single cohort. Use one architecture per paired experiment and report the transfer limitation.
- **Database/query profiling, test-body optimization, or fixture extraction:** no evidence connects these to the pre-first-module interval; prior fixture extraction saved 0.400 s require time but increased warm project compile by 1.531 s and combined time by 1.131 s.
- **Redefining `boot_ms` or moving startup work:** no product or CI acceptance decision here. The immediate need is truthful interpretation and attribution, not a metric rewrite.

## Lessons for the planner

1. Read the callee and its server protocol before inferring ordering from a caller. In this runtime the runner starts before the parallel compiler require returns.
2. Treat the documented 31→36 file/async assignment change as a confounded comparison; because async modules can start during require, it can shift the metric boundary as well as change work.
3. Keep a local hypothesis test separate from CI acceptance: no local finding changes the 9-minute, ratio, or coverage claims.
4. Preserve source/load/cache/host identity and raw observations. A result without these controls is anecdotal and must not move a constant or threshold.

## Sources

### Primary: runtime and toolchain

- [Elixir v1.15.8 `Mix.Tasks.Test` source](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/mix/lib/mix/tasks/test.ex) — app start, helper load and `CT.require_and_run` ordering.
- [Elixir v1.15.8 `Mix.Compilers.Test` source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/mix/lib/mix/compilers/test.ex) — `async_run` before `ParallelCompiler.require`, followed by `await_run`.
- [Elixir v1.15.8 `ExUnit.Case` source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/case.ex) — after-compile registration into async or sync module queues.
- [Elixir v1.15.8 `ExUnit.Server` source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/server.ex) — asynchronous module availability and the all-modules-loaded barrier.
- [Elixir v1.15.8 `ExUnit.Runner` source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/runner.ex) — async queue scheduling and `module_started` dispatch.
- [Elixir v1.15.8 ExUnit source](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit.ex) — async module semantics, `max_cases`, and timeout behavior.
- [ExUnit.Formatter v1.15.6 docs](https://hexdocs.pm/ex_unit/1.15.6/ExUnit.Formatter.html) — formatter event contract; patch-level documentation nearest to the 1.15.8 runtime.
- [Mix `mix test` v1.15.3 docs](https://mix.hexdocs.pm/1.15.3/Mix.Tasks.Test.html) — profile-require semantics; exact 1.15.8 local diagnostic is recorded in phase evidence.
- [Erlang/OTP ERTS `erlang` docs](https://www.erlang.org/docs/28/apps/erts/erlang.html) — wall/runtime and scheduler-wall-time semantics. Scheduler guidance is stable across the relevant interface; target CI is OTP 26.2.5.21.

### Primary: measurement practice

- [LLVM Benchmarking tips](https://llvm.org/docs/Benchmarking.html) — repeated runs, noise reduction, and measurement bias.
- [Google Benchmark user guide](https://github.com/google/benchmark/blob/main/docs/user_guide.md) — repetitions, aggregates, and randomized interleaving.
- [Linux kernel CPU isolation documentation](https://docs.kernel.org/admin-guide/cpu-isolation.html) — scheduler, interrupt, and frequency sources of timing noise.

### Repository evidence

- `AGENTS.md`; `prompts/threadline-elixir-oss-dna.md`; `prompts/audit-lib-domain-model-reference.md` (verification/CI discipline; domain model is unrelated to this measurement and adds no constraints).
- `.planning/phases/247-ci-critical-path-and-suite-lanes/247-CONTEXT.md`, `247-DIAGNOSTIC-RUN.md`, `247-DIAGNOSTIC-EVIDENCE.json`, `247-VERIFICATION.md`.
- `.planning/debug/247-min-startup.md`; `test/support/partition_monitor.ex`; `bin/ci-test-partitions`.

## Confidence and unresolved questions

| Area | Confidence | Basis |
|---|---|---|
| `boot_ms` meaning and async boundary | HIGH | Corrected after tracing the v1.15.8 Mix callee, ExUnit Case registration, Server barrier, Runner, and repository formatter. |
| Historical CI cause | LOW / unresolved | 17–22 s did not recur in the one changed-head off-main run; source/assignment/load changed and no repeat is authorized. |
| Proposed local thresholds/protocol | MEDIUM | Explicit pre-registration designed to detect a large boundary effect; thresholds require maintainer acceptance when converted into an execution plan. |
| CI acceptance status | HIGH | The diagnostic is explicitly not a main cohort; 247-VERIFICATION remains `gaps_found` at 2/4. |

Open question: after the synthetic boundary experiment validates the mechanism, what evidence is sufficient to localize the historic CI-only delay without another CI dispatch? Current answer: none of the available observations is sufficient; record the gap and stop pending separately authorized evidence.
