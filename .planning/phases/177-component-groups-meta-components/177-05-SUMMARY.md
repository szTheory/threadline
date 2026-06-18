---
phase: 177-component-groups-meta-components
plan: 05
subsystem: operator-surface-design-system
tags: [stress-fixtures, design-system-ledger, group-stories, parity, GROUP-01, GROUP-02, verification-scaffold]
requires:
  - "177-02: stack/cluster layout primitives + semantic gap tokens"
  - "177-03: data_panel/toolbar/detail_header meta-components + cross-child state coordination + page_header breadcrumbs"
  - "177-04: group motion (overlay/data-region/stale/tab) + reconnect/offline connection-class group"
provides:
  - "12 GROUP-01 group stress stories tagged live vs reference-only (D-07)"
  - "ledger↔fixtures↔DESIGN-SYSTEM projection parity for the 12 group configurations"
  - "render assertion covering all 12 group stories across the 320–1440 × dark/light/system matrix"
affects:
  - "Phase 178 (page-stress): the live/reference surface tag tells it which groups ship on a real page"
tech-stack:
  added: []
  patterns:
    - "ledger↔fixtures↔projection lockstep: a story without a matching ledger row + DESIGN-SYSTEM row silently does not render — all three move in the same change"
    - "surface tag (:live | :reference) carried in both story data and metadata so it flows to the ledger projection (notes)"
key-files:
  created:
    - .planning/phases/177-component-groups-meta-components/deferred-items.md
  modified:
    - lib/threadline/operator_surface/stress_fixtures.ex
    - .planning/design-system-ledger.json
    - DESIGN-SYSTEM.md
    - test/threadline/operator_surface/stress_fixtures_test.exs
    - test/threadline/operator_surface/stress_router_test.exs
    - .planning/REQUIREMENTS.md
decisions:
  - "D-07 realized via a single surface tag (:live | :reference) on each group story; the 10 live + 2 reference-only split is asserted in stress_fixtures_test"
  - "All 6 prior reserved baselines (action-bar, filter-bar, kv-list, pagination, status-strip, timeline-list) are absorbed into the 12 configs — zero orphaned *.reserved group ids remain"
  - "Surface signal lives in the ledger entry `notes` field (no new @entry_keys added — the enforced key allowlist stayed intact)"
  - "New current group stories scored 62/62/90 (current/ratchet/target), mirroring the Phase 176 current state stories"
metrics:
  duration_min: 17
  completed: 2026-06-18
  tasks: 3
  files_changed: 7
  library_tests: "1074 passing, 0 failures (1 excluded)"
status: complete
---

# Phase 177 Plan 05: GROUP-01 12-Configuration Stress Mapping + Ledger Parity Summary

Mapped all 12 GROUP-01 configurations onto group stress stories tagged `live` vs `reference-only` (D-07), and kept the `.planning/design-system-ledger.json` ↔ `stress_fixtures.ex` ↔ `DESIGN-SYSTEM.md` projection in lockstep — so every group configuration is auditable as a unit on `/audit/__stress` across 320/375/768/1024/1440 × dark/light/system, with the full library suite green.

## What Was Built

### Task 1 — Remap `@group_stories` to the 12 configurations with a surface tag
Replaced the 6 reserved `group.*.reserved` baselines with the 12 GROUP-01 configurations as `status: "current"`, `owner_phase: 177` stories built by a dedicated `group_story/4` builder that takes `surface in [:live, :reference]` and carries the tag in **both** `data` and `metadata` (so it flows to the ledger projection). Wired `group_story_maps/0` into `stories/0` in place of `reserved_story_maps(@group_stories, "group", 177)`. Each story gets a per-config `cases` set (e.g. data-panel → empty/stale/error; offline → reconnecting/stale; permission-denied → permission_denied) so the stress matrix exercises the relevant states.

The 12 ids (sorted), with surface:
- `group.data-panel.current` (live; absorbs pagination, timeline-list)
- `group.detail-header.current` (live; absorbs kv-list)
- `group.drawer-form.reference` (**reference-only**, D-07)
- `group.empty-cta.current` (live; absorbs action-bar action-cluster semantics)
- `group.modal-destructive.current` (live)
- `group.offline.current` (live)
- `group.page-header.current` (live)
- `group.permission-denied.current` (live)
- `group.stats-chart-table.current` (live; absorbs status-strip)
- `group.tabs-subviews.reference` (**reference-only**, D-07)
- `group.toast-update.current` (live)
- `group.toolbar.current` (live; absorbs filter-bar)

`stress_fixtures_test.exs` now asserts: exactly 12 group stories, each `status: current` / `owner_phase: 177`, each with a `surface` tag in `[:live, :reference]` matching across data+metadata, no orphaned `*.reserved` group ids, and the exact 10-live / 2-reference split. The `@required_inventory_story_ids` list was updated to the new 12 ids.

### Task 2 — Sync ledger + DESIGN-SYSTEM projection (parity)
Replaced the 6 `group.*.reserved` ledger entries with 12 `group.*` current entries (`current_score: 62`, `ratchet_score: 62`, `target_score: 90`, `category/kind: "group"`, `owner_phase: 177`, `status: "current"`), carrying the live/reference signal in the `notes` field — **no new `@entry_keys` were introduced**, so the enforced key allowlist (and its test) stayed intact. Reconciled `ratchet.locked_ids` (removed the 6 reserved ids, added the 12 new), `ratchet.minimum_scores` (removed 6, added 12 at 62), and `required_inventory.groups` (the 6 baseline names → the 12 config slugs). Regenerated the `DESIGN-SYSTEM.md` "Groups" section with a deterministic projection row per ledger entry. The ledger parity test (`stress_ledger_test.exs`) confirms fixtures↔ledger↔projection lockstep.

