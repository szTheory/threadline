---
phase: "234"
slug: "typespec-and-doc-completion-gate"
status: draft
threats_open: 4
asvs_level: 1
created: "2026-10-05"
---

# Phase 234 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Later executors → gate pin files | Executors must not weaken ratchets instead of fixing code. | Gate configuration and pinned findings |
| Compiled BEAM metadata → checker | The checker must fail closed when docs metadata is missing. | Docs and typespec chunks |
| Adopter code → public facade options | Caller options must not relabel internal scope bindings. | Keyword keys and scope context |
| Operator surface → hidden Query API | Internal callers supply the correct scope surface. | Surface labels and query parameters |
| Adopter code → Evidence writers | Caller fields are validated and persisted as append-only evidence. | Evidence attributes and snapshots |
| Adopter upgrade → hidden Proof helpers | Hidden helpers remain callable but are no longer documented API. | Evidence records and proof values |
| Adopter code → Export options | Caller options cannot inject internal scope labels. | Export filters, options, and scope |
| SQL-native adopters → StorageSchema | Table identifiers must be validated before reaching SQL text. | Schema and table identifiers |
| Published types → adopter Dialyzer | Field types must truthfully describe values adopters consume. | Typespec metadata |
| Capture layer → semantics layer | Capture types must not depend on application-level semantics. | Hydrated action structs |
| Executor → Dialyzer configuration | Strict findings must not be suppressed through alternate ignore mechanisms. | Warning flags and ignore files |
| Executor → documentation review | An independent reviewer must assess the frozen rubric input. | Public docs, specs, and types |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-234-01 | Tampering | Doc/spec coverage sentinel | high | mitigate | Keep the D-55-approved >=82 visible function/macro entry floor and correct its failure message; preserve module, facade-entry, Docs-chunk, and D-07 hidden-pin checks. | open |
| T-234-02 | Repudiation | Ratchet pins | medium | mitigate | Exact-set pins and zero-gap gates; ratchet machinery retired in Plan 06. | closed |
| T-234-03 | Information disclosure | Public facade options | high | mitigate | Closed per-function allowlists exclude internal scope labels; contract tests cover facade functions. | closed |
| T-234-04 | Denial of service | Actor LiveView after API closure | medium | mitigate | Call sites use the supported query API and scoped LiveView tests pass. | closed |
| T-234-05 | Tampering | Transaction lookup validation | low | mitigate | Fetch repository before resolving IDs; tests cover malformed IDs with missing repository. | closed |
| T-234-06 | Information disclosure | Captured-data documentation | medium | mitigate | State captured column values and the caller's scope authorization seam consistently; D-46 review found remaining omissions. | open — below high threshold |
| T-234-SC (Plan 01) | Tampering | Package installation, Plan 01 | low | accept | Plan 01 records no package installation or changes. | closed — accepted |
| T-234-07 | Repudiation | Hidden Proof helpers | low | mitigate | Keep helpers callable, document the change in CHANGELOG, and include the breaking-change footer. | closed |
| T-234-08 | Tampering | Evidence attrs types | low | mitigate | Restrict public attrs types to keys actually accepted by the record changeset. | open — below high threshold |
| T-234-SC (Plan 02) | Tampering | Package installation, Plan 02 | low | accept | Plan 02 records no package installation or lockfile changes. | closed — accepted |
| T-234-09 | Information disclosure | Export scope options | high | mitigate | Closed allowlists reject caller-supplied internal labels; operators use hidden ExportReads. | closed |
| T-234-10 | Tampering | SQL identifier validation | medium | mitigate | Validate identifiers before quoting and document the closed table-name set. | closed |
| T-234-11 | Denial of service | Export and timeline call sites | medium | mitigate | Move callers with the API closure and rerun controller/LiveView coverage. | closed |
| T-234-SC (Plan 03) | Tampering | Package installation, Plan 03 | low | accept | Plan 03 records no package installation. | closed — accepted |
| T-234-12 | Tampering | Capture and semantics struct types | medium | mitigate | Hand-write field types and verify with Dialyzer; keep the layer boundary explicit. | closed |
| T-234-13 | Tampering | Capture-to-semantics type dependency | low | mitigate | Keep AuditTransaction's hydrated action type generic so capture does not depend on semantics. | open — below high threshold |
| T-234-SC (Plan 04) | Tampering | Package installation, Plan 04 | low | accept | Plan 04 records no package installation. | closed — accepted |
| T-234-SC (Plan 05) | Tampering | Package installation, Plan 05 | low | accept | Plan 05 records no package installation. | closed — accepted |
| T-234-14 | Tampering | Dialyzer ignore bypasses | high | mitigate | Exact five-flag contract, empty ignore file, no @dialyzer attributes, and no :no_* flags. | closed |
| T-234-15 | Repudiation | Self-review of documentation quality | medium | mitigate | A fresh agent reviewed the complete generated surface against the frozen rubric; report records its findings. | closed |
| T-234-16 | Denial of service | Cold PLT rebuild | low | accept | Plan 06 accepts one bounded cold PLT rebuild of about nine minutes. | closed — accepted |
| T-234-SC (Plan 06) | Tampering | Package installation, Plan 06 | low | accept | Plan 06 records no package installation. | closed — accepted |
| T-234-22 | Tampering | Coverage vacuity floor, Plan 12 | high | mitigate | Retain the D-55 >=82 D-03 visible function/macro assertion, align its failure message, and prove the module, facade timeline, Docs-chunk, and D-07 hidden-pin checks with Plan 12's focused gate and measured inventory. | open |
| T-234-23 | Tampering | RepositoryBoundary and Critic.Measure raise helpers, Plan 12 | medium | mitigate | Make both task_error!/3 helpers private with truthful private no_return() specs; assert neither is exported, preserve exact messages for all four Mix task failure paths, and require the focused integration test, compiled metadata probe, and strict Dialyzer evidence from Plan 12. | open — below high threshold |
| T-234-24 | Repudiation | Independent D-46 review, Plan 13 | high | mitigate | Require a fresh independent reviewer, a dated report tied to the regenerated input hash, complete positive surface inventory, WR-01 through WR-07 evidence, and the validated PASS-only handoff; a valid FAIL blocks Plan 15. | open |
| T-234-25 | Repudiation | Error, page, telemetry, and investigation module summaries, Plan 14 | low | mitigate | Apply frozen M-1/M-2 criteria and require the independent D-46 reviewer to inspect all five current moduledocs, including IncidentChange and LinkedTransaction. | open — below high threshold |
| T-234-26 | Repudiation | Security and SPEC-02 sign-off, Plan 15 | high | mitigate | Revalidate the current D-46 PASS, strict Dialyzer, D-28 compiled-spec probe, D-55 coverage gate, and source-backed closure of every open high threat before setting threats_open: 0 or status: verified. | open |

