# 159-DESIGN-BRIEF.md — Round-1 Generation Contract

- **Phase:** 159-brand-audit-and-research — Plan 03 (convergence)
- **Requirement:** RES-04
- **Inputs:** `159-AUDIT.md` (14 verdicts, 15-dimension scorecard baseline 79/150, 8-surface stress matrix, GAP-01..12, UP-01..11) and `159-RESEARCH.md` (11 case studies, 6-technique motif catalog, numeric 16px/monochrome thresholds, surface constraints, OFL typeface candidates)
- **Consumer:** Phase 161 (logo tournament) generates all round-1 candidates against this contract; Phase 162 (brand book v2) verifies final assets against it. Every rule below is checkable without judgment calls.
- **Date:** 2026-06-12

This is a contract, not an essay. Where a rule has a number, the number is the rule. Where a rule says MUST or MUST NOT, there is no discretionary middle.

---

## 1. What we keep

The audit verdicted the verbal system and infrastructure KEEP. Candidates MUST NOT relitigate any of it:

| Kept element | Audit verdict | What it means for candidates |
|---|---|---|
| Brand DNA — essence "Threadline makes system history followable", audience, emotional register, anti-traits (not flashy, not cute, not cyberpunk, not militarized, not compliance-bureaucratic, not generic SaaS) | KEEP (AUDIT §2) | Candidates are judged against the anti-trait list; a mark that feels flashy or cute fails regardless of craft (AUDIT §10 verdict) |
| Visual metaphor — "a line that connects discrete points into an intelligible path" | KEEP (AUDIT §2) | The metaphor stays; what changes is that the winning mark must *embody* it structurally instead of *adjacent-placing* it beside the name (AUDIT Finding E2) |
| Voice and microcopy system — say-this/not-this pairs, banned vocabulary, testable writing rules | KEEP (AUDIT §10) | Acceptance criterion for candidates, not a revision target |
| Palette philosophy — night-infrastructure system, dual-mode semantic roles (scorecard 8/10) | KEEP (AUDIT §3 dim 9, §7) | A seed, not a contract — see Degrees of freedom (§4) |
| Token infrastructure — tokens.json/tokens.css dual format, raw/semantic layering, operator-surface lane discipline | KEEP (AUDIT §7) | Untouched in Phase 161; additive changes only if the winner shifts the accent palette |
| Landing/docs blueprints and ready-to-use copy | KEEP (AUDIT §11) | Out of v1.35 blast radius except mechanical asset-reference swaps |
| Naming and tagline — "Threadline" and "Follow what happened." | Settled (REQUIREMENTS.md Out of Scope) | Out of scope for candidates; no naming or tagline alternatives in any round |

Also carried forward from the audit's REWORK sections: the asset-roster *shape* (primary dark/light, icon mark, monochrome, favicon, social card) and the textual misuse rules (no mascot, no shields, no rotation, no glow) survive even though every current mark does not (AUDIT §8).

## 2. Motif rules

Every candidate MUST be built on a named motif strategy drawn from the research technique catalog. The six sanctioned technique names, used verbatim from `159-RESEARCH.md` §2, are:

1. **Negative space** — a second image formed by the unprinted space between or inside letterforms (FedEx arrow canon).
2. **Pattern-through-letterforms** — a repeating pattern passed through the letterforms while the word stays legible (IBM 8-bar canon).
3. **Continuous-line mark** — the whole mark or wordmark drawn as a single uninterrupted stroke (NASA worm canon). The strongest conceptual fit: a thread *is* a continuous line.
4. **Ligature wordmark** — two or more letters fused into a single designed glyph (The Met canon).
5. **Stroke continuation** — one stroke escapes its letterform and continues into the mark or across the word (Amazon smile canon).
6. **Counter replacement** — a letter's counter or part replaced by a pictorial element that still functions as the letter (Goodwill g canon).

**Motif rules, binding on every candidate:**

