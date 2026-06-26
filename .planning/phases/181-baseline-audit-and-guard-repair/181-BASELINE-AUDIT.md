---
phase: 181-baseline-audit-and-guard-repair
date: 2026-06-26
status: baseline-packet
requirements: [BASE-01, BASE-03]
evidence_tiers:
  tier_a: source/CI contracts for route, auth, feature-gate, stress, ledger, and fixture truth
  tier_b: rendered CI slices for overflow, navigation, header, and selected responsive cells
  tier_c: local screenshot packet under .planning/phases/181-baseline-audit-and-guard-repair/screenshots
source_decisions: [D-181-01, D-181-02, D-181-03, D-181-07, D-181-08, D-181-09, D-181-10, D-181-11, D-181-12, D-181-13, D-181-14, D-181-15, D-181-16]
---

# Phase 181 Baseline Audit Packet

This packet records current rendered truth for the mounted `/audit` operator surface before v1.38 page polish starts. It is a planning artifact, not a redesign brief: findings are classified for later phases and guard repair, while page hierarchy, route paths, feature gates, public component APIs, capture/query/auth semantics, root dependencies, and design-system ratchets remain unchanged.

## Evidence Contract

- **D-181-01:** Phase 181 evidence is an audit packet, not a screenshot dump.
- **D-181-02:** The packet feeds `181-SCREENSHOT-INVENTORY.md`, `181-GUARD-REPAIR.md`, and `181-VERIFICATION.md`.
- **D-181-03:** Every finding uses one of the shared issue taxonomy buckets below.
- **D-181-07:** Evidence is tiered: source/CI contracts, rendered CI slices, and local screenshot packet proof.
- **D-181-08:** The existing bounded screenshot CI allowlist stays bounded unless a later phase records an owned rebaseline.

## Issue Taxonomy

| Bucket | Meaning | Default Owner |
|---|---|---|
| JTBD/IA drift | The page exists and renders, but task order, hierarchy, or destination framing needs page-polish work. | 183-186 |
| stale selector or copy contract | Tests or docs may pin old copy, selector shape, or removed contracts rather than current rendered behavior. | 181-03, 181-04 |
| screenshot or ledger drift | Screenshot inventory, stress ledger, projection, or allowlist evidence may not match current rendered truth. | 181-06, 181-07, 181-08 |
| accessibility/focus/motion proof gap | Existing proof is incomplete for focus, keyboard, APG, reduced motion, or rendered viewport behavior. | 181-05, 187 |
| route/auth/feature-gate invariant gap | Route, auth, export, policy, evidence, coverage, stress, or optional-dependency boundaries need source proof. | 181-05 |
| later-phase polish follow-up | Finding is real but intentionally deferred because fixing it would be page IA, copy, layout, or visual polish. | 183-187 |

## Compact Operator Context Contract

Per **D-181-09**, later v1.38 plans should consume this compact contract instead of reopening broad research.

| Contract | Current Truth |
|---|---|
| Personas (**D-181-10**) | Incident/support operator; audit-readiness/security/platform operator; governance/export operator; adopting developer/maintainer. |
| Core JTBD (**D-181-11**) | Find what happened; verify capture readiness; inspect evidence/governance safely; export/share current evidence; maintain the UI without public component or dependency leakage. |
| Canonical nouns (**D-181-12**) | Audit Action, Audit Transaction, Audit Change, Actor, Subject, Request, Job, Correlation, Coverage, Evidence, Redaction, Retention, Export, Saved View, Timeline Entry, Diff, Snapshot. |
| Canonical verbs (**D-181-13**) | filter, scan, open, copy, compare, refresh, remediate, queue export, download, confirm destructive action, return. |
| Design pillars (**D-181-14**) | Task-led orientation; semantic-first raw-on-demand detail; dense but scannable data; explicit trust state; accessible native-first interaction; composed Threadline brand across dark/light/system; purposeful motion and performance; Phoenix/LiveView-native maintainer DX. |
| Backend-detail rule (**D-181-15**) | Hide backend implementation details unless needed for remediation, proof, or performance constraints; expose technical anchors as secondary raw detail, copyable refs, commands, or docs links. |
| Brand/theming truth (**D-181-16**) | `brandbook/brand-book.md` is authoritative. Operator UI is dark-primary, with shipped light/system lanes via server-resolved `data-tl-theme` and cookie-backed runtime picker; no localStorage, JS theming, or decorative consumer-app effects. |

## Page/JTBD Matrix

