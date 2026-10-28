# Phase 247 Cost Model Follow-up — Research

**Researched:** 2026-10-27
**Domain:** Elixir test partitioning, CI timing evidence, and bounded cost-model validation
**Confidence:** HIGH for the frozen evidence and current implementation; MEDIUM for cross-framework guidance; LOW for root cause beyond the captured evidence.

<user_constraints>
## User Constraints (from 247-CONTEXT.md)

These are the phase decisions that directly constrain this cost-model supplement. The complete source remains [247-CONTEXT.md](247-CONTEXT.md).

### Locked Decisions

**D-03: Commit types.** CI/test infrastructure changes are non-releasable (`ci:`/`chore:`/`test:`); nothing in this phase changes the public API or the Hex package.

**D-08: Measurement protocol and miss policy.** The first 5 consecutive `ci.yml` runs on main at/after the split head, attempt 1, conclusion success; event `push` or `workflow_dispatch` on main. Record the 5 run IDs, wall times, median, per-leg and fan-in durations, and the new slowest job in VERIFICATION. If it misses: read CI-01 per-project totals; shard the dominant project 2-way; re-measure. Never relax 9 min silently — a remaining miss is a recorded gap and a scope decision for the maintainer.

**D-09: Classify with `@moduletag :repo_contract`**, meaning “outcome does not depend on the Elixir/OTP/PostgreSQL toolchain”. Module tag only, never per-test `@tag` (exclusion is per file). The file name is NOT the classifier. Each candidate needs review; untagged runs everywhere.

**D-10: Exclude by file filtering in `bin/ci-test-partitions`**, driven by `THREADLINE_TEST_SCOPE: toolchain` on the min and latest matrix rows only (absent on current). Local `mix test` and the current lane run everything; the `test_helper.exs` exclude list does NOT change.

**D-11: Weights from real CI timings.** A CI-only formatter records per-file wall time, partition boot time before first module, and partition wall; writes a TSV per partition uploaded on all lanes. Ingestion takes per-file medians from three current-lane runs; fit the async factor once by least squares from partition totals vs sync/async sums. Keep N=4. Keep `--write-weights` as offline fallback. Use per-lane weights only if min/latest still miss 1.15 after refresh.

**D-12: Ratio measurement.** The script prints `max/min ratio` and emits `::warning::` above 1.15 — NOT a hard gate. VERIFICATION records the ratio for 3 consecutive runs on each lane from the step summary. Parse the script's table, never ExUnit summary lines. Run `mix verify.flake` or 3 CI runs after reassignment before claiming the ratio.

### the agent's Discretion

- Final per-leg timeouts and budgets once CI-01/D-11 data exists (D-16 budget style, documented in comments).
- Whether the measurement script lives in `bin/` or under a phase `tools/` dir.
- Optional small `with_timeout/2` helper for `setup_all` subprocess calls if the D-16(c) reproduction points at one.

### Deferred Ideas (OUT OF SCOPE)

