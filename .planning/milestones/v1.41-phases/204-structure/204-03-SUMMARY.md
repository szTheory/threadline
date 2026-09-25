---
phase: 204-structure
plan: 03
subsystem: operator-surface
tags: [css, style, byte-lock, compile-time-resource, external_resource, hex-packaging, refactor]

requires:
  - phase: 204-structure
    provides: "204-01 CSS byte lock (golden file + two sha256 pins) and source size gate; 204-02 SourceFamily reader and ci.all de-duplication"
provides:
  - "Threadline.OperatorSurface.Style reads nine ordered .css segments (01_tokens … 09_responsive) at compile time"
  - "Style.segments/0 (@doc false): the explicit cascade list"
  - "Threadline.Test.StyleSource (test/support/style_source.ex): css!/0 in cascade order, read!/0 = css <> newline <> style.ex text"
  - "Byte-lock cases: source reader follows the rendered cascade, segment order, existence/uniqueness, no orphan css, every segment is an external resource, no Path.wildcard"
  - "Hex archive assertion for all nine segment files; planning-vocabulary scan widened to style/*.css"
  - "Size gate carries no style entry (the style.ex file and css/1 function exceptions are gone)"
affects: [204-04, 204-05, operator-surface, release-artifact, source-size-gate]

actuals:
  tokens: 79173    # chars/4 over the realized diff (moved CSS counted as removed + added)
  tasks: 3
  commits: 11
plan_head_before: 500fe905b349b5e9a15dbff165bbfa27d71bfa07

tech-stack:
  added: []
  patterns:
    - "Compile-time CSS resource: explicit @segments list, one @external_resource per segment, @stylesheet built once and rendered with Phoenix.HTML.raw"
    - "Order-bearing source reader: order comes from the compiled module (Style.segments/0), never the filesystem"
    - "Pivot then peel tail-first, one segment per commit, each proven byte-identical"

key-files:
  created:
    - lib/threadline/operator_surface/style/01_tokens.css
    - lib/threadline/operator_surface/style/02_base_shell.css
    - lib/threadline/operator_surface/style/03_page_home.css
    - lib/threadline/operator_surface/style/04_controls.css
    - lib/threadline/operator_surface/style/05_feedback.css
    - lib/threadline/operator_surface/style/06_layout_primitives.css
    - lib/threadline/operator_surface/style/07_find_detail.css
    - lib/threadline/operator_surface/style/08_overlays_motion.css
    - lib/threadline/operator_surface/style/09_responsive.css
    - test/support/style_source.ex
  modified:
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/style_byte_lock_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/brandbook_token_parity_test.exs
    - test/threadline/operator_surface/component_contract_test.exs
    - test/threadline/operator_surface/stress_router_test.exs
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts
    - DESIGN-SYSTEM.md

key-decisions:
  - "<style> and </style> live in the Elixir concatenation, not in the segment bytes. The segment bytes are exactly the golden minus those tags, and the first render was byte-identical, so no join-newline adjustment was needed. 01_tokens.css therefore begins with the newline that followed <style>."
  - "The @segments and @cascade lists are multi-line ~w sigils. The final nine-name list would exceed the line length on one line."
  - "The browser-lane gate is the invariant (exactly the known 8 screenshot failures, 326 passed / 16 skipped, baselines untouched), not the plan's literal '82 passed'. That literal dates from the old six-spec lane, and verify.example_browser now runs 350 tests."

patterns-established:
  - "Order-bearing resources get their own reader keyed to the compiled order list; SourceFamily (alphabetical) stays for presence/absence pins"
  - "Per-segment @external_resource is asserted through Style.__info__(:attributes), not just present in source"

requirements-completed: [STRUCT-02, STRUCT-03]

