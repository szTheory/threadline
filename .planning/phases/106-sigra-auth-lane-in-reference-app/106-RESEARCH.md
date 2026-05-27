# Phase 106: Sigra Auth Lane in Reference App — Research

**Researched:** 2026-05-27  
**Domain:** `examples/threadline_phoenix/` — Sigra install, host-owned `current_user` bridge, help-desk provisioning, layered ExUnit auth  
**Confidence:** HIGH for codebase/router/contracts; MEDIUM for Sigra `--no-live` generator gaps (verified against `sigra` 0.2.5 in lockfile)

---

## Executive Summary

Phase 106 replaces faked `conn |> assign(:current_user, …)` browser auth with real Sigra signup/login/session, maps Sigra `current_scope` → help-desk-aware `current_user`, and keeps existing `/audit` authorize/scope callbacks unchanged. Work is confined to `examples/threadline_phoenix/`; `lib/threadline/integrations/sigra.ex` stays read-only unless **106b** opens.

**Critical findings for planning:**

1. **Sigra is already a dependency** (`mix.exs` line 55: `{:sigra, "~> 0.2", optional: true}`; lockfile `0.2.5`) but **no auth code is installed** — app was scaffolded `--no-html`, `--no-mailer`, `--no-gettext`; only API `sigra_conn/2` tests exist.
2. **`mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin`** is the correct install slice; it injects `plug :fetch_current_scope` into `:browser`, adds ~15+ files under `lib/threadline_phoenix/accounts/` and `lib/threadline_phoenix_web/`, and adds Sigra migrations — but **does not** install Phoenix HTML (`Layouts`, `core_components`, `:html` in `threadline_phoenix_web.ex`) — planner must bootstrap that separately (106-UI-SPEC / D-106-03b).
3. **`RegistrationController` is missing from Sigra 0.2.5 templates** while router injection references it for `--no-live` — Phase 106 must **hand-ship** `RegistrationController` (thin wrapper around `Accounts.register_user/2` + `RegistrationHTML`) or open **106b** if upstream fixes land; do not switch to `--live` without scope creep.
4. **`on_register` hooks are documented but not wired in `Sigra.Auth.register/3`** — provisioning via `Accounts.Hooks.on_register/2` in config is **not** sufficient today; call `HelpDesk.provision_default_workspace_for_user/2` explicitly after `{:ok, user}` in registration (and idempotently on login if org missing).
5. **`is_admin` is host-owned** with `--no-admin` — no `SigraAdminPolicy`; use config allowlist (user ids/emails) in `OperatorUser`, honoring impersonator for `is_admin` per D-106-02f.
6. **`organization_id` on `current_user` comes from help-desk**, not Sigra org tables (`--no-organizations`) — resolve via membership lookup + optional `user_sessions.active_organization_id` (column still migrated); never slug.
7. **Baseline: 23 tests** in example app (`mix test`); AUTH-04 requires keeping all green while migrating `operator_surface_test.exs` and adding `help_desk_audit_http_test.exs`.

---

## 1. Sigra Install Mechanics

### Exact command (from 106-CONTEXT D-106-03a)

Run from `examples/threadline_phoenix/`:

```bash
cd examples/threadline_phoenix
mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin --yes
mix ecto.migrate
```

| Flag | Effect |
|------|--------|
| `Accounts User users` | Context `ThreadlinePhoenix.Accounts`, schema `User`, table `users` |
| `--no-live` | Controller HEEx: `RegistrationHTML`, `session_html.ex` (login); **no** `RegistrationLive` |
| `--no-organizations` | No Sigra `organizations` / membership tables; `Scope` without org hydration |
| `--no-passkeys` | No passkey routes/JS |
| `--no-admin` | No `SigraAdminPolicy`, admin LiveViews, impersonation UI |

### Files generated (Core feature — `deps/sigra/lib/sigra/install/features/core.ex`)

