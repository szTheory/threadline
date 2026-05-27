---
phase: 106-sigra-auth-lane-in-reference-app
plan: 01
subsystem: auth
tags: [sigra, phoenix, ecto, help-desk, registration]

requires:
  - phase: 105-help-desk-domain-expansion-in-reference-app
    provides: help-desk org/membership/agent schemas and fixtures
provides:
  - Sigra users table and Accounts context in the reference app
  - Phoenix HTML stack for controller-mode auth templates
  - Registration with help-desk workspace auto-provision
  - Home page with register/login and /audit links
affects: [106-sigra-auth-lane-in-reference-app plan 02, plan 03]

tech-stack:
  added: [sigra, gettext, swoosh, heroicons]
  patterns:
    - "Sigra install --no-organizations with help-desk tenancy"
    - "Explicit provision after register (not on_register hook)"
    - "Controller-mode HEEx with Layouts.app and core_components"

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix/accounts.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/user_auth.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/registration_controller.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/components/core_components.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_controller.ex
    - examples/threadline_phoenix/test/threadline_phoenix/help_desk_provision_test.exs
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/mix.exs
    - examples/threadline_phoenix/README.md

key-decisions:
  - "Provision help-desk org in RegistrationController after {:ok, user} because Sigra does not invoke on_register hooks"
  - "CLOAK_KEY set via config/dev.exs and config/test.exs for Vault (Sigra install requirement)"
  - "Dormant /users/settings/* routes added only for verified-route compile checks; return 404 in walkthrough"

patterns-established:
  - "Idempotent HelpDesk.provision_default_workspace_for_user/2 keyed by org_memberships (organization_id, user_id)"
  - "Sigra optional dep removed; {:sigra, \"~> 0.2\"} compiles unconditionally in the example app"

requirements-completed: [AUTH-01, AUTH-02]

duration: 18min
completed: 2026-05-27
---

# Phase 106 Plan 01: Sigra Auth Foundation Summary

**Sigra controller-mode auth with users migrations, Phoenix HTML bootstrap, registration that auto-provisions help-desk org membership, and a home page linking register/login and /audit.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-27T16:16:02Z
- **Completed:** 2026-05-27T16:34:00Z
- **Tasks:** 4
- **Files modified:** 49

## Accomplishments

- Installed Sigra (`--no-live --no-organizations --no-passkeys --no-admin`) with `users` table migrations and `fetch_current_scope` on the browser pipeline
- Bootstrapped Phoenix 1.8 HTML (`Layouts`, `CoreComponents`, Gettext, dev `/dev/mailbox`)
- Shipped `RegistrationController` calling `HelpDesk.provision_default_workspace_for_user/2` after successful signup
- Added `PageController` home and README walkthrough URLs for register/login/logout

## Task Commits

Each task was committed atomically:

1. **Task 1: Sigra install + migrate** - `b50e51e` (feat)
2. **Task 2: Phoenix HTML stack bootstrap** - `a476ed1` (feat)
3. **Task 3: RegistrationController + provision hook** - `d3cdc50` (feat)
4. **Task 4: PageController home + README setup steps** - `28312e9` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix/accounts.ex` - Sigra Accounts context and registration API
- `examples/threadline_phoenix/lib/threadline_phoenix_web/user_auth.ex` - Session and `fetch_current_scope` plugs
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` - `provision_default_workspace_for_user/2`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/registration_controller.ex` - Register + provision + log in
- `examples/threadline_phoenix/lib/threadline_phoenix_web/components/core_components.ex` - Input, button, flash, header for auth HEEx
- `examples/threadline_phoenix/README.md` - `mix sigra.install` and walkthrough URL table

## Decisions Made

- Provision at registration controller success path (not Sigra `on_register` config) per RESEARCH.md hook gap
- Dev/test `CLOAK_KEY` via `System.put_env` in config files so Vault starts without manual env setup
- Dormant settings/MFA routes return 404 to satisfy Phoenix verified-route compile checks without enabling product settings UI

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] HTML stack required before Sigra templates compile**
- **Found during:** Task 1 (post `mix sigra.install`)
- **Issue:** Generated `*_html.ex` modules require `ThreadlinePhoenixWeb.html/0` and core components; migrate/compile blocked
- **Fix:** Implemented Task 2 HTML infrastructure before Task 1 verification could pass; committed as separate task 2 commit immediately after task 1
- **Files modified:** `threadline_phoenix_web.ex`, `components/*`, `gettext.ex`
- **Verification:** `mix compile --warnings-as-errors` passes
- **Committed in:** `a476ed1`

**2. [Rule 3 - Blocking] CLOAK_KEY and Swoosh test client**
- **Found during:** Task 1 verify (`mix run` / `mix test`)
- **Issue:** Vault and Swoosh required env/config not injected by install alone
- **Fix:** `CLOAK_KEY` in `config/dev.exs` and `config/test.exs`; `config :swoosh, :api_client, false` in test
- **Files modified:** `config/dev.exs`, `config/test.exs`
- **Verification:** `mix test test/threadline_phoenix/help_desk_provision_test.exs` passes
- **Committed in:** `b50e51e`, `a476ed1`

**3. [Rule 1 - Bug] Dormant Sigra settings routes broke `--warnings-as-errors`**
- **Found during:** Task 2 compile verify
- **Issue:** Generated MFA/settings templates reference routes not in router
- **Fix:** Added `DormantAuthController` and stub `/users/settings*` routes (404)
- **Files modified:** `router.ex`, `dormant_auth_controller.ex`
- **Verification:** `mix compile --warnings-as-errors` exits 0
- **Committed in:** `a476ed1`

---

**Total deviations:** 3 auto-fixed (1 missing critical, 2 blocking/compile)
**Impact on plan:** No scope creep; required for a compiling reference app. AUTH-01/02 foundation delivered.

## Issues Encountered

None beyond deviations above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 02 (`OperatorUser` plug and `current_user` bridge)
- Ready for Plan 03 (`login_via_sigra` and HTTP audit proof tests)
- Registration and session cookies work; `/audit` still uses legacy `assign(:current_user)` until Plan 02

## Self-Check: PASSED

- `mix test test/threadline_phoenix/help_desk_provision_test.exs` — 2 tests, 0 failures
- `mix compile --warnings-as-errors` — success
- `lib/threadline_phoenix/accounts.ex` exists
- Sigra/users migrations present; `users` query succeeds after migrate

---
*Phase: 106-sigra-auth-lane-in-reference-app*
*Completed: 2026-05-27*
