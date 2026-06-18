---
phase: 176-data-display-operator-patterns
plan: 04
subsystem: operator-surface
tags: [data-display, flatten, card-nesting, coverage, page-header, declutter, regression-test, wave-4]

# Dependency graph
requires:
  - "176-02: UI.page_header (with the new :meta slot added here), UI.empty_state, UI.alert — the page chrome the coverage branches consume"
  - "176-03: current style.ex/style_contract_test.exs state (the .tl-secondary-ref ellipsis already removed); coverage/retention/redaction LiveViews were intentionally NOT touched by 03, leaving coverage flatten to this plan"
provides:
  - "Coverage uses UI.page_header in ALL three branches (form-error, empty, success) — the hand-rolled tl-coverage-command header is gone"
  - "UI.page_header gains an optional :meta slot (renders <p class=tl-page__meta>) — backward-compatible, carries coverage last-checked time"
  - "The synthetic tl-coverage-command shell is demoted: trust-rail, tl-summary-grid metric tiles, remediation, table are now direct page-stack siblings (D-11 one card boundary per logical unit)"
  - "Dead tl-coverage-command__* CSS deleted from style.ex (base + tablet) with a paired style_contract refute String.contains?(src, \"tl-coverage-command\") locking the deletion"
  - "Card-nesting regression test GREEN across all 11 operator surfaces — no tl-card* class nests under another tl-card* element (Plan-01 Wave-0 RED → GREEN, DATA-05/D-12)"
affects:
  - "Resolves the coverage-schema-card-declutter carried todo; the last DATA-05 card-nesting Wave-0 scaffold is now GREEN. Remaining 5 RED scaffolds are the retention T3 prune + ref-copy ones owned by plan 05."

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Flatten rule realized: a synthetic command-shell card surface (tl-coverage-command) is replaced by UI.page_header + plain page-stack <section> siblings spaced by the existing --tl-space-* gaps; only genuinely repeated items (tl-card--metric tiles) keep a card boundary"
    - "page_header :meta slot is additive and optional (defaults to []) — every existing page_header call site is unaffected; coverage success branch is the only consumer today"
    - "CSS deletion paired with its contract assertion IN THE SAME TASK (Pitfall 2 / T-176-08): the style_contract base-responsive + tablet assertions that pinned tl-coverage-command* were swapped for a single refute that fails CI on re-introduction"
    - "The card-nesting regression treats tl-coverage-command as a card-family surface (its @surface_prefixes), so flattening the shell is exactly what turns the all-11-pages refutation GREEN; the metric tiles are NOT page sections so they legitimately remain card-family"

key-files:
  created:
    - .planning/phases/176-data-display-operator-patterns/176-04-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/coverage_live.ex
    - lib/threadline/operator_surface/style.ex
    - lib/threadline/operator_surface/ui.ex
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/operator_surface/live/coverage_live_test.exs

key-decisions:
  - "[176-04]: Added an optional :meta slot to UI.page_header (owned by plan 175, shared by all operator pages) rather than smuggling the coverage last-checked line through :inner_block. The slot defaults to [] and renders nothing when absent, so it is byte-for-byte backward compatible for every other page_header call site; coverage's success branch is the sole consumer. This is the cleanest D-12 fit and keeps the existing tl-page__meta styling. Rule 2 (missing critical functionality — the plan's key_links call for page_header title/:lede/:actions/:meta but the component had no :meta slot)."
  - "[176-04]: Deleting the tl-coverage-command__* CSS forced updating THREE existing style_contract assertions in the SAME task (base-responsive .tl-coverage-command + .tl-coverage-command .tl-trust-rail, and tablet .tl-coverage-command__header) — those tests pinned the now-deleted rules and would have gone red. Replaced them with a single refute that locks the deletion, plus an assert that the metric grid keeps its generic .tl-summary-grid margin (the spacing the removed __metrics modifier used to zero out). Paired-deletion invariant (T-176-08) honored."
  - "[176-04]: Task 2 (system-wide nesting sweep) required NO source change beyond Task 1. The card-nesting regression test renders all 7 fixture-free pages + references all 11 surface modules and refutes card-under-card; it went GREEN the moment the coverage command shell was flattened in Task 1. coverage_live.ex was the only confirmed card-nester (as the plan's scope note predicted), so no other LiveView was added to files_modified and the plan stayed disjoint from plan 05 (retention/redaction untouched)."
  - "[176-04]: Dropped the tl-coverage-command__metrics modifier from the metric grid — the bare .tl-summary-grid already supplies margin-bottom: var(--tl-space-4) (correct page-stack spacing), whereas the modifier only existed to zero that margin inside the shell. No new --tl-* token; brand-token parity stays green."

