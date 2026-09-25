# Phase 198 — UI Review

**Audited:** 2026-09-09
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md exists)
**Screenshots:** Not captured. `localhost:3000` and `:5173` were unavailable; `:8080` returned HTTP 301 rather than the required application HTTP 200. All findings below are code-based.
**Scope:** Operator-surface pages touched by the phase's `@ui_form_policy` rollout, the export-status copy change, shared UI/style primitives, and the responsive/accessibility tests Phase 198 modified or used as verification.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Task-led labels and typed empty/error copy are strong, but shared failure copy tells operators to “Retry” without rendering a retry action. |
| 2. Visuals | 3/4 | Pages consistently establish an `h1` and reusable card/detail hierarchy, but shared empty states hard-code `h3`, producing skipped heading levels on several top-level page states. |
| 3. Color | 3/4 | The palette is centralized and accent use is restrained, but `paper` and `ink` tokens are self-referential in every theme block and therefore resolve invalidly if consumed. |
| 4. Typography | 2/4 | Eight named size roles and three weights exceed the abstract four-size/two-weight discipline; stress-fixture inline styles add raw `600`/`700` values outside the token contract. |
| 5. Spacing | 3/4 | Most layout uses a coherent 4px scale, but several component dimensions and paddings (`3px`, `10px`, `22px`, `44px`, `52px`) sit outside it. |
| 6. Experience Design | 2/4 | Error, empty, permission, and destructive-confirmation states are unusually thorough, but no production LiveView renders the shared loading state and retry guidance has no operable control. |

**Overall: 16/24**

---

## Top 3 Priority Fixes

1. **Make retry guidance operable** — Operators in stale, source-down, or fallback error states are told to retry but receive no control — add a required `:actions` slot or retry event/URL to `stale_banner/1` and `data_state/1`, then render a labeled button/link.
2. **Use real loading states in production flows** — Slow refreshes and filter submissions expose no explicit busy message even though `loading_state/1` exists — connect query/refresh state to `UI.loading_state`, `aria-busy`, and disabled controls on the data region.
3. **Let shared empty states choose the correct heading level** — A fixed `h3` skips from page `h1` to `h3` on empty pages — add a validated heading-level attribute or render an `h2` for page-level states and reserve `h3` for nested cards.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING — “Retry” is prose, not an action.** `UI.stale_banner/1` ends with `Retry.` and `UI.data_state/1` says `Retry, then check ...`, but neither component exposes or renders an action at [lib/threadline/operator_surface/ui.ex:603](/Users/jon/projects/threadline/lib/threadline/operator_surface/ui.ex:603), [lib/threadline/operator_surface/ui.ex:665](/Users/jon/projects/threadline/lib/threadline/operator_surface/ui.ex:665), or [lib/threadline/operator_surface/ui.ex:692](/Users/jon/projects/threadline/lib/threadline/operator_surface/ui.ex:692). A source search found no `phx-click="retry..."` or visible `Retry` control in the operator surface. Replace the imperative with an actual retry button/link, or name the concrete browser action if retry is intentionally external.
- **Positive evidence.** Copy is otherwise specific and task-led: the shell groups are “Investigate”, “Audit readiness”, and “Evidence & exports”; the home cards are action-oriented; export empty/failure states explain the next step at [lib/threadline/operator_surface/live/export_status_live.ex:244](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/export_status_live.ex:244) and [lib/threadline/operator_surface/live/export_status_live.ex:345](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/export_status_live.ex:345). Phase 198 also consolidated export status vocabulary into one tested owner at [lib/threadline/operator_surface/presentation.ex:362](/Users/jon/projects/threadline/lib/threadline/operator_surface/presentation.ex:362).
- **Positive evidence.** Generic production CTA searches found no “Submit”, “Click Here”, or bare “OK”. The only bare “Cancel” instances are intentionally rendered inside the stress fixture rather than a production workflow.

### Pillar 2: Visuals (3/4)

