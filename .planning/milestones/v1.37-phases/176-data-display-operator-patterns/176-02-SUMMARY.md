---
phase: 176-data-display-operator-patterns
plan: 02
subsystem: operator-surface
tags: [ui-components, data-display, data-state, ref, kv, data-table, forensic, a11y, stress, wave-2]
requirements-completed: [DATA-01, DATA-02, DATA-03]

# Dependency graph
requires:
  - "176-01: Presentation.ref/2 → %{visible, title, full}; truncate_for per-kind; icons eye_off/funnel/lock/cloud_off/archive"
provides:
  - "UI.ref/1 — single call-site copy affordance; binds data-tl-copy={full} on <code> AND gated button (never .title/.visible, D-02); zero-JS renders full (D-06); copy_label required (D-07)"
  - "UI.kv/1 — tl-kv <dl> with required :item key slot; render_slot in <dd> (D-08)"
  - "UI.data_table/1 — :col label feeds <th> + every <td data-label> from one source; rows|stream (phx-update=stream); row_id; row_status data-status stripe; :action kebab; no ARIA table roles (D-09)"
  - "UI.loading_state/1 — named sibling, role=status + aria-busy + spinner + text node (D-13)"
  - "UI.stale_banner/1 — role=status tl-alert--warning strip with as_of + Retry, rendered ABOVE data (D-14)"
  - "UI.empty_state/1 variant enum gains no_data/permission/unavailable; adds role/icon/focus_heading (D-15/D-16)"
  - "UI.data_state/1 — typed-reason dispatcher: distinct role+icon shape+heading per reason; unavailable sub-cases state 'not a permissions issue'"
  - "10 stress stories (ref/kv/data_table + 7 data-states) on /audit/__stress with ledger + DESIGN-SYSTEM parity"
affects:
  - "176-03 (coverage flatten) + 176-04/05 (page adoption) consume these components; the data_state_mapping wave-0 test is now GREEN"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ref/1 mirrors stat_tile attr-only shape; binds Presentation.ref(full) to data-tl-copy on every copy surface — the forensic integrity boundary"
    - "data_state/1 is a multi-clause function component pattern-matching on %{reason: ...}; each clause renders the locked empty_state variant / loading_state with the taxonomy's role+icon+heading"
    - "D-15 focus rescue is CSP-clean: a generated heading id + tabindex=-1 + phx-mounted={JS.focus(...)} — no inline handler"
    - "data-state distinctness is enforced by shape (lock/funnel/cloud_off/eye_off/archive), never color alone (D-16)"
    - "stress story registration stays coupled: stress_fixtures.ex ↔ design-system-ledger.json ↔ DESIGN-SYSTEM.md must all agree or stress_ledger_test fails"

key-files:
  created:
    - .planning/phases/176-data-display-operator-patterns/176-02-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/ui.ex
    - test/threadline/operator_surface/ui_test.exs
    - lib/threadline/operator_surface/stress_fixtures.ex
    - lib/threadline/operator_surface/live/stress_live.ex
    - .planning/design-system-ledger.json
    - DESIGN-SYSTEM.md

key-decisions:
  - "[176-02]: built UI.data_state/1 as the typed-reason dispatcher (not in the plan's task list but required by the Plan-01 data_state_mapping wave-0 RED test). data_state/1 maps each reason to the locked empty_state variant / loading_state — it is the seam that turns the 3 data-state assertions GREEN at the component level. Rule 2/3."
  - "[176-02]: copy_label required-attr enforcement is a compile-time WARNING (Phoenix attr semantics), not a runtime raise; the contract test asserts the warning via CaptureIO. D-07 honored (no default)."
  - "[176-02]: ledger JSON + DESIGN-SYSTEM.md edited alongside stress_fixtures.ex (NOT in plan files_modified) because stress_ledger_test couples all three (every StressFixtures story needs a matching ledger entry + projected inventory row). Rule 3 — blocking. New entries: current-status state-kind, current_score==ratchet_score==62, owner_phase 176."
  - "[176-02]: new BEM element classes (tl-empty__icon, tl-empty__spinner, tl-alert__icon, tl-ref, tl-empty--loading) compose the existing system; zero new --tl-* token; brand-token parity + style_contract stay green. No style.ex change (plan constraint honored)."
  - "[176-02]: reformatted pre-existing ui_test.exs format drift (deferred from 176-01) in the same commit that edits it."

