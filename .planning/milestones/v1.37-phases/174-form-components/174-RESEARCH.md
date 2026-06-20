# Phase 174: Form components - Research

**Researched:** 2026-06-16
**Domain:** Phoenix UI Components, Web Accessibility, CSS
**Confidence:** HIGH

## Summary

This phase completes the internal form component primitive library for the Threadline operator surface and applies it across the 11 LiveView pages. It strictly avoids adding any public/host-facing API, enforcing the `optional: true` contract for UI dependencies. We will implement native HTML5 controls with a monolithic `<.field>` component that correctly handles label, input, and programmatically linked errors and help text to satisfy WAI-ARIA and WCAG 2.2 AA.

**Primary recommendation:** Build a monolithic `Threadline.OperatorSurface.UI.field` that takes explicit `name`, `value`, and `errors` rather than `Phoenix.HTML.FormField` to preserve zero mandatory dependencies.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Components must use explicit `name`, `value`, and `errors` props rather than depending on `Phoenix.HTML.FormField` structs or `to_form/1`.
- **D-02:** This approach strictly preserves the invariant that `phoenix_html` is an `optional: true` dependency, ensuring pure Plug/capture adopters don't pay for UI dependencies.
- **D-03:** Emphasizes raw functional UI primitives over framework coupling, establishing a bulletproof "least-surprise" boundary that works seamlessly with raw strings, Maps, or Ecto changesets without forcing the caller's hand.
- **D-04:** Use native HTML5 controls (`<select>`, `<input type="date">`, `<input type="checkbox">`) styled with CSS, avoiding custom JS elements (like Alpine.js or complex `Phoenix.LiveView.JS` hooks) entirely for core primitives.
- **D-05:** Preserves the "zero new runtime dependencies" and "CSP-proof" invariant while keeping out-of-the-box accessibility (screen readers, mobile native pickers) free.
- **D-06:** Comboboxes/switches can use minimal `Phoenix.LiveView.JS` solely for ARIA state toggling, but must degrade gracefully.
- **D-07:** Implement a monolithic `<.field>` (or `<.form_control>`) component that composes the label, input, and error messages together.
- **D-08:** This drastically reduces template duplication across the 11 operator-surface LiveView pages, answering COMP-05 directly.
- **D-09:** Ensures programmatically connected help and error states (WAI-ARIA APG compliance) are impossible for developers to forget, delivering on the "great developer ergonomics" demand.

### the agent's Discretion
None explicitly listed.

### Deferred Ideas (OUT OF SCOPE)
None
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-04 | Internal form components exist (text/textarea/select/combobox/checkbox/radio/switch/search/number-date/filter controls/field group/error summary/help/required-optional/disabled-readonly) with visible associated labels, programmatically connected help + errors, non-color validation, and focus preserved across LiveView patches. | Native HTML5 inputs wrapped in `<.field>` handle focus natively. Explicit aria-describedby connects help/errors. |
| COMP-05 | The 11 operator-surface LiveView pages consume the components (inline class-soup replaced) and template duplication is materially reduced. | Component extraction to `Threadline.OperatorSurface.UI` handles the CSS classes (`tl-control`, `tl-field`, etc.). |
| COMP-06 | Per-component contract tests lock attrs/slots/states/a11y so a component regression fails CI. | Tested via `rendered_to_string` assertions in `test/threadline/operator_surface/ui_test.exs` |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Form State | Frontend Server (LiveView) | Browser (Native DOM) | LiveView handles validation and submission; browser native inputs handle focus, keyboard navigation, and basic validation feedback. |
| ARIA Linking | Frontend Server (SSR) | — | The `<.field>` component generates ID-linked labels, inputs, and aria-describedby attributes at render time. |
| Styling / Focus | Browser / Client | — | Pure CSS styling via BEM classes (`tl-field`, `tl-control`, `tl-checkbox`) using existing CSS variables. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix.Component | ~> 1.7 | Function components | Standard Phoenix view layer, already in use (`Threadline.OperatorSurface.UI`). |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix.LiveView.JS | ~> 1.0 | ARIA toggles | Only for switches or comboboxes that require local client-side toggle without roundtrips. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `name`/`value`/`errors` | `Phoenix.HTML.FormField` | Using `FormField` forces `phoenix_html` as a hard dependency, violating the `optional: true` contract. |
| Native `<select>` / `<input type="date">` | Alpine.js or JS Hook driven custom controls | Custom controls require JS, breaking the CSP-proof / zero-JS invariant and requiring extensive ARIA implementation. Native is free a11y. |

## Package Legitimacy Audit

No external packages are being added in this phase. The phase entirely utilizes in-tree code and existing optional dependencies defined in `mix.exs`.

## Architecture Patterns

### Recommended Project Structure
All components reside in the existing UI module to prevent macro sprawl.

```
lib/threadline/operator_surface/
├── ui.ex                # Add `<.field>`, `<.input>`, `<.label>`, `<.error>`, `<.help>`
test/threadline/operator_surface/
└── ui_test.exs          # Add render tests for all form components
```

