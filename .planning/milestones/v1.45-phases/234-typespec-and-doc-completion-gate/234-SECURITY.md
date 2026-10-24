---
phase: "234"
slug: "typespec-and-doc-completion-gate"
status: verified
threats_open: 0
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
| Example encryption source → Hex advisory acknowledgement | A package finding may be acknowledged only while the vulnerable primitive is unreachable in the reference app. | Vault cipher configuration, encrypted fields, legacy ciphertext, and audit metadata |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-234-01 | Tampering | Doc/spec coverage sentinel | high | mitigate | Plan 12 retains the D-55-approved >=82 visible function/macro floor, module and facade timeline checks, Docs-chunk guard, and unchanged D-07 hidden pin; Plan 13 independently counted 82 visible entries and 52 moduledocs. | closed — 234-12-SUMMARY.md; 234-13-SUMMARY.md; 234-D46-REVIEW.md |
| T-234-02 | Repudiation | Ratchet pins | medium | mitigate | Exact-set pins and zero-gap gates; ratchet machinery retired in Plan 06. | closed |
| T-234-03 | Information disclosure | Public facade options | high | mitigate | Closed per-function allowlists exclude internal scope labels; contract tests cover facade functions. | closed |
| T-234-04 | Denial of service | Actor LiveView after API closure | medium | mitigate | Call sites use the supported query API and scoped LiveView tests pass. | closed |
| T-234-05 | Tampering | Transaction lookup validation | low | mitigate | Fetch repository before resolving IDs; tests cover malformed IDs with missing repository. | closed |
| T-234-06 | Information disclosure | Captured-data documentation | medium | mitigate | The fresh D-46 WR-04 PASS and source spot-check confirm the D-38 note on required facade reads/exports and current ChangeDiff and Export entries: values are captured as written, trigger-time redaction is distinct from read-time access control, and callers authorize reads with :scope_query_fn. | closed — 234-D46-REVIEW.md WR-04; lib/threadline.ex; lib/threadline/change_diff.ex; lib/threadline/export.ex |
| T-234-SC (Plan 01) | Tampering | Package installation, Plan 01 | low | accept | Plan 01 records no package installation or changes. | closed — accepted |
| T-234-07 | Repudiation | Hidden Proof helpers | low | mitigate | Keep helpers callable, document the change in CHANGELOG, and include the breaking-change footer. | closed |
| T-234-08 | Tampering | Evidence attrs types | low | mitigate | Rechecked against lib/threadline/evidence.ex and test/threadline/evidence_test.exs; Plan 15's evidence contract test passed. The broad caller map remains a low-severity contract area because accepted attrs are changeset-validated. Keep open below the blocking threshold pending a separately scoped narrowing decision. | open — below high threshold |
| T-234-SC (Plan 02) | Tampering | Package installation, Plan 02 | low | accept | Plan 02 records no package installation or lockfile changes. | closed — accepted |
| T-234-09 | Information disclosure | Export scope options | high | mitigate | Closed allowlists reject caller-supplied internal labels; operators use hidden ExportReads. | closed |
| T-234-10 | Tampering | SQL identifier validation | medium | mitigate | Validate identifiers before quoting and document the closed table-name set. | closed |
| T-234-11 | Denial of service | Export and timeline call sites | medium | mitigate | Move callers with the API closure and rerun controller/LiveView coverage. | closed |
| T-234-SC (Plan 03) | Tampering | Package installation, Plan 03 | low | accept | Plan 03 records no package installation. | closed — accepted |
| T-234-12 | Tampering | Capture and semantics struct types | medium | mitigate | Hand-write field types and verify with Dialyzer; keep the layer boundary explicit. | closed |
| T-234-13 | Tampering | Capture-to-semantics type dependency | low | mitigate | Rechecked lib/threadline/capture/audit_transaction.ex and test/threadline/capture_semantics_boundary_test.exs: hydrated actions remain generic at the capture boundary and Plan 15's layer-boundary test passed. Keep open below the blocking threshold for continued boundary surveillance. | open — below high threshold |
| T-234-SC (Plan 04) | Tampering | Package installation, Plan 04 | low | accept | Plan 04 records no package installation. | closed — accepted |
| T-234-SC (Plan 05) | Tampering | Package installation, Plan 05 | low | accept | Plan 05 records no package installation. | closed — accepted |
| T-234-14 | Tampering | Dialyzer ignore bypasses | high | mitigate | Exact five-flag contract, empty ignore file, no @dialyzer attributes, and no :no_* flags. | closed |
| T-234-15 | Repudiation | Self-review of documentation quality | medium | mitigate | A fresh agent reviewed the complete generated surface against the frozen rubric; report records its findings. | closed |
| T-234-16 | Denial of service | Cold PLT rebuild | low | accept | Plan 06 accepts one bounded cold PLT rebuild of about nine minutes. | closed — accepted |
| T-234-SC (Plan 06) | Tampering | Package installation, Plan 06 | low | accept | Plan 06 records no package installation. | closed — accepted |
| T-234-22 | Tampering | Coverage vacuity floor, Plan 12 | high | mitigate | Plan 12 preserves the D-55 >=82 D-03 visible function/macro assertion, corrected failure message, module/facade timeline/Docs-chunk checks, and D-07 hidden pins; Plan 13 measured 82 entries and 52 moduledocs in the fresh inventory. | closed — 234-12-SUMMARY.md; 234-13-SUMMARY.md; 234-D46-REVIEW.md |
| T-234-23 | Tampering | RepositoryBoundary and Critic.Measure raise helpers, Plan 12 | medium | mitigate | Plan 12 records both task_error!/3 helpers private with truthful private no_return() specs and all four exact caller messages; Plan 15's compiled probe found neither helper exported nor any public bang no_return spec, strict Dialyzer reported zero errors, and the focused test passed 31 tests. | closed — 234-12-SUMMARY.md; Plan 15 D-28 probe; test/threadline/operator_surface/critic_trust_test.exs; mix verify.dialyzer |
| T-234-24 | Repudiation | Independent D-46 review, Plan 13 | high | mitigate | The fresh independent PASS is tied to the regenerated input SHA-256, counts all required surfaces, records WR-01 through WR-07, and passes the full Plan 13 report-integrity verifier. | closed — 234-13-SUMMARY.md; 234-D46-REVIEW.md |
| T-234-25 | Repudiation | Error, page, telemetry, and investigation module summaries, Plan 14 | low | mitigate | All five current moduledocs passed frozen M-1/M-2 review; the report explicitly covers IncidentChange and LinkedTransaction. | closed — 234-14-SUMMARY.md; 234-D46-REVIEW.md WR-07 |
| T-234-26 | Repudiation | Security and SPEC-02 sign-off, Plan 15 | high | mitigate | After Plan 19, Plan 15 reran the reachability and accountable-ignore contracts (19/19), `mix verify.deps_audit` (all three lockfiles clean), and a fresh canonical `mix ci.all` (root tests 3006/0; example tests 130/0; strict Dialyzer 0 errors; live Dialyzer slice 17/0; npm audit 0 vulnerabilities; Playwright 318 passed, 26 intentionally skipped). The current independent D-46 report has exactly one PASS and passes Plan 13's full input/report integrity verifier. Plan 15's focused coverage/evidence/layer tests (73/0), D-28 compiled-spec probe, four-path caller-message test (31/0), and strict Dialyzer (0 errors) also pass; SPEC-02 is now evidence-gated for completion. | closed — 234-15-SUMMARY.md; 234-19-SUMMARY.md; 234-D46-REVIEW.md; mix ci.all; Plan 15 focused gates |
| T-234-27 | Tampering | ActorRef, Subject, and Retention map contracts, Plan 16 | medium | mitigate | Existing ActorRef/Subject/Retention compatibility tests passed in the 73-test focused evidence suite; fresh independent WR-02 review accepted D-56's three narrow alias exceptions. | closed — 234-16-SUMMARY.md; 234-D46-REVIEW.md WR-02 |
| T-234-28 | Repudiation | Audit.transaction/3 return summary, Plan 16 | medium | mitigate | Audit.transaction/3 documents the success/error tuple and conditional audit-ID merge/wrap in its opening paragraph; the fresh independent WR-05 source review passed and strict docs build passed in Plan 13. | closed — 234-16-SUMMARY.md; 234-D46-REVIEW.md WR-05 |
| T-234-29 | Tampering | Subject and Retention public type contracts, Plan 17 | medium | mitigate | 234-17-SUMMARY.md records `mix test test/threadline/evidence/subject_test.exs`, `mix test test/threadline/retention/policy_test.exs`, `mix compile --warnings-as-errors`, `mix verify.dialyzer`, and `MIX_ENV=dev mix docs --warnings-as-errors`; 234-D46-REVIEW.md WR-02 PASS reviewed the current types and behavior. | closed — 234-17-SUMMARY.md; 234-D46-REVIEW.md WR-02 |
| T-234-30 | Repudiation | StorageSchema.role/0 public type documentation, Plan 18 | medium | mitigate | 234-18-SUMMARY.md records the one-`@typedoc` source change in `lib/threadline/storage_schema.ex`, the unchanged five-role `Threadline.StorageSchema.role/0` union, compiled-doc visibility for all five roles, `mix compile --warnings-as-errors`, `MIX_ENV=dev mix docs --warnings-as-errors`, and `mix verify.dialyzer`; 234-D46-REVIEW.md WR-02/S-4(e) PASS names the same type and source. | closed — 234-18-SUMMARY.md; lib/threadline/storage_schema.ex; 234-D46-REVIEW.md WR-02 |
| T-234-31 | Tampering | `cloak 1.1.4` AES-CTR ciphertext authentication, EEF-CVE-2026-95105 | high | mitigate | Plan 234-19 `cloak_advisory_reachability_contract_test.exs` parses the live vault and proves exactly one `Cloak.Ciphers.AES.GCM` default with tag `AES.GCM.V1`; `git show b50e51e4:examples/threadline_phoenix/lib/threadline_phoenix/vault.ex` proves GCM was present at the tracked initial revision, and the Plan 19 history scan found no tracked CTR tag/reader path. The exact EEF-CVE-2026-95105 entry has separate rationale, reachability, and review-by metadata; the accountable-ignore and reachability contracts pass 19/19, and `mix verify.deps_audit` is clean across all three lockfiles. | closed — 234-19-SUMMARY.md; live reachability contract; tracked initial-vault/history proof; canonical dependency audit |
| T-234-32 | Tampering | `cloak_ecto 1.3.0` PBKDF2 iteration count, EEF-CVE-2026-94206 | medium | mitigate | Plan 234-19 `cloak_advisory_reachability_contract_test.exs` parses the live field and proves `Cloak.Ecto.Binary` uses `ThreadlinePhoenix.Vault`, while scanning example lib/config/priv sources for `Cloak.Ecto.PBKDF2`. The exact EEF-CVE-2026-94206 entry has separate rationale, reachability, and review-by metadata; the accountable-ignore and reachability contracts pass 19/19, and `mix verify.deps_audit` is clean across all three lockfiles. | closed — 234-19-SUMMARY.md; live reachability contract; canonical dependency audit |
| T-234-33 | Denial of service | Mobile reduced-motion E2E case | low | mitigate | Plan 21 closes `#stress-toast` through its visible control, observes both the toast and modal hidden, then requires an ordinary Show Drawer click; focused mobile Playwright and canonical CI pass. | closed — 234-21-SUMMARY.md; operator-motion.spec.ts; focused mobile gate; mix ci.all |

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
| 2026-10-06 | 31 | 28 | 3 | Plan 15 evidence reconciliation; final mix ci.all gate failed |
| 2026-10-06 | 33 | 28 | 5 | D-58 added separate high CTR and medium PBKDF2 findings before Plan 19 execution |
| 2026-10-06 | 33 | 30 | 3 | Plan 19 live reachability contracts and canonical dependency audit passed |
| 2026-10-06 | 33 | 31 | 2 | Plan 15 fresh full CI and evidence-gated sign-off; two below-threshold low findings remain open |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed; only T-234-08 and T-234-13 remain open, both below the high-threat threshold
- [x] `status: verified` set in frontmatter

**Approval:** Verified — Plan 20/21 passed the final full CI and evidence gates; T-234-26 and T-234-33 are closed, and SPEC-02 is Complete.

## Security Audit 2026-10-06

| Metric | Count |
|---|---|
| Threats found | 34 |
| Closed | 32 |
| Open | 2 |
