---
phase: 204-structure
plan: 04
subsystem: operator-surface, query, governance
tags: [refactor, mechanical-checker, hex-packaging, query, credo-register, size-gate, generated-migration]

requires:
  - phase: 204-structure
    provides: "204-01 source size gate and CSS byte lock; 204-02 SourceFamily reader; 204-03 style split (style/01_tokens.css is the token source of truth)"
provides:
  - "MechanicalChecker split into six @moduledoc false siblings: Scorecards, Parsing, Contrast, TokenConformance, RatchetMetrics, AccentHue"
  - "mix.exs exclude pattern ~r{^lib/threadline/operator_surface/mechanical_checker(\\.ex$|/)} plus archive assertions for the prefix and all six sibling paths"
  - "Threadline.Query.Cursors (@moduledoc false): keyset cursor, paging, and actor-history window/trim/edge helpers"
  - "sha256 + byte-size pins for Governance.Migration.migration_content/0 (library default and AuditLog schemas)"
  - "Governance.Migration.migration_content/0 assembled from ordered per-statement helpers"
affects: [204-05, 204-06, 204-07, source-size-gate, credo-register, release-artifact]

actuals:
  tokens: 21335    # chars/4 over the realized diff (moved code counted as removed + added)
  tasks: 3
  commits: 12
plan_head_before: e518e109e6ee4494b405715d6c2ff2a891a884fe

tech-stack:
  added: []
  patterns:
    - "Pinned constants stay in the parent and reach siblings as an argument map built by a private parent function (wcag_thresholds/0, token_scales/0, mode_b_limits/1)"
    - "Pin generated output first (sha256 + byte size), then restructure behind the unchanged pin"
    - "Multi-alias on an existing line so an extraction does not shift recorded line coordinates above it"

key-files:
  created:
    - lib/threadline/operator_surface/mechanical_checker/scorecards.ex
    - lib/threadline/operator_surface/mechanical_checker/parsing.ex
    - lib/threadline/operator_surface/mechanical_checker/contrast.ex
    - lib/threadline/operator_surface/mechanical_checker/token_conformance.ex
    - lib/threadline/operator_surface/mechanical_checker/ratchet_metrics.ex
    - lib/threadline/operator_surface/mechanical_checker/accent_hue.ex
    - lib/threadline/query/cursors.ex
  modified:
    - lib/threadline/operator_surface/mechanical_checker.ex
    - lib/threadline/query.ex
    - lib/threadline/query/filter_params.ex
    - lib/threadline/governance/migration.ex
    - mix.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/credo_config_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/storage_schema_migration_contract_test.exs

key-decisions:
  - "Parsing was carved first, not Scorecards. Scorecards calls parse_color and shadow_signatures, which were private to the parent. Carving Parsing first let every later sibling depend on a real module, not on temporarily public parent functions. The packaging widening landed with Parsing, so it still came with the first sibling."
  - "Only textually pinned constants stay in the parent. @shadow_token_signatures and @ms_tolerance moved to TokenConformance, @px_tolerance to Parsing, and @accent_saturation_floor and @hue_bucket_window to AccentHue. The test does not pin any of these five."
  - "Contrast calls the parent's public relative_luminance/1 and contrast_ratio/2 at runtime, so the gamma-2.4 line has one home. mix xref reports no compile-connected cycle."
  - "The governance 'default' pin is the library default: :storage_schema is unset, which gives \"public\", the value an adopter's install sees with no config. config/test.exs sets \"threadline\", but the pin does not depend on that config. The AuditLog pin covers mixed-case quoting."
  - "validate_timeline_page_size! was renamed timeline_page_size! in Query.Cursors so both call sites keep their two-line shape. Together with the multi-alias `alias Threadline.Query.{Cursors, Scope}`, no line above the moved code shifted. This keeps the recorded Dialyzer coordinates at query.ex :53, :64, :105, and :116 accurate."

patterns-established:
  - "An internal sibling takes pinned constants as arguments, never redeclaring them"
  - "Each new maintainer-only sibling joins @maintainer_only_paths in the commit that creates it"

requirements-completed: [STRUCT-03, STRUCT-04, STRUCT-07]

