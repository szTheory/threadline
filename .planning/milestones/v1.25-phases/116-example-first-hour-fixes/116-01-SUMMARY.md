---
phase: 116-example-first-hour-fixes
plan: 01
subsystem: api
tags: [phoenix, sigra, session, curl, doc-contract]

requires:
  - phase: 115-narrative-doc-sync
    provides: Audit.transaction/3 narrative alignment in guides
provides:
  - Session plugs on example :api pipeline before Threadline.Plug
  - sigra_conn/2 session-token staging compatible with fetch_current_scope
  - Authenticate before auth subsection in example README and getting-started §6
  - Doc-contract locks for API auth staging literals
affects:
  - 116-02 (README install restructure builds on auth curl anchor)

tech-stack:
  added: []
  patterns:
    - "Host session before Threadline.Plug on API routes"
    - "Test auth via :user_token session key, not direct assign"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - examples/threadline_phoenix/test/support/conn_case.ex
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs
    - examples/threadline_phoenix/README.md
    - guides/getting-started-saas.md
    - test/threadline/example_phoenix_readme_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs

key-decisions:
  - "Session plugs stay outside router-pipeline-actor-fn doc fence"
  - "sigra_conn/2 updates active_organization_id via UserSession Ecto row, not Sigra.Session changeset"
  - "Correlation fallback test uses Ecto.UUID org id when Accounts.Organization is not generated"

patterns-established:
  - "Cookie curl with _threadline_phoenix_key is canonical happy path for POST /api/posts"
  - "Doc contracts lock auth staging literals without locking full curl fences"

requirements-completed: [EXAMPLE-01, EXAMPLE-04]

duration: 25min
completed: 2026-05-27
---

# Phase 116 Plan 01: API Auth Staging Summary

**Browser Sigra session reaches POST /api/posts via fetch_session/fetch_current_scope on :api, with cookie curl documented and locked in dual-contract tests.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-27T22:30:00Z
- **Completed:** 2026-05-27T22:55:00Z
- **Tasks:** 5
- **Files modified:** 9

## Accomplishments

- Added `plug(:fetch_session)` and `plug(:fetch_current_scope)` to the example `:api` pipeline before `Threadline.Plug` (outside the doc fence).
- Refactored `sigra_conn/2` to stage `:user_token` in session so integration tests work with the new pipeline plugs.
- Documented **Authenticate before the audited API call** in the example README and `guides/getting-started-saas.md` §6 with cookie curl and `missing actor` boundary.
- Extended doc-contract tests to lock shared auth staging literals.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add session plugs to `:api` pipeline** - `5fe306b` (feat)
2. **Task 2: Fix sigra_conn/2 for session-plug compatibility** - `70b8557` (fix)
3. **Task 3: Example README auth subsection + cookie curl** - `3fc358d` (docs)
4. **Task 4: Sync getting-started §6 auth staging + curl** - `3b8180c` (docs)
5. **Task 5: Doc-contract locks for API auth staging** - `bd9ef6e` (test)

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - Session plugs on `:api` pipeline
- `examples/threadline_phoenix/test/support/conn_case.ex` - Session-token `sigra_conn/2`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_*_test.exs` - User-fixture auth staging
- `examples/threadline_phoenix/README.md` - Auth subsection + cookie curl under Audited HTTP path
- `guides/getting-started-saas.md` - §6 auth staging dual-contract
- `test/threadline/example_phoenix_readme_contract_test.exs` - API auth staging contract test
- `test/threadline/getting_started_saas_doc_contract_test.exs` - §6 auth literal locks

## Decisions Made

- Session plugs placed outside `router-pipeline-actor-fn` fence to preserve getting-started snippet extraction.
- `active_organization_id` in `sigra_conn/2` updated via `UserSession` Ecto schema because `Sigra.Session` has no changeset.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] sigra_conn org staging via UserSession, not Sigra.Session changeset**
- **Found during:** Task 2 (Fix sigra_conn/2)
- **Issue:** `Ecto.Changeset.change/2` on `Sigra.Session` raised `UndefinedFunctionError`; `AccountsFixtures.create_organization/1` requires ungenerated `Accounts.Organization`
- **Fix:** Update `user_sessions.active_organization_id` through `UserSession` Ecto row; correlation fallback test uses `Ecto.UUID.generate()` for org id
- **Files modified:** `conn_case.ex`, `posts_correlation_path_test.exs`
- **Verification:** All 7 posts_* tests pass; `mix verify.example` green
- **Committed in:** `70b8557`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for test compatibility; behavior matches plan intent (persisted session drives Sigra correlation).

## Issues Encountered

None beyond the deviation above.

## User Setup Required

None - no external service configuration required.

## Verification

```bash
cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs test/threadline_phoenix_web/posts_incident_json_path_test.exs  # 7 tests, 0 failures
mix verify.example  # 53 tests, 0 failures
mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs  # 10 tests, 0 failures
```

## Next Phase Readiness

Ready for **116-02** (README install restructure, Track A/B, mix task ownership). Auth curl anchor is in place; no blockers.

## Self-Check: PASSED

- [x] All 5 tasks executed with individual commits
- [x] SUMMARY.md created at `.planning/phases/116-example-first-hour-fixes/116-01-SUMMARY.md`
- [x] Plan verification commands exit 0
- [x] Key artifacts exist on disk

---
*Phase: 116-example-first-hour-fixes*
*Completed: 2026-05-27*
