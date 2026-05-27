---
phase: 117-evidence-plane-doc-authority
plan: 01
subsystem: docs
tags: [evidence-plane, semver, doc-authority, audit-transaction]

# Dependency graph
requires:
  - phase: 115-narrative-doc-sync
    provides: Audit.transaction/3 blessed write path narrative baseline
  - phase: 114-release-0-6-0-packaging
    provides: 0.6.0 semver packaging and CHANGELOG [0.6.0] section
provides:
  - Maintainer-accurate split evidence guide map in PROJECT.md (no phantom hub)
  - Hex semver vocabulary in getting-started and upgrade-path adopter guides
  - 0.5.x → 0.6.x minor upgrade bullet with Evidence + Audit.transaction/3 pointers
  - Incident JSON step 1 prose aligned to Audit.transaction/3 with :action
affects:
  - 117-02 (doc-contract locks against final prose)
  - v1.25 DOC requirements DOC-01, DOC-02

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Split-guide evidence plane map (no hub file)"
    - "Hex semver in adopter paths; API-era v1.xx headings allowlisted in domain-reference"

key-files:
  created: []
  modified:
    - .planning/PROJECT.md
    - guides/getting-started-saas.md
    - guides/upgrade-path.md
    - guides/domain-reference.md

key-decisions:
  - "No guides/evidence-plane.md hub — PROJECT.md lists how-threadline-works, upgrade-path, domain-reference, operator-surface"
  - "Adopter semver: 0.6.0+ recommended path heading; 0.5.0 lane era; 0.5.x→0.6.x upgrade bullet"
  - "Incident JSON step 1 names Audit.transaction/3 with :action, not record_action/2 alone"

patterns-established:
  - "Maintainer doc alignment bullet mirrors README Evidence plane split-guide links"
  - "Upgrade-path intro evaluator sentence packages 0.6.0 vs 0.5.0 semver story"

requirements-completed: [DOC-01, DOC-02]

# Metrics
duration: 5min
completed: 2026-05-27
---

# Phase 117 Plan 01: Doc Authority Prose Summary

**Maintainer and adopter prose now use split evidence guides and Hex semver — phantom hub removed, 0.5→0.6 upgrade documented, incident JSON step 1 cites Audit.transaction/3**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-27T22:43:00Z
- **Completed:** 2026-05-27T22:48:20Z
- **Tasks:** 3 completed
- **Files modified:** 4

## Accomplishments

- Fixed `.planning/PROJECT.md` shipped-milestone bullet to list real split guides instead of phantom `guides/evidence-plane.md`
- Swept `v1.2x` milestone labels from `guides/getting-started-saas.md` and `guides/upgrade-path.md`; added `0.5.x → 0.6.x` Evidence plane minor-upgrade bullet
- Updated incident JSON step 1 in `guides/domain-reference.md` to describe semantics via `Threadline.Audit.transaction/3` with `:action`

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix PROJECT.md evidence-plane guide map (DOC-01)** - `5450662` (docs)
2. **Task 2: Semver sweep getting-started + upgrade-path (DOC-02)** - `efeafc8` (docs)
3. **Task 3: Fix domain-reference incident JSON step 1 (DOC-03 prose)** - `1bd2814` (docs)

**Plan metadata:** `dfd35d6` (docs: complete plan)

## Files Created/Modified

- `.planning/PROJECT.md` — Replaced phantom evidence-plane hub with split-guide paths in doc-alignment bullet
- `guides/getting-started-saas.md` — `Recommended path (0.6.0+)` heading
- `guides/upgrade-path.md` — Semver lane prose, 0.5.x→0.6.x bullet, evaluator intro sentence, packaging scorecard era label
- `guides/domain-reference.md` — Incident JSON step 1 blessed write path prose

## Decisions Made

None beyond locked D-117-01/02/03 context — plan executed as written.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Prose baseline ready for plan 117-02 doc-contract locks and `mix verify.doc_contract` alias wiring
- No blockers for wave 2 execution

## Self-Check: PASSED

- `rg 'v1\.2[0-9]' guides/getting-started-saas.md guides/upgrade-path.md` — empty (PASS)
- `rg -F 'guides/evidence-plane.md' .planning/PROJECT.md` — empty (PASS)
- Incident step 1 names `Audit.transaction/3` with `:action` (PASS, line 274)

---
*Phase: 117-evidence-plane-doc-authority*
*Completed: 2026-05-27*
