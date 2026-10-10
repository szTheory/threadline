---
phase: "240"
slug: "connected-investigation-and-recovery"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-10"
---

# Phase 240 — UI Design Contract

> Contract for continuing a committed investigation across row history, actor and correlation pivots, saved searches, sharing, clipboard feedback, and the existing drawer. Phase 239 remains the shared visual and component baseline.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — existing private Phoenix/HEEx UI primitives and Threadline CSS tokens |
| Preset | Not applicable; no shadcn or external component system |
| Component library | `Threadline.OperatorSurface.UI` private components; native HTML controls |
| Icon library | Existing `Threadline.OperatorSurface.Components.Icon` |
| Font | Geist/Inter system sans for UI; IBM Plex Mono for identifiers, timestamps, and evidence |

Retain the accepted Phase 239 identity, hierarchy, themes, and task shell. Operators and engineers have equal priority: labels explain the job while complete authorized identifiers, exact values, and timestamp offsets remain reachable. Use familiar Timeline, Transaction, and row-history conventions, sentence-case copy, existing semantic tokens, and private primitives. Do not add a palette, public component API, dependency, client framework, or motion system.

Phase 240 visual authority is the Phase 239 approved contract and current `lib/threadline/operator_surface/` tokens and primitives. The interaction authority is `.planning/phases/240-connected-investigation-and-recovery/240-CONTEXT.md` D-01 through D-10, with the failure boundary in `240-RESEARCH.md` (including the Phase 239 WR-03 transaction outage finding). Do not treat a URL as host scope or an access grant.

**Primary visual hierarchy:** On Timeline, the applied query summary and matching change rows are the focal point; actor/correlation pivots and row-history or transaction links stay visible as supporting actions. In row history, lead with the current row identity and selected as-of context, then give the history evidence the strongest content emphasis. When history opens from a Transaction drawer, keep the transaction identity and safe return destination legible in the existing Phase 239 header hierarchy while the selected row's history remains the focal evidence. Preserve the Phase 239 transaction order: semantic transaction summary before distinct change records. Use the existing task shell, tokens, and private primitives.

## Component Inventory

Enumerated by `rg -n '    def [a-z_]+\(assigns\)' lib/threadline/operator_surface/ui/{page,actions,form,overlay,data,display}.ex | wc -l` — 49 local components — `Threadline.OperatorSurface.UI (threadline@1.0.1; source-owned)` — 2026-10-10.

This is a non-exhaustive list of source-owned known-good private primitives, not a closed allowlist. Inspect the local modules for additional primitives before creating one. No external package or registry applies.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Shell, page header, detail header | `Threadline.OperatorSurface.UI.Page` | Shared navigation, page hierarchy, breadcrumbs, transaction metadata |
| Buttons and links | `Threadline.OperatorSurface.UI.Actions` | Use semantic links for navigation and buttons for actions |
| Inputs, labels, field groups | `Threadline.OperatorSurface.UI.Form` | Native controls and existing validation patterns |
| Data states and tables | `Threadline.OperatorSurface.UI.Data` | Preserve loading, empty, failed, denied, redacted, absent, and pruned distinctions |
| Ref, badge, card, stack, cluster | `Threadline.OperatorSurface.UI.Display` | Keep complete authorized values and copy eligibility aligned |
| Drawer, toast, popover, dropdown, accordion | `Threadline.OperatorSurface.UI.Overlay` | Preserve focus lifecycle, dismissal, and local overflow behavior |

## Spacing Scale

Keep the existing 4px base grid and token roles. For new Phase 240-owned layout, use only the values listed below and reuse existing tokens; existing Phase 239 token uses elsewhere remain inherited and are not removed or redefined.

| Value | Usage |
|-------|-------|
| 4px | Icon gaps and tight label spacing |
| 8px | Compact control and inline gaps |
| 16px | Default page/control padding and content gaps |
| 24px | Section spacing |
| 32px | Major layout gaps |
| 48px | Large page-level separation |

Borders/dividers and the existing status stripe retain their Phase 239 treatment. Decorative icons and badges may remain 24px; interactive targets remain at least 40px, with 44px preferred where layout allows.

## Typography

Use these four phase-level roles with existing families and line-height tokens. Do not shrink evidence to fit; wrap or provide local scrolling while preserving the full value.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Label and identifier | 14px | 400 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Section heading | 20px | 600 | 1.2 |
| Page/detail title | 24px | 600 | 1.2 |

Inherited subordinate metadata and compact-status roles continue to use the Phase 239 type system. Phase 240 adds no font sizes and does not remove or rewrite shared styles; subordinate roles do not replace the four phase-level sizes above for primary instructions, evidence values, or interactive labels. Use the existing 500 weight only where already required by shared shell primitives; Phase 240 adds no weight or typeface.

## Color

