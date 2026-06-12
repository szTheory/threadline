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