- Raising Playwright `workers` above 1 (needs per-worker DB/tenant isolation + flake run).
- Rebalancing current-only steps across lanes.
- Path-aware / change-aware lanes — SEED-006 stays closed unless its measured trigger fires.
- `Mix.shell().cmd` not forwarding cancel signals to child scripts — a possible future requirement line (mitigated here by the script's own watchdog).
</user_constraints>

## Summary

**Recommendation: keep the assignment rule, `292/1000` async factor, lane scope, four partitions, colocation and 1.15 threshold unchanged. Make the next cost-model step a single bounded, read-only replay of the frozen B3, qualifying B4 and diagnostic timing evidence, with startup kept separate from modeled test-body cost. Do not refresh weights from the mixed-head diagnostic or launch another CI cohort from this evidence.** [VERIFIED: `bin/ci-test-partitions:229-236,357-362`; `.planning/phases/247-ci-critical-path-and-suite-lanes/247-19-SUMMARY.md:44-65`; `.planning/phases/247-ci-critical-path-and-suite-lanes/247-DIAGNOSTIC-RUN.md:82-120`]

The evidence points to at least two different effects: B4 min's total ratio misses coincide with a repeated 17–23 s partition-3 **pre-first-module** delay, while the single diagnostic run had a short pre-first-module interval but a still-imbalanced observed body-cost profile. Do not interpret the TSV field `boot_ms` as VM startup alone: exact Elixir 1.15.8 Mix source calls `ExUnit.async_run()` before `Kernel.ParallelCompiler.require(...)`, then awaits test execution afterward, so test-file require/compilation and suite scheduling overlap. A first-module timestamp may therefore be affected by load/compile concurrency. The diagnostic changed source and assignment shape, so those outcomes cannot be pooled as one controlled before/after. A model replay can identify which component deserves a new hypothesis; it cannot close CI-03 or prove a new candidate. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-19-SUMMARY.md:61-65`; `.planning/phases/247-ci-critical-path-and-suite-lanes/247-DIAGNOSTIC-RUN.md:66-103`; CITED: [Elixir v1.15.8 `Mix.Compilers.Test`](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/mix/lib/mix/compilers/test.ex), lines 66-80]

**Primary recommendation:** perform the audit below once, preserve the existing fail-closed inventory and acceptance rules, and stop with “no signal” if no repeatable residual cause emerges. If an actionable hypothesis survives, write a separately reviewed candidate and request a new measurement budget before any hosted run or landing. [INFERENCE from the phase measurement boundary in `247-CONTEXT.md` D-08/D-12 and the stop record in `247-19-SUMMARY.md:75-81`]

## Evidence and interpretation

| Evidence set | Use in the audit | Limits |
|---|---|---|
| Fixed B3: three runs × four timing files per lane | Reproduce the existing formula on the source cohort; check arithmetic and lane splits. The phase record says these are the fixed main runs used to refresh all three lane weights. [VERIFIED: `247-16-PLAN.md` context and `247-16-SUMMARY.md` “Implementation and provenance”] | The same cohort informed the weights and is not an independent holdout. Do not present its model fit as out-of-sample evidence. [INFERENCE from the B3 ingestion and evaluation sequence in `247-16-PLAN.md`] |
| Fixed B4: four qualifying successful runs on the same main squash | Use only as the chronological holdout for descriptive replay; retain the first-three mandated ratios as the official fixed ratio sample. [VERIFIED: `247-19-SUMMARY.md:48-57`] | Two failed runs are exclusions, not slow or failed timing samples. B4 is incomplete (4/5); it does not provide a completed median acceptance result. [VERIFIED: `247-19-SUMMARY.md:44-55`] |
| One off-main diagnostic | Analyze separately for startup phases and body residuals. Its immutable evidence includes actual per-partition assignments and raw timing rows. [VERIFIED: `247-DIAGNOSTIC-RUN.md:20-39,46-55`] | Different source head, extra fixture fixes/instrumentation, and changed min assignment shape make it neither a fifth B4 run nor a controlled before/after. [VERIFIED: `247-DIAGNOSTIC-RUN.md:36-41,82-103`] |

### Bounded replay result

The phase's source-head replay reports that the duration-floor model lowers fixed B3 residual RMS from 35.693 to 6.963 s on min, 17.589 to 14.528 s on current, and 29.264 to 7.108 s on latest, evaluating the original assignments. This supports the specific long-async-floor correction on its source cohort; it is not validation of refreshed weights or live balance. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-16-SUMMARY.md` “Fixed B3 model check”; formula and async classifier quoted from `bin/ci-test-partitions:229-236,320-362`]

On the four qualifying B4 min runs, direct arithmetic on header `wall_ms` and `boot_ms` yields total ratios of 1.238, 1.287, 1.271 and 1.256; diagnostic body-only ratios are 1.140, 1.165, 1.127 and 1.171. Partition 3's header interval is 20.469 / 18.940 / 17.227 / 22.723 s across the four successes, versus about 1.9–3.0 s for the other partitions. The first three official B4 total ratios are reported as 1.24 / 1.28 / 1.27. The B4 body-only calculation is diagnostic only: it does not erase the miss under the exact acceptance rule. [VERIFIED: header arithmetic on qualifying B4 min TSVs under `/tmp/threadline-247-b4-artifacts/{40449332597,40450141708,40450801580,40451533079}`; reported ratios quoted from `.planning/phases/247-ci-critical-path-and-suite-lanes/247-19-SUMMARY.md:48-55`; phase interpretation at `247-19-SUMMARY.md:65`]

The diagnostic trace found pre-first-module intervals of 1.6–2.2 s. Its saved, source-aware formula analysis gives body residuals 7.3 / 10.0 / 12.9 / 2.9 s and a printed min ratio of 1.31. The stored committed-weight prediction was about 133.6 s per partition while diagnostic observed formula costs were about 78.6 / 78.1 / 86.9 / 72.1 s. The difference is nonuniform across large files; this is consistent with weight drift or workload changes, but one changed-head sample cannot distinguish them. [VERIFIED: `247-DIAGNOSTIC-RUN.md:46-64,89-103`; `247-DIAGNOSTIC-EVIDENCE.json` `min_phase_analysis` and `raw_min_timings`]

## Local audit protocol

Keep this to one offline pass over artifacts already on disk, plus at most one short controlled local diagnostic only if the replay isolates a concrete startup hypothesis. No new hosted runs, no repeated fitting loop, and no package installation are part of this recommendation. [PROPOSAL; consistent with the explicit one-run diagnostic stop in `247-DIAGNOSTIC-RUN.md:105-123`]

1. **Freeze identity and cohort.** Verify metadata/head/attempt and exact artifact filenames. Use B3 as the source cohort; B4's four successful exact-main runs as holdout; keep the two failed B4 exclusions visible but out of timing statistics; keep the diagnostic isolated. Do not select runs by favorable ratio. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-19-SUMMARY.md:48-57,69-73`]
2. **Reproduce before interpreting.** For every partition, report `boot_ms`, `wall_ms`, row count, sync raw sum, async raw sum, longest async file, modeled cost, `wall - boot - model`, and the total `wall` ratio. Separately calculate body-only ratios for diagnosis. Compare exact millisecond results and the runner's printed integer-second results; do not round inputs before computing residuals. The repository currently reports `# threadline.partition-timings/1 partition=<n> lane=<lane> boot_ms=<ms> wall_ms=<ms>` and its bin-cost function uses the longest async duration as a floor. [VERIFIED: `bin/ci-test-partitions:357-362`; `247-DIAGNOSTIC-RUN.md:68-98`]
3. **Separate weight drift from model residual.** For each recorded assignment, calculate (a) observed-file cost with the classifier and formula from that run's exact source head, and (b) predicted cost from the committed lane weights for the same assignment. Do not apply today's `async: true` grep to historical TSVs unless the relevant test-file source is byte-identical to that run; the diagnostic evidence already stores source-aware classifications and costs. Do not conflate stale per-file estimates with a bad group-cost rule. Preserve colocation as an indivisible group and do not search alternative coefficients or partition counts in this pass. [PROPOSAL; current group cost/assignment implementation quoted at `bin/ci-test-partitions:357-418`]
4. **Stratify before aggregating.** Keep lane, run, partition, boot, and body as separate dimensions. The four partition residuals within one workflow share a runner and are not four independent CI samples. Report run-level ranges and the named per-partition traces; if an uncertainty summary is shown, resample whole runs and label it descriptive only. With three B3 runs, four B4 successes, and one diagnostic run, do not use a bootstrap interval as evidence that the 1.15 criterion is met. [PROPOSAL; sample sizes verified in `247-16-SUMMARY.md` and `247-19-SUMMARY.md:44-55`]
5. **Classify the pre-first-module interval correctly.** Preserve total wall as the acceptance quantity. Keep the TSV's `boot_ms`, helper milestones and first-module timestamp as separate observed stages; the field name is not proof of pure startup. Mix 1.15.8 starts ExUnit's asynchronous run before parallel test-file require and awaits it after require, so an experiment should record both require completion and first module. Do not use `wall - boot` as the accepted ratio: D-12 uses the runner's total partition seconds. [CITED: [Elixir v1.15.8 `Mix.Compilers.Test`](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/mix/lib/mix/compilers/test.ex); VERIFIED: D-12 in `247-CONTEXT.md`; header fields in `bin/ci-test-partitions:264-289`; `247-DIAGNOSTIC-RUN.md:66-87`]
6. **If the static replay isolates a pre-first-module anomaly, run one synthetic local probe only.** Use a benign async canary and a deliberately delayed/blocked require completion under the exact min toolchain, with fixed checkout/cache/host and paired order; record helper completion, require completion, first module and total wall. Cap at three pairs. Do not mutate or mark any shared-database test async; stop if the effect is inconsistent. This can test whether the current first-module metric is sensitive to compile/load overlap, but cannot establish hosted CI acceptance. [PROPOSAL; plausible causal hypothesis from the v1.15.8 source above, requiring falsification]

### Falsifiable disposition

| Result of the bounded pass | Decision |
|---|---|
| Frozen TSVs or identity do not reproduce, or changed/failed cohorts are needed to get the preferred result | **NO-GO.** Fix the evidence reconciliation; do not tune or sample. [PROPOSAL] |
| B4 total misses are reduced in body-only arithmetic but remain above/near the threshold in some runs | **NO-GO for weight/group-cost changes on that fact alone.** Keep total ratio as acceptance; the pre-first-module interval is a hypothesis, and source-aware residual analysis must remain separate. [INFERENCE from B4 headers and `247-19-SUMMARY.md:61-65`] |
| B4 holdout, replayed with the exact source classifier, shows a consistent, explainable body-cost residual tied to a specific measured cause, and one candidate fixes it in a frozen offline replay without changing inventory, colocation, async flags, lane scope, or `N=4` | **GO to candidate design only.** Define an independent validation cohort and explicit budget before any CI dispatch; offline replay is not a pass. [PROPOSAL] |
| No cause survives stratification or the short local probe | **NO SIGNAL; stop unchanged.** Keep the existing gap visible and require new scope/budget for further work. [PROPOSAL; aligns with `247-19-SUMMARY.md:75-81`] |

## Approach decision matrix

| Approach | Strongest case | Evidence risk / cost | Recommendation |
|---|---|---|---|
| **Frozen replay, no source change** | Separates boot, body, stale weights, and model error without consuming CI budget. | Cannot close CI-03 or demonstrate a changed candidate. | **Choose this now.** [INFERENCE from the evidence boundary in `247-DIAGNOSTIC-RUN.md:100-123`] |
| Refresh weights from B4 + diagnostic | Captures newer file durations, and a fresh median may lower skew if the suite has drifted. | B4 is only four successes and diagnostic is a different head; pooling them creates leakage and head/fixture confounding. Refreshing on failed or cherry-picked runs biases the result. | **Reject for this pass.** Use no B4/diagnostic data to write weights. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-19-SUMMARY.md:44-57,79-81`; diagnostic identity at `247-DIAGNOSTIC-RUN.md:20-39`] |
| Change async factor, longest-file floor, LPT, or group-cost math | Could fix systematic underestimation or a clear long-file domination pattern. | The diagnostic's lower observed file costs are nonuniform; tuning on that one altered run would overfit. Async is also a correctness/concurrency property, not only a scheduling hint. [CITED: [ExUnit.Case v1.15.8](https://hexdocs.pm/ex_unit/1.15.8/ExUnit.Case.html)] | **Defer until holdout residual identifies a cause.** Current formula and stable deterministic ties remain. [VERIFIED: `bin/ci-test-partitions:229-236,357-418`] |
| Reclassify `async: true`, alter fixture grouping, or adjust nested Mix/cold-build order | Could reduce contention or stabilize cold nested compile tests if that mechanism is specifically implicated. | Can introduce shared-state flakes or change what the timing represents; needs a focused failing reproduction and security/coverage review. ExUnit says async should only be used when tests do not change global state. [CITED: [ExUnit.Case v1.15.8](https://hexdocs.pm/ex_unit/1.15.8/ExUnit.Case.html)] | **Do not change without a concrete reproducer.** Preserve test flags, inventory, and exact-once gate. [VERIFIED: `bin/ci-test-partitions:423-430`; `AGENTS.md` CI conventions] |
| Adopt Mix default `--partitions` or copy a generic sharder | Less custom scheduling logic. | Mix's documented algorithm is sorted-file round-robin, not measured duration balancing; that conflicts with the recorded prior imbalance and loses this repo's explicit grouping/cost/inventory behavior. [CITED: [Mix.Tasks.Test v1.20.4](https://mix.hexdocs.pm/Mix.Tasks.Test.html)] | **Reject.** Keep the small existing custom scheduler. [VERIFIED: `bin/ci-test-partitions:45-56,357-430`] |
| Start a new hosted CI cohort now | Could yield current acceptance data. | B4 is explicitly incomplete, the diagnostic budget is consumed, and further main CI budget requires a separate scope decision. [VERIFIED: `247-19-SUMMARY.md:44-57,75-81`; `247-DIAGNOSTIC-RUN.md:105-123`] | **NO-GO until separately scoped and authorized.** No model change should be used to justify another run. [PROPOSAL] |

## Architecture, operations, and stakeholder lessons

- **Scheduler boundary:** ExUnit owns concurrency within one VM; Threadline's runner owns cross-VM/file partition assignment. ExUnit's `async: true` is module-level concurrency and is only valid where shared global state is not modified. Keep these meanings distinct. [CITED: [ExUnit.Case v1.15.8](https://hexdocs.pm/ex_unit/1.15.8/ExUnit.Case.html); VERIFIED: `bin/ci-test-partitions:313-418`]
- **Operations:** runner boot is in the acceptance wall, even when it is not a file-weight cost. Measure it separately, preserve the 1.15 warning/report behavior, and don't turn a diagnostic decomposition into a ratio exclusion. [VERIFIED: D-12 in `247-CONTEXT.md`; `247-DIAGNOSTIC-RUN.md:66-98`]
- **Security and integrity:** timing TSVs are external evidence that influences scheduling. Treat them as data; require exact identity, schema, lane, four partitions/run, inventory and successful attempt before interpreting, and retain exactly-once validation. Never let a bad weight silently omit tests. [VERIFIED: `bin/ci-test-partitions:262-308,423-430`; `247-16-PLAN.md` threat model]
- **Maintainer DX and semver:** no new dependency, CI job ID, public API, Hex package behavior, hidden suite skip, or default `mix test` exclusion is justified by this diagnosis. Keep the canonical named verification path. [VERIFIED: `AGENTS.md` “CI & Verification Conventions”; `247-CONTEXT.md` D-03/D-10]
- **Product latency:** the objective is total required-CI wall and balanced partitions, not an attractive model-fit number. The current run is the decision unit for the 9-minute wall and D-12 is a three-run partition measurement; local synthetic wins do not satisfy either. [VERIFIED: `247-CONTEXT.md` phase boundary and D-08/D-12]

## Primary sources

- [ExUnit.Case v1.15.8](https://hexdocs.pm/ex_unit/1.15.8/ExUnit.Case.html) — async is module-level and constrained by shared global state.
- [Mix.Tasks.Test v1.20.4](https://mix.hexdocs.pm/Mix.Tasks.Test.html) — `--partitions` process partitioning and sorted round-robin default; current Elixir/Mix docs, so use only for the generic semantics, not as evidence about Threadline's tested min-lane version.
- [GitHub: Choosing the runner for a job](https://docs.github.com/en/actions/how-tos/write-workflows/choose-where-workflows-run/choose-the-runner-for-a-job) — runner instances/specifications differ by public/private account and label; avoid pooling unlike environments.
- [Bazel Test Encyclopedia 7.7.0](https://bazel.build/versions/7.7.0/reference/test-encyclopedia) — test runner must explicitly cooperate with framework sharding. Prior art for keeping the scheduler boundary explicit; not a recommendation to adopt Bazel.

## Confidence and unresolved questions

| Area | Confidence | Reason |
|---|---|---|
| Current implementation and cohort identity | HIGH | Read the current script and phase artifacts; run identities, B4 exclusions, and formula inputs are recorded. |
| Startup as a contributor to B4 min ratio | HIGH for observation; LOW for root cause | `boot_ms` and 17–23 s partition-3 delays repeat, but source traces do not explain the delay; a different-head run was fast. |
| Weight drift as diagnostic explanation | MEDIUM | Per-file committed and observed durations differ nonuniformly; one different-head run cannot establish future timing distribution. |
| New optimizer/factor/async classification | LOW | No independent validation cohort demonstrates a specific change is causal. |

**Open question:** Does the recurring B4 min partition-3 pre-first-module delay come from test-file require/compile overlap, scheduling, or an external resource interaction under the exact min runner? The diagnostic branch did not reproduce the long interval, but it changed the assignment and source; do not infer that the issue is fixed. The synthetic canary probe can validate metric sensitivity without changing a shared-database test's concurrency contract. [INFERENCE from the v1.15.8 Mix source and `247-DIAGNOSTIC-RUN.md:75-87`]

**Ready for planning:** plan only the frozen replay and a bounded local startup probe if replay indicates it is still decision-relevant. Any weight/model/async or hosted-CI change requires a separately justified candidate, unchanged coverage/thresholds, and a new explicit measurement budget.
