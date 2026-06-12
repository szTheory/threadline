# Threadline Logo Tournament — Rounds Log

**Protocol** (per `161-CONTEXT.md` and `159-DESIGN-BRIEF.md` §5): the tournament runs
user-judged elimination rounds. Per round, per candidate, the user gives a verdict —
**ADVANCE/KILL/MUTATE** — with reasons, recorded verbatim here. Rounds after 1 contain
4–6 candidates, all mutations traceable to recorded feedback (max one invited wildcard
per round). Round cap is 4: hitting it triggers an explicit user decision (extend or
pick best available), never silent continuation. The winner is an explicit user
statement recorded as checkpoint evidence — the user picks, always; nothing is
auto-selected. Every candidate in every round must pass the mechanical HC-1..6 gate
(`tools/hc-gate.mjs`) before the user sees it.

---

## Round 1

**Date:** 2026-06-12 · **Gallery:** `candidates/round-1/gallery.html` (open over `file://`)
· **Gate:** `node tools/hc-gate.mjs candidates/round-1` → 24 files, 0 FAIL, 0 WARN
(quota 3/3/1/1, 8 distinct pairs, technique-spread and double-hook rules all PASS).

### Roster

| ID | Slug | Lane | Strategy (technique · hook, verbatim BRIEF §2/MR-3) | Typeface | HC gate |
|----|------|------|------------------------------------------------------|----------|---------|
| C1 | `c1-running-thread` | Integrated typemark | Stroke continuation · descender-free lowercase run | Geist 500 (Phase 160 kit) | PASS · favicon strokes 1.70px @16, 2 elements, silhouette PASS |
| C2 | `c2-strung-crossbar` | Integrated typemark | Ligature wordmark · Th pair | Geist 600 (Phase 160 kit) | PASS · favicon stroke 1.80px @16, 1 element, silhouette PASS |
| C3 | `c3-pinned-eye` | Integrated typemark | Counter replacement · e/a/d counters | Geist 500 (Phase 160 kit) | PASS · favicon strokes 1.70/1.50px @16, 3 elements, silhouette PASS |
| C4 | `c4-knotline` | Unified mark+type lockup | Continuous-line mark · T crossbar | Geist 500 (Phase 160 kit) | PASS · favicon stroke 1.70px @16, 1 element, silhouette PASS |
| C5 | `c5-needle-eye` | Unified mark+type lockup | Negative space · i dot | Geist 500 (Phase 160 kit) | PASS · filled favicon ink-scan: min ink 2.00px, min gap 1.75px @16, 1 element, silhouette PASS |
| C6 | `c6-topstitch` | Unified mark+type lockup | Stroke continuation · double-l verticals | Sora SemiBold v2.000 (OFL) | PASS · favicon strokes 1.70px @16, 2 elements, silhouette PASS |
| C7 | `c7-th-monoline` | Monogram / mark-led | Continuous-line mark · Th pair | custom monoline + Geist 600 wordmark | PASS · favicon strokes 1.70px @16, 2 elements, min gap 1.00px, silhouette PASS |
| C8 | `c8-needle-run` | Wordmark-only | Pattern-through-letterforms · descender-free lowercase run | Space Grotesk Medium v2.0.0 (OFL) | PASS · filled favicon ink-scan: min ink 1.00px, min gap 1.00px @16, 1 element, silhouette PASS |

**OFL alternate sources** (fonts downloaded to a temp dir at generation time, never committed;
letterforms regenerated via `brandbook/tools/text-to-paths.mjs --font` with ephemeral
`fontkit@2.0.4`):

- **Sora SemiBold** — Version 2.000 · official upstream `https://github.com/sora-xor/sora-font`,
  `fonts/ttf/Sora-SemiBold.ttf` (master). Kit text "Threadline"; measured d/l ascender stem
  width 139/1000 upm.
- **Space Grotesk Medium** — v2.0.0 release zip · official upstream
  `https://github.com/floriankarsten/space-grotesk/releases/tag/2.0.0`,
  `ttf/static/SpaceGrotesk-Medium.ttf`. Kit text "threadline" (lowercase); measured stems
  l=103, T(t)=108/1000 upm.

