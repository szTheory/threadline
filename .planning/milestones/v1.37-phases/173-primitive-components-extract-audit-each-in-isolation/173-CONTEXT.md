# Phase 173: Primitive components (extract + audit each in isolation) - Context

**Gathered:** 2026-06-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract the class-soup primitive and overlay/disclosure set into internal private function components, each audited in isolation with a full interaction-state matrix and correct a11y semantics. No public/host-facing API is exposed.

</domain>

<decisions>
## Implementation Decisions

### Component Module Structure
- **D-01:** **Single module for primitives (`Threadline.OperatorSurface.UI` or `CoreComponents`).** Keep all primitives (button, badge, alert, dialog, etc.) in a single cohesive module matching Phoenix's `core_components.ex` idiom, avoiding file explosion for simple pure functions.

### Component API Design (Attrs & Slots)
- **D-02:** **Strict validation.** Use explicit `@doc` and typed `attr`, failing at compile-time for typos to ensure robust internal use.

### Overlay Management
- **D-03:** **Phoenix.LiveView.JS commands.** Use Phoenix.LiveView.JS for simple toggles and modal/drawer state, avoiding custom JS hooks to keep it JS-light and fail-closed.

### Folded Todos
- **Coverage "schema: public" card de-clutter (reduce nested border/padding blocks)**
  - *Original Problem:* Coverage "schema: public" card has too many nested borders.
  - *How it fits:* Folded into the component group extraction, specifically reducing visual noise using the newly audited primitive components.
- **Dark/light/system theme picker with idiomatic UI controls (THEME-TOGGLE-01 demand signal)**
  - *Original Problem:* Need a runtime dark/light/system picker with idiomatic UI controls.
  - *How it fits:* Primitives required for the segmented control / toggle will be audited and extracted in this phase, paving the way for Phase 175.
- **Transaction page content left-pushed at desktop widths (theme-independent layout bug)**
  - *Original Problem:* Transaction page content is left-pushed at desktop widths.
  - *How it fits:* Foundational container/layout primitives established in this phase will fix alignment issues globally.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Brand and UI Specs
- `.planning/phases/172-foundations-audit-hardening/172-UI-SPEC.md` — UI Design Contract (Visual and interaction contract for frontend phases)
- `brandbook/brand-book.md` — Threadline Brand Book (Source of truth for brand DNA, typography, colors, layout, and copy)
- `DESIGN-SYSTEM.md` — Living inventory of foundation tokens, primitives, and forms
- `lib/threadline/operator_surface/style.ex` — Core CSS token definitions and operator surface styling

### Phase Scope And Requirements
- `.planning/ROADMAP.md` — Phase 173 goal, dependencies, success criteria.
- `.planning/REQUIREMENTS.md` — COMP-01, COMP-02, COMP-03.
- `.planning/PROJECT.md` — Current milestone description, product posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/threadline/operator_surface/components/icon.ex`: Existing internal icon component, will be integrated into or act alongside the new primitives.
- `lib/threadline/operator_surface/components/logo.ex`: Existing internal logo component.
- `lib/threadline/operator_surface/components/surface_header.ex`: Contains current component patterns.

### Established Patterns
- **Internal Components Only:** All components lack a public/host-facing API, aligning with v1.31 freeze intent.
- **Fail-closed Auth:** Stress lab routes/components are strictly dev/test-gated.

### Integration Points
- `/audit/__stress` route for mounting and testing each new primitive.
- Existing LiveView HEEx templates (e.g. `actor_live.ex`) to be refactored to use the new `CoreComponents`/`UI` module.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches. Ensure interaction states (hover, focus-visible, active, disabled) are fully represented.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 173-Primitive components (extract + audit each in isolation)*
*Context gathered: 2026-06-15*