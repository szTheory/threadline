# Requirements: Threadline v1.35 Unified Logo & Brand Book v2

**Defined:** 2026-06-11
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.35 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Brand Audit

- [ ] **AUD-01**: User can read a complete 14-section pressure-test audit of the existing `brandbook/` (KEEP/TIGHTEN/REWORK/ADD/REMOVE verdict per section plus a 1–10 scorecard), including an explicit audit of the current logo against the icon-left-of-text antipattern and the SVG `<text>` portability bug.
- [ ] **AUD-02**: User can see a stress-test matrix executed against the current brand assets across real surfaces: GitHub README render, Hex.pm, HexDocs, favicon at 16px, dark mode, light mode, monochrome, and social card.

### Design Research

- [x] **RES-01**: User can read ≥8 devtools/OSS identity case studies (with sources) covering mark/type relationship, favicon survival, and dark/light strategy — including at least one failure case.
- [x] **RES-02**: User can read an integrated-typemark technique catalog (negative space, stroke continuation, counter replacement, ligature, continuous line) extracted as a reusable menu for candidate generation.
- [x] **RES-03**: User can read numeric small-size legibility thresholds (16px favicon stroke/detail floors) and monochrome/gradient-dependence rules stated as testable constraints, not adjectives.
- [x] **RES-04**: User can read a `DESIGN-BRIEF.md` that synthesizes audit + research into the round-1 generation contract: motif rules, hard constraints (no subtitle in primary, no container chips, must survive 16px and one color), degrees of freedom (OFL-safe typeface and palette exploration), and the four archetype lanes.

### Glyph Outline Pipeline

- [x] **GLYPH-01**: User can rerun a committed Node script that converts vendored woff2 fonts (Geist 500/600 at minimum) into per-glyph SVG path data for "Threadline" with real font-shaping kerning applied — one `<path>` per glyph, coordinates rounded to 2 decimals.
- [x] **GLYPH-02**: User can see overlay evidence that generated outlines match a live-font browser render at 2× zoom.
- [x] **GLYPH-03**: Glyph-kit output contains zero `<text>` elements and renders letterform counters (e/a/d holes) correctly.

### Logo Tournament

