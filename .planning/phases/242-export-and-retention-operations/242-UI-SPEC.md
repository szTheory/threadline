---
phase: "242"
slug: "export-and-retention-operations"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-10"
---

# Phase 242 — UI Design Contract

> Contract for completing the existing export, retention-prune, and LiveView recovery journeys. Phase 239–241 visual contracts and the current operator UI remain the design baseline.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — existing private Phoenix/HEEx UI primitives and Threadline CSS tokens |
| Preset | Not applicable; no shadcn or external component system |
| Component library | `Threadline.OperatorSurface.UI` private components; native HTML controls |
| Icon library | Existing `Threadline.OperatorSurface.Components.Icon` |
| Font | Geist/Inter system sans for UI; IBM Plex Mono for identifiers, timestamps, and evidence |

Preserve the accepted operator shell, identity, themes, hierarchy, and calm sentence-case language. Use existing status/data primitives and current routes. This phase adds no dependency, component package, public component API, route, retention schema, or new visual system. The interaction authority is `242-CONTEXT.md` D-01–D-10; the requirements are UIO-01, UIO-05, and UIA-05. Existing Threadline tokens and the Phase 239–241 UI-SPECs supply inherited visual rules.

The visual hierarchy follows the active task: on Timeline, the committed search and export action; on Exports, the actor-owned job status and usable download/return path; on Retention, the latest-run summary and run history, with the destructive action visually secondary until deliberate confirmation. During transport loss, keep the current page readable and available; only mutations pause.

## Component Inventory

Enumerated by `rg -n 'def [a-z_]+\\(assigns\\)' lib/threadline/operator_surface/ui/{page,actions,form,overlay,data,display}.ex | wc -l` — 49 local components — `Threadline.OperatorSurface.UI (threadline@1.0.1; source-owned)` — 2026-10-10.

This is a non-exhaustive list of source-owned known-good private primitives, not a closed allowlist. Inspect local modules for other suitable primitives before creating one. No external package or registry applies.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Shell, page header, detail header, tabs | `Threadline.OperatorSurface.UI.Page` | Preserve shared navigation and page hierarchy. |
| Buttons and links | `Threadline.OperatorSurface.UI.Actions` | Use buttons for mutations and links for navigation/downloads. |
| Inputs, labels, field groups | `Threadline.OperatorSurface.UI.Form` | Keep the type-to-confirm input labeled and native. |
| Data states and tables | `Threadline.OperatorSurface.UI.Data` | Keep loading, empty, failed, denied, and stale states distinct. |
| Ref, badge, card, stack, cluster | `Threadline.OperatorSurface.UI.Display` | Keep exact identifiers and status labels readable. |
| Modal, toast, reconnect banner | `Threadline.OperatorSurface.UI.Overlay` | Reuse modal focus lifecycle and polite shell-level connection status. |

## Spacing Scale

Use the existing 4px-root Threadline grid and named tokens for all new or changed layout. Keep the prior phase's compact scale and do not introduce off-grid spacing.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon-to-label and compact inline gaps |
| sm | 8px | Compact controls and table-cell grouping |
| md | 16px | Default card, field, and control spacing |
| lg | 24px | Section padding and section rhythm |
| xl | 32px | Major content-group separation |
| 2xl | 48px | Page-level section breaks |
| 3xl | 64px | Large page-level separation where space allows |

Exceptions: existing 1px borders/dividers and 3px status stripe are not spacing tokens. Keep interactive targets at least 40×40px; prefer the existing 44px target where practical. A compact control may retain a smaller visual box only when its actual target remains at least 40×40px.

## Typography

Use the existing semantic roles and font families. These four sizes and two weights govern primary phase content; inherited subordinate metadata may continue using existing 12–13px roles.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Label and identifier | 14px | 400 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Section heading | 20px | 600 | 1.2 |
| Page title | 24px | 600 | 1.2 |

Use the mono stack for IDs, exact timestamps, and technical identifiers. Never reduce primary instructions or interactive labels to fit; wrap long values or provide local overflow while preserving the full value.

