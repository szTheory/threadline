---
phase: "240"
slug: "connected-investigation-and-recovery"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-10"
---

# Phase 240 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Host authorization to operator LiveViews | Each route and row-history read uses the host-provided repository, scope, and scope query function. URL state cannot supply or widen those values. | Tenant-scoped transaction and row-change records |
| Saved search persistence | SavedView reads and mutations are tied to the current identifiable ActorRef and use the host storage policy. | Actor identity, saved filter names and canonical supported filters |
| Authorized value to browser clipboard | Server-rendered display tokens gate copy controls; the delegated browser handler receives only the authorized value and reports actual completion. | Complete authorized identifiers and field values; no redacted/sentinel values |
| Browser URL and LiveView patch | URL parsing retains only a bounded origin, canonical supported filters, and valid as-of timestamps. | Local route state; no host scope, tenant, cursor, or arbitrary return URL |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-240-01 | Tampering | RowHistoryLive route parser | high | mitigate | Recognizes only `origin=timeline`, canonicalizes supported filters, validates ISO timestamps, and constructs encoded local paths; `row_history_live_test.exs` covers malformed/unsupported context. | closed |
| T-240-02 | Elevation of Privilege | Existing host-scoped reads | high | mitigate | Row-history component passes `scope` and `scope_query_fn` to both history and as-of reads; transaction bundle receives the same host scope. Integration tests prove current scope and denial behavior. | closed |
| T-240-03 | Information Disclosure | TransactionLive child-history boundary | high | mitigate | Child history mounts only when the parent transaction is neither unavailable nor missing; `transaction_live_test.exs` proves unavailable parent causes no child read. | closed |
| T-240-04 | Spoofing | SavedView ownership | high | mitigate | Lists only the current identifiable ActorRef's views; confirm-delete re-reads by both record ID and actor_ref. Timeline LiveView tests cover actor isolation and mutation ownership. | closed |
| T-240-05 | Tampering | FilterParams and host scope | high | mitigate | Pivots and saved-view application rebuild local routes from the canonical filter allowlist; receiving routes use normal host authorization and scope. | closed |
| T-240-06 | Information Disclosure | Shared-search URL | medium | mitigate | Share URL contains only canonical applied supported filters and states that results/access are recomputed by the receiving host; tests exclude drafts and host scope. | closed |
| T-240-07 | Information Disclosure | UI.Display and transaction copy eligibility | high | mitigate | Redacted, omitted, absent, and null tokens have no copyable full value; redacted display removes the title/full-value disclosure. UI and transaction tests assert non-copyability. | closed |
| T-240-08 | Tampering | OperatorSurface.Script clipboard status | medium | mitigate | One guarded delegated listener announces success only on resolved `writeText` or a `true` fallback result; rejected/failed writes announce manual recovery and remove the temporary textarea. Browser tests cover outcomes and patches. | closed |
| T-240-09 | Information Disclosure | Row-history transition and evidence presentation | low | mitigate | Row-history drawer and evidence timeline items explicitly suppress animation/transition; browser checks cover entry, as-of patches, and reduced motion. | closed |
| T-240-SC | Tampering | Dependency installation | high | mitigate | No dependency manifest or lockfile changed in Phase 240; no install task was executed. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above the configured `high` threshold count toward `threats_open`.*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

## Accepted Risks Log

No accepted risks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-10 | 10 | 10 | 0 | Codex inline ASVS L1 audit |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-10