- **WARNING — shared empty-state semantics force a skipped heading level.** `UI.empty_state/1` always renders its title as `h3` at [lib/threadline/operator_surface/ui.ex:532](/Users/jon/projects/threadline/lib/threadline/operator_surface/ui.ex:532). Page-level empty states are used immediately below top-level page headers, including Exports at [lib/threadline/operator_surface/live/export_status_live.ex:245](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/export_status_live.ex:245), Actor activity, Timeline, Transaction, Retention, and Evidence. This weakens the document outline and makes the visual/semantic hierarchy dependent on where the component happens to be placed. Add a controlled `heading_level` API or separate page-level and nested empty-state primitives.
- **Positive evidence.** The common page header owns a single `h1`, detail headers deliberately use `h2`, and cards/sections descend from there. The shell includes a visible-on-focus skip link and labeled navigation groups at [lib/threadline/operator_surface/components/surface_header.ex:31](/Users/jon/projects/threadline/lib/threadline/operator_surface/components/surface_header.ex:31) and [lib/threadline/operator_surface/components/surface_header.ex:57](/Users/jon/projects/threadline/lib/threadline/operator_surface/components/surface_header.ex:57).
- **Limitation.** Focal-point balance, actual density, clipping, and icon rendering cannot be awarded a 4/4 from source alone; no screenshots were captured in this audit.

### Pillar 3: Color (3/4)

- **WARNING — two palette primitives are invalid self-references.** `--tl-color-paper: var(--tl-color-paper)` and `--tl-color-ink: var(--tl-color-ink)` occur in the base, explicit light, and system-light blocks at [lib/threadline/operator_surface/style.ex:61](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:61), [lib/threadline/operator_surface/style.ex:106](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:106), [lib/threadline/operator_surface/style.ex:232](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:232), and [lib/threadline/operator_surface/style.ex:284](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:284). They are currently unused by operator styles, so this is not a present blocker, but any future consumer will receive an invalid computed value. Define them from the brand constants (`#F7F9FC` and `#0F1728`) or remove them until needed.
- **Positive evidence.** Hardcoded color values are centralized in the theme token declarations; production rules overwhelmingly consume semantic variables. Direct usage counts in `style.ex` were: muted 69, border 59, text 47, raised surface 27, surface 25, danger 20, accent-strong 15, and base accent 6. That distribution keeps the bright accent visually scarce in source terms and uses semantic status colors rather than one overloaded primary.
- **Limitation.** The 60/30/10 balance and real contrast cannot be visually confirmed without a rendered capture, so this pillar does not receive 4/4.

### Pillar 4: Typography (2/4)

- **WARNING — the type scale is broader than the abstract standard.** The shared style declares eight named roles: 12, 13, 13, 14, 15, 16, 20, 24, and 32px (`xs`, `sm`, `dense`, `label`, `ui`, `body`, `heading`, `title`, `display`) at [lib/threadline/operator_surface/style.ex:34](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:34). Even treating `sm` and `dense` as one numeric size leaves eight distinct numeric sizes. Consolidate near-duplicate 13/14/15px roles and document a smaller semantic ladder.
- **WARNING — fixture markup bypasses the weight tokens.** The system defines 400/500/600 tokens at [lib/threadline/operator_surface/style.ex:47](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:47), but stress examples embed raw `font-weight: 600` and `700`, including [lib/threadline/operator_surface/live/stress_live.ex:237](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/stress_live.ex:237) and [lib/threadline/operator_surface/live/stress_live.ex:245](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/stress_live.ex:245). Because the stress surface is itself rendered UI, use the same variables or clearly isolate deliberately adversarial samples from the normal type audit.
- **Positive evidence.** Outside the stress fixtures, usage is strongly tokenized: the scan found 66 label-size uses, 20 body, 12 heading, 7 title, and 1 display; weight usage is concentrated on `regular`, `medium`, and `strong`.

### Pillar 5: Spacing (3/4)