coverage:
  - id: D1
    description: "MechanicalChecker split into six internal siblings; verify.mechanical green at every commit"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "mix verify.mechanical (test/threadline/operator_surface/mechanical_checker_test.exs, 28 tests) plus refute_partition_test after each of the 7 Task 1 commits"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mechanical checker family absent from the Hex archive"
    requirement: STRUCT-03
    verification:
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs#built Hex archive excludes maintainer-only tooling (prefix + six sibling paths)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Banners removed: mechanical_checker 10 -> 0, query 1 -> 0; size gate banner entries deleted"
    requirement: STRUCT-04
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#separator banners"
        status: pass
    human_judgment: false
  - id: D4
    description: "query.ex 895 -> 745 lines with no public def removed; walkthrough-pinned filter pipeline intact"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "query_test, code_walkthrough_doc_contract_test, exports/timeline_browse doc contracts, public_surface_contract_test, dialyzer_slice_contract_test (232 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Four register sites drained (Nesting 26 -> 25, CyclomaticComplexity 16 -> 13, ceiling 42 -> 38)"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "test/threadline/credo_config_contract_test.exs; mix credo --strict (3307 mods/funs, no issues)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Generated governance migration byte-identical before and after the split"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "test/threadline/storage_schema_migration_contract_test.exs#generated governance migration output is byte-identical to its pins"
        status: pass
    human_judgment: false

duration: 26 min
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 04: MechanicalChecker, Query, and Governance Migration Split Summary

**`mechanical_checker.ex` went from 948 lines to 178, with six internal siblings under a directory-wide Hex exclusion. `query.ex` went from 895 lines to 745 by moving private cursor and paging helpers into `Threadline.Query.Cursors`. The 138-line `migration_content/0` heredoc is now ordered per-statement helpers behind new sha256 pins. Eleven banners and four register sites are gone, and the size gate lost five entries.**

## Performance

- **Duration:** about 26 min
- **Started:** 2026-09-23T19:54:42Z
- **Completed:** 2026-09-23T20:20:30Z
- **Tasks:** 3
- **Files modified:** 17

## Accomplishments

- **MechanicalChecker (tracer):** the parent keeps `run/1`, the `check_scorecard/2` dispatch, public `relative_luminance/1`, `contrast_ratio/2`, and `measure_mode_b/1`, `linearize_channel/1` with its gamma-2.4 line, and every text-pinned constant. The dispatch order is unchanged (`Contrast ++ TokenConformance ++ RatchetMetrics`), so violation lists come out in the same order. Each sibling exposes one entry point (`Contrast.check/2`, `TokenConformance.check/2`, `RatchetMetrics.check/3`, `AccentHue.count/1`), or a small loader surface (`Scorecards.fetch_required_input/2`, `Scorecards.load/1`), or shared helpers (`Parsing`).
- **Packaging:** the `mix.exs` pattern now matches the whole family. `release_artifact_contract_test` asserts that the `mechanical_checker/` prefix and each of the six sibling paths are absent from the built archive. Each path was added in the commit that created its file.
- **Query:** only private helpers moved. The `filter_by_*` pipeline, the three `repo.preload(… storage_opts([], opts))` lines, and `@allowed_timeline_filter_keys` stay in `query.ex`. `git diff base..HEAD -- lib/threadline/query.ex` removes no `def` line.
- **Governance migration:** pinned first (`3c749d67`), then split (`93fb9771`). Both pins passed on the first compile of the split and stayed green. No pin value was ever edited.

## Task Commits

1. **Task 1: MechanicalChecker split (tracer)**
   - `033b429f` Parsing, plus the Hex exclude widening and archive prefix
   - `6988d426` Scorecards (parent 804 -> 511 lines; file exception deleted)
   - `088a92f0` Contrast
   - `b41ffcc5` TokenConformance, draining the Nesting site
   - `f42e8762` RatchetMetrics
   - `6ef3f469` AccentHue
   - `6726459d` remaining banners become prose or are deleted; SSOT comment now names `style/01_tokens.css`
2. **Task 2: Query.Cursors and register drains**
   - `9ef3f7ee` move cursor and paging helpers; delete the `filter_by_*` banner; drop the query.ex file and banner entries
   - `bda60050` drain the `actor_history/2` CyclomaticComplexity site
   - `b49ddd90` drain both FilterParams CyclomaticComplexity sites
3. **Task 3: governance migration**
   - `3c749d67` test: pin the generated governance migration output
   - `93fb9771` refactor: split into ordered parts; drop the `migration_content/0` function exception

## D-11 Banner Dispositions (mechanical_checker.ex, original line numbers)

