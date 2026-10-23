---
phase: "243"
slug: "integrated-verification-and-review-preview"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-11"
---

# Phase 243 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Pull request workflow to required CI | Branch code runs in the read-only pull-request lane; privileged workflows do not execute fork artifacts. | Source, test reports, bounded job results |
| Playwright reporter to CI artifact | Reporter output is untrusted; only validated allowlisted journey status and identity fields leave runner temp storage. | Expected/discovered/executed identities and pass status |
| Checkout and receipts to evidence runner | Paths, receipts, fixtures, and candidate bytes are validated before browser or database setup and before process signals. | Candidate and fixture hashes, process and database identity |
| Browser evidence to review artifacts | Captures and manifests contain synthetic seeded data; raw bundles remain local and ignored. | Screenshots, manifests, source and asset hashes |
| Evidence index to release recommendation | Exact candidate, required jobs, receipt, preview, captures, and finding dispositions must reconcile. | Safe paths, hashes, run identity, finding status |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-243-01 | Tampering / Repudiation | Expected/discovered/executed journey reconciliation | high | mitigate | Exact project, file, and title identity rejects missing, duplicate, skipped, failed, malformed, or retry-only required cases; 31/31 identities passed in exact-SHA CI run 38158769462. | closed |
| T-243-02 | Information disclosure | CI receipt and diagnostics | high | mitigate | CI uploads the bounded allowlisted success receipt only; the receipt contains no reporter attachments, cookies, storage state, credentials, or raw traces. Artifact and receipt digests are recorded in `243-CI-RECEIPT.json`. | closed |
| T-243-03 | Elevation of privilege | Pull request workflow execution | high | mitigate | Workflow contract tests preserve the read-only pull-request lane, stable required job IDs, and required-job topology; no `pull_request_target` or privileged artifact execution was introduced. | closed |
| T-243-04 | Tampering / Repudiation | Candidate identity and visual baseline | high | mitigate | Candidate receipts bind material working-tree inputs and the accepted baseline; candidate-review and manifest contracts reject stale bytes. The recorded Phase 238 baseline digest remained unchanged. | closed |
| T-243-05 | Denial of service / Tampering | Evidence process and database | high | mitigate | Preflight verifies checkout, loopback listener, owned process, derived database, and partition before setup or stop; focused preflight checks passed 7/7 and preview lifecycle checks passed 5/5. | closed |
| T-243-06 | Information disclosure | Screenshot and manifest output | high | mitigate | Synthetic fixtures and allowlisted metadata bound durable evidence; raw capture bundles remain local/ignored and were not included in the CI artifact. Candidate and receipt contracts passed. | closed |
| T-243-07 | Spoofing / Tampering | Preview process, port, checkout, and database identity | high | mitigate | Preview receipt checks reconcile live cwd, loopback listener, PostgreSQL database, candidate receipt, and asset hashes before reuse or stop; lifecycle checks passed 5/5. | closed |
| T-243-08 | Elevation of privilege | Host authentication and deep links | high | mitigate | Preview route probes exercise unauthenticated redirect and authenticated access through the real Phoenix host authorization pipeline; exact-SHA browser CI passed. | closed |
| T-243-09 | Information disclosure | Preview receipt and browser context | high | mitigate | Receipt schema retains only bounded candidate, fixture, route, process, database, and asset identities; cookies, storage state, credentials, and customer data are excluded. | closed |
| T-243-10 | Repudiation / Tampering | Visual comparison and findings | high | mitigate | Findings link matched source/output hashes and conditions; the final 34-shell candidate bundle and review ledger validate against the recorded manifests. | closed |
| T-243-11 | Information disclosure | Captures and review prose | high | mitigate | Captures use synthetic seeded data; raw bundles stay local/ignored and the compact review ledger stores hashes and bounded findings. | closed |
| T-243-12 | Spoofing | Policy and operation status copy | medium | mitigate | Mounted policy and evidence LiveView tests passed 14/14 each and preserve distinct host scope, unreadable/missing states, and refresh semantics. | closed |
| T-243-13 | Tampering / Repudiation | Candidate freeze and evidence freshness | high | mitigate | Candidate, fixture, source, route-manifest, output, asset, and baseline hashes were recomputed and reconciled at `2f7560e97778d914a7639cbae308bb66fb7c528f`; remote branch points to the same SHA. | closed |
| T-243-14 | Denial of service | Preview lifecycle | high | mitigate | Before signaling or reopen, the receipt verifies the owned process, cwd, exclusive loopback listener, database mapping, and unchanged candidate state; the preview remains available on its isolated synthetic database. | closed |
| T-243-15 | Information disclosure | Raw capture and preview data | high | mitigate | Synthetic fixture and local ignored evidence constrain data; the workflow artifact contains only the validated receipt, not successful raw browser traces. | closed |
| T-243-16 | Spoofing / Repudiation | Required CI run identity | high | mitigate | Run 38158769462 is bound to the exact pushed candidate SHA, branch, workflow, required job IDs, and successful statuses; all 16 jobs succeeded. | closed |
| T-243-17 | Tampering | Downloaded receipt and evidence index | high | mitigate | The downloaded receipt was schema-validated and reconciled to run/SHA plus expected, discovered, and executed inventory; 31/31 identities passed once with no retry or skip. | closed |
| T-243-18 | Information disclosure | CI artifact and final evidence index | high | mitigate | Only the synthetic allowlisted browser receipt and compact paths/hashes were retained; the indexed archive and receipt digests identify the accepted evidence. | closed |
| T-243-19 | Elevation of privilege | Fork pull request artifact handling | high | mitigate | Fork-controlled artifacts are treated as data and validated; the workflow does not execute downloaded code in a privileged job or introduce a privileged fork trigger. | closed |
| T-243-SC | Tampering | Package installation | high | mitigate | No package or dependency was added by Phase 243; all six summaries record an empty `tech-stack.added` list. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above the configured high threshold count toward `threats_open`.*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-11 | 20 | 20 | 0 | Codex — ASVS L1 mitigation-presence check |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** ASVS L1 mitigation-presence check complete; exact-SHA required CI and browser receipt passed.

## Security Audit 2026-10-11

| Metric | Count |
|---|---|
| Threats found | 20 |
| Closed | 20 |
| Open | 0 |
