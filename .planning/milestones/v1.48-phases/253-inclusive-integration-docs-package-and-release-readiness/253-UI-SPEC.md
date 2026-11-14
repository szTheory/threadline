---
phase: "253"
slug: "inclusive-integration-docs-package-and-release-readiness"
status: approved
shadcn_initialized: false
preset: none
created: "2026-11-13"
---

# Phase 253 — UI Design Contract

> Inclusive-use and visual-evidence contract for the existing Threadline Admin. The approved brand, Phase 251 job contracts, Phase 252 Operations UI, and the current mounted LiveViews remain the source of truth. This phase validates complete existing jobs and corrects only attributable defects.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — repository-owned Phoenix LiveView/HEEx components and scoped CSS tokens |
| Preset | Not applicable; shadcn is not used |
| Component library | Custom `Phoenix.Component` modules; no third-party UI component library |
| Icon library | `Threadline.OperatorSurface.Components.Icon` (inline SVG) |
| Font | Locally served Threadline Familjen Grotesk, Geist, and IBM Plex Mono WOFF2 aliases; preserve host opt-out and system fallbacks |

Keep Phoenix LiveView/HEEx and the existing example/dev/test PhoenixStorybook boundary. Continue using `.threadline-ui` and the approved `brand/` sources. Use the existing paired logos and favicon; shipped assets and licenses already align, so change them only for a demonstrated mismatch. Dark remains the default; preserve the immediate, native CSRF-protected Dark/Light/System theme flow. Do not add React, Fablebook, an adapter, registry, dependency, public UI API, or a second route/story/journey inventory. PhoenixStorybook stories are static composition evidence only.

## Component Inventory

Enumerated by `rg --files lib/threadline/operator_surface/components lib/threadline/operator_surface/ui | wc -l` — 10 components — `threadline@1.1.0` — 2026-11-13.

Cross-check: `find lib/threadline/operator_surface/components lib/threadline/operator_surface/ui -type f -name '*.ex' | wc -l` — 10 source files. No mismatch.

This is a non-exhaustive inventory of repository-owned modules, not a closed allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Icon | `Threadline.OperatorSurface.Components.Icon` | Semantic inline icons for links, copy controls, and state feedback; pair with visible text for operation/status meaning. |
| Logo | `Threadline.OperatorSurface.Components.Logo` | Supplied compile-time light/dark lockup; preserve geometry and minimum size. |
| SurfaceHeader | `Threadline.OperatorSurface.Components.SurfaceHeader` | Existing shell, route navigation, and immediate theme selection. |
| UnsupportedView | `Threadline.OperatorSurface.Components.UnsupportedView` | Safe fallback for unsupported or unavailable feature routes. |
| Actions | `Threadline.OperatorSurface.UI.Actions` | Existing action links and controls; keep visible, specific labels. |
| Data | `Threadline.OperatorSurface.UI.Data` | Existing table, loading, empty, stale, and unavailable states. |
| Display | `Threadline.OperatorSurface.UI.Display` | Exact values, timestamps, identifiers, and copy controls. |
| Form | `Threadline.OperatorSurface.UI.Form` | Existing filters, schema controls, and correction states. |
| Overlay | `Threadline.OperatorSurface.UI.Overlay` | Existing modal, drawer, toast, and focus behavior. |
| Page | `Threadline.OperatorSurface.UI.Page` | Existing page shell, page/detail headers, pagination, and layout. |

Route owners outside these directories remain the existing LiveViews and components. Use `RetentionHistoryLive.Components` for Retention run and preview rendering and `ExportStatusLive.Components` for Export job history. Do not duplicate their production markup or invent a generic page engine.

## Spacing Scale

Keep the approved 8-point rhythm in 4px increments. Preserve existing dense-control geometry; do not introduce spacing tokens for this phase.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps and tight inline alignment. |
| sm | 8px | Compact controls and row-internal spacing. |
| md | 16px | Standard control padding and panel content. |
| lg | 24px | Related content groups. |
| xl | 32px | Page sections. |
| 2xl | 48px | Major page breaks. |
| 3xl | 64px | Outer page-level separation. |

