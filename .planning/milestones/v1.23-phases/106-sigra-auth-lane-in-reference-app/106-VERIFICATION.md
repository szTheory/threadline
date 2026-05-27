---
phase: 106-sigra-auth-lane-in-reference-app
status: passed
verified: 2026-05-27
score: 16/16
---

# Phase 106 Verification Report

**Phase goal:** Wire real Sigra signup/login/session in `examples/threadline_phoenix/`, replace faked-conn admin assigns, and expose `organization_id` + role on `current_user` so the existing `/audit` mount and authorize-fn continue to work end-to-end against real auth.

**Status:** passed

## Must-Have Verification

| # | Must-have (plan truths + artifacts) | Status | Evidence |
|---|-------------------------------------|--------|----------|
| 1 | Sigra `users` table after `mix ecto.migrate` | ✓ | `priv/repo/migrations/20260527161605_create_sigra_auth_tables.exs`; `mix ecto.migrate` + `SELECT 1 FROM users` OK |
| 2 | GET `/` shows register/login when logged out | ✓ | `page_html.ex` links to `/users/register`, `/users/log_in` when `@current_scope.user` nil |
| 3 | POST `/users/register` creates user + help-desk membership | ✓ | `registration_controller.ex` → `HelpDesk.provision_default_workspace_for_user/2`; `help_desk_provision_test.exs` (2 tests) |
| 4 | POST `/users/log_in` establishes session | ✓ | `login_via_sigra/2` default `:http` POST; operator + HTTP audit tests pass |
| 5 | Artifact: `accounts.ex` | ✓ | `lib/threadline_phoenix/accounts.ex` |
| 6 | Artifact: `registration_controller.ex` | ✓ | `lib/threadline_phoenix_web/controllers/registration_controller.ex` |
| 7 | `current_user` has `is_admin`, `role`, `organization_id` after login | ✓ | `operator_user.ex` `build_operator_user/2`; HTTP audit test asserts `current_scope` + `actor_ref` |
| 8 | `/audit` works for admin/support; `my_authorize_fn` unchanged | ✓ | `operator_surface_test.exs` admin/support scenarios; authorize/scope bodies in `router.ex` unchanged per plan 02 |
| 9 | Agent role gets 403 on `/audit` | ✓ | `operator_surface_test.exs` "agent membership without admin email receives 403" |
| 10 | Artifact: `operator_user.ex` | ✓ | `lib/threadline_phoenix_web/operator_user.ex` + `plugs/assign_operator_user.ex` |
| 11 | `operator_surface_test` uses `login_via_sigra`, not `assign(:current_user` | ✓ | `rg 'assign\(:current_user' test/` — no matches; tests call `login_via_sigra` |
| 12 | `help_desk_audit_http_test` proves `actor_ref` from real session | ✓ | `help_desk_audit_http_test.exs` POST `/dev/help_desk/ticket_reply`, asserts `{:user, user_id}` |
| 13 | All pre-existing example tests pass (23+ baseline) | ✓ | `mix test` — **27 tests, 0 failures** |
| 14 | `mix verify.example` passes from repo root | ✓ | Exit 0 (2026-05-27) |
| 15 | Artifact: `login_via_sigra/2` in ConnCase | ✓ | `test/support/conn_case.ex` default `mode: :http` |
| 16 | Artifact: `help_desk_audit_http_test.exs` | ✓ | File exists; dev route gated by `dev_routes` compile_env |

## Requirements Traceability

| ID | Plan | Status | Notes |
|----|------|--------|-------|
| AUTH-01 | 106-01 | ✓ | `{:sigra, "~> 0.2"}` in `mix.exs`; Sigra migration; README `mix sigra.install` + `mix ecto.setup` |
| AUTH-02 | 106-01 | ✓ | Router `/users/*` routes; `PageController` home; session via `UserAuth` / `fetch_current_scope` |
| AUTH-03 | 106-02 | ✓ | `OperatorUser` + `:operator_browser` on `/audit`; `config/test.exs` admin allowlist |
| AUTH-04 | 106-03 | ✓ | Real HTTP login in browser tests; API tests still use `sigra_conn/2`; full suite green |

All four requirement IDs in plan frontmatter match `REQUIREMENTS.md` Phase 106 mapping.

## ROADMAP Success Criteria

1. **`mix ecto.setup` + working signup → login → logout** — **verified (automated proxy).** Migrations and README steps present; register/provision/login paths covered by tests. Logout route exists (`DELETE /users/log_out`); no dedicated logout test (see Human Verification).
2. **`current_user` exposes `is_admin`, `role`, `organization_id` matching authorize/scope** — **verified** (`OperatorUser` + operator surface tests).
3. **Help-desk audit tests use real Sigra session** — **verified** (`help_desk_audit_http_test.exs`, `login_via_sigra`).
4. **Pre-existing tests pass; no faked-conn regressions** — **verified** (27/27; `posts_*` still use `sigra_conn/2`).

## Scope Guard

- Changes confined to `examples/threadline_phoenix/**` — **verified** (plans 01–03 file lists; no Phase 106 commits under `lib/threadline/` in recent history).
- `lib/threadline/integrations/sigra.ex` read-only — **verified** (no edits in phase deliverables).

## Human Verification

**Superseded by CI (2026-05-27):** Phase 106 UAT scenarios are covered by `examples/threadline_phoenix/test/threadline_phoenix_web/sigra_auth_flow_test.exs`, which runs under `mix verify.example` in the `verify-test` GitHub Actions job. No manual browser pass is required before Phase 107.

Automated coverage: cold-start users table, register + session reload, admin `/audit` access, agent 403, logout + audit denial. Optional maintainer smoke (`mix phx.server`) remains a walkthrough convenience only.

## Non-Blocking Findings (from 106-REVIEW.md)

| ID | Severity | Summary |
|----|----------|---------|
| WR-001 | warning | `HelpDeskDevController` does not assert `ticket.organization_id == org.id` (dev/test route only) |
| WR-002 | warning | `SessionController` discards provision `{:error, _}` on login |
| IN-001 | info | Registration flash may `inspect` internal errors |

These do not fail phase must-haves; address before Phase 107 if seeds rely on login safety-net.

## Gaps

None against phase must-haves or AUTH-01–AUTH-04.

## Self-Check

Commands re-run during verification (2026-05-27):

```bash
cd examples/threadline_phoenix && mix test
cd examples/threadline_phoenix && mix ecto.migrate --quiet && mix run -e 'ThreadlinePhoenix.Repo.query!("SELECT 1 FROM users LIMIT 0")'
cd /Users/jon/projects/threadline && mix verify.example
rg 'assign\(:current_user' examples/threadline_phoenix/test/
```

All exited 0; grep found no faked `current_user` assigns in tests.