- [x] **TOUR-01**: User sees exactly 8 round-1 concepts spanning the archetype quota (3 integrated typemarks, 3 unified mark+type lockups, 1 monogram/mark-led, 1 wordmark-only), each with a distinct named motif strategy.
- [x] **TOUR-02**: User can review every candidate in every round in a self-contained local gallery HTML (file://, zero network) showing six contexts: dark background, light background, monochrome, literal 16px favicon (+4× magnification), 32px, and a simulated GitHub README header.
- [x] **TOUR-03**: User's per-candidate feedback is recorded verbatim in `ROUNDS.md` with ADVANCE/KILL/MUTATE tags, and the winner is an explicit user statement captured as checkpoint evidence — never auto-selected.
- [x] **TOUR-04**: Each round after the first contains only variations/mutations of user-advanced candidates traceable to recorded feedback (max one user-invited wildcard per round), with a 4-round cap that triggers an explicit decision rather than silent continuation.

### Logo System Constraints

- [x] **LOGO-01**: No candidate uses an icon-beside-plain-set-type structure as its primary form — every candidate is an integrated typemark or a lockup where mark and type are demonstrably designed as one unit (shared geometry, tight optical spacing).
- [x] **LOGO-02**: No rectangular or rounded-rectangle background container appears behind any mark in any candidate or final asset — marks work directly on the canvas.
- [x] **LOGO-03**: The primary lockup contains no subtitle/tagline text; the tagline appears only in a separate `-subtitle` variant.
- [x] **LOGO-04**: Every candidate ships with a monochrome single-color rendition from round 1 onward, judged alongside the color version.
- [x] **LOGO-05**: Every candidate and final logo SVG is pure outlines/paths with zero `<text>` elements.

### Brand Book v2

- [x] **BOOK-01**: User can use a full asset family regenerated from the tournament winner in `brandbook/`: `logo-primary.svg`, `logo-primary-light.svg`, `logo-mark.svg`, `logo-monochrome.svg`, `favicon.svg`, `social-card.svg`, plus `logo-primary-subtitle.svg` (and `logo-wordmark.svg` if the winner has a separable wordmark) — all pure-path SVGs.
- [x] **BOOK-02**: The primary lockup in `brandbook/` carries no subtitle; "FOLLOW WHAT HAPPENED" appears only in the `-subtitle` variant and social card.
- [ ] **BOOK-03**: User can open `brandbook/index.html` directly from disk as a standalone professional brand book — identity story, logo system (clear-space, minimum size, misuse gallery), color, typography, voice/microcopy, application examples — with zero external network requests.
- [ ] **BOOK-04**: Every REWORK/ADD item from AUD-01 is either resolved in the new brand book or explicitly descoped with a recorded reason.
- [ ] **BOOK-05**: The misuse gallery documents the killed antipatterns: background chips, icon-bolted-beside-plain-text, and subtitle-in-primary.
- [ ] **BOOK-06**: `brandbook/` stays text/SVG/HTML/CSS/JSON-only at ≤ ~300KB total, with no committed binaries; tokens/`brand-book.md` updated only if the winner motivated palette/typography changes.
- [ ] **BOOK-07**: `pressure-test.md` is rerun against the new system and its scorecard meets or beats the AUD-01 baseline.

### Product Rollout (optional — user opts in at end-of-milestone checkpoint)

- [ ] **ROLL-01**: If opted in: the operator-surface logo component (`lib/threadline/operator_surface/components/logo.ex`) renders the winning mark while preserving the `var(--tl-*)` theming contract, with `style.ex` untouched (recorded freeze exception).
- [ ] **ROLL-02**: If opted in: the example-app admin favicon uses the new `favicon.svg`.
- [ ] **ROLL-03**: If opted in: the root README header uses the new brand assets with dark/light handling that works in GitHub's SVG sandbox.

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Public Rollout

- **HEXDOCS-BRAND-01**: Evaluate restrained ExDoc brand treatment after docs IA is stable.
- **LANDING-01**: Public landing page, only after a separate IA/content scope is selected.
- **SOCIAL-PNG-01**: Social-card PNG export, only when a downstream channel requires raster.

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Trademark/legal clearance | Human/legal review remains outside GSD automation; flagged in the design brief only. |
| Motion/animation guidelines, print/CMYK/Pantone, merch | Not needed for OSS repo surfaces; no downstream consumer exists. |
| Naming/tagline alternatives | "Threadline" and "Follow what happened." are settled; this milestone redesigns the visual identity, not the language. |
| Runtime operator surface changes beyond optional ROLL-01 | v1.31 froze the operator surface design contract; `style.ex` stays untouched in all scenarios. |
| Marketing-site / landing-page build | Requires separate IA and content scope (LANDING-01 deferred). |
| Committed raster exports / font binaries in brandbook/ | Repo stays text/SVG-first; fonts already vendored under `priv/fonts/`. |
| Losing tournament candidates in `brandbook/` | Only the winner graduates; candidates archive with the phase history. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUD-01 | Phase 159 | Pending |
| AUD-02 | Phase 159 | Pending |
| RES-01 | Phase 159 | Complete |
| RES-02 | Phase 159 | Complete |
| RES-03 | Phase 159 | Complete |
| RES-04 | Phase 159 | Complete |
| GLYPH-01 | Phase 160 | Complete |
| GLYPH-02 | Phase 160 | Complete |
| GLYPH-03 | Phase 160 | Complete |
| TOUR-01 | Phase 161 | Complete |
| TOUR-02 | Phase 161 | Complete |
| TOUR-03 | Phase 161 | Complete |
| TOUR-04 | Phase 161 | Complete |
| LOGO-01 | Phase 161 | Complete |
| LOGO-02 | Phase 161 | Complete |
| LOGO-03 | Phase 161 | Complete |
| LOGO-04 | Phase 161 | Complete |
| LOGO-05 | Phase 161 | Complete |
| BOOK-01 | Phase 162 | Complete |
| BOOK-02 | Phase 162 | Complete |
| BOOK-03 | Phase 162 | Pending |
| BOOK-04 | Phase 162 | Pending |
| BOOK-05 | Phase 162 | Pending |
| BOOK-06 | Phase 162 | Pending |
| BOOK-07 | Phase 162 | Pending |
| ROLL-01 | Phase 163 | Pending (optional) |
| ROLL-02 | Phase 163 | Pending (optional) |
| ROLL-03 | Phase 163 | Pending (optional) |

**Coverage:**
- v1.35 requirements: 28 total (25 core + 3 optional rollout)
- Mapped to phases: 28/28 ✓ (Phase 159: 6, Phase 160: 3, Phase 161: 9, Phase 162: 7, Phase 163: 3 optional)
- Unmapped: 0

---
*Requirements defined: 2026-06-11*
*Last updated: 2026-06-11 after v1.35 roadmap creation (phases 159–163 mapped)*
