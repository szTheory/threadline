---
phase: 135-seed-enrichment-ia-lock-in
plan: "04"
subsystem: demo-seed
tags: [demo, docs, doc-contract, recipe-table, actor-literals, DEMO-MANIFEST]
dependency_graph:
  requires:
    - phase: 135-01
      provides: "Named actor literals in Manifest (Manifest.actor_id/1) — zendesk-sync, oban-retention-purge, trigger-backfill"
    - phase: 135-03
      provides: "In-window variety pack: 5 INSERT / 4 UPDATE / 2 DELETE; non-human actor clusters; SavedView rows"
  provides:
    - "DEMO-MANIFEST.md extended with ## State recipes table (24 rows) + ## Named actor literals section"
    - "demo_manifest_contract_test.exs: doc-contract test pinning recipe table + actor literals against drift"
  affects:
    - "Phases 136-143 (8 downstream screenshot phases that cite DEMO-MANIFEST.md recipes)"
    - "v1.31-UI-AUDIT.md state matrix (documented reachability for all screen states)"

tech-stack:
  added: []
  patterns:
    - "Path.expand + File.read! + String.contains?/2 per-literal assert (doc-contract test pattern)"
    - "Screen x state x login x filter/path recipe table in DEMO-MANIFEST.md"

key-files:
  created:
    - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs
  modified:
    - examples/threadline_phoenix/DEMO-MANIFEST.md

key-decisions:
  - "D-03: Recipe table backed by doc-contract test so recipes can't silently drift from seed across 8 downstream screenshot phases"
  - "D-04 deferral: Coverage fully-covered/all-empty state noted as Phase-138-owned (trigger-registration dependent, not seed-reachable)"
  - "D-01: One-command story (mix demo.reset && mix demo.seed) + no --profile flags documented in DEMO-MANIFEST.md"
  - "demo_manifest_contract_test.exs kept separate from demo_manifest_test.exs (which tests the Elixir Manifest module)"
  - "Pre-existing walkthrough_evidence_test.exs formatting issue left untouched per clean_tree_discipline"

patterns-established:
  - "Doc-contract test for markdown docs: async: true, Path.expand/2 for file path, describe blocks, String.contains?/2 per literal with assert message"
  - "Recipe table format: Screen | State | Login | Filter/Path | Notes"

requirements-completed: [POLISH-SEED]

duration: 5min
completed: 2026-06-03
---

# Phase 135 Plan 04: DEMO-MANIFEST.md Recipe Table + Doc-Contract Test Summary

**DEMO-MANIFEST.md extended to SSOT with a 24-row per-state recipe table and named actor literals section, backed by an 8-test doc-contract test that locks them against drift for the 8 downstream screenshot phases.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-06-03T23:20:00Z
- **Completed:** 2026-06-03T23:25:00Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 extended)

## Accomplishments

- Extended DEMO-MANIFEST.md with `## State recipes` (24 rows covering all operator-surface screen states reachable from the enriched seed) and `## Named actor literals` (4 non-human kinds with exact ID strings and Manifest accessor keys)
- Created `ThreadlinePhoenix.DemoManifestContractTest` — 8 assertions in 2 describe blocks pinning the recipe table header, screen names, empty/scoped literals, future-date filter, one-command story, Coverage deferral, and all three named actor literals
- Working tree clean — no out-of-scope files modified (pre-existing formatter-version drift on `walkthrough_evidence_test.exs` left untouched per clean_tree_discipline)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add per-state recipe table + named actor literals to DEMO-MANIFEST.md** - `51003de` (docs)
2. **Task 2: Add demo_manifest_contract_test.exs doc-contract test** - `3bec1a9` (test)

**Plan metadata:** (committed below)

## Files Created/Modified

- `examples/threadline_phoenix/DEMO-MANIFEST.md` — Extended with `## State recipes` (24 rows: screen × state × login × filter/path × notes) and `## Named actor literals` (zendesk-sync, oban-retention-purge, trigger-backfill, anonymous)
- `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` — New `ThreadlinePhoenix.DemoManifestContractTest`; async: true; 8 tests in 2 describe blocks (`recipe table`, `named actor literals`); 0 failures

## Decisions Made

- **Recipe table scope:** 24 rows covering all meaningful states including permission-edge (scoped support login), empty (purged offboarded-co org and future-date filter), op-variety (filter by update/delete), actor-variety (non-human actor kinds), and rich-diff rows
- **D-04 deferral documented:** Coverage fully-covered/all-empty row explicitly marked "DEFERRED to Phase 138 — depends on trigger registration + schema introspection (`Health.trigger_coverage`), not org rows; cannot be produced seed-only"
- **doc_manifest_contract_test.exs vs demo_manifest_test.exs:** Kept as separate modules — the existing `DemoManifestTest` tests the Elixir `Manifest` module; the new `DemoManifestContractTest` tests the `.md` document
- **One-command story:** `mix demo.reset && mix demo.seed` referenced explicitly; "No `--profile` flag is used or needed" documented

## Deviations from Plan

None — plan executed exactly as written. The `walkthrough_evidence_test.exs` formatter-version drift was identified as pre-existing (last modified in commits 5431462/db94c49) and left untouched per clean_tree_discipline.

## Issues Encountered

`mix verify.format` alias does not exist in the examples/threadline_phoenix app (the plan's verification step referenced it). Used `mix format --check-formatted` directly. This revealed the pre-existing `walkthrough_evidence_test.exs` formatting issue — confirmed pre-existing and left untouched.

## Known Stubs

None — the recipe table documents real reachable states and the doc-contract test asserts real literals. The Coverage deferred row is intentionally marked DEFERRED (not a stub).

## Threat Flags

None — docs + a read-only test, no secrets/PII, no runtime surface.

## Self-Check: PASSED

- `examples/threadline_phoenix/DEMO-MANIFEST.md` — FOUND (contains "## State recipes", "zendesk-sync", "Phase 138", "?from=2030", "mix demo.reset && mix demo.seed", "Named actor literals")
- `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` — FOUND (8 tests, 0 failures)
- commit 51003de — FOUND (docs(135-04): add per-state recipe table + named actor literals)
- commit 3bec1a9 — FOUND (test(135-04): add demo_manifest_contract_test.exs)
- `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` — 8 tests, 0 failures
- `git status --short` — clean (no out-of-scope files)

---
*Phase: 135-seed-enrichment-ia-lock-in*
*Completed: 2026-06-03*
