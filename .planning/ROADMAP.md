# Roadmap: v1.35 Unified Logo & Brand Book v2

**Status:** active — Phase 159 planned, ready to execute
**Opened:** 2026-06-11
**Approved plan:** `~/.claude/plans/have-to-compare-it-lexical-shore.md`

## Goal

Replace the icon-beside-plain-text logo with a unified, tournament-selected logo system — user always picks the winner — and rebuild `brandbook/index.html` as a standalone professional HTML brand book. All text/SVG, self-contained in `brandbook/`, every logo SVG pure paths.

## Non-goals

- Trademark/legal clearance (flagged for human review in the design brief only).
- Motion/animation guidelines, print/CMYK/Pantone, or merch.
- Naming/tagline changes — "Threadline" and "Follow what happened." are settled.
- Marketing-site / landing-page build (LANDING-01 deferred).
- Runtime operator surface UI changes beyond optional ROLL-01; `style.ex` stays frozen in all scenarios.
- Committed raster exports / font binaries in `brandbook/`.
- Losing tournament candidates graduating to `brandbook/` — only the winner lands there.

## Phases

| Phase | Name | Requirements | Status |
|---|---|---|---|
| 159 | brand-audit-and-research | AUD-01, AUD-02, RES-01, RES-02, RES-03, RES-04 | Planned (3 plans) |
| 160 | glyph-outline-pipeline | GLYPH-01, GLYPH-02, GLYPH-03 | Not started |
| 161 | logo-tournament | TOUR-01, TOUR-02, TOUR-03, TOUR-04, LOGO-01, LOGO-02, LOGO-03, LOGO-04, LOGO-05 | Not started |
| 162 | brand-book-v2 | BOOK-01, BOOK-02, BOOK-03, BOOK-04, BOOK-05, BOOK-06, BOOK-07 | Not started |
| 163 | product-logo-rollout (OPTIONAL) | ROLL-01, ROLL-02, ROLL-03 | Not started — decision-gated |

**Execution order:**
- [ ] **Phase 159: brand-audit-and-research** - Pressure-test the existing brandbook and research devtools/OSS identities, converging into DESIGN-BRIEF.md (parallel with 160).
- [ ] **Phase 160: glyph-outline-pipeline** - fontkit-based text-to-outline pipeline so every logo SVG is pure paths with real shaped kerning (parallel with 159).
- [ ] **Phase 161: logo-tournament** - 8 round-1 candidates across four archetypes; human checkpoint rounds until the user declares a winner.
- [ ] **Phase 162: brand-book-v2** - Graduate the winner into the full `brandbook/` asset family and rebuild the standalone brand book.
- [ ] **Phase 163: product-logo-rollout (OPTIONAL)** - User opts in at an end-of-milestone checkpoint with the winner in hand; declining records ROLL-* as a future-milestone seed, not failures.

## Phase Details

### Phase 159: brand-audit-and-research
**Goal**: A design brief grounded in a pressure-test audit of the existing `brandbook/` plus external devtools/OSS identity research — so round-1 candidates are generated from knowledge, not vibes.
**Depends on**: Nothing (can run parallel with Phase 160)
**Requirements**: AUD-01, AUD-02, RES-01, RES-02, RES-03, RES-04
**Success Criteria** (what must be TRUE):
  1. User can read a complete 14-section `AUDIT.md` with a KEEP/TIGHTEN/REWORK/ADD/REMOVE verdict per section, a 1–10 scorecard, and explicit findings on the icon-left-of-text antipattern and the SVG `<text>` portability bug.
  2. User can see a stress-test matrix executed against the current brand assets across GitHub README render, Hex.pm, HexDocs, 16px favicon, dark mode, light mode, monochrome, and social card.
  3. User can read `RESEARCH.md` with ≥8 cited devtools/OSS identity case studies (including at least one failure case), an integrated-typemark technique catalog, and numeric 16px legibility and monochrome/gradient-dependence thresholds stated as testable constraints.
  4. User can read `DESIGN-BRIEF.md` stating the round-1 generation contract: motif rules, measurable hard constraints (no subtitle in primary, no container chips, must survive 16px and one color), degrees of freedom (OFL-safe typeface and palette exploration), and the four archetype lanes.
  5. Every REWORK/ADD audit item is routed to a downstream requirement or descoped with a recorded reason.
**Plans**: 3 plans (waves: 01 ∥ 02 → 03)

Plans:
- [ ] 159-01-PLAN.md — Brandbook pressure-test audit: 14 sections + verdicts, 15-dimension scorecard, 8-surface stress-test matrix → `159-AUDIT.md` (wave 1)
- [ ] 159-02-PLAN.md — External devtools/OSS identity research: ≥8 cited case studies, typemark technique menu, numeric 16px/monochrome thresholds, surface constraints, OFL typefaces → `159-RESEARCH.md` (wave 1, parallel)
- [ ] 159-03-PLAN.md — Convergence: round-1 generation contract + REWORK/ADD traceability routing → `159-DESIGN-BRIEF.md` (wave 2)

### Phase 160: glyph-outline-pipeline
**Goal**: A reproducible text-to-outline pipeline so every logo SVG is pure paths with real font-shaping kerning — portable everywhere, no font dependency.
**Depends on**: Nothing (can run parallel with Phase 159)
**Requirements**: GLYPH-01, GLYPH-02, GLYPH-03
**Success Criteria** (what must be TRUE):
  1. User can rerun a committed fontkit-based Node script that converts vendored `priv/fonts/geist-*.woff2` (500/600 at minimum) into per-glyph SVG path data for "Threadline" with shaped kerning applied — one `<path>` per glyph, coordinates rounded to 2 decimals.
  2. User can see overlay evidence that generated outlines match a live-font browser render at 2× zoom.
  3. Glyph-kit output contains zero `<text>` elements and renders letterform counters (e/a/d holes) correctly.
