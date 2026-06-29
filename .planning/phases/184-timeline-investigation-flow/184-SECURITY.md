---
phase: 184
slug: timeline-investigation-flow
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-29
---

# Phase 184 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| URL/form filters -> Timeline LiveView | User-controlled query/form params are parsed into Timeline filters and canonical URL state. | Filter values for actor, action, table, operation, correlation, source, and time range |
| Timeline row actions -> route targets | Rendered row actions link to transactions, correlation pivots, row history, and export flows. | Audit transaction IDs, table names, scalar row IDs, and current filter query |
| Timeline -> export controller/job | Timeline exposes export affordances, but authorization and direct download behavior stay in existing export boundaries. | Current filter query, actor context, export format, and queued job metadata |
| Audit values -> browser DOM/copy controls | Audit refs, correlation IDs, row IDs, and copy labels are rendered into HEEx and `data-tl-copy` attributes. | Potentially sensitive identifiers and long refs |
| Responsive/focus/motion CSS -> operator workflow | Layout, drawer, pager, keyboard focus, and reduced-motion controls must not hide investigation actions or create denial-of-service UX failures. | Viewport-specific UI state and keyboard navigation state |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-184-01 | Information Disclosure / Elevation of Privilege | Timeline row-history and export pivots | mitigate | `safe_row_history_path/3` only renders row-history links when the table has a configured schema mapping; default no-schema mounts retain transaction-only pivots. Export links remain controller-authenticated and query-scoped. | closed |
| T-184-02 | Tampering / Denial of Service | Filter params | mitigate | Timeline uses `FilterParams` allowlists and canonical query generation; source contracts assert URL-backed submit semantics and no result-changing `phx-change`. | closed |
| T-184-03 | Information Disclosure | Export filter handoff | mitigate | Carry, queue, and direct download affordances use the current `@filter_query`; export controller/filter tests verify parity and authorization boundaries. | closed |
| T-184-04 | Tampering / XSS | Row refs, copy values, route labels | mitigate | Row refs and copy values render through HEEx, existing `UI.ref`/`Presentation` helpers, and private segment encoders rather than raw HTML interpolation. | closed |
| T-184-05 | Repudiation | Background export feedback | mitigate | Export queue behavior preserves job context and explicit success/failure flash copy while keeping direct downloads in authenticated controller routes. | closed |
| T-184-06 | Information Disclosure / Repudiation | Empty, scoped, and stale state copy | mitigate | Source contracts assert distinct empty/scoped/error/capped/stale meanings so operators do not mistake filtered or stale views for complete history. | closed |
| T-184-07 | Tampering / XSS | Long refs and copy controls | mitigate | Long visible refs wrap/truncate safely while full values stay in exact copy metadata; copy contracts and browser proof assert full-value metadata. | closed |
| T-184-08 | Denial of Service | Responsive CSS, drawer, pager, focus | mitigate | Style/source contracts and browser proof cover stable controls, focus visibility, drawer Escape/focus return, and no overflow at 320, 375, 768, 1024, and 1440 px. | closed |
| T-184-09 | Repudiation | Export unavailable/failure feedback | mitigate | Export unavailable/failure copy is explicit and preserves current row context/action stability. | closed |
| T-184-10 | Denial of Service | Motion/layout jumps | mitigate | Style contracts forbid Timeline row animation and `transition: all`; browser reduced-motion proof passes. | closed |
| T-184-SC | Tampering | Package installs | accept | No package-manager dependency or manifest change is part of Phase 184; the existing private UI primitives and existing Playwright setup are reused. | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Verification Evidence

| Evidence | Result |
|----------|--------|
| `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/pager_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/style_contract_test.exs` | 189 tests, 0 failures |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts` | 27 tests, 0 failures |
| `mix verify.example_browser_light tests/operator-timeline-investigation-flow.spec.ts` | 9 tests, 0 failures |
| `184-VERIFICATION.md` | Canonical status `passed`; broad `mix verify.test` residuals classified outside Phase 184 |
| `184-REVIEW.md` | Status `clean`; prior row-history, contract, and browser-proof findings resolved |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-184-SC | T-184-SC | Phase 184 added no dependency manifests or package-manager installs, so no new supply-chain review is required for this phase. | GSD Phase 184 plan and security audit | 2026-06-29 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-29 | 11 | 11 | 0 | Codex / GSD secure-phase hook |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-29
