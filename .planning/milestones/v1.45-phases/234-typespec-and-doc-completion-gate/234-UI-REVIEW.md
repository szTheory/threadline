# Phase 234 — UI Review

**Audited:** 2026-10-06
**Baseline:** Abstract six-pillar standards; no `234-UI-SPEC.md` exists. The phase primarily changes typespecs, docs, and their contract tests, so the operator surface was inspected as the shipped UI context rather than treating the phase as a visual redesign.
**Screenshots:** Not captured — localhost:8080 answered, but Playwright capture failed at desktop (1440×900), mobile (375×812), and tablet (768×1024). Visual findings are code-derived.
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Domain-specific empty-state language is present; stress-demo controls include generic “Cancel” labels. |
| 2. Visuals | 2/4 | Tokenized hierarchy and responsive rules exist, but screenshots could not verify rendering and stress story controls use inline presentation styles. |
| 3. Color | 2/4 | Semantic palettes are defined, but `ink` and `paper` tokens self-reference and are invalid; one stress fixture hardcodes an off-palette amber. |
| 4. Typography | 2/4 | Nine declared font-size tokens and three weights exceed the abstract scale guidance of at most four sizes and two weights. |
| 5. Spacing | 3/4 | Most layout uses spacing tokens; the scale includes custom 20px/40px steps and isolated raw values, so consistency is imperfect. |
| 6. Experience Design | 3/4 | Loading/error/empty states, focus styles, and reduced-motion support are present; interaction states were not captured, and this phase does not add UX-state coverage. |

**Overall: 15/24**

---

## Top 3 Priority Fixes

1. **WARNING — Repair cyclic `--tl-color-ink` and `--tl-color-paper` definitions** — consumers resolve to invalid custom-property values and lose intended foreground/background colors — assign concrete primitives in the dark and light token lanes and add a source contract preventing self-references.
2. **WARNING — Consolidate the type scale** — nine size tokens and three weights weaken hierarchy and add maintenance choices — retain a compact role-based scale (for example, body, label, heading, display) and map current component roles to it.
3. **WARNING — Move inline stress-story styling and raw amber into named component tokens/classes** — the stress showcase bypasses the shared visual system and permits accidental palette drift — create component variants using semantic tokens and validate all rendered foreground/background pairs.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING** — The primary operational empty states name the missing domain data, e.g. “No audited tables found” and “No row-level changes captured” ([coverage_live.ex](lib/threadline/operator_surface/live/coverage_live.ex:166), [transaction_live.ex](lib/threadline/operator_surface/live/transaction_live.ex:247)). This is clear and consistent with the brand’s plain, technical voice.
- **WARNING** — The stress-story UI has generic “Cancel” controls in simulated dialogs ([sections.ex](lib/threadline/operator_surface/live/stress_live/sections.ex:282)). Replace with a contextual action where the control actually dismisses or abandons a named operation. No broad “Submit” or “Click Here” pattern was found in the inspected operational screens.
- Phase 234’s docs/types changes are not UI copy changes; its summaries report docs build and contract verification, not visual copy acceptance.

### Pillar 2: Visuals (2/4)

- **WARNING** — The shell and control styles implement hierarchy, clear focus rings, and responsive layout ([02_base_shell.css](lib/threadline/operator_surface/style/02_base_shell.css:43), [04_controls.css](lib/threadline/operator_surface/style/04_controls.css:494), [09_responsive.css](lib/threadline/operator_surface/style/09_responsive.css:110)). Code indicates deliberate layout, but failed captures prevent validating actual visual balance at the required viewport sizes.
- **WARNING** — Stress-story examples put button styles directly in markup, making variants less consistent and harder to audit ([sections.ex](lib/threadline/operator_surface/live/stress_live/sections.ex:282), [sections.ex](lib/threadline/operator_surface/live/stress_live/sections.ex:327)). Extract these into named classes/components.
- Phase 234’s scope is API documentation/typespec completion; its summaries do not claim UI implementation or responsive visual changes.

### Pillar 3: Color (2/4)

