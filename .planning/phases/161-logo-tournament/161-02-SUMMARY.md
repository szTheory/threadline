---
phase: 161-logo-tournament
plan: 02
subsystem: brand
tags: [logo, tournament, checkpoint, winner, svg, geist]

# Dependency graph
requires:
  - phase: 161-logo-tournament
    provides: "plan 01: round-1 candidates, hc-gate.mjs, build-gallery.mjs, ROUNDS.md roster"
provides:
  - "Winner: C13 topstitch-geist — candidates/round-2/c13-topstitch-geist{,-mono,-favicon}.svg (graduation source for Phase 162)"
  - "ROUNDS.md complete: round-1 + round-2 verbatim verdicts, winner declaration as checkpoint evidence"
  - "Round-2 package: 6 C1/C6 mutations (19 SVGs incl. C12 dedicated light asset), gallery, gate green"
affects: [162-brand-book-v2]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Checkpoint loop ran 2 of capped 4 rounds; every verdict captured verbatim; winner = explicit user statement, never auto-selected"
    - "Round-2 judged variable: light-surface legibility — every candidate's light rendition explicitly designed (C12 ships a dedicated -light.svg)"

key-files:
  created:
    - .planning/phases/161-logo-tournament/candidates/round-2/c{9..14}-*.svg (19 files)
    - .planning/phases/161-logo-tournament/candidates/round-2/gallery.html
  modified:
    - .planning/phases/161-logo-tournament/ROUNDS.md (verdicts + Winner section)
---

# Plan 161-02 Summary — Tournament rounds + winner

**Outcome: C13 topstitch-geist is the tournament winner**, declared by explicit user statement at the round-2 checkpoint (2026-06-12): "i really like this one let's run with it it's pretty elegantly good c13-topstitch-geist".

## What happened

- **Round-1 checkpoint (TOUR-03):** user reviewed all 8 candidates in the six-context gallery. Verdicts verbatim in ROUNDS.md: C1 running-thread ADVANCE ("awesome… perhaps a little hard to read"), C6 topstitch ADVANCE ("liked… running thread more striking"), C2–C5/C7/C8 KILL. Follow-up diagnosis recorded: the light rendition was the legibility problem; dark loved; blue appealing.
- **Round 2 (TOUR-04):** 6 candidates, all mutations of the two ADVANCEd parents, each traceable to a verbatim quote (C9 gap-thread, C10 baseline-run, C11 eye-to-eye, C12 dual-surface, C13 topstitch-geist, C14 stitchline). No wildcard (none invited). hc-gate green (19 files, 0 FAIL), light renditions explicitly designed.
- **Round-2 checkpoint:** user declared C13 the winner. Tournament closed after 2 of the capped 4 rounds. Remaining candidates KILLed by the declaration.

## Winner lineage

C6 topstitch (round 1, Sora) → **C13 topstitch-geist**: the escape-arc stitch re-cut on Geist 600 — d/l ascenders cut at y=444, one connecting arc with stroke 128 (= measured Geist 600 stem width), deeper rise (319.5). Technique: Stroke continuation · hook: d/l ascender pair. The stitch is the extractable mark and the 16px favicon survivor.

## Handoff to Phase 162

Graduation source files (only these leave the phase dir, regenerated into brandbook/):
- `candidates/round-2/c13-topstitch-geist.svg` (primary)
- `candidates/round-2/c13-topstitch-geist-mono.svg` (monochrome)
- `candidates/round-2/c13-topstitch-geist-favicon.svg` (16px favicon form)

Phase 162 owes: light-surface primary, `-subtitle` variant, social card, wordmark/mark extraction, full BOOK-01 family + rebuilt index.html. Note from the tournament: C13's light rendition passed review, but Phase 162 should preserve the round-2 light-mode discipline (explicit light design, not recoloring) across the whole asset family.

## Verification

- `node tools/hc-gate.mjs candidates/round-2` → 19 files, 0 FAIL, 0 WARN (re-run at winner declaration).
- ROUNDS.md: `## Winner` section present; round-1 and round-2 feedback sections fully populated, zero placeholder slots; all quotes verbatim.
- Requirements TOUR-02/03/04 satisfied (TOUR-01 + LOGO-01..05 closed by plan 01).
- No commits touch brandbook/ or lib/; losing candidates remain archived in the phase dir.
