---
phase: 248-reconcile-the-base-and-safety-proof-ownership
plan: "02"
subsystem: operator-surface
tags: [phoenix, authorization, router, scope, migration]

# Dependency graph
requires:
  - phase: "248-01"
    provides: Preserved baseline and reviewed host-mount authorization contract
provides:
  - Pipeline-only operator mounts fail compilation with actionable migration guidance
  - Fixture mounts declare real authorization or intentional public access
  - Host migration guides and executable documentation contracts match the compiler policy
affects: [operator-surface, host-auth, migration-guides]

# Actuals
actuals:
  tokens: 9384.5
  tasks: 3
  commits: 8
  plan_head_before: 586cdcdcd0fb5de268cb76f702afc1b18d1d2c38
  plan_head_after: 80f3c0be8b9806e8a5ed8da180fa2cbbb848e148

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Inspect recognizable callback AST arity without evaluating callback code
    - Require an exact literal true for unauthenticated mount acknowledgement

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/router.ex
    - test/threadline/operator_surface/router_test.exs
    - test/threadline/operator_surface/breadcrumb_test.exs
    - test/threadline/operator_surface/card_nesting_regression_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs
    - test/threadline/operator_surface/exports_mix_parity_test.exs
    - test/threadline/operator_surface/gating_test.exs
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - test/threadline/operator_surface/skip_link_test.exs
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/live/actor_live_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs
    - test/threadline/operator_surface/live/evidence_live_test.exs
    - test/threadline/operator_surface/live/policy_redaction_live_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs
    - test/threadline/operator_surface/live/row_history_live_test.exs
    - test/threadline/operator_surface/live/start_live_test.exs
    - test/threadline/operator_surface/live/timeline_live_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - guides/operator-surface.md
    - guides/integration-contracts.md
    - guides/code-walkthrough.md
    - test/threadline/operator_surface_doc_contract_test.exs

key-decisions:
  - "A usable unary authorize_fn or the exact literal adopter_acknowledges_unauthenticated: true is required; pipe_through remains host middleware and never satisfies Threadline authorization."
  - "Known callback shapes and literal non-function values are checked statically; opaque expressions remain runtime-checked and callback bodies are not run during macro expansion."
  - "Inline anonymous callbacks use a unique generated remote helper on the host router because Plug.Builder only accepts remote function captures in route options; no Threadline route, option, or module was added."
  - "Existing route paths, capability callbacks, host query scoping, and authorization return behavior remain unchanged."

requirements-completed: [ADM-02]

coverage:
  - id: D1
    description: "Mount compilation rejects pipeline-only, absent, invalid-literal, and recognizable wrong-arity authorizers while accepting supported callbacks and the exact public opt-out."
    requirement: ADM-02
    verification:
      - kind: integration
        ref: "mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/query/scope_fail_closed_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Affected operator fixtures state their main-mount authorization intent while preserving real scoped and capability authorizers."
    requirement: ADM-02
    verification:
      - kind: integration
        ref: "mix test test/threadline/operator_surface"
        status: pass
    human_judgment: false
  - id: D3
    description: "All three migration guides describe the explicit callback-or-public-opt-out policy and retain host middleware guidance."
    requirement: ADM-02
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface_doc_contract_test.exs"
        status: pass
    human_judgment: false

# Metrics
duration: 32min
completed: 2026-11-10
status: complete
---

# Phase 248 Plan 02: Fail-Closed Operator Mount Authorization Summary

**Operator mounts now require a unary host authorizer or literal public opt-out; pipeline-only mounts fail with actionable compile errors while existing routes and scope behavior remain intact.**

## Performance

- **Duration:** 32 min
- **Started:** 2026-11-11T01:08:05Z
- **Completed:** 2026-11-11T01:40:03Z
- **Tasks:** 3
- **Files modified:** 23

## Accomplishments

