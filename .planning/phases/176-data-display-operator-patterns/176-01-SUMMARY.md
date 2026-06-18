---
phase: 176-data-display-operator-patterns
plan: 01
subsystem: operator-surface
tags: [presentation, ref, truncation, icons, data-state, wave-0, red-green, forensic, security]

# Dependency graph
requires: []
provides:
  - "Presentation.ref/2 → %{visible, title, full} where full == the exact complete value (reuses secondary_ref_value/1 extraction); the forensic primitive every downstream copy affordance depends on"
  - "Presentation.truncate_middle/3 with :tail_min guaranteeing >= N trailing chars of the original survive verbatim; default split byte-for-byte unchanged (export_summary backward-compat)"
  - "Per-kind truncate_for/2 (uuid/correlation/arn/actor/hash/path/email/url/timestamp); :timestamp never truncates"
  - "Presentation.value_token/1 truncation at 56 keeping the full value in :title (shape %{text, modifier, title} preserved)"
  - "Icon glyphs eye_off (redacted), funnel (no-data), lock (permission), cloud_off (source-down); archive reused for pruned"
  - "Four RED Wave-0 tests binding Phase 176 requirements: card-nesting regression (D-12), typed-reason→state mapping (D-16), T3 fail-closed+audit (D-21), ref-copy-equals-full (Pitfall 4)"
  - "Threadline.OperatorSurface.RefCopyContract shared test helper (assert_copy_equals_full / refute_copy_truncated) reusable across every consuming LiveView test"
affects:
  - "176-02/03 (UI.data_state + empty_state variants) turn the data-state mapping test GREEN"
  - "176-03 (coverage flatten) turns the card-nesting regression GREEN"
  - "176-05 (T3 server enforcement + UI.ref adoption) turns the retention T3 + ref-copy tests GREEN"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ref/2 layers a third face (full) over the existing secondary_ref shape and reuses secondary_ref_value/1 — value extraction is never rebuilt (D-01)"
    - ":tail_min is a keyword on a 3rd arg; absent → identical to today's split, so export_summary/1's truncate_middle(correlation, 28) is unchanged"
    - "Wave-0 tests parse rendered HTML with zero new deps: a self-contained tag-stack tokenizer (card-nesting) and regex extractors (copy targets, icon-path signatures) — no Floki/LazyHTML (v1.37 zero-new-dep invariant)"
    - "Card-family SURFACE detection treats tl-card block/modifier AND the synthetic tl-coverage-command shell as boundaries but excludes BEM __element classes"

key-files:
  created:
    - .planning/phases/176-data-display-operator-patterns/176-01-SUMMARY.md
    - test/threadline/operator_surface/card_nesting_regression_test.exs
    - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
    - test/support/ref_copy_contract.ex
    - .planning/phases/176-data-display-operator-patterns/deferred-items.md
  modified:
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/operator_surface/components/icon.ex
    - test/threadline/operator_surface/presentation_test.exs
    - test/threadline/operator_surface/live/retention_history_live_test.exs

key-decisions:
  - "[176-01]: ref/2 reuses the existing secondary_ref_value/1 dispatch for `full`; value extraction is not rebuilt (D-01). title == full; visible is per-kind truncation."
  - "[176-01]: :tail_min is additive — head keeps today's default split, tail grows to max(default, tail_min); the no-:tail_min path is byte-for-byte unchanged so export_summary/1 is unaffected (D-03)."
  - "[176-01]: source-down glyph is :cloud_off (reads as 'source unreachable'); :plug not added. archive reused for pruned per D-15."
  - "[176-01]: Wave-0 HTML assertions use a self-contained tokenizer/regex (no Floki — not a project dep; v1.37 zero-new-dep invariant). RefCopyContract lives in test/support (only test/support is on the compile path)."
  - "[176-01]: card-nesting regression treats the synthetic tl-coverage-command shell as a card-family surface (the D-12 flatten target) so the test is genuinely RED on coverage today; literal card>card alone would be a false-green scaffold."

# Metrics
metrics:
  duration: ~30m
  tasks: 3
  files_created: 5
  files_modified: 4
  completed: 2026-06-18
---

# Phase 176 Plan 01: Presentation core + icon contracts + Wave-0 test scaffolds Summary

Established the deterministic forensic primitive (`Presentation.ref/2` returning `%{visible, title, full}` with `full` == the exact complete value, plus tail-safe `:tail_min` middle truncation and per-kind rules), added the four missing data-state icon glyphs, and authored the four MISSING Wave-0 tests that start RED and turn GREEN as Phase 176 proceeds.

## What was built

### Task 1 — Presentation core (TDD: RED `989f03c` → GREEN `45a788d`)
- `truncate_middle/3` gains `:tail_min`: when set, at least N trailing chars of the original value survive verbatim (the forensic discriminating tail). The default (no `:tail_min`) path is byte-for-byte unchanged, so `export_summary/1`'s `truncate_middle(correlation, 28)` is unaffected.
- `ref/2` returns `%{visible, title, full}`; `full = secondary_ref_value(value)` (reusing the existing dispatch for `%ActorRef{}`, `%{"type","id"}`, JSON maps, `to_string`), `title = full`, `visible = truncate_for(value, opts)`.
- `truncate_for/2` routes per `:kind` — uuid/correlation (middle ~34, tail≥8), arn/actor (tail-weighted, tail≥12), hash (~24), path (filename tail ~42), email (keep full domain), url (host head + last segment tail), timestamp (never truncated).
- `value_token/1` now truncates strings/JSON at 56 chars keeping the full value in `:title`, preserving the `%{text, modifier, title}` shape.

