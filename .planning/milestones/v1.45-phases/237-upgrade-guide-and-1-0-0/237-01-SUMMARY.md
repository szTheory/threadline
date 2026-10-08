---
phase: 237-upgrade-guide-and-1-0-0
plan: 01
subsystem: documentation
tags: [elixir, exunit, exdoc, upgrade-guide, release-notes]
requires:
  - phase: 236-support-floor-and-partition-weights
    provides: PostgreSQL 15 support floor and complete sorted test-weight inventory
provides:
  - Conditional 0.11.x preflight and seven-step 1.0 upgrade guide for 0.11.x and 0.12.x adopters
  - Exact unique-ID contract across 12 Unreleased breaking entries, eight deprecations, and three 0.12.0 prerequisites
  - ExDoc and Adopt graph registration plus a weighted contract test
affects: [phase-237-release-rehearsal, adopter-docs, changelog-contracts]
actuals:
  tokens: 7535
  tasks: 2
  commits: 2
commits: 2
plan_head_before: eeaf8eb118829a50f478c1245de7c03ef5c2c673
plan_head_after: 8dc5556dec2ed89e1ae6372175724c670e018780
tech-stack:
  added: []
  patterns: [scoped hidden IDs with exact source-guide set equality, version-aware changelog section selection]
key-files:
  created:
    - guides/upgrading-to-1.0.md
    - test/threadline/upgrading_to_1_0_doc_contract_test.exs
  modified:
    - CHANGELOG.md
    - guides/upgrade-path.md
    - test/threadline/guide_graph_contract_test.exs
    - mix.exs
    - test/partition_weights.txt
key-decisions:
  - "Keep the 0.11-only 0.12.0 preflight in a separate guide region, then map all 20 1.0 entries under exactly seven numbered steps."
  - "Select the 1.0 source scope from Unreleased during staging and the dated 1.0.0 section after release preparation."
patterns-established:
  - "Changelog contracts extract hidden IDs from top-level source bullets and reject missing, extra, duplicate, untagged, or cross-scope mappings before comparing sets."
requirements-completed: [DOCS-03]
coverage:
  - id: D1
    description: "A 0.11.x-only preflight and seven shared steps provide a complete 1.0 upgrade procedure with one actionable mapping for each scoped changelog item."
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/threadline/upgrading_to_1_0_doc_contract_test.exs"
        status: pass
      - kind: integration
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mutation controls and the complete partition inventory protect both change-ID scopes and the new test weight."
    verification:
      - kind: unit
        ref: "mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/guide_graph_contract_test.exs"
        status: pass
      - kind: unit
        ref: "mix verify.format"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-10-07
status: complete
---

# Phase 237 Plan 01: 1.0 Adopter Guide and Change Contract Summary

**0.11.x and 0.12.x adopters now have one seven-step 1.0 procedure, with each human-owned breaking change and deprecation checked against a hidden guide ID.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-10-07T20:07:46Z
- **Completed:** 2026-10-07T20:17:49Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Wrote the conditional preflight for the three 0.12.0 changes, followed by exactly seven numbered 1.0 steps. The guide distinguishes `AuditTransaction` as one database transaction from `AuditAction` as a semantic event, explains that action association changes affect exploration hydration, and states the `action_id` column and foreign key remain unchanged.
- Added 20 stable hidden IDs to the 1.0 breaking and deprecation entries and three separate IDs to the 0.12.0 prerequisites. The contract checks each source bullet once, exact unique sets, ordered headings, the no-trigger-regeneration statement, and both current Unreleased and future dated 1.0.0 changelog scopes.
- Registered the guide in ExDoc and the Adopt graph, routed the upgrade path to it, and assigned the test a sorted partition weight of 4.

## Task Commits

1. **Task 1: Publish the complete guide with an end-to-end changelog contract** — `d1ff1d02` (`feat`)
2. **Task 2: Make the change-map contract mutation-resistant and partitioned** — `8dc5556d` (`test`)

## Files Created/Modified

- `guides/upgrading-to-1.0.md` — conditional preflight and seven shared migration steps.
- `CHANGELOG.md` — hidden IDs attached to the 12 Unreleased breaks, eight deprecations, and three 0.12.0 breaks.
- `guides/upgrade-path.md` — route from the 0.12.x jump to the complete 1.0 guide.
- `test/threadline/upgrading_to_1_0_doc_contract_test.exs` — source/guide mapping, scope, ordering, and mutation contracts.
- `test/threadline/guide_graph_contract_test.exs` — Adopt registration and route validation for the new guide.
- `mix.exs` — ExDoc extra registration.
- `test/partition_weights.txt` — explicit weight for the new contract.

## Decisions Made

- The 0.11.x preflight remains separate from the seven 1.0 steps so 0.12.x adopters can skip it cleanly.
- The change-map extractor follows the Unreleased staging section until a dated `[1.0.0]` section exists, then selects that release block.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Routed the detailed upgrade guide through the existing upgrade-path guide graph**
- **Found during:** Task 1 (guide graph verification)
- **Issue:** Adding the guide to the Adopt lane exposed graph assumptions tied to the previous 23-guide count and required a non-README inbound route plus a return path.
- **Fix:** Updated the graph count to 24, used `guides/upgrade-path.md` as the detailed guide's inbound route, and added the guide's `Next steps` links back to the Adopt landing and its successor.
- **Files modified:** `test/threadline/guide_graph_contract_test.exs`, `guides/upgrade-path.md`, `guides/upgrading-to-1.0.md`
- **Verification:** Focused guide graph contract passed.
- **Committed in:** `d1ff1d02`

**Total deviations:** 1 auto-fixed (Rule 3 - Blocking)
**Impact on plan:** The route preserves the existing intent graph while making the new upgrade guide reachable from the upgrade-path entry point.

## Verification

- `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/guide_graph_contract_test.exs` — 40 tests, 0 failures.
- `mix verify.format` — passed.
- `MIX_ENV=dev mix docs --warnings-as-errors` — passed; HTML, Markdown, and EPUB documentation generated without warnings.

REL-02's milestone-wide `git log --grep="BREAKING CHANGE"` reconciliation remains for the later Phase 237 audit plan; this plan covers the documented Unreleased and 0.12.0 source entries.

## Issues Encountered

The first ExDoc run found warnings for references to hidden Query functions. The guide now describes those deprecated calls without creating links to hidden API docs; warning-free ExDoc passed after that correction. The repository's state and roadmap handlers did not recognize its custom plan-position and phase-list formats, so those two sequence markers were updated by hand in line with the repository instructions; the numeric progress summary already reflected this plan.

## User Setup Required

None.

## Next Phase Readiness

Plan 237-01 is complete. The release rehearsal and milestone-history audit remain separate phase work; REL-02 should stay open until the full history cross-check is recorded.

## Self-Check: PASSED

- All seven plan-owned files are present.
- Task commits `d1ff1d02` and `8dc5556d` are ancestors of the current HEAD.
- Stub scan found no placeholder implementation or incomplete migration guidance.

---
*Phase: 237-upgrade-guide-and-1-0-0*
*Completed: 2026-10-07*