- Enforced the approved compile-time mount policy: a usable unary `authorize_fn` or exact literal `adopter_acknowledges_unauthenticated: true`; `pipe_through` alone no longer satisfies it.
- Added negative-path coverage for absent and invalid authorizers, non-literal acknowledgements, recognizable wrong arities, and multi-element tuple literals. Kept callback bodies deferred until runtime and verified generated route contracts.
- Made each affected fixture mount explicit while preserving real main, export, coverage, policy, evidence, actor, and scoped authorizers where those are under test.
- Aligned the operator-surface, integration-contract, and code-walkthrough guides with the compiler behavior and added an executable three-guide documentation contract.

## TDD Evidence

- **Tracer RED:** `mix test test/threadline/operator_surface/router_test.exs` exited 2 with 9 tests and 1 failure. The new pipeline-only mount test failed because compilation did not raise. **GREEN:** the focused router/auth/export/theme/scope command passed all 81 tests.
- **Additional guard RED:** the router matrix exited 2 with 13 tests and 2 failures: a three-element tuple literal compiled, and an exploratory assertion that an inline callback helper could be private failed. The tuple literal was added to the non-function AST rejection. The inline callback contract remains a public-macro compile-and-deferred-invocation assertion; Plug.Builder requires a remote function capture in route options, so inline callbacks are normalized to a uniquely named generated helper on the host router.
- **Documentation RED:** `mix test test/threadline/operator_surface_doc_contract_test.exs` exited 2 with 7 tests and 1 failure because the guide still treated `pipe_through` as mount authorization. After aligning the guidance, the contract passed all 7 tests. Its wording check normalizes Markdown whitespace so line wrapping does not affect the result.

## Task Commits

1. **Task 1 RED:** `5eaf42a9` — `test(248-02): reject pipeline-only operator mount`
2. **Task 1 GREEN:** `8082b1f0` — `fix(248-02): require explicit operator mount authorization`
3. **Task 2:** `43a5afea` — `fix(248-02): declare fixture mount authorization intent`
4. **Task 3 RED:** `6e273495` — `test(248-02): enforce explicit mount migration guidance`
5. **Task 3 GREEN:** `804a93d5` — `docs(248-02): align mount authorization migration guidance`
6. **Guard boundary RED:** `335db912` — `test(248-02): cover literal tuple and inline callback boundaries`
7. **Guard boundary GREEN:** `81405758` — `fix(248-02): reject tuple mount authorizers`
8. **Test review:** `80f3c0be` — `test(248-02): keep inline callback contract behavioral`

**Plan metadata:** to be committed after this summary's self-check.

## Files Created/Modified

