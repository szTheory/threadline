---
phase: 141-motion-micro-animation
artifact: motion-inventory
status: source-contract
requirements: [POLISH-MOTION]
---

# Phase 141 Motion Inventory

This inventory is the source-testable contract for Threadline operator-surface motion. It covers shipped CSS animations and non-trivial transition families in `lib/threadline/operator_surface/style.ex`; it does not authorize new animation libraries, route changes, layout redesign, or broad responsive work.

## Locked Motion Scale

| token_or_keyframe | contract |
|---|---|
| `--tl-motion-fast` | `120ms` |
| `--tl-motion-base` | `180ms` |
| `--tl-motion-slow` | `240ms` |
| `--tl-motion-stagger` | `40ms` |
| `--tl-motion-distance-sm` | `8px` |
| `--tl-motion-distance-md` | `16px` |
| `--tl-ease-standard` | `cubic-bezier(0.2, 0, 0, 1)` |
| `--tl-ease-out` | `cubic-bezier(0.16, 1, 0.3, 1)` |
| `--tl-transition-fast` | `var(--tl-motion-fast) var(--tl-ease-standard)` |
| `tl-drawer-in` | Drawer/subview entry only; transform + opacity. |
| `tl-rise-in` | Low-frequency item entry only; transform + opacity. |
| `tl-thread-draw` | Signature Signal Cyan proof/progression thread only; transform scale. |
| `tl-fade-in` | Low-frequency evidence assembly only; opacity. |
| `tl-copy-pulse` | Copy success feedback only; box-shadow pulse. |

Reduced-motion behavior is centralized in `@media (prefers-reduced-motion: reduce)`: `.threadline-ui *`, `.threadline-ui *::before`, `.threadline-ui *::after`, and `.tl-policy__row::details-content` collapse transition and animation duration to `1ms`, set animation delay to `0ms`, force one iteration, use `scroll-behavior: auto`, and reset `.tl-button:active` transform.

## Inventory