Keep the dark, light, and System semantic maps in `style/01_tokens.css`. The 60/30/10 split describes visual area, not a requirement to recolor every component.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Dark `#0B1020`; light `#F7F9FC` | Page ground and large quiet surfaces |
| Secondary (30%) | Dark `#141B2D` with raised `#1B253A`; light `#FFFFFF` with raised `#EEF3FA` | Navigation, panels, drawers, and forms |
| Accent (10%) | Dark Thread Blue `#4F8CFF`; light Thread Blue `#1557C0` | Primary action, current/applied query state, investigation links, and visible focus |
| Destructive | Dark `#FF8585`; light `#A33434` | Delete saved search only |

Accent reserved for: the primary Save search action, focused controls, applied filter selection, and meaningful investigation navigation. Copy confirmation uses the existing success/signal semantic color only after confirmed copy. Do not use accent as a general surface fill or rely on color alone for status.

## Copywriting Contract

Use calm, precise, actionable sentence case. Keep canonical terms consistent: “saved search,” “Timeline,” “Transaction,” “row history,” and “as-of snapshot.” A correlation is a filter/pivot, not an incident; an actor does not own a transaction.

| Element | Copy |
|---------|------|
| Primary CTA | Save search |
| Share action | Copy search URL |
| Empty state heading | No saved searches |
| Empty state body | Save the applied Timeline filters to return to this search. |
| Row-history unavailable | Row history is unavailable. Retry row history or return to Timeline. |
| Copy success | Copied |
| Copy failure | Copy failed. Select the value and copy it manually. |
| Shared URL explanation | This URL shares the applied filters. Results and access are determined by the receiving host. |
| Destructive confirmation | Delete saved search “{name}”? This removes it from your saved searches. Actions: Keep saved search; Delete search. |

Do not claim that a shared URL preserves result rows, page position, host scope, tenant, or authorization. Do not include copied values in status feedback. Missing or unavailable transaction state remains authoritative; a known unavailable parent never renders or queries child history. Direct row-history load failure is retryable and must not be labeled empty, denied, or not found. Preserve distinct absent, pruned, and never-captured evidence wording from existing data-state components.

## Interaction Contract

| Journey | Required behavior |
|---------|-------------------|
| Row history and as-of | Provide a visible safe return action. A recognized transaction origin returns to the same transaction and keeps its identity; validated Timeline origins restore only supported committed filters. Direct entry with no valid origin returns to the default Timeline. Preserve selected `as_of` through updates and URL patches. Browser Back remains a convenience, not the sole return control. |
| URL state and access | Parse only existing allowlisted fields and a bounded origin discriminator. Rebuild local return paths under the current surface root. Reject unknown fields/origins and arbitrary return URLs. Never put host scope, tenant identity, or accumulated cursor pages in the URL; re-evaluate host authorization and scope on every route. |
| Actor/correlation pivots | Preserve the existing supported Timeline filters and a safe return context. Keep AuditTransaction, AuditAction, ActorRef, and AuditContext distinct in labels and summaries. |
| Saved searches | Save and restore the canonical committed Timeline query through the current actor-owned `SavedView` behavior. Draft filter edits are not saved. Apply by restoring the supported query through the normal validated route path. Anonymous actors do not receive a save affordance. |
| Search sharing | Build the copyable canonical local URL from the applied query, not draft edits or a saved-search record. Explain that the receiving host recomputes results and enforces its own access and scope. |
| Copy controls | Keep one document-level delegated click handler, bound once for fresh direct entry and repeated LiveView patches. Start clipboard writes directly from activation. Announce success only after Clipboard API resolution or confirmed legacy fallback. On failure, expose an accessible actionable message and selectable authorized value; preserve focus and clean temporary selection nodes. Never render copy controls or unauthorized full values for redacted, absent, omitted, or non-copyable evidence. |
| Frequent actions | Keyboard activation, Escape dismissal, copy, pivots, saved-search apply, filter changes, pagination, and as-of changes are immediate. Evidence value changes are immediate; investigation rows never stagger. |
| Drawer motion | Default to immediate. A drawer may use only existing tokenized spatial motion (at most 240ms, transform/opacity, interruptible) if the current lifecycle can safely identify pointer/touch activation without new shared modality state or replay after LiveView patches. Keyboard open/dismiss stays immediate. Under `prefers-reduced-motion: reduce`, remove spatial movement while retaining clear state and copy feedback. |
| Keyboard, touch, and focus | Use semantic links/buttons, visible focus, usable touch targets, predictable Escape dismissal and focus return. Error feedback must not steal focus from the active drawer. Long values wrap or scroll locally without widening the page or hiding return/actions. |

No new confirmation is needed for navigation, filter, copy, or saved-search application. Delete saved search is destructive and requires the confirmation copy above. No other destructive action is introduced by this phase.

## UI Considerations

The deterministic UI consideration probe classified four Phase 240 surfaces using explicit author-reviewed kind unions. All 26 applicable considerations are resolved with explicit acceptance criteria; no items were auto-dismissed or unclassified. 240-UI-PROBE.json records the computed categories and resolutions. These are required future checks, not execution passes. User-facing copy remains owned by the Copywriting Contract.

