---
phase: 204-structure
plan: 09
subsystem: operator-surface
tags: [refactor, liveview, stress-lab, function-components, size-gate, hex-packaging, credo, structural-register]

requires:
  - phase: 204-structure
    provides: "Threadline.Test.SourceFamily reader (204-05/06), size gate at measured ceilings (204-02), credo register at 21 (204-08), LiveView sibling pattern (204-08)"
provides:
  - "Threadline.OperatorSurface.Live.StressLive.Sections (lib/threadline/operator_surface/live/stress_live/sections.ex): one function component per stress-lab section, with attr declarations"
  - "Threadline.OperatorSurface.Live.StressLive.Refute (lib/threadline/operator_surface/live/stress_live/refute.ex): refute-twin copy and inline-style helpers"
  - "Threadline.OperatorSurface.Live.StressLive.Paths (lib/threadline/operator_surface/live/stress_live/paths.ex): stress-lab URL helpers"
  - "mix.exs exclude pattern ~r{^lib/threadline/operator_surface/live/stress_live(\\.ex$|/)} with the stress_live/ prefix and all three sibling paths proven absent from the unpacked Hex archive"
  - "stress_live.ex at 224 lines (from 1398), with no size exception and no register sites; the only file exception left is stress_fixtures.ex"
  - "Credo register 21 -> 19 (Nesting 15, CyclomaticComplexity 4), @ceiling 19"
affects: [204-10, 204-11, 204-15, source-size-contract, credo-config-contract, release-artifact-contract, STRUCT-03, STRUCT-07]

actuals:
  tokens: 36600     # chars/4 over the realized diff f9769ed7..5bed4c63 (146311 chars)
  tasks: 2
  commits: 7        # MEASURED: git rev-list --count f9769ed7..HEAD before the SUMMARY commit
plan_head_before: f9769ed71204f3178dbd04bd1c116c7c5904a581

tech-stack:
  added: []
  patterns:
    - "Markup moved into a component keeps its original absolute indentation. HEEx trims a component template's leading and trailing whitespace, so the parent's whitespace around the call reproduces the original bytes exactly."
    - "Pure helper modules in a LiveView family (Refute, Paths) expose def functions and carry @moduledoc false; only the Sections module uses Phoenix.Component"
    - "A {key, key} => value module attribute map replaces a many-clause case when Credo counts the clauses as complexity"

key-files:
  created:
    - lib/threadline/operator_surface/live/stress_live/sections.ex
    - lib/threadline/operator_surface/live/stress_live/refute.ex
    - lib/threadline/operator_surface/live/stress_live/paths.ex
  modified:
    - lib/threadline/operator_surface/live/stress_live.ex
    - lib/threadline/operator_surface/stress_fixtures.ex
    - mix.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/operator_surface/stress_router_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/credo_config_contract_test.exs

key-decisions:
  - "A third sibling, StressLive.Refute, holds the refute-twin helpers (about 600 lines). If they had gone into Sections with the markup, Sections would have been about 1,300 lines. That needs either a size exception, which D-12 forbids, or this split."
  - "Paths was needed even though the parent was already under 800. story_sidebar/1 in Sections and handle_params/3 in the parent both build stress-lab URLs, so the helpers have to be public in a module both can reach."
  - "The display helpers (story_id, score, screenshot_status, ledger_id, origin_cohort, status, preview_copy) and the three link-class helpers moved into Sections as defp, next to the only markup that reads them."
  - "Section components are public (Sections.page_header, ledger_metrics, story_sidebar, story_details, refute_matrix, ui_matrix). The eight per-twin and five matrix-group components are private to Sections."
  - "The parent keeps show_refute_matrix?/1 and show_ui_matrix?/1, because those decide whether a section renders at all (the :if on each call)."
  - "Refute helpers drop their refute_ prefix (Refute.twin/1, Refute.color_accent/2, and so on). The module name already says it."
  - "component_contract_test needed no change. It lists stress_live.ex by filename and reads it through SourceFamily, so the siblings are already in scope. rendered_output_contract's git ls-files pathspec already matches live/stress_live/*.ex."

