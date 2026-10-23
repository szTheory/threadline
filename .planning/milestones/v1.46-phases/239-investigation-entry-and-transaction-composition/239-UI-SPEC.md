---
phase: "239"
slug: "investigation-entry-and-transaction-composition"
status: approved
reviewed_at: "2026-10-09"
shadcn_initialized: false
preset: none
created: "2026-10-09"
---

# Phase 239 — UI Design Contract

> Visual and interaction contract for the Home → filtered Timeline → transaction investigation journey. Generated from the approved Phase 239 context, the retained current-main UI, and accepted Phase 238 renders.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — existing private Phoenix/HEEx UI primitives and Threadline CSS tokens |
| Preset | Not applicable; no shadcn or external component system |
| Component library | `Threadline.OperatorSurface.UI` private components; native HTML controls |
| Icon library | Existing `Threadline.OperatorSurface.Components.Icon` |
| Font | Geist/Inter system sans for UI; IBM Plex Mono for identifiers, timestamps, and evidence |

Use Impeccable Operate mode: keep the familiar task shell, navigation, forms, and controls; earn polish through accurate hierarchy, scanability, deliberate density, and the existing “night infrastructure with luminous signal lines” identity. This phase refines the current world. It does not introduce a new visual world, palette, public component API, framework, package, or route.

The visual source of truth is the accepted Phase 238 route bundle `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_close_routes_1791521924`, especially `route.home`, `route.timeline`, and `route.transaction` at 1280, 768, and 375 CSS px. Keep that bundle immutable as the before reference. The 375px Timeline long-filter capture in the separate accepted state bundle is a known whole-page overflow defect, not an acceptable layout variant. Source anchors are `style/01_tokens.css` through `style/09_responsive.css`, `ui/{page,actions,form,overlay,data,display}.ex`, and the three LiveViews named in `239-CONTEXT.md`.

## Component Inventory

Enumerated by `rg -n '    def [a-z_]+\(assigns\)' lib/threadline/operator_surface/ui/{page,actions,form,overlay,data,display}.ex` — 47 local components — `Threadline.OperatorSurface.UI (threadline@1.0.1; source-owned)` — 2026-10-09.

This is a non-exhaustive list of source-owned, known-good private primitives, not a closed allowlist. Check the local modules for other needed primitives before building one. No external installed component package or registry applies.

| Component | Import path | Notes |
|-----------|-------------|-------|
| Shell, page header, detail header | `Threadline.OperatorSurface.UI.Page` | Shared navigation, page hierarchy, breadcrumbs, transaction metadata |
| Buttons and links | `Threadline.OperatorSurface.UI.Actions` | Existing variants and compact controls; preserve semantic links/buttons |
| Inputs, labels, field groups | `Threadline.OperatorSurface.UI.Form` | Native form controls with existing field/error patterns |
| Data states and tables | `Threadline.OperatorSurface.UI.Data` | Loading, empty, failed, denied, redacted and pruned state primitives; use truthful states |
| Ref, badge, card, stack, cluster | `Threadline.OperatorSurface.UI.Display` | Preserve exact authorized value boundary and existing operation/status vocabulary |
| Drawer, toast, popover, dropdown, accordion | `Threadline.OperatorSurface.UI.Overlay` | Reuse existing lifecycle and focus primitives; validate overlapping states |

## Spacing Scale

Use the existing 4px base grid. Keep role tokens consolidated in `style/01_tokens.css`; preserve useful current steps rather than forcing every layout onto a 8px-only scale.

| Token | Value | Usage |
|-------|-------|-------|
| 1 | 4px | Optical/icon gaps and tight label spacing |
| 2 | 8px | Compact control and inline gaps |
| 3 | 12px | Form/control padding and dense row gaps |
| 4 | 16px | Default page/control padding and content gaps |
| 5 | 20px | Home card padding and prominent inset spacing |
| 6 | 24px | Section spacing and roomy page insets |
| 8 | 32px | Major section/layout gaps |
| 10 | 40px | Existing deliberate vertical breathing room |
| 12 | 48px | Large page-level separation |

