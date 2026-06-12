---
phase: 159-brand-audit-and-research
plan: 03
subsystem: brand
tags: [design-brief, branding, logo, typemark, tournament-contract, traceability]

# Dependency graph
requires:
  - 159-AUDIT.md (14 verdicts, 79/150 scorecard baseline, stress matrix, GAP-01..12, UP-01..11)
  - 159-RESEARCH.md (11 case studies, 6-technique motif catalog, numeric 16px/monochrome thresholds, OFL typefaces)
provides:
  - 159-DESIGN-BRIEF.md — the round-1 generation contract Phase 161 candidates are generated against
  - Hard constraints HC-1..6 stated numerically with downstream requirement IDs (LOGO-01..05, TOUR-02, GLYPH-03)
  - Motif rules MR-1..5 using the six verbatim RESEARCH technique names with Threadline letterform hooks
  - Four archetype lane table (3+3+1+1=8) with the distinct-named-motif (technique, hook) rule
  - 30-row audit-item traceability table: 27 ROUTED, 3 DESCOPED, zero empty cells
affects: [phase-161 tournament, phase-162 brand book v2, BOOK-04, BOOK-05, BOOK-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Motif strategy defined as a (technique, letterform hook) pair to make 8 distinct strategies arithmetically honest against a 6-technique catalog"
    - "Every hard constraint phrased as MUST/MUST NOT with a number or binary procedure plus an inline downstream requirement ID"

key-files:
  created:
    - .planning/phases/159-brand-audit-and-research/159-DESIGN-BRIEF.md
  modified: []

key-decisions:
  - "Motif distinctness defined at the (technique, letterform hook) pair level: 8 candidates need 8 distinct pairs; within a lane no technique repeats; at most two technique names may appear twice across lanes (6 techniques vs 8 candidates)"
  - "GAP-09 and UP-08 (social-card raster pipeline) DESCOPED to SOCIAL-PNG-01 (future) per REQUIREMENTS Out of Scope; the social-card.svg source itself regenerates under BOOK-01"
  - "GAP-06/GAP-07/UP-06/UP-09 (switching snippet, specimen fixes) routed to BOOK-03 rather than fixed now — re-cutting specimens before the new mark exists would be churn (AUDIT section 9)"
  - "Trademark carried as exactly one DESCOPED row (Human review) and one line in brief section 6 — the only legal mentions"

patterns-established:
  - "Round-1 elimination gates are the audit stress matrix's three FAIL rows restated as HC-4/HC-5/HC-6"
  - "Definition of done for round 1 is a single quotable paragraph Phase 161 can lift verbatim"

requirements-completed: [RES-04]

# Metrics
duration: 9min
completed: 2026-06-12
---

# Phase 159 Plan 03: Design Brief Convergence Summary

**177-line round-1 generation contract synthesizing audit + research: 6 verbatim motif techniques with Threadline letterform hooks, 6 numeric hard constraints carrying LOGO-01..05/TOUR-02/GLYPH-03 IDs, 9 named OFL typeface degrees of freedom, the 3+3+1+1 archetype lane table, and a 30-row traceability table routing every REWORK/ADD item (27 ROUTED, 3 DESCOPED)**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-06-12T01:07:33Z
- **Completed:** 2026-06-12T01:16:30Z
- **Tasks:** 2
- **Files modified:** 1 (created)

## Accomplishments

- **RES-04 (contract):** `159-DESIGN-BRIEF.md` states the full round-1 contract — "What we keep" confirmed against the actual AUDIT KEEP verdicts (DNA, voice, palette philosophy, tokens, blueprints; naming/tagline settled); motif rules MR-1..5 naming the six RESEARCH techniques verbatim (Negative space, Pattern-through-letterforms, Continuous-line mark, Ligature wordmark, Stroke continuation, Counter replacement) with the Th/double-l/i-dot/e-a-d-counter/descender-free letterform hooks; gradient-dependence, gimmick-dependence (moz://a), and container chips as named disqualifying antipatterns.
- **Hard constraints HC-1..6, numeric/mechanical:** no subtitle glyphs in primary [LOGO-03]; zero container shapes [LOGO-02]; no icon-beside-plain-set-type with the removability test [LOGO-01]; literal-16px survival restating RESEARCH thresholds verbatim (stroke >=1.5px target / >=1.0px floor, gaps/counters >=1.0px, 1.5px around modifiers, 1px corner radius, <=4 element detail floor, silhouette-first binary test, design-at-16px rule) [TOUR-02 contexts]; single-flat-color survival with monochrome rendition from round 1 [LOGO-04]; zero `<text>` elements via the Phase 160 glyph pipeline [LOGO-05, GLYPH-03].
- **Degrees of freedom:** Geist named as OFL-1.1 incumbent seed plus the eight RESEARCH candidates by name (Inter, Space Grotesk, IBM Plex Sans, Manrope, Sora, Hanken Grotesk, Archivo, JetBrains Mono as mono-companion only); palette shifts allowed; tokens/product UI change only if the winner demands it.
- **Archetype lanes [TOUR-01]:** table of exactly 8 round-1 candidates (3 integrated typemarks, 3 unified lockups, 1 monogram/mark-led, 1 wordmark-only) with the distinct-named-motif rule defined at the (technique, hook) pair level.
- **Traceability (ROADMAP criterion 5):** 30 rows — 6 section-level REWORK/ADD verdicts, GAP-01..12, UP-01..11, plus the trademark flag — each ROUTED to a named v1.35 requirement (LOGO-*, TOUR-*, BOOK-*) or DESCOPED with a recorded reason; zero empty cells; coherence pass (a)–(d) performed; quotable "Definition of done for round 1" closes the document.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the round-1 generation contract** - `ea15d00` (docs)
2. **Task 2: Route every REWORK/ADD audit item — traceability table and coherence check** - `3a130b8` (docs)

## Files Created/Modified

- `.planning/phases/159-brand-audit-and-research/159-DESIGN-BRIEF.md` - 177-line round-1 generation contract plus 30-row audit-item traceability table

## Decisions Made

- Defined "distinct named motif strategy" as a (technique, letterform hook) pair so the 8-candidate / 6-technique arithmetic is honest: no two candidates share a pair, no technique repeats within a lane, at most two technique names may appear twice across lanes.
- DESCOPED exactly three items: GAP-09 and UP-08 (raster export pipeline → SOCIAL-PNG-01 future requirement, consistent with the committed-raster Out of Scope rule) and the trademark flag (→ human review). Everything else ROUTED to LOGO-01..05, TOUR-01/TOUR-02, BOOK-01/BOOK-03/BOOK-04/BOOK-05/BOOK-07.
- Routed specimen/switching fixes (GAP-06, GAP-07, UP-06, UP-09) to BOOK-03 rather than fixing now, following the audit's own churn warning (specimens must be re-cut against the new mark anyway).

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- Task 1 automated verify: PASS (file exists; 16px, subtitle, container/chip, OFL, LOGO-0, monogram, wordmark-only, trademark all present).
- Task 2 automated verify: PASS (traceability heading present; 30 disposition rows; 0 empty-cell rows; `git status --porcelain brandbook/` empty; no `lib/` file in any phase-159 commit).
- Artifact is 177 lines (min_lines 150 satisfied); key-link patterns `GAP-0[0-9]` and `[Tt]echnique` both present.

## Issues Encountered

None.

## Known Stubs

None — analysis/contract artifact only; no code or UI surface created.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or schema changes. Threat register applied: T-159-04 (brandbook/lib read-only) verified by the Task 2 gate; T-159-05 (no silent drops) satisfied by the explicit ROUTED/DESCOPED disposition per item.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 161 can generate 8 round-1 candidates from `159-DESIGN-BRIEF.md` without interpretation: lanes, motif vocabulary, elimination gates, and the definition of done are all stated mechanically.
- Phase 162 inherits the BOOK-04 backlog (the routed GAP/UP table), the BOOK-05 misuse-gallery content, and the BOOK-07 79/150 meet-or-beat baseline.
- Trademark/legal clearance remains flagged for human review before public rollout.

## Self-Check: PASSED

- FOUND: .planning/phases/159-brand-audit-and-research/159-DESIGN-BRIEF.md
- FOUND: .planning/phases/159-brand-audit-and-research/159-03-SUMMARY.md
- FOUND: commit ea15d00 (Task 1)
- FOUND: commit 3a130b8 (Task 2)

---
*Phase: 159-brand-audit-and-research*
*Completed: 2026-06-12*
