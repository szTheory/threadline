# Phase 93: Phase 88 Verification Backfill - Research

**Researched:** 2026-05-25
**Domain:** Verification backfill for denial / fallback UX truth on the current tree
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01: Use a four-band proof bar.** Phase 93 only closes when current-tree proof agrees across root behavior, public doc contract, example-host proof, and durable verification plus bookkeeping artifacts.
- **D-02: Behavior-only closure is insufficient.** LiveView and HTTP denial proof must be paired with doc/example proof and Phase 88 verification artifacts.
- **D-03: Keep proof server-authoritative.** Hidden export affordances are convenience UX only; the current tree must also prove direct HTTP denial and direct-route unsupported/denied states.
- **D-04: Public adopter guidance is part of the proof.** `guides/operator-surface.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, and `examples/threadline_phoenix/README.md` are first-class evidence for this phase.
- **D-05: Prefer named rerun surfaces.** `mix verify.doc_contract` and `mix verify.example` are part of the closure story, not optional convenience.

### Truth-first drift handling
- **D-06: Repair only local, same-pass drift inline.** If Phase 93 finds a small mismatch in tests, docs, example guidance, or verification wording, it may be repaired in the same pass only if the fix stays local and can be re-proved immediately.
- **D-07: Narrow rather than stretch.** If the current tree proves less than the original Phase 88 intent, artifacts and authority surfaces must say less instead of preserving aspirational wording.
- **D-08: Partial convergence is failure.** Do not fix tests while docs overclaim, and do not write verification artifacts that outrun current behavior.
- **D-09: Keep auth/export claims conservative.** Anything that weakens the host-owned export boundary, fallback truthfulness, or single-tree `/audit` posture should bias toward narrowing unless the repair is obviously small and fully provable.

### Authority updates when truth changes
- **D-10: Requirement-scoped authority updates are allowed only when closure is real.** If Phase 93 truly closes `AUTH-01`, `UX-01`, and `UX-02`, update `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` narrowly and exactly.
- **D-11: Verification artifacts alone are not enough if active planning surfaces still show Phase 88 open or misleadingly pending.**
- **D-12: Do not absorb Phase 94's broader reconciliation work.** Phase 93 may update requirement-scoped truth; broader milestone cleanup stays separate unless current-tree honesty would otherwise be broken.

### the agent's Discretion
- Exact command set, as long as the four-band proof bar stays intact and rerunnable.
- Exact split between Wave 1 repair work and Wave 2 artifact packaging, as long as artifact writing does not happen before the proof bands are settled.
- Exact wording in `88-VERIFICATION.md`, `88-VALIDATION.md`, and any Phase 93 summary/validation artifacts, as long as the final claim stays no broader than current-tree truth.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | Support-scoped operators are read-only by default and cannot use export endpoints unless the host explicitly opts in through `export_authorize_fn`. | The current tree already has direct HTTP denial proof in `test/threadline/operator_surface/controllers/export_controller_test.exs` and export-affordance hiding in `test/threadline/operator_surface/live/timeline_live_test.exs`; Phase 93 must confirm those remain aligned and package them into Phase 88 closure artifacts. |
| UX-01 | Support-scoped operators get least-surprise UX: export affordances hidden when unavailable, export URLs still deny server-side, and unsupported support-lane views show explicit fallback messaging. | The current tree already contains denied/unsupported shell proof in `export_status_live_test.exs`, `coverage_live_test.exs`, `policy_redaction_live_test.exs`, and `retention_history_live_test.exs`; Phase 93 must verify that these tests, docs, and example guidance all tell the same story. |
| UX-02 | Support-lane docs and example behavior stay aligned on fallback transports and "what to do instead" when a support-scoped operator hits an unavailable surface. | Doc-contract tests already lock the fallback wording across the operator guide, SaaS quickstart, integration contracts guide, and example README. Phase 93 must rerun those proofs and convert the results into durable Phase 88 verification evidence. |
</phase_requirements>

## Summary

Phase 93 is a proof-packaging phase, not a new UX-design phase. Phase 88 already shipped the descriptor-driven unsupported shell, exact-or-generic export fallback guidance, and explicit HTTP `403 forbidden` proof. The missing link is the verification chain: Phase 88 still lacks `88-VERIFICATION.md` and `88-VALIDATION.md`, and the requirement ledger still marks `AUTH-01`, `UX-01`, and `UX-02` pending. [VERIFIED: phase file inventory, requirements ledger]

The current tree appears well-positioned for a truth-first backfill. Root tests already cover hidden export affordances, direct export denial, denied export fallback UX, and unsupported coverage/policy/retention shells. Public contract tests already lock export fallback wording and host-owned callback seams. The example Phoenix host still proves the shared `/audit` tree and admin-only export posture through its own test surface and `mix verify.example`. [VERIFIED: targeted grep across tests, docs, mix aliases, and CI workflow]

The main risk is proof drift between what the tree does and what the durable authority surfaces say. Because Phase 88 has implementation summaries but not verification artifacts, the repo currently has behavior and docs without the maintainers' evidence chain needed to close the requirements honestly. The safest plan is therefore the same two-wave pattern used in Phases 90-92: first rerun and repair only local current-tree drift, then write the missing Phase 88 verification/validation artifacts and update requirement-scoped authority surfaces only if the evidence still holds. [VERIFIED: prior backfill plan pattern]

**Primary recommendation:** Plan Phase 93 in two waves:
1. Re-verify and, if needed, narrowly repair current-tree denial/fallback proof across root tests, doc-contract tests, example-host proof, and named rerun surfaces.
2. Convert that settled proof into `88-VERIFICATION.md` and `88-VALIDATION.md`, then reconcile `AUTH-01`, `UX-01`, and `UX-02` in planning authority files only if Wave 1 proved them fully on the current tree.

## Current Tree Findings

### Behavior proof already exists
- `test/threadline/operator_surface/live/timeline_live_test.exs` still proves the support-scoped timeline hides export affordances.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` contains an explicit plain-text `403 forbidden` denial assertion.
- `test/threadline/operator_surface/live/export_status_live_test.exs` covers both generic and exact denied export fallback paths.
- `test/threadline/operator_surface/live/coverage_live_test.exs`, `policy_redaction_live_test.exs`, and `retention_history_live_test.exs` lock unsupported-view fallback messaging.

