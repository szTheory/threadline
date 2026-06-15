# Phase 172: Foundations audit & hardening (tokens) - Research

**Researched:** 2026-06-15
**Domain:** Design System Foundations, CSS Tokens, and Theming
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Token Override Approach
- **D-01:** **Semantic Token Mapping in style.ex**. Keep `brandbook/tokens.json` strictly for primitive brand tokens (Thread Blue, Graphite, Fog, Space 1-16). In `style.ex`, map these primitives to functional UI tokens (e.g., `--tl-color-surface-hover`, `--tl-color-border-focus`). The parity test only enforces the primitive tokens. This maintains the SSOT for the brand while giving the operator surface the flexibility to compose functional states without polluting the brand book with component-specific CSS.

#### Decision Brief Format
- **D-02:** **Hybrid (Code-anchored + Markdown Ledger).** Write the full decision briefs in the `DESIGN-SYSTEM.md` v2 ledger (requirement DS-02). In `style.ex`, leave a concise 1-2 line comment with a pointer to the specific section in `DESIGN-SYSTEM.md` (e.g., `/* See DESIGN-SYSTEM.md § "Light Mode Table Hover" */`). This keeps `style.ex` clean but ensures anyone changing the token understands why it exists, preventing the "Grafana lesson" footgun.

#### Motion Reductions
- **D-03:** **Cross-fade fallback.** For `@media (prefers-reduced-motion: reduce)`, do not use `0ms` universally. Instead, zero out positional transitions (`transform`, `translate`, `scale`) but preserve opacity fades (e.g., `120ms ease`). This keeps the UI feeling polished and communicative (things still "appear") without causing motion sickness, aligning with the brand's "calm in tense moments" trait.

#### Folded Todos
- **Dark/light/system theme picker with idiomatic UI controls (THEME-TOGGLE-01 demand signal)**
  - *Original Problem:* Need a runtime dark/light/system picker with idiomatic UI controls.
  - *How it fits:* Folded as an idiomatic, zero-JS segmented control using Plug + Cookie to persist the selection. LiveView `phx-click` sends an event, saves the cookie, and patches the UI. Fits the NAV/foundations scope.
- **Transaction page content left-pushed at desktop widths (theme-independent layout bug)**
  - *Original Problem:* Transaction page content is left-pushed at desktop widths.
  - *How it fits:* Folded. Will fix the max-width container (`.tl-home` or similar `.tl-container` class) with `max-width: 1000px; margin: 0 auto;` to ensure content is centered on ultra-wide desktop monitors, maintaining readability.
- **Coverage "schema: public" card de-clutter (reduce nested border/padding blocks)**
  - *Original Problem:* Coverage "schema: public" card has too many nested borders.
  - *How it fits:* Folded. Flatten the card-in-card structure. Remove the outer border/background for the schema grouping and just use a header, letting individual table cards sit directly on the page background to reduce visual noise.

### the agent's Discretion
None explicitly defined in CONTEXT.md (all implementation items were locked under Decisions).

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DS-05 | Foundations (color, typography, spacing, radius, shadow, z-index, density, motion tokens) are audited against the brand book; off-brand / contrast / scale gaps are fixed; any new token lands in `brandbook/tokens.{json,css}` first and keeps the parity test green. | Primitive tokens live in `brandbook/tokens.json`, semantic tokens in `style.ex`. `brandbook_token_parity_test` enforces parity. |
| DS-06 | Each significant foundation decision is captured as a compact decision brief (problem / users-JTBD / options / tradeoffs / idiomatic-for-LiveView / recommendation / rejected alternatives / tests to lock it). | Decision briefs live in `DESIGN-SYSTEM.md` with concise 1-2 line pointer comments in `style.ex` |
</phase_requirements>

## Project Constraints (from GEMINI.md)

- **Dependency Strategy for Adapters:** When designing integrations or scale-out adapters for common industry standards (e.g. Oban, S3), default to providing them as **In-Tree Optional Dependencies**. Do not create separate micro-packages. Provide explicit behaviour contracts, add underlying libraries as `optional: true` in `mix.exs`, and ensure clear initialization errors if the dependency is missing. This follows the Swoosh/Ecto "batteries-included" paradigm and minimizes version drift risk, maintaining Developer Experience (DX) goals. *(Note: Primarily informational for this UI/foundation phase)*