Exceptions: retain existing 12px, 20px, and 40px values in dense tables and controls. Text controls remain 40px high. Icon-only touch targets have a 44px minimum hit area without enlarging the visible glyph. Keep existing spacing aliases in UI CSS; do not add spacing aliases to `brand/brand.json`.

## Typography

Use only the two interface weights: 400 regular and 600 semibold. This contract uses four sizes: 12px, 13px, 16px, and 28px. Display type is for covers and social cards, not Admin screens.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body and control text — Geist | 16px | 400 | 1.55 |
| Dense metadata — Geist | 13px | 400 | 1.4 |
| IDs, table/field names, and code — IBM Plex Mono | 13px | 400 | 1.5 |
| Labels and column labels — Geist | 12px | 600 | 1.2; uppercase and 0.12em tracking only at this size |
| Page/section headline — Familjen Grotesk | 28px | 600 | 1.2; sentence case |

The approved brand assigns Familjen Grotesk 600 at 28px to page titles and section heads. The retained Phase 252 capture records the current `/audit/policy/retention` page title at 28px in computed Geist. Correct only the page-title style owner (`.tl-page__title`) to use the existing heading-family token, then verify its computed family and served font asset. Do not apply a blanket `h1`/`h2` rule or churn every heading. The 16px, 600-weight `Retention preview` card title is a compact dense-interface label, not the 28px brand headline role; keep it in Geist. Keep timestamps and counts tabular, IDs complete for assistive technology and copy, and visible ID shortening middle-elided without wrapping. Preserve the host font opt-out and system fallbacks.

## Color

Use the approved 60/30/10 role hierarchy. The labels are role proportions; keep the actual approved dark/light shares and tokens rather than forcing exact pixel percentages or expanding the palette.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (about 60%) | Dark: Threadline Black `#0B1020` (62%). Light: Paper `#F7F9FC` (64%). | Page ground; dark remains default. |
| Secondary (about 30%) | Dark: Graphite `#141B2D` (24%) with Fog `#D7DEEA` reading text (8%). Light: Card White `#FFFFFF` (22%) with Ink `#0F1728` reading text (8%). | Rows, cards, panels, and primary reading layer. |
| Accent (about 10% maximum) | Dark: Thread Blue `#4F8CFF`. Light: Thread Blue Deep `#1557C0`. | Links, visible focus, selection, and the existing primary-action edge only; accent may occupy less than 10%. |
| Dividers | Dark: Slate Line `#23304A`. Light: Hairline `#C9D3E2`. | Group and row separation; never text or the sole control boundary. |
| Destructive | Dark: `#FF8585`. Light: `#A33434`. | The final irreversible Retention prune action only. |

Accent reserved for: brand links, visible 2px focus rings, selected state, and the primary-action edge. Signal Cyan marks correlation identifiers; Iris is for code keywords and a selected saved view, never a status. Stitch Blue `#4781E6` is logo-thread artwork only. Insert, Update, Delete, and Redacted remain visible words whose semantic colors reinforce, never replace, their meaning. In forced colors, use system colors and preserve focus plus visible words/shapes; do not depend on exact brand hues.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | `Preview retention` (read-only). After a ready preview, offer `Review and confirm`. The final modal action alone is `Prune now`. |
| Retention empty state | Heading: `No retention runs`. Body: `A run will appear here after a confirmed prune or scheduled retention operation.` |
| Retention history error | `Retention history could not be loaded. The saved runs are unchanged. Refresh to check their current status.` Keep the visible `Refresh retention history` action. |
| Retention preview error | `Retention preview is unavailable. No counts are shown and a prune cannot be started from this view. Refresh the history and try the preview again; if it keeps failing, contact your administrator.` Keep the error adjacent to the preview and expose it as an alert. |
| Destructive confirmation | Title: `Prune retained audit data?` Explain the global configured-store scope, that current operator/tenant scope does not limit it, that preview counts are sequential estimates and not stored for the run, and that the action cannot be undone. Require the exact policy name. Actions: `Keep audit data` and `Prune now`. |

