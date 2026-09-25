---
phase: 204-structure
plan: 15
subsystem: quality-gates
tags: [credo, contract-test, structural-register, source-size, phase-end-proof]
status: complete

requires:
  - phase: 204-structure
    provides: "lib-side register drained to 12 test-side sites; size gate at one file exception (204-01..204-14)"
provides:
  - "credo_config_contract_test: @register %{}, @ceiling 0, @historical_max 46; subset-tolerant register shape; empty-register self-test"
  - "source_size_contract_test: at-rest test pinning exactly one named exception (stress_fixtures.ex), empty function and banner maps"
  - "Zero per-site Refactor.Nesting / Refactor.CyclomaticComplexity disables and zero `# Structural debt:` comments in lib/ and test/"
  - "Recorded phase-end gate table (ci.all, browser lane, bump rehearsal, dialyzer, xref cycles, compile_no_optional, format)"
affects: [STRUCT-07, STRUCT-03, STRUCT-04, phase-204-verification]

actuals:
  tokens: 6718      # chars/4 over the realized diff 11177c9d..0140b132
  tasks: 3
  commits: 10       # MEASURED: git rev-list --count 11177c9d..HEAD before the SUMMARY commit
plan_head_before: 11177c9dc119a9295a9879f0d79aa8a67c345875

tech-stack:
  added: []
  patterns:
    - "Flatten contract-test nesting by extracting a multi-clause defp (pattern match on the reduce/case subject) rather than rewriting the assertion"
    - "Register validation reads Map.get(register, check, {0, successor}), so an empty register is a valid register"

key-files:
  created: []
  modified:
    - test/threadline/credo_config_contract_test.exs
    - test/threadline/dialyzer_ignore_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/guide_graph_contract_test.exs
    - test/support/getting_started_fixtures.ex
    - test/threadline/operator_surface/card_nesting_regression_test.exs
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
    - test/threadline/source_size_contract_test.exs

key-decisions:
  - "The register reached 0 by real fixes only. There were 12 sites (11 Nesting, 1 CyclomaticComplexity), all fixed, none re-registered. The D-13 fallback was not used."
  - "validate_register_shape!/2 now accepts any subset of the two registered checks and still rejects any other key. Its message still contains 'exactly', so the extra-check self-test is unchanged."
  - "The operator_surface_fixture_contract_test site annotated 'refute class case' was actually reported by Credo on the `if Enum.all?(… fn …)` line. Both were extracted (refute_references/1 and named_references/1) so the file is clean under mix credo --strict."
  - "getting_started_fixtures extract!/2 was split into seven helpers. finish!/3 first measured complexity 10, so the snippet check became non_empty_snippet!/3. Raise order and messages are unchanged, and 32 tests across the four consumers pass."

requirements-completed: [STRUCT-07, STRUCT-03, STRUCT-04]

duration: 20min
completed: 2026-09-24
---

# Phase 204 Plan 15: Structural register drained to zero Summary

**All 12 remaining test-side Credo structural suppressions were fixed with extracted multi-clause helpers. The structural register is now `%{}` with a ceiling of 0, the size gate is pinned at rest to one named exception (`stress_fixtures.ex`), and every phase-end gate is green.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-09-24T03:22:43Z
- **Completed:** 2026-09-24T03:42:24Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- The register gate can represent a drained register. A missing key counts as 0. The exact-equality self-test uses a local `register_with(2, 1)`. A new self-test proves that `%{}` accepts a clean tree and rejects one annotated Nesting disable with `Credo.Check.Refactor.Nesting: scanned 1`, and that a single-key register is valid.
- All 12 sites were drained, one commit per file, with `@register` and `@ceiling` lowered in the same commit: 12 → 11 → 10 → 9 → 7 → 6 → 3 → 0. The register was then pinned at `%{}`.
- The moduledoc now says the register is drained, that any new disable fails until it is registered in review with an exact count and a named successor, and that a missing check counts as 0.
- The size gate has a new at-rest test: `Map.keys(@file_exceptions) == ["lib/threadline/operator_surface/stress_fixtures.ex"]`, `@function_exceptions == %{}`, `@banner_exceptions == %{}`, with "needs a named reason in review" failure messages.

## Extracted helpers (per file)

| File | Sites | Helpers |
|---|---:|---|
| dialyzer_ignore_contract_test.exs | 1 N | `make_warning_irreducible/2` (multi-clause match on id) |
| release_artifact_contract_test.exs | 1 N | `put_readable/3` (multi-clause on `File.read` result) |
| guide_graph_contract_test.exs | 1 N | `next_step_targets/2` |
| test/support/getting_started_fixtures.ex | 1 N + 1 CC | `resolve_path/1`, `scan_line/3`, `start_marker/3`, `end_marker/3`, `interior_line/2`, `finish!/3`, `non_empty_snippet!/3` |
| card_nesting_regression_test.exs | 1 N | `walk_token/2` |
| rendered_output_contract_test.exs | 3 N | `validate_exception_step/2`, `scan_line_vocabulary/2`, `scan_line_attributes/2` |
| operator_surface_fixture_contract_test.exs | 3 N | `load_scorecard/3`, `unreferenced_cell/2`, `broken_reference/1`, `refute_references/1`, `named_references/1` |

No assertion, failure message, or scanned set changed. Each file ran green after its own commit.

## Task Commits

