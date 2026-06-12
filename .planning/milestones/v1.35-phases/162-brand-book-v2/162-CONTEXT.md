# Phase 162: brand-book-v2 - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Source:** Approved milestone plan + tournament outcome (winner C13 topstitch-geist) + 159-AUDIT.md backlog + 159-DESIGN-BRIEF.md constraints

<domain>
## Phase Boundary

Graduate the tournament winner (C13 topstitch-geist) into `brandbook/` as a complete regenerated asset family, rebuild `brandbook/index.html` into a standalone professional HTML brand book, execute the audit's REWORK/ADD backlog (BOOK-04 routing from the DESIGN-BRIEF traceability table), and rerun pressure-test.md to meet-or-beat the 79/150 baseline. This phase WRITES to brandbook/ (the first phase allowed to); it still never touches lib/ or product code.

</domain>

<decisions>
## Implementation Decisions

### The winner (graduation source — do not redesign, regenerate faithfully)
- `161-logo-tournament/candidates/round-2/c13-topstitch-geist.svg` (+ `-mono`, `-favicon`): Geist 600 wordmark, d/l ascenders cut at y=444, one connecting escape-arc with stroke 128 (= measured stem width), deeper arc rise 319.5, Thread Blue #4781E6 arc. Technique: stroke continuation on the d/l ascender pair. The stitch arc + cut stems is the extractable mark and the favicon survivor.
- User's verbatim selection: "i really like this one let's run with it it's pretty elegantly good c13-topstitch-geist" — "elegantly good" is the bar for everything derived from it.
- Tournament lesson carried forward: every light-surface rendition is explicitly DESIGNED, never just recolored from dark.

### Asset family (BOOK-01, all pure-path SVGs, zero <text>, HC-1..6 still binding)
In `brandbook/` (replacing the old family): `logo-primary.svg` (dark surfaces), `logo-primary-light.svg`, `logo-mark.svg` (the extractable stitch mark), `logo-monochrome.svg` (exactly one paint value), `favicon.svg` (the C13 16px-designed cut — NO container chip, replacing the old rounded-square), `social-card.svg`, `logo-primary-subtitle.svg` (the ONLY lockup carrying "FOLLOW WHAT HAPPENED"), `logo-wordmark.svg` (the Geist-600 pure-path wordmark without the arc, if separable — it is: word with intact d/l). Old logo-*.svg files are replaced in place (same filenames where roles match) so downstream references survive.
- BOOK-02: "FOLLOW WHAT HAPPENED" greps only in the -subtitle variant and social card.
- Grep gates: `grep -rn '<text' brandbook/*.svg` empty; monochrome single paint; favicon contains no rect chip.

### index.html rebuild (BOOK-03)
- Standalone professional brand book: identity story (essence, metaphor — now genuinely embodied by the stitch), logo system (full family, clear-space rule, minimum sizes, dark/light usage incl. the GitHub `<picture>` snippet from RESEARCH §3b), MISUSE GALLERY (BOOK-05 — visual don'ts rendered inline: background chip, icon-bolted-beside-plain-text, subtitle-in-primary, gradient-dependence, stretched/recolored abuse), color system (tokens — additive change only if needed; the winner uses existing Thread Blue family, #4781E6 vs token #4F8CFF: reconcile deliberately and document the decision), typography (Geist/IBM Plex Mono, now with the pure-path wordmark story), voice/microcopy (KEEP verdict — port, don't rewrite), application examples.
- Zero external network requests opened via file:// (self-contained CSS; @font-face MAY reference ../priv/fonts relative paths only if they fail gracefully offline — prefer system-stack fallbacks; candidate/logo renders are inlined pure paths and never depend on fonts).
- The misuse gallery and the brand book overall must look "very professional, stands on its own" (user requirement).

### Audit backlog (BOOK-04) + pressure-test rerun (BOOK-07)
- Resolve every ROUTED item from the DESIGN-BRIEF traceability table targeting BOOK-01/02/03/05/07: GAP-04 (16px favicon), GAP-05 (true one-color master), GAP-06 (<picture> dark/light documentation), GAP-07/UP-09 (examples regenerated with inlined geometry), GAP-08/UP-07 (light icon mark), GAP-10 (chipless favicon), GAP-12/UP-10 (misuse gallery + numeric thresholds), UP-04, UP-05, UP-06, UP-11. DESCOPED items (GAP-09/UP-08 raster pipeline) stay descoped.
- Rebuild `pressure-test.md` on the audit's 15 adversarial dimensions and rerun: scorecard must meet or beat 79/150 with no dimension below its baseline row.
- `brand-book.md` updated to describe the new logo system as settled brand truth (v1.33 lesson: no process-history framing in brandbook/).
- `examples/*.svg` refreshed (readme-header, social, docs-page minimum) with inlined pure-path geometry.

### Budget & hygiene (BOOK-06)
- brandbook/ stays text/SVG/HTML/CSS/JSON only, ≤ ~300KB total, no binaries, no font duplication.
- tokens.json/tokens.css: additive changes only if the winner demands (likely only documenting the arc blue if it stays #4781E6).
- Screenshots (desktop/mobile direct-open evidence, favicon at literal 16/32px) live in the PHASE dir, never brandbook/.

### Claude's Discretion
- index.html visual design (calm, dark-first, professional; it represents the brand it documents).
- Whether old example SVGs are regenerated or pruned (all killer no filler — prune what no surface needs, document removals).
- Exact clear-space/minimum-size numbers (derive from HC-4 thresholds + C13 geometry).
- #4781E6 vs #4F8CFF reconciliation (pick one story, document it, keep operator-surface tokens untouched).

</decisions>

<specifics>
## Specific Ideas

- The brand metaphor finally closes: "a line that connects discrete points into an intelligible path" — the stitch arc literally rises out of the word's fabric and dives back in. The identity story section should tell this without overclaiming.
- README `<picture>`/dark-light snippet is DOCUMENTED here (BOOK-03); actually applying it to README is optional Phase 163 (ROLL-03).
- gsd-verify-work UAT with the user closes this phase (second hard human gate): user opens index.html and approves.

</specifics>

<deferred>
## Deferred Ideas

- Product rollout (logo.ex, example-app favicon, README header) — optional Phase 163, user decides with the finished brand book in hand.
- Raster/og:image export pipeline — SOCIAL-PNG-01 (future).

</deferred>

---

*Phase: 162-brand-book-v2*
*Context gathered: 2026-06-12*
