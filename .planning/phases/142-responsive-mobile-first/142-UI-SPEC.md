---
phase: 142
slug: responsive-mobile-first
status: draft
shadcn_initialized: false
preset: none
created: 2026-06-04
---

# Phase 142 - UI Design Contract

> Responsive design contract for the Threadline operator surface. Preserve the existing dark operator-console visual language; this phase changes layout behavior, scroll ownership, and breakpoint consistency only.

## Design System

| Property | Value |
|----------|-------|
| Tool | none |
| Preset | not applicable |
| Component library | Phoenix LiveView components plus scoped operator-surface CSS |
| Icon library | existing operator-surface primitives only |
| Font | Geist/Inter/system UI for interface text; IBM Plex Mono/JetBrains Mono/ui-monospace for code and IDs |

Source: `lib/threadline/operator_surface/style.ex`. No shadcn, Tailwind, or third-party registry is part of this phase.

## Breakpoint Scale

Tokenize these names in source comments/custom properties and enforce literal media-query use with source-contract tests, since CSS custom properties cannot be used directly in standard media queries.

| Token | Width | Contract |
|-------|-------|----------|
| `phone` | `0-767px` | Default mobile-first layout. Must pass at `375px`. |
| `tablet` | `768-1279px` | Wrapped medium layout. Must pass at `768px`. |
| `desktop` | `1280px+` | Dense operator layout. Must pass at `1280px`. |

Replace the current `481px` and `721px` layout layers with the named scale unless implementation proves a narrower compatibility layer is still required. If retained, any intermediate compatibility layer must be documented as internal and must not become an acceptance breakpoint.

## Spacing Scale

Keep the existing token scale and use multiples of 4 only.

| Token | Value | Usage |
|-------|-------|-------|
| `--tl-space-1` | `4px` | Inline gaps, compact affordances |
| `--tl-space-2` | `8px` | Nav/control gaps |
| `--tl-space-3` | `12px` | Compact row and toolbar padding |
| `--tl-space-4` | `16px` | Default panel padding |
| `--tl-space-6` | `24px` | Page and section padding |
| `--tl-space-8` | `32px` | Larger layout gaps |
| `--tl-space-12` | `48px` | Major offsets |

Exceptions: `--tl-hit-area` and primary controls stay at `40px` minimum. Do not introduce smaller mobile tap targets.

## Typography

Do not introduce new type sizes for responsive work.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | `14px` | `400` | `1.5` |
| Label/UI | `12px` or `13px` | `500` | `1.4` |
| Heading | `18px` | `600` | `1.2` |
| Display | `28px` | `600` | `1.15` |

Long IDs, references, commands, and values must wrap with existing mono/value primitives instead of forcing horizontal page overflow.

## Color

Keep the existing dark-only palette.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#0B1020` | Root background and page field |
| Secondary (30%) | `#141B2D`, `#1B253A` | Cards, panels, topbar, toolbar, rows |
| Accent (10%) | `#4F8CFF` | Active nav, selected segmented controls, focus border, primary links, primary CTA |
| Signal | `#4EDFD1` | Correlation, live trace, positive system-flow affordances only |
| Destructive | `#FF8585` | Destructive actions and delete/error status only |

Accent reserved for: active route state, selected controls, focus-visible ring/border, primary links, and primary action emphasis. Do not use accent as a general card/background wash.

## Responsive Components

### Tables And Cards

| Width | Required behavior |
|-------|-------------------|
| `375` | `.tl-table--responsive` renders as labelled card rows; `thead` hidden; each `td` exposes `data-label` via `::before`; no root overflow. |
| `768` | Card rows may gain roomier spacing/wrapping, but controls and labels still wrap inside the viewport. |
| `1280` | Restore true table semantics with visible header, table rows/cells, and `--tl-table-min-width` inside `.tl-table-wrap`. |

`.tl-table-wrap` is an allowed internal horizontal scroll owner for desktop-style tables only. It must not cause `document.documentElement.scrollWidth - clientWidth > 1`.

### Toolbar And Filters

| Width | Required behavior |
|-------|-------------------|
| `375` | `.tl-toolbar__form` stacks vertically; fields and controls are `width: 100%`; action groups wrap and remain visible before data rows when they are primary filters. |
| `768` | Fields and action groups wrap into rows; datetime/select controls keep usable intrinsic width without pushing root overflow. |
| `1280` | Toolbar may become sticky and compact; actions align right; secondary groups can regain left divider. |