Exceptions: 1px borders/dividers and the existing 3px status stripe are non-spacing details. Remove or document any 3px padding exception in the owned detail styles; do not add off-grid spacing. Consolidate equivalent control and page spacing roles without blanket rewriting unrelated surfaces.

## Typography

Retain the established fixed-size scale and the two incumbent families. Do not shrink ordinary data to fit columns; reflow it. These floors are anchored to the accepted renders and token roles, then should be consolidated where equivalent roles currently duplicate values.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Dense metadata / compact status | 12px minimum | 400 or 500 | 1.4 |
| Dense row data | 13px minimum | 400 or 500 | 1.4–1.5 |
| Labels and mono identifiers | 14px | 400 or 600 | 1.4 |
| Controls / secondary UI | 15px | 400 or 600 | 1.5 |
| Body copy | 16px | 400 | 1.5 |
| Section heading | 20px | 500 or 600 | 1.2 |
| Page title | 24px | 500 or 600 | 1.2 |
| Home lead heading | 32px | 500 | 1.15 |

The 12–13px roles are limited to subordinate metadata, compact status, and dense row labels. Primary instructions, important evidence values, and interactive labels remain at least 14px. Avoid adding weights beyond existing 400/500/600 roles; use 500 for hierarchy and 600 for control/section emphasis. Keep line length for explanatory prose near 65–75ch where layout permits; evidence can be denser.

## Color

Keep the existing dark, light, and system semantic maps in `style/01_tokens.css`. The ratio describes visual area, not a demand to recolor specific components: roughly 60% page ground, 30% raised/secondary surfaces, and 10% active signal/detail.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Dark `#0B1020`; light `#F7F9FC` | Page ground and large quiet surfaces |
| Secondary (30%) | Dark `#141B2D` with raised `#1B253A`; light `#FFFFFF` with raised `#EEF3FA` | Navigation, panels, change records, forms |
| Accent (10%) | Dark Thread Blue `#4F8CFF`; light Thread Blue `#1557C0` | Primary Timeline CTA, focused controls, active/applied selection, meaningful inline navigation |
| Destructive | Dark `#FF8585`; light `#A33434` | Destructive action only; no destructive action is added by Phase 239 |

Accent reserved for: primary CTA, current/selected/applied query state, inline links that navigate the investigation, and visible focus treatment. Use the existing insert/update/delete and warning/error/success semantic colors only for their corresponding evidence/status meanings. Do not tint every card or control with accent. Preserve neutral contrast and tokens in Light, Dark, and System; do not repair the self-referential paper/ink aliases by inventing a new palette.

## Copywriting Contract

Use calm, precise, sentence-case task language and canonical destination nouns (`Timeline`, `Transaction`, `Coverage`, `Evidence`, `Exports`). Describe AuditTransaction, AuditAction, ActorRef, and AuditContext independently. Claim context only when recorded.

| Element | Copy |
|---------|------|
| Primary CTA | Open the timeline |
| Home supporting copy | Search captured changes by time, table, actor, or correlation. Open a transaction to inspect its row changes and any recorded action or context. |
| Empty state heading | No changes match these filters |
| Empty state body | Adjust the time range or filters, then apply again. |
| Error state | Timeline could not be loaded. Check the applied filters and try again. |
| Destructive confirmation | None in this phase. |

Do not use the baseline claim “Every change is connected to the action, context, and story around it.” If an actor or context field has no recorded value, label it `Not recorded` where that statement is true. A transaction not found must not claim pruning as fact: say it was not found, offer return to Timeline/check the ID, and preserve the ambiguity between a missing and pruned record. A transaction actor and a linked action actor are separate; never infer one from the other.

## Journey and Interaction Contract

**Home:** Keep the task-oriented hierarchy in the accepted render. Timeline remains the primary investigation entry and the only full-width primary card. Keep row-history and correlation lookup visibly available, with input labels and task descriptions. Keep Coverage and Evidence/Exports discoverable as secondary destinations. Keep system-health warnings visible without letting them displace the investigation CTA. Use `Open the timeline` consistently and sentence case across links/buttons. Do not turn Home into a generic dashboard or add a new investigation job.