- `lib/threadline/operator_surface/router.ex` — explicit mount predicate, literal acknowledgement check, static callback-arity checks, and actionable call-site compile error.
- `test/threadline/operator_surface/router_test.exs` — compile matrix, call-site error assertions, route contract, and callback non-invocation proof.
- `test/threadline/operator_surface/{breadcrumb_test,card_nesting_regression_test,copy_contract_test,exports_mix_parity_test,gating_test,rendered_output_contract_test,skip_link_test,transaction_live_test}.exs` — explicit intent on each affected main mount.
- `test/threadline/operator_surface/live/{actor_live,coverage_live,evidence_live,policy_redaction_live,retention_history_live,row_history_live,start_live,timeline_live}_test.exs` — explicit public test intent alongside unchanged capability and scope callbacks.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` — explicit main-surface intent while retaining export-specific denial and scoped authorization cases.
- `guides/operator-surface.md`, `guides/integration-contracts.md`, `guides/code-walkthrough.md` — corrected host migration contract and examples.
- `test/threadline/operator_surface_doc_contract_test.exs` — executable policy assertions across all three guides.

## Decisions Made

- Host `pipe_through` middleware continues to apply authentication, sessions, CSRF, and tenant policy; it does not satisfy the Threadline mount authorization requirement.
- Literal `true` is the only acknowledgement that opts out, and it is documented as intentional public access with identical compile-time meaning in tests and production.
- A usable inline unary callback is normalized to a generated remote helper in the adopter's router. This helper is an implementation detail required by Plug.Builder's route-option serialization; Threadline adds no route, option, module, or documented callback API.
- Runtime callback grants, denials, errors, scope behavior, capability separation, public routes, and the existing UI/brand assets remain unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reject multi-element tuple literals as invalid authorizers**
- **Found during:** Task 1 close-out review
- **Issue:** The initial literal-shape classifier rejected two-element tuple literals but allowed Elixir's AST form for a three-element tuple, which could not be called as an authorizer.
- **Fix:** Added explicit rejection for tuple-literal AST nodes and a regression case.
- **Files modified:** `lib/threadline/operator_surface/router.ex`, `test/threadline/operator_surface/router_test.exs`
- **Verification:** Router matrix passed 13 tests; focused auth/scope proof passed 81 tests; full operator suite passed 839 tests.
- **Committed in:** `81405758`

**Total deviations:** 1 auto-fixed (Rule 1 bug). **Impact:** The additional negative path closes the planned invalid-literal boundary; no scope expansion.

## Issues Encountered

- The initial Hex cache location was not writable in this worktree. Locked Mix dependencies were fetched using a temporary cache; `mix.lock` and dependency versions were not changed.
- Plug.Builder cannot escape anonymous functions or private local captures into these router options. Inline unary callbacks therefore use a unique generated remote helper in the adopter's router so supported callback ASTs continue to compile without running during expansion.
- The first post-edit documentation check was sensitive to Markdown line wrapping. The test was changed to normalize whitespace, and the final contract passes.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

- Plan 248-02 is complete. The focused authorization/scope proof passed 81 tests, the affected operator suite passed 839 tests, the documentation contract passed 7 tests, and formatting checks passed.
- The plan's flagged-unverified ADM-02 edge-probe classification remains unresolved. The canonical example/browser and integration gate is still assigned to plan 248-04; record any further edge discovered there rather than treating the open probe as resolved.
- No dependency, lockfile, release, workflow, route, option, runtime UI, or brand changes were made.

---
*Phase: 248-reconcile-the-base-and-safety-proof-ownership*
*Completed: 2026-11-10*

## Self-Check: PASSED

- All 23 planned source, test, and guide files exist, and all 8 task commits are ancestors of the current plan branch.
- `gsd_run check evaluation-scope --plan "248-02" --commits-only --raw` resolved this plan with 8 commits.
- The focused authorization/scope tests, full operator-surface suite, documentation contract, and formatting check passed.

## Targeted Mount Review Fixes

This follow-up applies only the two findings from the targeted mount review. It supersedes the earlier router verification for those callback shapes; it does not update phase state or claim the remaining Phase 248 work is complete.

- **CR-01 — local unary captures:** local short and unqualified named `authorize_fn` captures are lowered to generated remote callbacks on the host router. Phoenix router generation now compiles them, and the tests invoke the authorization hook read from the generated LiveView route metadata. Qualified external captures remain unchanged, and compilation is still checked not to invoke callback bodies.
- **WR-01 — guarded callback arity:** guarded callback arity counts parameter patterns inside `:when`, excluding the guard expression. Guarded unary callbacks compile; guarded multi-argument callbacks fail at the mount call with the existing actionable authorization diagnostic.
- **Commits:** `e4694ebb` (`fix(248-02): normalize local mount authorizers for Phoenix`) and `f00b2b5e` (`fix(248-02): validate guarded authorizer arity`).
- **Superseding verification:** the focused router/auth/export/theme/scope set passed 85 tests; `mix test test/threadline/operator_surface` passed 843 tests; `mix verify.format` passed. Detailed source identities and pre-fix evidence are in [248-MOUNT-FIXES.md](248-MOUNT-FIXES.md).

This targeted pass changed no public host API, route, dependency, runtime brand, or phase state. Other Phase 248 plans and requirements remain under their existing verification ownership.