# Metrics
metrics:
  duration: ~25m
  tasks: 2
  files_created: 1
  files_modified: 5
  completed: 2026-06-18
---

# Phase 176 Plan 04: Coverage flatten + card-nesting regression GREEN Summary

Flattened the coverage "schema" command shell — the real DATA-05 / `coverage-schema-card-declutter` target — by replacing the hand-rolled `tl-coverage-command` header with `UI.page_header` in all three branches and demoting the shell's children to plain page-stack siblings, then turned the Plan-01 card-nesting Wave-0 RED test GREEN across all 11 operator surfaces. Every CSS deletion is paired with its contract-test update in the same task.

## What was built

### Task 1 — Flatten coverage to page_header + delete the command shell (`157398d`)
- The success branch's hand-rolled `<section class="tl-coverage-command">…<h1 class="tl-page__title">…` header is deleted and replaced with `<UI.page_header title={"Coverage — schema: #{@schema_param}"}>` carrying `:lede`, an `:actions` Refresh button (`:refresh` icon), and a `:meta` slot rendering `Presentation.checked_label(@coverage_for_schema.last_checked_at)`. All three branches (form-error, empty, success) now use `UI.page_header` (the form-error/empty branches already did per plan 03's shell).
- Added an optional `:meta` slot to `UI.page_header` (renders `<p class="tl-page__meta">`); defaults to `[]` so every other page_header call site is unaffected.
- Demoted the `tl-coverage-command` shell: the trust-rail, the `tl-summary-grid` metric tiles, the remediation section, and the coverage table are now direct page-stack `<section>` siblings spaced by the existing `--tl-space-*` gaps. The `tl-card--metric` tiles (legit repeated items) are kept; the `tl-coverage-command__metrics` modifier is dropped (bare `.tl-summary-grid` supplies the right margin).
- Deleted the dead `tl-coverage-command__*` CSS from `style.ex` (the base `.tl-coverage-command`, `__header`, `__heading`, `__actions`, `__metrics`, `.tl-coverage-command .tl-trust-rail`, plus the tablet `__header`/`__actions` overrides).
- Locked the deletion IN THE SAME COMMIT (Pitfall 2 / T-176-08): `style_contract_test.exs` now `refute String.contains?(src, "tl-coverage-command")` and asserts the metric grid keeps `.tl-summary-grid { margin-bottom: var(--tl-space-4) }`; the three former `tl-coverage-command*` assertions are gone.
- Extended `coverage_live_test.exs`: the success and form-error branches render `<header class="tl-page__header">` + a single `<h1 class="tl-page__title">`, the page contains no `tl-coverage-command` class, the `tl-card--metric` tiles + `tl-summary-grid` survive, and the title/lede/meta literals render.

### Task 2 — System-wide nesting sweep + card-nesting regression GREEN (verification gate, no source change)
- Ran the Plan-01 `card_nesting_regression_test.exs` (renders the 7 fixture-free pages, references all 11 surface modules, refutes any `tl-card*` class nested under another `tl-card*` element). It is GREEN — the coverage command-shell flatten in Task 1 removed the only confirmed card-under-card nester (the regression treats `tl-coverage-command` as a card-family surface, and the metric tiles nested inside it were the violation).
- No other page tripped the regression, so no LiveView beyond `coverage_live.ex` was added to `files_modified` and the plan stayed disjoint from plan 05 (retention_history_live.ex / policy_redaction_live.ex untouched). Task 2 needed no commit of its own.

## Verification