**Timeline query:** Preserve the existing primary filters, advanced-filter disclosure, and explicit `Apply` action. The supported URL allowlist is the committed user query; preserve schema/table, time, actor, and correlation filters. Draft edits are not reflected in the active-filter summary or result identity before Apply. Apply navigates to the query URL; reload and back/forward restore and execute the query. Cursor paging stays incremental, tied to the applied query, and resets when the query changes. The URL never carries host authorization/tenant scope. Canonical labels are `Timeline`, `Filters`, `Apply`, and `Reset to last 24 hours` (or an existing precise reset label); use sentence case.

During a changed query from a nonempty result set, either retain old rows with their old query identity and an explicit updating state, or clear them while showing pending. Never show old rows under the new query summary. Pending, empty, failed, denied, and completed states remain distinct; a recovery action retries the same applied query. Initial-empty loading alone is not sufficient evidence for this contract.

**Transaction:** Put a concise semantic transaction summary before distinct `AuditChange` records. Keep actor, optional linked action, correlation, captured time, and recorded execution context as separately labeled facts; show only values present in existing authorized reads. One transaction groups row changes; do not imply that one action maps one-to-one to one transaction. Each change remains its own record with operation/table/row identity and field evidence. Pair `Before` and `After` values on wide layouts; stack each value under its explicit label at narrow widths or 200% zoom. Do not place heterogeneous evidence in a forced wide table or duplicate it inside nested panels.

Preserve inserts, deletes, no field-level evidence, null, absent, omitted, and redacted values as distinct states. Keep `[REDACTED]` visible as the only value for redacted evidence; never expose hidden bytes through disclosure content, DOM attributes, or an alternate route. Keep not-found/denied scope behavior server-authoritative.

**Exact values:** Whenever a displayed identifier, value, or timestamp is abbreviated, render an adjacent visible native inline disclosure (prefer `<details>/<summary>` with the existing tokens) named for the item, such as `Show full transaction ID`, `Show full value`, or `Show exact timestamp`. Expanded text must be complete, selectable, keyboard-operated, touch-reachable, and present with JavaScript enabled. Disclosure does not depend on hover/title, `datetime`, noscript, or Copy. Render the exact timestamp with its timezone/offset in visible text (ISO 8601; UTC explicitly labeled when normalized). Preserve the original authorized bytes and redaction boundary. Copy remains convenience behavior owned by Phase 240, not the only way to access a full value here.

## Responsive, Theme, and Control Floors

- At 320 CSS px, 375px, 768px, and 1280px, page content reflows without whole-document horizontal overflow. `document.documentElement.scrollWidth` must not exceed `clientWidth` for Home, Timeline, or Transaction at the 320/375 narrow checks. A genuinely two-dimensional data region may scroll locally and must keep the page itself within its viewport.
- Constrain filter grid/flex children and native date controls (`min-width: 0` through their full ancestor chain). Long single-token filters/chips wrap or otherwise expose the complete value without pushing the page wider. Keep all query controls and Apply visible. Preserve exact filter value access.
- Home cards become one column at narrow widths, with primary Timeline first; row-history and correlation forms stack and retain labels. Timeline rows keep operation/table, actor/row identity, and transaction/history actions readable without clipping. Transaction metadata becomes stacked labeled pairs; change cards stack `Before`/`After` under their labels. Long identifiers/values wrap at safe boundaries or use the full-value disclosure.
- Test short viewport heights separately so sticky header/navigation and focused controls do not cover the current task. Test actual browser-chrome 200% zoom as a separate proof from viewport widths and DPR/CSS scaling. This contract makes no claim that the zoom pass has already run.
- Keep ordinary input and primary-action controls at least 40px high. Compact visual controls may use the existing 32px role only when their actual pointer/touch target remains at least 40×40px; inline text links remain naturally keyboard/touch reachable. Preserve clear 3px-equivalent focus ring contrast using existing focus tokens. Do not remove outlines without an equal visible focus treatment.
- Preserve immediate feedback for frequent Apply, navigation, and disclosure interactions. Retain reduced-motion support. No decorative loading choreography or delayed action animation.

