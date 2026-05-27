---
phase: 106-sigra-auth-lane-in-reference-app
plan: 03
subsystem: auth
tags: [sigra, phoenix, conn-case, help-desk, audit-capture, testing]

requires:
  - phase: 106-sigra-auth-lane-in-reference-app
    plan: 02
    provides: OperatorUser scope bridge and operator_browser pipeline on /audit
provides:
  - login_via_sigra/2 ConnCase helper (HTTP and session modes)
  - Operator surface tests using real Sigra login
  - help_desk_audit_http_test.exs HTTP capture proof
  - Dev-only HelpDeskDevController ticket_reply route
affects: [107-realistic-seed-data-demo-mix-tasks, 108-walkthrough-script]

tech-stack:
  added: []
  patterns:
    - "login_via_sigra default :http POST /users/log_in through browser plugs"
    - "HTTP audit proof via dev_routes + unboxed_run when fixtures precede capture"
    - "auth_fixtures user_fixture confirms email and uses password123456"

key-files:
  created:
    - examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_http_test.exs
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/help_desk_dev_controller.ex
  modified:
    - examples/threadline_phoenix/test/support/conn_case.ex
    - examples/threadline_phoenix/test/support/fixtures/auth_fixtures.ex
    - examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/config/test.exs

key-decisions:
  - "help_desk_audit_http_test runs inside Sandbox.unboxed_run/2 so HelpDesk capture is not the first write in the sandbox transaction (fixture inserts reuse audit_transactions rows without actor_ref)"
  - "Dev route gated by dev_routes compile_env; enabled in config/test.exs for ConnCase proof"
  - "HelpDeskDevController falls back to ActorRef from current_user when Sigra.actor_ref_from_conn returns nil"

patterns-established:
  - "Browser tests authenticate with login_via_sigra/2; API tests keep sigra_conn/2; DataCase keeps explicit AuditContext"
  - "Zero assign(:current_user) in examples/threadline_phoenix/test/"

requirements-completed: [AUTH-04]

duration: 4min
completed: 2026-05-27
---

# Phase 106 Plan 03: Real Session Tests and HTTP Audit Proof Summary

**ConnCase `login_via_sigra/2` replaces faked browser assigns, operator surface tests use real Sigra HTTP login with UUID org scoping, and a dev-only help-desk route proves `actor_ref` capture from the browser pipeline.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-27T16:23:32Z
- **Completed:** 2026-05-27T16:27:36Z
- **Tasks:** 4
- **Files modified:** 7

## Accomplishments

- Added `login_via_sigra/2` to ConnCase with default `:http` mode and optional `:session` fast path
- Migrated `operator_surface_test.exs` off `assign(:current_user)` to fixtures + `login_via_sigra`; added agent-only 403 audit gate test
- Shipped dev-only `POST /dev/help_desk/ticket_reply` and `help_desk_audit_http_test.exs` proving Sigra session → `actor_ref` on capture
- Full example-app regression green: 27 tests, `mix verify.example` passes, no `assign(:current_user` in test tree

## Task Commits

Each task was committed atomically:

1. **Task 1: login_via_sigra/2 in ConnCase** - `8c3e372` (feat)
2. **Task 2: Migrate operator_surface_test.exs** - `90eded2` (feat)
3. **Task 3: help_desk_audit_http_test + minimal capture route** - `20d9916` (feat)
4. **Task 4: Full regression + verify.example** - (verification only, no commit)

## Files Created/Modified

- `examples/threadline_phoenix/test/support/conn_case.ex` - `login_via_sigra/2`, verified routes import for HTTP login
- `examples/threadline_phoenix/test/support/fixtures/auth_fixtures.ex` - `confirmed_at` on `user_fixture/1`, password `password123456`
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` - real auth for admin/support/agent scenarios
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/help_desk_dev_controller.ex` - dev capture proof endpoint
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - dev route under `dev_routes`
- `examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_http_test.exs` - HTTP actor_ref proof
- `examples/threadline_phoenix/config/test.exs` - `dev_routes: true`

