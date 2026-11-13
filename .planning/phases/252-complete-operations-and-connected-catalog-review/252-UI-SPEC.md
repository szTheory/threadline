---
phase: "252"
slug: "complete-operations-and-connected-catalog-review"
status: draft
shadcn_initialized: false
preset: none
created: "2026-11-13"
---

# Phase 252 — UI Design Contract

> Add the Retention preview and connect the existing Operations catalog to production screen patterns. Phase 251 and the approved Threadline brand remain the visual source of truth. Preserve existing Export behavior and the host app's existing UI shell.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — repository-owned Phoenix LiveView/HEEx components and scoped CSS tokens |
| Preset | Not applicable; shadcn is not used |
| Component library | Custom Phoenix.Component modules under Threadline.OperatorSurface; no third-party UI component library |
| Icon library | Threadline.OperatorSurface.Components.Icon (inline SVG) |
| Font | Threadline-private Familjen Grotesk, Geist, and IBM Plex Mono aliases with locally served licensed WOFF2 |

Use the existing .threadline-ui variables and brand/brand.json tokens. Dark remains the default theme and light remains a complete theme. Keep the host font opt-out, theme behavior, paired logo assets, and existing shell. Phoenix LiveView/HEEx and PhoenixStorybook 1.2.0 stay in the example/dev/test boundary. Do not introduce React, Fablebook, a new registry, adapter, or dependency.

---

## Component Inventory

Enumerated by `rg --files lib/threadline/operator_surface/components lib/threadline/operator_surface/ui | wc -l` — 10 components — threadline@1.1.0 — 2026-11-13.
Cross-check: `find lib/threadline/operator_surface/components lib/threadline/operator_surface/ui -type f -name '*.ex' | wc -l` — 10 source files. No mismatch.

This is a non-exhaustive list of repository-owned components, not a closed allowlist.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Icon | Threadline.OperatorSurface.Components.Icon | Existing semantic inline icons; never use an icon or color without a visible text label for an operation or state. |
| Logo | Threadline.OperatorSurface.Components.Logo | Existing compile-time light/dark lockup. |
| SurfaceHeader | Threadline.OperatorSurface.Components.SurfaceHeader | Existing shell, navigation, and theme selection. |
| UnsupportedView | Threadline.OperatorSurface.Components.UnsupportedView | Preserve the existing safe unavailable/denied route fallback. |
| Actions | Threadline.OperatorSurface.UI.Actions | Existing labelled action controls. |
| Data | Threadline.OperatorSurface.UI.Data | Existing loading, empty, error, and table presentations. |
| Display | Threadline.OperatorSurface.UI.Display | Exact values, timestamps, references, and copy controls. |
| Form | Threadline.OperatorSurface.UI.Form | Existing form controls and inline correction states. |
| Overlay | Threadline.OperatorSurface.UI.Overlay | Existing accessible modal, focus, and cancel behavior. |
| Page | Threadline.OperatorSurface.UI.Page | Existing page shell, headers, and layout. |

For Export, reuse ExportStatusLive.Components.job_history/1. For Retention, narrowly extract and share its existing read-only run-history and preview presentation between the LiveView and static story. Do not duplicate production markup or create a general page engine.

---

## Spacing Scale

Keep Phase 251's 8-point rhythm, using multiples of four:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label gaps and inline alignment. |
| sm | 8px | Compact controls and row spacing. |
| md | 16px | Standard control padding and panel content. |
| lg | 24px | Related content groups. |
| xl | 32px | Page sections. |
| 2xl | 48px | Major page breaks. |
| 3xl | 64px | Page-level separation. |

Exceptions: retain existing 12px, 20px, and 40px values in dense tables and controls. Keep text controls at 40px high and icon-only controls at a 44px minimum hit area. Do not add spacing tokens for this phase.

---

## Typography

Use the existing local font aliases and only the two interface weights: 400 regular and 600 semibold. This contract uses four sizes:

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body and control text (Geist) | 16px | 400 | 1.55 |
| Dense metadata and identifiers (Geist or IBM Plex Mono) | 13px | 400 | 1.4 Geist; 1.5 Mono |
| Labels and column headings (Geist) | 12px | 600 | 1.2; uppercase and 0.12em tracking only at this size |
| Page and section headings (Familjen Grotesk) | 28px | 600 | 1.2 |

