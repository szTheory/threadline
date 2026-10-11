---
phase: "242"
slug: "export-and-retention-operations"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-10"
---

# Phase 242 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Timeline / LiveView → ExportJob | Server derives the actor and persists only validated export context. | ActorRef, supported filters, queue state |
| Browser → ExportController → storage | A requested job ID is re-authorized against current owner, state, expiry, and storage availability. | Job ID, actor identity, artifact path |
| Browser confirmation → RetentionHistoryLive | The server rechecks host authorization and typed confirmation before recording and triggering a destructive action. | Confirmation text, host privilege, AuditAction |
| Pruner → PostgreSQL audit schema | Accepted runs, deletion progress, and terminal outcomes cross an asynchronous database boundary. | RetentionRun state and committed deletion counts |
| Browser transport → LiveView mutation controls | Disconnected or in-flight client controls remain disabled until fresh server-rendered state arrives. | Transport state, operation state, mutation revision |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-242-01 | Spoofing / Information disclosure | ExportJob and ExportController.download/2 | high | mitigate | Actor-owned job reads and request-time ownership, status, expiry, and storage checks in `export_status_live.ex` and `controllers/export_controller.ex`; wrong-actor and expired/missing-object cases are covered by controller tests. | closed |
| T-242-02 | Elevation of privilege | RetentionHistoryLive.prune_now | high | mitigate | `authorize_prune/1`, canonical policy token, `Plug.Crypto.secure_compare/2`, and AuditAction recording precede `Pruner.trigger/0` in `retention_history_live.ex`; forged confirmation and denied authorization tests assert no prune. | closed |
| T-242-03 | Tampering / Repudiation | Pruner.trigger/0 and RetentionRun | high | mitigate | `pruner.ex` persists queued acceptance and coalesces active runs under advisory locking; `retention.ex` updates the accepted run through terminal state. Trigger, coalescing, and lock tests cover the lifecycle. | closed |
| T-242-04 | Information disclosure / Repudiation | Retention failure tracking | high | mitigate | `retention.ex` persists safe failure categories and cumulative committed deletion counts; partial-batch and failure tests reject raw exception disclosure and false zero counts. | closed |
| T-242-05 | Tampering / Repudiation | Offline and in-flight mutation binding | high | mitigate | Native mutation controls are disabled through real socket loss and submission; server guards remain authoritative and reconnect does not replay mutations. Route-state browser assertions cover pointer, Enter, Space, stable counts, and deliberate retry after recovery. | closed |
| T-242-06 | Information disclosure | Reconnect status and job/run reads | medium | mitigate | Reconnect refreshes persisted actor-owned export jobs and current retention runs before mutation controls unlock; status rendering distinguishes transport loss from operation failure. LiveView and browser tests cover refresh and recovery. | closed |
| T-242-SC | Tampering | Package installs | high | mitigate | No install task or package addition occurred; all three phase summaries record `tech-stack.added: []`. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above the configured high threshold count toward `threats_open`.*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-10 | 7 | 7 | 0 | Codex — ASVS L1 mitigation-presence check |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-10

## Security Audit 2026-10-11

| Metric | Count |
|---|---|
| Threats found | 7 |
| Closed | 7 |
| Open | 0 |
