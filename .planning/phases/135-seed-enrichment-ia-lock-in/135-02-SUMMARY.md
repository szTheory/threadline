---
phase: 135-seed-enrichment-ia-lock-in
plan: "02"
subsystem: docs-and-test
tags: [ia-lock, doc-contract, personas, jtbd, earned-flows]
dependency_graph:
  requires: []
  provides:
    - "Locked v1.31-PERSONAS-IA.md with EF1–EF5 earned-flow IDs (D-15/D-16/D-19)"
    - "One-line IA pointer in v1.31-UI-AUDIT.md (D-17)"
    - "ia_lock_doc_contract_test.exs: 6-assertion lock test (D-18)"
  affects:
    - ".planning/milestones/v1.31-PERSONAS-IA.md"
    - ".planning/milestones/v1.31-UI-AUDIT.md"
    - "test/threadline/ia_lock_doc_contract_test.exs"
tech_stack:
  added: []
  patterns:
    - "ExUnit doc-contract test (async: true, Path.expand, String.contains? per-literal loop)"
key_files:
  created:
    - "test/threadline/ia_lock_doc_contract_test.exs"
  modified:
    - ".planning/milestones/v1.31-PERSONAS-IA.md"
    - ".planning/milestones/v1.31-UI-AUDIT.md"
decisions:
  - "D-15: Lock status header added to PERSONAS-IA.md; no fork into UI-AUDIT.md"
  - "D-16: EF1–EF5 earned-flow table written with finding→JTBD→persona→flow trace"
  - "D-17: One-line pointer added to UI-AUDIT.md immediately after Status line"
  - "D-18: 6-test doc-contract test locks all IDs + pointer; passes mix verify.test"
  - "D-19: J1–J11 confirmed correct; no J1–J10 wording present"
metrics:
  duration: "2m"
  completed_date: "2026-06-03"
  tasks_completed: 2
  files_modified: 3
---

# Phase 135 Plan 02: IA Lock-In Summary

Locked the persona/JTBD/IA decisions into one authoritative source by writing EF1–EF5 earned-flow IDs into `v1.31-PERSONAS-IA.md`, adding a Phase 135 lock status header, placing a one-line IA pointer in `v1.31-UI-AUDIT.md`, and backing the whole lock with a 6-assertion doc-contract test that survives a context clear.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Lock PERSONAS-IA.md (status header + EF1–EF5 + J1–J11 reconcile) + UI-AUDIT pointer | 9818fd2 | v1.31-PERSONAS-IA.md, v1.31-UI-AUDIT.md |
| 2 | Add IA-lock doc-contract test (D-18) | 9adf353, 755b29d | test/threadline/ia_lock_doc_contract_test.exs |

## What Was Built

### Task 1 — PERSONAS-IA.md locked

- Added `**Status:** Locked by Phase 135 (2026-06-03). IDs P1–P5 / J1–J11 / EF1–EF5 are stable; per-screen phases (137–143) cite from here.` after the opening paragraph.
- Added `## Earned Flows (EF1–EF5)` section with a table binding each EF to its flow name, JTBD, persona, and audit finding(s):
  - EF1: Record-first cordoned path → J4/P2 → F-1001 (Phase 140)
  - EF2: First-class row-history entry → J2/P1 → F-1003 (138/140)
  - EF3: Close the export loop → J6/P3 → F-602, F-1002 (140)
  - EF4: Correlation-id paste/deep-link on Home → J1/P1 → F-1001 (140)
  - EF5: Prove-group separator before Exports (+ optional Verify→Trust card label) → P3 IA → F-105, F-304 (139)
- Verified J1–J11 all present, no "J1–J10" wording.
- Added one-line pointer to `v1.31-UI-AUDIT.md` immediately after the Status line referencing P1–P5, J1–J11, EF1–EF5 per D-17.

### Task 2 — Doc-contract test

Created `Threadline.IaLockDocContractTest` (`async: true`) with 6 tests:
1. Asserts all persona IDs P1–P5 present in PERSONAS-IA.md
2. Asserts all JTBD IDs J1–J11 present in PERSONAS-IA.md
3. Asserts all earned flow IDs EF1–EF5 present in PERSONAS-IA.md
4. Asserts Find/Verify/Prove triad present (spaced variant)
5. Asserts "Locked by Phase 135" lock status header present
6. Asserts v1.31-UI-AUDIT.md contains pointer referencing "v1.31-PERSONAS-IA.md", "P1–P5", and "EF1–EF5"

All 6 tests green. `mix verify.test`: 757 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Format failure: blank line before assert**
- **Found during:** Task 2 verification (`mix verify.format`)
- **Issue:** `mix format` required a blank line before the `assert` in the `carries the Phase 135 lock status header` test
- **Fix:** Ran `mix format` and committed the one-line whitespace fix
- **Files modified:** `test/threadline/ia_lock_doc_contract_test.exs`
- **Commit:** 755b29d

## Known Stubs

None. This plan is docs + a read-only test. No data stubs or placeholder content.

## Threat Flags

None. This plan edits planning markdown and adds a read-only doc-contract test. No runtime code, no input handling, no network/DB writes.

## Self-Check: PASSED

Files created/exist:
- FOUND: `.planning/milestones/v1.31-PERSONAS-IA.md` (modified)
- FOUND: `.planning/milestones/v1.31-UI-AUDIT.md` (modified)
- FOUND: `test/threadline/ia_lock_doc_contract_test.exs` (created)

Commits:
- FOUND: 9818fd2
- FOUND: 9adf353
- FOUND: 755b29d