Keep timestamps and counts tabular. Render identifiers and table/field names in IBM Plex Mono. If an ID is visually middle-elided, retain its complete accessible name and copy value. Preserve existing focus outlines and fallback fonts.

---

## Color

Follow the approved 60/30/10 hierarchy. Accent may occupy less than 10%; keep the existing palette and do not use accent as a large fill.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (about 60%) | Dark: Threadline Black #0B1020 (62%). Light: Paper #F7F9FC (64%). | Page ground; dark remains default. |
| Secondary (about 30%) | Dark: Graphite #141B2D (24%). Light: Card White #FFFFFF (22%). | Rows, cards, and panels. |
| Text | Dark: Fog #D7DEEA. Light: Ink #0F1728. | Primary reading and data. |
| Accent (about 10% maximum) | Dark: Thread Blue #4F8CFF. Light: Thread Blue Deep #1557C0. | Links, visible focus, selected state, and the existing primary action edge. |
| Dividers | Dark: Slate Line #23304A. Light: Hairline #C9D3E2. | Group and row separation only, never text or the sole control boundary. |
| Destructive | Dark: #FF8585. Light: #A33434. | The irreversible Retention action only. |

Accent reserved for: brand links, visible focus rings, selection, and the primary action edge. Preserve semantic status colors with visible status words; Insert, Update, Delete, and Redacted are words first and color second. Stitch Blue #4781E6 is logo-thread artwork only. Do not change the existing global primary-fill or palette treatment in this phase.

The inherited global primary-fill/palette refinement and broad zoom, error-pixel, inclusive-use, and docs/package work belong to Phase 253; they are explicitly nonblocking for this contract.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Before a successful preview: Preview retention. In the confirmation modal after a successful preview: Prune now. Preserve existing Export action labels and behavior. |
| Export empty state | Heading: No export jobs. Body: Start an export from Timeline to see its status here. Action: Open timeline. |
| Retention empty state | Heading: No retention runs. Body: A run appears here after a confirmed prune or scheduled retention operation. Show Preview retention as the next step; a preview is transient and never appears as a run. |
| Retention preview | Heading: Retention preview. Show separate “Estimated AuditChange candidates” and “Estimated empty AuditTransaction candidates” counts, plus “Preview generated at {exact timestamp} UTC.” Label both counts as estimates. Explain that the scope is all eligible history in the worker's configured Threadline audit store and is not narrowed by the current user or tenant scope. |
| Disabled empty-transaction cleanup | Show “Empty-transaction cleanup is disabled, so empty AuditTransaction candidates are not included in this estimate.” Do not show this as 0 eligible. When cleanup is enabled and the actual candidate count is zero, show 0 eligible. |
| Estimate caveat | “These counts are sequential estimates, not a snapshot. History and settings may change before the run. The worker recomputes its cutoff later; batch limits apply to the run, not these counts. Actual removals may differ.” Do not invent or imply a preview cutoff, atomic count, or guaranteed final total. |
| Retention preview failure | “Retention preview is unavailable. No counts are shown and a prune cannot be started from this view. Refresh the history and try the preview again; if it keeps failing, contact your administrator.” Use the same no-count/no-confirmation state for a denied, unreadable, mismatched, or restarted target; do not expose process, repo, or schema diagnostics. |
| Export error | Preserve the current distinction: “Export history could not be loaded. Your saved jobs are unchanged; try refreshing this page.” Keep the visible Refresh export history action. |
| Retention history error | Preserve the current distinction: “Retention history could not be loaded. The saved runs are unchanged. Refresh to check their current status.” |
| Destructive confirmation | Title: “Prune retained audit data?” Include the two estimates, generated UTC time, global configured-store scope, and estimate caveat. Ask the operator to type the exact policy name “default”. Actions: Keep audit data and Prune now. State that the action cannot be undone. |

