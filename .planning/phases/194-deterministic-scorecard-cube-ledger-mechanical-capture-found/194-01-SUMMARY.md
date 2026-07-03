---
phase: 194-deterministic-scorecard-cube-ledger-mechanical-capture-found
plan: 01
subsystem: testing
tags: [design-system-ledger, scorecard-cube, ratchet-guard, wcag, elixir, exunit, json-migration]

# Dependency graph
requires:
  - phase: 171-176
    provides: v1 design-system-ledger.json (flat single-score schema) + stress_ledger_test.exs guard
provides:
  - "design-system-ledger.json v2: page × persona × lens scorecard cube (14 cells/entry across 130 entries)"
  - "cube_axes block: 5 personas (P1-P5) + 6 D-01 frozen lenses with method/kind/authority metadata"
  - "mechanical_floors {} + ratchet.signoffs [] top-level scaffolding for Plans 02/03"
  - "5 deterministic cube guard blocks (rollup-integrity, per-cell monotonicity, evidence-on-gain, axis validity, floor-bump authority)"
  - "valid_cell_keys/1 + scorecard_row/2 test helpers"
  - "DESIGN-SYSTEM.md ## Scorecard Cube per-(page × persona) projection with freshness guard"
affects: [194-02-capture-lane, 194-03-mechanical-checker, phase-195-cell-rating]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Dotted cell-key grammar persona.lens (P1.hierarchy) + all.lens for persona-invariant lenses"
    - "Legacy watermark: current_score/ratchet_score stay as scalar; legacy_score freezes v1 provenance; cells born unrated"
    - "Rollup-integrity guard: current_score == min(rated cells) else == ratchet_score (vacuously green when unrated)"
    - "Evidence-on-gain: score increase requires File.exists?-true cell-keyed evidence_ref map"
    - "Markdown-substring freshness guard mirrored for a second projection table (scorecard_row/2)"

key-files:
  created: []
  modified:
    - ".planning/design-system-ledger.json — v1→v2 in-place migration (version 2, cube_axes, mechanical_floors, ratchet.signoffs, per-entry legacy_score + 14-cell scores)"
    - "test/threadline/operator_surface/stress_ledger_test.exs — v2 module attributes + 6 new test blocks + 2 helpers"
    - "DESIGN-SYSTEM.md — ## Scorecard Cube projection (385 rows)"

key-decisions:
  - "Scalar current_score/ratchet_score/target_score left untouched at migration; cells born unrated so min-of-cells would be 0 and falsely trip monotonicity — scalar is the legacy watermark until Phase 195 rates cells"
  - "evidence_ref OMITTED at migration (no gains at rest) and kept in @optional_entry_keys; guard treats it as a cell-keyed File.exists? map when present"
  - "Cube projection in DESIGN-SYSTEM.md scoped to page-kind entries only (77 pages × 5 personas = 385 rows); non-page entries keep their existing inventory freshness rows"
  - "Migration + guard @top_level_keys/@entry_keys updates landed in ONE atomic commit so the pre-existing 10-block suite never went red"

patterns-established:
  - "In-place v1→v2 JSON ledger migration via throwaway Node script, keys sorted for deterministic diff/review"
  - "Guard teeth proven by injecting a below-floor cell / unearned gain / rated-cell mismatch, observing RED, then reverting"

requirements-completed: [LEDGER-01, LEDGER-02, LEDGER-03, LEDGER-04, LEDGER-05]

coverage:
  - id: D1
    description: "Ledger v2 scorecard cube — 130 entries carry a sorted 14-cell page×persona×lens scores map + legacy_score; cube_axes/mechanical_floors/ratchet.signoffs seeded"
    requirement: LEDGER-01
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/stress_ledger_test.exs#cube_axes declares the frozen lens order and every entry carries the valid cell set"
        status: pass
    human_judgment: false
  - id: D2
    description: "Per-cell monotonicity guard — a non-null cell current below its floor fails without a ratchet reset + rationale"
    requirement: LEDGER-02
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/stress_ledger_test.exs#per-cell scores can only ratchet upward unless the entry has an explicit reset"
        status: pass
    human_judgment: false
  - id: D3
    description: "Evidence-on-gain guard — current_score > ratchet_score requires a non-empty cell-keyed evidence_ref whose every path File.exists?"
    requirement: LEDGER-03
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/stress_ledger_test.exs#a score increase carries a File.exists?-true evidence_ref for every cited cell"
        status: pass
    human_judgment: false
  - id: D4
    description: "DESIGN-SYSTEM.md ## Scorecard Cube per-(page × persona) projection with per-row freshness guard"
    requirement: LEDGER-04
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/stress_ledger_test.exs#Scorecard Cube projection is fresh for every page-entry × persona row"
        status: pass
    human_judgment: false
  - id: D5
    description: "All guards run deterministically inside mix ci.all (async:true, pure filesystem, no LLM/network)"
    requirement: LEDGER-05
    verification:
      - kind: unit
        ref: "mix test test/threadline/operator_surface/stress_ledger_test.exs (16 tests, 0 failures) + mix verify.format"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: 2026-07-03
