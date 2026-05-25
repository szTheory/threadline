# Phase 90: Phase 85 Verification Backfill - Research

**Researched:** 2026-05-25
**Domain:** Current-tree proof, verification backfill, and requirement closure for the Phase 85 support-lane claim boundary
**Confidence:** HIGH for the existing proof surfaces and missing-artifact gap; MEDIUM for milestone bookkeeping because `ROADMAP.md` and `STATE.md` still carry known drift from Phase 89 follow-up

## Summary

Phase 90 is a verification-backfill phase, not a new support-lane feature phase.
The current tree already contains the key claim-boundary truth Phase 85 was
supposed to lock:

- the support lane is one shared `/audit` mount with host-owned seams,
- `authorize_fn`, `scope_query_fn`, and `export_authorize_fn` remain the core
  integration surface,
- support-scoped row history / as-of is not currently claimed as first-party
  proof,
- no Threadline-owned role DSL, tenancy DSL, or separate `/support` product
  tree was introduced.

What is missing is the closure chain. The v1.21 audit explicitly says `SCOPE-03`,
`AUTH-02`, and `ADOPT-03` remain unsatisfied because Phase 85 only produced
context and summary artifacts. There is no `85-VERIFICATION.md`, no
`85-VALIDATION.md`, and the active milestone surfaces still leave those
requirements pending.

**Primary recommendation:** keep Phase 90 narrow. Re-verify the current tree as
it exists today, tighten only literal truth surfaces if a small mismatch is
found, write `85-VERIFICATION.md` and `85-VALIDATION.md` from that current-tree
proof, then reconcile the milestone bookkeeping for exactly `SCOPE-03`,
`AUTH-02`, and `ADOPT-03`.

## Audit-Driven Gap Definition

The milestone audit already localizes the Phase 90 problem:

- `SCOPE-03` is unsatisfied because Phase 85 has claim-lock context only and no
  phase verification artifact.
- `AUTH-02` is unsatisfied because the callback contract is described in
  context/docs only and was never phase-verified.
- `ADOPT-03` is unsatisfied because the minimal-controls posture is spread
  across Phase 85 and Phase 87 outputs but was never closed with a verification
  artifact.

This means Phase 90 should not redesign the lane. It should turn existing truth
into auditable evidence.

## Current-Tree Findings

### Verified claim-boundary truth

- `guides/upgrade-path.md` already narrows the root `phoenix-surface` claim and
  says support-scoped row history / as-of remains `unclaimed`.
- `guides/operator-surface.md` already treats row history / as-of as a product
  surface while explicitly stopping short of a first-party support-lane claim
  for that path.
- `guides/getting-started-saas.md` already teaches one shared `/audit` mount
  with host-owned `authorize_fn`, `scope_query_fn`, and `export_authorize_fn`,
  and already warns that support-lane row-history/as-of wording is narrower on
  the current tree.
- `guides/integration-contracts.md` already frames `authorize_fn`,
  `scope_query_fn`, and `export_authorize_fn` as the supported composition seams
  without introducing any Threadline-owned auth or tenancy DSL.
- `examples/threadline_phoenix/README.md` already stays a narrower
  `sigra-reference` proof path instead of broader product authority.

### Verified callback-contract truth

- `test/threadline/operator_surface/auth_test.exs` proves the shared
  `%{assigns: assigns}` callback shape works on the LiveView face, including
  support scopes and telemetry outcomes for granted, denied, and error cases.