coverage:
  - id: D1
    description: "Stylesheet rendered from nine ordered compile-time .css segments, byte-identical to the golden at every commit"
    requirement: STRUCT-02
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/style_byte_lock_test.exs (golden + both sha256 pins, run after all 11 commits)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser: 326 passed / 8 failed (known 8) / 16 skipped after every commit"
        status: pass
    human_judgment: false
  - id: D2
    description: "Segment integrity guards: cascade order, existence/uniqueness, no orphan, per-segment external resource, no wildcard, source reader equals rendered cascade"
    requirement: STRUCT-02
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/style_byte_lock_test.exs#source reader follows the rendered cascade / segments are the cascade / no orphan css / every segment is an external resource"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every style source reader repointed to Threadline.Test.StyleSource; indentation literals moved to rendered indentation"
    requirement: STRUCT-02
    verification:
      - kind: unit
        ref: "style_contract_test, brandbook_token_parity_test, component_contract_test, stress_router_test (156 tests in the ZOC set, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Hex archive contains all nine segments; planning-vocabulary scan covers style/*.css"
    requirement: STRUCT-02
    verification:
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs#built Hex archive excludes repository evidence"
        status: pass
      - kind: unit
        ref: "test/threadline/operator_surface/rendered_output_contract_test.exs#tracked render-capable source inventory stays explicit and non-empty"
        status: pass
    human_judgment: false
  - id: D5
    description: "Size gate carries no style entry; every segment and style.ex under 800 lines"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D6
    description: "e2e comments and DESIGN-SYSTEM.md cite segment files instead of style.ex line numbers"
    verification:
      - kind: other
        ref: "grep -rn 'style\\.ex:[0-9]' examples/threadline_phoenix/e2e/tests DESIGN-SYSTEM.md -> 0 hits; DESIGN-SYSTEM doc-contract tests 129/0"
        status: pass
    human_judgment: false

duration: 2h 8m
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 03: style.ex Split into Nine Compile-Time CSS Segments Summary

**The 4,509-line `style.ex` heredoc is now a 56-line module that compiles nine ordered `.css` segments (317–685 lines each) into one `Phoenix.HTML.raw` stylesheet. The rendered bytes matched the golden at every one of the 11 commits.**

## Performance

- **Duration:** about 2h 8m. Most of it was ten 9-minute browser-lane runs plus one diagnostic re-run.
- **Started:** 2026-09-23T17:41:50Z
- **Completed:** 2026-09-23T19:50:20Z
- **Tasks:** 3
- **Files modified:** 24

## Accomplishments

- **Pivot (tracer):** `style/stylesheet.css` was written from the golden fixture's bytes (between `<style>` and `</style>`), not from source lines. `style.ex` now builds `@stylesheet` at compile time from an explicit `@segments` list, with one `@external_resource` per segment. It renders `{@fonts_html}{@stylesheet}`, both through `raw`. The first compile was byte-identical, with no join-newline adjustment.
- **Eight tail-first peels plus the rename**, one commit each. Every cut was re-verified by a comment- and string-aware brace-depth scan (`/tmp/p204-03-depth.py`): each sits at depth 0, after a blank line, and final depth stays 0. The cut lines matched RESEARCH exactly (318, 674, 1099, 1706, 2125, 2779, 3285, 3970). The segment sizes match the D-03 table exactly: 317 / 356 / 425 / 607 / 419 / 654 / 506 / 685 / 511. `/* End Find cluster primitives */` sits verbatim in `07_find_detail.css` (D-06).
- **`Threadline.Test.StyleSource`** is the one reader for the stylesheet. The order comes only from `Style.segments/0`, with no wildcard and no sort. The byte-lock suite proves that the reader's CSS, wrapped the way `style.ex` wraps it, equals the golden bytes.
- **Guards:** segment order, existence/uniqueness/non-empty, no orphan `.css`, every segment is an external resource (via `Style.__info__(:attributes)`), and no `Path.wildcard` in `style.ex`. The Hex archive is asserted to contain all nine files, and the planning-attribute scan covers `style/*.css`.
- **Size gate:** the `style.ex` file exception and the `{style.ex, :css, 1}` function exception are gone. The transient `stylesheet.css` pin fell 4480 → 3969 → 3284 → 2778 → 2124 → 1705 → 1098 and was deleted at peel 03, when the remainder reached 673 lines.