## Decisions Made

- HTTP audit proof test uses `Sandbox.unboxed_run/2` for the full test body (same capture-honesty pattern as `help_desk_audit_test.exs`) because help-desk fixture inserts create an `audit_transactions` row in the sandbox transaction before `set_config` runs
- `dev_routes` enabled in test config only; route not exposed without compile_env gate
- Operator surface tests use UUID `to_string(org.id)` for post meta scoping, not slug strings

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ConnCase could not compile login_via_sigra HTTP path**
- **Found during:** Task 2 verification (`mix test operator_surface_test.exs`)
- **Issue:** `post/3` and `~p` unavailable in ConnCase module body (only in `using` block)
- **Fix:** Added `use ThreadlinePhoenixWeb, :verified_routes` and `import Phoenix.ConnTest` to ConnCase
- **Files modified:** `test/support/conn_case.ex`
- **Verification:** `mix test test/threadline_phoenix_web/operator_surface_test.exs` passes
- **Committed in:** `90eded2`

**2. [Rule 3 - Blocking] HTTP audit test saw NULL actor_ref due to sandbox txid reuse**
- **Found during:** Task 3 verification (`help_desk_audit_http_test.exs`)
- **Issue:** Fixture inserts on audited tables create `audit_transactions` for the sandbox transaction before HelpDesk `set_config`; trigger `ON CONFLICT DO NOTHING` reuses row without updating `actor_ref`
- **Fix:** Wrap entire HTTP proof test in `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` (matches Phase 105 DataCase pattern)
- **Files modified:** `test/threadline_phoenix/help_desk_audit_http_test.exs`
- **Verification:** `mix test test/threadline_phoenix/help_desk_audit_http_test.exs` passes
- **Committed in:** `20d9916`

**3. [Rule 2 - Missing Critical] auth_fixtures alignment for HTTP login**
- **Found during:** Task 1 (plan required confirmed users + password alignment)
- **Issue:** `user_fixture/1` left `confirmed_at` nil; default password differed from `login_via_sigra` default
- **Fix:** Confirm user after register; set `valid_user_password` to `password123456`
- **Files modified:** `test/support/fixtures/auth_fixtures.ex`
- **Verification:** operator and HTTP tests login without mailbox
- **Committed in:** `8c3e372`

**4. [Rule 1 - Bug] HelpDeskDevController actor_ref fallback**
- **Found during:** Task 3 debugging
- **Issue:** Defensive fallback when `Sigra.actor_ref_from_conn/1` returns nil but `current_user` is present
- **Fix:** `actor_ref_from_current_user/1` fallback in controller
- **Files modified:** `help_desk_dev_controller.ex`
- **Verification:** HTTP test passes with Sigra + OperatorUser assigns
- **Committed in:** `20d9916`

---

**Total deviations:** 4 auto-fixed (2 bugs, 1 blocking, 1 missing critical)
**Impact on plan:** AUTH-04 delivered; patterns align with Phase 105 unboxed capture proofs. No scope creep.

## Issues Encountered

None beyond deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 106 complete (plans 01–03); all AUTH-01–AUTH-04 requirements satisfied on current tree
- Ready for Phase 107 (`demo.seed` / `demo.reset`) with real Sigra users and provision helper
- API tests unchanged (`sigra_conn/2`); `help_desk_audit_test.exs` DataCase unchanged

## Self-Check: PASSED

- `cd examples/threadline_phoenix && mix test` — 27 tests, 0 failures
- `cd ../.. && mix verify.example` — passes
- `! rg 'assign\(:current_user' examples/threadline_phoenix/test/` — no matches
- `rg 'def login_via_sigra' examples/threadline_phoenix/test/support/conn_case.ex` — found
- `rg 'login_via_sigra' examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` — found
- `help_desk_audit_http_test.exs` exists and asserts `actor_ref` for logged-in user

---
*Phase: 106-sigra-auth-lane-in-reference-app*
*Completed: 2026-05-27*
