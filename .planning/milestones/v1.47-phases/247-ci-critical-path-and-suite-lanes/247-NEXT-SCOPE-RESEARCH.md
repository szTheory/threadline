# Phase 247 Next-Scope Research — Reliability, Measurement, and Stop Rule

**Prepared:** 2026-10-27
**Scope:** Bounded next decision for CI-02/CI-03 gaps; no source, workflow, CI, or GitHub changes.
**Confidence:** HIGH for recorded phase evidence and GitHub Actions behavior; MEDIUM for the proposed local experiment design.

## Recommendation

Do one local-only, preregistered diagnosis of the min-lane startup interval and assignment-cost model, then stop. Keep the existing fixture reliability fixes as an independently reviewable test-only candidate; do not combine those changes with a performance experiment or infer a performance gain from them. Do not tune weights, async assignment, thresholds, or workflow from the single diagnostic run. A proven causal fix can become a separately reviewed future candidate, with its exact-head required CI run treated as the ordinary merge gate and any new main measurement cohort requiring a new, explicit run-budget decision.

This is a recommendation, not evidence that CI-03 is solved or a request to waive its target. If the fixed local experiment is inconclusive, retain the honest gap and require an explicit scope decision before another hosted cohort or a target change.

## Evidence and Current State

- Phase scope set CI-02 to a five-success main median and CI-03 to partition ratio `<= 1.15` across three runs; it requires measurement on main and explicitly says a miss stays a recorded gap pending a scope decision. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-CONTEXT.md`, “Phase Boundary”, D-08, D-12]
- Plan 19 stopped at its six-run cap with four qualifying successes and two failed exclusions. The canonical median is null, so CI-02 remains incomplete. The fixed min ratios are `1.24 / 1.28 / 1.27`, all above `1.15`; CI-03 remains a measured miss. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-19-SUMMARY.md`, “Execution and exact head”; `.planning/phases/247-ci-critical-path-and-suite-lanes/247-VERIFICATION.md`, CI-02/CI-03 findings]
- Two reviewed local test-fixture fixes (`136bb932`, `714b4dbb`) pass their targeted negative controls and broader local checks. They are test-only, not on main, and did not establish a changed main ratio. The local recovery explicitly warns that its ARM64/PostgreSQL 16 timing is not CI's AMD64/PostgreSQL 15 acceptance environment. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-RECOVERY.md`, “Committed fixes” and “Verification”]
- The sole authorized off-main diagnostic, run `40504321590`, passed 17/17 jobs in 450 seconds. It is one observation on a different head, not a fifth B4 success or a main measurement. The previously observed 17–22 second min P3 pre-module interval did not recur; helper work was fast. Its actual P3 assignment also changed from the frozen 31 all-sync files to 36 files including eight async files. The isolated compile profile lacked concurrent partition load. The evidence itself concludes neither the startup cause nor a corrective optimization is proven. Its 1/1 dispatch budget is spent. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-DIAGNOSTIC-RUN.md`, “Identity and budget”, “Startup findings”, “Disposition and next scope”; `.planning/phases/247-ci-critical-path-and-suite-lanes/247-DIAGNOSTIC-EVIDENCE.json`, limits]
- Security register reports 40/40 planned threat IDs closed at ASVS L1, while expressly leaving CI-02 incomplete and CI-03 a miss. Therefore this follow-up should preserve those security dispositions and avoid claiming a deeper security audit or a performance acceptance result. [VERIFIED: `.planning/phases/247-ci-critical-path-and-suite-lanes/247-SECURITY.md`, sign-off and final audit]

## Bounded Local Investigation

**Owner:** CI/test-infrastructure maintainer (or executor); a second reviewer checks the frozen protocol and interpretation. No hosted-run owner is needed because this scope spends no CI dispatches.

1. Before collecting observations, freeze the disposable harness, exact min Elixir/OTP pair, compiler/dependency cache state, process layout, timing boundaries, and unchanged cost formula. Do not change source, production test assignments, weights, real-suite async tags, or workflow. Any async-vs-sync comparison must use an isolated synthetic auxiliary canary, not tests that touch a real DB, shared environment, or filesystem. A compiler/load-boundary control is an alternative if it can exercise the timing oracle without changing suite behavior.
2. Use one disposable harness and a fixed cap of three paired observations per condition, alternating order. Put a specified controlled load barrier in the synthetic canary so the tracer's helper/file-load/first-module boundaries have a known ordering and interval. Capture those timestamps and the canary's wall time; emit no payloads, process dictionaries, test contents, or secrets. Bound child processes and clean up only the process group created by the harness. The pairs are descriptive causal screening, not a statistical proof.
3. Treat two questions separately: (a) does the tracer correctly measure its declared timing semantics under the controlled barrier? (b) does any result explain the historical 17–22 second min-lane interval on CI's AMD64/PostgreSQL 15 environment? Passing (a) validates the oracle only; it does not establish (b). A faster local ARM host, or failure to reproduce the historical delay there, must not be called an inconclusive oracle test or evidence that the CI cause is fixed. Concrete canary stimulus and expected-bound values are deferred to the measurement-design research; do not invent a portable threshold from the historical interval.
4. In the same read-only analysis, replay B3, B4, and diagnostic per-file durations through the unchanged cost formula and assignment. Report predicted component costs and residuals; label these as explanatory model diagnostics, not CI ratios or proof of target-runner behavior. Do not refit parameters to the observations.
5. After the three-pair cap, stop. If the controlled canary validates timing semantics, record that bounded result and keep the historical CI cause unresolved unless there is independent target-environment evidence. If the oracle fails its specified controlled expectation, report the instrumentation defect and stop. Neither outcome authorizes more samples, source tuning, or hosted dispatches. CI-02 and CI-03 remain governed by their unchanged acceptance protocols.

## Candidate Separation, Gates, and Spend

| Work | Treatment | Gate / budget |
|---|---|---|
| Fixture reliability fixes (`136bb932`, `714b4dbb`) | Keep as a separate test-only quality candidate. Their source review and local negative controls are evidence for fixture correctness; they are not performance evidence. Keep change ownership clear so a future partition profile can identify which changed factor caused what. | Exact-head local canonical verification plus independent review; if proposed for merge, the normal PR-required check on that exact head must be green. No extra dispatches or main measurement cohort are implicit. |
| Local tracer + unchanged-model replay | One fixed, local-only diagnostic as described above. No package, API, public behavior, test exclusion, workflow, weight, or threshold change. | Three predetermined pairs, fixed endpoint; stop on inconclusive result. |
| Causal CI candidate, if found | New candidate with only the causal performance change and its focused contract/negative control. Keep fixture-only fixes out unless required for the causal change. | Review and exact-head required CI gate before any standing merge grant is used. State expected resource/time cost before execution. |
| New hosted performance cohort | Separate from candidate PR acceptance and from the completed diagnostic budget. Use the fixed existing main identity and acceptance rules unless the maintainer explicitly changes scope. Preserve failed runs and exclusions; do not retry a failed run or continue past a fixed cap to obtain a favorable sample. | New explicit run-budget decision required before dispatch. Stop on cap; no automatic seventh run and no relaxation of `1.15`, `540 s`, or five-success requirements. |

GitHub documents `workflow_dispatch` as a manually run workflow event (Actions UI, CLI, or REST API), but that technical capability is not authorization for another run. [CITED: [Managing workflow runs](https://docs.github.com/en/actions/how-tos/manage-workflow-runs)] GitHub also documents job/workflow `GITHUB_TOKEN` permissions as a way to grant minimum required access; retain the existing narrow permissions and add only a job-scoped read permission if a demonstrated artifact operation needs it. [CITED: [Workflow syntax — permissions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions)] Same-run artifact handoff uses upload/download actions between dependent jobs; cross-run downloads need a token and run identifier, so a future receipt or experiment should keep run identity explicit and avoid cross-run artifact inputs. [CITED: [Store and share workflow artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data), [download-artifact](https://github.com/actions/download-artifact)] Per-artifact `retention-days` is configurable but cannot exceed repository/organization/enterprise limits; select only the retention needed to preserve the approved evidence, and ensure artifacts contain bounded diagnostics rather than sensitive test state. [CITED: [Store and share workflow artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data)]

The repository guide's standing merge grant is for an agent's own green, reviewed quality PRs; it does not override the separate explicit budget already exhausted for measurement. [VERIFIED: `.planning/MILESTONE-GUIDE.txt`, “Operating Posture”; `.planning/phases/247-ci-critical-path-and-suite-lanes/247-DIAGNOSTIC-RUN.md`, “Identity and budget”]

## Adversarial Review of “Local A/B + Offline Fit”

The proposal is useful only as a bounded oracle check and descriptive screening exercise. It can pass while the explanation is wrong if it:

- toggles async mode on tests that use real DB, environment, or shared filesystem state, changing behavior or introducing unsafe cross-test interference;
- changes fixture/process ownership together with the canary stimulus, so the apparent effect belongs to changed test behavior or removed contention;
- compares a frozen 31-file B4 profile with a 36-file live assignment, or treats `boot_ms` as the same endpoint after the first module scheduling boundary changed;
- warms compilation/dependency caches in one arm, profiles serially while another arm runs under four partition processes, or uses a different runner/DB/toolchain and then calls the effect “CI startup”;
- fits parameters on the same small sample used to declare success, silently changes the async factor/weights until the model matches, or treats an offline estimated cost ratio as the printed acceptance ratio;
- omits sync/async exact-once checks, fixture process ownership checks, failed-attempt exclusions, or explicit per-pair raw results, allowing tests to pass while silently dropping work or cleaning up a still-running process;
- allows background children to survive a timed-out sample and contaminate later pairs, or chooses only the favorable retry/order after seeing results.

Countermeasures are an isolated synthetic canary or compiler/load-boundary control, a specified controlled-load oracle, fixed process/cache state, alternating order, exact process-group ownership, full raw-pair retention, unchanged suite annotations and model, and no post hoc extra samples. Keep any diagnostic artifact run-scoped and short-lived; store the concise summarized evidence needed for later review in the repository. The historical CI root cause remains unproven unless target-environment evidence establishes it.

## Lessons to Carry Forward

**DO**

- Freeze the measurement head, run identity, sample cap, exclusions, and acceptance logic before spending hosted CI; preserve the canonical incomplete payload and immutable failures.
- Separate correctness/reliability evidence from performance causality and acceptance. Let each candidate change one measurable factor.
- Test fixture ownership and cross-process filesystem isolation with a negative control that demonstrates the regression when the fix is removed.
- Keep test-only fixes test-only, public APIs stable, action pins full-SHA with provenance comments, artifacts scoped by run and lane, outputs capped, and token permissions minimal.
- Use normal exact-head required CI as the merge gate; make extra measurement-run spend a distinct checkpoint.
- Stop when the fixed experiment cannot answer the causal question. Preserve the gap rather than manufacturing a pass.

**DO NOT**

- Do not reinterpret a one-run diagnostic as a B4 success or main median; do not replace historical evidence or fabricate a complete measurement file.
- Do not assume that an apparently old/excluded path proves a cause, or that test fixture repairs improve a timing ratio.
- Do not mix tracer changes, fixture changes, async flags, weight refresh, cache policy, and timeout/threshold tuning in one candidate.
- Do not copy per-lane weight/model complexity unless evidence proves the simpler shared model misses and the added state pays for itself.
- Do not weaken `mix test`, add exclusions, silently alter public/package behavior, or take the user's explicit scope/budget decision for them.

## Dimensions Reviewed and Stopping Point

In scope: CI reliability and measurement integrity, evidence provenance, fixture/process ownership, artifact retention and data minimization, workflow token scope, merge-gate semantics, runner cost, test coverage preservation, exact-head verification, and whether a change touches public API or semver. No new package or public API is justified; CI/test-only changes remain non-releasable per phase context.

Security work is constrained to the existing narrow controls: artifact minimization/retention, run-scoped provenance, pinned actions, bounded process diagnostics, and least privilege. The phase already closes 40 authored threats at ASVS L1; a new generic security checklist, L2/L3 claim, SIEM/compliance feature, or UI review would be unrelated. UI work remains out of scope under the project milestone guide. Stop research here because the decisive unknown is empirical causality; further option surveys cannot resolve it.

## Sources

- Phase evidence: `247-CONTEXT.md`, `247-19-SUMMARY.md`, `247-LOCAL-RECOVERY.md`, `247-DIAGNOSTIC-RUN.md`, `247-DIAGNOSTIC-EVIDENCE.json`, `247-VERIFICATION.md`, `247-SECURITY.md`.
- Project constraints: `AGENTS.md`, `prompts/threadline-elixir-oss-dna.md`, `.planning/MILESTONE-GUIDE.txt`, `.planning/MILESTONE-ARC.md`.
- Official GitHub documentation linked inline above. Claims about exact supported features should be rechecked before implementation if the workflow/action major versions change.