## Color

Retain existing Light, Dark, and System semantic maps in `style/01_tokens.css`. The 60/30/10 ratio describes visual hierarchy, not literal pixel accounting.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Dark `#0B1020`; light `#F7F9FC` | Page ground and broad quiet surfaces |
| Secondary (30%) | Dark `#141B2D` with raised `#1B253A`; light `#FFFFFF` with raised `#EEF3FA` | Navigation, panels, forms, and run/job rows |
| Accent (10%) | Dark `#4F8CFF`; light `#1557C0` | Primary export action, meaningful navigation, active selection, and visible focus |
| Destructive | Dark `#FF8585`; light `#A33434` | Prune confirmation action only |

Accent reserved for: the primary export action, meaningful navigation, active selection, and visible keyboard focus. Use existing semantic warning, success, error, and neutral tokens for operation status, always with text labels; do not rely on color alone. Use danger color only for the confirmed prune action and its consequence.

## Copywriting Contract

Use calm, precise operator language. An accepted queue request is not a completed export; a completed job's metadata does not prove the file remains available. Transport loss does not establish mutation failure. A prune is global to the configured Threadline storage schema, with cutoff evaluated at execution; host tenant scope is not a prune filter.

| Element | Copy |
|---------|------|
| Primary CTA | `Export changes` |
| Secondary destructive CTA | `Prune now` |
| Empty export history | Heading: `No export jobs`; body: `Start an export from Timeline to see its status here.` |
| Empty retention history | Heading: `No retention runs`; body: `A run will appear here after a confirmed prune or scheduled retention operation.` |
| Queue acceptance | `Export queued. You can follow its status here.` Use only after the adapter accepts the job. |
| Export failure | `Export could not be queued. Check the export status, then try again from Timeline.` |
| Export unavailable | `The export file is unavailable or expired. Return to Timeline and start a new export if you still need it.` |
| Retention scope explanation | `This prune applies the configured retention policy globally to the configured Threadline storage schema. At execution, it removes AuditChange rows strictly older than the policy cutoff and may also remove empty AuditTransaction rows when configured. The current operator or tenant scope does not limit this prune. This history does not record a preview count or the cutoff used for this run.` |
| Retention failure | `Retention prune failed ({safe_category}). {completed_count} rows were deleted before the failure. Review the run details and resolve the reported category before starting another prune.` Render only a safe category, never raw database or exception text. |
| Disconnected status | `Connection lost. Read-only information may be stale; actions are paused until current status is refreshed.` |
| Reconnecting status | `Reconnecting. Actions will remain unavailable until current status is refreshed.` |
| Destructive confirmation | Title: `Prune retained audit data?`; body: use the full Retention scope explanation above, then `To confirm, type the policy name “default” exactly. This action cannot be undone.` Actions: `Cancel`; `Prune now`. |

Never say or imply “exactly once,” tenant-filtered pruning, a preview count, a historical cutoff, or file availability based only on job metadata. Do not claim a prune completed from a flash or queue acknowledgement; show the persisted run status. Distinguish pending, running, failed, completed, expired, and missing-file export states. Keep host authorization as the server authority.

## Journey and Interaction Contract

