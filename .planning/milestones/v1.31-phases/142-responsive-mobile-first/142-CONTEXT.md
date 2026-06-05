# Phase 142: responsive-mobile-first - Context

**Gathered:** 2026-06-04
**Status:** Ready for research and planning
**Mode:** auto-selected defaults from Phase 142 roadmap and prior responsive evidence

<domain>
## Phase Boundary

Phase 142 owns genuine mobile-first responsiveness across the operator surface:

- Tokenize a breakpoint scale and use it consistently instead of scattered literal media query widths.
- Give tables, filters/toolbars, drawers/subviews, and top navigation mobile-first layouts.
- Verify every operator-surface screen at 375, 768, and 1280 viewport widths.
- Eliminate document-level horizontal overflow regressions while preserving intentional internal scroll containers where they are the right interaction.

This phase must not broaden into Phase 143 final accessibility/screenshot-diff infrastructure or new product workflows. It may add focused browser UAT, source-contract tests, and narrowly scoped CSS/layout changes.
</domain>

<auto_decisions>
## Auto-Selected Discussion Decisions

- **D-01:** Treat `375 / 768 / 1280` as the acceptance viewport matrix because it is explicit in the roadmap and requirement.
- **D-02:** Preserve the existing operator-console visual language and IA. Responsive work should improve layout behavior, density, wrapping, and scroll ownership without redesigning the surface.
- **D-03:** Tokenize breakpoints in `Style.css` as source-level custom properties/documented constants where CSS supports them, but keep actual `@media` queries standards-compliant. If CSS custom properties cannot be used directly in media queries, pair variables with source-contract tests that lock literal media widths to named tokens.
- **D-04:** Keep the topbar navigation reachable on mobile. Internal nav horizontal scroll is acceptable only when explicitly owned by `.tl-topbar__nav`; document/root horizontal overflow is not acceptable.
- **D-05:** Tables should be mobile-first labelled cards at narrow widths and restore true table semantics at desktop widths. Each table-like surface must use a shared responsive pattern rather than bespoke ad-hoc overflow.
- **D-06:** Filters and toolbar controls should stack on phones, wrap at tablet, and align as a compact toolbar on desktop.
- **D-07:** Drawers/subviews should fit 375px without clipping primary controls or values; desktop may keep the right-side drawer width.
- **D-08:** Browser verification must cover representative operator routes in one responsive matrix, using computed document overflow and key reachability checks rather than screenshot baselines.
- **D-09:** Keep Phase 142 independent of Phase 143: do not build screenshot-diff CI, final visual diff baselines, or broad ARIA/focus audits here.
</auto_decisions>

<existing_responsive_surface>
## Current Responsive Surface To Preserve And Improve

Current CSS already has a mobile-first foundation in `lib/threadline/operator_surface/style.ex`:

- Base phone layout for `.tl-page`, `.tl-topbar`, `.tl-home`, `.tl-toolbar`, `.tl-table--responsive`, `.tl-subview`, and shared cards.
- Hard-coded media layers at `@media (min-width: 481px)` and `@media (min-width: 721px)`.
- Responsive tables stack into labelled card rows by default and restore table display at desktop.
- `.tl-topbar__nav` intentionally owns horizontal scrolling for compact mobile navigation.
- `.tl-table-wrap` owns table overflow when desktop-style tables exceed available width.
- Existing no-overflow helper patterns live in Playwright specs for Home/Nav, Find, Prove, Earned Flows, and Motion.

Known gap from the roadmap: the breakpoint scale is not tokenized around the accepted 375 / 768 / 1280 matrix, and no single proof confirms every operator surface at all three widths.
</existing_responsive_surface>

<screen_matrix>
## Screens In Scope

Phase 142 should treat these operator-surface routes as the baseline matrix unless research finds a missing enabled route:

- `/audit`
- `/audit/timeline`
- `/audit/coverage`
- `/audit/transactions/:id` using seeded demo data
- `/audit/rows/:table/:record_id` using seeded demo data
- `/audit/actors/:type/:id` using seeded demo data
- `/audit/evidence`
- `/audit/policy/redaction`
- `/audit/policy/retention`
- `/audit/exports`

The matrix should include 375, 768, and 1280 widths. Height may follow existing Playwright project defaults or use a stable 812/900 height per viewport where practical.
</screen_matrix>

<persona_mapping>
## Persona/JTBD Contract

- **P1 Incident Responder:** Needs Timeline, transaction, row-history, actor, and correlation views to remain scannable on a phone during an incident.
- **P2 Support Agent:** Needs record-first and row-history layouts to fit a 375px support workflow without horizontal document scrolling.
- **P3 Compliance/Security Reviewer:** Needs Evidence, Redaction, Retention, and Exports dense states to remain readable across tablet and desktop.
- **P4 Audit Operator/SRE:** Needs topbar/nav, health, coverage, and toolbar controls to remain reachable without hidden controls.
- **P5 Adopter Developer:** Needs a tokenized responsive scale and source-contract tests that make host-app layout regressions diagnosable.
</persona_mapping>

<canonical_refs>
## Canonical References

- `.planning/ROADMAP.md` - Phase 142 goal and success criteria.
- `.planning/REQUIREMENTS.md` - `POLISH-RESPONSIVE`.
- `.planning/phases/139-orientation-hub-home-nav/139-03-SUMMARY.md` - mobile Home/nav reachability and `.tl-topbar__nav` as intentional scroll owner.
- `.planning/phases/138-find-cluster-polish/138-04-SUMMARY.md` - Find mobile UAT across Timeline, Transaction, Row History, Actor, and Coverage.
- `.planning/phases/137-prove-cluster-polish/137-VERIFICATION.md` - Prove dense-state mobile UAT.
- `.planning/phases/141-motion-micro-animation/141-VERIFICATION.md` - motion baseline to preserve.
- `lib/threadline/operator_surface/style.ex` - responsive CSS, breakpoint literals, tables, toolbars, drawers, and topbar.
- `test/threadline/operator_surface/style_contract_test.exs` - source-contract test pattern for CSS tokens.
- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts`
</canonical_refs>

<implementation_guidance>
## Planning Guidance

- Start with breakpoint/token/source-contract work so CSS and browser tests share a stable responsive vocabulary.
- Plan vertical layout slices around shared primitives: topbar/nav, toolbar/filter controls, responsive tables/cards, and drawers/subviews.
- Add one focused responsive matrix Playwright spec that logs in once per viewport group, visits the screen matrix, verifies no document-level horizontal overflow, and checks key controls remain reachable.
- Use seeded demo discovery patterns from Phase 140/141 browser specs for transaction, row-history, and actor routes.
- Do not require screenshots for acceptance; computed overflow, visibility, route reachability, and source contracts are the primary automated proof.
- Keep internal scroll exceptions explicit: topbar nav and table wrappers may scroll internally, but root document overflow should remain within a 1px tolerance.
</implementation_guidance>

<deferred>
## Deferred Beyond Phase 142

- Final accessibility sweep, focus-order audit, and ARIA baseline.
- Screenshot-diff infrastructure and baseline explanation.
- New routes, new workflows, or semantic changes to exports, row history, policy, evidence, or coverage.
- Broad visual redesign or theme changes.
</deferred>

---
*Phase: 142-responsive-mobile-first*
*Context gathered: 2026-06-04*
