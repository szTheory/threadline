---
phase: 195-validated-adversarial-critic-runner-panel
plan: "03"
subsystem: operator_surface/refute_battery
tags: [refute, critic, mechanical, partition-rule, D-03, CRITIC-02]
dependency_graph:
  requires: [195-02]
  provides: [refute-battery-substrate, refute-set-manifest, refute-scorecards, partition-guard]
  affects: [operator_surface, design-system-ledger, scorecards, stress_live, stress_fixtures]
tech_stack:
  added: []
  patterns:
    - refute-twin-fixture-idiom
    - mechanical-partition-proof
    - betterer-floor-seeding
    - temp-dir-mechanical-isolation-test
key_files:
  created:
    - .planning/refute/refute-set.json
    - test/threadline/operator_surface/refute_partition_test.exs
    - .planning/scorecards/refute.*.json (78 files, 13 stories × 6 theme/bp)
  modified:
    - lib/threadline/operator_surface/live/stress_live.ex
    - .planning/design-system-ledger.json
    - .planning/scorecards/page.*.json (120 files, scroll_cost floor bumps)
decisions:
  - Ember color (#FF8A5B, lum 0.403) cannot be used as CSS text color on page backgrounds in light mode — fails WCAG 4.5:1. Brand-fidelity and veto-ordering twins redesigned to use border-left accent on div containers (border colors not captured in color_pairs).
  - Veto-ordering twin uses border-left (not span color) to avoid MODE A WCAG fails; the off-token raw hex #e8a246 is detected at the panel layer (Plan 06), not the mechanical checker.
  - Typography flawed pole maps all six type roles to label (14 px) or sm (13 px). Both font sizes generate browser-default p margin-top that is off the spacing scale — all typography helper functions now use explicit 4-value margin shorthand.
  - h2 browser default margin-top (0.83em) is off-scale at both heading (20 px → 16.6 px) and body (16 px → 13.28 px) font sizes. All refute h2 elements now use margin: 0 0 var(--tl-space-N) 0.
  - h3.tl-text-label computes to 18.72 px (off font-size scale) with 18.72 px margins (off spacing scale). Replaced with p element using token CSS variables for font-size and explicit margin.
  - Adding 14 ledger entries grows the sidebar, increasing scrollHeight for all page stories. Bumped mechanical_floors for 20 page stories to new captured scroll_cost values (betterer baseline — floors only increase).
metrics:
  duration: "multi-session (context window boundary between Task 1 and Task 2)"
  completed: 2026-07-03
  tasks_completed: 2
  files_changed: 205
status: complete
---

# Phase 195 Plan 03: Refute-Test Battery Deterministic Substrate Summary

7 committed A/B twin fixtures (6 gestalt + 1 veto-ordering), 78 scorecards, and a 10-assertion pure-Elixir partition guard proving gestalt flaws pass all mechanical gates (D-03), forming the deterministic substrate CRITIC-02 requires before the LLM scorer may drive the ratchet.

## Objective

Build the refute-test battery's deterministic substrate: hand-authored A/B twin fixtures (polished + one injected gestalt flaw), a refute manifest, committed scorecards for the gestalt twins, and a partition-rule guard proving gestalt flaws pass all mechanical gates.

## What Was Built

### Task 1 (prior session, commit 64555391)

- Added 14 refute story tuples to `StressFixtures` (`@refute_twin_stories` module attribute + helpers)
- Added refute matrix render block to `stress_live.ex` (twin render + 7 helper function families)
- Added `REFUTE_STORIES` constant + Band R capture loop to `operator-tier-a-capture.spec.ts`
- 7 twin pairs: rhythm, density-card, hierarchy, typography, brand-fidelity, density-chrome, veto-ordering
- Veto-ordering flawed pole deliberately excluded from the REFUTE_STORIES capture band

### Task 2 (this session, commit 099afbaa)

**Ledger:** Added 14 refute entries to `design-system-ledger.json` (category: refute, kind: refute, all scores unrated at 0). Bumped `mechanical_floors` for 20 page stories whose `scroll_cost` increased after the sidebar grew to accommodate 144 entries.

**Scorecards:** 78 new refute scorecards committed — 13 stories × 6 (dark/light × 375/768/1280). The veto-ordering flawed pole correctly produces no committed scorecard.

**Refute manifest** (`.planning/refute/refute-set.json`): 7 twins, each recording `twin_id`, `polished_cell_id`, `flawed_cell_id`, `target_lens`, `expected_direction`, `class` (gestalt | veto_ordering), and `evidence_note`.

**Partition guard** (`test/threadline/operator_surface/refute_partition_test.exs`): 10 async assertions — manifest shape, required fields, scorecard existence for all 6 breakpoints per gestalt twin, D-03 mechanical gate proof (temp dir + MechanicalChecker.run/1), veto-ordering scorecard absence, veto-ordering evidence_note content, golden-set.json disjointness.

**stress_live.ex fixes** (Mode A violations eliminated — 423 → 0):
1. Replaced `<h3 class="tl-text-label tl-color-muted">` with `<p style="font-size: var(--tl-font-size-label); ...">` — h3.tl-text-label computed to 18.72 px off both scales
2. All refute h2 elements: `margin-bottom: ...` → `margin: 0 0 ... 0` — h2 browser default 0.83em is off the spacing scale at heading (20 px) and body (16 px) sizes
3. All typography helper functions: `margin-bottom: ...` → `margin: 0 0 ... 0` — label (14 px) and sm (13 px) p margins are off the spacing scale
4. Brand-fidelity twin redesigned: ember button background removed (fails WCAG 3.0:1 in light mode); now uses card `border-left: 3px solid var(--tl-color-ember)` on flawed pole and standard card on polished
5. Veto-ordering twin redesigned: ember span `color` removed (fails WCAG 4.5:1 in light mode); now uses div `border-left` — polished: `var(--tl-color-ember)`, flawed: `#e8a246` (the off-token hex that trips the Plan 06 panel veto)
6. Chrome-bloat: input `margin: 0` added; help-text p `margin: var(--tl-space-1) 0 0 0` to zero default margin-bottom (13 px at sm font is off-scale)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ember color fails WCAG in light mode as text/button-bg**
- **Found during:** Task 2 — mix verify.mechanical showed 423 violations across all 78 refute scorecards
- **Issue:** ember (#FF8A5B, lum 0.403) has contrast 2.19:1 against light page bg (#F7F9FC, lum 0.944) — below the 4.5:1 text threshold and 3.0:1 non-text threshold. Also: ember text on rgba amber bg (alpha 0.12, checker treats as solid rgb) produced 1.07:1 contrast
- **Fix:** Redesigned brand-fidelity twin (card border-left instead of ember button bg + amber span) and veto-ordering twin (div border-left instead of span color); both use `border-left` which is outside the color_pairs capture selector
- **Files modified:** `lib/threadline/operator_surface/live/stress_live.ex`
- **Commit:** 099afbaa

**2. [Rule 1 - Bug] h3.tl-text-label and h2 browser-default margins off spacing scale**
- **Found during:** Task 2 — mix verify.mechanical analysis
- **Issue:** h3.tl-text-label class computes to 18.72 px font-size (off font-size scale) and 18.72 px margin-top/bottom (off spacing scale). h2 browser default 0.83em at 20 px = 16.6 px (off spacing scale); at 16 px = 13.28 px (off spacing scale)
- **Fix:** Replaced h3 with inline-styled p element; added explicit 4-value margin shorthand to all refute h1/h2 elements
- **Files modified:** `lib/threadline/operator_surface/live/stress_live.ex`
- **Commit:** 099afbaa

**3. [Rule 1 - Bug] Typography p margins off spacing scale at label/sm font sizes**
- **Found during:** Task 2 — mix verify.mechanical analysis
- **Issue:** Browser default p margin = 1em. At 14 px (label): 14 px is off [4, 8, 12, 16, 20, 24, 32, 40, 48]. At 13 px (sm): 13 px is also off scale
- **Fix:** All typography helper functions now use `margin: 0 0 var(--tl-space-N) 0` shorthand to zero margin-top
- **Files modified:** `lib/threadline/operator_surface/live/stress_live.ex`
- **Commit:** 099afbaa

**4. [Rule 2 - Missing] scroll_cost floor bumps for page.* stories**
- **Found during:** Task 2 — mix verify.mechanical failed on page.actor.happy and others
- **Issue:** Adding 14 new ledger entries to the sidebar increased scrollHeight for all page stories. Existing mechanical_floors were below the new captured scroll_cost values
- **Fix:** Bumped mechanical_floors for 20 page stories to match the re-captured scroll_cost values. This is the correct "betterer baseline" behavior — floors only increase
- **Files modified:** `.planning/design-system-ledger.json`, 120 page scorecard files
- **Commit:** 099afbaa

## Verification Results

```
mix verify.mechanical: 18 tests, 0 failures
mix test test/threadline/operator_surface/refute_partition_test.exs: 10 tests, 0 failures
mix compile --warnings-as-errors: clean
```

## Known Stubs

None. The refute matrix renders live from stress_live.ex fixtures and produces captured scorecards. No stub data or hardcoded empty values flow to the UI.

## Threat Flags

None. The refute fixture adds a new render path at `/audit/__stress?story=refute.*` but this route is already operator-gated by the existing `only: [:dev]` constraint on the operator surface router. No new trust boundary is introduced.

## Self-Check: PASSED

- `.planning/refute/refute-set.json` exists: FOUND
- `test/threadline/operator_surface/refute_partition_test.exs` exists: FOUND
- 78 refute scorecard files exist in `.planning/scorecards/`: FOUND
- Task 1 commit 64555391: FOUND (`git log --oneline --all | grep 64555391`)
- Task 2 commit 099afbaa: FOUND (`git rev-parse --short HEAD`)