| Line | Section | Disposition |
|---|---|---|
| :26 | MODE-A locked WCAG constants | Prose comment over pinned attributes (the constants are text-pinned in the parent) |
| :33 | MODE-B far ceilings | Prose comment over pinned attributes |
| :37 | Token scale constants | Prose comment over pinned attributes; the SSOT now names `style/01_tokens.css` |
| :120 | luminance helpers | Deleted: the section is the single clause group `linearize_channel/1` |
| :132 | scorecard loading | Sibling module `MechanicalChecker.Scorecards` |
| :432 | MODE-A WCAG contrast | Sibling module `MechanicalChecker.Contrast` |
| :536 | MODE-A token conformance | Sibling module `MechanicalChecker.TokenConformance` |
| :661 | MODE-B ratchet floors and ceilings | Sibling module `MechanicalChecker.RatchetMetrics`; `measure_mode_b/1` stays public in the parent |
| :743 | distinct-accent-hue | Sibling module `MechanicalChecker.AccentHue` |
| :804 | shared parsing helpers | Sibling module `MechanicalChecker.Parsing` |
| query.ex :840 | private filter pipeline | Deleted: one cohesive `filter_by_*` clause group, which must stay in query.ex because the walkthrough pins it |

## Register Counts (credo_config_contract_test)

| | Before | After |
|---|---|---|
| Nesting | 26 | 25 (TokenConformance spacing check -> `off_scale_spacing/3`) |
| CyclomaticComplexity | 16 | 13 (`actor_history/2`, `filters_raw_from_params/1`, `collapse_actor_ref/1`) |
| `@ceiling` | 42 | 38 |

## Size Gate Changes (source_size_contract_test)

- File exceptions removed: `mechanical_checker.ex` (948 -> 804, then deleted at 511) and `query.ex` (895, deleted at 782).
- Function exception removed: `{governance/migration.ex, :migration_content, 0}` (138).
- Banner entries removed: `mechanical_checker.ex` (10 -> 9 -> 8 -> 7 -> 6 -> 5 -> 4 -> deleted) and `query.ex` (1 -> deleted).

## Verification

- Every commit ran `mix compile --force --warnings-as-errors`, the size and credo contract tests, the tests that read the touched file, and `mix credo --strict` on the touched files.
- Plan level: full `mix test` gave **1769 tests, 0 failures, 1 excluded**. `mix verify.xref_cycles`: no cycles. `MIX_ENV=test mix verify.compile_no_optional`: exit 0. `MIX_ENV=dev mix verify.dialyzer`: 0 errors (no PLT rebuild). `mix credo --strict` over the whole repo: no issues. `mix format --check-formatted`: exit 0.
- Browser lane not run: no commit in this plan touches rendered code (the checker is maintainer-only, and Query and Governance produce data, not markup). The D-00b rendered-output gates are not in scope here.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

**1. [Rule 3 - Blocking] Carve order: Parsing before Scorecards.**
- **Found during:** Task 1 step (1).
- **Issue:** Scorecards validation calls `parse_color/1` and `shadow_signatures/1`, which were private to the parent. Carving Scorecards first would have meant making parent helpers public for one commit.
- **Fix:** Parsing came first, together with the packaging widening, so the first sibling still carried the exclusion and archive assertions. Scorecards came second.

**2. [Rule 2 - Correctness] The pin failure message has no first differing line.**
- **Issue:** The plan asks the pin failure to report "the first differing line". A sha256 pin has no expected text to diff against, and adding a golden file would be a second artifact the plan did not ask for.
- **Fix:** The failure reports the schema, the pinned and measured byte sizes, both hashes, and where to compare. A separate `byte_size` assertion pins the sizes (`@governance_default_bytes 3377`, `@governance_auditlog_bytes 3407`). It never prints the migration text.

**3. [Rule 1 - Consistency] One recorded Dialyzer coordinate moved.**
- The fixed-warning record at `query.ex` :651 (`audit_changes_for_transaction` spec, `test/fixtures/dialyzer/query-storage.json`) now sits lower, because the actor-history helpers above it moved out. The plan's own move list makes this unavoidable. The record is historical, `dialyzer_slice_contract_test` stays green, and a resurfaced warning would still fail as "unrecorded live warning". Coordinates :53, :64, :105, and :116 are unchanged.

**Total deviations:** 3. **Impact:** none on output, packaging, or public API.

## Issues Encountered

- **Broken-windows ledger not appended.** `.planning/WINDOWS.md` is a protected path for this dispatch. Nothing needed a ledger entry anyway: no stubs, no skipped tests, no unrun verify.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- The size gate now holds file exceptions only for stress_live, timeline_live, stress_fixtures, and ui.ex, and banner entries only for export_controller, coverage_live, start_live, timeline_live, and actor_ref.
- The register has 38 sites left for the drain plans.

---
*Phase: 204-structure*
*Completed: 2026-09-23*

## Self-Check: PASSED

- All seven created files exist, and each sibling has `@moduledoc false`.
- All 12 commit hashes resolve.
- The ledger count (`git rev-list --count e518e109..HEAD`) is 12, matching `actuals.commits`.
- No `Phase \d` / `STRUCT-0x` / `D-NN` / `file:line` text in any new or modified lib file.