### Pattern 1: Monolithic Field Component
**What:** A singular `<.field>` component that conditionally renders labels, inputs, errors, and help text based on the `type` attribute.
**When to use:** For all form inputs across the operator surface.
**Example:**
```elixir
def field(assigns) do
  ~H"""
  <div class={["tl-field", @errors != [] && "tl-field--error", @class]}>
    <.label for={@id}><%= @label %></.label>
    <.input id={@id} name={@name} value={@value} type={@type} aria-describedby={help_id(@id) <> " " <> error_id(@id)} />
    <.error :for={msg <- @errors} id={error_id(@id)}><%= msg %></.error>
    <.help :if={@help_text} id={help_id(@id)}><%= @help_text %></.help>
  </div>
  """
end
```

### Anti-Patterns to Avoid
- **Implicit `to_form/1` mapping:** Do not use `form.field` or require developers to pass a `Phoenix.HTML.Form` struct. It restricts usage and creates coupling.
- **Color-only validation:** Ensure errors are accompanied by an icon or prefix text (e.g., `<.error>` includes an aria-hidden SVG), satisfying WCAG non-color validation rules.
- **Custom dropdown for dates:** Avoid building a calendar. Let the browser handle `<input type="date">`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Form components | Standalone packages | In-tree components | GEMINI.md mandate: "default to providing them as In-Tree Optional Dependencies. Do not create separate micro-packages." |
| Date Pickers | Custom calendar with JS | `<input type="date">` | Accessibility, mobile native pickers, zero JS footprint. |

## Common Pitfalls

### Pitfall 1: LiveView Focus Loss
**What goes wrong:** Typing into an input causes LiveView to patch the DOM, losing cursor focus.
**Why it happens:** The input lacks a stable, unique `id`, or the form state is poorly tracked.
**How to avoid:** Always require and pass down an `id` to the `<.input>` component. Ensure `phx-feedback-for` or `phx-update="ignore"` is used where appropriate, but usually a stable `id` handles it.

### Pitfall 2: Disconnected ARIA Labels
**What goes wrong:** Screen readers read the input but not the associated error message or help text.
**Why it happens:** Missing `aria-describedby` or mismatched IDs.
**How to avoid:** The `<.field>` component MUST programmatically compute and apply `aria-describedby` if `errors` or `help_text` are present.

### Pitfall 3: `phoenix_html` Coupling
**What goes wrong:** Users who install `threadline` purely as an API capture layer without Phoenix UI dependencies get a compilation or runtime error.
**Why it happens:** `Phoenix.HTML.Form` functions are used directly in component logic.
**How to avoid:** Use plain maps, strings, and standard Elixir types for component assigns (`name`, `value`, `errors` list).

## Code Examples

### The Form Input Contract
```elixir
# lib/threadline/operator_surface/ui.ex
attr :id, :string, required: true
attr :name, :string, required: true
attr :value, :any, default: nil
attr :type, :string, default: "text"
attr :label, :string, required: true
attr :errors, :list, default: []
attr :help_text, :string, default: nil
attr :rest, :global, include: ~w(autocomplete disabled readonly required placeholder phx-debounce)
def field(assigns) do
  # Monolithic implementation connecting label, input, error
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom rich JS select/date controls | Native HTML5 controls (`<select>`, `<input type="date">`) styled via CSS | Ongoing | Huge drop in accessibility bugs, zero JS payload, native mobile support. |
| Scattered `phx-html` form helpers | Explicit `name`/`value` pure function components | Phoenix LiveView ~0.18+ (verified in OSS communities) | Decouples UI layers from Ecto Changesets/Form structs, making components usable with plain Maps. |

## Assumptions Log

None — all implementation rules and architectural decisions were verified against `174-CONTEXT.md` and `GEMINI.md`.

## Open Questions

None. The constraints provide a clear path forward for replacing the inline class-soup with structured internal components.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified). This phase uses only Elixir code and CSS within the project tree.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Phoenix.LiveViewTest) |
| Config file | `mix.exs` / `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/operator_surface/ui_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COMP-06 | Form components render correct ARIA, focus, labels | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ✅ Wave 0 |
| COMP-05 | Operator pages compile/render with new forms | unit/smoke | `mix test test/threadline/operator_surface/` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/operator_surface/ui_test.exs`
- **Per wave merge:** `mix ci.all`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
None — existing test infrastructure (`test/threadline/operator_surface/ui_test.exs` and `ui_stress_test.exs`) covers all phase requirements.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Native HTML5 constraints (e.g. `required`, `pattern`) combined with standard LiveView server-side validation. |
| V6 Cryptography | no | — |

### Known Threat Patterns for Elixir/LiveView

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via user input | Tampering | Phoenix HEEx engine auto-escapes all strings rendered via `<%= @value %>`. |
| CSRF in forms | Spoofing | LiveView form bindings use secure WebSocket channels with built-in token verification. Standard `form` components don't circumvent this. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/174-form-components/174-CONTEXT.md` - Confirms zero JS, native elements, optional `phoenix_html`.
- `GEMINI.md` - Confirms "in-tree optional dependencies" and single component files.
- `lib/threadline/operator_surface/ui.ex` - Confirms component declaration style (`Phoenix.Component`, explicit BEM classes).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Dictated by context constraints and Elixir/Phoenix ecosystem standards.
- Architecture: HIGH - Monolithic `<.field>` component with explicit ARIA mapping perfectly answers the context constraints.
- Pitfalls: HIGH - Documented LiveView focus tracking and ARIA issues are common in Phoenix apps.

**Research date:** 2026-06-16
**Valid until:** 2026-07-16