| Category | Paths (under `examples/threadline_phoenix/`) |
|----------|-----------------------------------------------|
| Context | `lib/threadline_phoenix/accounts.ex`, `user.ex`, `user_token.ex`, `user_session.ex`, `scope.ex`, `emails.ex`, `mailer.ex`, `audit_event.ex`, MFA schemas, `hooks.ex` |
| Web | `lib/threadline_phoenix_web/user_auth.ex`, `auth_error_handler.ex`, `controllers/session_controller.ex`, `session_html.ex`, `registration_html.ex`, `confirmation_*`, `reset_password_*`, `mfa_*`, `controllers/auth/sudo_controller.ex` |
| Migrations | `priv/repo/migrations/*_create_sigra_auth_tables.exs`, `*_add_active_organization_id_to_user_sessions.exs`, `*_create_audit_events.exs` |
| Test support | `test/support/fixtures/auth_fixtures.ex`, `test/support/conn_case_helpers.ex` |
| Config inject | `config/config.exs` — `:sigra`, `:sigra_config`, `:sigra` worker keys |
| Test inject | `config/test.exs` — argon2 fast hash |
| Router inject | `import ThreadlinePhoenixWeb.UserAuth`; `plug :fetch_current_scope` in `:browser`; large `# Sigra authentication` scope block |

**Not generated:** `RegistrationController` (router lists it for `--no-live` — **gap**). **Not generated:** Phoenix `Layouts`, `core_components.ex`, Gettext backend, `:html` macro block.

### Pipeline hooks Sigra injects into `router.ex`

```elixir
# Injected into pipeline :browser
plug :fetch_current_scope

# New pipelines
pipeline :require_authenticated do
  plug :require_authenticated_user
  plug :require_mfa
end

# Routes (subset — walkthrough-critical)
GET/POST  /users/log_in     SessionController
DELETE    /users/log_out    SessionController (requires auth)
GET/POST  /users/register   RegistrationController  # controller must be implemented
# + confirmation, reset, MFA routes (dormant for walkthrough)
```

`UserAuth.fetch_current_scope/2` assigns `conn.assigns.current_scope` and `conn.private[:sigra_session]` — same shape `Threadline.Integrations.Sigra` already reads on `:api` (`lib/threadline/integrations/sigra.ex:69-70`).

### AUTH-01 / `mix ecto.setup` integration

Current alias (`mix.exs:68`): `"ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]`.

**Planner action:** Document in README that first-time setup after Phase 106 is:

```bash
mix deps.get
mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin --yes
# bootstrap HTML stack (see §3)
mix ecto.setup
mix threadline.gen.triggers   # if not already in setup path
```

Consider extending `setup` alias to fail fast if `users` table missing. **Optional dep:** keep `optional: true` or remove `optional:` so CI always compiles Sigra — either works if dep is always in `mix.exs`.

### HTML / mailer bootstrap (D-106-03b — manual)

App lacks `use ThreadlinePhoenixWeb, :html` (`lib/threadline_phoenix_web.ex` has only `:router`, `:channel`, `:controller`).

Minimum additions:

| Asset | Purpose |
|-------|---------|
| `lib/threadline_phoenix_web/components/layouts.ex` | `<Layouts.app flash={@flash} current_scope={@current_scope}>` |
| `lib/threadline_phoenix_web/components/core_components.ex` | `<.input>`, `<.button>`, `<.form>`, `<.header>`, `<.flash>` |
| `lib/threadline_phoenix_web/gettext.ex` | `UserAuth` uses Gettext |
| `:html` quote in `threadline_phoenix_web.ex` | `RegistrationHTML`, `PageHTML` |
| Swoosh | Install adds `lib/threadline_phoenix/mailer.ex` + dev adapter inject; add **dev mailbox forward** in router when `dev_routes: true` (`config/dev.exs:54` already sets flag) |

Practical approach: copy Phoenix 1.8 defaults from a throwaway `mix phx.new` (same versions) or minimal `mix phx.gen.html` into a temp path — **not** `phx.gen.auth` (REQUIREMENTS out of scope).

---

## 2. Registration → Provision Hook Points

### Target API (106-CONTEXT D-106-01)

```elixir
# lib/threadline_phoenix/help_desk.ex — ADD
@spec provision_default_workspace_for_user(String.t(), keyword()) ::
  {:ok, Organization.t()} | {:error, term()}

@spec get_membership_role(String.t(), String.t()) :: :agent | :support | nil
```

**`provision_default_workspace_for_user/2` behavior:**

- Single `Ecto.Multi`: insert `Organization` (generated slug/name — discretion), `OrgMembership` (`role: "agent"` default), `Agent` with same `user_id`.
- `user_id` = `to_string(sigra_user.id)` (Sigra `User` uses `binary_id` UUID — `deps/sigra/priv/templates/sigra.install/core/user.ex`).
- Idempotent: if `OrgMembership` exists for `(organization_id, user_id)`, return existing org (unique index on `org_memberships` — Phase 105).
- After success: optionally `Sigra.SessionStores.Ecto.update_active_organization/3` so `session.active_organization_id` = help-desk org UUID for correlation suffixes.