requirements-completed: []
requirements-advanced: [STRUCT-03, STRUCT-07]  # stress_live family done; other LiveViews and 19 register sites belong to later 204 plans

coverage:
  - id: D1
    description: "Hex exclusion widened to the stress_live family and proven against the unpacked archive; page header extracted as the tracer"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "release_artifact_contract_test (built archive refutes stress_live/ prefix and each sibling path), stress_router_test, ui_form_policy, rendered_output_contract, source_size (125 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser: 326 passed / 8 failed / 16 skipped after one unchanged re-run (see Deviations); mix verify.operator_stress exit 0, 32 passed / 6 skipped, same as base"
        status: pass
    human_judgment: false
  - id: D2
    description: "render/1 carved into per-section components; stress_live.ex under 800 lines; no stress_live size exception remains"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs real-tree file and function tests; grep -c 'live/stress_live' in the size test prints 0"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after every commit: 326/8/16, known 8 only, baselines clean; verify.operator_stress exit 0 32/6 after every commit"
        status: pass
    human_judgment: false
  - id: D3
    description: "Both stress_live register sites drained; register 21 -> 19"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "credo_config_contract_test; mix credo --strict on the whole repo (3422 mods/funs, no issues)"
        status: pass
      - kind: integration
        ref: "DB_PORT=5433 mix test (1769 tests, 0 failures, 1 excluded); MIX_ENV=dev mix verify.dialyzer (Total errors: 0); mix compile --no-optional-deps --warnings-as-errors clean"
        status: pass
    human_judgment: false

duration: 1h49m
completed: 2026-09-24
status: complete
---

# Phase 204 Plan 09: Stress lab LiveView split Summary

**stress_live.ex goes from 1,398 lines to 224. Its 540-line render/1 is now a list of calls to per-section components in `StressLive.Sections`. The refute-twin helpers moved to `StressLive.Refute` and the URL helpers to `StressLive.Paths`. The Hex package excludes the whole `stress_live` family, both complexity register sites are drained, and the rendered HTML of all 294 stress-lab URLs is byte-identical to the plan base.**

## Performance

- **Duration:** 1h 49m (most of it spent on seven browser-lane runs of about 9 minutes each)
- **Started:** 2026-09-23T23:22:38Z
- **Completed:** 2026-09-24T01:12:01Z
- **Tasks:** 2
- **Files:** 3 created, 7 modified

## Line counts

| File | Before | After |
|------|--------|-------|
| lib/threadline/operator_surface/live/stress_live.ex | 1398 | 224 |
| lib/threadline/operator_surface/live/stress_live/sections.ex | (new) | 706 |
| lib/threadline/operator_surface/live/stress_live/refute.ex | (new) | 595 |
| lib/threadline/operator_surface/live/stress_live/paths.ex | (new) | 52 |

StressLive.render/1 went from 540 lines to under 120. The largest component is `ui_matrix_overlays/1` at about 85 lines.

Size-gate entries removed: the stress_live.ex file exception and its render/1 function exception. The only file exception left is `lib/threadline/operator_surface/stress_fixtures.ex`, with the D-12 reason.

## Section-to-component map