Show a ready preview as estimates with distinct `Estimated AuditChange candidates` and `Estimated empty AuditTransaction candidates` labels, the exact UTC generation time, the worker-store scope, and the existing sequential-estimate caveat. A successful zero count remains `0`; do not turn disabled cleanup or missing data into zero. Keep failure, queued, running, completed, and partially recorded outcomes distinct. Do not promise adopter comprehension or use `tamper-proof`, `immutable`, `compliant`, `certified`, or `audit log` as product claims. Current documentation uses Threadline Admin and approved plain language; preserve technical module/API/route names and incoming anchors. ExDoc owns its code colors and theme; do not restyle it wholesale.

## Interaction Contract

### Primary visual anchors

The ordinary investigation centers the committed Timeline result list and then the selected transaction/diff or row-history evidence. Retention centers the recorded run history and its Preview retention entry; once ready, the estimate card is the anchor, and the confirmation dialog owns focus while open. Exports centers persisted job status and its permitted next action. Page headlines orient the job; shell chrome and metrics support the evidence and task controls rather than competing with them. Preserve the existing layout and density.

### Mounted jobs and existing controls

Use the existing `route-inventory.json`, `operator-journey-inventory.json`, and source checklist as the single route/job/state crosswalk. Real mounted `/audit` LiveViews own behavior. The mounted route set is `/audit`, `/audit/timeline`, `/audit/transactions/:id`, `/audit/transactions/:id/history/:table/:record_id`, `/audit/rows/:table/:record_id`, `/audit/actors/:kind/:id`, `/audit/coverage`, `/audit/evidence`, `/audit/exports`, `/audit/policy/redaction`, and `/audit/policy/retention`. Do not substitute Storybook stories for host routes.

| Journey | Required interaction |
|---------|----------------------|
| Ordinary investigation | Home lookup → applied Timeline query → transaction/diff → row history → copy the full ID → return with the committed search intact. Preserve direct entry, reload, browser back, actor/correlation pivots, and supported return context where each current route/job owns them. |
| Retention review | On `/audit/policy/retention`, open a read-only preview with `Preview retention`; after the preview is ready, `Review and confirm` opens the typed-confirmation dialog. Normal browser paths may submit the empty required field to demonstrate that it stays open and causes no write, then cancel with Escape or `Keep audit data`. Keep `Prune now` only as the final dialog submit. |
| Export review | Preserve the existing `/audit/exports` status distinctions, source-search return path, protected download lifecycle, and completed-only download action. A static status story or screenshot does not prove a download. |

For every changed control and selected complete job, verify the accessible name matches visible intent, semantic role/state is exposed, keyboard order follows the visible task, `document.activeElement` is the actual intended target, focus is visibly styled and unobscured, and modal/drawer dismissal returns focus to the control that opened it. Keep the modal focus trap, initial focus in the confirmation field, Escape/Keep cancellation, server-side exact-token check, authorization recheck, no-write blank submit, reconnect no-replay, and exact-target worker checks. A wrong or empty confirmation never audits or starts a run. The valid destructive Retention proof remains on its separate uniquely owned mutation database; ordinary captures and browser paths never type a valid token.

Install controlled clipboard doubles before navigation or keyboard activity in each new selected local context. Assert full-value copy intent and only show success after the double reports success. Preserve failure/manual recovery copy. Do not claim native clipboard contents, permission, untouched/restored state, or foreground execution.

### Inclusive conditions