### Where to invoke (D-106-01b)

| Hook point | Viable? | Notes |
|------------|---------|-------|
| `config :sigra, hooks: [on_register: {Accounts.Hooks, :on_register}]` | **No** | `Sigra.Hooks.maybe_run_hook/4` is only used for password/email/delete — **not** register (`grep` deps/sigra) |
| `Accounts.Hooks.on_register/2` in generated file | Template only | Uncomment + implement if Sigra adds register hook later |
| **`RegistrationController.create/2`** | **Yes** | After `Accounts.register_user/1` → `{:ok, user}` → `provision_default_workspace_for_user(to_string(user.id))` |
| **`ConfirmationController.confirm/2`** | Partial | User row exists earlier; WALK-01 uses mailbox — provision at register is better for “register → login → /audit” |
| **Login `SessionController.create/2`** | Safety net | Idempotent provision if user has no membership (seeds, partial failures) |

**Registration flow (Sigra default):** `register_user` → confirmation email sent → user may log in (default `require_confirmation: false` in `Sigra.Auth.authenticate/3`). Provision on register ensures org exists before first login.

### Sigra `Accounts.register_user/2` (generated)

```elixir
# deps/sigra/priv/templates/sigra.install/core/auth.ex:87-98
SigraAuth.register(Repo, attrs, changeset_fn: changeset_fn)
```

Uses `Sigra.Auth.register/3` → `register_user_multi` → `Repo.transact()` — **separate transaction** from help-desk unless planner composes `Ecto.Multi.append/2` manually (advanced; post-register call is simpler and matches CONTEXT).

---

## 3. OperatorUser Mapping (`scope` → `current_user`)

### New modules (D-106-02)

| Module | Path | Responsibility |
|--------|------|----------------|
| `ThreadlinePhoenixWeb.OperatorUser` | `lib/threadline_phoenix_web/operator_user.ex` | `build_operator_user/2`, plug `assign_from_scope/2` |
| `ThreadlinePhoenixWeb.Plugs.AssignOperatorUser` | `lib/threadline_phoenix_web/plugs/assign_operator_user.ex` | `plug ThreadlinePhoenixWeb.OperatorUser, :assign_from_scope` |

### Mapping contract (D-106-02c)

| `current_user` key | Source |
|--------------------|--------|
| `:id` | `scope.user.id` (UUID) |
| `:organization_id` | Help-desk org UUID string — see resolution below |
| `:role` | `HelpDesk.get_membership_role(user_id, org_id)` → `:agent` \| `:support` |
| `:is_admin` | Host policy on **impersonator** when `scope.impersonating_from` set; else host allowlist on `scope.user` |

**Organization resolution (`--no-organizations`):**

1. `conn.private[:sigra_session].active_organization_id` if set (help-desk UUID written at provision/login).
2. Else `HelpDesk.get_default_organization_for_user/1` (planner-named) — query `org_memberships` for user, pick sole/first org.
3. Never use `organizations.slug` in auth assigns.

**`:agent` + `/audit`:** `require_authenticated_operator/2` (`router.ex:34-47`) returns 403 for non-admin/non-support — **no router change** (D-106-02d).

**Impersonation (D-106-02f):** If `scope.impersonating_from` present, `is_admin` from impersonator only; **do not** grant `:support` from impersonated user's membership.

**`is_admin` without `--no-admin`:**

```elixir
# config/dev.exs / config/test.exs (example)
config :threadline_phoenix, ThreadlinePhoenixWeb.OperatorUser,
  admin_emails: ["admin@example.com"]
```

Grep acceptance: `grep -n 'admin_emails\|admin_user_ids' examples/threadline_phoenix/config/*.exs`

### Recompute every request (D-106-02e)

Do not `put_session(:current_user, …)` for full map; only existing `threadline_current_user` session copy in `require_authenticated_operator/2` stays. One indexed lookup:

```sql
-- org_memberships unique on (organization_id, user_id)
```

---

## 4. Router / Pipeline Changes

### Current `/audit` mount (`router.ex:119-130`)

```elixir
scope "/audit" do
  pipe_through([:browser, :operator_auth])
  threadline_operator_surface("/", ...)
end
```

### Target order (D-106-02b)

```elixir
pipeline :operator_browser do
  plug ThreadlinePhoenixWeb.Plugs.AssignOperatorUser
end

scope "/audit" do
  pipe_through([:browser, :operator_browser, :operator_auth])
  threadline_operator_surface("/", ...)  # unchanged options
end
```

