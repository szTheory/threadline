# Phase 172: foundations-audit-hardening - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Foundations (color, typography, spacing, radius, shadow, z-index, density, motion tokens) are audited against the brand book; off-brand / contrast / scale gaps are fixed; any new token lands in `brandbook/tokens.{json,css}` first and keeps the parity test green. Each significant foundation decision is captured as a compact decision brief.
</domain>

<decisions>
## Implementation Decisions

### Token Override Approach
- **D-01:** **Semantic Token Mapping in style.ex**. Keep `brandbook/tokens.json` strictly for primitive brand tokens (Thread Blue, Graphite, Fog, Space 1-16). In `style.ex`, map these primitives to functional UI tokens (e.g., `--tl-color-surface-hover`, `--tl-color-border-focus`). The parity test only enforces the primitive tokens. This maintains the SSOT for the brand while giving the operator surface the flexibility to compose functional states without polluting the brand book with component-specific CSS.

### Decision Brief Format
- **D-02:** **Hybrid (Code-anchored + Markdown Ledger).** Write the full decision briefs in the `DESIGN-SYSTEM.md` v2 ledger (requirement DS-02). In `style.ex`, leave a concise 1-2 line comment with a pointer to the specific section in `DESIGN-SYSTEM.md` (e.g., `/* See DESIGN-SYSTEM.md § "Light Mode Table Hover" */`). This keeps `style.ex` clean but ensures anyone changing the token understands why it exists, preventing the "Grafana lesson" footgun.

### Motion Reductions
- **D-03:** **Cross-fade fallback.** For `@media (prefers-reduced-motion: reduce)`, do not use `0ms` universally. Instead, zero out positional transitions (`transform`, `translate`, `scale`) but preserve opacity fades (e.g., `120ms ease`). This keeps the UI feeling polished and communicative (things still "appear") without causing motion sickness, aligning with the brand's "calm in tense moments" trait.

### Folded Todos
- **Dark/light/system theme picker with idiomatic UI controls (THEME-TOGGLE-01 demand signal)**
  - *Original Problem:* Need a runtime dark/light/system picker with idiomatic UI controls.
  - *How it fits:* Folded as an idiomatic, zero-JS segmented control using Plug + Cookie to persist the selection. LiveView `phx-click` sends an event, saves the cookie, and patches the UI. Fits the NAV/foundations scope.
- **Transaction page content left-pushed at desktop widths (theme-independent layout bug)**
  - *Original Problem:* Transaction page content is left-pushed at desktop widths.
  - *How it fits:* Folded. Will fix the max-width container (`.tl-home` or similar `.tl-container` class) with `max-width: 1000px; margin: 0 auto;` to ensure content is centered on ultra-wide desktop monitors, maintaining readability.
- **Coverage "schema: public" card de-clutter (reduce nested border/padding blocks)**
  - *Original Problem:* Coverage "schema: public" card has too many nested borders.
  - *How it fits:* Folded. Flatten the card-in-card structure. Remove the outer border/background for the schema grouping and just use a header, letting individual table cards sit directly on the page background to reduce visual noise.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand and UI Specs
- `.planning/phases/172-foundations-audit-hardening/172-UI-SPEC.md` — UI Design Contract (Visual and interaction contract for frontend phases)
- `brandbook/brand-book.md` — Threadline Brand Book (Source of truth for brand DNA, typography, colors, layout, and copy)
- `DESIGN-SYSTEM.md` — Living inventory of foundation tokens, primitives, and forms
- `lib/threadline/operator_surface/style.ex` — Core CSS token definitions and operator surface styling
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/threadline/operator_surface/style.ex`: Contains the base CSS, custom properties (`--tl-*`), and light/dark theme lanes. Modifications for motion and token overrides will happen here.
- `lib/threadline/operator_surface/presentation.ex`: Presentation helpers.

### Established Patterns
- **Zero-JS Theme Toggle:** `data-tl-theme` attribute applied on the LiveView root, driven by server-side state. The theme picker will reuse this pattern via cookies and a Plug.
- **Token Naming:** Variables are prefixed with `--tl-`. Primitive colors like `--tl-color-accent` vs functional roles like `--tl-color-accent-border`.

### Integration Points
- `threadline_operator_surface` namespace module where the theme-picker Plug will integrate.
- Page templates (e.g., `coverage_live.ex`, `transaction_live.ex`) for layout bug fixes and card de-cluttering.
</code_context>

<specifics>
## Specific Ideas

- Implement the "Emil Kowalski / GOV.UK" approach for reduced motion (opacity fades over 0ms).
- Keep component-specific functional tokens in `style.ex` while maintaining strict `brandbook/tokens.json` parity for primitive tokens.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope
</deferred>

---

*Phase: 172-foundations-audit-hardening*
*Context gathered: 2026-06-15*