- **WARNING** — The design system defines a semantic palette and accent lane in [01_tokens.css](lib/threadline/operator_surface/style/01_tokens.css:34), which supports consistent use in most components.
- **WARNING** — `--tl-color-ink` and `--tl-color-paper` resolve to themselves at lines 44/46 and are repeated in dark/light overrides at lines 89–90, 215–216, and 267–268 ([01_tokens.css](lib/threadline/operator_surface/style/01_tokens.css:44)). A custom property that depends on itself is invalid at computed-value time; give each token a concrete value or alias a differently named primitive. This can remove intended colors wherever these tokens are consumed.
- **WARNING** — Stress story fixture includes raw `#e8a246` instead of a palette token ([refute.ex](lib/threadline/operator_surface/live/stress_live/refute.ex:588)). The primary color set is otherwise centralized; no pixel-based 60/30/10 distribution could be measured without successful screenshots.

### Pillar 4: Typography (2/4)

- **WARNING** — The token layer declares nine font-size role names (12, 13, 14, 15, 16, 20, 24, and 32px, with 13px duplicated as `sm` and `dense`) and three weights (400, 500, 600) ([01_tokens.css](lib/threadline/operator_surface/style/01_tokens.css:17)). That exceeds the abstract guidance of four sizes and two weights, increasing hierarchy drift risk.
- Keep named roles only where they represent visibly distinct text roles; collapse duplicate 13px aliases and reduce weight choices to regular/strong unless a third is demonstrably needed.
- Screenshots were unavailable, so legibility and wrapping at mobile/tablet sizes were not visually verified.

### Pillar 5: Spacing (3/4)

- **WARNING** — The base tokens provide a mostly coherent 4px-derived spacing scale, and shared layout rules consume those tokens ([01_tokens.css](lib/threadline/operator_surface/style/01_tokens.css:5), [06_layout_primitives.css](lib/threadline/operator_surface/style/06_layout_primitives.css:1)).
- **WARNING** — The scale adds 20px and 40px (`space-5`, `space-10`) alongside the 4/8/12/16/24/32/48px sequence, while `row-padding-compact` is a separate 10px token ([01_tokens.css](lib/threadline/operator_surface/style/01_tokens.css:9), [01_tokens.css](lib/threadline/operator_surface/style/01_tokens.css:139)). These may be intentional, but should be justified as named component roles or aligned to the base scale. Inline styles also make spacing audits less reliable.
- No spacing contract exists for this phase; visual alignment remains code-derived because captures failed.

### Pillar 6: Experience Design (3/4)

- **WARNING** — State coverage is present: coverage initializes an empty snapshot and handles refresh errors ([coverage_live.ex](lib/threadline/operator_surface/live/coverage_live.ex:26), [coverage_live.ex](lib/threadline/operator_surface/live/coverage_live.ex:59)); invalid schema is exposed as an alert with a recovery link ([coverage_live.ex](lib/threadline/operator_surface/live/coverage_live.ex:301)); useful empty states are rendered at lines 164–167. This is a solid baseline.
- **WARNING** — Keyboard focus and reduced-motion accommodations are explicitly present ([02_base_shell.css](lib/threadline/operator_surface/style/02_base_shell.css:43), [09_responsive.css](lib/threadline/operator_surface/style/09_responsive.css:468)). Copy-only buttons also have contextual accessible names ([transaction_live.ex](lib/threadline/operator_surface/live/transaction_live.ex:261)).
- **WARNING** — No screenshots or interaction captures were available to verify focus order, state transitions, or responsive task completion. Phase 234 itself centers on docs and type contracts, so no new UI state coverage is evidenced in its summaries.

---

## Files Audited

- `.planning/phases/234-typespec-and-doc-completion-gate/234-01-PLAN.md` through `234-19-PLAN.md`, matching summaries, and `234-CONTEXT.md`
- `brandbook/brand-book.md`
- `lib/threadline/operator_surface/style/01_tokens.css`, `02_base_shell.css`, `04_controls.css`, `06_layout_primitives.css`, `08_overlays_motion.css`, `09_responsive.css`
- `lib/threadline/operator_surface/live/coverage_live.ex`, `transaction_live.ex`, `timeline_live/filters.ex`, `stress_live/sections.ex`, `stress_live/refute.ex`
- `lib/threadline/operator_surface/auth.ex`, `router.ex`