1. **Task 1 (tracer): empty register valid**: `243bc5e6` (test)
2. **Task 1: dialyzer_ignore site**: `386ea6a8` (refactor)
3. **Task 2: release_artifact site**: `3585bb36` (refactor)
4. **Task 2: guide_graph site**: `3511d90d` (refactor)
5. **Task 2: getting_started_fixtures sites**: `77212e86` (refactor)
6. **Task 2: card_nesting_regression site**: `2fbabed5` (refactor)
7. **Task 2: rendered_output_contract sites**: `634936f0` (refactor)
8. **Task 2: operator_surface_fixture_contract sites**: `e0e3e472` (refactor)
9. **Task 2: pin register at zero**: `076ce142` (test)
10. **Task 2: size gate at rest**: `0140b132` (test)
11. **Task 3: phase-end proof**: no code change (measurements only; nothing stale found)

## Phase-end gate table (Task 3)

| Gate | Command | Exit | Summary line | Duration |
|---|---|---:|---|---:|
| format | `mix verify.format` | 0 | clean | <1s |
| ci.all | `DB_PORT=5433 MIX_ENV=test mix ci.all` | 0 | `1778 tests, 0 failures, 1 excluded`; `117 tests, 0 failures`; Dialyzer `done (passed successfully)`; example Playwright `318 passed, 26 skipped` | 383s |
| browser lane | `mix verify.example_browser` | 1 (expected) | `326 passed / 8 failed / 16 skipped`; the 8 failures are exactly operator-screenshot-regression.spec.ts :108, :115, :136, :145 × desktop + mobile; baseline snapshots dir clean | 443s |
| bump rehearsal | `mix verify.bump_rehearsal` | 0 | `Bump rehearsal OK: a 0.9.0 -> 0.10.0 release commit passes every doc-contract test` | 64s |
| dialyzer | `MIX_ENV=dev mix verify.dialyzer` | 0 | `done (passed successfully)` | 2s |
| xref cycles | `mix verify.xref_cycles` | 0 | `No cycles found` | <1s |
| no-optional compile | `MIX_ENV=test mix verify.compile_no_optional` | 0 | compiled 138 files, no warnings | 2s |
| full credo | `mix credo --strict` | 0 | `3467 mods/funs, found no issues` (315 files) | <1s |
| Elixir 1.15 minimum lane | CI only | pending CI | n/a | n/a |

The full suite went from 1776 to 1778 tests: the new empty-register self-test and the new at-rest size test. The browser lane gates on the 326/8/16 invariant rather than the plan's stale "82 passed" literal, as the orchestrator directed. `test/fixtures/operator_surface/scorecards/` was restored after the browser run and was not staged.

## Byte lock and golden

- `test/fixtures/style/operator_surface.css` has exactly one commit in its history (`ef458852`, 204-01). sha256 is `c7baf51ecd9b4465675ea12a67218974157616ea8e8937e71aa166ca8154ab4b`, which equals `@golden_sha256`.
- `@golden_sha256` and `@rendered_sha256` in style_byte_lock_test.exs are byte-identical to 204-01 (`c7baf51e…`, `b10d6a2c…`). The byte lock test is green inside ci.all.

## Line counts: files with an exception at 204-01

| File | 204-01 | Now |
|---|---:|---:|
| lib/threadline/operator_surface/style.ex | 4509 | 56 (CSS moved to 9 `style/*.css` files, max 685) |
| lib/threadline/operator_surface/ui.ex | 1686 | split (file removed) |
| lib/threadline/operator_surface/live/timeline_live.ex | 1399 | 608 |
| lib/threadline/operator_surface/live/stress_live.ex | 1398 | 224 |
| lib/threadline/operator_surface/stress_fixtures.ex | 980 | 980 (the one named exception) |
| lib/threadline/operator_surface/mechanical_checker.ex | 948 | 178 |
| lib/threadline/query.ex | 895 | 745 |

## Acceptance checks

- `grep -c 'Map.fetch!(@register' credo_config_contract_test.exs` → 0
- `grep -rln 'Structural debt:' lib test` returns only credo_config_contract_test.exs, where the text appears only in its moduledoc, the `@debt_prefix` attribute, and synthetic string literals.
- `grep -rnE 'credo:disable-for-next-line Credo\.Check\.Refactor\.(Nesting|CyclomaticComplexity)' lib test` → no output. The contract test assembles its synthetic disables from `@comment_head`, so the literal never appears.
- `grep -c '@historical_max 46'` → 1. `grep -c 'stress_fixtures.ex' source_size_contract_test.exs` → 3.
- `.credo.exs` and `mix.exs` are unchanged since the plan base, so Credo's defaults `max_nesting 2` and `max_complexity 9` are untouched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Mislabelled structural-debt site in operator_surface_fixture_contract_test**
- **Found during:** Task 2
- **Issue:** The third site's comment named the refute-class `case`, but Credo reported the nesting on the `if Enum.all?(references, fn … end)` line that the disable actually covered.
- **Fix:** Extracted both `refute_references/1` and `named_references/1`.
- **Commit:** `e0e3e472`

**2. [Rule 3 - Blocking] finish!/3 measured cyclomatic complexity 10 after the first split**
- **Found during:** Task 2 (getting_started_fixtures)
- **Fix:** Moved the empty-snippet check into `non_empty_snippet!/3`.
- **Commit:** `77212e86`

**3. Browser lane literal.** The plan's verify greps for "82 passed". Per the orchestrator note and the project rules, the gate was the 326/8/16 invariant with exactly the known eight failures. It held on the first run, so no re-run was needed.

None of the HALT conditions fired. No site was re-registered, no threshold changed, no baseline was regenerated, and no hooks were bypassed.

## Known Stubs

None.

## Self-Check: PASSED

- All 9 modified files exist, and all 10 task commits are present in `git log`.