**Plans**: 1 plan

Plans:
- [ ] 160-01-PLAN.md — fontkit text-to-paths pipeline, Geist 500/600 glyph kits with determinism proof, 2x overlay evidence, brandbook/tools regeneration copy (wave 1, autonomous)

### Phase 161: logo-tournament
**Goal**: User selects the winning unified logo through feedback-driven elimination rounds — user picks, always; never auto-selected.
**Depends on**: Phase 159, Phase 160
**Requirements**: TOUR-01, TOUR-02, TOUR-03, TOUR-04, LOGO-01, LOGO-02, LOGO-03, LOGO-04, LOGO-05
**Success Criteria** (what must be TRUE):
  1. Round 1 presents exactly 8 concepts meeting the archetype quota (3 integrated typemarks, 3 unified mark+type lockups, 1 monogram/mark-led, 1 wordmark-only), each with a distinct named motif strategy.
  2. User has reviewed every candidate in every round in six contexts (dark background, light background, monochrome, literal 16px favicon + 4× magnification, 32px, simulated GitHub README header) via a self-contained local gallery HTML opened over `file://` with zero network requests.
  3. Per-candidate feedback is recorded verbatim in `ROUNDS.md` with ADVANCE/KILL/MUTATE tags; every round after the first contains only mutations of user-advanced candidates traceable to that feedback (max one user-invited wildcard per round), with a 4-round cap that triggers an explicit decision rather than silent continuation.
  4. Winner is an explicit recorded user statement captured as checkpoint evidence.
  5. No candidate has a background chip, a subtitle in its primary form, an icon-beside-plain-set-type structure, or a `<text>` element — and every candidate ships a monochrome rendition from round 1 onward.
**Plans**: TBD (internal checkpoint loop: round-N-generate → round-N-checkpoint → finalize-winner)

### Phase 162: brand-book-v2
**Goal**: The tournament winner graduated into the full `brandbook/` asset family and a rebuilt standalone professional HTML brand book, with the audit backlog executed.
**Depends on**: Phase 159, Phase 161
**Requirements**: BOOK-01, BOOK-02, BOOK-03, BOOK-04, BOOK-05, BOOK-06, BOOK-07
**Success Criteria** (what must be TRUE):
  1. `brandbook/` contains the full asset family regenerated from the winner — `logo-primary.svg`, `logo-primary-light.svg`, `logo-mark.svg`, `logo-monochrome.svg`, `favicon.svg`, `social-card.svg`, `logo-primary-subtitle.svg` (and `logo-wordmark.svg` if separable) — all pure-path SVGs with zero `<text>` elements.
  2. "FOLLOW WHAT HAPPENED" appears only in the `-subtitle` variant and social card — never in the primary lockup.
  3. User can open `brandbook/index.html` directly from disk as a standalone professional brand book — identity story, logo system with clear-space/minimum-size/misuse gallery, color, typography, voice/microcopy, application examples — with zero external network requests.
  4. The misuse gallery documents the killed antipatterns (background chips, icon-bolted-beside-plain-text, subtitle-in-primary), and every AUD-01 REWORK/ADD item is resolved or explicitly descoped with a recorded reason.
  5. `brandbook/` stays text/SVG/HTML/CSS/JSON-only at ≤ ~300KB with no committed binaries, and the rerun `pressure-test.md` scorecard meets or beats the Phase 159 baseline.
**Plans**: TBD (closes with gsd-verify-work UAT — second hard human gate)

### Phase 163: product-logo-rollout (OPTIONAL)
**Goal**: If the user opts in at the end-of-milestone checkpoint with the winner in hand, the new identity rolls into product surfaces; if declined, the requirements seed a future milestone.
**Depends on**: Phase 162
**Requirements**: ROLL-01, ROLL-02, ROLL-03 (all optional, decision-gated)
**Success Criteria** (what must be TRUE):
  1. User has made an explicit opt-in/decline decision at the end-of-milestone checkpoint with the winning logo in hand.
  2. If opted in: the operator-surface logo component (`lib/threadline/operator_surface/components/logo.ex`) renders the winning mark with the `var(--tl-*)` theming contract preserved and `style.ex` untouched (recorded freeze exception); `mix compile --warnings-as-errors` and `mix verify.test` stay green.
  3. If opted in: the example-app admin favicon uses the new `favicon.svg`, and the root README header uses the new brand assets with dark/light handling that works in GitHub's SVG sandbox.
  4. If declined: ROLL-01–03 are recorded as a seed for a future milestone — not failures.
**Plans**: TBD (decision gate first)
**UI hint**: yes

## Human Gates

- Every tournament round checkpoint (gallery open, per-candidate verdicts).
- Winner declaration (explicit user statement, Phase 161).
- Brand book UAT (gsd-verify-work, Phase 162).
- Rollout opt-in decision (Phase 163 gate).

## Latest Shipped Milestone

<details>
<summary>✅ v1.34 Local Docker Admin UI DX (Phases 154-158) - SHIPPED 2026-06-07</summary>

Full archive: `.planning/milestones/v1.34-ROADMAP.md`

</details>

- ✅ **v1.33 Brand Review + Direction Selection** — Phases 150-153 (shipped 2026-06-06). Archive: `.planning/milestones/v1.33-ROADMAP.md`
- ✅ **v1.32 Brand System Foundation** — Phases 145-149 (shipped 2026-06-05). Archive: `.planning/milestones/v1.32-ROADMAP.md`
