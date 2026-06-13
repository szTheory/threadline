# Phase 166 UI-SPEC - Operator Surface Light Theme Mechanism

**Phase:** 166 - unfreeze-token-lane-mechanism
**Status:** Approved for planning
**Created:** 2026-06-12

## Visual Contract

- Dark remains the base `.threadline-ui` lane and must be visually byte-stable except for replacing the shell-nav active inset with a token carrying the same dark value.
- Light is an additive value lane on the same semantic token names; it is not a new component class system and does not introduce per-component light selectors in this phase.
- System mode uses the same light values only under `@media (prefers-color-scheme: light)`.
- Native controls and scrollbars must follow the active surface mode through scoped `color-scheme` on `.threadline-ui`.

## Light Lane Token Targets

Use these Phase 166 values unless a source test proves a contrast failure inside this phase:

- Base: `bg #F7F9FC`, `surface #FFFFFF`, `surface-raised #EEF3FA`, `surface-hover #E7ECF4`, `surface-selected #DDE8FF`.
- Glass/overlay: `surface-tint rgba(255, 255, 255, 0.92)`, `surface-tint-strong rgba(247, 249, 252, 0.96)`, `backdrop rgba(15, 23, 40, 0.42)`.
- Borders/focus: `border #C9D3E2`, `border-strong #A7B4C8`, `border-focus #1557C0`, `focus-ring 0 0 0 3px rgba(21, 87, 192, 0.22), 0 0 0 1px var(--tl-color-border-focus)`.
- Text: `text #0F1728`, `muted #3B4762`, `muted-soft #73819C`.
- Accent: `accent #1557C0`, `accent-strong #0E459B`, `accent-soft rgba(21, 87, 192, 0.12)`, `accent-wash rgba(21, 87, 192, 0.06)`, `accent-border rgba(21, 87, 192, 0.28)`, `accent-inset rgba(21, 87, 192, 0.16)`, `on-accent #FFFFFF`.
- Signal: `signal #0F8F85`, `signal-bg rgba(15, 143, 133, 0.12)`, `signal-border rgba(15, 143, 133, 0.30)`.
- Ink/paper: `ink #0F1728`, `paper #F7F9FC`.
- Status: `danger #A33434`, `danger-bg rgba(163, 52, 52, 0.10)`, `danger-border rgba(163, 52, 52, 0.28)`, `warning-text #7A5400`, `warning-bg rgba(122, 84, 0, 0.12)`, `warning-border rgba(122, 84, 0, 0.30)`, `success-text #136C47`, `success-bg rgba(19, 108, 71, 0.12)`, `success-border rgba(19, 108, 71, 0.30)`, `info-text #1557C0`, `info-bg rgba(21, 87, 192, 0.10)`, `info-border rgba(21, 87, 192, 0.28)`, `neutral-bg rgba(59, 71, 98, 0.10)`, `neutral-text #3B4762`, `neutral-border #C9D3E2`.
- Brand/shadow: `brand-rail #0F1728`, `shadow-subtle 0 1px 2px rgba(15, 23, 40, 0.08), 0 1px 3px rgba(15, 23, 40, 0.06)`, `shadow-popover 0 10px 28px rgba(15, 23, 40, 0.18)`, `shadow-raised 0 18px 48px rgba(15, 23, 40, 0.24)`.

## Interaction Contract

- Focus-visible selectors remain unchanged and continue to use `--tl-focus-ring`.
- Status chips, alerts, op badges, redaction rows, policy drift rows, and job error states continue to reference existing status tokens; this phase changes values, not per-component markup.
- The shell-nav active inset uses `--tl-color-accent-inset` in both modes.
- No visible in-app text, toggle, segmented control, or settings UI is introduced for theme selection.

## Acceptance

- Every root surface has `data-tl-theme`.
- Default mounts render `data-tl-theme="dark"`.
- A host mount with `theme: :system` renders `data-tl-theme="system"` on the dead render.
- Light/system CSS exists in the source and is scoped to `.threadline-ui`.
- The string `theme-toggle` remains absent from `style.ex`.