### Task 3 — Render assertion across the matrix + full gate
Added a `stress_router_test.exs` assertion that loads `/audit/__stress?story=<id>&category=group&theme=<t>&viewport=<v>` for each of the 12 group story ids across all 3 themes × 5 viewports, asserting each renders without error, is the selected story, and applies the requested theme. Ran the full phase gate.

## Verification Results (exact counts)

- `mix test stress_fixtures_test.exs` — **11 tests, 0 failures**
- `mix test stress_ledger_test.exs` — **10 tests, 0 failures**
- `mix test stress_router_test.exs` — **15 tests, 0 failures** (includes the new 12-group × 15-cell render assertion)
- `mix verify.format` — **clean** (no unformatted files)
- `mix verify.credo` — **no issues** (2129 mods/funs, 226 files)
- `mix verify.test` (full library suite) — **1074 tests, 0 failures (1 excluded)**
- `mix compile --warnings-as-errors` — **exit 0, clean**
- Brand-token parity / source-governance assertions (forbidden terms, no frontmatter, synthetic-only fixtures) — **GREEN** (part of the suites above)

Zero new runtime deps; no public component API touched; capture and semantics layers untouched (v1.37 invariant held).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Formatted pre-existing test format debt to unblock the verify.format gate**
- **Found during:** Task 3 (`mix ci.all` → first step `mix verify.format`)
- **Issue:** `test/threadline/operator_surface/ui_stress_test.exs` (committed by 173-04) and `test/threadline/operator_surface/live/row_history_live_test.exs` were committed in an unformatted state, failing `mix verify.format`. This blocks the phase-177 verification gate, which requires `mix verify.format` green.
- **Proof pre-existing:** both files were committed clean (no working-tree edits from this plan) and predate plan 05.
- **Fix:** `mix format` on both (zero behavior change); committed as a separate `style(177-05)` chore with clear attribution.
- **Files modified:** `test/threadline/operator_surface/ui_stress_test.exs`, `test/threadline/operator_surface/live/row_history_live_test.exs`
- **Commit:** 313e52c

**2. [Scope boundary] REQUIREMENTS.md marked GROUP-01 + GROUP-02 complete**
- Per the plan's verification note, GROUP-01 (12 configs auditable as units at all breakpoints) is delivered by this plan, and GROUP-02 (layout/state/motion coherence) is delivered across plans 02–04. Both checkboxes + the traceability table were updated to Complete with per-plan attribution.

## Deferred Issues

**Pre-existing example-app demo-seed timeout** (logged to `deferred-items.md`):
`mix verify.example` / `mix ci.all` reports 1 failure at `examples/threadline_phoenix/test/mix/tasks/threadline_evidence_show_example_test.exs:20` — the test setup (`Demo.Seed.run/0` → `Demo.Seed.Exports.run/1` `insert_all`) exceeds the default 60s ExUnit setup timeout under the local dual-Postgres dev environment. **Proven pre-existing**: the test fails identically with all plan-05 changes stashed, and references no plan-05 artifact. Out of scope (example sub-project demo-seed performance, not the design system). Owner: a future example-app/perf phase.

## Known Stubs

None. The reference-only stories (`group.drawer-form.reference`, `group.tabs-subviews.reference`) are intentional canonical reference assemblies (D-06b / D-07) — they have no live page consumer this phase by design, are fully fixture-backed, render on the stress route, and are tracked for promotion when a real operator need surfaces (Deferred Ideas). They are not placeholder/empty-data stubs.

## Manual Audit Checklist (staged for `/gsd-verify-work`)

The pixel "holds together at every viewport" judgment is a human pass per VALIDATION.md. For each of the 12 group stories at 320/375/768/1024/1440 × dark/light/system:

1. **Spacing/hierarchy:** the configuration reads as one coherent unit (intentional gap rhythm via stack/cluster), not class-soup.
2. **data_panel state matrix** (`group.data-panel.current`): toggle empty / loading / error / stale / no-data / permission / unavailable — confirm the toolbar's filter/sort controls go **disabled** on loading and hard error; the **stale banner sits above** still-rendered live data (never replaces it); permission/unavailable **collapses the panel body** to one message with the distinct icon shape (lock vs funnel vs cloud_off forensic distinction survives composition).
3. **Motion:** observe overlay enter/exit (modal fade+scale, drawer slide, toast fade-up via `group.modal-destructive` / `group.drawer-form` / `group.toast-update`) and the data-region cross-fade on state swap; re-check all under `prefers-reduced-motion: reduce` (transitions collapse to ~instant via the existing blanket).
4. **Tabs/segmented** (`group.tabs-subviews.reference`): active indicator animates; subview crossfade reads as intentional.
5. **Reconnect/offline** (`group.offline.current`): drop the LiveView socket and confirm the reconnect banner (`role="status"`) appears and mutating actions disable via the connection CSS hooks on `.threadline-ui` (`.phx-loading` / `.phx-error`).
6. **Responsive reflow:** toolbar wrap at narrow widths, action-cluster → kebab collapse, stat-cards grid → stack, breadcrumb truncation.

## Self-Check: PASSED

- `lib/threadline/operator_surface/stress_fixtures.ex` — FOUND (12 group stories, surface tag)
- `.planning/design-system-ledger.json` — FOUND (12 group entries, valid JSON)
- `DESIGN-SYSTEM.md` — FOUND (12 Groups projection rows)
- `test/threadline/operator_surface/stress_fixtures_test.exs` — FOUND (12-count + tag + split assertions)
- `test/threadline/operator_surface/stress_router_test.exs` — FOUND (12-group render assertion)
- `.planning/phases/177-component-groups-meta-components/deferred-items.md` — FOUND
- Commits 8987793, 8f62d25, 9ca8453, 313e52c — all present in `git log`
