---
phase: "249-map-jobs-scenarios-and-the-brand-contract"
plan: "03"
subsystem: demo-seeds
tags: [elixir, phoenix, ecto, postgresql, audit-capture, fixture-data]

requires:
  - phase: "249-map-jobs-scenarios-and-the-brand-contract"
    provides:
      - "Plan 02 fixed demo calendar, deterministic identities, and retention boundary"
provides:
  - "Seed-internal timestamp helpers and coherent original row snapshots for ordinary stories"
  - "One run clock for current-window seed rows and export expiry"
  - "Focused contracts for setup, hero, actor-window, current-story, filler, export, and retention boundaries"
affects: [249-04-scenario-catalog, demo-seed-contracts]

actuals:
  tokens: null
  tasks: 3
  commits: 7
  plan_head_before: f89f051cbba4048860c23e1ec8cf8cef5435e9d7
  plan_head_after: ed1d87a98bdf20590a3b97d5049f13b3ca5d68f0

tech-stack:
  added: []
  patterns:
    - "Apply represented business timestamps to seed changesets before Repo writes."
    - "Keep transaction IDs and event times in the seed context for the existing Temporal pass."
key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs

key-decisions:
  - "Use force_change for seed updated_at values so equal-to-current timestamps are not replaced by Ecto's automatic update timestamp."
  - "Repair missing ticket assignees inside seed changesets; keep public HelpDesk casts and schema unchanged."
  - "Keep physical action recording time separate from represented business/event time."
requirements-completed: []
requirements-addressed: [ADM-06, ADM-07]
coverage:
  - id: D1
    description: "#4521 has setup and close snapshots at their represented instants, with redaction and semantic identity preserved."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs##4521 row and reply snapshots match the represented close event"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#close reply insert is redacted on #4521"
        status: pass
    human_judgment: false
  - id: D2
    description: "Setup snapshots, #4518 reply/close then deletion, and the twelve agent2 events retain exact chronology and actors."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#organization, user, membership, agent and base ticket writes use setup S"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs##4518 closes with a reply before the later capture-only deletion"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#all twelve agent2 close snapshots match their events and agent3 owns the earlier role change"
        status: pass
    human_judgment: false
  - id: D3
    description: "Globex, current-window stories, ordinary Acme/Globex filler, and exports use coherent pre-write timestamps and the single seed-run clock."
    requirement: ADM-06
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#reply and ticket close snapshots match the represented days-ago event"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#each story preserves its single run clock, operation order, actor and row snapshots"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#Acme and Globex filler insert/update/delete histories share each event instant"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#completed downloadable export bytes contain the exact corrected captured_at"
        status: pass
    human_judgment: false
  - id: D4
    description: "Offboarded Co remains the distinct 90-day fixture, with the strict 21 < 60 < 90 cutoff invariant, other-organization survival, and a purged-empty audit scope."
    requirement: ADM-07
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#offboarded-co audit footprint purged with manifest retention evidence"
        status: pass
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs#double demo.reset keeps heroes and semantic fingerprint stable"
        status: pass
      - kind: other
        ref: "examples/threadline_phoenix: mix compile --warnings-as-errors (compile-time strict cutoff invariant)"
        status: pass
    human_judgment: false

duration: null
completed: "2026-11-11"
status: complete
summary-authored: "2026-11-12 02:44:50 UTC"
---

# Phase 249 Plan 03: Map jobs, scenarios and the brand contract Summary

**Seeded ticket and reply snapshots now retain their represented times across setup, hero incidents, current-window stories and ordinary Acme/Globex filler, while physical action recording and retention boundaries remain distinct.**

## Performance

- **Plan duration:** Not recorded in this worktree; the parent will reconcile terminal timing from the managed launch receipt.
- **Summary authored:** 2026-11-12 02:44:50 UTC
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added seed-only timestamp and reply/close helpers, stamped original rows before trigger capture, and retained the existing transaction-ID timestamp map.
- Corrected setup, #4521, #4518, the agent2 close window, Globex, current-window stories, and ordinary filler histories; export insertion and expiry now share one seed-run clock.
- Added exact row-snapshot, event-order, actor, assignee, export-expiry, redaction, reset-stability, and retention assertions. Public schemas, HelpDesk casts/signatures, and runtime clock behavior remain unchanged.