## Task Commits

1. **Task 1: pivot the stylesheet into one compile-time `.css` file**: `efbac2cd` (refactor)
2. **Task 2: peel eight segments tail-first, then rename:**
   - `864232ec` peel 09_responsive
   - `4a3218c2` peel 08_overlays_motion
   - `3218480c` peel 07_find_detail
   - `ee11688d` peel 06_layout_primitives
   - `e6497059` peel 05_feedback
   - `42caa480` peel 04_controls
   - `2a11b1d3` peel 03_page_home
   - `093d10c9` peel 02_base_shell
   - `fe3dfc5e` name the stylesheet remainder 01_tokens.css (`git mv`; `git log --follow` tracks 11 commits)
3. **Task 3: refresh stale style.ex citations**: `0d1a132e` (docs)

## ZOC Evidence (after every commit)

Step 1 (`mix compile --force --warnings-as-errors`) and step 2 (the seven ZOC test files plus `release_artifact_contract_test`, **156 tests, 0 failures**) passed after all 11 commits. Step 2 includes the "source reader follows the rendered cascade" case and the order-sensitive slicers in `style_contract_test`.

Step 3, browser lane (`mix verify.example_browser`). After each run, `test/fixtures/operator_surface/scorecards` was restored (see Issues).

| Commit | Result |
|---|---|
| pivot `efbac2cd` | 326 passed / 8 failed (known 8) / 16 skipped, baselines clean |
| peel 09 `864232ec` | 326 / 8 known / 16, clean |
| peel 08 `4a3218c2` | 326 / 8 known / 16, clean |
| peel 07 `3218480c` | 326 / 8 known / 16, clean |
| peel 06 `ee11688d` | 326 / 8 known / 16, clean |
| peel 05 `e6497059` | run 1: 325 / **9** / 16. The extra failure was `[desktop-chromium] operator-coverage-readiness.spec.ts:119 tablet`, `Tearing down "context" exceeded the test timeout of 120000ms` (a 5.2 min hang, no assertion). Run 2 on the same commit with nothing changed: 326 / 8 known / 16, clean |
| peel 04 `42caa480` | 326 / 8 known / 16, clean |
| peel 03 `2a11b1d3` | 326 / 8 known / 16, clean |
| peel 02 `093d10c9` | 326 / 8 known / 16, clean |
| rename `fe3dfc5e` | 326 / 8 known / 16, clean |
| docs `0d1a132e` | 326 / 8 known / 16, clean |

The known 8 are `operator-screenshot-regression.spec.ts` :108, :115, :136 and :145, each on desktop-chromium and mobile-chromium. The set was identical in every passing run.

Plan-level verification: full `mix test` gave **1768 tests, 0 failures, 1 excluded**. `MIX_ENV=test mix verify.compile_no_optional` exited 0. `MIX_ENV=dev mix verify.dialyzer` reported 0 errors (no PLT rebuild needed). `mix credo --strict` found no issues, and `mix format --check-formatted` exited 0.

## Indentation Literals Changed (style_contract_test.exs)

Source indentation (8 or 10 spaces) became rendered indentation (2 or 4 spaces). What each assertion checks did not change:

- `:973` `".threadline-ui .tl-shell-nav__item--active,\n        .threadline-ui …"` → `"\n  .threadline-ui …"`
- `:1014` `".tl-table--compact th,\n        .tl-table--compact td"` → `"\n  .tl-table--compact td"`
- `:1020` `".tl-table--compact .tl-table__code,\n        .tl-table--compact code"` → `"\n  .tl-table--compact code"`
- `:1356` `".tl-table {\n          background: …"` → `".tl-table {\n    background: …"`

Each rewritten literal was confirmed to occur in the rendered CSS.

## Remaining `"lib/threadline/operator_surface/style.ex"` Hits in test/ (intentional)

