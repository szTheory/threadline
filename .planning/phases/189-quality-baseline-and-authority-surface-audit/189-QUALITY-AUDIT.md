---
phase: 189
artifact: quality-audit
audited: 2026-07-01
scope: v1.39-authority-surface-baseline
requirements: [QUAL-01, QUAL-02, QUAL-03]
status: draft
source_precedence:
  - runtime/source proof
  - release/package truth
  - public docs
  - CI/gates
  - planning/residual history
---

# Phase 189 Quality Baseline and Authority-Surface Audit

This is an audit and routing artifact only: Phase 189 does not edit source code, README/guides, CI workflows, schemas, UI, screenshot baselines, release automation, or package metadata.

## Executive Summary

- Pending ranked evidence inspection. This shell defines the artifact contract and evidence inventory before final scoring.
- Scores use `0` through `4`; confidence is always separate as `High`, `Medium`, or `Low`.
- Findings route only when repo evidence affects a current adoption, production, support, release, or maintainer authority surface promised by v1.39.

## Evidence Contract

Planning artifacts define scope and residual history, but current-tree proof decides what is true. Runtime/source proof, release/package truth, public docs, CI/gates, and planning/residual history must be reconciled before a row is scored.

## Score Rubric

| Score | Meaning |
|---:|---|
| 0 | Unknown, unproven, or broken trust boundary. |
| 1 | Must-fix adoption, operations, release, or maintainer risk. |
| 2 | Workable with material residual. |
| 3 | Good enough for current claims. |
| 4 | Strong/proven. |

Confidence is named separately as `High`, `Medium`, or `Low`. Do not encode confidence in the score.

## Priority Taxonomy

| Priority | Meaning | Default route |
|---|---|---|
| Blocker | Current false public claim, red required release/branch-protection gate, broken storage/capture/query/auth correctness, security-sensitive footgun, or proof gap that makes an active requirement impossible to close honestly. | Must-fix now or phase-owned |
| Must fix before publish | Defect that would make a new Hex release, README promise, upgrade story, or v1.39 closeout misleading. | Phase-owned |
| Prove before claim | Existing proof is narrower than the tempting claim, especially screenshots, broad visual regression, assistive-technology certification, external staging, or pilot evidence. | Phase-owned, future, or external |
| External-owned | Host staging or real adopter pilot evidence requires integrator-controlled proof. | External-owned |
| Maintenance note | Hex auth-session warnings, dependency advisory output, or tool-environment notes that do not affect shipped code, package installability, or required release gates. | Maintenance note |
| Backlog cleanup | Legacy planning, Nyquist, or frontmatter residuals that do not affect active v1.39 traceability. | Backlog cleanup |
| Future seed | Real but scope-expanding risk outside v1.39, such as external pilot depth, broader screenshot hardening, richer observability, or reconnect UX beyond current proof. | Future seed |
| Good enough | Current claims are proven enough for the stated support contract. | Good enough |
| N/A | Intentionally unclaimed or out-of-category dimension. | N/A |

## Evidence Inventory

### Current Source And Tests

- `lib/threadline/storage_schema.ex`, `lib/threadline/query.ex`, `lib/threadline/capture/migration.ex`, `lib/threadline/semantics/migration.ex`, and `lib/threadline/governance/migration.ex` define current storage-schema behavior.
- `lib/threadline/capture/audit_transaction.ex`, `lib/threadline/capture/audit_change.ex`, `lib/threadline/semantics/audit_action.ex`, and `lib/threadline/governance/*.ex` expose fixed `@schema_prefix "threadline"` storage models that Phase 190 must prove or repair for custom schemas.
- `test/threadline/storage_schema_test.exs`, `test/threadline/capture/trigger_sql_storage_schema_test.exs`, and `test/threadline/storage_schema_migration_contract_test.exs` are the focused storage-schema proof surfaces.
- `mix.exs` defines named `mix verify.*` and `mix ci.*` entrypoints that should be cited instead of ad hoc proof language.

### Release, Package, And Docs

- `mix.exs`, `.release-please-manifest.json`, `release-please-config.json`, `CHANGELOG.md`, `README.md`, and `guides/adoption-pilot-backlog.md` are the release/version truth set.
- `test/threadline/adoption_pilot_doc_contract_test.exs` and `test/threadline/release_artifact_contract_test.exs` guard parts of the public release/docs contract.
- `mix hex.info threadline` is the package-truth command when current Hex evidence is cited.

### CI And Gates

- `.github/workflows/ci.yml` owns stable job ids and separate lanes for format, Credo, no-optional compile, test/example/doc contracts, Hex evaluator, browser E2E, PgBouncer topology, ExDoc, Hex tarball, and release shape.
- `.github/workflows/release.yml` is the canonical publish lane; `.github/workflows/hex-publish.yml` is the legacy tag-only fallback.
- `.github/workflows/flake-detection.yml` is opt-in/nightly and intentionally outside `mix ci.all`.
- `CONTRIBUTING.md` documents branch-protection mappings, local `mix ci.all`, host staging ownership, and release runbooks.
- `test/threadline/ci_topology_contract_test.exs` guards CI job ids, PgBouncer topology, local aliases, and host staging markers.

### Residual And UI Proof

- `.planning/milestones/v1.38-MILESTONE-AUDIT.md`, `.planning/MILESTONES.md`, and `.planning/RETROSPECTIVE.md` define known v1.38 residuals and proof-boundary lessons.
- `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` proves current SEED-005 reconnect behavior with a real socket-drop sample.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` documents local-only screenshot-regression boundaries.
- `examples/threadline_phoenix/e2e/playwright.config.ts`, `lib/threadline/operator_surface/ui.ex`, `DESIGN-SYSTEM.md`, and `.planning/design-system-ledger.json` bound operator UI and screenshot claims.

### External And Host Proof

- `CONTRIBUTING.md` classifies host staging evidence as integrator-owned attestation.
- `guides/adoption-pilot-backlog.md` carries host staging templates and real-pilot scaffolds, but in-repo demo proof is not real external adopter evidence.

### Planning History

- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/milestones/v1.38-MILESTONE-AUDIT.md`, `.planning/MILESTONES.md`, and `.planning/RETROSPECTIVE.md` define scope, invariants, owner phases, and residual history.

## Ranked Evidence Ledger

| Rank | Quality dimension | Score | Confidence | Evidence refs | Practical consequence | Highest-leverage fix | Priority | Route bucket | Owner phase |
|---:|---|---:|---|---|---|---|---|---|---|

## QUAL-03 Residuals

Pending Task 3 population.

## Good Enough / N/A Appendix

Pending Task 3 population.

## v1.39 Narrowing

Pending Task 3 population.
