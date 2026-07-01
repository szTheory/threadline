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

- Weakest current risk: configurable `storage_schema` is public-facing but not yet proven end-to-end across every Threadline-owned Ecto schema and operator/governance path.
- Next risk: public version/docs truth still mixes current `0.9.0` package reality with older `0.6.0` evaluator framing and `~> 0.6` install surfaces.
- CI/CD trust is structurally healthy but unmeasured for v1.39 efficiency: stable job ids exist, while cache/setup cost, PgBouncer image pinning, and branch-protection alignment remain Phase 192 work.
- UI-adjacent residuals are mostly proof-boundary issues, not missing product: SEED-005 reconnect is currently good enough, while screenshot stability remains local-only.
- External pilot and host staging proof stay external-owned; the repo can provide templates and modest indexes, not pretend to operate third-party staging.
- Good-enough rows are visible below so the audit narrows v1.39 instead of turning it into another broad UI/product/compliance milestone.

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
| 1 | Configurable `storage_schema` confidence beyond default `threadline` | 1 | High | `README.md`; `guides/getting-started-saas.md`; `lib/threadline/storage_schema.ex`; `lib/threadline/query.ex`; `lib/threadline/capture/audit_transaction.ex`; `lib/threadline/capture/audit_change.ex`; `lib/threadline/semantics/audit_action.ex`; `lib/threadline/governance/export_job.ex`; `test/threadline/storage_schema_test.exs`; `test/threadline/capture/trigger_sql_storage_schema_test.exs` | Adopters are told they can use another storage schema such as `audit`, but fixed Ecto prefixes and partial tests make that promise untrusted for non-default installs. | Build Phase 190 proof with `storage_schema: "audit"` across capture, query, semantics, governance, evidence, export, retention, and operator-relevant reads, then fix or narrow every failure. | Must fix before publish | Phase-owned | 190 |
| 2 | Release/version/docs authority surface | 1 | High | `mix.exs`; `.release-please-manifest.json`; `release-please-config.json`; `CHANGELOG.md`; `README.md`; `guides/evaluating-threadline.md`; `guides/adoption-pilot-backlog.md`; fresh command `mix hex.info threadline` reported latest `0.9.0` on 2026-07-01; `test/threadline/adoption_pilot_doc_contract_test.exs`; `test/threadline/release_artifact_contract_test.exs` | Evaluators see current package truth beside older 0.6-era framing, so a stranger cannot tell whether the public docs describe the current release or a legacy support lane. | Make Phase 191 reconcile README, guides, evaluator docs, adoption backlog, CHANGELOG/package metadata, Release Please wiring, and doc contracts around explicit `0.9.0` truth or deliberately justified older examples. | Must fix before publish | Phase-owned | 191 |
| 3 | CI/CD measurement and gate-trust baseline | 2 | High | `.github/workflows/ci.yml`; `.github/workflows/release.yml`; `.github/workflows/flake-detection.yml`; `mix.exs` aliases `ci.all`, `verify.release`, `verify.example_browser`, `verify.flake`; `CONTRIBUTING.md`; `test/threadline/ci_topology_contract_test.exs` | Maintainers have many gates, but v1.39 cannot honestly claim faster or more deterministic CI until critical path, repeated setup cost, cache state, PgBouncer pinning, and branch-protection mapping are measured. | Have Phase 192 record current CI timing/topology evidence first, then make low-risk cache/setup/topology changes with before/after notes. | Must fix before publish | Phase-owned | 192 |
| 4 | Closeout traceability and residual ownership | 2 | Medium | `.planning/REQUIREMENTS.md`; `.planning/STATE.md`; `.planning/ROADMAP.md`; `.planning/milestones/v1.38-MILESTONE-AUDIT.md`; `.planning/MILESTONES.md`; `.planning/RETROSPECTIVE.md` | A future closeout can look cleaner than the evidence if old Nyquist, screenshot, CI, Hex, and summary-frontmatter residuals are flattened or forgotten. | Use this ledger as Phase 193 input: verify fixed rows, preserve deferred rows, and state the next milestone recommendation without erasing proof limits. | Prove before claim | Phase-owned | 193 |
| 5 | Known CI/example-app residuals | 2 | Medium | `.planning/milestones/v1.38-MILESTONE-AUDIT.md`; `.planning/STATE.md`; `mix.exs` alias `ci.all`; `.github/workflows/ci.yml`; `.planning/RETROSPECTIVE.md` | Inherited broad-suite or example-app failures can be mistaken for current release blockers or ignored as noise; either mistake weakens maintainer trust. | Phase 192 should separate current red required gates from historical residuals and record what is required for release readiness. | Prove before claim | Phase-owned | 192 |
| 6 | Screenshot-regression confidence | 2 | Medium | `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts`; `examples/threadline_phoenix/e2e/playwright.config.ts`; `.planning/milestones/v1.38-MILESTONE-AUDIT.md`; `DESIGN-SYSTEM.md`; `.planning/design-system-ledger.json` | Operators should not hear a broad visual-stability claim when the screenshot guard is local-only, skipped in CI, and previously classified non-green. | Keep screenshot stability as a proof-boundary row unless a future UI-regression phase fixes the local runner/bootstrap and narrows the claim to that runner. | Prove before claim | Future seed | future |
| 7 | Host staging ownership | 2 | High | `CONTRIBUTING.md`; `test/threadline/ci_topology_contract_test.exs`; `guides/adoption-pilot-backlog.md`; `.planning/STATE.md` | Threadline can publish templates and review small indexes, but maintainers cannot claim third-party staging topology was operated or verified by this repo. | Keep host staging as integrator-owned evidence; update in-repo templates only when named host evidence exists. | External-owned | External-owned | external |
| 8 | External pilot boundaries | 2 | High | `.planning/REQUIREMENTS.md`; `.planning/PROJECT.md`; `.planning/STATE.md`; `guides/adoption-pilot-backlog.md`; `.planning/RETROSPECTIVE.md` | A synthetic or demo-only pilot claim would mislead adopters about real-world validation. | Leave real pilot proof signal-gated and require named adopter or integrator evidence before promoting it. | External-owned | External-owned | external |
| 9 | Hex and dependency maintenance notes | 3 | Medium | `.planning/milestones/v1.38-MILESTONE-AUDIT.md`; `.planning/STATE.md`; `mix.exs`; `mix.lock`; fresh command `mix hex.info threadline` reported latest `0.9.0` on 2026-07-01 | Expired auth-session or advisory notes matter for maintenance, but the current audit found no repo evidence that package installability or required release gates are broken by them. | Refresh Hex auth and dependency-advisory posture during release maintenance without making Phase 189 install packages or change deps. | Maintenance note | Maintenance note | none |
| 10 | SEED-005/reconnect operator behavior | 3 | High | `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts`; `lib/threadline/operator_surface/ui.ex`; `DESIGN-SYSTEM.md`; `.planning/design-system-ledger.json` | Current source and a real socket-drop browser spec show the reconnect banner and mutating-control dimming exist, so calling this missing would create fake UI scope. | Preserve the current evidence; reopen only if real socket-drop proof fails, mutating affordances become unsafe, or operators report trust-impacting behavior. | Good enough | Good enough | none |
| 11 | Optional Phoenix and private operator-surface boundary | 4 | High | `mix.exs` optional deps; `.github/workflows/ci.yml` job `verify-compile-no-optional`; `test/threadline/ci_topology_contract_test.exs`; `README.md`; `DESIGN-SYSTEM.md`; `.planning/MILESTONES.md` | Capture-only adopters are protected from root UI bloat, and maintainers have explicit proof that no public component API is promised. | Keep optional dependency and private-component contracts under existing source/doc tests; do not route new work from Phase 189. | Good enough | Good enough | none |
| 12 | Compliance platform, public component API, WAL/CDC, and runtime destructive redaction expansion | 4 | High | `.planning/REQUIREMENTS.md`; `.planning/PROJECT.md`; `README.md`; `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-CONTEXT.md`; `.planning/milestones/v1.38-MILESTONE-AUDIT.md` | These are intentionally unclaimed dimensions; treating them as missing would expand v1.39 beyond the milestone contract. | Keep them out of v1.39 unless a future milestone is explicitly opened from real adopter or procurement pressure. | N/A | N/A | none |

## QUAL-03 Residuals

Pending Task 3 population.

## Good Enough / N/A Appendix

Pending Task 3 population.

## v1.39 Narrowing

Pending Task 3 population.