| Journey | Required behavior |
|---------|-------------------|
| Export from Timeline | Start from the committed supported filters. Preserve only validated filter fields in the persisted job and rebuild a local Timeline return link from those saved fields; use the local unfiltered Timeline path when no filters exist. Never accept an arbitrary return URL, host scope, tenant, cursor, or draft filters. |
| Export job lifecycle | Treat the current actor-owned persisted `ExportJob` as the source of truth after mount and reconnect. Render pending/queued, running, failed, completed-ready, expired, and missing-file outcomes distinctly. Say “queued” only after adapter acceptance. Keep scoped exports unavailable where the existing product contract disallows them. |
| Download | Offer download only when current readiness permits it. The existing request controller remains authoritative for actor ownership, completion, expiry, and storage delivery. A failed request must show actionable unavailable feedback; do not probe storage on every render. Intentional repeat export requests remain possible. |
| Retention history | Keep the recent-run summary adjacent to the newest-first history and state the actual displayed/capped row count. Show status, cumulative rows deleted, duration, and available timestamps. Keep safe failure category and partial completed-deletion count with the failed run. Do not infer cutoff or historical policy snapshot from current configuration. |
| Prune confirmation | Preserve the exact canonical policy-name type-to-confirm flow. The modal explains global schema scope and consequence before submission. `Cancel`, Escape, or the existing close control dismisses without pruning; only deliberate submit requests the operation. Server authorization, constant-time token comparison, audit-before-prune ordering, and server duplicate/in-flight guards remain authoritative. |
| Modal focus | On open, use the existing modal focus trap and focus the labeled confirmation input. Keep Tab/Shift+Tab inside while modal is open. Escape and Cancel close it without submitting. On close, restore focus to the original `Prune now` trigger. Give title and description stable IDs and associate them through the existing modal primitive. Do not move focus to the reconnect banner or status messages. |
| Disconnect/reconnect | Use the existing shell-level polite `role="status"` banner driven by actual LiveView transport state. Keep page content and read-only navigation available. Native-disable every mutation button while disconnected/reconnecting and while that action is in flight; keep CSS dimming/pointer suppression only as a secondary affordance. Do not use page-wide inertness or remove read-only content. |
| Reconciliation | On reconnect, refresh durable jobs and runs before reenabling mutations. Announce the status change without setting focus, scrolling, or moving the current focus. Never replay a pending or uncertain export/prune. If the outcome is unknown, show current persisted state and require a fresh deliberate activation. No exactly-once guarantee is implied. |
| Authorization and scope | Preserve existing host authorization and per-request download ownership checks. Client visibility, disabled attributes, return URLs, confirmation fields, and tenant context are never security boundaries. Retention always describes the configured schema-wide policy accurately. |
| Motion and themes | Reuse existing tokenized transitions and reduced-motion handling. No motion may delay status clarity, action availability, or focus restoration. Preserve Light, Dark, and System themes. |

## Responsive and Accessibility Floors

- Verify 320 CSS px, 375px, 768px, and 1280px widths plus actual browser-chrome 200% zoom. The document must not gain horizontal overflow; a genuinely wide table may use contained local scrolling while preserving run/job identity and actions.
- At narrow widths, stack run/job metadata and actions into labeled groups; let long identifiers and safe failure categories wrap. Keep export download/return actions and prune history controls visible and reachable.
- Keep confirmation text, global scope explanation, input label, and both modal actions available without clipped dialog content. Use a scrollable modal body when the short viewport requires it; keep the action row reachable.
- Use semantic buttons for mutation and links for navigation or downloads. Preserve a visible high-contrast focus ring and at least 40×40px interactive targets. Native `disabled` must block pointer, Enter, and Space activation during disconnect and in-flight submission; server guards still reject forged/repeated events.
- Connection changes are announced in the existing polite status region and do not receive programmatic focus. Reconnect must not steal focus from read-only navigation or a still-usable control. Do not auto-submit after reconnection.
- Verify keyboard opening, focus containment, Escape/Cancel behavior, focus return, keyboard-disabled mutations, touch targets, and reduced motion. Do not communicate status by color alone.

## UI Considerations

Applicable state considerations resolved: 25 total (18 explicit, 7 backstop), 0 unresolved, 0 unclassified. Empty/error state copy is defined in `Copywriting Contract`; this section defines coverage and truth conditions. These are acceptance criteria for planning and verification, not claims that checks have already passed.