status: complete
---

# Phase 194 Plan 01: Deterministic Scorecard-Cube Ledger Summary

**Migrated the design-system ledger from flat v1 single-score to a v2 page × persona × lens scorecard cube (14 cells across 130 entries), added 5 mechanical cube-invariant guard blocks with proven teeth, and projected a per-lens Scorecard Cube table into DESIGN-SYSTEM.md — all deterministic in mix ci.all, no LLM, no network.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-07-03T09:18Z
- **Completed:** 2026-07-03T09:25:27Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Migrated `.planning/design-system-ledger.json` to `version: 2`: added top-level `cube_axes` (5 personas P1–P5 with real labels + 6 D-01 frozen lenses carrying method/kind/authority), `mechanical_floors: {}`, and `ratchet.signoffs: []`; every one of the 130 entries gained `legacy_score` (frozen v1 provenance) and a sorted 14-cell unrated `scores` cube. Scalar `current_score`/`ratchet_score`/`target_score` left byte-identical (legacy watermark).
- Extended `stress_ledger_test.exs` guard: v2 `@top_level_keys`/`@entry_keys`/`@optional_entry_keys`, banned `Lost Pixel`, and added 5 new cube guard blocks (rollup-integrity, per-cell monotonicity, evidence-on-gain, axis validity, floor-bump authority) plus the `valid_cell_keys/1` helper. Teeth proven by injecting a below-floor cell, an unearned gain, and a rated-cell mismatch → 4 RED, then reverted → all green.
- Added `## Scorecard Cube` to `DESIGN-SYSTEM.md`: 385 rows (77 page-kind entries × 5 personas) with the frozen 6-lens column order, unrated cells rendering em-dash, and a `Score` rollup column; added `scorecard_row/2` + a per-row freshness guard mirroring the existing inventory substring mechanic.

## Task Commits

1. **Task 1: Migrate ledger v1→v2 + guard module attributes (atomic)** — `d8970e3c` (feat)
2. **Task 2: Add the 5 cube guard blocks + valid_cell_keys/1** — `ad5461f0` (test)
3. **Task 3: Scorecard Cube projection + freshness guard** — `3814511d` (feat)

_Note: Task 2 was a TDD/test-only task; the deliverable is the guard, proven via inject-then-revert rather than a separate feat commit._

## Files Created/Modified
- `.planning/design-system-ledger.json` — v1→v2 in-place migration (only additive keys; scalars unchanged; keys sorted for deterministic diff)
- `test/threadline/operator_surface/stress_ledger_test.exs` — v2 attributes + 6 new test blocks (5 cube + 1 scorecard freshness) + `valid_cell_keys/1` + `scorecard_row/2`
- `DESIGN-SYSTEM.md` — new `## Scorecard Cube` per-(page × persona) projection

## Decisions Made
- Kept scalar scores as the legacy watermark and born all cells `unrated` (null current, floor 0) — recomputing `current_score` to min-of-cells at migration would have collapsed to 0 and falsely tripped monotonicity against `ratchet_score`.
- Omitted `evidence_ref` at migration (no gains at rest); it stays optional and the guard validates it as a cell-keyed `File.exists?` map only when a real gain appears (Phase 195+).
- Scoped the DESIGN-SYSTEM cube projection to page-kind entries per the locked migration rules; the full 14-cell `scores` map still lives on all 130 entries in the JSON.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. Pre-existing ~81 local `mix test` failures (storage_schema/search_path env issue, undefined audit tables) are unrelated to this plan and were not touched; verification focused on the guard test file, which is pure-filesystem and passes independently.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The deterministic cube ledger + guards are landed AHEAD of any nondeterministic score producer (the LOCKED dependency spine). Plan 02 (capture lane) and Plan 03 (mechanical checker) can now reference `cube_axes`, `mechanical_floors`, `ratchet.signoffs`, and per-entry `scores`/`evidence_ref`.
- `mechanical_floors` is intentionally empty `{}` — Plan 03 populates it from first capture.

## Self-Check: PASSED

- `.planning/design-system-ledger.json` — FOUND (version 2, 130 entries × 14 cells verified)
- `test/threadline/operator_surface/stress_ledger_test.exs` — FOUND (16 tests, 0 failures)
- `DESIGN-SYSTEM.md` — FOUND (## Scorecard Cube, 385 rows)
- Commits `d8970e3c`, `ad5461f0`, `3814511d` — all present in git log
- `mix verify.format` PASS (exit 0); `mix test <guard>` 16/16 green

---
*Phase: 194-deterministic-scorecard-cube-ledger-mechanical-capture-found*
*Completed: 2026-07-03*
