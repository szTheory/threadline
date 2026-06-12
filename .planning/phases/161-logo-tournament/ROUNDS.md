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
*Phase: 161-logo-tournament · Round 1 prepared by plan 161-01; checkpoint runs in plan 161-02.*