## Summary

This phase solidifies the design system foundations by auditing CSS tokens against the newly established Threadline brand book and fixing any contrast or scale drift. It introduces strict governance for tokens: `brandbook/tokens.json` acts as the source of truth for base primitive colors and sizing, while `style.ex` handles mapping these primitives into semantic, component-specific roles (e.g., surface, border, hover states). It also establishes a hybrid documentation model for design decisions and addresses key UI footguns including reduced motion handling, zero-JS theme toggling via Plug+Cookie, and layout decluttering on the Transaction and Coverage pages.

**Primary recommendation:** Establish a rigid boundary between primitive brand tokens in `brandbook/tokens.json` and semantic functional tokens in `style.ex`, using Plugs and cookies for zero-JS theming, and employing opacity-only transitions for reduced motion.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Brand Primitive Tokens | Static / Assets | API / Backend | `brandbook/tokens.json` acts as the absolute SSOT for brand primitives (colors, spacing scale). |
| Semantic Token Mapping | API / Backend | Browser / Client | `style.ex` composes primitive tokens into semantic UI variables (e.g. `--tl-color-surface`) sent as CSS to the client. |
| Theme Selection (Toggle) | Frontend Server (SSR) | Browser / Client | Zero-JS toggle uses an Elixir Plug to read/write a cookie, setting `data-tl-theme` on the root HTML. |
| Motion Reduction | Browser / Client | — | Implemented purely in CSS using `@media (prefers-reduced-motion: reduce)` to override transform properties while keeping opacity. |
| Decision Ledger | Documentation | — | `DESIGN-SYSTEM.md` holds the detailed "why" for foundation decisions to prevent unprincipled overrides. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Plug (`Plug.Conn`) | ~> 1.15 | Cookie management | Standard Elixir library for HTTP connection manipulation; enables zero-JS theme persistence. |
| Phoenix.LiveView | ~> 0.20 | Event handling | `phx-click` will trigger the theme toggle event to save the cookie and update the session. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Plug + Cookie | `localStorage` + inline JS | Rejected by CONTEXT.md and REQUIREMENTS.md due to FOUC on dead render and CSP incompatibility. |
| Storybook | PhoenixStorybook | Explicitly forbidden in REQUIREMENTS.md; internal `/audit/__stress` route used instead. |

## Package Legitimacy Audit

> **Required** whenever this phase installs external packages. Run the Package Legitimacy Gate protocol before completing this section.

*No external packages are installed in this phase. The phase relies entirely on the existing Phoenix/LiveView/Plug stack.*

## Architecture Patterns

### System Architecture Diagram
```
[User Clicks Theme Toggle] 
       │
       ▼
[LiveView Event (`phx-click`)] 
       │
       ▼
[LiveView Event Handler] 
  │ 1. Updates socket assigns (`theme: new_theme`) 
  │ 2. Issues `push_event` or standard redirect/patch to save cookie
  │
  ▼
[Elixir Plug (`ThemePlug`)] 
  │ Reads `theme` cookie on every request
  │ Sets `assigns[:theme]` for root layout
  │
  ▼
[Root HTML (`root.html.heex`)]
  │ Renders `<html data-tl-theme={@theme}>`
  │
  ▼
[Browser (CSS variables applied)]
  │ `style.ex` provides light/dark/system CSS rules based on `data-tl-theme`
```