`:browser` must run first (Sigra injects `fetch_session` + `fetch_current_scope` there).

### Home + auth routes (D-106-03)

```elixir
scope "/", ThreadlinePhoenixWeb do
  pipe_through :browser
  get "/", PageController, :home
end
# Sigra-injected /users/* scopes remain
```

**Do not change:** `my_authorize_fn/1`, `my_export_authorize_fn/1`, `scope_operator_query/3`, `:api` pipeline (`router.ex:99-108`).

### Admin pipeline note

Existing `pipeline :admin_auth` + `require_authenticated_admin/2` (`router.ex:15-32`) are unused by `/audit` today. Leave as-is or wire later; operator path uses `:operator_auth` only.

---

## 5. Test Strategy

### Layers (D-106-04)

| Layer | Mechanism | Files |
|-------|-----------|-------|
| Fast capture | DataCase + explicit `%AuditContext{}` | `test/threadline_phoenix/help_desk_audit_test.exs` — **unchanged** |
| API Sigra boundary | `sigra_conn/2` | `posts_audit_path_test.exs`, `posts_correlation_path_test.exs`, `posts_incident_json_path_test.exs` — **unchanged** |
| Browser session | `login_via_sigra/2` | `operator_surface_test.exs`, **new** `help_desk_audit_http_test.exs` |

### `login_via_sigra/2` (`test/support/conn_case.ex`)

```elixir
def login_via_sigra(conn, user, opts \\ []) do
  case Keyword.get(opts, :mode, :http) do
    :http ->
      conn
      |> Phoenix.ConnTest.init_test_session(%{})
      |> Plug.Conn.put_req_header("content-type", "application/x-www-form-urlencoded")
      |> Phoenix.ConnTest.post(~p"/users/log_in", %{
        "user" => %{"email" => user.email, "password" => user.password}
      })

    :session ->
      import ThreadlinePhoenixWeb.ConnCaseHelpers, only: [log_in_user: 2]
      log_in_user(conn, user)
  end
end
```

- **Default `:http`** — exercises `fetch_current_scope` + CSRF + `SessionController.create/2`.
- **`:session`** — wraps generated `ConnCaseHelpers.log_in_user/2` (`put_session(:user_token, token)`).
- Tests need `user` with known password — use `auth_fixtures.ex` `user_fixture(password: "password123456")` after install.

**CSRF:** Use `Phoenix.ConnTest` — `post/3` follows redirect; may need `fetch_flash` / follow_redirect.

### Migrate `operator_surface_test.exs`

Replace:

```elixir
|> assign(:current_user, %{id: 1, is_admin: true, ...})
```

With:

1. `user = user_fixture(...)` + `membership_fixture(org, user_id: to_string(user.id), role: "support")`
2. `conn = login_via_sigra(conn, user)`
3. `create_post_for_org(to_string(org.id), ...)` — **use real UUID**, not `"support-org-1"` (`router.ex:84` meta filter).

Admin scenario: user on admin allowlist + membership optional.

### `help_desk_audit_http_test.exs` (new, `async: false`)

Prove: Sigra login `user_id` → `actor_ref` on help-desk capture.

Minimal route (planner discretion):

```elixir
# e.g. POST /dev/help_desk/ticket_reply (browser + require_authenticated)
# Controller builds AuditContext from Integrations.Sigra.actor_ref_from_conn(conn)
# or ActorRef.new(:user, to_string(scope.user.id))
# Calls HelpDesk.ticket_replied_and_closed/6
```

Assert join `AuditTransaction.actor_ref` = `{:user, user_id}`.

### Fixtures alignment (D-106-04f)

`help_desk_fixtures.ex` `membership_fixture/2` `user_id` must match `to_string(sigra_user.id)` used in `login_via_sigra`.

### Baseline regression (AUTH-04)

```bash
cd examples/threadline_phoenix && mix test
mix verify.example   # from repo root
```

Grep: `assign(:current_user` should be **absent** in migrated files:

```bash
rg 'assign\(:current_user' examples/threadline_phoenix/test/
```

---

## 6. Risks & 106b Escape Triggers