# Metrics
metrics:
  duration: ~40m
  tasks: 3
  files_created: 1
  files_modified: 6
  completed: 2026-06-18
---

# Phase 176 Plan 02: Data-display + data-state component set Summary

Built the internal `Threadline.OperatorSurface.UI` data-display + data-state family — `ref/1`, `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1`, three new `empty_state` variants, and the `data_state/1` typed-reason dispatcher — as pure render functions with per-component contract tests and full `/audit/__stress` registration, turning the Plan-01 data-state mapping RED test GREEN at the component level. No page is migrated (plans 03/04/05).

## What was built

### Task 1 — ref/1, kv/1, data_table/1 (TDD: RED `d3273d3` → GREEN `617eb47`)
- `ref/1`: renders `<code class="tl-secondary-ref" title={full} data-tl-copy={full}>{visible}</code>` plus a `Script.enabled?()`-gated copy button that ALSO carries `data-tl-copy={full}`. For a long value, `data-tl-copy == full != visible` (the forensic D-02 contract). When scripts are disabled the `<code>` renders `full` for zero-JS select-all (D-06). `copy_label` is required with no default (D-07).
- `kv/1`: `<dl class="tl-kv">` with a required `:item key` slot; `<dt>` shows key, `<dd>` shows `render_slot(item)`.
- `data_table/1`: `:col` slot with required `label` emits `<th>{label}` AND every `<td data-label={label}>` from one source; `rows` OR `stream` (truthy → `phx-update="stream"`); `row_id` → `<tr id=…>`; `row_status` → `data-status` stripe; `:action` kebab slot; always `tl-table tl-table--responsive`; NO ARIA table roles (D-09).

### Task 2 — loading_state/1, stale_banner/1, empty_state variants, data_state/1 (TDD: RED `8c880a6` → GREEN `93a8027`)
- `loading_state/1`: `role="status"` + `aria-busy="true"`, `<.spinner/>` + an overridable default text node ("Loading audit changes…"). A structurally distinct named sibling, not a variant (D-13).
- `stale_banner/1`: `role="status"` `tl-alert--warning` strip with a refresh glyph and an `as_of` timestamp; copy "Couldn't refresh — showing last known data from <timestamp>. Retry." Rendered ABOVE data (D-14).
- `empty_state/1`: variant enum gains `no_data`, `permission`, `unavailable`; adds `role`, `icon`, and `focus_heading` (D-15 focus rescue: generated heading id + `tabindex="-1"` + `phx-mounted={JS.focus(...)}`, CSP-clean). `error_state/1` now delegates with `role="alert"` + warning glyph + focus rescue; its `variant="error"` delegation is otherwise unchanged.
- `data_state/1`: typed-reason dispatcher mapping `:loading/:no_data/:unauthorized/:source_down/:redacted/:pruned/_` each to its locked role + DISTINCT icon shape + heading. The three unavailable sub-cases each state "This is not a permissions issue" (D-16). This is the seam that turns the Plan-01 `data_state_mapping_wave0_test` GREEN.

### Task 3 — stress registration (`9e17e86`)
- 10 new state-kind stress stories (`state.ref.current`, `state.kv.current`, `state.data-table.current`, `state.loading`, `state.stale`, `state.no-data`, `state.permission`, `state.unavailable-down`, `state.unavailable-redacted`, `state.unavailable-pruned`) in `stress_fixtures.ex`, rendered in isolation in the `stress_live.ex` matrix.
- Matching ledger entries in `.planning/design-system-ledger.json` and inventory rows in `DESIGN-SYSTEM.md` so the ledger↔registry↔projection parity stays green.

## Verification