## Task Commits

1. **Task 1 RED** — b84003ae (test(249-03): assert #4521 captured timestamp chronology)
2. **Task 1 GREEN** — f171e5c6 (feat(249-03): stamp #4521 rows before trigger capture)
3. **Task 2 RED** — 21c0224b (test(249-03): assert setup and #4518 timestamp chronology)
4. **Task 2 GREEN** — fc66cee2 (feat(249-03): align seed setup and actor timelines)
5. **Task 3 RED** — b6e9f686 (test(249-03): assert ordinary event snapshot timelines)
6. **Task 3 GREEN** — aca8c761 (feat(249-03): align ordinary seed snapshots to event clocks)
7. **Task 3 verification** — ed1d87a9 (test(249-03): assert export run-clock expiry)

## Files Created/Modified

- examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex — Captures one second-precision run clock for the existing seed pipeline.
- examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex — Stamps existing timestamp fields before writes, preserves equal update timestamps, and groups seed-only reply/close writes.
- examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex — Aligns setup rows to S.
- examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex — Aligns hero, active-window, and current-story writes to their represented events.
- examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex — Uses one represented timestamp for filler insert and update/delete snapshots.
- examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex — Uses the run clock for export insertion and downloadable expiry.
- examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs — Covers source snapshots, event sequences, actors, identities, and retention boundaries.

## Decisions Made

- Timestamp existing schema fields before Repo writes; do not rewrite captured row JSON after the fact.
- Use one run clock for current-window offsets and export expiry, while keeping named epoch-relative fixtures explicit.
- Set ticket assignees inside seed changesets because the runtime Ticket changeset does not cast that field; no public cast or schema change was needed.
- Force updated_at in the seed helper when it equals the stored value, so the represented time survives Ecto's automatic timestamping.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve assignee_id in seed writes**

- **Found during:** Task 3
- **Issue:** The existing public Ticket changeset omits assignee_id from its casts, so seed inserts and reassignment silently left tickets unassigned.
- **Fix:** Apply assignee_id directly to the seed changeset with put_change; keep the runtime API unchanged.
- **Files modified:** anchors.ex, filler.ex, demo_contract_test.exs
- **Verification:** The full plan-focused example suite passed with assignee snapshot and final-row assertions.
- **Committed in:** aca8c761

**2. [Rule 1 - Bug] Keep same-instant filler updated_at values**

- **Found during:** Task 3
- **Issue:** When the update's represented timestamp equaled the ticket's just-inserted timestamp, Ecto removed the equal put_change and substituted wall-clock updated_at.
- **Fix:** Use force_change for the existing updated_at schema field in the seed-only update helper.
- **Files modified:** support.ex, demo_contract_test.exs
- **Verification:** Acme and Globex filler snapshot contract and the full plan-focused example suite passed.
- **Committed in:** aca8c761

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs).  
**Impact on plan:** Both fixes correct seed-only state that contradicted the planned scenario; no public surface or schema scope changed.

## Issues Encountered

All task3 contract failures were diagnosed and corrected. The final focused suite passes. ExUnit output includes shape-fixture module redefinition warnings; the suite exit was successful.

## Proof Limits

- The ADM-06 edge probe still classifies the broader spec-less autonomous-recall and descriptorless flagged-unverified intent claims as unresolved. These tests establish only the named snapshot, actor, and chronology facts; Plan 04 owns the independent review of that broader boundary.
- No root-wide, canonical, browser, hosted, or release checks were run; the authorized evidence is the focused example contract suite and example-owned format/compile checks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Ready for Plan 249-04 with deterministic seed-clock and capture-boundary evidence. Preserve the ADM-06 proof limitation above during the independent review.

## Self-Check: PASSED

- All seven plan-owned source/test files exist; no generated stubs were introduced.
- All seven task commits are ancestors of this worktree HEAD, and the evaluation-scope query resolved all seven plan commits.
- Final plan verification passed: focused example command reported 26 tests, 0 failures; example formatting and warnings-as-errors compilation passed.
- Worktree branch, root, clean diff, and planning artifact ownership checks passed; STATE.md, ROADMAP.md, and REQUIREMENTS.md were not modified.

---
*Phase: 249-map-jobs-scenarios-and-the-brand-contract*
*Completed: 2026-11-11*