### Pattern 1: Zero-JS Theme Persistence
**What:** Using `Plug.Conn` to read a cookie on initial request and a LiveView event to set the cookie, avoiding `localStorage` FOUC.
**When to use:** When you need a persistent UI state (like theme) that must be known before the first HTML render to avoid flashing, and must work without client-side JS executing first.
**Example:**
```elixir
# Theme Plug
def call(conn, _opts) do
  theme = conn.cookies["tl_theme"] || "system"
  Plug.Conn.assign(conn, :theme, theme)
end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Creating component-specific colors in `brandbook/tokens.json`.
  - *Why it's bad:* Pollutes the universal brand identity with UI-specific logic (e.g., `card-border-hover`).
  - *What to do instead:* Define primitive colors (e.g., `Graphite`, `Fog`) in the brandbook, and map them to semantic names (`--tl-color-surface`) in `style.ex`.
- **Anti-pattern:** Using `transition: all 0ms` for `prefers-reduced-motion`.
  - *Why it's bad:* Makes the UI feel broken and jarring.
  - *What to do instead:* Remove positional transitions (`transform`, `scale`) but leave a fast opacity fade (`120ms ease`) so state changes are still communicated gracefully.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Client-side theme flicker | `localStorage` + `<script>` in head | Plug + Cookie | `localStorage` approach is blocked by CSP and causes FOUC on dead renders in SSR applications. |
| Component UI catalog | External Storybook deps | `/audit/__stress` route | Prevents adding heavy dependencies, keeps testing internal and authenticated. |

## Runtime State Inventory

*Step 2.5: SKIPPED (This is an audit and hardening phase, not a rename/refactor phase.)*

## Environment Availability

*Step 2.6: SKIPPED (no external dependencies identified, pure code/config changes in existing Elixir project)*

## Common Pitfalls

### Pitfall 1: Breaking Parity Test
**What goes wrong:** Adding a new color to `style.ex` without adding its primitive to `tokens.json`.
**Why it happens:** Developer focuses only on the operator surface and forgets the dual-source contract.
**How to avoid:** Always define the raw value in `brandbook/tokens.json` first, then reference it in `style.ex`. Check `brandbook_token_parity_test` locally.
**Warning signs:** CI fails on the `brandbook_token_parity_test`.

### Pitfall 2: Reduced Motion Over-Correction
**What goes wrong:** Using `* { transition: none !important; }` for reduced motion.
**Why it happens:** Easiest way to disable motion.
**How to avoid:** Explicitly override only `transform`, `translate`, and `scale` properties in the `@media (prefers-reduced-motion: reduce)` block, leaving `opacity` and `color` transitions intact.

## Code Examples

### Emil Kowalski / GOV.UK Reduced Motion Pattern
```css
/* Source: D-03 / Emil Kowalski */
@media (prefers-reduced-motion: reduce) {
  .threadline-ui *,
  .threadline-ui *::before,
  .threadline-ui *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
  
  /* Exception: preserve opacity fades for state changes */
  .threadline-ui .tl-fade-supported {
    transition: opacity 120ms ease !important;
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `localStorage` theming | HTTP Cookies + SSR | v1.36+ | No FOUC, respects CSP, reliable SSR rendering |
| Universal `0ms` motion | Selective cross-fade fallback | v1.37 | Better UX for reduced-motion users while preventing motion sickness |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | LiveView zero-JS theme toggle will require a POST form redirect (which creates a tiny flash) OR a tiny JS hook to be pure zero-JS UX without a full redirect. | Architecture Patterns | If a redirect is unacceptable, a 2-line JS hook might be required despite "zero-JS" goals. (Though often `Plug.Conn.put_resp_cookie` during a `push_navigate` works smoothly in LiveView). |

## Open Questions (RESOLVED)

1. **LiveView Cookie Writing without JS**
   - What we know: LiveView websocket connections cannot directly write HTTP cookies to the browser without a redirect or JS interop.
   - What's unclear: Does the project permit a tiny `Phoenix.LiveView.JS` hook for setting the cookie, or must it use a full page redirect via `push_navigate` to a controller to remain strictly "zero-JS"?
   - RESOLVED: Use a controller endpoint (e.g. `POST /audit/theme`) for the theme toggle form, which sets the cookie and redirects back. This satisfies the strict "zero JS" requirement and matches standard SSR patterns.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) |
| Config file | `mix.exs` / `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DS-05 | Token parity between `tokens.json` and `style.ex` | unit | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ Wave 0 |
| DS-06 | Decision briefs documented | manual | N/A (Doc update) | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix ci.all`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements. The `brandbook_token_parity_test` is already explicitly noted as existing in the requirements.

## Sources

### Primary (HIGH confidence)
- `172-CONTEXT.md` - Phase constraints and locked decisions
- `.planning/REQUIREMENTS.md` - Phase goals and DS-05/DS-06 definitions
- `brandbook/brand-book.md` - Brand constraints and visual identity

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Phoenix mechanics are well established.
- Architecture: HIGH - Zero-JS cookie toggling is standard in Phoenix.
- Pitfalls: HIGH - Documented directly in context and requirements.

**Research date:** 2026-06-15
**Valid until:** 2026-07-15