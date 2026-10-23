---
phase: "243"
slug: "integrated-verification-and-review-preview"
status: draft
shadcn_initialized: false
preset: none
created: "2026-10-11"
---

# Phase 243 — UI Design Contract

> Execution-time visual and interaction gate for the already-approved bounded fixes. This contract does not authorize a new UI design or expand the approved review batch.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual, private Phoenix/HEEx UI system |
| Preset | Not applicable |
| Component library | Existing private `Threadline.OperatorSurface.UI` components |
| Icon library | Existing inline `Threadline.OperatorSurface.Components.Icon` |
| Font | Existing Geist with Inter/system fallbacks; IBM Plex Mono stack for identifiers and commands |

Reuse existing Threadline tokens, shell, routes, private HEEx components, semantic status styles, and page-specific CSS. Do not add components, packages, registries, or a new palette. Preserve Light, Dark, and System appearance. The current phase scope is limited to policy refresh spacing and plain-language unreadable-state heading, Evidence footer spacing and reachability, established shell/theme/responsive/accessibility behavior across eleven routes, and the DR-243-01 drawer-title carry-forward.

Keep the existing route title and primary content card as each page's visual anchor. On Redaction policy, the posture card is the primary review object, with schema and refresh controls secondary; on Evidence, the subject card leads and its footer links remain secondary. This records the current hierarchy without introducing a redesign.

## Component Inventory

Enumerated by `rg -n '^\s*def [a-z][a-z0-9_]*\(assigns\)' lib/threadline/operator_surface/ui --glob '*.ex' | wc -l` — 49 private UI components — `threadline@1.0.1` — 2026-10-11.

This is a non-exhaustive set of known-good private primitives, not a closed allowlist. Reuse suitable existing components; this phase requires no new component.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `shell/1`, `page_header/1` | `Threadline.OperatorSurface.UI.Page` | Preserve the established shared shell and route hierarchy. |
| `button/1`, `link/1` | `Threadline.OperatorSurface.UI.Actions` | Preserve existing distinction between mutation and navigation. |
| `data_table/1`, `empty_state/1`, `error_state/1`, `loading_state/1` | `Threadline.OperatorSurface.UI.Data` | Retain existing truthful data states. |
| `badge/1`, `alert/1`, `card/1`, `stack/1`, `cluster/1`, `ref/1`, `full_value/1` | `Threadline.OperatorSurface.UI.Display` | Keep status and exact references readable. |
| Existing overlay primitives | `Threadline.OperatorSurface.UI.Overlay` | Preserve drawer, toast, and focus behavior. |
| `icon/1` | `Threadline.OperatorSurface.Components.Icon` | Use the installed inline icon set. |

## Spacing Scale

Use existing 4px-root Threadline spacing tokens for changed layout. Do not restyle unrelated routes or normalize untouched components.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Compact inline/icon gaps |
| sm | 8px | Compact controls and footer separation |
| md | 16px | Default card/control spacing and policy refresh-to-posture gap |
| lg | 24px | Section rhythm |
| xl | 32px | Major content groups |
| 2xl | 48px | Page-level breaks |
| 3xl | 64px | Large page-level separation where already used |

Exceptions: existing borders and status stripes are not spacing tokens. Evidence footer links retain the corrected 8px card-edge separation and at least 40px reachable height at widths up to 480px. The policy refresh action retains the corrected 16px gap before the posture card.

## Typography

Retain existing semantic roles and font stacks; use only these four sizes and two weights for phase-scoped UI.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Label and identifier | 14px | 400 | 1.4 |
| Body and controls | 16px | 400 | 1.5 |
| Section heading | 20px | 600 | 1.2 |
| Page title | 24px | 600 | 1.2 |

Use the existing mono stack for exact identifiers and timestamps. Wrap long text or retain its established local overflow behavior; do not shrink labels to fit.

## Color

Preserve existing semantic tokens and Light, Dark, and System themes. The 60/30/10 split describes hierarchy, not literal pixel measurement.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `var(--tl-color-bg)`; Dark `#0B1020`, Light `#F7F9FC` | Page canvas and broad background |
| Secondary (30%) | `var(--tl-color-surface)`; Dark `#141B2D`, Light `#FFFFFF` | Existing cards, navigation, tables, and raised surfaces |
| Accent (10%) | `var(--tl-color-accent)`; Dark `#4F8CFF`, Light `#1557C0` | Existing primary actions, meaningful links, active selection, and visible focus |
| Destructive | Existing `var(--tl-color-danger)` | Existing destructive actions only; no destructive UI is added |

Accent reserved for: existing primary actions, meaningful navigation, active selection, and keyboard focus. Status continues to use existing semantic tokens with text labels; color alone never conveys state. Do not add colors or alter the palette.

## Copywriting Contract

No new CTA, empty state, error state, or destructive action is introduced by this verification phase. Preserve the route-specific copy and operation state distinctions from Phases 241 and 242. The one scoped wording correction uses the exact plain-language heading `Could not inspect` while retaining the public `:could_not_introspect` status enum and its distinction from a missing deployment. Do not expose raw exceptions, redacted values, or imply authorization or operation completion from a client-side affordance.

| Element | Copy / contract |
|---------|-----------------|
| Primary CTA | No new CTA; keep existing route-specific action labels and behavior. |
| Empty state | Preserve existing route-specific empty copy; empty remains distinct from failed or unavailable reads. |
| Error state | Preserve existing actionable safe error copy; never convert a failed read into an empty or healthy result. |
| Unreadable policy heading | `Could not inspect`; keep public status `:could_not_introspect` unchanged. |
| Destructive confirmation | No new destructive action; retain the existing exact policy-name prune confirmation and full global-scope explanation. |

