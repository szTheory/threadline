# Phase 176 — Deferred Items (out-of-scope discoveries)

## 176-01: `ui_test.exs` not format-clean

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27
- **Item:** `test/threadline/operator_surface/ui_test.exs` is not `mix format`-clean (pre-existing, last touched in 174-05).
- **Why deferred:** Out of scope for plan 176-01 (touches only presentation/icon + Wave-0 tests). `mix verify.format` fails on this file independent of this plan's changes. A later 176 plan that edits `ui_test.exs` (it adds the `ref`/`kv`/`data_table` describes) should reformat it in the same commit.

## 176-03: `card_nesting_regression_test.exs` RED on `/audit/coverage`

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27
- **Item:** `card_nesting_regression_test.exs` is RED on `/audit/coverage` (`tl-card--metric` tiles nested inside the synthetic `tl-coverage-command` shell — D-12 flatten violation).
- **Why deferred:** Out of scope for plan 176-03. This plan's invariants explicitly forbid touching `coverage_live.ex` (the coverage flatten is plan 04/05). The card-nesting RED scaffold stays RED until the coverage-flatten plan lands `UI.page_header` + demotes the command shell. The failure is coverage-only and unrelated to the display pages this plan migrated.

## 176-03: `row_history_live_test.exs` / `ui_stress_test.exs` not format-clean

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27
- **Item:** `test/threadline/operator_surface/live/row_history_live_test.exs` and `test/threadline/operator_surface/ui_stress_test.exs` are not `mix format`-clean (pre-existing; not touched by this plan).
- **Why deferred:** Out of scope for plan 176-03 (`files_modified` does not include them). `mix verify.format` fails on these independent of this plan's changes; every file this plan edited is format-clean. The later 176 plan that edits either file should reformat it in the same commit.
