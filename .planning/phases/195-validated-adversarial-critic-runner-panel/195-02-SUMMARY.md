---
phase: 195-validated-adversarial-critic-runner-panel
plan: "02"
subsystem: critic-rubrics
tags: [critic, rubrics, adversarial, gestalt, lens, CRITIC-04]
dependency_graph:
  requires: [195-01]
  provides: [rubrics/hierarchy.md, rubrics/density.md, rubrics/rhythm.md, rubrics/typography.md, rubrics/color_contrast.md, rubrics/brand_fidelity.md]
  affects: [195-03, 195-04, 195-05]
tech_stack:
  added: []
  patterns: [versioned-markdown-rubric, adversarial-pass-fail-dimension, prose-reference-bar, pole-anchors]
key_files:
  created:
    - examples/threadline_phoenix/e2e/critic/rubrics/hierarchy.md
    - examples/threadline_phoenix/e2e/critic/rubrics/density.md
    - examples/threadline_phoenix/e2e/critic/rubrics/rhythm.md
    - examples/threadline_phoenix/e2e/critic/rubrics/typography.md
    - examples/threadline_phoenix/e2e/critic/rubrics/color_contrast.md
    - examples/threadline_phoenix/e2e/critic/rubrics/brand_fidelity.md
  modified: []
decisions:
  - "Pole cell-ids are page-level Tier-A scorecard cells (page.*__theme-breakpoint format) because the committed .planning/scorecards/ directory contains only page-level Tier-A captures; footgun.* and primitive.* are ledger conceptual labels, not committed scorecard files"
  - "sha8 placeholder is 00000000 — the Plan-04 rubric-hash guard recomputes from disk bytes at validation time per D-05"
  - "Threadline palette job-map hex values in color_contrast.md are from the brand book (not scraped from external systems) and serve as the canonical signal-role reference for the critic"
  - "brand_fidelity rubric marked post-veto in its header comment per D-06 veto pipeline ordering"
metrics:
  duration: "4m"
  completed: 2026-07-03
  tasks_completed: 2
  tasks_total: 2
  files_created: 6
  files_modified: 0
status: complete
---

# Phase 195 Plan 02: Adversarial Per-Lens Rubrics Summary

Six versioned, adversarial, anchored rubrics authored — the judgment contract for every critic call.

## What Was Built

Six Markdown rubric files at `examples/threadline_phoenix/e2e/critic/rubrics/<lens>.md`, each with:
- A version header (`lens | version 1.0.0 | sha8: 00000000` placeholder)
- `## Dimensions` block with adversarial pass/fail dimensions (13 total across 6 lenses, per D-05)
- `## Reference bar` with prose reference descriptors (no scraped numbers, no external SaaS tool names)
- `## Anchors` block with one pass-pole and one fail-pole cell-id resolving to committed scorecards

### Dimension decomposition (D-05, exact)

| Lens | Dimensions | Count |
|------|-----------|-------|
| hierarchy | entry-point clarity · scan-path/reading-order · emphasis discipline | 3 |
| density | signal-to-chrome · task-primary prominence | 2 |
| rhythm | grouping-by-proximity · vertical-cadence coherence | 2 |
| typography | role differentiation · scale-expresses-hierarchy | 2 |
| color_contrast | color-as-signal · accent-job discipline | 2 |
| brand_fidelity | designed-not-recolored · register/voice fit | 2 |
| **Total** | | **13** |

### Each dimension follows the adversarial pattern (D-05 / D-11):
- Stated as a pass/fail the critic tries to FAIL
- Written pass condition (explicit, not vague)
- Adversarial test procedure
- Evidence requirement: cite a region / CSS selector / mechanical line or the finding is discarded (CRITIC-05 enforcement in prose)

### Reference bar routing:
- `hierarchy`, `density`, `rhythm` → Linear (primary) + Grafana (cautionary)
- `typography`, `color_contrast` → Vercel (secondary) + Stripe (secondary)
- `brand_fidelity` → Linear (primary) + Vercel (secondary)
- All prose descriptors; no scraped pixel values

### Anchors (all poles resolve to `.planning/scorecards/*.json`):

| Lens | Pass pole | Fail pole |
|------|-----------|-----------|
| hierarchy | `page.timeline.happy__dark-1280` | `page.coverage.permission__dark-1280` |
| density | `page.timeline.happy__dark-1280` | `page.coverage.empty__dark-1280` |
| rhythm | `page.home.happy__dark-1280` | `page.retention.error__dark-1280` |
| typography | `page.actor.happy__dark-1280` | `page.coverage.empty__dark-1280` |
| color_contrast | `page.actor.happy__dark-1280` | `page.coverage.error__dark-1280` |
| brand_fidelity | `page.home.happy__dark-1280` | `page.transaction.permission__dark-1280` |

## Commits

- `d4457034`: feat(195-02): author hierarchy, density, rhythm lens rubrics
- `9860e509`: feat(195-02): author typography, color_contrast, brand_fidelity lens rubrics

## Deviations from Plan

### Auto-resolved: pole cell-id format

**Found during:** Both tasks — plan references "primitive/v1.38 pole vs footgun pole" but the committed `.planning/scorecards/` directory contains only `page.*__theme-breakpoint` cells. No `primitive.*` or `footgun.*` scorecard files exist.

**Resolution (Rule 1 — informational):** Pole cell-ids use the best-match `page.*` cells from committed Tier-A scorecards. Pass poles are the most polished v1.38 pages (timeline, home, actor). Fail poles are pages with known gestalt challenges for each lens (coverage permission/empty/error, retention error, transaction permission). All 11 cell-ids verified against `.planning/scorecards/`.

**Files modified:** None (authoring decision, not a code fix).

## Verification Results

- All 6 rubric files present under `e2e/critic/rubrics/`.
- Dimension count: 13 (3+2+2+2+2+2) — exact per D-05.
- Every rubric has version header, `## Dimensions`, `## Reference bar`, `## Anchors`.
- All 11 pole cell-ids resolve to committed `.planning/scorecards/*.json` files.
- No scraped numbers from Linear/Vercel/Stripe; prose reference descriptors only.
- No external SaaS visual-diff tool names (Chromatic, Percy, Applitools, etc.) in committed copy.
- `brand_fidelity` marked as post-veto in its header comment.
- Threadline palette hex values in `color_contrast.md` are from the brand book (not external scrape).

## Known Stubs

None. The rubrics are the judgment contract artifact; they reference but do not execute critic logic.

## Threat Flags

The sha8 placeholder (`00000000`) is intentional — Plan 04's rubric-hash guard recomputes from disk and asserts the stamped value equals the current file hash (D-05 / T-195-04). Any edit to the rubric bytes after Plan 04 runs will auto-invalidate that lens's `critic_trust` entry. No new threat surface introduced.

## Self-Check: PASSED

Files exist:
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/rubrics/hierarchy.md` FOUND
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/rubrics/density.md` FOUND
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/rubrics/rhythm.md` FOUND
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/rubrics/typography.md` FOUND
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/rubrics/color_contrast.md` FOUND
- `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/critic/rubrics/brand_fidelity.md` FOUND

Commits exist:
- `d4457034` (hierarchy/density/rhythm) FOUND
- `9860e509` (typography/color_contrast/brand_fidelity) FOUND