| id | selector_or_keyframe | surface | trigger | persona_jtbd | rationale | token | properties | frequency | reduced_motion | source | status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| M-01 | `.threadline-ui a` | Global scoped links | Hover/focus affordance on navigable text or button-styled anchors | P1/P2/P5: understand which scoped text can be followed without scanning for browser-default link styling | Keeps link affordance legible inside the dark operator surface while staying token-governed across host apps | `--tl-transition-fast` | color, background-color, border-color, box-shadow, transform | Frequent, user-triggered | `prefers-reduced-motion` collapses transition duration through `.threadline-ui *` | `style.ex` `.threadline-ui a` | keep |
| M-02 | `.tl-topbar .tl-topbar__nav-item` | Header navigation | Hover and active-route changes | P1/P4: keep current operator context and destination changes readable during triage | Restrained color/background/border/shadow transition communicates navigation state without moving layout | `--tl-transition-fast` | color, background-color, border-color, box-shadow | Frequent, user-triggered | `prefers-reduced-motion` collapses transition duration through `.threadline-ui *` | `style.ex` `.tl-topbar .tl-topbar__nav-item` | keep |
| M-03 | `.tl-home__card` | Operator Home launcher cards | Home surface mount | P2/P5: orient quickly to the three main operator jobs after landing | Low-distance rise introduces the launcher set as a task surface rather than a decorative hero | `tl-rise-in`, `--tl-motion-base`, `--tl-ease-out`, `--tl-motion-stagger` | opacity, transform | Low, page entry | `prefers-reduced-motion` collapses animation duration and delays through `.threadline-ui *` | `style.ex` `.tl-home__card` | keep |
| M-04 | `.tl-home__card--primary::before` | Operator Home primary card | Primary card mount | P2/P5: recognize the front-door path into the operator surface | Signature `tl-thread-draw` marks the primary entry thread; the documented `120ms` delay lets the card establish before the proof line draws | `tl-thread-draw`, `--tl-motion-slow`, `--tl-ease-out`, documented `120ms` signature delay | transform | Low, page entry | `prefers-reduced-motion` collapses animation duration and resets delay to `0ms` through `.threadline-ui *::before` | `style.ex` `.tl-home__card--primary::before` | justify |
| M-05 | `.tl-toolbar__control`, `.tl-control` | Filter and form controls | Hover, focus, disabled-state changes | P1/P2/P4: see active input focus and available filters while scanning dense controls | Border/background/shadow transitions make keyboard and pointer state clear without animating position | `--tl-transition-fast` | border-color, box-shadow, background-color | Frequent, user-triggered | `prefers-reduced-motion` collapses transition duration through `.threadline-ui *` | `style.ex` `.tl-toolbar__control, .tl-control` | keep |
| M-06 | `.tl-button` | Buttons and anchor buttons | Hover, active press, disabled/busy changes | P1/P2/P4: confirm command affordance and press feedback without delaying action | Token-backed color/surface/shadow transitions and a tiny active transform clarify action state; transform reset prevents reduced-motion press movement | `--tl-transition-fast` | color, background-color, border-color, box-shadow, transform | Frequent, user-triggered | `prefers-reduced-motion` collapses transition duration and `.tl-button:active` resets transform to `none` | `style.ex` `.tl-button` | keep |
| M-07 | `.tl-change` | Timeline/change rows | Hover or row emphasis state changes | P1/P4: maintain row scan density while still showing the current row target | Background/shadow transition is restrained and intentionally avoids entrance animation on high-frequency timeline paging | `--tl-transition-fast` | background-color, box-shadow | Frequent, user-triggered | `prefers-reduced-motion` collapses transition duration through `.threadline-ui *` | `style.ex` `.tl-change` | keep |
| M-08 | `.tl-policy__summary` | Policy drift details summary | Hover on expandable drift row | P3/P4: find which policy row can expand for configured-vs-deployed evidence | Background transition clarifies expandability without animating the dense row contents | `--tl-transition-fast` | background-color | Medium, user-triggered | `prefers-reduced-motion` collapses transition duration through `.threadline-ui *` | `style.ex` `.tl-policy__summary` | keep |
| M-09 | `.tl-policy__row::details-content` | Policy drift details content | Details row open/close | P3: compare configured and deployed values without a jarring snap when drilling into evidence | This is the rare layout-affecting exception; it is scoped to details expansion and explicitly covered by reduced motion | `--tl-motion-base`, `--tl-ease-out` | block-size, content-visibility | Medium, user-triggered | `prefers-reduced-motion` includes `.tl-policy__row::details-content` and collapses transition duration to `1ms` | `style.ex` `.tl-policy__row::details-content` | justify |
| M-10 | `.tl-subview` | Row-history/detail drawer | Subview opens | P1/P4: preserve spatial relationship when a drawer opens from the current row/context | Drawer-in motion makes the context shift legible while remaining transform/opacity-only | `tl-drawer-in`, `--tl-motion-base`, `--tl-ease-standard`, `--tl-motion-distance-md` | opacity, transform | Medium, user-triggered | `prefers-reduced-motion` collapses animation duration through `.threadline-ui *` | `style.ex` `.tl-subview` | keep |
| M-11 | `#retention-runs > tr` | Retention prune run table | New prune-run row inserted | P4: notice the newly confirmed retention action without re-animating the whole table | A single low-frequency row rise confirms a consequential operation; unchanged rows stay still | `tl-rise-in`, `--tl-motion-base`, `--tl-ease-out` | opacity, transform | Low, event-triggered | `prefers-reduced-motion` collapses animation duration through `.threadline-ui *` | `style.ex` `#retention-runs > tr` | keep |
| M-12 | `.tl-subview__timeline > *` | Drawer timeline/history items | Row-history drawer content mounts | P1/P3: read the drawer as a continued evidence thread instead of an unrelated panel | Staggered rise gives order to low-frequency history items while using the same rise token contract | `tl-rise-in`, `--tl-motion-base`, `--tl-ease-out`, `--tl-motion-stagger` | opacity, transform | Medium, user-triggered | `prefers-reduced-motion` collapses animation duration and delays through `.threadline-ui *` | `style.ex` `.tl-subview__timeline > *` | keep |
| M-13 | `.tl-record-list > .tl-record-card` | Evidence proof record lists | Proof records assemble on page/subview mount | P3: see proof cards arrive as one evidence group without drawing attention from record content | Opacity-only fade is the least intrusive way to assemble low-frequency proof records | `tl-fade-in`, `--tl-motion-base`, `--tl-ease-out` | opacity | Low, page or panel entry | `prefers-reduced-motion` collapses animation duration through `.threadline-ui *` | `style.ex` `.tl-record-list > .tl-record-card` | keep |
| M-14 | `#transactions-list > .tl-change` | Actor transactions list | Actor transaction rows assemble on entry | P1/P3: distinguish low-frequency actor transaction reveal from the high-frequency timeline stream | Scoped fade prevents shared `.tl-change` timeline paging from animating while still clarifying this assembled list | `tl-fade-in`, `--tl-motion-base`, `--tl-ease-out` | opacity | Low, page or panel entry | `prefers-reduced-motion` collapses animation duration through `.threadline-ui *` | `style.ex` `#transactions-list > .tl-change` | keep |
| M-15 | `.tl-copy` | Copy ID affordance | Hover/focus state before copying | P1/P2/P3: identify copyable IDs and refs without extra labels | Token-backed border/color transition keeps the small chip discoverable without motion-heavy decoration | `--tl-transition-fast` | color, border-color, background-color, box-shadow | Frequent, user-triggered | `prefers-reduced-motion` collapses transition duration through `.threadline-ui *` | `style.ex` `.tl-copy` | keep |
| M-16 | `.tl-copy.is-copied` | Copy ID success feedback | Embedded JS toggles copied state after successful copy | P1/P2/P3: get immediate confirmation that a row/ref ID copied | `tl-copy-pulse` is a one-shot success pulse; the static `::after` copied chip preserves confirmation when motion is reduced | `tl-copy-pulse`, `--tl-motion-base`, `--tl-ease-out` | box-shadow | Medium, user-triggered success | `prefers-reduced-motion` collapses animation duration; static `.tl-copy.is-copied::after` remains visible | `style.ex` `.tl-copy.is-copied` | keep |
| M-17 | `.tl-journey-rail::before` | Proof/adoption journey rail | Journey/proof rail enters | P3/P5: read the adoption/proof steps as one connected progression | Signature `tl-thread-draw` is justified here as proof/progression connective tissue, not generic decoration | `tl-thread-draw`, `--tl-motion-slow`, `--tl-ease-out`, documented `120ms` signature delay | transform | Low, page or panel entry | `prefers-reduced-motion` collapses animation duration and resets delay to `0ms` through `.threadline-ui *::before` | `style.ex` `.tl-journey-rail::before` | justify |
| M-18 | `.tl-policy__summary::before` | Policy drift summary chevron | Details row open/close | P3/P4: see expanded/collapsed state while comparing drift rows | Small transform transition communicates disclosure state and is scoped to one chevron | `--tl-transition-fast` | transform | Medium, user-triggered | `prefers-reduced-motion` collapses transition duration through `.threadline-ui *::before` | `style.ex` `.tl-policy__summary::before` | keep |
| M-19 | `.tl-policy__success::after` | Policy drift all-clear message | All redaction drift clears to zero | P3: confirm trust-restored proof state after consequential redaction validation | Signature `tl-thread-draw` is justified as earned proof completion and mirrors the journey/progression motif | `tl-thread-draw`, `--tl-motion-slow`, `--tl-ease-out`, documented `120ms` signature delay | transform | Low, state-triggered success | `prefers-reduced-motion` collapses animation duration and resets delay to `0ms` through `.threadline-ui *::after` | `style.ex` `.tl-policy__success::after` | justify |

## Non-Goals

- No new keyframes beyond `tl-drawer-in`, `tl-rise-in`, `tl-thread-draw`, `tl-fade-in`, and `tl-copy-pulse`.
- No `transition: all`.
- No JavaScript animation library markers or package installs.
- No broad responsive, route, IA, screenshot, or production CSS changes in Plan 01.