- **MR-1.** Each candidate MUST declare exactly one primary technique from the list above, by its verbatim name. Declaring a secondary technique is permitted; the primary carries the candidate's identity.
- **MR-2.** The motif MUST encode Threadline meaning — thread, line, stitch, evidence path, "follow what happened" — *structurally* (in the geometry of the letterforms or the mark), not decoratively (an ornament that could be deleted without changing the wordmark). Test: remove the motif; if what remains is a complete generic wordmark, the motif was decoration and the candidate fails (this is the AUDIT Finding E2 failure mode).
- **MR-3.** Suggested letterform attack surfaces, from the research letterform inventory of "Threadline": the **Th** pair (the classic ligature in type history), the **double-l verticals** (a natural slot for a vertical thread channel or twin parallel threads), the **i dot** (needle/knot/node — but the replacement shape must be ownable, not a generic dot), the **e/a/d counters** (thread-eye/needle-eye/node candidates), and the **descender-free lowercase run** of "threadline" (one unbroken x-height band — a single horizontal thread line can pass through the entire word at one consistent height without colliding with descenders).
- **MR-4.** Named antipatterns, all disqualifying: **gradient-dependence** (a mark whose identity disappears when the gradient is removed has no identity — RESEARCH §2b), **gimmick-dependence** (the moz://a failure mode: a letterform substitution must still read as the letters it replaces at body size, must not depend on insider syntax knowledge, and the identity must survive after the joke is explained once and forgotten — RESEARCH §1), and **container chips** (rectangular or rounded-rect background shapes behind the mark — see HC-2).
- **MR-5.** The device MUST assist reading, never fight it (catalog-level rule, RESEARCH §2). A substitution or slice that reads as a typo or punctuation noise at body size fails.

## 3. Hard constraints (every candidate, every round)

Each constraint is mechanical: checkable from the SVG source or a literal render, with its downstream requirement ID inline. A candidate violating any HC is eliminated before judging, in every round, with no exceptions.

- **HC-1 — No subtitle in the primary lockup [LOGO-03].** The primary lockup MUST contain zero subtitle/tagline glyphs. "FOLLOW WHAT HAPPENED" (or any tagline text) appears only in a separate `-subtitle` variant. Check: glyph inventory of the primary asset contains only the ten letterforms of "Threadline" plus the mark geometry.
- **HC-2 — No container chips [LOGO-02].** Zero rectangular or rounded-rectangle background container shapes behind any mark, in any variant, at any size. Marks work directly on the canvas. Check: the SVG contains no `<rect>` (or path-drawn rectangle) whose role is a background plate behind the mark. (The current `favicon.svg` rounded-square chip is the named anti-example — AUDIT GAP-10.)
- **HC-3 — No icon-beside-plain-set-type [LOGO-01].** No candidate may use an icon placed left of (or beside) plainly set type as its primary structure. Mark and type MUST be demonstrably one unit: shared geometry (a stroke, counter, or grid that both halves depend on) or tight optical spacing designed as a single drawing. Check: delete either half; if the remaining half is independently complete and generic, the candidate fails (AUDIT Finding E2 removability test).
- **HC-4 — Survives literal 16px [TOUR-02 gallery contexts].** Numeric thresholds restated verbatim from RESEARCH §2b (primary source: Primer/Octicons):
  - Stroke weight: **>= 1.5px at 16px canvas (target), >= 1.0px (absolute floor)**. No stroke in the 16px favicon render measures < 1.0px; primary strokes measure >= 1.5px.
  - Gap / counter size: **>= 1.0px at 16px canvas; >= 1.5px around modifier elements**. Every counter/gap in the 16px render measures >= 1.0px.
  - Corner detail: **1px radius at 16px** unless a larger radius is itself the identifying feature.
  - Detail floor: **<= 4 distinct strokes/elements at 16px** (derived constraint, flagged as derived in RESEARCH). Count distinct strokes/shapes in the favicon form; > 4 fails.
  - **Silhouette-first test (binary):** fill every path with one solid color, render at literal 16px; the mark MUST still be identifiable as this mark and no other. If recognition requires interior detail or color, fail.
  - **Design at 16px, never shrink:** the deliverable set MUST include a dedicated 16px-designed artifact; the favicon is not the wordmark scaled.
- **HC-5 — Survives one flat color [LOGO-04].** Every candidate ships a monochrome single-color rendition from round 1 onward, judged alongside the color version. Single-flat-color test (binary, RESEARCH §2b): replace every fill and stroke with one flat color — no opacity tiers, no gradients, no overlap-as-tone. The flattened mark MUST be identical in structure to the original and still identifiable. A mark whose distinctiveness rests on a color transition rather than geometry fails (gradient-dependence, MR-4). Dark/light flip test: the mark MUST survive on both #FFFFFF and the brand dark (#0B1020) via a single adaptive asset or an explicit pair.
- **HC-6 — Pure paths, zero `<text>` [LOGO-05, GLYPH-03].** Every candidate and final SVG contains **zero `<text>` elements** — letterforms are outlined vector paths produced via the Phase 160 glyph pipeline (fontkit text-to-outline, one `<path>` per glyph, shaped kerning). Check: `grep -c '<text' file.svg` returns 0. This is non-negotiable on every surface: GitHub serves SVGs under `default-src 'none'; style-src 'unsafe-inline'; sandbox` — external fonts never load, so live text is never the designed wordmark (AUDIT Finding E1, RESEARCH §3a).

## 4. Degrees of freedom

Per the locked v1.35 seed-drift decision: **current Geist + tokens are a seed, not a contract.** Tokens and product UI change only if the winner demands it (and `lib/threadline/operator_surface/style.ex` stays frozen in all scenarios).

- **Typeface exploration is free within OFL-safe candidates.** Geist (OFL-1.1, incumbent seed) plus the eight OFL-1.1-verified candidates from RESEARCH §5, by name:
  1. **Inter** — UI grotesque; ships an l-with-tail alternate directly useful for differentiating the double-l; safe but low distinctiveness.
  2. **Space Grotesk** — mono-flavored quirks (single-story a, kinked l); strongest "technical credibility with personality" candidate.
  3. **IBM Plex Sans** — engineered grotesque; matching Plex Mono solves the code-companion role ("Plex" is a reserved font name — renaming required for modification).
  4. **Manrope** — open counters helpful for e/a at small sizes; distinctive angle-cut t.
  5. **Sora** — flat-cut l that makes the double-l read as deliberate twin strokes.
  6. **Hanken Grotesk** — round, generous e/a/d counters that tolerate counter-replacement experiments.
  7. **Archivo** — variable width axis (the only candidate offering wordmark-width tuning); strong vertical emphasis flattering the ll pair.
  8. **JetBrains Mono** — mono companion role only, not a wordmark candidate.
- **Palette shifts are allowed.** The night-infrastructure philosophy stays (§1); specific accent hexes may move if the motif demands it. Any new brand color the winner introduces is recorded additively in tokens during Phase 162 (AUDIT §7).
- **Letterform modification is expected.** Candidates MAY redraw, fuse, slice, or extend glyphs (that is what §2 is for) — the OFL permits modification (with the Plex reserved-name caveat above), and the Phase 160 pipeline outputs editable path data.
- **Not free:** naming, tagline, the anti-trait list, the token architecture, and everything in §3.

## 5. Four archetype lanes (round-1 quota) [TOUR-01]

Round 1 presents **exactly 8 candidates** in four lanes:

| Lane | Count | Definition | Motif rule |
|---|---|---|---|
| Integrated typemark | 3 | The wordmark itself is the mark — identity lives in the letterform construction (Zig/Vite model); no separable icon | Each of the 3 carries a distinct named motif strategy (§2 technique, verbatim) applied to a named letterform hook |
| Unified mark+type lockup | 3 | A mark and the wordmark designed as one drawing — shared geometry or tight optical spacing per HC-3; mark is extractable for small slots | Each of the 3 carries a distinct named motif strategy; the shared geometry IS the motif's structural encoding |
| Monogram / mark-led | 1 | A letter-derived mark (e.g., Th monogram or T/t construction) carries the identity; wordmark accompanies but the mark leads (Elixir-drop durability model) | Carries a distinct named motif strategy; the monogram MUST pass HC-4 silhouette-first as the designated 16px survivor |
| Wordmark-only | 1 | Pure typographic identity, no mark at all — distinctiveness from letterform craft alone | Carries a distinct named motif strategy executed purely in type |

**Distinct-named-motif rule:** a motif strategy is a (technique, letterform hook) pair — e.g., "Continuous-line mark via the t-crossbar exit" or "Negative space in the e/a/d counters." All 8 candidates MUST declare 8 distinct strategies; **no two candidates share the same (technique, hook) pair**, and within any single lane no technique name repeats. With 6 techniques and 8 candidates, at most two technique names may appear twice across lanes — and only with different letterform hooks. Every candidate's declared strategy is recorded with the candidate in the Phase 161 gallery and `ROUNDS.md`.

Elimination gates for round 1 are the three FAIL rows of the audit stress matrix, restated as the HCs: renders correctly on GitHub with zero font dependency (HC-6), survives literal 16px (HC-4), survives literal one color (HC-5). The user picks the winner — never auto-selected (TOUR-03).

## 6. Out of scope / flags

- **Trademark:** trademark/legal clearance of any new mark is NOT performed in this milestone and is flagged for human review before public rollout — this is the only legal mention in this brief.
- Excluded from all rounds: motion/animation, print/CMYK/Pantone, merch, and naming/tagline alternatives (settled language, REQUIREMENTS.md Out of Scope).
- Landing page and HexDocs brand application: deferred to LANDING-01 / HEXDOCS-BRAND-01 (future milestones).
- This brief contains no SVG markup by design — it is the generation contract; implementation belongs to Phases 160–162.

---

## Audit item traceability

Every AUDIT.md section carrying a REWORK or ADD verdict, plus every GAP-nn/UP-nn item, with a disposition. Disposition is exactly one of **ROUTED** (to a named downstream v1.35 requirement) or **DESCOPED** (with a recorded reason consistent with REQUIREMENTS.md "Out of Scope" / "Future Requirements"). No row may have an empty cell.

### Section-level REWORK/ADD verdicts

| Item ID | Audit finding (one line) | Disposition | Routed to | Reason |
|---|---|---|---|---|
| AUDIT-S03 | Prior pressure-test scorecard measured intent, not survival; superseded by the adversarial 15-dimension 79/150 baseline | ROUTED | BOOK-07 | Phase 162 rerun must meet or beat 79/150 with no dimension regressing below its baseline row |
| AUDIT-S04 | Prior stress-test section was untested advice; replaced by the executed 8-surface matrix (1 PASS / 4 DEGRADED / 3 FAIL) | ROUTED | BOOK-07 | Matrix stays executable for the Phase 162 rerun; its three FAIL rows are the HC elimination gates restated in §5 (TOUR-02 contexts) |
| AUDIT-S05 | Prior risk register missed every structural defect; replaced by the severity-ordered GAP-01..12 register | ROUTED | BOOK-04 | The GAP register is the audit backlog BOOK-04 resolves or descopes item-by-item (per-item routing below) |
| AUDIT-S06 | The book had no routable upgrade backlog; UP-01..11 is new surface area to route or descope | ROUTED | BOOK-04 | Audit backlog resolution is BOOK-04's job; each UP item carries its own routing below |
| AUDIT-S08 | Every mark and lockup must be regenerated against the numeric constraints; only the asset-roster shape and misuse rules carry forward | ROUTED | TOUR-01 | Regeneration happens via the Phase 161 tournament under LOGO-01..05 (HC-1..6); roster shape lands as BOOK-01's asset family |
| AUDIT-S13 | Prior action plan recommended shipping the defects this audit demonstrates; replaced by the severity-ordered v1.35 sequence | ROUTED | BOOK-04 | The replacement priority order is the v1.35 phase sequence itself (159 → 161 → 162); BOOK-04 records each item's resolution; the do-not list carries forward into BOOK-05 |

### GAP items (audit section 5)

| Item ID | Audit finding (one line) | Disposition | Routed to | Reason |
|---|---|---|---|---|
| GAP-01 | Primary lockup is icon-left-of-text with zero shared geometry — no integrated identity exists | ROUTED | LOGO-01 | HC-3 bans the structure for every candidate; TOUR-01's lanes generate the integrated replacements |
| GAP-02 | "FOLLOW WHAT HAPPENED" subtitle baked into all three primary lockups, ~4.4px at the book's own 160px minimum | ROUTED | LOGO-03 | HC-1 bans subtitle glyphs in every candidate's primary; BOOK-02 enforces it on the final brandbook assets |
| GAP-03 | 11 of 13 SVGs depend on `<text font-family="Geist…">` that GitHub's font-less sandbox cannot satisfy | ROUTED | LOGO-05 | HC-6 requires zero `<text>` elements via the Phase 160 glyph pipeline (GLYPH-01..03 complete); BOOK-01 ships the pure-path family |
| GAP-04 | Favicon geometry (1.25px strokes, 2px dots at 16px) is below the legibility floor | ROUTED | BOOK-01 | A dedicated 16px-designed favicon cut per HC-4 thresholds joins the regenerated family; TOUR-02's literal-16px gallery context is the elimination gate |
| GAP-05 | The "monochrome" asset uses two inks plus a 45%-opacity tone — no asset survives literal one-color reproduction | ROUTED | LOGO-04 | HC-5's single-flat-color test gates every candidate from round 1; BOOK-01 ships the true one-color master |
| GAP-06 | No dark/light switching mechanism documented or committed — every single-slot surface breaks one mode | ROUTED | BOOK-03 | Brand book v2 documents the `<picture>`+prefers-color-scheme snippet and per-surface asset assignments (RESEARCH §3b); README application is optional ROLL-03 |
| GAP-07 | README/docs specimens embed the logo via external `<image href>` that GitHub's CSP blocks | ROUTED | BOOK-03 | Application examples are regenerated in Phase 162 with inlined geometry; fixing them before the new mark exists would be churn (AUDIT §9) |
| GAP-08 | Icon mark's Fog dot/ticks vanish on white and no light icon variant exists — fails Hex.pm/HexDocs light slots | ROUTED | BOOK-01 | The regenerated asset family includes a light-surface (or adaptive) icon mark; HC-5's dark/light flip test gates candidates |
| GAP-09 | Social card exists only as SVG with no committed raster export pipeline while og:image consumers require PNG | DESCOPED | SOCIAL-PNG-01 (future) | Raster export is deferred until a downstream channel requires it (REQUIREMENTS Future Requirements; committed raster exports are Out of Scope); the social-card.svg source itself regenerates under BOOK-01 |
| GAP-10 | Favicon relies on a rounded-rect container chip — the exact forbidden container pattern | ROUTED | LOGO-02 | HC-2 bans container shapes in every candidate and final asset; BOOK-05's misuse gallery documents the killed pattern |
| GAP-11 | The mark's blue→cyan meaning lives entirely in a gradient stroke — gradient-dependence as identity | ROUTED | LOGO-04 | MR-4 names gradient-dependence disqualifying; HC-5's flatten test mechanically catches it in every round |
| GAP-12 | Misuse guidance is text-only with no visual misuse gallery and no numeric small-size thresholds | ROUTED | BOOK-05 | Brand book v2's misuse gallery documents the killed antipatterns with this brief's HC-4 numbers as the thresholds |

### UP items (audit section 6)

| Item ID | Audit finding (one line) | Disposition | Routed to | Reason |
|---|---|---|---|---|
| UP-01 | Run the tournament across four archetype lanes with each candidate naming its motif strategy | ROUTED | TOUR-01 | §5 of this brief is the lane quota and distinct-named-motif rule verbatim |
| UP-02 | Ship every wordmark-bearing asset with letterforms converted to outlined vector paths | ROUTED | LOGO-05 | HC-6; the Phase 160 pipeline (GLYPH-01..03, complete) produces the outlines; BOOK-01 ships the family |
| UP-03 | Remove the subtitle from all primary lockups; tagline only in surface copy | ROUTED | LOGO-03 | HC-1 for candidates; BOOK-02 enforces the `-subtitle`-variant-only rule on final assets |
| UP-04 | Design a size-specific favicon/mark cut with >=2px effective strokes at 16px, silhouette-first, no chip | ROUTED | BOOK-01 | Dedicated 16px artifact required by HC-4's design-at-16px rule; TOUR-02's 16px context is the per-round gate |
| UP-05 | Produce a true one-color monochrome master verified by literal flatten-to-one-color test | ROUTED | BOOK-01 | LOGO-04 gates candidates from round 1; the final master lands in BOOK-01's family |
| UP-06 | Commit a ready-to-paste GitHub README `<picture>` snippet plus per-surface asset assignments | ROUTED | BOOK-03 | Brand book v2 documents the snippet and assignments; applying it to the root README is optional ROLL-03 |
| UP-07 | Add a light-surface icon mark variant (or currentColor-driven adaptive mark) for Hex.pm/HexDocs slots | ROUTED | BOOK-01 | The regenerated family covers light-surface duty; ExDoc's single-asset constraint (RESEARCH §3c) makes HC-5's flip test the gate |
| UP-08 | Commit an on-demand raster export script producing the og:image PNG deterministically | DESCOPED | SOCIAL-PNG-01 (future) | No raster consumer exists in v1.35; committed raster exports and binaries are Out of Scope — revisit when a channel requires PNG |
| UP-09 | Inline logo geometry into the example SVGs so specimens render on GitHub | ROUTED | BOOK-03 | Specimens are re-cut against the new mark in Phase 162 with inlined geometry (regenerating now would be churn per AUDIT §9) |
| UP-10 | Add a visual misuse gallery and numeric small-size thresholds to the brand book | ROUTED | BOOK-05 | Misuse gallery is BOOK-05 verbatim; thresholds are HC-4's numbers |
| UP-11 | Rebuild pressure-test.md on this audit's 15 adversarial dimensions for a comparable Phase 162 rerun | ROUTED | BOOK-07 | BOOK-07 is the meet-or-beat rerun against the 79/150 baseline, row-for-row |

### Flagged for human review

| Item ID | Audit finding (one line) | Disposition | Routed to | Reason |
|---|---|---|---|---|
| AUDIT-TM | Trademark/legal clearance of any new mark is out of audit scope and flagged for human review | DESCOPED | Human review (no v1.35 requirement) | Legal review remains outside GSD automation per REQUIREMENTS Out of Scope; carried as the single legal flag in §6 of this brief |

**Routing coverage:** 6 section verdicts + 12 GAP + 11 UP + 1 flag = 30 rows; 27 ROUTED, 3 DESCOPED; zero empty cells.

## Coherence pass

Performed over the whole brief before sign-off:

- **(a) Locked-decision consistency:** every HC matches the locked v1.35 decisions in STATE/CONTEXT — no background chips (HC-2), no subtitle in primary with a separate `-subtitle` variant (HC-1), logotype optically close to the mark / one unit (HC-3), pure paths with zero `<text>` (HC-6), seed-drift freedom for OFL typefaces and palette (§4), and the user always picks the winner (§5, TOUR-03).
- **(b) KEEP verdicts respected:** §1 carries every AUDIT KEEP/TIGHTEN keeper forward (DNA, voice, palette philosophy, tokens, blueprints, misuse do-not list, asset-roster shape); nothing in §§2–5 revises any of them.
- **(c) No hedge words:** every constraint uses MUST / MUST NOT / fails / banned phrasing with a number or a binary procedure; no "should consider," no "ideally," no "where possible."
- **(d) Read-only phase confirmed:** `git status --porcelain brandbook/` is empty and no Phase 159 commit touches `lib/` (pre-existing uncommitted `lib/` work belongs to other lanes and was not staged).

## Definition of done for round 1

Round 1 is done when Phase 161 has presented exactly 8 candidates — 3 integrated typemarks, 3 unified mark+type lockups, 1 monogram/mark-led, 1 wordmark-only — where every candidate declares a distinct named motif strategy (a verbatim §2 technique applied to a named Threadline letterform hook, no two candidates sharing a (technique, hook) pair), every candidate passes all six hard constraints mechanically (zero subtitle glyphs in the primary, zero container shapes, no icon-beside-plain-set-type, 16px survival at the §3 numeric thresholds including the silhouette-first test, a monochrome single-flat-color rendition judged alongside the color version, and zero `<text>` elements — pure paths from the Phase 160 glyph pipeline), and every candidate is shown in the six TOUR-02 gallery contexts for the user — and only the user — to advance, kill, or mutate.

---
*Phase: 159-brand-audit-and-research — Plan 03*
*Inputs: 159-AUDIT.md, 159-RESEARCH.md — Consumer: Phase 161 round 1*