- Run the selected ordinary and high-risk mounted flows in desktop Chromium and mobile Chromium. Check Dark and Light on matched representative routes; preserve the existing System theme behavior. Do not create a route × theme × state × width cross-product.
- At 320 CSS px viewport width, keep page actions and content reachable and the document/root free of horizontal overflow. Intentional data-table scrolling may remain inside its existing bounded `.tl-table-wrap`.
- For embedded reflow, constrain the actual host parent slot to 640 CSS px while the desktop viewport remains 1280×900. Measure the parent slot and mounted surface separately (`getBoundingClientRect`, `clientWidth`, and `scrollWidth`); assert no overflow escapes the host slot. Do not measure only a shrink-wrapped child or let its width define the test container.
- Prove real 200% browser tab zoom using the existing isolated headless Chromium helper in `operator-tab-zoom.ts`: set zoom with `chrome.tabs.setZoom`, read back `chrome.tabs.getZoom() === 2`, and verify the extension measured the exact owned loopback tab URL. Exercise a representative ordinary investigation state and Retention preview/dialog controls. A 2× DPR, CSS `zoom`, transform, or narrowed viewport is not browser zoom evidence.
- Use the existing mobile Chromium project at a 375×900 CSS viewport with touch enabled; required actions must work by tap without hover. Keep 40px text controls and give icon-only touch controls a 44×44px hit area.
- In one selected focused-control/operation-status case, emulate `forcedColors: active`; confirm system focus indication, text labels, operation words, and status shapes remain visible. Color never carries status alone.
- In the Retention confirmation and one ordinary detail/refresh state, emulate `prefers-reduced-motion: reduce`; the same content, focus, and status outcome must be available without relying on animation or transition.
- In every selected UI context, distinguish UI/browser proof from real data and authorization proof. The runner may enable the existing real Pruner only after the host Repo/schema is ready through its managed server launch. Keep `config/test.exs` Retention disabled. Verify the actual worker PID/Repo/schema/sleep snapshot and readiness marker before browser preview; record fixture overrides. No fake worker, global test-config flip, default-cleanup claim, or worker-availability-as-deletion claim is allowed.

Existing browser owners to extend or select are `operator-accessibility.spec.ts`, `operator-responsive-mobile-first.spec.ts`, `operator-zoom-proof.spec.ts`, `operator-route-states.spec.ts`, and `operator-motion.spec.ts`; reuse `operator-tab-zoom.ts`, `operator-investigation-pair.ts`, `operator-evidence-manifest.ts`, and the existing route/journey evidence owners. Migrate stale Retention entry probes to `Preview retention` and then `Review and confirm` only where the test promises an open modal. Keep all existing cases active; do not silently skip ordinary CI coverage.

## Capture and Evidence Contract

Capture only the following bounded representative batches when their visual content changes. For each changed visual state, produce one before/after pair with the same route, state, fixture, browser, viewport, DPR, theme, zoom, and intended container. Capture a fresh pre-change view from the actual Phase 252 source/runtime `74fe8df2b2520868d464eca93054492fc93a2cad` before editing any visible owner; the planning checkout SHA is a separate identity. Use retained Phase 252 captures as a baseline only when their route, data, browser, served assets, and capture conditions match. Existing preview/dialog images have no pre-Phase-252 equivalent; retain that historical limit.

| Batch | Bounded checkpoints | Maximum |
|-------|----------------------|---------|
| Ordinary investigation | `/audit/timeline` with populated committed query/copy feedback at 1280×900 Dark; `/audit/transactions/:id` diff at 375×900 Light; transaction-origin row history with preserved return context at 1280×900 Dark. | 3 matched pairs |
| High-risk operations | `/audit/policy/retention` populated run history and `Preview retention` at 1280×900 Dark; ready preview at 375×900 Light; open empty-token confirmation dialog with actual initial focus at 1280×900 Dark; `/audit/exports` with failed/pending/completed statuses and completed-only Download affordance at 1280×900 Light. | 4 matched pairs |