## Journey and Interaction Contract

| Surface | Required behavior |
|---------|-------------------|
| Eleven-route shell | Preserve Home, Timeline, Transaction, Row, History drawer, Actor, Coverage, Evidence, Exports, Redaction policy, and Retention policy routes and their established shared shell. Keep the degraded Timeline twin as a verification state. |
| Redaction policy | Keep the existing refresh action and schema scope. Maintain a 16px tokenized gap before the posture card. Use `Could not inspect` for unreadable inspection while preserving the `:could_not_introspect` public enum and missing/unreadable distinction. |
| Evidence footer | Keep existing links, accessible names, and destinations. At 320px, both links remain visible, in viewport, reachable, at least 40px high, and separated 8px from the card edge. |
| History drawer | Carry forward DR-243-01: the title's top line is obscured by the fixed header in the reviewed 1280px state while Close remains visible. Keep this as an explicit medium visual-clarity disposition and recheck it in Plan 05; do not broaden this bounded correction batch. |
| Auth, scope, and operation truth | Preserve host authorization, tenant scope, redaction, route behavior, operation status truth, and server-side guards. UI visibility or disabled state is never an authorization boundary. Do not imply queued work is complete or replay uncertain mutations after reconnect. |
| Keyboard and focus | Preserve semantic controls, visible high-contrast focus, keyboard/touch reachability, predictable dismissal, and focus return for existing overlays. Connection/status announcements remain polite and do not steal focus. |
| Motion and themes | Respect reduced motion and preserve Light, Dark, and System preference behavior across reload and LiveView navigation. |

## Responsive and Accessibility Floors

- Preserve the existing responsive and accessibility behavior across all eleven routes. Check 320px where applicable, 375px, 768px, 1280px, and actual browser tab zoom at 200% as separate conditions.
- Prevent document-level horizontal overflow. Existing genuinely two-dimensional tables may use contained local scrolling while preserving data access and primary controls.
- Preserve semantic names and relationships, readable validation, visible focus, keyboard and touch reachability, and status text that does not rely on color alone.
- Keep Evidence footer actions reachable at narrow width. Keep long values readable through wrapping or their existing deliberate local overflow affordance.
- Keep reduced-motion behavior; no transition may delay status clarity, focus restoration, or action availability.

## UI Considerations

> Probe scope is limited to Phase 243's corrected Evidence footer, Redaction refresh/posture presentation, and the carried-forward History drawer title. Other route states remain governed by their existing contracts and the full-shell verification plan.

Applicable state considerations resolved: 11 closed (2 explicit, 3 backstop, 6 dismissed), 0 unresolved.

| Category | Element | Status | Resolution / Reason |
|----------|---------|--------|---------------------|
| loading | Evidence footer links | dismissed | Fixed navigation links have no per-link in-flight state; destination loading is a route state covered separately. |
| error | Evidence footer links | dismissed | Footer links do not submit or load data; destination failures remain route states covered separately. |
| overflow | Evidence footer links | explicit | At 320 CSS px, both links stay visible and in-viewport, provide at least 40px reachable height, and retain an 8px card-edge gap; the focused Playwright check and setup checks passed. |
| long-text | Evidence footer links | dismissed | Labels are fixed and short, with no variable text; accessible names and destinations remain unchanged. |
| loading | Redaction refresh action | dismissed | This bounded correction adds no separate asynchronous refresh presentation; the existing LiveView action and returned inspection state remain authoritative. |
| error | Redaction refresh action | explicit | Unreadable inspection renders “Could not inspect,” retains public `:could_not_introspect`, remains distinct from missing deployment, and does not preserve stale match assurance after failed refresh; mounted tests cover these semantics. |
| long-text | Redaction refresh action | dismissed | The control uses a fixed short label; no variable text enters its label. |
| overflow | Redaction posture summary | backstop | Review the fresh candidate capture for clipping or horizontal overflow at final responsive widths; retain the 320px focused check and 16px refresh-to-posture gap as evidence, and record any limitation. |
| long-text | Redaction posture summary | backstop | Check dynamic schema, table, and status values for readable wrapping or their existing local full-value treatment; do not shrink text or hide values. |
| overflow | History drawer title | backstop | Recheck DR-243-01 in the fresh History drawer capture, record whether the title is clipped by the fixed header and its impact, and retain the medium carry-forward disposition if it persists. |
| long-text | History drawer title | dismissed | The reviewed heading is fixed short copy; the finding concerns overlay placement beneath the fixed header, not variable or unusually long text. |

## Evidence Status and Limits

Plan 04 records focused post-fix observations on source HEAD `af1a3369f3a0061707283fab18c7c2663d2b1893`: the Evidence footer and Redaction policy were checked at 320px; the Light/System lane covered responsive states; and real desktop tab zoom factor 2 reported a 640px CSS viewport, DPR 2, and zero horizontal overflow. These are focused condition checks, not the final exact-candidate full-shell confirmation. The Plan 04 matched eleven-route full-shell comparison is labeled limited because baseline OS and generated assets/fixtures differ; it is dark-only at 1280/768/375 and tab zoom 1. Plan 05 owns fresh receipt-bound full-shell captures and final finding confirmation after all source changes.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable — Phoenix/HEEx private UI system; no external registry or package is used — 2026-10-11 |

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** Approved 2026-10-11 (7/7 PASS; no recommendations).
