# Phase 141: motion-micro-animation - Context

**Gathered:** 2026-06-04
**Status:** Ready for research and planning
**Mode:** auto-selected defaults from Phase 141 roadmap and Phase 140 boundary

<domain>
## Phase Boundary

Phase 141 owns the operator-surface motion layer only:

- Document a motion inventory that maps each shipped animation to trigger, JTBD, and token.
- Reuse the existing `120ms`, `180ms`, and `240ms` timing tokens plus the signature thread-draw pattern.
- Ensure every animated surface honors `prefers-reduced-motion`.
- Remove, neutralize, or justify any gratuitous motion.

This phase must not broaden into Phase 142 responsive/mobile-first layout work or Phase 143 accessibility/screenshot-diff infrastructure. It may add focused tests or source-contract checks for motion tokens, inventory completeness, and reduced-motion coverage.
</domain>

<auto_decisions>
## Auto-Selected Discussion Decisions

- **D-01:** Treat motion as a design-system contract, not as decorative polish. Every animation must have an explicit trigger, JTBD, and token entry.
- **D-02:** Keep the current motion token scale as authoritative: `--tl-motion-fast: 120ms`, `--tl-motion-base: 180ms`, `--tl-motion-slow: 240ms`, `--tl-motion-stagger: 40ms`, `--tl-motion-distance-sm: 8px`, and `--tl-motion-distance-md: 16px`.
- **D-03:** Reuse existing keyframes (`tl-rise-in`, `tl-thread-draw`, `tl-drawer-in`, `tl-fade-in`, `tl-copy-pulse`) unless research proves a narrow need. Do not add ad-hoc one-off keyframes or literal durations.
- **D-04:** Preserve the signature Signal Cyan thread-draw as the branded motion motif. It may appear only where it clarifies a completed path, primary entry, or evidence/proof progression.
- **D-05:** Keep motion GPU-friendly: `opacity` and `transform` are preferred; layout-affecting motion must remain rare and justified.
- **D-06:** `prefers-reduced-motion: reduce` must cover every animation and transition. Prefer a single scoped blanket plus targeted overrides where visual state would otherwise remain transformed.
- **D-07:** Inventory documentation is a deliverable, not optional commentary. It should live under Phase 141 artifacts and be testable against source names/tokens.
- **D-08:** Avoid broad visual redesign. Phase 141 may refine existing animated surfaces but should not change IA, content hierarchy, route behavior, mobile layouts, or export/row-history semantics.
- **D-09:** Browser verification should use focused motion/reduced-motion assertions, not screenshot baselines or broad responsive matrix checks reserved for later phases.
</auto_decisions>

<existing_motion_surface>
## Current Motion Surface To Inventory

The current operator-surface CSS already contains motion primitives and shipped uses:

- Tokens in `lib/threadline/operator_surface/style.ex`: `--tl-motion-fast`, `--tl-motion-base`, `--tl-motion-slow`, `--tl-motion-stagger`, `--tl-motion-distance-sm`, `--tl-motion-distance-md`, `--tl-ease-standard`, `--tl-ease-out`, and `--tl-transition-fast`.
- Generic link/button/control transitions for color, background, border, box-shadow, and transform.
- Home launcher card entrance via `tl-rise-in` and staggered delays.
- Home primary card signature thread via `tl-thread-draw`.
- Subview/drawer entrance via `tl-drawer-in` and row-history panel rise/fade sequencing.
- Collapsible sections using tokenized `block-size` / `content-visibility` transition.
- Copy feedback via `tl-copy-pulse`.
- Journey/proof thread-draw and redaction-success thread-draw moments.
- Reduced-motion blanket at the end of `Style.css` that collapses animation and transition durations and resets transform-sensitive surfaces.
</existing_motion_surface>

<persona_mapping>
## Persona/JTBD Contract

- **P1 Incident Responder:** Motion may clarify thread continuity and active context changes without slowing triage.
- **P2 Support Agent:** Motion may make Home/record lookup state changes legible but must not distract from lookup speed.
- **P3 Compliance/Security Reviewer:** Motion may reinforce export/proof handoff completion and evidence continuity.
- **P4 Audit Operator/SRE:** Motion must preserve scan density and operational confidence; no decorative loops or attention traps.
- **P5 Adopter Developer:** Motion tokens and inventory should be easy to audit and override in host apps.
</persona_mapping>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` - Phase 141 goal and success criteria.
- `.planning/REQUIREMENTS.md` - `POLISH-MOTION`.
- `.planning/phases/140-earned-new-flows/140-VERIFICATION.md` - earned-flow baseline to preserve.
- `.planning/phases/140-earned-new-flows/140-RESEARCH.md` - Phase 140 explicitly deferred motion refinements to Phase 141.
- `lib/threadline/operator_surface/style.ex` - motion tokens, keyframes, current animated surfaces, and reduced-motion media query.
- `test/threadline/operator_surface/style_contract_test.exs` - existing source-contract pattern for CSS/design-system assertions.
- `examples/threadline_phoenix/e2e/playwright.config.ts` - existing Playwright reduced-motion setting and browser test configuration.
- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts`, `operator-earned-flows.spec.ts`, `operator-find-mobile.spec.ts`, and `operator-prove-mobile.spec.ts` - focused browser UAT analogs.
</canonical_refs>

<implementation_guidance>
## Planning Guidance

- Start with a motion inventory and source-contract tests so the phase has an auditable spine before changing CSS.
- Prefer small vertical slices around named motion surfaces: token/inventory contract, Home/thread-draw, subview/proof transitions, and reduced-motion browser verification.
- Use tests to reject literal duration drift, uncovered keyframes, and missing reduced-motion coverage.
- Keep animation additions scarce. Strengthening documentation, removing stray ad-hoc transitions, or adding reduced-motion assertions can satisfy much of this phase.
- Do not introduce JavaScript animation libraries, external dependencies, visual snapshot baselines, or route/state changes.
</implementation_guidance>

<deferred>
## Deferred Beyond Phase 141

- Breakpoint scale and broad mobile-first layout work.
- Final accessibility sweep, focus-order audit, and screenshot-diff guard.
- New earned flows, export workflows, or row-history semantics.
- Cross-app theme customization APIs for motion.
</deferred>

---
*Phase: 141-motion-micro-animation*
*Context gathered: 2026-06-04*
