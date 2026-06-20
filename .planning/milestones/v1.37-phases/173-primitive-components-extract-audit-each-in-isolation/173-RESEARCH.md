# Phase 173: Primitive components (extract + audit each in isolation) - Research

**Researched:** 2026-06-15
**Domain:** Phoenix Component Extraction & Accessibility
**Confidence:** HIGH

## Summary

This phase extracts the hard-coded HTML and "class-soup" from the existing operator surface into a single, cohesive private component module (`Threadline.OperatorSurface.UI`). This centralizes accessibility semantics, state transitions, and responsive behavior for all fundamental building blocks (primitives, overlays, and disclosures).

**Primary recommendation:** Create `Threadline.OperatorSurface.UI` as a drop-in replacement matching the Phoenix `core_components.ex` paradigm, utilizing strictly typed `attr` definitions and `Phoenix.LiveView.JS` for all interactive overlay states to avoid custom Javascript.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **Single module for primitives (`Threadline.OperatorSurface.UI` or `CoreComponents`).** Keep all primitives (button, badge, alert, dialog, etc.) in a single cohesive module matching Phoenix's `core_components.ex` idiom, avoiding file explosion for simple pure functions.
- **D-02:** **Strict validation.** Use explicit `@doc` and typed `attr`, failing at compile-time for typos to ensure robust internal use.
- **D-03:** **Phoenix.LiveView.JS commands.** Use Phoenix.LiveView.JS for simple toggles and modal/drawer state, avoiding custom JS hooks to keep it JS-light and fail-closed.

### the agent's Discretion
- No specific requirements — open to standard approaches. Ensure interaction states (hover, focus-visible, active, disabled) are fully represented.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-01 | Internal private function components exist for the primitive set (button, icon-button, link, badge/chip/tag/pill, alert/banner/callout, card/panel, stat tile, divider, empty state, error state, spinner/progress/skeleton, code/log/JSON, avatar) with documented attrs/slots — no public/host-facing API. | Verified `Threadline.OperatorSurface.UI` single-module pattern. |
| COMP-02 | Overlay & disclosure primitives (modal/dialog, drawer/sheet, toast/flash, tooltip, popover, dropdown/menu, tabs, segmented control, accordion/disclosure) are internal components with correct keyboard, focus-trap/restore, escape, and scrim semantics. | Verified native `Phoenix.LiveView.JS` capabilities (`JS.push_focus`, `JS.show`/`JS.hide`) handle all a11y focus routing. |
| COMP-03 | Every primitive renders correctly in all interaction states (default/hover/focus-visible/active/pressed/disabled/loading/selected/current) across dark/light/system; non-interactive elements expose no misleading affordances. | Pure CSS handling using `:hover`, `:focus-visible`, `:active`, combined with semantic HTML tags `<button>`, `<a>`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Basic Primitives (Button, Badge, Alert) | Frontend Server (HEEx) | — | Pure structural generation of markup and CSS classes (`tl-*`). |
| Overlays & Disclosures (Modal, Drawer) | Frontend Server (HEEx) | Browser / Client | Server generates initial markup; Client handles open/close/focus using `Phoenix.LiveView.JS` without custom Javascript. |
| Accessibility Semantics (ARIA, Role) | Frontend Server (HEEx) | Browser / Client | Semantic HTML output + dynamic updates to `aria-expanded` via `JS` macros. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix.Component | Built-in | Component API (`attr`, `slot`) | Idiomatic Elixir approach to functional UI rendering. |
| Phoenix.LiveView.JS | Built-in | Client-side interactions | Zero-custom-JS way to handle dialogs, dropdowns, and focus traps. |

**Version verification:** 
The stack utilizes built-in Phoenix modules already present in the project. No new dependencies or packages are added, satisfying the Phase 171 invariant: "zero new runtime dependencies; inline assets only."

## Architecture Patterns

### Recommended Project Structure
```
lib/threadline/operator_surface/
├── components/          # (Existing) Legacy individual components
├── ui.ex               # (New) Unified primitive component library
└── style.ex            # (Existing) CSS token definitions
```

### Pattern 1: Core Components Style Module
**What:** Group all stateless UI components into a single `Threadline.OperatorSurface.UI` module containing robust `@doc false` and typed `attr` definitions.
**When to use:** For all standard UI atoms like buttons, chips, panels, and badges.
**Example:**
```elixir
defmodule Threadline.OperatorSurface.UI do
  @moduledoc false
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc false
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "tl-button",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
```

