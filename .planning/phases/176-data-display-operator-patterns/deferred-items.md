# Phase 176 — Deferred Items (out-of-scope discoveries)

| Found in | Item | Why deferred |
|----------|------|--------------|
| 176-01 | `test/threadline/operator_surface/ui_test.exs` is not `mix format`-clean (pre-existing, last touched in 174-05). | Out of scope for plan 176-01 (touches only presentation/icon + Wave-0 tests). `mix verify.format` fails on this file independent of this plan's changes. A later 176 plan that edits `ui_test.exs` (it adds the `ref`/`kv`/`data_table` describes) should reformat it in the same commit. |
