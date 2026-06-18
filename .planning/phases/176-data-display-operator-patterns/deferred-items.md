# Phase 176 — Deferred Items (out-of-scope discoveries)

| Found in | Item | Why deferred |
|----------|------|--------------|
| 176-01 | `test/threadline/operator_surface/ui_test.exs` is not `mix format`-clean (pre-existing, last touched in 174-05). | Out of scope for plan 176-01 (touches only presentation/icon + Wave-0 tests). `mix verify.format` fails on this file independent of this plan's changes. A later 176 plan that edits `ui_test.exs` (it adds the `ref`/`kv`/`data_table` describes) should reformat it in the same commit. |
| 176-03 | `card_nesting_regression_test.exs` is RED on `/audit/coverage` (`tl-card--metric` tiles nested inside the synthetic `tl-coverage-command` shell — D-12 flatten violation). | Out of scope for plan 176-03. This plan's invariants explicitly forbid touching `coverage_live.ex` (the coverage flatten is plan 04/05). The card-nesting RED scaffold stays RED until the coverage-flatten plan lands `UI.page_header` + demotes the command shell. The failure is coverage-only and unrelated to the display pages this plan migrated. |