*Status: open · closed · open — below high threshold (non-blocking) · closed — accepted*
*Only open threats at or above workflow.security_block_on count toward threats_open.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-234-01 | T-234-SC (Plan 01) | No package installation or changes in Plan 01. | Approved Plan 234-01 disposition | 2026-10-05 |
| AR-234-02 | T-234-SC (Plan 02) | No package installation or lockfile changes in Plan 02. | Approved Plan 234-02 disposition | 2026-10-05 |
| AR-234-03 | T-234-SC (Plan 03) | No package installation in Plan 03. | Approved Plan 234-03 disposition | 2026-10-05 |
| AR-234-04 | T-234-SC (Plan 04) | No package installation in Plan 04. | Approved Plan 234-04 disposition | 2026-10-05 |
| AR-234-05 | T-234-SC (Plan 05) | No package installation in Plan 05. | Approved Plan 234-05 disposition | 2026-10-05 |
| AR-234-06 | T-234-16 | One bounded cold PLT rebuild is expected after the dependency metadata change. | Approved Plan 234-06 disposition | 2026-10-05 |
| AR-234-07 | T-234-SC (Plan 06) | No package installation in Plan 06. | Approved Plan 234-06 disposition | 2026-10-05 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-05 | 22 | 18 | 4 | gsd-security-auditor; independent D-46 reviewer |
| 2026-10-05 | 27 | 18 | 9 | planning reconciliation of active Plans 12–15 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [ ] `threats_open: 0` confirmed
- [ ] `status: verified` set in frontmatter

**Approval:** pending