- `test/support/style_source.ex:17`: `read!/0` appends the module text after the CSS.
- `test/threadline/operator_surface/style_byte_lock_test.exs:37`: the no-`Path.wildcard` refutation reads the module itself.
- `test/threadline/operator_surface/rendered_output_contract_test.exs:187, :423`: the planning-attribute inventory lists the module file alongside `style/*.css`.

## Decisions Made

See `key-decisions` in the frontmatter. In short: the `<style>` tags live in Elixir, the segment lists are multi-line, and the browser gate measures the known-8 invariant rather than the stale "82 passed" literal.

## Deviations from Plan

**1. [Rule 3 - Blocking] The browser-lane gate literal "82 passed" is stale.**
- **Found during:** Task 1 ZOC step 3.
- **Issue:** The plan's grep requires `82 passed`, a count from the old six-spec lane. `verify.example_browser` now runs 350 tests, and the healthy result is 326 passed / 8 failed / 16 skipped. The literal grep fails on a healthy lane.
- **Fix:** The gate now checks the invariant the HALT clause describes (`/tmp/p204-03-browser-check.sh`): failed == 8, the failing set equals exactly the known 8 screenshot cases, passed == 326, skipped == 16, and the baseline PNG directory is clean. I applied it identically after every commit.
- **Files modified:** none in the repository.

**2. [Rule 3 - Blocking] Task 3's verify command passes a `.css` fixture to `mix test`.**
- **Found during:** Task 3 verify.
- **Issue:** `grep -rln 'DESIGN-SYSTEM.md' test` also matches `test/fixtures/style/operator_surface.css`, and `mix test` then tries to compile it.
- **Fix:** I ran the same command filtered to `.exs`: guide_graph, critic_trust, stress_ledger, public_surface, release_artifact, and the byte lock. Result: 129 tests, 0 failures.

**3. [Rule 1 - Consistency] More citations refreshed than the plan listed.**
- Citations without line numbers (`(style.ex's`, `(style.ex):`, `style.ex >=768px`) now name the segment too, so no e2e comment points at a file that no longer holds CSS. They are still comments only, and every file keeps its line count, so the known-8 line keys (:108/:115/:136/:145) are unchanged.

**Total deviations:** 3 (2 blocking verify-command fixes, 1 consistency). **Impact:** none on rendered output. The gates are equivalent or stricter.

## Issues Encountered

- **Tier A capture rewrites tracked scorecard fixtures.** Each `verify.example_browser` run modified about 84 files under `test/fixtures/operator_surface/scorecards/`. The values depend on timing, for example a focus ring captured mid-transition (`rgba(…0.4) 2.8686px` vs `0.404 2.89164px`) and `scroll_cost` 33.303 vs 40.29. These files were clean at plan start. I restored that directory after every run (`git checkout -- test/fixtures/operator_surface/scorecards`) and never staged them. Worth knowing for any phase that runs the lane locally.
- **One flaky context teardown** at peel 05 (see the ZOC table). It did not reproduce on an unchanged re-run, and the byte lock proves the CSS was identical.
- **Broken-windows ledger not appended.** `.planning/WINDOWS.md` is a protected path for this dispatch, so the two stale-verify-command deviations above are recorded here only.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- STRUCT-02 is complete. The size gate no longer carries any style exception.
- Later extraction plans can reuse the StyleSource pattern for any order-bearing resource, and SourceFamily stays for presence pins.
- Future plans should update their browser-gate literal to the known-8 invariant (326 / 8 / 16 today).

---
*Phase: 204-structure*
*Completed: 2026-09-23*

## Self-Check: PASSED

- All 10 created files (nine segments + `test/support/style_source.ex`) and `style.ex` exist.
- All 11 commit hashes resolve (`git cat-file -e`).
- The ledger count (`git rev-list --count 500fe905..HEAD`) is 11, matching `actuals.commits`.
- No `Phase \d` / `STRUCT-0x` / `D-NN` text in `lib/threadline/operator_surface/style/`, `style.ex`, or `style_source.ex`.