| Original render/1 section | Component | Visibility | Attrs |
|---|---|---|---|
| Lab header with Clear filters | `Sections.page_header/1` | public | clear_path |
| Ledger metrics strip | `Sections.ledger_metrics/1` | public | selected_story, selected_entry |
| Sidebar: category nav, status filters, story list | `Sections.story_sidebar/1` | public | 9 (categories, filters, stories, selection, stress_path) |
| Preview header, ledger table, fixture preview | `Sections.story_details/1` | public | selected_story, selected_entry, selected_assigns, selected_theme, selected_viewport |
| Refute Twin matrix wrapper | `Sections.refute_matrix/1` | public | selected_story |
| Twin 1 Rhythm | `refute_rhythm/1` | private | selected_story |
| Twin 2 Density (card wrap) | `refute_density_card/1` | private | selected_story |
| Twin 3 Hierarchy | `refute_hierarchy/1` | private | selected_story |
| Twin 4 Typography | `refute_typography/1` | private | selected_story |
| Twin 5 Brand fidelity | `refute_brand_fidelity/1` | private | selected_story |
| Twin Color contrast | `refute_color_contrast/1` | private | selected_story |
| Twin 6 Density (chrome bloat) | `refute_density_chrome/1` | private | selected_story |
| Twin 7 Veto ordering | `refute_veto_ordering/1` | private | selected_story |
| Primitives Matrix wrapper | `Sections.ui_matrix/1` | public | none |
| Buttons, Links | `ui_matrix_actions/1` | private | none |
| Badges, Alerts, Misc Atoms, Cards & Tiles | `ui_matrix_display/1` | private | none |
| Empty & Error States, Data Display, Data States | `ui_matrix_data/1` | private | none |
| Forms, Data Panel | `ui_matrix_forms/1` | private | none |
| Overlays & Disclosures | `ui_matrix_overlays/1` | private | none |

The ledger-error alert and the empty-preview state (a few lines each) stay inline in the parent's render/1. There is no `embed_templates`, no `.heex`, and no `defdelegate`. `@ui_form_policy {:has_forms, ...}` is still declared on the StressLive page module.

## Register sites drained

| Site | Technique | Commit |
|------|-----------|--------|
| `refute_brand_lines/1` (complexity 10), now `Refute.brand_lines/1` | split into multi-clause `brand_copy/1` (by scenario) and `brand_note/1` (by rung) | 5bed4c63 |
| `refute_color_accent/2` (complexity 13), now `Refute.color_accent/2` | `@color_accents` `{rung, role}` map with `Map.fetch!/2`; the WIDENED comment moved with the r2 rows | 5bed4c63 |

The register is now Nesting 15 + CyclomaticComplexity 4 = 19, with `@ceiling 19`.

## verify.operator_stress: base and after

| Point | Exit | Result |
|---|---|---|
| Plan base (f9769ed7, before any change) | 0 | 32 passed / 6 skipped |
| After each of the 7 commits | 0 | 32 passed / 6 skipped |

## Zero-output-change evidence (D-00b)

After every commit:
- `mix compile --force --warnings-as-errors` is clean, and `mix format --check-formatted` passes.
- `mix credo --strict` on the stress_live family reports no issues.
- The ZOC test set is green (125 tests): stress_router, component_contract, rendered_output_contract, ui_form_policy, style_byte_lock, source_size, credo_config, release_artifact, source_comment_location, and optional_deps.
- `mix verify.example_browser` finished at **326 passed / 8 failed / 16 skipped**. The failing set was exactly `operator-screenshot-regression.spec.ts:108/:115/:136/:145` on desktop-chromium and mobile-chromium. The snapshot baselines stayed clean, and the scorecard fixtures were restored after every run.
- `mix verify.operator_stress` exited 0 with 32 passed / 6 skipped, the same as base.

Extra evidence (not committed): a throwaway ExUnit capture (`/tmp/p204_09_capture_test.exs`) rendered 294 URLs through a copy of the real stress router, capturing both the static and the connected render for each. The URLs were every StressFixtures story plus every graded-ladder story, each with its category, and six filter, theme, and viewport combinations, including an unknown category and story. That is 588 HTML files. CSRF tokens, the LiveView session and static tokens, `phx-` ids, and the `tl-*-<unique integer>` element ids were masked. Two captures at the plan base were identical to each other. After every commit, all **588 files were byte-identical** to the base. That includes the whitespace: no indentation changed, which is stricter than the whitespace-collapsed compare 204-08 needed.

