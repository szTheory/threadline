# Phase 248 — implementation research synthesis

**Date:** 2026-11-10
**Scope:** ADM-01–04. Research is not an execution or acceptance receipt.

## Recommendation

Use four bounded, ordered slices: preserve the candidate/dispositions; correct the explicit host mount contract; update the vulnerable locked dependencies within current constraints; repair the repeat-suite setup and obtain affected proof. The approved milestone scope/order remains unchanged. Do not port retained UI edits in this phase.

## Evidence and implementation guidance

### Candidate preservation (ADM-01)

The independent [candidate report](../../../research/2026-11-10-brand-admin/248-candidate-research.md) contains exactly 31 product/docs/test rows, per-file blob identities and port/replace/defer recommendations. Preserve the old `agent-241-01` checkout and its unrelated planning/instruction changes. Four retained paths overlap subsequent upstream work: accessibility browser tests, motion browser tests, the Admin guide and the style contract. Preserve upstream modal focus assertions, the current package-version example and the `:repo_contract` tag when later phases replay intent.

Promote the matrix into a phase baseline artifact with source identities and proof owners. Recheck its rows against the preserved dirty files without modifying that checkout. A file may have multiple later owners, but each distinct path appears once in the inventory. No row is a port into Phase 248.

### Explicit mount contract (ADM-02)

The [mount report](../../../research/2026-11-10-brand-admin/248-mount-research.md) traces `router.ex`, `auth.ex`, export/theme plugs, fixture mounts and guide contracts. The current guard accepts any pipeline, even though the absent callback defaults to allow. Require a usable unary `authorize_fn` or exact literal `adopter_acknowledges_unauthenticated: true`. Pipeline-only, missing/nil authorizer and non-true acknowledgement must not pass. Reject statically evident wrong callback arity; opaque expressions must retain runtime deny/error behavior. Do not evaluate arbitrary callback AST during macro expansion.

Retain valid callback captures and expressions, `:ok`/`true`/`{:ok, scope}` returns, callback denial/error behavior, query scope and generated routes. A deliberate unauthenticated mount retains its existing meaning. Give explicit test fixture mounts auth intent rather than weakening the shared router helper. Reconcile the stale guide claim that acknowledgement raises in tests/warns in production against actual supported behavior. Use the checked UI-SPEC diagnostic as the copy contract.

### Compatible advisory remediation (ADM-03)

The current [proof report](../../../research/2026-11-10-brand-admin/248-proof-research.md) verifies live issue #61 and primary advisories. Minimum compatible targets: Ecto 3.14.3 in root/bench/example, Phoenix.HTML 4.4.0 in root/example, Bandit 1.14.1 in example. Existing constraints already admit these fixes. Resolve through Mix; inspect collateral lock changes and minimum-toolchain compatibility before accepting them. Do not edit Hex checksums by hand, suppress advisories, raise support floors or change public APIs.

Inspect all three audit results, including non-blocking example/bench findings: a zero process exit alone is not a clean advisory report. Any remaining reachable runtime risk blocks affected acceptance/release; preserve the existing tier policy. Local evidence does not close live issues or replace the scheduled clean receipt.

### Attributable suite setup (ADM-04)

Live run [42577559585](https://github.com/szTheory/threadline/actions/runs/42577559585), source `d35b9422`, seed `876664`, failed two tests in `BrowserJourneyEvidenceContractTest` because the locked Playwright CLI was absent. The Flake Detection workflow lacks the pinned Node/`npm ci` setup already present in the current required-test lane. This is an observed setup failure with a source-grounded root-cause inference, not evidence of random test flakiness.

Add the equivalent existing pinned Node setup and locked E2E installation before the full repeat suite. Preserve job IDs, tags, suite scope, repeats, budgets, classifier and failure visibility. Reproduce the specific missing-CLI failure once in a clean isolated environment, then run the same seeded file after setup. Use one post-fix existing repeat-suite proof, diagnosing any new failure before further execution. Do not dispatch hosted CI or push merely to reproduce a known setup omission; prepare local proof and disclose live receipt limits. Required local builds/tests/review are already authorized.

## Execution boundary

GSD 1.20.0 resolves `orchestrator-worktree` and a usable `codex exec --cd` descriptor. The supported local `worktree.set-baseref` setting resolved the missing default-fork-reference condition without disabling isolation. Before any executor starts, create through the GSD adapter, verify the actual fork equals the candidate and bind cwd through the resolved descriptor. Preserve configured worktrees and stop if binding cannot be established. Do not substitute an unisolated collaboration executor.

## Validation Architecture

- Candidate/disposition: compare the 31 unique rows and blob identities against the preserved worktree; verify approved brand-source hashes and current-main ancestry. No browser result is implied.
- Mount: existing compile matrix plus runtime auth/export/theme denial/scope contracts; update only affected fixture mounts. Focused checks first, then the operator tests and example host behavior already exercised by canonical gates.
- Advisories: existing `mix verify.deps_audit` across all three lockfiles with findings inspected, dependency diff review and current supported-toolchain compile/test proof.
- Suite: the recorded seeded evidence-contract file, existing workflow/setup contracts, then one affected repeat run after setup. Preserve the real Playwright discovery tests rather than replacing them with file-presence assertions.
- Integrated phase gate: existing `mix ci.all` after repairs, with subordinate checks reused where source identity supports it. No new jobs, paid critic, broad cross-product runs or silent retries. Resource/environment failures are evidence gaps until diagnosed.
- Review: independent plan checker and code review, with all relevant findings fixed and bounded retests before completion. No routine human UAT.

## Adversarial synthesis and remaining assumptions

The independent UI contract review found no phase-boundary conflict. It correctly identified unresolved deterministic edge-probe rows. Preserve the original probe report; classify the three inventory probes with concrete assertions and carry the three `unclassified` requirement probes as explicit assumptions alongside their substantive tests. Do not auto-dismiss an unclassified item or infer passing acceptance from a planning artifact.

Potential failure modes to guard: validating only LiveView but bypassing generated HTTP routes; treating a truthy acknowledgement or nil callback as explicit auth; accepting audit exit zero with non-blocking findings; re-running the whole suite before installing its real discovery dependencies; copying the old UI diff over upstream fixes; calling local readiness a live issue/CI/release receipt.

No new scope/security/compatibility decision is required by the research. If implementation demonstrates that an in-range dependency fix cannot support the current toolchain, stop the affected path and present that concrete consequence.