- `test/threadline/operator_surface/export_auth_plug_test.exs` proves the same
  callback shape works on the HTTP export face through the synthetic
  `%{assigns: conn.assigns}` mirror when `export_authorize_fn` is absent, and
  also proves `export_authorize_fn` is the explicit override when a host wants a
  narrower or broader export posture.
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`
  is the underlying example-host proof surface, but the honest runnable entrypoint
  from the repo root is `mix verify.example`. That command proves the example
  app still uses one shared `/audit` mount, keeps support users scoped on the
  claimed read surface, and denies exports by default.

### Verified minimal-controls truth

- The out-of-scope section in `.planning/REQUIREMENTS.md` explicitly rejects a
  Threadline-owned RBAC DSL, tenancy DSL, separate `/support` tree, and default
  support export access.
- The root docs and example router keep the control surface minimal and additive:
  one `authorize_fn`, optional `scope_query_fn`, optional
  `export_authorize_fn`, and optional specialized gates such as
  `coverage_authorize_fn` / `policy_authorize_fn`.
- No current-tree public contract surface introduces a new role system or policy
  engine to satisfy the support-lane story.

## Verified Risks

### Risk 1: Reopening the row-history claim by accident

Phase 89 deliberately narrowed the public support-lane claim around row history
/ as-of. Phase 90 should preserve that truth when writing `85-VERIFICATION.md`.
If the verification artifact restates the original Phase 85 intent without the
Phase 89 narrowing, it will recreate the same contradiction the audit already
flagged.

### Risk 2: Confusing Phase 85 closure with later phase closure

Phase 90 only closes the claim-boundary and callback/minimal-controls
requirements. It must not mark `SCOPE-01`, `SCOPE-02`, `ADOPT-01`, `ADOPT-02`,
`AUTH-01`, `UX-01`, `UX-02`, `DOC-01`, or `DOC-02` complete here.

### Risk 3: Mutating milestone authority too broadly

`ROADMAP.md` and `STATE.md` still carry known drift from the Phase 89
follow-up. Phase 90 may repair the specific bookkeeping needed to mark
Phase 90 and its mapped requirements honestly, but it should not pretend the
entire milestone is closed or silently resolve later-phase verification debt.

## Planning Recommendations

### Plan 90-01: Re-verify the current Phase 85 truth and write the phase verdict

Use the current tree as the authority. Re-run the doc-contract, auth-contract,
and example-host proof paths. If any literal wording drift remains in the named
Phase 85 proof surfaces, make the smallest truthful repair. Then write
`85-VERIFICATION.md` with explicit sections for:

- support-lane claim boundary,
- shared callback contract across LiveView and HTTP export,
- minimal additive controls and example proof,
- requirement closure for `SCOPE-03`, `AUTH-02`, and `ADOPT-03`.

### Plan 90-02: Add Nyquist and bookkeeping closure

Create `85-VALIDATION.md` in the modern Nyquist shape using the commands from
Plan 90-01. Then update `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`,
and `.planning/STATE.md` so the active milestone surface records exactly what
Phase 90 closed and what remains pending.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit doc-contract tests, operator auth/export contract tests, focused root support-surface behavior tests, example-host proof via Mix alias, and planning-artifact grep checks |
| Quick run | `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs --max-failures 1` |
| Phase gate | `MIX_ENV=test mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 1` then `mix verify.example` |

### Requirement Map

| Requirement | Truth to prove | Expected evidence |
|-------------|----------------|-------------------|
| SCOPE-03 | The support-lane claim names only the currently proven `/audit` surfaces and explicitly excludes the rest. | `85-VERIFICATION.md`, doc-contract tests, and current guide wording |
| AUTH-02 | One shared `%{assigns: assigns}` authorization callback remains the canonical contract across LiveView and HTTP export, with stable telemetry outcomes. | `85-VERIFICATION.md`, `auth_test.exs`, `export_auth_plug_test.exs` |
| ADOPT-03 | The milestone kept controls minimal and additive instead of introducing a Threadline-owned role or tenancy system. | `85-VERIFICATION.md`, requirements out-of-scope section, integration docs, example proof |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/v1.21-MILESTONE-AUDIT.md`
- `.planning/phases/85-support-lane-surface-audit/85-CONTEXT.md`
- `.planning/phases/85-support-lane-surface-audit/85-RECOMMENDATION.md`
- `.planning/phases/85-support-lane-surface-audit/85-01-PLAN.md`
- `.planning/phases/85-support-lane-surface-audit/85-02-PLAN.md`
- `.planning/phases/85-support-lane-surface-audit/85-01-SUMMARY.md`
- `.planning/phases/85-support-lane-surface-audit/85-02-SUMMARY.md`
- `.planning/phases/89-contract-lock-final-verification/89-RESEARCH.md`
- `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md`
- `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md`
- `guides/upgrade-path.md`
- `guides/operator-surface.md`
- `guides/getting-started-saas.md`
- `guides/integration-contracts.md`
- `examples/threadline_phoenix/README.md`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`
- `test/threadline/upgrade_path_doc_contract_test.exs`
- `test/threadline/operator_surface_doc_contract_test.exs`
- `test/threadline/getting_started_saas_doc_contract_test.exs`
- `test/threadline/integration_contracts_doc_contract_test.exs`
- `test/threadline/example_phoenix_readme_contract_test.exs`
- `test/threadline/operator_surface/auth_test.exs`
- `test/threadline/operator_surface/export_auth_plug_test.exs`

## RESEARCH COMPLETE
