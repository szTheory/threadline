---
phase: 110-triage-narrow-fixes
plan: 01
subsystem: ui
tags: [phoenix, sigra, landing-page, heex, curl-smoke, ci]

requires:
  - phase: 109-maintainer-walkthrough-dry-run
    provides: finding 0001 filed from WALK-01-04 BadMapError
provides:
  - Nil-safe @current_scope guards on landing page for logged-out visitors
  - Finding 0001 closed with fixed_in SHA
  - L0 curl 200 smoke attestation for GET /
affects: [110-02, 110-03, validation-re-walk]

tech-stack:
  added: []
  patterns:
    - "Host-owned nil-safe current_scope in PageHTML before field access"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_html.ex
    - .planning/v1.23/findings/0001-landing-500-badmap.md
    - test/threadline/example_phoenix_readme_contract_test.exs

key-decisions:
  - "0001 fix stays in examples/ only — host Sigra wiring, zero lib/threadline commits"

patterns-established:
  - "Logged-out landing :if guards is_nil(@current_scope) before @current_scope.user"

requirements-completed: [FIX-01]

duration: 15min
completed: 2026-05-27
---

# Phase 110 Plan 01: Wave 1 — Finding 0001 Landing 500 Summary

**Nil-safe `@current_scope` on ThreadlinePhoenix landing page closes finding 0001; logged-out GET / returns 200**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-27T19:30:00Z
- **Completed:** 2026-05-27T19:45:00Z
- **Tasks:** 3 completed
- **Files modified:** 3

## Accomplishments

- Guarded `PageHTML.home/1` with `is_nil(@current_scope) or is_nil(@current_scope.user)` for Register/Log in block and `@current_scope && @current_scope.user` for signed-in block
- L0 smoke: `curl` to `http://localhost:4000/` returned `200` (no BadMapError in server log)
- Finding 0001 frontmatter updated to `status: fixed` with full `fixed_in` SHA
- L1 gate: `mix ci.all` passed at repo root

## Task Commits

Each task was committed atomically:

1. **Task 1: Ensure nil-safe landing template and commit** - `7b9e46b5b90c5da7f64c88ae539e8390f8734826` (fix)
2. **Task 2: L0 smoke — curl landing 200** - verification only (no commit; curl returned `200`)
3. **Task 3: Update finding 0001 and run L1 ci.all** - `93ad9b9` (Rule 3 deviation: contract test) + `9c2df32` (docs: close finding)

**Plan metadata:** `1c121f1` (docs: complete plan)

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_html.ex` - Nil-safe `@current_scope` guards on landing HEEx
- `.planning/v1.23/findings/0001-landing-500-badmap.md` - Closed finding with `fixed_in` SHA
- `test/threadline/example_phoenix_readme_contract_test.exs` - Aligned proof-artifact literal with 108-05 README copy (Rule 3 deviation)

## Decisions Made

- Followed D-110-04b: 0001 fix in `examples/threadline_phoenix/` only; no `lib/threadline/**` commits

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] README contract test drift from 108-05**
- **Found during:** Task 3 (Update finding 0001 and run L1 ci.all)
- **Issue:** `mix ci.all` failed — README says "runnable proof artifact behind both paths" but `example_phoenix_readme_contract_test.exs` still asserted "that path"
- **Fix:** Updated contract test assertion to match committed README copy
- **Files modified:** `test/threadline/example_phoenix_readme_contract_test.exs`
- **Verification:** `mix ci.all` exit 0 after fix
- **Committed in:** `93ad9b9`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required to satisfy Task 3 acceptance criteria (`mix ci.all` exit 0). No scope creep into WR-001/WR-002 or `lib/threadline/**`.

## Issues Encountered

- Stale Phase 109 walkthrough clone still served port 4000 with unfixed code (500). Killed old process and started workspace server before L0 curl.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Wave 1 complete; ready for plan 110-02 (WR-001/WR-002 filing and doc fixes)
- §1 gate unblocked on fix SHA — validation re-walk can resume from WALK-01-04 after Wave 2

## Self-Check: PASSED

- [x] `page_html.ex` contains `is_nil(@current_scope)`
- [x] Task 1 commit message cites finding 0001
- [x] curl HTTP status `200`
- [x] Finding 0001 `status: fixed` with 40-char `fixed_in`
- [x] `mix ci.all` exit 0

---
*Phase: 110-triage-narrow-fixes*
*Completed: 2026-05-27*