| Surface / state | Status | Verification | Acceptance criterion |
|---|---|---|---|
| Export jobs / empty | resolved | explicit | Show the documented empty-history copy only after a successful read with zero actor-owned jobs. |
| Export jobs / loading | resolved | explicit | Keep the source search or Exports page identity visible while job state is loading; do not imply acceptance. |
| Export jobs / error | resolved | explicit | Keep read-only content available and distinguish a failed read from no jobs or failed export. |
| Export jobs / populated | resolved | explicit | Show each persisted job's current lifecycle state and expose download only when current readiness allows it. |
| Export jobs / partial | resolved | explicit | Expired or missing-file completion metadata remains distinct from usable completed download; transport loss remains separate from job failure. |
| Export jobs / overflow | resolved | backstop | At narrow widths and zoom, job identity, current status, source return, and available download remain reachable without document overflow. |
| Export jobs / zero-one-many | resolved | backstop | Empty, one, and many job histories retain accurate counts and the recent-history cap wording. |
| Export jobs / long-text | resolved | backstop | Long filter values and IDs wrap or use an existing full-value affordance without obscuring status or actions. |
| Retention runs / empty | resolved | explicit | Show documented empty-history copy only after a successful read with zero runs. |
| Retention runs / loading | resolved | explicit | Keep retention page identity and schema-wide policy explanation available while the run list loads. |
| Retention runs / error | resolved | explicit | A failed run-history read is not shown as an empty history; offer the existing safe refresh path. |
| Retention runs / populated | resolved | explicit | Show run status, cumulative deleted count, duration, and available timestamps from persisted records. |
| Retention runs / partial | resolved | explicit | A failed run shows safe failure category and cumulative deletions from completed batches; never show raw exception or imply zero after partial progress. |
| Retention runs / overflow | resolved | backstop | Run identity, status, counts, and available actions reflow or scroll locally at narrow widths and actual 200% zoom. |
| Retention runs / zero-one-many | resolved | backstop | Zero, one, and many runs have correct singular/plural and cap wording; order remains newest first. |
| Retention runs / long-text | resolved | backstop | Long run IDs and safe category labels wrap without displacing counts or status. |
| Prune confirmation / empty | resolved | explicit | An empty confirmation input cannot be represented as confirmation; the exact policy name is required. |
| Prune confirmation / loading | resolved | explicit | While submission is in flight, disable the prune submit natively and keep Cancel/read-only context available. |
| Prune confirmation / error | resolved | explicit | Mismatch, lost authorization, or runtime unavailable returns actionable safe feedback and performs no prune. |
| Prune confirmation / partial | resolved | explicit | Confirm copy states global configured-schema scope and possible empty-transaction removal without implying tenant filtering, preview count, or stored historical cutoff. |
| Prune confirmation / long-text | resolved | backstop | At short heights and zoom, full consequence and confirmation controls remain reachable; scrolling stays inside the modal. |
| Reconnect status / loading | resolved | explicit | Actual socket loss announces a polite status and clearly marks information as potentially stale while mutations are unavailable. |
| Reconnect status / error | resolved | explicit | Prolonged connection failure preserves read-only page and status copy; no action is reported failed solely from transport loss. |
| Reconnect status / partial | resolved | explicit | On reconnect, refreshed persisted state is shown before mutations reenable; uncertain requests are not replayed or called exactly once. |
| Mutation controls / loading | resolved | explicit | Native disabled blocks keyboard and pointer activation while disconnected or in flight; server-side guards remain active. |

### Cross-cutting checks outside the compiled state taxonomy

| Element | Status | Resolution |
|---------|--------|------------|
| Global retention scope | resolved (explicit) | Say the policy operates globally within the configured Threadline storage schema; current host operator/tenant filters do not scope pruning. The cutoff is evaluated at execution and not recorded in run history. |
| Modal focus lifecycle | resolved (explicit) | Focus the labeled input on open; contain focus; Escape/Cancel dismiss without mutation; restore focus to the trigger. |
| Reconnect announcement | resolved (explicit) | Use the existing polite status banner, update copy as needed, and never move focus or replay mutation. |
| Themes, zoom, and motion | resolved (backstop) | Check Light/Dark/System, 320/375/768/1280px, actual 200% zoom, keyboard, touch, visible focus, and reduced motion for affected journeys. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable — no shadcn or third-party registry is used — 2026-10-10 |

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS
- [ ] Dimension 7 Inventory Provenance: PASS

**Approval:** pending checker review