| Surface | Route or selector source | Primary JTBD | Current render proof expected from screenshot task | Issue taxonomy bucket | Guard disposition | Later-phase owner |
|---|---|---|---|---|---|---|
| Shell/global nav | `SurfaceHeader.surface_header/1`; `data-testid="operator-header"` and `data-testid="operator-nav-shell"`; nav links `operator-nav-overview`, `operator-nav-timeline`, `operator-nav-coverage`, `operator-nav-evidence`, `operator-nav-policy`, `operator-nav-retention`, `operator-nav-exports` | Know where I am, what destinations exist, and what is currently active. | All Tier C page screenshots include the shell; Tier B responsive slices cover 375/768/1024 Shell/Home/Timeline/Coverage and Phase 178 320/1440 route sweep. | JTBD/IA drift; accessibility/focus/motion proof gap; route/auth/feature-gate invariant gap | Preserve nav route/test-id contract; audit current active-state, feature-gated visibility, skip link, mobile `details` disclosure, and theme picker proof before Phase 183. | 183 |
| Home `/audit` | `live("/", StartLive, :index)`; screenshot name `home`; `operator-nav-overview` | Pick the right operator job without reading an info dump. | `home__default__1280.png`, `home__default__375.png`, and `home__light__1280.png` from `operator-screenshots.spec.ts`; rendered-slice checks include Shell/Home at 375/768/1024. | JTBD/IA drift; screenshot or ledger drift; later-phase polish follow-up | Preserve route and launcher destinations; classify task hierarchy, nav orientation, and screenshot freshness for Phase 183 instead of rewriting copy/layout now. | 183 |
| Timeline | `live("/timeline", TimelineLive, :index)`; screenshot names `timeline`, `timeline-dense`, `timeline-empty`; `data-testid="timeline-row"` | Filter, scan, open transaction/row history, and export current view. | `timeline__default__1280.png`, `timeline__default__375.png`, `timeline__light__1280.png`, plus dense and empty state default outputs; Tier B responsive checks include Timeline at 375/768/1024 and Phase 178 320/1440 route sweep. | JTBD/IA drift; stale selector or copy contract; accessibility/focus/motion proof gap; later-phase polish follow-up | Preserve filter URL semantics, row actions, saved-view/export paths, and current selectors; classify toolbar/filter hierarchy and mobile density for Phase 184. | 184 |
| Coverage | `live("/coverage", CoverageLive, :index)`; screenshot name `coverage`; `data-testid="coverage-table"` | Answer whether one schema is audit-ready and what to fix next. | `coverage__default__1280.png`, `coverage__default__375.png`, and `coverage__light__1280.png`; Tier B responsive checks include Coverage at 375/768/1024 and Phase 178 320/1440 route sweep. | JTBD/IA drift; route/auth/feature-gate invariant gap; later-phase polish follow-up | Preserve coverage auth gate and schema URL state; record repeated readiness/CTA risks for Phase 185 instead of editing page hierarchy in Plan 01. | 185 |
| Transaction detail | `live("/transactions/:id", TransactionLive, :show)`; screenshot name `transaction`; `data-testid="transaction-change-row"` | Explain one transaction and its changed rows. | `transaction__default__1280.png` and `transaction__default__375.png` from the clicked Timeline transaction path. | JTBD/IA drift; stale selector or copy contract; accessibility/focus/motion proof gap; later-phase polish follow-up | Preserve transaction route, deep-link, ref-copy, and row-history affordances; classify detail-header and dense diff readability for Phase 186. | 186 |
| Row history | `live("/rows/:table/:record_id", RowHistoryLive, :show)` and `live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)`; screenshot name `row-history`; `data-testid="row-history-drawer"` | Reconstruct one row's history/as-of context. | `row-history__default__1280.png` and `row-history__default__375.png` from the transaction drawer path; Phase 178 rendered slices cover 320/1440 route sweep. | JTBD/IA drift; accessibility/focus/motion proof gap; stale selector or copy contract; later-phase polish follow-up | Preserve drawer and standalone route semantics, redacted-value proof, focus behavior, and transaction backlink contract; defer drawer/page polish to Phase 186. | 186 |
| Actor detail | `live("/actors/:kind/:id", ActorLive, :show)`; screenshot name `actor`; seeded actor `user/33123cc4-da21-5674-b030-e168cee90521` | Understand what one actor did and where to go next. | `actor__default__1280.png` and `actor__default__375.png`; rendered proof includes the 30d pressed state and transactions-list/empty-state branch. | JTBD/IA drift; stale selector or copy contract; later-phase polish follow-up | Preserve actor-kind/id route and scoped-query behavior; classify actor window controls, empty state, and onward links for Phase 186. | 186 |
| Evidence | `live("/evidence", EvidenceLive, :index)`; screenshot name `evidence`; `data-testid="evidence-table"` | Inspect proof records without implying broader compliance theater. | `evidence__default__1280.png` and `evidence__default__375.png`; denied support-state evidence remains local/test output, not a durable Tier C name. | JTBD/IA drift; route/auth/feature-gate invariant gap; stale selector or copy contract; later-phase polish follow-up | Preserve evidence fail-closed gate and proof vocabulary; classify metadata density and unavailable state for Phase 186. | 186 |
| Exports | `live("/exports", ExportStatusLive, :index)` plus controller downloads under `/audit/exports`; screenshot name `exports` | Prepare or retrieve current-view handoff artifacts safely. | `exports__default__1280.png` and `exports__default__375.png`; screenshot spec requires Completed, Failed, and Queued statuses. | JTBD/IA drift; route/auth/feature-gate invariant gap; accessibility/focus/motion proof gap; later-phase polish follow-up | Preserve export controller auth, status labels, download links, and current-view export contract; defer workflow hierarchy to Phase 186. | 186 |
| Redaction | `live("/policy/redaction", PolicyRedactionLive, :index)`; screenshot name `redaction`; `data-testid="policy-section"` | Understand redaction posture without offering unscoped destructive runtime redaction. | `redaction__default__1280.png` and `redaction__default__375.png`; rendered proof includes `Redaction policy` heading. | JTBD/IA drift; route/auth/feature-gate invariant gap; later-phase polish follow-up | Preserve policy gate and no-runtime-redaction boundary; classify posture copy and remediation hierarchy for Phase 186. | 186 |
| Retention | `live("/policy/retention", RetentionHistoryLive, :index)`; screenshot name `retention`; heading `Retention window` | Review retention/prune consequences with type-to-confirm safety. | `retention__default__1280.png` and `retention__default__375.png`; accessibility specs continue to sample retention prune modal proof. | JTBD/IA drift; route/auth/feature-gate invariant gap; accessibility/focus/motion proof gap; later-phase polish follow-up | Preserve retention auth re-check, type-to-confirm, reconnect-safe disabled state, audit-the-action, and focus restoration; defer page polish to Phase 186/187. | 186 |
| Stress route `/audit/__stress` | Example-app stress route; `operator-stress.spec.ts`; `.planning/design-system-ledger.json`; `DESIGN-SYSTEM.md` | Maintainer-only component/page/fixture ratchet evidence. | Tier B/CI stress screenshot allowlist stays bounded to existing happy/error/permission/boundary cells; Plan 07 inventories freshness without promoting a full matrix. | screenshot or ledger drift; stale selector or copy contract; route/auth/feature-gate invariant gap | Preserve authenticated maintainer-only stress boundary, ledger/projection ratchet, screenshot allowlist, and no-production-story exposure; repair drift in Plans 06-08 only with owner evidence. | 181, 182, 187 |

