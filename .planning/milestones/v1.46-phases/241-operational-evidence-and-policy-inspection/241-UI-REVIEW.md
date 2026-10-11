---
phase: 241
audited: 2026-10-10
status: passed_with_advisories
blockers: 0
warnings: 3
score: 21/24
reviewer: Codex inline
---

# Phase 241: UI Review

Audited against `241-UI-SPEC.md`, current source, fresh full-shell captures of Coverage/Evidence/Redaction at 1280 and 320 CSS pixels, and executable route proofs. Captures were taken from synthetic partition 24111 after the final source fix; their ignored manifest records the candidate head, all 23 source hashes, browser version, inline-style hash and screenshot hashes. Animations were allowed to finish before capture. All six captures have zero document overflow.

Screenshots and manifest: `examples/threadline_phoenix/e2e/artifacts/phase241-review/`. Storage was confirmed ignored before capture. This is a bounded inline review, not milestone-wide before/after acceptance or an independent agent pass. Selected-reference history, Light/System appearance, failure states, input modes and real zoom are supported by tests; the screenshot set itself is Dark, populated state only.

## Pillar Scores

| Pillar | Score | Finding |
|--------|-------|---------|
| Copywriting | 3/4 | Unavailable/no-match and current-deployment limits are precise; the retained section heading “Could not introspect” differs from the clearer row label “Could not inspect”. |
| Visuals | 4/4 | Coverage remains a scoped table, Evidence uses subject-grouped cards, and Policy retains paired comparisons; no new decorative surface or missing asset appeared in the bounded captures. |
| Color | 4/4 | Existing semantic tokens and explicit status text remain; this phase introduces zero hardcoded colors or styles. Light/Dark/System route cases execute separately. |
| Typography | 4/4 | Existing type roles and mono identifiers are retained; no new size/weight/font declaration. Exact references are disclosed/copied through existing controls rather than relying on truncated previews. |
| Spacing | 3/4 | The new policy refresh cluster touches the posture card; the inherited evidence footer links are also close to the card edge. |
| Experience Design | 3/4 | Scope, visible focus, keyboard/touch, reduced motion and real zoom are proven; inherited evidence footer links remain compact beside each other on narrow layouts. |

**Overall: 21/24. No blocker prevents inspection task completion.**

## Advisory Dispositions

| ID | Finding and impact | Disposition |
|----|--------------------|-------------|
| UI-241-01 | Policy refresh directly abuts the posture card at both capture widths. Reachability is proven, but section rhythm is weaker here. | Deferred to Phase 243 integrated visual cleanup: use the existing spacing/component system for separation; preserve refresh behavior and required controls. |
| UI-241-02 | Existing Evidence group footer links sit close to one another and the card edge at 320px. Primary history actions are separate and reachable. | Deferred to Phase 243: inspect padding/gap and existing compact target treatment together with the integrated Evidence layout. |
| UI-241-03 | Existing unreadable section heading uses “Could not introspect”, while its per-row status says “Could not inspect”. Meaning remains distinct from matching deployment. | Deferred to Phase 243 copy consistency review; maintain the public `could_not_introspect` status value. |

The first item is introduced by the recovered action, and the latter two are inherited. No spacing, token or baseline changes were made merely to inflate this review score.

## Behavioral Evidence

The route-specific cases exercise 320/768/1280 CSS pixels in Light/Dark/System in both voting projects, keyboard or touch with visible focus, normalized policy disclosure, missing and unreadable triggers, and reduced motion. Desktop extension readback verifies tab zoom factor 2 with a 640 CSS-pixel viewport, zero document overflow and reachable controls on all three routes. Mobile extension zoom is an explicit unsupported-capability skip.

No registry or external UI package was used. Baselines and ratchet signoffs were not changed. Full candidate integration and visual comparison remain Phase 243 work.