- `mix test .../coverage_live_test.exs .../style_contract_test.exs .../brandbook_token_parity_test.exs` → **53 tests, 0 failures** (Task 1).
- `mix test .../card_nesting_regression_test.exs` → **2 tests, 0 failures** — GREEN across all 11 surfaces (Task 2).
- Full `test/threadline/operator_surface/` → **545 tests, 5 failures** — down from the 6 documented Wave-0 RED scaffolds; the 1 card-nesting (D-12) is now GREEN. ALL 5 remaining failures are the `RetentionHistoryLiveTest` Wave-0 scaffolds owned by plan 05 (4 T3 prune fail-closed enforcement + 1 retention ref-copy). This plan's invariants forbid touching retention/redaction LiveViews, so those stay RED for their owning plan.
- `grep -c 'tl-coverage-command' coverage_live.ex style.ex` → **0 / 0** (shell + CSS fully removed); `UI.page_header` present in all three branches.
- `mix compile --warnings-as-errors` clean; every file this plan touched is `mix format --check-formatted` clean.
- No new `--tl-*` token; brand-token parity + style_contract green.
- Capture & semantics layers untouched — only the coverage LiveView, the coverage region of style.ex, the additive page_header `:meta` slot in ui.ex, and the two coverage/style tests edited (exploration layer only).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added an optional :meta slot to UI.page_header**
- **Found during:** Task 1.
- **Issue:** The plan's `key_links` call for `UI.page_header (title/:lede/:actions/:meta)` to carry the coverage last-checked line, but `page_header` (built in plan 175) had no `:meta` slot — only `:heading`, `:lede`, `:actions`, `:inner_block`.
- **Fix:** Added `slot(:meta, ...)` rendering `<p :if={@meta != []} class="tl-page__meta">`. Optional and defaulting to `[]`, so it is backward compatible for every other page_header consumer; coverage's success branch is the only call site that passes it. Keeps the existing `tl-page__meta` styling.
- **Files modified:** lib/threadline/operator_surface/ui.ex
- **Commit:** 157398d

**2. [Rule 3 - Blocking] Updated three style_contract assertions that pinned the deleted CSS**
- **Found during:** Task 1.
- **Issue:** `style_contract_test.exs` asserted the existence of `.tl-coverage-command`, `.tl-coverage-command .tl-trust-rail` (base-responsive), and `.tl-coverage-command__header` (tablet). Deleting that CSS (the plan's mandate) would have turned those assertions red.
- **Fix:** Removed the three `tl-coverage-command*` assertions and replaced them with the paired-deletion `refute String.contains?(src, "tl-coverage-command")` lock plus an assert that the metric grid keeps `.tl-summary-grid { margin-bottom: var(--tl-space-4) }`. Done in the same commit as the deletion (T-176-08).
- **Files modified:** test/threadline/operator_surface/style_contract_test.exs
- **Commit:** 157398d

## Deferred Issues (out of scope)

- **Retention T3 prune (4) + retention ref-copy (1)** Wave-0 RED scaffolds stay RED — owned by plan 05; this plan's invariants forbid touching `retention_history_live.ex` / `policy_redaction_live.ex`.
- **`row_history_live_test.exs` `mix format` drift** — pre-existing, not in this plan's `files_modified` (already logged to deferred-items.md by plan 03). Every file this plan edited is format-clean.

## Known Stubs

None. The coverage flatten is real wiring (page_header in all three branches, live last-checked meta, preserved metric tiles, working Refresh). No placeholder data, "coming soon", or mock-only props introduced.

## Threat Flags

None new. The two plan-assigned threat mitigations are satisfied:
- **T-176-08** (silent CSS-deletion regression): the `tl-coverage-command__*` deletion is paired in the same task with a `refute String.contains?(src, "tl-coverage-command")` style_contract assertion — re-introduction fails CI.
- **T-176-09** (accidental card nesting across pages): the card-nesting regression test renders all 11 surfaces and refutes card-under-card; it is GREEN and locks the declutter against future regression.
No new network endpoints, auth paths, file access, or schema changes — exploration-layer display flatten only.

## Self-Check: PASSED

All 5 modified files + the SUMMARY exist on disk; the task commit `157398d` is present in git history; `coverage_live.ex` contains `UI.page_header` and no `tl-coverage-command`; `style.ex` contains no `tl-coverage-command`; `ui.ex` page_header has the `:meta` slot; the card-nesting regression test is GREEN.