| Risk | Severity | Mitigation / 106b trigger |
|------|----------|---------------------------|
| **Missing `RegistrationController`** in Sigra 0.2.5 | HIGH | Ship `lib/threadline_phoenix_web/controllers/registration_controller.ex` in 106; or 106b upstream Sigra fix |
| **No Phoenix HTML stack** | HIGH | Bootstrap `Layouts` + `core_components` before auth templates compile |
| **`on_register` hook not invoked by Sigra** | MEDIUM | Post-register `provision/2` in controller; document in PLAN |
| **Email confirmation vs walkthrough** | MEDIUM | Tests use confirmed users or `user_fixture` with `confirmed_at`; dev mailbox for WALK-01 (Phase 108) |
| **Optional `sigra` dep not loaded** | LOW | `conn_case` already references `Sigra.Session`; ensure `mix deps.get` in CI |
| **Org id mismatch in operator tests** | MEDIUM | Migrate to UUID org fixtures; meta `organization_id` must match `current_user.organization_id` |
| **`active_organization_id` without Sigra orgs** | MEDIUM | Store help-desk UUID on `user_sessions` via `SessionStores.Ecto.update_active_organization/3` after provision |
| **MFA blocking login in tests** | LOW | Test users without MFA enabled; `require_mfa` only on `:require_authenticated` pipeline |
| **Forking `UserAuth`** | — | **106b only** per D-106-03f |
| **`lib/threadline/integrations/sigra.ex` change** | — | **106b only** if browser capture cannot get `actor_ref` without adapter change (unlikely — API path already works) |
| **Dual org tables** | — | Out of scope — do not enable `--organizations` |

---

## 7. Validation Architecture (Nyquist)

### Test framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (`examples/threadline_phoenix`) |
| Config | `config/test.exs` (+ Sigra argon2 inject) |
| Quick run | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs --max-failures 1` |
| HTTP help-desk | `mix test test/threadline_phoenix/help_desk_audit_http_test.exs` |
| Full suite | `cd examples/threadline_phoenix && mix test` |
| Repo gate | `mix verify.example` (root) |
| Baseline | 23 tests, 0 failures (pre-106) |

### Phase requirements → test map

| Req ID | Behavior | Test type | Automated command / grep |
|--------|----------|-----------|----------------------------|
| **AUTH-01** | Sigra dep + migrations + `ecto.setup` | compile/migrate | `cd examples/threadline_phoenix && mix deps.get && mix ecto.migrate --quiet && mix run -e "ThreadlinePhoenix.Repo.query!(\"SELECT 1 FROM users LIMIT 0\")"` |
| **AUTH-02** | Register/login/logout routes + session | ConnCase HTTP | `mix test test/threadline_phoenix_web/operator_surface_test.exs` (login path); optional dedicated `auth_routes_test.exs` with POST register + GET / |
| **AUTH-03** | `current_user` has `is_admin`, `role`, `organization_id`; `/audit` works | ConnCase | `operator_surface_test` admin + support scenarios; `refute conn.assigns[:current_user].organization_id == ""` after login |
| **AUTH-04** | No faked assigns; real session help-desk capture; regressions | DataCase + ConnCase + API | `rg 'assign\(:current_user' test/` → empty; `mix test`; `mix verify.example` |

### Sampling rate

- **Per task:** targeted `mix test <file>`
- **Per wave:** full `mix test` in example app
- **Phase gate:** `mix verify.example` + manual smoke `mix phx.server` → register → login → `/audit` (ROADMAP SC #1)

### Wave 0 gaps (pre-execute)

| Gap | Action |
|-----|--------|
| No `users` table | `mix sigra.install ...` + migrate |
| No HTML components | Bootstrap before compile auth templates |
| No `RegistrationController` | Add in Plan 01 |
| No `provision_default_workspace_for_user/2` | Add to `HelpDesk` |
| No `OperatorUser` / plug | Add in Plan 02 |
| No `login_via_sigra/2` | Extend `conn_case.ex` |
| No `help_desk_audit_http_test.exs` | Add in Plan 03 |

---

## Codebase Anchors (grep-verifiable)

| Item | Path |
|------|------|
| Faked auth tests | `test/threadline_phoenix_web/operator_surface_test.exs:17,30,51` |
| API sigra shim | `test/support/conn_case.ex:39-66` |
| Operator plugs | `lib/threadline_phoenix_web/router.ex:19-47,62-97` |
| Help desk (no provision yet) | `lib/threadline_phoenix/help_desk.ex` |
| Membership roles | `lib/threadline_phoenix/help_desk/org_membership.ex:14` |
| Sigra adapter (read-only) | `lib/threadline/integrations/sigra.ex` |
| Integration guide | `guides/integrations/sigra.md` |
| UI contract | `.planning/phases/106-sigra-auth-lane-in-reference-app/106-UI-SPEC.md` |

---

## RESEARCH COMPLETE
