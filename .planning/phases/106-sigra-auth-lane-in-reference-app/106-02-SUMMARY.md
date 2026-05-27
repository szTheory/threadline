---
phase: 106-sigra-auth-lane-in-reference-app
plan: 02
subsystem: auth
tags: [sigra, operator-user, help-desk, phoenix, plugs]

requires:
  - phase: 106-sigra-auth-lane-in-reference-app
    plan: 01
    provides: Sigra sessions, registration provision, fetch_current_scope on browser pipeline
provides:
  - HelpDesk membership role and default-org lookup helpers
  - OperatorUser scope bridge with host is_admin allowlist and impersonation-safe desk role
  - operator_browser pipeline on /audit before operator_auth
  - Login safety-net provision when membership is missing
affects: [106-sigra-auth-lane-in-reference-app plan 03]

tech-stack:
  added: []
  patterns:
    - "Recompute current_user every request from current_scope + org_memberships"
    - "Impersonation: is_admin and desk role from impersonator only (D-106-02f)"
    - "organization_id from sigra_session.active_organization_id or HelpDesk default org UUID"

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/operator_user.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/plugs/assign_operator_user.ex
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/session_controller.ex
    - examples/threadline_phoenix/config/dev.exs
    - examples/threadline_phoenix/config/test.exs

key-decisions:
  - "Default org for multi-membership users is earliest by inserted_at (documented in HelpDesk moduledoc)"
  - "Skipped optional active_organization_id session write on login; OperatorUser falls back to HelpDesk.get_organization_id_for_user/1"
  - "my_authorize_fn, scope_operator_query, and lib/threadline left unchanged per scope guard"

patterns-established:
  - "pipe_through [:browser, :operator_browser, :operator_auth] on /audit scope"
  - "Host admin allowlist via config :threadline_phoenix, ThreadlinePhoenixWeb.OperatorUser"

requirements-completed: [AUTH-03]

duration: 1min
completed: 2026-05-27
---

# Phase 106 Plan 02: OperatorUser Scope Bridge Summary

**Sigra `current_scope` maps to help-desk-aware `current_user` via `OperatorUser`, with `/audit` wired through `:operator_browser` before unchanged authorize callbacks.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-27T16:21:09Z
- **Completed:** 2026-05-27T16:22:29Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added `HelpDesk.get_membership_role/2`, `get_default_organization_for_user/1`, and `get_organization_id_for_user/1`
- Shipped `ThreadlinePhoenixWeb.OperatorUser` and `Plugs.AssignOperatorUser` with host `admin_emails` / `admin_user_ids` config
- Wired `/audit` through `:operator_browser` before `:operator_auth`; login provisions workspace when membership is missing

## Task Commits

Each task was committed atomically:

1. **Task 1: HelpDesk membership helpers** - `b65213e` (feat)
2. **Task 2: OperatorUser module + AssignOperatorUser plug** - `2f7e6aa` (feat)
3. **Task 3: Router pipeline + login safety-net** - `2348720` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` - Membership role and default org resolution for OperatorUser
- `examples/threadline_phoenix/lib/threadline_phoenix_web/operator_user.ex` - `build_operator_user/2` and `assign_from_scope/2`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/plugs/assign_operator_user.ex` - Thin plug delegating to OperatorUser
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - `:operator_browser` pipeline on `/audit`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/session_controller.ex` - Idempotent provision on login
- `examples/threadline_phoenix/config/dev.exs`, `config/test.exs` - OperatorUser admin allowlist

## Decisions Made

- Multi-org users resolve default org by earliest `org_memberships.inserted_at`
- Did not set `user_sessions.active_organization_id` on login; session fallback uses HelpDesk default org UUID string
- Preserved `my_authorize_fn/1`, `my_export_authorize_fn/1`, and `scope_operator_query/3` bodies unchanged

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 03 (`login_via_sigra`, operator surface and HTTP audit proof tests)
- `/audit` receives `current_user` from Sigra scope when authenticated; agent role still 403 via existing `require_authenticated_operator`
- Operator surface tests still use faked assigns until Plan 03 migrates them

## Self-Check: PASSED

- `mix compile --warnings-as-errors` — success
- `mix test test/threadline_phoenix/help_desk_provision_test.exs` — 2 tests, 0 failures
- `help_desk.ex` contains `def get_membership_role(` and `def get_default_organization_for_user(`
- `operator_user.ex` contains `def build_operator_user(` and `def assign_from_scope(`; references `impersonating_from`
- `config/test.exs` contains `ThreadlinePhoenixWeb.OperatorUser`
- `router.ex` contains `pipeline :operator_browser`; `/audit` uses `:operator_browser` before `:operator_auth`
- `my_authorize_fn/1` body unchanged from pre-plan

---
*Phase: 106-sigra-auth-lane-in-reference-app*
*Completed: 2026-05-27*
