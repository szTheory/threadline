# Phase 161: logo-tournament - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Source:** Approved milestone plan + `159-DESIGN-BRIEF.md` (the binding round-1 generation contract) + user decisions locked at plan approval

<domain>
## Phase Boundary

Generate 8 diverse logo candidates per the DESIGN-BRIEF and run user-judged elimination rounds until the user declares a winner. The USER picks — always; no auto-selection, no "recommended" styling in the gallery. Deliverables: per-round candidate SVGs + self-contained gallery.html in the phase dir, ROUNDS.md feedback log, and a recorded winner declaration. Only the winner graduates to brandbook/ — in Phase 162, not here. This phase writes nothing under brandbook/ or lib/.

</domain>

<decisions>
## Implementation Decisions

### Binding contract
- `159-DESIGN-BRIEF.md` is the generation contract: MR-1..5 motif rules, HC-1..6 hard constraints (all mechanical), §4 degrees of freedom, §5 archetype lanes, and the "Definition of done for round 1". The plan must not restate-and-drift; cite the brief.
- Round 1: exactly 8 candidates — 3 integrated typemarks, 3 unified mark+type lockups, 1 monogram/mark-led, 1 wordmark-only. Each declares a distinct (technique, letterform-hook) pair per the brief's distinct-named-motif rule.
- Letterforms come from the Phase 160 glyph kits (`.planning/phases/160-glyph-outline-pipeline/glyph-kit-geist-{500,600}.{svg,json}`), or for non-Geist explorations from the same pipeline run against an OFL candidate font (`brandbook/tools/text-to-paths.mjs` + `--font`). Zero `<text>` anywhere (HC-6). Kit JSONs expose kerned offsets + stem widths (Geist 500: l=106/T=108; 600: l=128/T=130 font units) for motif stroke matching.
- Display-size optical kerning pass is owned here (after motif surgery, adjust per-glyph translate offsets; overlay against the kit baseline for evidence).

### Tournament structure (one phase, internal checkpoint loop)
- Tasks model: round-N-generate → round-N HUMAN CHECKPOINT → either round-N+1-generate (mutations from feedback) or finalize-winner. Round cap 4: hitting it triggers an explicit user decision (extend / pick best available), never silent continuation.
- Rounds after 1: 4–6 candidates, ALL mutations of user-ADVANCEd candidates traceable to recorded feedback; max one user-invited wildcard per round.
- ROUNDS.md: per round, per candidate — verbatim user feedback, verdict tag (ADVANCE/KILL/MUTATE), and reasons. Winner = explicit user statement recorded as checkpoint evidence.
- Checkpoint mechanics: orchestrator (main session) prompts the user to open the gallery file, then collects per-candidate verdicts via AskUserQuestion/conversation. "All fine" is not a verdict — follow up. The executor prepares everything up to the checkpoint and stops; the orchestrator runs the human gate and dispatches the next round.

### Gallery (TOUR-02)
- Per round: `candidates/round-N/gallery.html`, self-contained, opens via file:// with zero network requests. Gallery chrome MAY use system fonts/inline CSS; candidate renders are inlined pure-path SVG only.
- Six contexts per candidate: (1) dark #0B1020, (2) light #FFFFFF/Paper, (3) monochrome single-flat-color, (4) literal 16px favicon render + 4× magnified copy side by side, (5) 32px render, (6) simulated GitHub README header strip (light + dark sub-variants acceptable as one strip).
- Candidates labeled C1..C8 with archetype lane + declared (technique, hook) strategy. Neutral presentation order; NO recommendation styling, no pre-ranking.
- Candidate SVG sources committed beside the gallery as `cN-<slug>.svg` (+ `cN-<slug>-mono.svg` if the mono is a separate file).

### Per-candidate deliverables (every round)
- Primary lockup SVG (pure paths, no subtitle, no chip), monochrome rendition, and a 16px-designed favicon form (the silhouette-first survivor — may be the mark/monogram element).
- HC-1..6 checked mechanically before the gallery ships: xmllint, grep '<text' = 0, no background rect/plate, glyph inventory = "Threadline" only, stroke/gap measurements at 16px, flatten test. A candidate failing any HC is fixed or replaced before user review.

### Claude's Discretion
- Palette/typeface choices per candidate within §4 degrees of freedom (mix of Geist-based and 1–3 OFL-alternative-based candidates is healthy diversity; don't make all 8 non-Geist).
- Exact gallery layout/styling (keep it calm, dark-first, professional — it is itself a brand artifact the user experiences).
- Which (technique, hook) pairs to assign to which lanes, subject to the brief's distinctness rules.
- Whether to pre-generate small PNG raster checks for self-verification (NOT committed; SVG-only in git).

</decisions>

<specifics>
## Specific Ideas

- User's strongest stated wants: fully integrated custom type treatment ("motif worked in, not icon left of text"), marks that "break the boundaries" (no containment), logotype optically close to the mark, no subtitle in primary.
- Brief's named letterform hooks: Th ligature pair, double-l verticals, i dot, e/a/d counters, the descender-free lowercase run (a horizontal thread can pass through the whole word "threadline" at one consistent height).
- Anti-trait list is a judging criterion: not flashy, not cute, not cyberpunk, not militarized, not compliance-bureaucratic, not generic SaaS.
- Elimination gates = the audit's three FAIL rows restated: GitHub font-less render (HC-6), literal 16px (HC-4), literal one color (HC-5).

</specifics>

<deferred>
## Deferred Ideas

- Graduating the winner into brandbook/ + full asset family + -subtitle variant — Phase 162.
- README/<picture> application — BOOK-03 docs in 162; actual README change optional ROLL-03.

</deferred>

---

*Phase: 161-logo-tournament*
*Context gathered: 2026-06-12*