## Theme and Overlay Behavior

Preserve Light, Dark, and System preference selection and session persistence across reload and LiveView navigation. Validate the chosen preference separately from computed effective theme. Under System, changing the OS color scheme updates the served computed styles without a duplicate client-side preference source. Verify computed foreground/background/border colors on actual rendered elements, not only token declarations or theme classes.

All affected controls need semantic names, visible keyboard focus, keyboard and touch operation, predictable dismissal, and focus return. Cover visible-focus traversal through Home lookup, Timeline primary/advanced filters, Apply, result links, and transaction full-value disclosures. For shared overlapping toast/menu/drawer combinations, test that the top layer receives input, dismissal follows the existing Escape/outside-dismiss policy, focus returns to the invoking control, and repeated LiveView patches do not leave stale handlers or hidden focus targets. Phase 239 owns shared overlay behavior; complete row/drawer recovery journeys and page-specific history header overlap stay Phase 240.

## UI Considerations

The installed deterministic UI probe classified six surfaces with explicit author-reviewed kind unions (forms, lists, navigation, controls and content). All 35 applicable considerations are resolved with explicit acceptance criteria below; no auto-dismissals or unclassified rows. `239-UI-PROBE.json` records the computed result. These are required future checks, not execution passes. Copy is owned by the Copywriting Contract above.