### Task 2 — Icons (`a4a13fa`)
- Added inline pure-path clauses `:eye_off` (redacted), `:funnel` (no-data), `:lock` (permission), `:cloud_off` (source-down) in alpha order; `:archive` reused for pruned. `mix compile --warnings-as-errors` clean.

### Task 3 — Four RED Wave-0 tests (`3503fdc`)
- **card_nesting_regression_test.exs** — references all 11 operator surface modules; renders the reachable pages and refutes a card-family surface nested under another. RED on `/audit/coverage` (the `tl-card--metric` tiles inside the synthetic `tl-coverage-command` shell — the D-12 flatten target).
- **data_state_mapping_wave0_test.exs** — asserts `UI.data_state/1` maps each typed reason (`:unauthorized`/`:source_down`/`:redacted`/`:pruned`/`:no_data`/other) to a distinct role + icon shape + heading and that unavailable states state "not a permissions issue". RED (no `data_state/1`, no `empty_state` variants).
- **retention_history_live_test.exs** (extended) — T3 fail-closed: forged token, forged scope, authz-absent, and a valid type-to-confirm prune recording an `AuditAction`. RED (handler has no secure_compare/authz/audit; no `phx-submit` form).
- **RefCopyContract** (test/support) + a retention copy-equals-full assertion — RED until `UI.ref/1` adoption.

## Verification

- `mix test test/threadline/operator_surface/presentation_test.exs` → 35 tests, 0 failures (Task 1 GREEN).
- `mix compile --warnings-as-errors` clean (Task 2).
- The three Wave-0 files compile and run; 9 new behavioral assertions are RED against current code (3 data-state + 1 card-nesting + 5 retention/ref-copy), all pre-existing retention tests still pass → the scaffolds bind real requirements, not tautologies.
- `mix format --check-formatted` clean on all files this plan touched.
- Capture & semantics layers untouched — this plan edits only `presentation.ex`, `icon.ex`, and test files (exploration layer only).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] No HTML parser dependency available for the Wave-0 render assertions**
- **Found during:** Task 3 (card-nesting test initially used `Floki.parse_fragment!`).
- **Issue:** Floki is not a project dependency, and the v1.37 invariant forbids adding one (package installs are also excluded from auto-fix).
- **Fix:** Replaced parser usage with a self-contained tag-stack tokenizer (card-nesting) and regex extractors (copy targets, icon-path signatures). Zero new deps.
- **Files modified:** test/threadline/operator_surface/card_nesting_regression_test.exs, test/support/ref_copy_contract.ex
- **Commit:** 3503fdc

**2. [Rule 3 - Blocking] Router macro cannot escape inline anonymous auth functions; shared helper must be on the compile path**
- **Found during:** Task 3.
- **Issue:** `threadline_operator_surface(..., authorize_fn: fn _ -> true end)` raised `cannot escape #Function`. Separately, `ref_copy_contract.ex` placed under `test/threadline/...` would not be compiled (only `lib` + `test/support` are on `elixirc_paths(:test)`).
- **Fix:** Added a named `Auth` module with `&Auth.authorize/1` (mirrors the existing per-page test harnesses) and moved the helper to `test/support/ref_copy_contract.ex`.
- **Commit:** 3503fdc

**3. [Scope boundary] Card-nesting detection widened beyond literal `tl-card`-under-`tl-card`**
- The coverage defect is "NOT literal card>card" (PATTERNS.md): the success branch nests `tl-card--metric` tiles inside the synthetic `tl-coverage-command` command shell. Treating that shell as a card-family surface makes the regression genuinely RED today (a literal-only check would be a false-green scaffold). BEM `__element` classes are excluded so the kept `tl-card--metric` tiles do not self-trigger.

## Deferred Issues (out of scope)

- `test/threadline/operator_surface/ui_test.exs` is not `mix format`-clean (pre-existing; last touched in 174-05). `mix verify.format` fails on this file independent of this plan. Logged to `deferred-items.md`; the later 176 plan that edits `ui_test.exs` (adding the `ref`/`kv`/`data_table` describes) should reformat it in the same commit. Not touched here per the scope boundary.

## Known Stubs

None — this plan deliberately ships RED Wave-0 test scaffolds (documented in each module's `@moduledoc`/comments as "Wave-0 RED until Plan 02/03/05"), not production stubs. The intentionally-RED tests are the gate that blocks merge until the downstream waves implement the behavior.

## TDD Gate Compliance

Task 1 followed RED→GREEN: `test(176-01)` `989f03c` (failing) → `feat(176-01)` `45a788d` (passing). Tasks 2 and 3 are non-TDD (`type="auto"`): Task 3 deliberately authors RED scaffolds that must stay RED this wave.

## Commits

- `989f03c` test(176-01): add failing Presentation ref/2 + tail-min + value_token tests
- `45a788d` feat(176-01): Presentation ref/2 three faces + tail-safe truncation
- `a4a13fa` feat(176-01): add data-state icons (eye_off, funnel, lock, cloud_off)
- `3503fdc` test(176-01): author four RED Wave-0 tests

## Self-Check: PASSED

All created/modified files exist on disk; all task commits (`989f03c`, `45a788d`, `a4a13fa`, `3503fdc`) and the docs commit (`5c18abf`) are present in git history.
