---
phase: "231"
slug: "facade-topology-and-the-capture-semantics-edge"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
---

# Phase 231 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Adopter code to `Threadline.Query` preload option | Adopter-supplied preload terms are validated before reaching `repo.preload/3`. | Preload terms and linked action data |
| Exploration reads to the configured storage schema | Hydration queries must use the caller-selected storage schema prefix. | Audit action identifiers and records |
| Repository docs to published HexDocs | Public guides and generated docs must describe supported facade APIs. | API names and usage examples |
| Contributor edits to adopter-facing examples | The facade-only scanner guards examples against hidden-module calls. | Example source and audit queries |
| Phase execution to package supply chain | The phase must not silently add or change dependencies. | Dependency declarations and lockfiles |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-231-01 | Information disclosure | `Query.hydrate_actions/3` | medium | mitigate | Hydration carries the caller's storage options into one batched query; storage-schema integration coverage verifies the selected prefix. | closed — action hydration tests and verification evidence |
| T-231-02 | Denial of service / Information disclosure | Deprecated preload shim | medium | mitigate | Preload values are split and validated before `repo.preload/3`; nested action preloads fail with `ArgumentError`. | closed — action hydration tests and verification evidence |
| T-231-03 | Tampering | `action_id`, foreign key, migrations, trigger SQL | high | mitigate | The explicit identifier and virtual action field remain; schema tests pin the association boundary and the phase diff gate protects migrations and trigger SQL. | closed — schema boundary tests and phase diff evidence |
| T-231-04 | Denial of service | Hydration `IN` list | low | accept | IDs are deduplicated and bounded by the caller's already-bounded result set, matching the cardinality of the former Ecto preload. | closed — accepted |
| T-231-05 | Tampering | `mix.exs` docs skip lists | medium | mitigate | The exact skip-list values are pinned by the public-surface contract test. | closed — public-surface contract test |
| T-231-06 | Information disclosure | Hidden module `@doc` text | low | accept | Hidden module docs remain in source and IEx; they do not create a public HexDocs page. | closed — accepted |
| T-231-07 | Repudiation / Tampering | Facade-only documentation scanner | medium | mitigate | The scanner has non-empty scope checks, an exact `timeline_query/1` allowlist, and recorded mutation controls. | closed — scanner contract and mutation-control evidence |
| T-231-08 | Tampering | Example replay script | low | accept | The example changes only to the equivalent facade read and runs against the example app's own test database. | closed — accepted |
| T-231-SC | Tampering | Package installation across all three plans | low | accept | No dependency or lockfile changes were introduced; example verification uses the existing locked dependencies. | closed — accepted |

*Status: open · closed · open — below high threshold (non-blocking) · closed — accepted*
*Severity: critical > high > medium > low — only open threats at or above the configured block threshold count toward `threats_open`.*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-231-01 | T-231-04 | Hydration list size follows the already-bounded caller result set and does not exceed the former preload cardinality. | Plan 231-01 recorded disposition | 2026-10-03 |
| AR-231-02 | T-231-06 | Hidden module documentation remains available in source and IEx but is not published as supported HexDocs API. | Plan 231-02 recorded disposition | 2026-10-03 |
| AR-231-03 | T-231-08 | The example script uses the equivalent facade call and the example app's isolated test database. | Plan 231-03 recorded disposition | 2026-10-03 |
| AR-231-04 | T-231-SC | No package was added; locked dependencies remain the supply-chain boundary for example verification. | Plans 231-01, 231-02, and 231-03 recorded disposition | 2026-10-03 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-07 | 9 | 9 | 0 | Orchestrator — ASVS L1 evidence reconciliation |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** Security verification is complete under ASVS level 1. All nine unique plan threats are closed, with accepted risks recorded and no blocking threats open.
