---
phase: "235"
slug: "stability-contract-and-adopter-guides"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
---

# Phase 235 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host configuration to generated migration to PostgreSQL | Configured redaction column names are checked against the selected relation before trigger DDL. | Table and column identifiers; captured values |
| Captured data to adopter documentation | Redaction claims must match the exercised generated trigger paths and identify residual plaintext copies. | Audit values and compatibility guidance |
| Installed database to compatibility claim | Public storage guarantees must match live PostgreSQL catalog facts. | Audit table names, columns, types, nullability, and indexes |
| Library source to public SQL name | Adopters rely on the actor GUC and generated trigger/function names. | GUC keys and SQL identifiers |
| Library output to host integration | Exports, health findings, task flags, and router routes affect downstream consumers. | Export fields, finding codes, flags, options, and paths |
| Ecto schema to adopter compatibility promise | The documented field subset and captured JSONB shapes affect 1.x callers. | Struct fields and captured-data shape |
| Phase execution to package supply chain | Phase work could add dependencies or change locked package versions. | Dependency declarations and lockfiles |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-235-01 | Information disclosure | Generated redaction migration | high | mitigate | Generated migrations check configured `mask:` and `exclude:` names against live catalog columns before trigger DDL; PostgreSQL tests cover missing names, rollback, and a valid capture control. | closed — migration-time regression tests; `mix ci.all` |
| T-235-02 | Information disclosure | Redaction guide | medium | mitigate | Claim-level docs tests link each behavior to its evidence and identify residual plaintext, rollout timing, and untested paths. | closed — redaction guide contract; guide graph contract |
| T-235-03 | Repudiation | Stability guide | medium | mitigate | Compatibility statements and public operator boundaries have named assertions and a removed-claim mutation control. | closed — stability guide and guide graph contracts |
| T-235-04 | Denial of service | Supported-table guide | medium | mitigate | The shape matrix names primary-key/index prerequisites and unsupported relation kinds, with code-backed assertions. | closed — table-shapes and guide graph contracts |
| T-235-05 | Tampering | Audit storage contract | high | mitigate | Live PostgreSQL catalog checks pin required audit tables, columns, types, nullability, and indexes with named set differences. | closed — storage catalog contract; `mix ci.all` |
| T-235-06 | Spoofing | Actor GUC and trigger/function names | medium | mitigate | Literal runtime-generated SQL, parsed `query!/2` calls, AST naming-call counts, and rename mutation controls protect the public names. | closed — public SQL contract; focused tests; `mix ci.all` |
| T-235-07 | Repudiation | Export fields and health findings | medium | mitigate | Literal contracts compare public export modes and finding codes with their source-producing paths. | closed — export public contract; `mix ci.all` |
| T-235-08 | Denial of service | Mix tasks and operator router | medium | mitigate | Contracts enumerate task flags, router options, and documented routes, including empty flag sets. | closed — public options contract; `mix ci.all` |
| T-235-09 | Tampering | Stable schema fields | medium | mitigate | Literal documented field subsets are checked against Ecto schema metadata with field-removal and additive-field controls. | closed — schema-fields and documentation contracts; `mix ci.all` |
| T-235-10 | Repudiation | Captured JSONB compatibility claim | medium | mitigate | Documentation contracts state additive keys and shapes without promising serialization bytes or key ordering. | closed — schema-fields contract and warning-free docs build |
| T-235-SC-01 | Tampering | Package installation, Plan 01 | high | mitigate | No project dependency or lockfile change was introduced; the canonical browser check used the existing locked dependency set. | closed — `mix ci.all`; repository lockfiles unchanged |
| T-235-SC-02 | Tampering | Package installation, Plan 02 | high | mitigate | No project dependency or lockfile change was introduced; the canonical browser check used the existing locked dependency set. | closed — `mix ci.all`; repository lockfiles unchanged |
| T-235-SC-03 | Tampering | Package installation, Plan 03 | high | mitigate | No project dependency or lockfile change was introduced; the canonical browser check used the existing locked dependency set. | closed — `mix ci.all`; repository lockfiles unchanged |
| T-235-SC-04 | Tampering | Package installation, Plan 04 | high | mitigate | No project dependency or lockfile change was introduced; the canonical browser check used the existing locked dependency set. | closed — `mix ci.all`; repository lockfiles unchanged |
| T-235-SC-05 | Tampering | Package installation, Plan 05 | high | mitigate | No project dependency or lockfile change was introduced; the canonical browser check used the existing locked dependency set. | closed — `mix ci.all`; repository lockfiles unchanged |

*Status: open · closed · open — below high threshold (non-blocking) · closed — accepted*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward `threats_open`.*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-07 | 15 | 15 | 0 | Orchestrator — ASVS L1 evidence reconciliation |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** Security verification is complete under ASVS level 1. All 15 plan threats are closed, with no blocking threats open.

## Security Audit 2026-10-07

| Metric | Count |
|---|---|
| Threats found | 15 |
| Closed | 15 |
| Open | 0 |