- **WARNING — component metrics drift off the 4px spacing grid.** The declared spacing scale is consistently 4/8/12/16/20/24/32/40/48px at [lib/threadline/operator_surface/style.ex:22](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:22), but shared metrics introduce 3px status stripes, 10px compact row padding, 22px badge height, 44px header height, and 52px mobile header height at [lib/threadline/operator_surface/style.ex:148](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:148). Some are defensible optical/control dimensions, but they are undocumented exceptions to the declared grid. Either align them or explicitly separate “component metrics” from “layout spacing” in the token contract.
- **Positive evidence.** Page, panel, toolbar, grid, and responsive spacing largely consume `--tl-space-*`; the phone/tablet/desktop layers reuse those tokens rather than proliferating one-off padding literals at [lib/threadline/operator_surface/style.ex:4097](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:4097) and [lib/threadline/operator_surface/style.ex:4141](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:4141).
- **Positive evidence.** Responsive tables intentionally contain their 720px minimum inside an overflow wrapper, and many grid children set `min-width: 0`, reducing accidental viewport expansion.

### Pillar 6: Experience Design (2/4)

- **WARNING — the loading primitive is not connected to a production flow.** `UI.loading_state/1` provides `role="status"`, `aria-busy="true"`, a spinner, and text at [lib/threadline/operator_surface/ui.ex:575](/Users/jon/projects/threadline/lib/threadline/operator_surface/ui.ex:575), but searches across all production `*_live.ex` pages and `row_history_component.ex` found zero calls. Its only rendered exercise is the stress fixture. Wire it to refresh/filter/query lifecycles so users receive explicit progress, not just delayed replacement content.
- **WARNING — retry recovery is incomplete.** The non-operable retry text described under Copywriting also degrades task recovery: the typed `:source_down` and fallback error states identify the problem but provide no keyboard-focusable recovery control.
- **Positive evidence.** State taxonomy is otherwise excellent: loading, no-data, unauthorized, source-down, redacted, pruned, and fallback error states have distinct roles, icons, and copy at [lib/threadline/operator_surface/ui.ex:634](/Users/jon/projects/threadline/lib/threadline/operator_surface/ui.ex:634). Page-specific empty states are present across the touched surfaces.
- **Positive evidence.** Destructive retention pruning uses a modal, explicit irreversible consequence copy, type-to-confirm input, server-side revalidation, and a danger action at [lib/threadline/operator_surface/live/retention_history_live.ex:276](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/retention_history_live.ex:276). Focus-visible rules cover buttons, links, form controls, and summaries; reduced-motion overrides are centralized at [lib/threadline/operator_surface/style.ex:4455](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:4455). Phase 198's focused row-history regression also records repeated focus, dialog-semantics, non-obscuration, and overflow coverage.

---

## Files Audited

- `lib/threadline/operator_surface/ui.ex`
- `lib/threadline/operator_surface/style.ex`
- `lib/threadline/operator_surface/presentation.ex`
- `lib/threadline/operator_surface/components/surface_header.ex`
- `lib/threadline/operator_surface/live/actor_live.ex`
- `lib/threadline/operator_surface/live/coverage_live.ex`
- `lib/threadline/operator_surface/live/evidence_live.ex`
- `lib/threadline/operator_surface/live/export_status_live.ex`
- `lib/threadline/operator_surface/live/policy_redaction_live.ex`
- `lib/threadline/operator_surface/live/retention_history_live.ex`
- `lib/threadline/operator_surface/live/row_history_live.ex`
- `lib/threadline/operator_surface/live/row_history_component.ex`
- `lib/threadline/operator_surface/live/start_live.ex`
- `lib/threadline/operator_surface/live/stress_live.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/live/transaction_live.ex`
- `test/threadline/operator_surface/ui_form_policy_contract_test.exs`
- `test/threadline/operator_surface/copy_contract_test.exs`
- `test/threadline/operator_surface/presentation_test.exs`
- `examples/threadline_phoenix/e2e/playwright.config.ts`
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts`
- `examples/threadline_phoenix/e2e/tests/register.spec.ts`
- Phase 198 plans, summaries, `198-CONTEXT.md`, `198-UAT.md`, and the row-history regression audit.

Registry audit skipped: `components.json` is absent, so shadcn/third-party registry checks do not apply.