Do not create a pair for an unchanged visual state merely to fill the limit. New-only forced-colors, embedded-parent, and actual-zoom assertions have no comparable prior state: record them as after-only with that limitation, not as paired visual wins. The capture/review packet must bind, per image, the actual source revision and changed-file identity; served CSS/JS/font request status and hashes; actual computed font family; route and UI state; scenario and audit/operation materialization identity; actual capture clock; browser/version; CSS viewport, DPR, theme, verified zoom; intended parent/container dimensions and overflow; and image digest. Record real clocks; do not claim frozen time. New after-only states cannot replace a missing before image.

Keep evidence claims separate:

| Evidence | Establishes | Does not establish |
|----------|------------|-------------------|
| HEEx/source and shared component tests | Names, semantic structure, static copy, component composition, and source contracts. | Mounted routing, authorization, database writes, browser focus, or rendered geometry. |
| Phoenix LiveView/ConnCase and root ExUnit against the actual Repo | Query lifecycle, host authorization, exact server-side confirmation, persisted rows, and actual operation outcomes at the named boundary. | Browser zoom, touch, focus visibility, or pixels. |
| Playwright mounted browser receipts | Only the exercised browser/project/route/state/viewport/theme/zoom and clipboard-double conditions. | Native clipboard, human understanding, every route/state combination, or unexercised accessibility breadth. |
| PhoenixStorybook and static images | Shared production component composition for the named fixed story. | Live routing, authorization, database reads/writes, downloads, worker behavior, reconnect, or lifecycle. |
| Matched screenshots and independent UI/copy review | Rendered appearance and copy for the exact bound source/assets/data/clock/browser conditions. | Behavior, permission, DB outcome, comprehensive WCAG conformance, or adopter comprehension. |
| Archive/docs contracts | Actual inspected package bytes, declared docs surface, stable anchors, and local package shape. | Published package, hosted required CI, merge, or REL-01 completion. |

The independent UI/copy review uses the exact frozen source/capture packet and current schemas. Refresh only affected width/copy/behavior checks after the final visible-source edit and before review. Record failed/superseded evidence and actual attempt, retry, skip, flake, and cardinality values. No human UAT or blanket accessibility/comprehension claim is made.

Keep `brandbook/` and `priv/fonts/` as clearly superseded, unshipped history with their paths and provenance intact. Preserve stable technical module/config/route names and incoming documentation anchors while current README/guides/example/ExDoc wording moves to the approved identity. ExDoc owns its syntax colors and theme; no wholesale documentation restyle is in scope.

## UI Considerations

The installed post-approval probe raised28 applicable rows across four authored surface/kind unions. Autonomous kind confirmation includes forms, lists, navigation, controls and static content where present; no media surface is introduced. All rows below are resolved with explicit criteria, not execution results. Existing source/route/job owners remain authoritative.