**Note on the "double-l verticals" hook:** "Threadline" has no literal double-l; the brief's
named hook maps to the word's twin adjacent ascender verticals — the **d/l pair** — which is
where C6 applies it.

**Ink-floor scan note (HC-4):** the /tmp pixel scan (16px render, 4× sampling) reports a few
sub-1px *interior* runs for C1/C2/C3/C4/C6. All were inspected in the silhouette renders and
are acute-junction wedges (e.g. the wedge where an h shoulder springs from its stem, or where
a thread crosses a ring) — inherent to any letterform junction, not designed features. Every
*designed* stroke, counter, and gap measures ≥ 1.0px at 16px; C5/C7/C8 scan fully clean.

### Design rationale

- **C1 — running-thread.** The crossbars of both e's escape their letterforms and run as one
  thread through the entire word at e-bar height, surfacing as stitch dashes in every gap and
  counter and diving behind every stem. The e's are structurally pinned to it — their bars ARE
  the thread, so the motif cannot be deleted without breaking both e's (MR-2). It is the
  brief's own strongest letterform fact made literal: the descender-free run lets one line
  pass through the whole of "Threadline", which is the product promise — one line through
  everything that happened.
- **C2 — strung-crossbar.** T and h fuse into a single ligature under one shared crossbar:
  taut where it rides the two posts, with the slack bellying gently beneath the bridge — a
  line strung between two fixed points, drawn with the physics of a real thread. The h's
  ascender terminates at the crossbar's underside; cut the line and the h is decapitated.
  Quietest candidate of the eight: at body size it is simply a confident wordmark, at display
  size the engineering shows.
- **C3 — pinned-eye.** The first e's counter is re-cut as a perfect circular eye holding a
  concentric gold node — a record pinned in the eye of the needle. Against Geist's organic
  bowls the geometric counter reads as deliberate instrumentation, making the first e the
  focal event of the word: an audit is exactly this, a point held where you can always find
  it. The pin is the only color in the mark.
- **C4 — knotline.** A single uninterrupted thread enters from the left, rises through one
  geometric loop, and becomes the T's crossbar — mark and wordmark are literally the same
  stroke (stroke width 99 = the crossbar thickness). The T's left arm was removed from the
  glyph: the thread's arrival completes the letter, so neither half survives alone (HC-3 by
  construction). The loop is the grabbable handle on history — calm, circular, technical, and
  it breaks above the cap line without any container.
- **C5 — needle-eye.** The i's dot becomes the needle's eye: an enlarged node whose thread is
  drawn entirely in negative space — an unprinted channel enters from the left and terminates
  in the eye. You read the line in the absence of ink, which is the auditor's posture: the
  evidence is in what the record shows AND what it doesn't. The node is the extractable mark
  and the designed 16px survivor; the wordmark stays full-strength Geist.
- **C6 — topstitch.** The word's twin ascender verticals — the adjacent d/l pair — are cut
  just above x-height and their strokes escape upward into one connecting arc: a single
  stitch rising out of the fabric of the word and diving back in, with the surfaced portion
  in accent blue above the cut line. Arc stroke width equals the measured Sora stem width
  (139), so the legs land flush on the cut stems: motif and letterform are one material.
  Sora's flat-cut terminals make the twin posts read as deliberate strands.
- **C7 — th-monoline.** One monoline thread writes "th": stem, baseline turn, rise, shoulder,
  post — a single unbroken stroke with two loose ends, with the t's crossbar as the thread's
  other end passing behind the stem (the same over/under weave vocabulary as C1 and C4). The
  monogram leads and is itself the favicon; the Geist 600 wordmark accompanies on a shared
  baseline at 0.535 scale, the mark-to-wordmark gap set equal to the monogram's arch counter.
- **C8 — needle-run.** Pure type: lowercase "threadline" in Space Grotesk, where a needle has
  passed through every vertical stem at one consistent height, leaving a row of nine punch
  holes — a repeating pattern through the letterforms. The thread itself is never shown; you
  see the evidence of its path and follow it, which is the product in one sentence. The gold
  i dot marks where the needle rests.

### Optical kerning notes