Filter summaries must remain visible on Timeline before dense row content. Buttons must keep existing labels such as `Open Timeline`, `Open row history`, `Download export`, and `Run retention prune`.

### Drawers And Subviews

| Width | Required behavior |
|-------|-------------------|
| `375` | `.tl-subview` is full viewport width, scrolls internally, and keeps header/close controls reachable. Values, copy controls, chips, and row-history timelines must wrap or clip internally. |
| `768` | Drawer remains usable without clipping primary controls; content may shift to a two-column grid only if both columns fit. |
| `1280` | Right-side drawer may use `width: min(--tl-drawer-width, 100vw)` below sticky topbar. |

Subview backdrop and drawer motion must preserve Phase 141 reduced-motion behavior.

### Navigation

`.tl-topbar__nav` owns compact horizontal nav scroll. It must remain visible and reachable on Home, Timeline, Coverage, Transaction, Row History, Actor, Evidence, Redaction, Retention, and Exports routes.

Allowed scroll owner: `.tl-topbar__nav`.

Forbidden nav outcomes: hiding group labels on mobile, trapping nav links offscreen without internal scroll, moving scroll ownership to the document/root, or replacing the current IA.

## Root Overflow Rule

At every acceptance viewport, the root document must satisfy:

```text
document.documentElement.scrollWidth - document.documentElement.clientWidth <= 1
```

Allowed internal scroll owners:

| Selector | Allowed reason |
|----------|----------------|
| `.tl-topbar__nav` | Compact operator navigation reachability |
| `.tl-table-wrap` | Contained desktop-style table overflow |
| `.tl-subview` | Full-height drawer content scrolling |
| `pre`, code/value containers | Long command or value inspection when wrapping is not semantically correct |

All other horizontal overflow is a regression unless explicitly documented in this UI-SPEC by a later amendment.

## Acceptance Matrix

Routes in scope:

`/audit`, `/audit/timeline`, `/audit/coverage`, seeded `/audit/transactions/:id`, seeded `/audit/rows/:table/:record_id`, seeded `/audit/actors/:type/:id`, `/audit/evidence`, `/audit/policy/redaction`, `/audit/policy/retention`, `/audit/exports`.

| Viewport | Acceptance checks |
|----------|-------------------|
| `375 x 812` | Viewport meta present; no root horizontal overflow; topbar groups and enabled destinations reachable; toolbar/filter controls stack; responsive tables render as labelled cards; drawers fit full width; primary controls visible. |
| `768 x 900` | No root horizontal overflow; toolbar/filter rows wrap; cards/tables remain readable; nav remains internally scrollable only if needed; drawers do not clip controls or values. |
| `1280 x 900` | No root horizontal overflow; desktop table semantics restored; sticky toolbar/topbar behavior preserved; drawer uses desktop right-side width; dense evidence/policy/export states remain scannable. |

Verification should use computed overflow, visibility, route reachability, and key control checks. Screenshot-diff baselines are out of scope for Phase 142.

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | Preserve existing route-specific verbs, including `Open Timeline`, `Open row history`, `Download export`, and `Run retention prune`. |
| Empty state heading | Preserve existing empty-state headings for each screen. |
| Empty state body | Preserve existing next-step copy; responsive work must not add explanatory UI copy. |
| Error state | Preserve existing problem-plus-next-step copy. |
| Destructive confirmation | `Run retention prune`: `Confirm retention prune. This permanently deletes older audit records; review the latest completed run and failure count first.` |

## Forbidden Patterns

- No broad visual redesign, new theme, light mode, new palette, new product workflow, or IA change.
- No document/root horizontal scrolling as a fix for cramped content.
- No hiding topbar destinations, group labels, primary controls, or destructive context on phones.
- No bespoke one-off table overflow when `.tl-table--responsive` or `.tl-table-wrap` applies.
- No fixed widths wider than the viewport unless contained by an approved internal scroll owner.
- No ad-hoc breakpoint literals outside the tokenized scale and source-contract tests.
- No screenshot-diff infrastructure, final accessibility sweep, or broad ARIA/focus audit in this phase.
- No edits to unrelated Phase 136/137 artifacts.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable |

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