## Task Commits

1. **Task 1 (tracer): widen the Hex exclusion and extract the page header:** `8066ee38`. The tracer verify was re-run green before expanding.
2. **Task 2: carve the remaining sections, get under 800, and drain the register:**
   - `51c46ec1`: Paths extraction
   - `12f3c493`: ledger_metrics, story_sidebar, and story_details
   - `95a9af95`: Refute helpers moved; the file exception deleted
   - `85c307bf`: refute_matrix and the per-twin components
   - `ecb9852e`: ui_matrix and the group components; the render/1 exception deleted
   - `5bed4c63`: both register sites drained

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Third sibling `StressLive.Refute`**
- **Found during:** Task 2 planning
- **Issue:** The plan lists Sections plus an optional Paths. The refute-twin helpers are about 600 lines. Putting them in Sections with their markup would have produced a file of about 1,300 lines, which needs a size exception, and D-12 and the HALT clause forbid that. Leaving them in the parent would have required making them public on the LiveView.
- **Fix:** Moved them into their own pure module, `StressLive.Refute`, which is listed in `@maintainer_only_paths`. The mix.exs exclusion covers it by directory.
- **Commit:** 95a9af95

**2. [Rule 1 - Stale reference] stress_fixtures.ex comment**
- **Found during:** Task 2
- **Issue:** A comment in `stress_fixtures.ex` pointed readers at "@hierarchy_scale in stress_live.ex", which moved.
- **Fix:** It now names `StressLive.Refute`. This is a one-line comment change, and the line count is unchanged, so the 980-line exception still matches.
- **Commit:** 95a9af95

**3. [Browser re-run] Task 1, one unchanged re-run**
- The first browser run after the Task 1 change reported a 9th failure: `operator-storybook.spec.ts:70` on mobile-chromium ("keeps representative stories within the 375px viewport"). The error was only "Test timeout of 120000ms exceeded", with no assertion, and that run took 16.5 minutes against the usual 8.5. The Storybook lane does not render the stress lab. This matches the dispatch's timeout-hang re-run class. One re-run with nothing changed was clean at 326/8/16 with the known 8. Every later run was clean on the first try.

**4. [Verify-path substitution] Browser gate**
- The plan's `grep '82 passed'` chain is stale, per the dispatch rules. The invariant was checked instead: 326/8/16, exactly the 8 known screenshot failures, and clean baselines.

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 stale reference), plus 1 re-run and 1 verify substitution.
**Impact on plan:** None on scope or output. Every size exception was removed, and none was added.

## Issues Encountered

- The first capture pass differed between two base runs. The cause was LiveView root ids (`phx-G…`) and `tl-empty-heading-<unique integer>` ids. After masking both, the captures were deterministic.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- The size gate's file exceptions are down to stress_fixtures.ex alone, as D-12 requires. The function exceptions left are the render/1 pins for actor, coverage, export_status, retention_history, start, and transaction LiveViews.
- 19 register sites remain. `mix credo --strict` is clean. The full suite passes (1769 tests, 0 failures), and `verify.dialyzer` reports 0 errors.

---
*Phase: 204-structure*
*Completed: 2026-09-24*

## Self-Check: PASSED

- sections.ex, refute.ex, and paths.ex exist. stress_live.ex is 224 lines.
- All 7 task commits (8066ee38, 51c46ec1, 12f3c493, 95a9af95, 85c307bf, ecb9852e, 5bed4c63) are in `git log`.
- Acceptance: `grep -c 'stress_live(' mix.exs` prints 1. `grep -c 'live/stress_live/"'` in release_artifact_contract_test prints 1. The test/fixtures diff from base is empty. `grep -c 'Structural debt:'` in stress_live.ex prints 0. `grep -c 'live/stress_live'` in the size test prints 0. The stress_fixtures.ex exception line appears once.
