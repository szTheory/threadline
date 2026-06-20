# Phase 174: Form components - Context

**Gathered:** 2026-06-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Internal private form components (text, textarea, select, combobox, checkbox, radio, switch, search, date, filters, field group, error, help, disabled-readonly) supporting LiveView pages with focus preservation, non-color validation, and zero public component API exposure.

</domain>

<decisions>
## Implementation Decisions

### Form API contract
- **D-01:** Components must use explicit `name`, `value`, and `errors` props rather than depending on `Phoenix.HTML.FormField` structs or `to_form/1`.
- **D-02:** This approach strictly preserves the invariant that `phoenix_html` is an `optional: true` dependency, ensuring pure Plug/capture adopters don't pay for UI dependencies.
- **D-03:** Emphasizes raw functional UI primitives over framework coupling, establishing a bulletproof "least-surprise" boundary that works seamlessly with raw strings, Maps, or Ecto changesets without forcing the caller's hand.

### Rich interactive controls
- **D-04:** Use native HTML5 controls (`<select>`, `<input type="date">`, `<input type="checkbox">`) styled with CSS, avoiding custom JS elements (like Alpine.js or complex `Phoenix.LiveView.JS` hooks) entirely for core primitives.
- **D-05:** Preserves the "zero new runtime dependencies" and "CSP-proof" invariant while keeping out-of-the-box accessibility (screen readers, mobile native pickers) free.
- **D-06:** Comboboxes/switches can use minimal `Phoenix.LiveView.JS` solely for ARIA state toggling, but must degrade gracefully.

### Field layout composition
- **D-07:** Implement a monolithic `<.field>` (or `<.form_control>`) component that composes the label, input, and error messages together.
- **D-08:** This drastically reduces template duplication across the 11 operator-surface LiveView pages, answering COMP-05 directly.
- **D-09:** Ensures programmatically connected help and error states (WAI-ARIA APG compliance) are impossible for developers to forget, delivering on the "great developer ergonomics" demand.

### Folded Todos
- **Coverage "schema: public" card de-clutter (reduce nested border/padding blocks)**: Form component wrappers and spacing primitives should directly address nested layout clutters in existing data display. (Area: operator-surface)
- **Dark/light/system theme picker with idiomatic UI controls (THEME-TOGGLE-01 demand signal)**: The form primitives (radio, switch, or segmented control) will serve as the foundation for building this picker. (Area: operator-surface)
- **Transaction page content left-pushed at desktop widths (theme-independent layout bug)**: Form components must be built mobile-first and respect responsive maximum widths to fix layout pushes. (Area: operator-surface)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Ecosystem & Brand DNA
- `prompts/audit-lib-domain-model-reference.md` — Explains the separation of capture, semantics, and exploration. Component states must reflect exploration context (e.g. read-only, deleted records).
- `prompts/threadline-elixir-oss-dna.md` — OSS quality bar (contracts, deterministic tests, explicit composition).
- `brandbook/brand-book.md` — Visual standards for typography, spacing, radius, shadow, and states (used in CSS token application for forms).

### Requirements
- `.planning/REQUIREMENTS.md` — v1.37 constraints (no public API, WCAG 2.2 AA).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.OperatorSurface.UI` (`lib/threadline/operator_surface/ui.ex`): Existing primitive components (`button`, `badge`, `alert`, `modal`) define the function component signature and module pattern to follow.
- `Threadline.OperatorSurface.Style` (`lib/threadline/operator_surface/style.ex`): Dark/light/system tokens are defined here. Form components must map directly to these existing `--tl-*` tokens.

### Established Patterns
- **Internal components only:** Components in `UI` are internal and not exposed via public API macros.
- **BEM / Class-soup extraction:** Current LiveView pages use raw classes; new components replace them.

### Integration Points
- **LiveView Pages:** 11 pages (Home, Timeline, Transaction, Row history, Actor, Coverage, Evidence, etc.) will consume these new components.

</code_context>

<specifics>
## Specific Ideas

- Emphasize developer ergonomics by making forms "correct by default" with WAI-ARIA attributes automatically linked.
- The UI must look good in dark, light, and system themes with no weirdness on hover/focus.
- Rely on native HTML5 controls for accessibility, keeping JS hooks to absolute zero.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 174-Form components*
*Context gathered: 2026-06-16*