| Surface / state | Status | Verification | Acceptance criterion |
| --- | --- | --- | --- |
| UI-240-TIMELINE / Timeline applied-query results / empty | resolved | explicit | A completed zero-result query retains its applied-filter summary and a filter-adjustment path; empty results are not reported as retrieval failure. |
| UI-240-TIMELINE / Timeline applied-query results / loading | resolved | explicit | Pending query navigation keeps the requested query identifiable and never labels prior-scope rows as results for the new query. |
| UI-240-TIMELINE / Timeline applied-query results / error | resolved | explicit | A failed or denied applied query is distinct from zero results; allowed retry or recovery retains the committed query and host scope. |
| UI-240-TIMELINE / Timeline applied-query results / populated | resolved | explicit | Timeline results retain supported action, table, actor, row, and transaction identities; existing paging remains reachable. |
| UI-240-TIMELINE / Timeline applied-query results / partial | resolved | explicit | Missing action, actor, or context remains explicitly unrecorded where accurate; partial evidence never invents attribution or widens supported filters. |
| UI-240-TIMELINE / Timeline applied-query results / overflow | resolved | explicit | Long filter values and identifiers wrap or scroll locally without widening the document; filters and row actions stay reachable at narrow widths and 200% zoom. |
| UI-240-TIMELINE / Timeline applied-query results / zero-one-many | resolved | explicit | Zero, one, and multi-page results use truthful counts and paging availability; changing the query clears old rows and cursor state. |
| UI-240-SAVED-SEARCH / Actor-owned saved-search collection / empty | resolved | explicit | When the current actor has no saved searches, show “No saved searches” and the Copywriting Contract guidance to save applied Timeline filters. |
| UI-240-SAVED-SEARCH / Actor-owned saved-search collection / loading | resolved | explicit | Loading saved searches preserves the committed Timeline query and does not present stale records as the requested actor’s saved searches. |
| UI-240-SAVED-SEARCH / Actor-owned saved-search collection / error | resolved | explicit | Save, apply, and delete failures receive actionable feedback; failed operations are never presented as saved, applied, or deleted, and deletion requires specific confirmation. |
| UI-240-SAVED-SEARCH / Actor-owned saved-search collection / populated | resolved | explicit | Only the current actor’s saved searches are listed; applying one restores its canonical supported committed query through normal validation. |
| UI-240-SAVED-SEARCH / Actor-owned saved-search collection / partial | resolved | explicit | Only supported canonical committed filters are saved or restored; draft values and host-scope state never become saved-search data. |
| UI-240-SAVED-SEARCH / Actor-owned saved-search collection / overflow | resolved | explicit | Long saved-search names and filter summaries wrap or scroll locally; all collection actions remain visible and reachable. |
| UI-240-SAVED-SEARCH / Actor-owned saved-search collection / zero-one-many | resolved | explicit | Empty, one, and many saved searches retain truthful singular or plural labels and usable apply and delete actions. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / empty | resolved | explicit | No available row changes remain distinct from absent, pruned, never-captured, and unavailable evidence; a known unavailable transaction remains authoritative. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / loading | resolved | explicit | Pending as-of or route changes keep the selected snapshot and origin visible and never present prior-state rows as the new history result. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / error | resolved | explicit | A direct row-history read failure is retryable and keeps a safe return action; it is not labeled empty, denied, or not found, and an unavailable parent suppresses child reads. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / populated | resolved | explicit | History shows supported changes at the selected as-of value with exact identity and authorized value affordances; transaction-origin history returns to the same transaction. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / partial | resolved | explicit | Redacted, absent, omitted, pruned, and never-captured evidence remains distinguishable; values and causal context are not fabricated. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / overflow | resolved | explicit | Long keys and values remain reachable through wrapping or local scrolling without hiding return, as-of, dismissal, or focus controls. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / zero-one-many | resolved | explicit | Zero, one, and many history rows preserve truthful states and keep the selected as-of value and safe return destination available. |
| UI-240-ROW-HISTORY / Row history and transaction-origin history / long-text | resolved | explicit | Full authorized identifiers, timestamps, and values remain selectable or copyable; long fields wrap or scroll locally, while redacted and non-copyable values expose no copy control. |
| UI-240-COPY / Clipboard controls and feedback / loading | resolved | explicit | While a clipboard write is pending, feedback does not claim success; the write starts from user activation and the current focus remains stable. |
| UI-240-COPY / Clipboard controls and feedback / error | resolved | explicit | Only confirmed Clipboard API or fallback completion announces “Copied”; failure offers manual-copy recovery and leaves the authorized value selectable. |
| UI-240-COPY / Clipboard controls and feedback / overflow | resolved | explicit | Copy status does not cover focus, drawer dismissal, or the source value; temporary selection nodes are removed after fallback. |
| UI-240-COPY / Clipboard controls and feedback / long-text | resolved | explicit | Long authorized text remains selectable without widening the page; redacted, absent, omitted, and otherwise non-copyable evidence stays non-copyable. |

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| External registry | None | Not applicable — no shadcn or third-party component registry is used |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** approved 2026-10-10