Keep Export's scoped immediate CSV/JSON/NDJSON downloads separate from the unscoped actor-owned background queue. Queue feedback is not a persisted accepted status; only a completed job exposes Download export. Do not add new copy that promises tenant-scoped background jobs. For Retention, show persisted queued/running/completed/failed outcomes as recorded and show actual deleted-row counts only from the run; never present preview estimates as removals.

---

The Retention preview summary is the primary visual anchor; global store scope and confirmation controls remain subordinate.

## Interaction Contract

### Export

Preserve the current committed-filter, authorization, owner, status, file-availability, expiry, recovery, and completed-only download behavior. Keep scoped immediate downloads and unscoped actor-owned queue visibly distinct. Existing job status and timestamp labels remain visible text; preserve the source-search return link. This phase changes Export only for a demonstrated defect.

### Retention preview and confirmation

1. Render Preview retention as a non-destructive read action. While counts are loading, announce “Previewing retention estimates…” as a status. Authorize before reading.
2. Show counts only after the configured worker target matches and the original target is rechecked after both sequential counts. The target coordination stays internal. A successful 0 AuditChanges / 0 enabled AuditTransactions preview is valid and may proceed.
3. Do not show counts or a confirm path on denial, read failure, target mismatch, worker restart, or target recheck failure. Clear any previously displayed estimate on failure.
4. Only a server-held successful preview enables the typed-confirmation path. Do not encode preview authority in a form value, hidden input, route, story fixture, or client event. Reauthorize and recheck the same target before confirmation, audit, and guarded trigger.
5. Keep the existing modal, initial focus, keyboard handling, constant-time typed validation, visible correction message, cancel action, audit-before-trigger order, and active-run coalescing. A wrong policy name does not audit or start a run. Cancel, remount, or reconnect clears the transient preview and confirmation; offline submit and reconnect never replay a prune. A fresh preview and deliberate confirmation are required.
6. After confirmation, show actual persisted run status and actual outcome. Do not show a preview row, create preview history, or add preview data to Evidence. If a worker stops after the audit request is recorded, do not imply that a run exists or retarget another worker.

### Operations catalog

- Add an Operations category with Export and Retention PhoenixStorybook page stories. Reuse the same production read-only renderers and static assigns from the existing Storybook Fixtures helper. Use scenario.acme-4521-investigation for the ordinary Export scene and the completed-small 14-row Demo.Seed.RetentionRuns fixture for ordinary Retention. Keep scenario.state-export-failed / fixture.state-export-failed.1, denied, huge-count, and other stress/boundary data in separate named scenes.
- The static story path must not call Repo, Demo.Seed, file writes, or mutation handlers. Retention destructive controls must be absent or inert. Label page compositions as static examples; they do not prove permissions, query results, URL lifecycle, downloads, persistence, or reconnect behavior.
- Document each story against the current semantic inventory: Exports links to route.exports, source-exports-6, proof-exports-1/2, and scenario.acme-4521-investigation; Retention links to route.retention, job.operator-retention-operations, source-retention-6, and proof-retention-1/2. Validate these identities against the existing inventories; do not add a second registry or adapter.

### Responsive and accessibility behavior

Use the existing Page/Data/Display/Form/Actions/Overlay compositions, native LiveView forms, and current responsive data-table boundaries. Keep meaning in words as well as color. Loading and successful operation feedback uses status semantics; errors use role=alert adjacent to the affected content. Tables retain semantic headers and exact values; timestamps retain machine-readable UTC values. Keep keyboard order, visible 2px theme-correct focus, modal focus return, and full accessible/copy values for elided IDs. No zoom, inclusive-use, broad error-pixel, or documentation sweep is required here.

Matched route captures: 1280px dark and 375px light for the ordinary Export and Retention scenes, with the same data, assets, clock, route, and browser before/after. Keep destructive outcomes in separately named fixtures so they cannot alter the matched pair. Existing Storybook smoke widths remain 320px, 375px, and 768px.

---

## UI Considerations

The installed engine computed30 applicable rows, all explicitly resolved as implementation criteria, not runtime passes. Autonomous kind review includes Export form/list/controls (U1), Retention preview/confirmation (U2), run history (U3) and catalog navigation/content (U4). No row was dismissed.

