---
phase: 181-baseline-audit-and-guard-repair
plan: 03
title: Stale Operator E2E Contract Repair
status: complete
date_completed: 2026-06-26T14:41:51Z
requirements: [BASE-01, BASE-02]
subsystem: operator-browser-guards
tags: [e2e, playwright, guard-repair, baseline-audit]
dependency_graph:
  requires: [181-02]
  provides: [current-operator-e2e-contracts, guard-repair-evidence]
  affects: [examples/threadline_phoenix/e2e, 181-GUARD-REPAIR]
tech_stack:
  added: []
  patterns:
    - Playwright route discovery with stable table filter and data-testids
    - Current support Coverage denied-state alert copy assertions
key_files:
  created:
    - .planning/phases/181-baseline-audit-and-guard-repair/181-03-SUMMARY.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
    - .planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md
decisions:
  - "Replace stale issue-number/correlation E2E contracts with current `ticket_replies` table-filter discovery, transaction href navigation, row-history redaction, and DELETE-row actor transaction checks."
  - "Keep out-of-plan stale browser families recorded as residual ledger ownership instead of editing files outside the Plan 03 file contract."
metrics:
  duration_seconds: 1028
  tasks_completed: 1
  files_modified: 3
  task_commit: 8227131
---

# Phase 181 Plan 03: Stale Operator E2E Contract Repair Summary

Stale operator browser guards now assert current `ticket_replies` discovery, transaction navigation, row-history redaction, DELETE-row behavior, and support Coverage denied-state copy.

## Completed Tasks

| Task | Status | Commit | Notes |
|---|---|---|---|
| Task 1: Repair stale E2E selectors and browser guard prose | Complete with residual precommit failures documented | `8227131` | Repaired the declared Playwright files and updated `181-GUARD-REPAIR.md` with replacement contracts and residual ownership. |

## What Changed

- Replaced stale `walk-acme-4521-close`, `#4521`, and `#4518` browser assumptions in the target E2E specs with current `ticket_replies` table-filter discovery.
- Strengthened transaction and row-history assertions to require stable URL/testid behavior plus rendered `[REDACTED]` evidence.
- Replaced the removed support Coverage copy assertion with the current `Coverage unavailable` alert and `mix threadline.health.coverage` fallback.
- Added Plan 03 repair evidence to `181-GUARD-REPAIR.md`, including residual ownership for adjacent stale E2E families outside the declared file list.

## Verification

| Command | Result | Evidence |
|---|---|---|
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator.spec.ts tests/operator-screenshots.spec.ts` | Passed | 18/18 Playwright tests passed across `chromium`, `desktop-chromium`, and `mobile-chromium`. |
| `cd examples/threadline_phoenix && mix precommit` | Failed, residual documented | 96 ExUnit tests ran with 7 inherited demo-seed contract failures around old `#4521`/`#4518` May anchors, `agent2` window rows, and `org_memberships` actor attribution. These files were not edited by Plan 03. |
| `rg -n "repair-now" .planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md` | Passed | Command returns the expected repair ledger rows, including Plan 03 ownership and later Plan 04 rows. |
| `git diff --check` | Passed | No whitespace errors before task commit. |

## Deviations from Plan

### Auto-fixed Issues

None - no directly caused implementation bugs required extra repair.

### Residual Issues

**1. Example app `mix precommit` remains red outside Plan 03 files**
- **Found during:** Task 1 verification
- **Issue:** `mix precommit` failed in Elixir demo/walkthrough contract tests that still expect old `#4521`/`#4518` May anchor rows and related seeded actor/window data.
- **Disposition:** Deferred as out of scope for this E2E selector plan; recorded in `181-GUARD-REPAIR.md` under Plan 03 residual verification.
- **Files not changed:** `test/threadline_phoenix/demo_contract_test.exs`, `test/threadline_phoenix_web/walkthrough_evidence_test.exs`, `test/threadline_phoenix_web/walkthrough_happy_path_test.exs`

## Auth Gates

None.

## Known Stubs

None. Stub-pattern scan only matched historical stale copy strings preserved as guard-ledger evidence; no created or modified runtime/UI stub blocks were found.

## Threat Flags

None. The plan changed browser tests and planning evidence only; it introduced no new endpoints, auth paths, file access patterns, schema changes, dependencies, route paths, feature gates, public APIs, or capture/query/auth semantics.

## Self-Check: PASSED

- Found `examples/threadline_phoenix/e2e/tests/operator.spec.ts`
- Found `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts`
- Found `.planning/phases/181-baseline-audit-and-guard-repair/181-GUARD-REPAIR.md`
- Found task commit `8227131`
- No tracked file deletions in task commit
