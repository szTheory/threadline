---
phase: 181-baseline-audit-and-guard-repair
plan: 01
subsystem: testing
tags: [operator-ui, audit, screenshots, playwright, baseline]

requires:
  - phase: v1.37
    provides: operator surface stress route, design-system ledger, screenshot guardrails, accessibility/motion evidence
provides:
  - Page/JTBD baseline audit matrix for all mounted /audit surfaces
  - Screenshot inventory separating Tier B rendered slices from Tier C local packet PNGs
  - Partial committed Tier C Home and Timeline screenshot packet
  - Owned stale rendered-guard findings for later Phase 181 repair plans
affects: [181-02, 181-03, 181-08, 181-09, 181-10, 181-11, 183, 184, 185, 186, 187]

tech-stack:
  added: []
  patterns:
    - Tiered evidence matrix: source/CI contracts, rendered slices, local packet screenshots
    - Packet-first baseline: failures are inventoried with owners instead of expanding CI screenshot baselines

key-files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md
    - .planning/phases/181-baseline-audit-and-guard-repair/181-SCREENSHOT-INVENTORY.md
    - .planning/phases/181-baseline-audit-and-guard-repair/screenshots/
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts

key-decisions:
  - "Plan 01 commits the partial Tier C Home/Timeline packet generated before stale E2E assertions failed, while recording missing cells with later-phase owners."
  - "The existing stress screenshot CI allowlist stays bounded; no full page x path x theme x viewport pixel matrix was promoted."
  - "A desktop-1024 responsive viewport row was added without changing operator routes, data-testids, capture/query/auth semantics, public APIs, or dependencies."

patterns-established:
  - "Every baseline row records route/render evidence, issue taxonomy, guard disposition, and later-phase owner."
  - "Screenshot failures are treated as owned guard-repair evidence, not as permission to weaken coverage."

requirements-completed: [BASE-01, BASE-03]

duration: 32 min
completed: 2026-06-26
status: complete
---

# Phase 181 Plan 01: Rendered Baseline Audit and Screenshot Inventory Summary

**Rendered `/audit` baseline packet with page/JTBD matrix, bounded screenshot inventory, partial Home/Timeline PNG evidence, and owned stale-rendered guard failures.**

## Performance

- **Duration:** 32 min
- **Started:** 2026-06-26T12:37:21Z
- **Completed:** 2026-06-26T13:09:26Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Created `181-BASELINE-AUDIT.md` with all real `/audit` surfaces plus `/audit/__stress`, each tied to route/render evidence, JTBD, issue taxonomy, guard disposition, and later-phase owner.
- Created `181-SCREENSHOT-INVENTORY.md` with Tier B/Tier C command results, existing CI `screenshot_allowlist` baselines, committed packet PNG paths, and failing rendered assertions.
- Added the bounded `desktop-1024` viewport row to `operator-responsive-mobile-first.spec.ts`.
- Committed nine partial Tier C screenshots for Home and Timeline default/light lanes.

## Task Commits

1. **Task 1: Create the page/JTBD baseline audit matrix** - `296e975` (docs)
2. **Task 2: Generate and inventory bounded screenshot evidence** - `f872e86` (docs)

## Files Created/Modified