Per the locked decision, every candidate was overlaid against its unmodified kit baseline
(candidate cyan 55% over kit magenta 55%, 2× screenshots, /tmp only — not committed).
Untouched glyphs blend to a uniform tone in all eight overlays: **no per-glyph translate
offsets were changed anywhere in round 1** — all surgeries are glyph-internal (counters,
cuts, bar removals, punches) or additive marks, so the kits' shaped GPOS kerning is
preserved exactly. Specific clearances verified:

- **C1:** thread under-pass gaps are ink ± 34 units at every stem (12 was tried first and
  read as a strikethrough; 34 makes the weave legible). The bar attaches flush to each e's
  inner left wall (no gap — it is the e's bar).
- **C2:** the ligature bridges the kit's native 275-unit Th stem gap; no tightening needed —
  the shared bar closes the pair optically. The slack belly bottoms at 46 units below the
  crossbar's underside.
- **C4:** loop tangent sits 460 units left of the T stem; loose end 430 units. The stroke
  terminates 40 units inside the T stem so the round cap is buried in letter ink.
- **C5:** the node overhangs the kit's square i dot by ~40 units per side; clearance to the
  l tail is 47 units (at different heights — verified non-colliding in overlay) and 114 units
  to the n stem.
- **C6:** d and l cut at y=400 (just above Sora's x-height top at 427); arc legs are
  coordinate-flush with the stems (same 139-unit width, same edges). The l's top-left flag
  (y 240–344) is removed by the cut; recorded as an intentional sidebearing change that does
  not alter the glyph's advance.
- **C7:** wordmark glyphs untouched at 0.535 scale; monogram-to-wordmark gap 290 units
  (= the monogram's arch counter width) on the shared y=985 baseline.

### Feedback — Round 1

*Collected at the round-1 checkpoint, 2026-06-12. User quotes verbatim.*

- **C1:** ADVANCE · reasons (verbatim): "c1-running-thread <--- this one is awesome it's just perhaps a little hard to read? i do like it a lot though explore variations that would be best of all worlds." Follow-up legibility diagnosis (verbatim): "somewhat the strikethrough effect, more on the dark version (which looks great visually though). , actually NO the dark version reads decently it's the light one that is harder to read. the monocrhome isn't a problem to read. i do find that blue very appealing especially on the dark BG. looks okay on the light to"
- **C2:** KILL · reasons — not advanced; user directed round 2 exclusively at the C1 and C6 concepts ("explore both of those concepts and we'll tournament them")
- **C3:** KILL · reasons — not advanced (same direction as C2)
- **C4:** KILL · reasons — not advanced (same direction as C2)
- **C5:** KILL · reasons — not advanced (same direction as C2)
- **C6:** ADVANCE · reasons (verbatim): "i also did like this one c6-topstitch that one too. i just felt that the running thread concept was more striking ... so yeah think deeply on this do another round here explore both of those concepts and we'll tournament them"
- **C7:** KILL · reasons — not advanced (same direction as C2)
- **C8:** KILL · reasons — not advanced (same direction as C2)

**Round-2 direction (user, verbatim):** "so yeah think deeply on this do another round here explore both of those concepts and we'll tournament them" — round 2 contains only C1/C6 mutations (TOUR-04); no wildcard invited.
**Key design lesson for round 2:** C1's dark rendition is loved and reads decently; the LIGHT rendition is the legibility problem (thread/letter value collision reads as strikethrough on white); monochrome reads fine; the blue is appealing, especially on dark. Every round-2 candidate's light rendition must be explicitly designed, not recolored from dark.

---

## Round 2

**Date:** 2026-06-12 · **Gallery:** `candidates/round-2/gallery.html` (open over `file://`)
· **Gate:** `node tools/hc-gate.mjs candidates/round-2` → 19 files, 0 FAIL, 0 WARN
(6 candidates × 3 forms + C12's dedicated light rendition). Gallery network audit:
0 external requests (Playwright).

**Composition (TOUR-04):** all six candidates are mutations of the two round-1 ADVANCEs —
C1 (`c1-running-thread`) and C6 (`c6-topstitch`) — per the user's direction, verbatim:
"so yeah think deeply on this do another round here explore both of those concepts and
we'll tournament them". No wildcard was invited; none is included. IDs continue the global
sequence: C9–C14.

**The judged variable this round:** light-mode thread/letter value separation on white.
Round-1 lesson, from the verbatim C1 feedback: "NO the dark version reads decently it's
the light one that is harder to read" — every round-2 candidate's light rendition is
explicitly designed, not recolored from dark, and the light panels were inspected in
rendered form before shipping.

### Roster

| ID | Slug | Parent | Feedback line addressed (verbatim) | Strategy (technique · hook) | Typeface | HC gate |
|----|------|--------|-------------------------------------|------------------------------|----------|---------|
| C9 | `c9-gap-thread` | C1 | "somewhat the strikethrough effect … it's the light one that is harder to read" | Stroke continuation · descender-free lowercase run | Geist 500 (Phase 160 kit) | PASS · favicon strokes 1.70px @16, 2 elements, designed gaps 1.25px, silhouette PASS |
| C10 | `c10-baseline-run` | C1 | "perhaps a little hard to read? … explore variations that would be best of all worlds" | Pattern-through-letterforms · descender-free lowercase run | Geist 500 (Phase 160 kit) | PASS · favicon strokes 1.70px @16, 2 elements, designed gaps 1.25px, silhouette PASS |
| C11 | `c11-eye-to-eye` | C1 | "perhaps a little hard to read? i do like it a lot though" | Counter replacement · e/a/d counters | Geist 500 (Phase 160 kit) | PASS · favicon strokes 1.70px @16, 2 elements, designed gaps 1.00px (floor), silhouette PASS |
| C12 | `c12-dual-surface` | C1 | "NO the dark version reads decently it's the light one that is harder to read" | Stroke continuation · descender-free lowercase run | Geist 500 (Phase 160 kit) | PASS · favicon strokes 1.70px @16, 2 elements, silhouette PASS (arc–bar wedge = round-1 adjudication) |
| C13 | `c13-topstitch-geist` | C6 | "i also did like this one c6-topstitch that one too" | Stroke continuation · double-l verticals (d/l pair) | Geist 600 (Phase 160 kit) | PASS · favicon strokes 1.70px @16, 2 elements, silhouette PASS (line/leg AA corner wedges adjudicated) |
| C14 | `c14-stitchline` | C1 × C6 | "i just felt that the running thread concept was more striking … explore both of those concepts" | Stroke continuation · descender-free lowercase run + double-l verticals | Geist 500 (Phase 160 kit) | PASS · favicon strokes 1.70px @16, 2 elements, designed gaps 1.25px, silhouette PASS |

**Ink-floor scan (HC-4, /tmp 16px render, 4× sampling):** all designed strokes and gaps
≥ 1.0px (C9/C10/C14 gaps 1.25px; C11 1.00px at the floor). Two sub-1px readings
adjudicated via silhouette renders as junction artifacts, not designed features: C12's
0.25px run is the acute wedge where the e-arc terminus meets the bar (carried unchanged
from round-1 C1, where it was adjudicated the same way); C13's 0.50px reading is
anti-aliasing at the right-angle line/leg crossings of the stitch arch.

### Design rationale

- **C9 — gap-thread.** Answers the strikethrough diagnosis head-on: the thread keeps C1's
  channel, weight, and blue, but surfaces only between letters — never inside a counter or
  aperture — so no foreign line ever crosses a letterform. Both e crossbars are restored to
  exact kit geometry and carried on the thread layer: the bars sit precisely where the eye
  expects an e's bar, yet they ARE the thread (remove it and both e's break — MR-2 holds).
  The weave stays continuous; the collisions are gone.
- **C10 — baseline-run.** Relocates the thread to the one channel where value collision is
  impossible: the baseline, which "threadline" leaves descender-free. The thread runs
  through the word's feet in strict textile alternation — over T, under h's first leg, over
  its second, under r, and so on through all thirteen baseline obstacles — and every
  over-crossed stem is cut and completed by the thread itself, so the word literally stands
  stitched to its own line. The most literal reading of the name: thread + line.
- **C11 — eye-to-eye.** Keeps what the user called striking and cuts the noise: fourteen
  surfacings become five. The thread enters the word through the first e's counter and
  leaves through the last e's — the two eyes the word already owns — passing behind
  everything between except one surfacing in the d–l gap. Both e bars stay intact; the
  thread is topologically captive through the needle eyes rather than welded to the bars.
- **C12 — dual-surface.** The conservative mutation: the dark rendition is byte-faithful to
  round-1 C1, because it is loved and reads decently. Only the light surface is
  re-engineered, in a dedicated light asset: thread tint lifted to #8FB3F0 so it sits a
  value-layer behind the dark word, under-pass halos widened from 34 to 70 units, and the
  five dashes that collapse at the wider halo dropped. Same identity, two correctly tuned
  surfaces.
- **C13 — topstitch-geist.** C6's stitch was liked but cut on Sora; this re-cuts it on the
  incumbent Geist voice. The adjacent d/l ascenders are cut at y=444 — just above Geist's
  x-height — and escape into one connecting arc whose stroke width equals the measured
  Geist 600 stem (128), landing flush on the cut stems; the arc rises deeper than C6's
  (319.5 vs 257 units above the cut). One stitch surfacing from the fabric of the word,
  now in the family typeface.
- **C14 — stitchline.** The hybrid the direction asked for: one continuous thread does both
  concepts' jobs. It surfaces six times — lead-in, the first e's bar, the a–d gap, once
  ABOVE the x-height as the d/l stitch arc (stroke 106 = the Geist 500 stem, ascenders cut
  at y=430), the i–n gap, and the last e's bar running out. C1's woven horizontality and
  C6's vertical escape, one line, no clutter. Restraint is the craft test.

### Light-mode treatment notes (the judged variable)

- **C9:** no foreign line crosses any letter; the only in-letter blue is the two e bars, at
  the exact anatomical bar position. Light verified clean in the rendered gallery panel.
- **C10:** thread sits entirely at the baseline, below the reading band; counters and
  x-height untouched. Light is collision-free by construction.
- **C11:** five surfacings; in-letter blue only inside the two e counters. Calm on white.
- **C12:** the only candidate with a DIFFERENT light asset (`c12-dual-surface-light.svg`):
  tint #8FB3F0 + 70-unit halos + 5 dashes dropped. The gallery's light panel and light
  README strip render the light asset (panel captioned "dedicated light rendition").
- **C13:** the stitch lives above the x-height; nothing crosses the reading band. Light
  inherently clean.
- **C14:** six surfacings, all in gaps / e bars / above the word; verified clean on white.

### Optical kerning notes

No per-glyph translate offsets were changed anywhere in round 2 — all letterforms reuse the
kits' shaped kerning exactly; all surgeries are glyph-internal cuts or additive marks:

- **C9:** e bar pieces are the kit bar geometry re-expressed on the mark layer (union with
  the cut ring = the intact kit e to within path rounding); gap dashes reuse C1's measured
  ±34-unit stem clearances.
- **C10:** feet cut horizontally at y=965 on T / h-right / l / n-left; the l foot's curve
  was split at its y=965 crossing (cut point x≈95 glyph-local). Thread band y 965–1045,
  80 units thick (C1's weight), ±34 clearances at under-passed stems.
- **C11:** thread thinned to 64 units (y 598–662) to ride the eye channel with clearance
  (47 top / 28 bottom inside the counters); eye dashes extend under the bowl walls and the
  letters print over them, so the thread tucks flush behind the ink.
- **C12:** dark file geometry identical to C1 (diffable); light file changes the mark layer
  only.
- **C13:** d/l cut at y=444; arc legs coordinate-flush with the Geist 600 stems
  (3100–3228 / 3361–3489); no sidebearing change (Geist's l has no flag, unlike Sora's).
- **C14:** d/l cut at y=430; arc legs flush with the Geist 500 stems (3031–3137 /
  3279–3385); e treatment identical to C1.

### Feedback — Round 2

*To be filled VERBATIM at the round-2 checkpoint (plan 161-02). Claude does not pre-fill
verdicts. Per candidate: ADVANCE / KILL / MUTATE + reasons in the user's own words. A winner
declaration ("CN is the winner") may happen here and ends the tournament.*

- **C9:** verdict —, reasons —
- **C10:** verdict —, reasons —
- **C11:** verdict —, reasons —
- **C12:** verdict —, reasons —
- **C13:** verdict —, reasons —
- **C14:** verdict —, reasons —

---
*Phase: 161-logo-tournament · Round 1 prepared by plan 161-01; rounds 2+ and all checkpoints run in plan 161-02.*