- `mix test test/threadline/operator_surface/ui_test.exs` → 52 tests, 0 failures (Tasks 1-2).
- `mix test .../stress_ledger_test.exs .../stress_router_test.exs .../stress_fixtures_test.exs` → 33 tests, 0 failures (Task 3).
- `mix test .../data_state_mapping_wave0_test.exs` → GREEN (the 3 Plan-01 data-state assertions now pass).
- `mix test test/threadline/brandbook_token_parity_test.exs .../style_contract_test.exs` → 37 tests, 0 failures (no new `--tl-*` token; no style.ex change).
- `mix compile --warnings-as-errors` clean; `mix format --check-formatted` clean project-wide.
- Full `test/threadline/operator_surface/` → 541 tests, 6 failures — ALL 6 are the documented Plan-01 Wave-0 cross-plan RED scaffolds (1 card-nesting D-12 → plan 03; 4 T3 prune enforcement + 1 retention ref-copy → plan 05). This plan correctly converted the 3 data-state assertions from RED→GREEN and left the page-adoption assertions RED for their owning plans (phase invariant: plan 02 does NOT migrate any page).
- Capture & semantics layers untouched — only ui.ex + stress fixtures/live + ledger/projection + tests edited (exploration layer only).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Built UI.data_state/1 (the typed-reason dispatcher)**
- **Found during:** Task 2.
- **Issue:** The plan's task list named `loading_state/1`, `stale_banner/1`, and the `empty_state` variants but not a dispatcher, yet the Plan-01 `data_state_mapping_wave0_test` calls `UI.data_state reason={...}` and the plan's stated output is "turning the Plan-01 data-state RED test partially GREEN at the component level." Without `data_state/1` that test stays RED.
- **Fix:** Added `data_state/1` as a multi-clause function component mapping each typed reason to the locked variant/state with the taxonomy's role + icon shape + heading (UI-SPEC §"Data-State Taxonomy").
- **Files modified:** lib/threadline/operator_surface/ui.ex, test/threadline/operator_surface/ui_test.exs
- **Commit:** 93a8027

**2. [Rule 3 - Blocking] Ledger JSON + DESIGN-SYSTEM.md updated alongside stress_fixtures.ex**
- **Found during:** Task 3.
- **Issue:** `stress_ledger_test.exs` requires every `StressFixtures.all()` story to have a matching ledger entry (by `ledger_id`) AND every ledger entry to have a projected inventory row in `DESIGN-SYSTEM.md`. Adding stories to `stress_fixtures.ex` alone makes 3 ledger tests fail. These two files are not in the plan's `files_modified`, but the plan's verification mandates `stress_ledger_test.exs` green.
- **Fix:** Added 10 matching ledger entries (current-status, state-kind, owner_phase 176, current_score==ratchet_score==62) and 10 inventory rows, both re-sorted.
- **Files modified:** .planning/design-system-ledger.json, DESIGN-SYSTEM.md
- **Commit:** 9e17e86

**3. [Rule 3 - Blocking] copy_label required-attr is a compile-time warning, not a runtime raise**
- **Found during:** Task 1.
- **Issue:** The RED test initially asserted `assert_raise ArgumentError` for an omitted `copy_label`; Phoenix `attr ... required: true` emits a compile-time WARNING (not a runtime exception), so the assertion could never hold.
- **Fix:** Re-targeted the contract test to assert the warning is emitted (via `ExUnit.CaptureIO.capture_io(:stderr, ...)` while compiling a throwaway component). D-07 (no default) is honored in the component.
- **Commit:** 617eb47

**4. [Scope boundary] Reformatted pre-existing ui_test.exs format drift**
- 176-01's deferred-items asked the later plan that edits `ui_test.exs` to reformat it in the same commit. Done in the Task-1 RED commit (`d3273d3`); the format change is whitespace-only.

## Known Stubs

None. All five components + the dispatcher are fully wired render functions with passing contract tests and live stress stories; no placeholder data or "coming soon" text. No page adoption is in scope for this plan (by design).

## Threat Flags

None. The two threat-register mitigations for this plan are satisfied: T-176-03 (ref/1 binds `data-tl-copy={full}` on `<code>` + button, zero-JS fallback renders full, ui_test asserts copy==full!=visible) and T-176-04 (permission/no_data/unavailable are structurally distinct with own role + icon shape + heading, ui_test asserts distinct glyphs and "not a permissions issue"). No new security surface introduced (exploration-layer render functions only).

## Self-Check: PASSED

All six modified files + the SUMMARY exist on disk; all five task commits (`d3273d3`, `617eb47`, `8c880a6`, `93a8027`, `9e17e86`) are present in git history; `ui.ex` contains `def ref/kv/data_table/loading_state/stale_banner/data_state`.