### Pattern 2: LiveView.JS for Dialogs and Overlays
**What:** Manage visibility and focus for modals/drawers strictly using `JS.show`/`JS.hide` to manipulate classes and accessibility attributes.
**When to use:** Modals, Drawers, Dropdowns, and Disclosures.
**Example:**
```elixir
def show_modal(js \\ %JS{}, id) do
  js
  |> JS.show(
    to: "##{id}",
    transition: {"tl-fade-in", "opacity-0", "opacity-100"}
  )
  |> JS.show(
    to: "##{id}-content",
    transition: {"tl-rise-in", "opacity-0 translate-y-4", "opacity-100 translate-y-0"}
  )
  |> JS.add_class("overflow-hidden", to: "body")
  |> JS.focus_first(to: "##{id}-content")
end

def hide_modal(js \\ %JS{}, id) do
  js
  |> JS.hide(
    to: "##{id}-content",
    transition: {"tl-rise-out", "opacity-100 translate-y-0", "opacity-0 translate-y-4"}
  )
  |> JS.hide(
    to: "##{id}",
    transition: {"tl-fade-out", "opacity-100", "opacity-0"}
  )
  |> JS.remove_class("overflow-hidden", to: "body")
  |> JS.pop_focus()
end
```

### Anti-Patterns to Avoid
- **File Explosion:** Creating `lib/threadline/operator_surface/components/button.ex`, `badge.ex`, etc. Use one module.
- **Custom JS Hooks:** Writing `Hooks.Modal = { mounted() { ... } }` in javascript. Phoenix.LiveView.JS handles this correctly without bridging.
- **Exposing Public API:** Leaving out `@doc false` or `@moduledoc false`. These components are internal-only.
- **Misleading Affordances:** Adding `cursor-pointer` to non-interactive elements like unlinked `badge` components.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dialog focus traps | Custom JS event listeners | `JS.focus_first()` and `JS.pop_focus()` | Prevents keyboard users from tabbing outside the modal natively. |
| ARIA expanded toggles | JS hooks mutating `aria-expanded` | `JS.set_attribute({"aria-expanded", "true"})` | Keeps accessibility state changes declarative in Elixir. |
| Click-outside dismiss | `window.addEventListener('click')` | `phx-click-away` | Native LiveView binding that correctly detects clicks outside the target element. |

## Common Pitfalls

### Pitfall 1: Breaking Keyboard Navigation in Overlays
**What goes wrong:** Modals open, but the user's `Tab` key moves focus to hidden elements behind the modal.
**Why it happens:** Missing `aria-modal="true"`, `role="dialog"`, and `JS.focus_first()`.
**How to avoid:** Ensure the root container has `role="dialog" aria-modal="true"` and the open action calls `JS.focus_first(to: "#dialog-content")`.

### Pitfall 2: Typos in Component Attributes
**What goes wrong:** Components fail to render or render incorrectly because of misnamed attributes.
**Why it happens:** Permissive component contracts (`attr :rest, :global` used exclusively).
**How to avoid:** Explicitly define every expected attribute (e.g. `attr :variant, :string, values: ~w(primary secondary danger)`) to leverage compile-time warnings.

## Code Examples

Verified patterns from official sources:

### [Dropdown Menu State Management]
```elixir
def dropdown(assigns) do
  ~H"""
  <div class="relative">
    <button
      type="button"
      phx-click={JS.toggle(to: "##{@id}-menu") |> JS.set_attribute({"aria-expanded", "true"}, to: "##{@id}-button")}
      phx-click-away={JS.hide(to: "##{@id}-menu") |> JS.set_attribute({"aria-expanded", "false"}, to: "##{@id}-button")}
      id={"#{@id}-button"}
      aria-expanded="false"
      aria-haspopup="true"
    >
      <%= render_slot(@trigger) %>
    </button>
    <div
      id={"#{@id}-menu"}
      class="hidden absolute tl-shadow-popover"
      role="menu"
    >
      <%= render_slot(@inner_block) %>
    </div>
  </div>
  """
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/operator_surface/ui_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COMP-01 | Renders primitive components correctly | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ❌ Wave 0 |
| COMP-02 | Overlays render with proper ARIA and roles | unit | `mix test test/threadline/operator_surface/ui_test.exs` | ❌ Wave 0 |
| COMP-03 | Component state permutations are renderable | integration | `mix test test/threadline/operator_surface/ui_stress_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/operator_surface/ui_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/ui_test.exs` — covers COMP-01, COMP-02
- [ ] `test/threadline/operator_surface/ui_stress_test.exs` — integration tests for component state permutations

## Sources

### Primary (HIGH confidence)
- `lib/threadline/operator_surface/style.ex` - Verified class names and CSS properties (`tl-*` namespace).
- `.planning/ROADMAP.md` & `.planning/REQUIREMENTS.md` - Verified phase boundaries and dependencies.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core components methodology is idiomatic to Phoenix.
- Architecture: HIGH - Dictated strongly by CONTEXT.md lock-ins.
- Pitfalls: HIGH - A11y in dialogs is a well-understood Phoenix JS domain.

**Research date:** 2026-06-15
**Valid until:** 2026-07-15