## Later-Phase Ownership

| Owner | Surfaces | Current Plan 01 Disposition |
|---|---|---|
| 183 | Shell/global nav, Home `/audit` | Audit route/render evidence and record IA risks; no hierarchy, CTA, or copy rewrite. |
| 184 | Timeline | Audit dense/empty/default evidence and stale selector risk; no workflow redesign. |
| 185 | Coverage | Audit readiness hierarchy and schema state proof; no duplicate-CTA cleanup yet. |
| 186 | Transaction detail, Row history, Actor detail, Evidence, Exports, Redaction, Retention | Audit detail/governance/export evidence and proof gaps; no page-level refactor. |
| 187 | Accessibility, motion, docs, adversarial closeout | Consume proof gaps from this packet and close with final verification. |

## Baseline Guard Notes

- `operator-screenshots.spec.ts` is the Tier C durable local packet source for `actor`, `coverage`, `evidence`, `exports`, `home`, `redaction`, `retention`, `row-history`, `timeline`, `timeline-dense`, `timeline-empty`, and `transaction`.
- The light lane uses the `desktop-chromium-light` project and should only be treated as durable local evidence for Shell/Home, Timeline, and Coverage in this plan.
- Existing screenshot CI baselines remain ledger-owned; Plan 01 records their relationship to the local packet but does not rebaseline or expand the allowlist.
- BASE-01 is satisfied at Plan 01 scope when every `/audit` page has a packet path and inventory disposition.
- BASE-03 is satisfied at Plan 01 scope when this packet links the v1.38 personas, JTBD, PhoenixStorybook/stress distinction, nav IA, accessibility, motion, and brand/theming decisions.