### Public contract proof already exists
- `test/threadline/operator_surface_doc_contract_test.exs` locks `authorize_fn`, `export_authorize_fn`, `Unsupported View`, plain-text `403`, and named fallback transports.
- `test/threadline/getting_started_saas_doc_contract_test.exs` locks the quickstart support-lane wording, including `scope_query_fn` and plain-text `403`.
- `test/threadline/integration_contracts_doc_contract_test.exs` locks the host-owned callback seam contract and export fallback wording.
- `test/threadline/example_phoenix_readme_contract_test.exs` locks the example README against the shared `/audit` tree and admin-only export posture.

### Example-host and rerun surfaces already exist
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` still proves export denial inside the nested host app.
- `mix.exs` still exposes `mix verify.example` and `mix verify.doc_contract`.
- `.github/workflows/ci.yml` still exposes those named proof surfaces in CI.

### Missing closure surfaces
- `.planning/phases/88-denial-fallback-ux-closure/` has `88-01-SUMMARY.md` and `88-02-SUMMARY.md`, but no `88-VERIFICATION.md` or `88-VALIDATION.md`.
- `.planning/REQUIREMENTS.md` still marks `AUTH-01`, `UX-01`, and `UX-02` pending with Phase 93 as the closing phase.

## Recommended Execution Shape

### Wave 1: Re-prove current-tree truth and repair only local drift
Run the named proof surfaces first:
- targeted root tests for timeline/export denial/unsupported shells,
- `mix verify.doc_contract`,
- `mix verify.example`,
- lightweight grep checks against `mix.exs` and `.github/workflows/ci.yml`.

If these expose local, same-pass drift, repair the specific failing files immediately. Keep the scope narrow:
- behavior/test drift in the operator-surface files and tests,
- wording drift in the guides or example README,
- rerun-surface drift in `mix.exs` or `.github/workflows/ci.yml` only if actually broken.

### Wave 2: Package the proof into durable Phase 88 evidence
Once the proof bands agree, create:
- `.planning/phases/88-denial-fallback-ux-closure/88-VERIFICATION.md`
- `.planning/phases/88-denial-fallback-ux-closure/88-VALIDATION.md`

Those artifacts should:
- state the exact current-tree claim boundary for denial/fallback UX,
- map `AUTH-01`, `UX-01`, and `UX-02` to specific commands and evidence bands,
- record any caveats or narrowed claims explicitly,
- drive requirement-state updates only if the proof actually closes the requirements.

## Architecture Patterns

### Pattern 1: Treat denied export posture as a multi-surface chain
The support-lane export story spans:
- hidden timeline affordances,
- direct `/audit/exports` denial messaging,
- plain-text HTTP `403 forbidden`,
- docs that explain why export is a separate privileged capability.

Phase 93 should verify and artifact that chain together instead of treating any one assertion as sufficient.

### Pattern 2: Treat docs, tests, and example guidance as one contract chain
This milestone already treats public docs and doc-contract tests as product surfaces. Phase 93 should follow that precedent and avoid maintainers-only closure language that adopters cannot rerun or inspect.

### Pattern 3: Package proof only after truth settles
Phases 90-92 use a stable backfill pattern:
1. verify current-tree truth,
2. repair only local drift,
3. write durable verification/validation artifacts,
4. update requirement-scoped authority surfaces only if the proof really changed status.

Phase 93 should follow the same order.

## Anti-Patterns to Avoid

- **Artifact-only closure:** Writing `88-VERIFICATION.md` without rerunning the proof bands would repeat the exact verification-chain gap this phase exists to close.
- **Behavior-only closure:** Passing root tests but skipping doc/example/rerun evidence would violate the four-band proof bar from `93-CONTEXT.md`.
- **Stretching the claim:** If some denial or fallback surface now proves less than Phase 88 intended, narrow the claim in the artifacts instead of inventing new behavior inside a verification-backfill phase.
- **Broad milestone cleanup:** Do not fold unrelated Phase 94 reconciliation or general milestone hygiene into this phase unless the current tree would otherwise remain materially dishonest.

## Commands and Proof Surfaces

- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1`
- `mix verify.doc_contract`
- `mix verify.example`
- `rg -n 'verify\\.example|verify\\.doc_contract|ci\\.all' mix.exs`
- `rg -n 'run: mix verify\\.example|run: mix verify\\.doc_contract|verify-test|verify-docs' .github/workflows/ci.yml`

## Key Insight

The shortest safe path is not to reopen Phase 88 behavior. It is to prove the current tree honestly, package that proof into the missing Phase 88 evidence artifacts, and move `AUTH-01`, `UX-01`, and `UX-02` only if those proof bands stay green.
