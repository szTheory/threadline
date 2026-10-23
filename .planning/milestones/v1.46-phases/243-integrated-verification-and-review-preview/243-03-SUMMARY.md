---
phase: 243-integrated-verification-and-review-preview
plan: "03"
subsystem: testing
tags: [phoenix, playwright, postgres, e2e, local-preview]
requires:
  - phase: 243-integrated-verification-and-review-preview
    provides: Candidate-bound receipt and evidence runner from Plan 02
provides:
  - Allowlisted local preview receipt bound to candidate, fixture, process, database, routes and exact served assets
  - Guarded localhost preview start, stop and fresh-partition reopen lifecycle
affects: [phase-243, operator-preview, e2e-evidence]
actuals:
  tokens: 10154
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [Detached local Phoenix VM with owned log, listener-PID receipt, process/database-bound stop guard]
key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-preview-receipt.ts
    - examples/threadline_phoenix/e2e/support/operator-preview-receipt.test.ts
  modified:
    - examples/threadline_phoenix/e2e/run-e2e.sh
    - test/threadline/e2e_preflight_contract_test.exs
key-decisions:
  - "Receipt PID is the live beam.smp process that owns the exact loopback listener; the launcher detaches it with stdin closed and all output redirected to a partition-owned log."
patterns-established:
  - "Preview receipts expose only bounded candidate, fixture, route, process, database and asset identities."
  - "Guarded stop revalidates unchanged receipt bytes and live process/listener/PostgreSQL ownership before signaling."
requirements-completed: [UIV-03]
coverage:
  - id: D1
    description: Candidate-bound receipt rejects forged identity and unsafe stop requests without signaling.
    requirement: UIV-03
    verification:
      - kind: unit
        ref: examples/threadline_phoenix/e2e/support/operator-preview-receipt.test.ts
        status: pass
      - kind: unit
        ref: test/threadline/e2e_preflight_contract_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Local preview proves login redirect, eleven authenticated deep links, LiveView, exact served assets, owned stop and fresh reopen.
    requirement: UIV-03
    verification:
      - kind: e2e
        ref: THREADLINE_E2E_LIVE_PREVIEW=1 ./node_modules/.bin/tsx --test support/operator-preview-receipt.test.ts
        status: pass
    human_judgment: false
plan_head_before: eeb3474ab5824b3a71e628ae3bc5d37619d4b550
plan_head_after: 6fcaee6cd6fb3eae8b50df85b122b2484a85c3d4
commits: 3
duration: 17min
completed: 2026-10-10
status: complete
---

# Phase 243 Plan 03: Guarded Phoenix Preview Summary

The localhost preview now proves the current Phase 243 candidate through a persistent listener-owning Elixir VM, authenticated operator routes, exact served asset hashes and a guarded fresh-partition reopen.

## Performance

- **Duration:** 17 min
- **Started:** 2026-10-10T23:30:00-04:00
- **Completed:** 2026-10-10T23:47:00-04:00
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added strict preview receipts bound to the candidate receipt, relevant diff, synthetic fixture, loopback URL, process, database, route probes and served/local JS/CSS hashes.
- Made the runner detach the Phoenix VM into a new session with stdin closed and stdout/stderr redirected to a partition-owned log; it now records the actual `beam.smp` listener PID.
- Verified the real start, login redirect, eleven authenticated deep links, LiveView connection, exact assets, guarded stop and fresh reopen on two new synthetic partitions. The completed run used `operator_243prev_1791690408393_19009_a` and `_b`; both were bound to candidate `6fcaee6c` and used `127.0.0.1` on independently selected ports.
- Retained earlier rejected preview receipts and their evidence runs. The rejected ownership check sent no signal.

## Task Commits

1. **Task 1: Bind guarded preview lifecycle to the Phase 243 candidate and served assets** — `3b24250c` (test)
2. **Task 1: Implement candidate-bound preview receipt and safety guards** — `1888c8a2` (feat)
3. **Task 2: Exercise real preview login, assets, stop and fresh reopen** — `6fcaee6c` (test)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/support/operator-preview-receipt.ts` — receipt schema, browser proof and guarded process stop.
- `examples/threadline_phoenix/e2e/support/operator-preview-receipt.test.ts` — negative controls and live two-partition lifecycle.
- `examples/threadline_phoenix/e2e/run-e2e.sh` — candidate preview launch, listener ownership and lifecycle integration.
- `test/threadline/e2e_preflight_contract_test.exs` — runner and preview safety contracts.

## Decisions Made

- Keep preview state in a narrow temporary receipt allowlist and persist no credentials, cookies, storage state, response bodies or arbitrary environment values.
- Treat the listener-owning `beam.smp` PID as the process identity and require its example-app cwd, exact loopback listener and PostgreSQL client database to agree before signaling.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Ignore non-success asset responses and normalize seeded deep-link paths**
- **Found during:** Task 2
- **Issue:** Redirect asset responses have no readable response body, and route fixtures can provide absolute URLs where the receipt requires paths.
- **Fix:** Capture only successful CSS/JavaScript responses and normalize all probed routes to pathname form.
- **Files modified:** `examples/threadline_phoenix/e2e/support/operator-preview-receipt.ts`
- **Verification:** Live preview lifecycle passed.
- **Committed in:** `6fcaee6c`

**2. [Rule 1 - Bug] Match the example-app cwd and preserve the real listener process after launcher exit**
- **Found during:** Task 2
- **Issue:** The stop guard compared the example-app process cwd to the repository root, while the shell launcher did not guarantee the VM survived its exit or record the listener-owning VM PID.
- **Fix:** Compare against the contained Phoenix example path, launch the VM in a detached session with all standard streams redirected to its owned log, and resolve/validate the unique `beam.smp` PID owning the preview listener.
- **Files modified:** `examples/threadline_phoenix/e2e/run-e2e.sh`, `examples/threadline_phoenix/e2e/support/operator-preview-receipt.ts`, `examples/threadline_phoenix/e2e/support/operator-preview-receipt.test.ts`
- **Verification:** The test confirmed the VM and exact listener remained alive after `run-e2e.sh` exited; guarded stop and fresh reopen passed.
- **Committed in:** `6fcaee6c`

**Total deviations:** 2 auto-fixed bugs. All were required to complete and safely verify the planned lifecycle.

## Issues Encountered

The first lifecycle attempts rejected unsafe process ownership before sending a signal; those receipts and evidence runs were retained. A subsequent live retry passed after correcting the cwd comparison and detaching the listener-owning VM.

## User Setup Required

None.

## Next Phase Readiness

Plan 04 can perform the bounded visual review while preserving the guarded local preview and candidate identity. The final evidence index should be refreshed after later candidate edits, as planned.

---
*Phase: 243-integrated-verification-and-review-preview*
*Completed: 2026-10-10*

## Self-Check: PASSED

The summary exists and task commits `3b24250c`, `1888c8a2` and `6fcaee6c` are ancestors of the current HEAD. Stub scan found only normal empty shell-variable initialization; no deliverable stub blocks the preview lifecycle.