| ID | Surface / state | Status | Verification | Acceptance criterion |
| --- | --- | --- | --- | --- |
| UC-239-01 | UI-239-HOME / empty | resolved | explicit | Empty lookup fields retain visible labels and supported entry points; no empty submission is represented as a successful investigation. |
| UC-239-02 | UI-239-HOME / loading | resolved | explicit | Home navigation and lookup activation retain their target identity and meaningful labels during pending navigation; no stale destination result is presented as complete. |
| UC-239-03 | UI-239-HOME / error | resolved | explicit | Invalid or unsupported lookup input has readable specific feedback; health-source failure remains unknown/unavailable rather than healthy. |
| UC-239-04 | UI-239-HOME / partial | resolved | explicit | A partially completed row lookup identifies the missing supported field without hiding the entered value; missing health/context data is not invented. |
| UC-239-05 | UI-239-HOME / overflow | resolved | explicit | Home shell, lookup controls and primary CTA stay within the page at narrow widths and actual 200% zoom; local evidence scrolling does not widen the document. |
| UC-239-06 | UI-239-HOME / long-text | resolved | explicit | Long lookup values and destination labels remain readable or have complete selectable access, with labels and activation controls reachable. |
| UC-239-07 | UI-239-TIMELINE / empty | resolved | explicit | A completed zero-result query uses the Copywriting Contract empty state with its applied filter summary and a usable recovery path. |
| UC-239-08 | UI-239-TIMELINE / loading | resolved | explicit | Starting query B from populated query A never labels A rows as B results; pending is observable and Apply labels/icons survive the patch. |
| UC-239-09 | UI-239-TIMELINE / error | resolved | explicit | A failed or denied applied query is distinct from an empty result; retry/allowed recovery retains the same query and host scope. |
| UC-239-10 | UI-239-TIMELINE / populated | resolved | explicit | A populated result list retains operation/table/actor/row/transaction identity and supports transaction navigation and existing incremental paging. |
| UC-239-11 | UI-239-TIMELINE / partial | resolved | explicit | Missing action/actor/context remains explicitly unrecorded where accurate; applying partial supported filters uses the allowlisted query without widening host scope. |
| UC-239-12 | UI-239-TIMELINE / overflow | resolved | explicit | The 232-character correlation filter does not produce page overflow; date inputs, filters, chips, Apply and result actions remain reachable. |
| UC-239-13 | UI-239-TIMELINE / zero-one-many | resolved | explicit | Zero, one and multi-page result scenarios render truthful counts and paging availability; changing query resets its cursor and old rows. |
| UC-239-14 | UI-239-TIMELINE / long-text | resolved | explicit | Long applied-filter values and row identifiers wrap or disclose their complete authorized value while retaining the applied query. |
| UC-239-15 | UI-239-TRANSACTION / empty | resolved | explicit | A found transaction with no changes is distinct from not-found, denied and failed retrieval; absent data is not called pruned without evidence. |
| UC-239-16 | UI-239-TRANSACTION / loading | resolved | explicit | While a transaction navigation/read is pending, visible transaction identity and its rows cannot be mismatched or announced completed early. |
| UC-239-17 | UI-239-TRANSACTION / error | resolved | explicit | Not-found/denied/failed transaction states preserve the server boundary and provide an appropriate return/retry path without leaking hidden context. |
| UC-239-18 | UI-239-TRANSACTION / populated | resolved | explicit | A populated transaction shows semantic summary before distinct change records with independently sourced actor/action/context and labeled Before/After values. |
| UC-239-19 | UI-239-TRANSACTION / partial | resolved | explicit | Missing optional action/context and null/absent/omitted/redacted field evidence remain distinguishable without fabricated attribution. |
| UC-239-20 | UI-239-TRANSACTION / overflow | resolved | explicit | Transaction metadata and change records stack at narrow widths/zoom; genuine local evidence scrolling does not create whole-document overflow. |
| UC-239-21 | UI-239-TRANSACTION / zero-one-many | resolved | explicit | Zero, one and multiple changes retain truthful counts, singular/plural labels, change identities and access to every rendered evidence value. |
| UC-239-22 | UI-239-TRANSACTION / long-text | resolved | explicit | Long unbroken identifiers/values preserve complete authorized bytes through wrapping or inline disclosure; field labels and actions remain usable. |
| UC-239-23 | UI-239-EXACT / loading | resolved | explicit | Native full-value disclosure responds synchronously to keyboard/touch activation without a remote loading dependency or Copy requirement. |
| UC-239-24 | UI-239-EXACT / error | resolved | explicit | Unavailable/redacted evidence discloses only its truthful authorized representation; no raw secret appears in visible text, DOM attributes or copy payloads. |
| UC-239-25 | UI-239-EXACT / overflow | resolved | explicit | Expanded values remain selectable within the page or a local evidence scroller at 320/375 widths and actual 200% zoom; focus remains visible. |
| UC-239-26 | UI-239-EXACT / long-text | resolved | explicit | An abbreviated ID/value or human timestamp expands to complete selectable authorized text; exact timestamps visibly include timezone/offset. |
| UC-239-27 | UI-239-THEME / empty | resolved | explicit | An absent saved theme preference uses the existing System default; the effective appearance follows the OS without inventing a second preference store. |
| UC-239-28 | UI-239-THEME / loading | resolved | explicit | Theme submission/navigation retains readable control labels and eventually reflects the persisted selection; pending submission is not a false success. |
| UC-239-29 | UI-239-THEME / error | resolved | explicit | Invalid or unauthorized theme submissions preserve existing server validation/auth behavior and do not claim a preference was saved. |
| UC-239-30 | UI-239-THEME / partial | resolved | explicit | System preference remains selected while effective appearance changes with the OS; reload and LiveView navigation preserve this distinction. |
| UC-239-31 | UI-239-THEME / long-text | resolved | explicit | System/Light/Dark labels and Apply theme remain readable, focusable and reachable at narrow widths and actual 200% zoom. |
| UC-239-32 | UI-239-OVERLAY / loading | resolved | explicit | Repeated LiveView patches while toast/menu/drawer states overlap retain names, top-layer input, dismissal and a valid focus target. |
| UC-239-33 | UI-239-OVERLAY / error | resolved | explicit | Error feedback remains readable and reachable without stealing focus from the active dialog; closing the top overlay restores the appropriate invoking control. |
| UC-239-34 | UI-239-OVERLAY / overflow | resolved | explicit | Shared overlays fit short/narrow viewports and scroll locally where needed; dismissal and focused controls are not covered by another UI layer. |
| UC-239-35 | UI-239-OVERLAY / long-text | resolved | explicit | Long toast/menu/drawer labels wrap without hiding dismissal or focused controls, and do not widen the underlying page. |

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

**Approval:** approved — 2026-10-09