- `181-BASELINE-AUDIT.md` - Canonical page/JTBD audit packet for v1.38 planning.
- `181-SCREENSHOT-INVENTORY.md` - Screenshot lane inventory, command results, missing-cell owners, and precommit result.
- `screenshots/home__default__1280.png`, `home__default__375.png`, `home__light__1280.png` - Home packet evidence.
- `screenshots/timeline__default__1280.png`, `timeline__default__375.png`, `timeline__light__1280.png` - Timeline packet evidence.
- `screenshots/timeline-empty__default__1280.png`, `timeline-empty__default__375.png`, `timeline-empty__light__1280.png` - Timeline empty-state packet evidence.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` - Added `desktop-1024` viewport row.

## Verification

| Check | Result |
|---|---|
| Baseline audit source check | PASS with safe-quoted `rg` equivalent; the plan's literal backtick regex triggers zsh command substitution. |
| Screenshot inventory source check | PASS for `__default__1280`, `__default__375`, `__light__1280`, `desktop-chromium-light`, `desktop-1024`, Tier B/Tier C, and required spec names. |
| `operator-screenshots.spec.ts` default packet | FAIL: 6 failed; generated Home, Timeline, Timeline-empty default PNGs before stale assertions. |
| `operator-screenshots.spec.ts` light packet | FAIL: 2 failed; generated Home, Timeline, Timeline-empty light PNGs before stale assertions. |
| `operator-phase-178-uat.spec.ts --grep "stays within viewport at 320 \\+ 1440|column 2 at 1024"` | PASS: 27 passed. |
| `operator-responsive-mobile-first.spec.ts --grep "operator responsive matrix: (phone|tablet|desktop-1024)|Timeline row-first command surface"` | FAIL: 12 passed, 18 failed; all failures recorded in inventory. |
| `cd examples/threadline_phoenix && mix precommit` | FAIL: 96 tests, 7 failures in existing demo-seed/audit-transaction assertions. |
| Plan source check for `BASE-01` / `BASE-03` evidence | PASS. |

## Decisions Made

- Committed only generated root phase packet PNGs, not Playwright `test-results` artifacts.
- Recorded missing screenshot cells with owners rather than weakening screenshot or responsive coverage.
- Left screenshot CI allowlist unchanged and bounded to the existing three stress baselines.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected generated screenshot output location**
- **Found during:** Task 2
- **Issue:** The plan command used a relative `OPERATOR_SCREENSHOT_DIR`, but `run-e2e.sh` runs Playwright from `examples/threadline_phoenix/e2e`, so PNGs were emitted under `examples/threadline_phoenix/e2e/.planning/...`.
- **Fix:** Moved the nine generated PNGs into `.planning/phases/181-baseline-audit-and-guard-repair/screenshots/` and removed the accidental generated E2E-relative `.planning` folder.
- **Files modified:** `screenshots/*.png`
- **Verification:** `find .../screenshots -name '*.png' | wc -l` returned 9.
- **Committed in:** `f872e86`

**2. [Rule 3 - Blocking] Re-ran Task 1 source grep with safe shell quoting**
- **Found during:** Task 1
- **Issue:** The plan's literal `rg` expression contains backticks around `/audit` and `/audit/__stress`; zsh interpreted them as command substitution.
- **Fix:** Re-ran the same source assertion with single-quoted regex content.
- **Files modified:** None.
- **Verification:** Safe-quoted `rg` matched all required surfaces, taxonomy buckets, and D-181 references.
- **Committed in:** Verification-only handling; no file commit required.

---

**Total deviations:** 2 auto-fixed or handled (2 Rule 3)  
**Impact on plan:** No scope expansion. The path correction keeps generated evidence in the intended phase directory; the quoting correction verifies the same source assertion.

## Issues Encountered

- `operator-screenshots.spec.ts:98` currently cannot find `timeline-row` with `tickets` for `correlation_id=walk-acme-4521-close`, blocking dense Timeline and downstream page captures.
- `operator-screenshots.spec.ts:176` currently cannot find `Coverage inspection is not available` for support-user Coverage denied-state evidence.
- `operator-responsive-mobile-first.spec.ts:353` and `:556` fail in phone/tablet/desktop-1024 rows because Timeline row discovery does not find the expected transaction link or row for `walk-acme-4521-close`.
- Example `mix precommit` fails in existing demo-seed/audit-transaction tests; no Elixir source, seed, capture, query, auth, route, dependency, or public API code changed in this plan.

## Known Stubs

None. Stub scan only found the quoted failed assertion text `Coverage inspection is not available` inside the inventory.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for `181-02` and `181-03`. The stale rendered evidence failures are explicit in `181-SCREENSHOT-INVENTORY.md` and should drive guard finding/repair without reopening page polish scope.

## Self-Check: PASSED

- Found `181-BASELINE-AUDIT.md`.
- Found `181-SCREENSHOT-INVENTORY.md`.
- Found 9 committed packet PNGs under the phase screenshots directory.
- Found task commits `296e975` and `f872e86` in git history.
- Working tree was clean before summary closeout.

---
*Phase: 181-baseline-audit-and-guard-repair*
*Completed: 2026-06-26*
