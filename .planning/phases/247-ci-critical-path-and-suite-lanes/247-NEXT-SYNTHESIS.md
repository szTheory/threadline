# Local gap diagnosis: coherent recommendation

Three independent research clusters covered runtime measurement, partition cost,
and operational scope/security. The orchestrator checked the call graph and
challenged the protocol. The maintainer requested this fan-out and automatic
adoption of clear recommendations. No new hosted-run budget was granted.

## Adopted path

1. Build one disposable, dependency-free synthetic ExUnit canary. Use exact min
   Elixir/OTP and the unchanged existing partition formatter. Vary only a benign
   auxiliary case's async metadata around a controlled 2,000 ms loader barrier.
   Record helper/registration/barrier/module/suite events. Never make a real
   database, environment or filesystem test async.
2. Validate the timing oracle with pre-event and post-event delay controls.
   Permit two warmups, three alternating pairs and two controls, each with a
   timeout and an overall deadline. Do not replace unfavorable/invalid samples.
   Logical event ordering is the primary oracle; timings describe its magnitude.
   Three pairs are descriptive replication, not a statistical confidence claim.
3. Replay the frozen existing B3/B4/diagnostic data once. Bind the async classifier,
   model, weights and colocation to each run's source revision. Keep training,
   holdout, failed exclusions and diagnostic observations separate. Report weight
   prediction error and observed-cost residual separately. Fit nothing.
4. Finish with an independently reviewed decision record and reproducible local
   receipts. Any local semantic result leaves historical CI causality and the
   main acceptance gates separate. A no-signal or invalid result stops the work;
   it does not trigger another sampling loop.

These are two serialized gap plans: the runtime canary first, then evidence replay
and decision reconciliation. Their output is a diagnostic disposition, not a
promised optimizer patch. No production source, real-suite annotation, dependency,
workflow, weights, assignment rule or threshold changes are in this scope.

## Adversarial corrections

- The initial runtime report inferred a load barrier from a caller. Exact
  `Mix.Compilers.Test` v1.15.8 instead starts `ExUnit.async_run()` before
  `Kernel.ParallelCompiler.require`, then awaits it. The report was corrected by
  reading the callee, ExUnit case registration, server and runner together.
- Comparing the old 31 all-sync files with 36 files/eight async modules changes
  the workload and the first-event boundary. It cannot identify a causal fix.
- Changing `--max-cases` alone does not remove async module availability during
  loading, so it is not the decisive control. A synthetic load-barrier experiment
  tests that specific mechanism without unsafe suite concurrency.
- An 8.5-second effect cutoff inferred from half the historical interval was
  rejected. Native ARM64 and hosted AMD64 have different speed/noise. Validate
  an explicitly injected event boundary, not an arbitrary portable speed target.
- Five real-suite pairs and repeated profiles add cost while still failing to
  isolate the variable. Three synthetic pairs plus two oracle controls are the
  smaller falsifiable experiment. No test framework or profiler dependency is
  justified.
- Historical replay must not apply today's async classifier to older revisions.
  Partitions within a workflow share a runner; they are not independent samples.
- A passing exact-head diagnostic validates its tests, not the uninstrumented
  merge head, performance causality, a five-run median, or three-run balance.

## Decision coverage and limits

Runtime/compiler, operating-system scheduling, SRE, test maintainers, operator DX,
security, product latency, semver, dependency maintenance and measurement-validity
lenses were considered. UI/rendering/graphics, public API redesign, deeper security
certification and new observability services add no useful decision information
for this CI-only question. Stop the option survey here; the remaining question is
empirical.

Keep the four fixture-fix files independently reviewable. Their local/diagnostic
proof is useful reliability evidence; no further PR, merge, publication or CI
dispatch occurs under this local-only scope. A future causal candidate must be
concrete, locally verified and reviewed before requesting an exact budget for
its PR/main measurement steps.

B4 remains incomplete with its fixed min misses. The one off-main diagnostic
remains separate: 450 s, ratios current/min/latest 1.17/1.31/1.10. Phase 247 stays
2/4 until its original main-based gates are actually satisfied or the maintainer
explicitly changes scope. Nothing here relaxes those gates.

## Primary sources and research inputs

- [Mix.Compilers.Test v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/mix/lib/mix/compilers/test.ex)
- [ExUnit.Server v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/server.ex)
- [ExUnit.Runner v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/runner.ex)
- [LLVM benchmarking guidance](https://llvm.org/docs/Benchmarking.html)
- [GitHub workflow artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data)
- `247-NEXT-MEASUREMENT-RESEARCH.md`, `247-NEXT-MODEL-RESEARCH.md`, and
  `247-NEXT-SCOPE-RESEARCH.md` retain the detailed alternatives, evidence and limits.

## Pre-data operational correction

The first launcher invocation exited Docker 125 before ExUnit started: a bind-mount argument wrongly included `,rw`, and the coordinator did not retain stderr. The original raw preflight receipt remains immutable. One documented launcher/capture repair and metadata-only version preflight precede the first observed series; the original pair/control/deadline limits remain. Any later launch failure or any measured invalidity stops without replacement. This repairs an implementation precondition without discarding or replacing scientific observations.