| Surface | Category | Status | Verification | Criterion |
|---|---|---|---|---|
| U1 | empty | resolved | explicit | Distinguish absent/unavailable data from a successful zero result and provide the existing next step. |
| U1 | loading | resolved | explicit | Expose pending work without stamping old data as a completed new read; static stories label pending as projection. |
| U1 | error | resolved | explicit | Use safe recovery copy, withhold unavailable counts/confirmation and never show diagnostics or imply an empty result. |
| U1 | populated | resolved | explicit | Render actual scoped source values/statuses and preview UTC generation time with stated evidence limits. |
| U1 | partial | resolved | explicit | Keep missing timestamps/counts and cleanup-not-included separate from zero and from completed outcomes. |
| U1 | overflow | resolved | explicit | Keep content/actions reachable within the actual page or catalog container at contracted widths. |
| U1 | zero-one-many | resolved | explicit | Keep zero/one/many count and noun meanings accurate; a successful zero preview remains valid. |
| U1 | long-text | resolved | explicit | Keep long references/timestamps readable, with complete accessible/controlled-copy values and no clipped controls. |
| U2 | empty | resolved | explicit | Distinguish absent/unavailable data from a successful zero result and provide the existing next step. |
| U2 | loading | resolved | explicit | Expose pending work without stamping old data as a completed new read; static stories label pending as projection. |
| U2 | error | resolved | explicit | Use safe recovery copy, withhold unavailable counts/confirmation and never show diagnostics or imply an empty result. |
| U2 | partial | resolved | explicit | Keep missing timestamps/counts and cleanup-not-included separate from zero and from completed outcomes. |
| U2 | overflow | resolved | explicit | Keep content/actions reachable within the actual page or catalog container at contracted widths. |
| U2 | long-text | resolved | explicit | Keep long references/timestamps readable, with complete accessible/controlled-copy values and no clipped controls. |
| U3 | empty | resolved | explicit | Distinguish absent/unavailable data from a successful zero result and provide the existing next step. |
| U3 | loading | resolved | explicit | Expose pending work without stamping old data as a completed new read; static stories label pending as projection. |
| U3 | error | resolved | explicit | Use safe recovery copy, withhold unavailable counts/confirmation and never show diagnostics or imply an empty result. |
| U3 | populated | resolved | explicit | Render actual scoped source values/statuses and preview UTC generation time with stated evidence limits. |
| U3 | partial | resolved | explicit | Keep missing timestamps/counts and cleanup-not-included separate from zero and from completed outcomes. |
| U3 | overflow | resolved | explicit | Keep content/actions reachable within the actual page or catalog container at contracted widths. |
| U3 | zero-one-many | resolved | explicit | Keep zero/one/many count and noun meanings accurate; a successful zero preview remains valid. |
| U3 | long-text | resolved | explicit | Keep long references/timestamps readable, with complete accessible/controlled-copy values and no clipped controls. |
| U4 | empty | resolved | explicit | Distinguish absent/unavailable data from a successful zero result and provide the existing next step. |
| U4 | loading | resolved | explicit | Expose pending work without stamping old data as a completed new read; static stories label pending as projection. |
| U4 | error | resolved | explicit | Use safe recovery copy, withhold unavailable counts/confirmation and never show diagnostics or imply an empty result. |
| U4 | populated | resolved | explicit | Render actual scoped source values/statuses and preview UTC generation time with stated evidence limits. |
| U4 | partial | resolved | explicit | Keep missing timestamps/counts and cleanup-not-included separate from zero and from completed outcomes. |
| U4 | overflow | resolved | explicit | Keep content/actions reachable within the actual page or catalog container at contracted widths. |
| U4 | zero-one-many | resolved | explicit | Keep zero/one/many count and noun meanings accurate; a successful zero preview remains valid. |
| U4 | long-text | resolved | explicit | Keep long references/timestamps readable, with complete accessible/controlled-copy values and no clipped controls. |

---

## Registry Safety

No third-party registries or blocks are used.

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None; shadcn and third-party registries are not used | None | Not applicable; manual Phoenix components and static PhoenixStorybook examples only. |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** Independent checker APPROVED2026-11-13; two nonblocking clarity recommendations incorporated.