| Surface | Category | Status | Verification | Acceptance criterion |
|---|---|---|---|---|
| UI-investigation | empty | resolved | explicit | No-match results, absent runs/jobs and empty confirmation inputs remain distinct from denied/unavailable reads; empty confirmation causes no write. |
| UI-investigation | loading | resolved | explicit | Pending query, preview or persisted status refresh is visibly identified; old data is not labeled a completed current read. |
| UI-investigation | error | resolved | explicit | Selected read/preview/download failures retain adjacent recovery feedback and safe controls; unavailable preview exposes no counts or confirmation. |
| UI-investigation | populated | resolved | explicit | Normal populated rows render actual route data with operation/status words and permitted actions; preview estimates remain distinct from persisted outcomes. |
| UI-investigation | partial | resolved | explicit | Missing/redacted/left-out values and active/failed checkpoint counts retain their actual meaning; missing values do not become zero or success. |
| UI-investigation | overflow | resolved | explicit | Selected 320px viewport and actual 640px host-parent checks keep actions/focus reachable and prevent document/host overflow; only bounded tables may scroll. |
| UI-investigation | zero-one-many | resolved | explicit | Existing zero/one/multiple row cases preserve singular/plural and summary values; a genuine zero preview is a valid ready estimate. |
| UI-investigation | long-text | resolved | explicit | Selected long names/URLs/feedback wrap within their owner; exact IDs remain accessible and copyable in full with controlled local clipboard doubles. |
| UI-retention | empty | resolved | explicit | No-match results, absent runs/jobs and empty confirmation inputs remain distinct from denied/unavailable reads; empty confirmation causes no write. |
| UI-retention | loading | resolved | explicit | Pending query, preview or persisted status refresh is visibly identified; old data is not labeled a completed current read. |
| UI-retention | error | resolved | explicit | Selected read/preview/download failures retain adjacent recovery feedback and safe controls; unavailable preview exposes no counts or confirmation. |
| UI-retention | populated | resolved | explicit | Normal populated rows render actual route data with operation/status words and permitted actions; preview estimates remain distinct from persisted outcomes. |
| UI-retention | partial | resolved | explicit | Missing/redacted/left-out values and active/failed checkpoint counts retain their actual meaning; missing values do not become zero or success. |
| UI-retention | overflow | resolved | explicit | Selected 320px viewport and actual 640px host-parent checks keep actions/focus reachable and prevent document/host overflow; only bounded tables may scroll. |
| UI-retention | zero-one-many | resolved | explicit | Existing zero/one/multiple row cases preserve singular/plural and summary values; a genuine zero preview is a valid ready estimate. |
| UI-retention | long-text | resolved | explicit | Selected long names/URLs/feedback wrap within their owner; exact IDs remain accessible and copyable in full with controlled local clipboard doubles. |
| UI-exports | empty | resolved | explicit | No-match results, absent runs/jobs and empty confirmation inputs remain distinct from denied/unavailable reads; empty confirmation causes no write. |
| UI-exports | loading | resolved | explicit | Pending query, preview or persisted status refresh is visibly identified; old data is not labeled a completed current read. |
| UI-exports | error | resolved | explicit | Selected read/preview/download failures retain adjacent recovery feedback and safe controls; unavailable preview exposes no counts or confirmation. |
| UI-exports | populated | resolved | explicit | Normal populated rows render actual route data with operation/status words and permitted actions; preview estimates remain distinct from persisted outcomes. |
| UI-exports | partial | resolved | explicit | Missing/redacted/left-out values and active/failed checkpoint counts retain their actual meaning; missing values do not become zero or success. |
| UI-exports | overflow | resolved | explicit | Selected 320px viewport and actual 640px host-parent checks keep actions/focus reachable and prevent document/host overflow; only bounded tables may scroll. |
| UI-exports | zero-one-many | resolved | explicit | Existing zero/one/multiple row cases preserve singular/plural and summary values; a genuine zero preview is a valid ready estimate. |
| UI-exports | long-text | resolved | explicit | Selected long names/URLs/feedback wrap within their owner; exact IDs remain accessible and copyable in full with controlled local clipboard doubles. |
| UI-shell | loading | resolved | explicit | Pending query, preview or persisted status refresh is visibly identified; old data is not labeled a completed current read. |
| UI-shell | error | resolved | explicit | Selected read/preview/download failures retain adjacent recovery feedback and safe controls; unavailable preview exposes no counts or confirmation. |
| UI-shell | overflow | resolved | explicit | Selected 320px viewport and actual 640px host-parent checks keep actions/focus reachable and prevent document/host overflow; only bounded tables may scroll. |
| UI-shell | long-text | resolved | explicit | Selected long names/URLs/feedback wrap within their owner; exact IDs remain accessible and copyable in full with controlled local clipboard doubles. |

## Registry Safety

No third-party registries or blocks are used. The UI remains repository-owned Phoenix components and static PhoenixStorybook examples.

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None; shadcn and third-party registries are not used | None | Not applicable |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-11-13 — independent checker; post-approval state probe resolved explicitly.
