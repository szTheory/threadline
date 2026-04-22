# Phoenix Auth Library — Jobs to Be Done, Personas & User Flows

> **Purpose**: LLM context document for designing and building a gold-standard Phoenix/Plug authentication library. All "users" here are software engineers integrating this library into their Phoenix application. Priority tiers: **P0** = must ship at launch, **P1** = ship in v1.x, **P2** = important but deferrable.

---

## Personas

### Persona A — Solo SaaS Builder ("Indie Hacker / Small Team")
Builds a product solo or with 1–2 others. Deploys a Phoenix + LiveView SaaS. Wants auth done in an afternoon so they can focus on the actual product. Comes from Rails/Devise or Laravel. Their greatest fear: wiring together 4 half-maintained libraries and writing security-sensitive plumbing themselves. Wants magic, but visible magic — they need to trust what they can't see, and debug what breaks.

### Persona B — Mid-Market Engineering Team
5–20 engineers shipping a B2B SaaS. Their customers will require MFA and SSO before signing contracts. The tech lead has already built auth "from scratch" twice before and doesn't want to do it again. Needs something they can demo to a security-conscious buyer. Cares about auditability, test coverage, and not painting themselves into a corner when requirements expand.

### Persona C — Platform/API Builder
Building a Phoenix API (REST or GraphQL) consumed by mobile apps or SPAs. Sessions are irrelevant; they need bearer tokens, API key scoping, and JWT. May be adding auth to an existing service that already has users. Wants the library to stay out of the way — no HTML, no LiveView, plug cleanly into their existing pipeline.

### Persona D — Experienced Elixir Developer (Upgrader)
Currently on a Pow-based app (Phoenix 1.6/1.7), needs to migrate to Phoenix 1.8+. Or has a hand-rolled auth system they've grown to distrust. Has specific opinions about Ecto schemas, contexts, and not having a library "take over" their data model. Needs granular control, a migration path, and the ability to keep their existing user table structure.

### Persona E — Enterprise / Security-Conscious Team
Shipping to enterprise customers with compliance requirements (SOC2, HIPAA adjacent). Needs audit logs, SSO per customer organization, SAML/OIDC, MFA enforcement policies, and session revocation. Less concerned about time-to-first-auth, more concerned about correctness and completeness. Will read the source code.

---

## Jobs to Be Done — Priority-Ordered

---

### P0-1 — Install the library and have basic email/password auth working in < 30 minutes

**Who**: All personas, but especially A and B.

**The job**: Get from `mix new` (or existing app) to a working register/login/logout flow, including a database migration, without writing security-sensitive code.

**Success criteria**: `mix auth.install` generates migrations, a schema, a context module, and LiveView pages. Developer runs `mix ecto.migrate`, starts the server, and can register + log in.

**Key flows**:
1. `mix auth.install` — interactive prompt: "What is your user schema module? (default: MyApp.Accounts.User)". Generates:
   - `priv/repo/migrations/*_create_auth_tables.exs` (users, user_tokens)
   - `lib/my_app/accounts.ex` context with `register_user/1`, `authenticate_user/2`, `get_user_by_email/1`, `get_user!/1`
   - `lib/my_app/accounts/user.ex` schema
   - `lib/my_app_web/live/auth/` — login, registration, forgot password LiveViews
   - `lib/my_app_web/controllers/auth_controller.ex` (session management over HTTP POST)
   - `lib/my_app_web/plugs/auth_plug.ex`
   - Router instructions / auto-patched scope
2. Developer runs `mix ecto.migrate`
3. Developer adds the auth router scope (shown in install output, or auto-patched)
4. Developer adds `plug MyAppWeb.Plugs.AuthPlug` to browser pipeline
5. Registration page works: email + password → create user → send confirmation email → redirect
6. Login page works: email + password → set session → redirect
7. Logout works: POST to `/auth/logout` → clear session → redirect

**Failure modes to handle well**:
- App already has a users table → generator detects this and offers to add auth columns to existing table vs. create a separate identity table
- Schema module name conflict → prompt to resolve
- Missing email config → clear error with instructions for config

---

### P0-2 — Protect routes, know who is logged in, get current user in controllers and LiveViews

**Who**: All personas. This is the core "make it work in my app" job.

**The job**: After installation, the developer needs to lock down routes, access `current_user` everywhere, and redirect unauthenticated requests.

**Key flows**:
1. **HTTP route protection** — plug in router pipeline:
   ```elixir
   pipeline :authenticated do
     plug MyApp.Auth.RequireAuth, redirect_to: "/login"
   end
   scope "/app", MyAppWeb do
     pipe_through [:browser, :authenticated]
     live "/dashboard", DashboardLive
   end
   ```
2. **Access current_user in a controller**:
   ```elixir
   def index(conn, _params) do
     user = conn.assigns.current_user  # always present after plug
     render(conn, :index, user: user)
   end
   ```
3. **Access current_user in a LiveView** via `on_mount`:
   ```elixir
   live_session :authenticated, on_mount: [{MyApp.Auth, :ensure_authenticated}] do
     live "/dashboard", DashboardLive
   end
   # In the LiveView:
   socket.assigns.current_user
   ```
4. **Conditional rendering in templates**:
   ```elixir
   <%= if @current_user do %>
     <.link href="/app">Dashboard</.link>
   <% else %>
     <.link href="/login">Log in</.link>
   <% end %>
   ```
5. **Check from anywhere in business logic**:
   ```elixir
   MyApp.Auth.authenticated?(conn)
   MyApp.Auth.current_user(conn)
   ```

**Edge cases**:
- Socket vs. conn — the library must provide identical `current_user` assignment on both
- LiveView navigation (patch/push_navigate) must re-check auth on mount, not just on initial connection
- Expired tokens must be gracefully handled (clear session, redirect to login with return URL)
- Remember-me persistent session should be transparently renewed

---

### P0-3 — Add social login (OAuth) with at least Google and GitHub

**Who**: Persona A (consumer SaaS), Persona B (B2B often also needs GitHub/Google).

**The job**: Let users sign in with Google/GitHub without building an OAuth flow from scratch. Handle account linking (email already exists), token storage, and profile sync.

**Key flows**:
1. **Install a provider**:
   ```elixir
   # config/config.exs
   config :my_app, MyApp.Auth,
     providers: [
       google: [client_id: "...", client_secret: "..."],
       github: [client_id: "...", client_secret: "..."]
     ]
   ```
2. **Routes are auto-registered**: `/auth/google`, `/auth/google/callback`, `/auth/github`, `/auth/github/callback`
3. **UI helper**: pre-built `<.oauth_button provider={:google} />` LiveView component
4. **Callback handling** (automatic, but hookable):
   - Receive OAuth user info from provider
   - Look up existing `oauth_accounts` record by `{provider, uid}`
   - If found: log in the linked user
   - If not found, email match exists: prompt to link accounts (configurable — some apps want auto-link, some require confirmation)
   - If not found, no email match: create new user + oauth_account, log in
5. **Account linking from settings** — existing logged-in user links a new OAuth provider:
   ```elixir
   # GET /auth/github?action=link redirects to GitHub
   # On callback: create oauth_accounts record for current_user, redirect to settings
   ```
6. **Token storage** — access token + refresh token stored encrypted in `oauth_accounts` table, accessible for API calls to the provider

**Failure modes**:
- Provider returns no email (GitHub with private email setting) → configurable fallback: prompt for email, reject, or create with generated handle
- User denies OAuth permission → graceful redirect back to login with flash
- Provider is down → error state with retry link
- CSRF state mismatch → reject with clear error

---

### P0-4 — Email confirmation (verify new accounts before allowing full access)

**Who**: All personas building any web app.

**The job**: New registrations trigger a confirmation email. Unconfirmed users have limited access until they verify. Confirmation tokens expire. Users can request resend.

**Key flows**:
1. User registers → `confirmed_at` is `nil` → confirmation email sent automatically via Oban job (or inline fallback)
2. User clicks link → token validated → `confirmed_at` set → session created → redirect to app
3. Unconfirmed user attempts login → configurable behavior:
   - Option A (default): allow login, show banner "please confirm your email"
   - Option B: block login until confirmed
4. Resend confirmation: `POST /auth/confirm` with email → rate-limited → new token generated, old invalidated, email sent
5. Token expiry: configurable TTL (default 48 hours) → expired token shows helpful error with resend link

**Security requirements**:
- Tokens are single-use
- Tokens are HMAC-protected (useless without server secret)
- Resend is rate-limited (prevent email flooding)
- No email enumeration: "if that address exists, we've sent a confirmation" messaging

---

### P0-5 — Password reset ("forgot password" flow)

**Who**: All personas.

**The job**: Standard password reset by email. Secure tokens, expiry, single-use, no enumeration.

**Key flows**:
1. User submits email on forgot password form
2. System: regardless of whether email exists, show "if that email is registered, you'll receive a link" (enumeration prevention)
3. If user exists: generate HMAC reset token, store hashed in `user_tokens` with context `"reset"` and 60-minute TTL, send email
4. User clicks link → token validated → show new password form
5. User submits new password → password updated → all existing sessions invalidated → new session created → redirect to app with success flash
6. Edge case: token expired → show error with link to request new one
7. Edge case: token already used → show "this link has already been used" error

---

### P0-6 — Session security: remember me, idle timeout, session invalidation on password change

**Who**: All personas.

**The job**: Standard session hygiene that developers shouldn't have to implement themselves.

**Key flows**:
1. **Remember me**: optional checkbox on login → sets a long-lived cookie (default 60 days) separate from the session cookie, backed by a `remember` context token in the database
2. **Idle timeout**: configurable (default off, opt-in). Session marked stale if no activity for N minutes. On next request: re-authenticate prompt (not full logout — show modal or redirect to login with return URL)
3. **Absolute timeout**: sessions expire unconditionally after N days even with activity (default 90 days)
4. **Password change invalidates all sessions**: when user changes password, all `session` context tokens for that user are deleted except the current one
5. **Logout all devices**: `MyApp.Auth.log_out_everywhere(user)` deletes all session tokens → broadcasts `disconnect` to all open LiveView sockets via PubSub

---

### P1-1 — TOTP-based two-factor authentication (MFA with authenticator apps)

**Who**: Persona B and E (required for enterprise). Increasingly expected even in consumer apps.

**The job**: Full TOTP enrollment, verification, and recovery flow. Not just the algorithm — the complete lifecycle.

**Key flows**:
1. **Enrollment**:
   - User navigates to security settings → clicks "Enable 2FA"
   - Library generates TOTP secret, returns QR code URI (use `NimbleTOTP.otpauth_uri/3`)
   - Display QR code + manual entry code in pre-built LiveView component
   - User enters 6-digit code to confirm enrollment → if valid, secret saved (encrypted) to `mfa_credentials` table, 2FA enabled
2. **Login with 2FA**:
   - Password verified → session created with `mfa_pending: true` flag (not fully authenticated)
   - Redirect to `/auth/mfa/verify`
   - User enters 6-digit code → validated → session upgraded to fully authenticated → redirect to intended URL
3. **Backup codes**:
   - Generated at enrollment (8 codes, single-use, hashed before storage)
   - Shown once with download/copy prompt
   - On login: "use a backup code" link on MFA page → validated → used code marked as consumed
   - When all codes used: prompt to regenerate (requires current TOTP code to confirm)
4. **"Trust this browser"** (optional, configurable):
   - Checkbox on MFA verify page → sets encrypted browser-trust cookie (30-day TTL)
   - On login: if trust cookie present and valid → skip MFA step
5. **Disable 2FA**:
   - Requires current TOTP code or backup code to confirm
   - All backup codes deleted, `mfa_credentials` record removed
6. **Enforcement policies** (configurable per route or role):
   ```elixir
   plug MyApp.Auth.RequireMFA  # blocks access if 2FA not enrolled
   ```

**Security**:
- TOTP secrets encrypted at rest (via Cloak or configurable encryption callback)
- Rate-limit code attempts (5 attempts then 15-minute lockout)
- Time window: ±1 step (30s before/after current window)

---

### P1-2 — API token authentication (bearer tokens for REST/JSON APIs)

**Who**: Persona C primarily. Also B and E when building APIs alongside their web app.

**The job**: Authenticate API requests via `Authorization: Bearer <token>` header. Issue, revoke, and scope tokens. No sessions, no cookies.

**Key flows**:
1. **Token issuance**:
   - Via user action (personal access token from settings UI)
   - Via API endpoint (for programmatic issuance: `POST /api/tokens`)
   - Token format: `myapp_live_<random_base64_32bytes>` — prefix for recognizability, never stored plaintext
2. **Token verification in pipeline**:
   ```elixir
   pipeline :api do
     plug :accepts, ["json"]
     plug MyApp.Auth.BearerAuth  # sets conn.assigns.current_user or returns 401
   end
   ```
3. **Scoped tokens**: tokens carry a list of scopes (`["read:contracts", "write:contracts"]`), checked at authorization layer
4. **Token lifecycle**:
   - Expiry date (optional)
   - Last-used-at tracking
   - Revocation: `DELETE /api/tokens/:id`
   - List active tokens (for user security settings page)
5. **Dual-mode apps** (session for browser, bearer for API):
   - Single `RequireAuth` plug that accepts either a session cookie or a bearer token, sets `current_user` the same way regardless
   ```elixir
   plug MyApp.Auth.AnyAuth  # tries session first, falls back to bearer
   ```

---

### P1-3 — Passkeys / WebAuthn (passwordless and second-factor)

**Who**: Persona B and E. Forward-looking persona A for consumer apps.

**The job**: Register a passkey, authenticate with it. Works as primary passwordless login and as a second factor. Built on the `Wax` library internally.

**Key flows**:
1. **Registration** (from security settings):
   - Server generates challenge → send to browser
   - Browser calls `navigator.credentials.create()` (handled by pre-built JS module)
   - Server validates response → store credential (credential_id, public_key, sign_count, friendly name like "MacBook Face ID")
2. **Authentication** (from login page):
   - User enters email (or auto-detect from discoverable credentials)
   - Server generates challenge
   - Browser calls `navigator.credentials.get()`
   - Server validates signature + incremented sign_count → authenticate user
3. **Multiple passkeys per user** — list in security settings, delete individual ones
4. **Passkey as second factor** — after password login, redirect to passkey verification instead of TOTP prompt (configurable preference)

---

### P1-4 — Organization / team multi-tenancy with roles and invitations

**Who**: Persona B and E. Most B2B SaaS needs this.

**The job**: Users belong to one or more organizations with roles. New members are invited by email. All auth context is organization-scoped.

**Key flows**:
1. **Organization creation**:
   - Any user can create an org (configurable) → user becomes `owner` member
2. **Invitation flow**:
   - Admin sends invite: `POST /org/:slug/invitations` with `{email, role}`
   - System generates signed token, sends email with `/invitations/accept?token=...`
   - If email matches existing user → confirm → create membership → redirect to org
   - If no existing user → create account first → then membership
   - Invitation expires (default 7 days)
   - Invitation can be revoked before acceptance
3. **Org context in auth**:
   ```elixir
   # current_user is always available; current_org depends on subdomain or path
   socket.assigns.current_org  # set by on_mount hook
   socket.assigns.current_membership  # role, permissions
   ```
4. **Role-based access**:
   ```elixir
   plug MyApp.Auth.RequireRole, :admin  # 403 if member is not admin/owner
   ```
5. **Switch organization** — if user belongs to multiple orgs, UI to switch active org context
6. **Remove member** — owner/admin can remove a member; member can leave

---

### P1-5 — Audit logging

**Who**: Persona B and E.

**The job**: Record security-relevant auth events with user, IP, user agent, timestamp, and outcome. Queryable by the app, exportable.

**Events to log automatically**:
- `login.success`, `login.failure`, `login.mfa_required`
- `logout`, `logout.all_devices`
- `password.changed`, `password.reset.requested`, `password.reset.completed`
- `email.changed`, `email.confirmation.sent`, `email.confirmed`
- `mfa.enrolled`, `mfa.disabled`, `mfa.backup_code_used`
- `passkey.registered`, `passkey.deleted`
- `session.revoked`
- `oauth.linked`, `oauth.unlinked`
- `api_key.created`, `api_key.revoked`
- `invitation.sent`, `invitation.accepted`, `invitation.revoked`
- `member.added`, `member.removed`
- `account.locked`, `account.unlocked`

**Developer interface**:
```elixir
# Query audit log
MyApp.Auth.AuditLog.for_user(user_id)
MyApp.Auth.AuditLog.for_org(org_id, since: ~D[2025-01-01])

# Hook in custom events
MyApp.Auth.AuditLog.record(conn, :custom_event, %{detail: "..."})
```

---

### P1-6 — Account lockout and brute-force protection

**Who**: All personas. Security baseline.

**The job**: Detect repeated failed login attempts and temporarily lock the account. Rate-limit by IP as well as by account.

**Key flows**:
1. Failed login increments `failed_login_attempts` counter on user record
2. After N failures (default 5): account is temporarily locked for 15 minutes (`locked_at` set)
3. Locked account login attempt: generic error message (don't distinguish "locked" from "wrong password" to prevent enumeration of locked accounts)
4. After lockout duration: `locked_at` automatically released on next successful login attempt
5. Admin can unlock manually
6. Optional: send email to user on lockout ("We noticed failed login attempts...")
7. **IP-based rate limiting** (via Hammer or pluggable rate limiter):
   - 10 failed attempts per IP per minute → return 429 with retry-after header
   - Applied before account lookup (protects against enumeration via timing)

---

### P1-7 — Session management UI (view and revoke active sessions)

**Who**: Persona B and E. Security-conscious users.

**The job**: Users can see all their active sessions (device, browser, IP, last active), and revoke any or all of them.

**Key flows**:
1. `GET /auth/sessions` (or settings subpage) — list of active sessions with:
   - User agent parsed to human-readable "Chrome on macOS"
   - IP address
   - Created at, last active at
   - "Current session" label
2. `DELETE /auth/sessions/:id` — revoke a specific session
3. `DELETE /auth/sessions` — revoke all sessions except current
4. Backend: deletes `user_tokens` records → next request from that session hits a dead token → redirect to login

---

### P1-8 — Email change with re-verification

**Who**: All personas.

**The job**: Users change their email address. The new address must be verified before it becomes active. The old address stays active until confirmed. User is notified at both addresses.

**Key flows**:
1. User submits new email in settings
2. Validation: new email not already taken (constant-time check)
3. System sends confirmation link to new email
4. System sends security notification to old email ("Your email is being changed — if this wasn't you, click here to cancel")
5. User clicks confirmation link on new email → `email` column updated, old email becomes inactive
6. Cancel link on old email → pending change cancelled, old email retained
7. Pending change expires after 24 hours

---

### P1-9 — Sudo mode (re-authentication before sensitive operations)

**Who**: Persona B and E. Security best practice for settings pages.

**The job**: Before sensitive operations (change password, delete account, view API keys, revoke sessions), require the user to re-confirm their identity even if they're logged in.

**Key flows**:
1. Route or action marked as requiring sudo:
   ```elixir
   plug MyApp.Auth.RequireSudo, max_age: 600  # 10 minutes
   ```
2. If user hasn't authenticated within the sudo window → redirect to `/auth/sudo`
3. Sudo confirmation page shows: re-enter password (or TOTP if MFA enrolled)
4. On success: `sudo_at` timestamp set in session → proceed to intended route
5. Sudo expires after `max_age` seconds
6. Sudo page shows what action triggered it: "To change your password, please confirm your identity"

---

### P2-1 — Enterprise SSO per organization (SAML 2.0 / OIDC)

**Who**: Persona E.

**The job**: Each enterprise customer organization can configure its own identity provider (Okta, Azure AD, Google Workspace). Users in that org authenticate via SSO. SSO-only mode disables password login.

**Key flows**:
1. Org admin configures IdP:
   - SAML: paste metadata XML or URL, set ACS URL, entity ID
   - OIDC: set client_id, client_secret, discovery URL
2. System validates IdP configuration (fetch metadata, verify signing cert)
3. Login flow: user enters email → domain matched to org SSO config → redirect to IdP → SAML assertion or OIDC token returned → validate → just-in-time user provisioning or lookup → log in
4. SSO-only mode: password login disabled for users in the org
5. Admin can exempt specific users from SSO-only (for break-glass scenarios)
6. SCIM provisioning (nice to have): auto-create/deprovision users as IdP sends SCIM events

---

### P2-2 — Magic links / passwordless email login

**Who**: Persona A for low-friction consumer apps.

**The job**: Users receive a one-time login link by email. No password required. Phoenix 1.8's generator already leans this way — the library should provide it as a polished first-class option.

**Key flows**:
1. Login page has email field with "Send me a login link" button (instead of or in addition to password)
2. Rate-limited email send (prevent flooding)
3. Email contains single-use signed link valid for 15 minutes
4. Click → validate token → create session → redirect to app → token consumed

---

### P2-3 — OAuth2 server (act as an identity provider)

**Who**: Persona E and platform builders.

**The job**: Issue OAuth2 access tokens to third-party clients. Authorization Code + PKCE flow. Scoped access. Wrap/integrate with the Boruta library.

**Key flows**:
1. Register an OAuth2 client application (client_id, client_secret, redirect_uris, allowed scopes)
2. Authorization endpoint: user approves scope → authorization code issued
3. Token endpoint: code exchanged for access + refresh tokens
4. Token introspection endpoint
5. User-facing "Authorized Applications" page to revoke grants

---

### P2-4 — Phone / SMS OTP (second factor)

**Who**: Persona B. Needed as an MFA fallback.

**The job**: Register a phone number. Receive SMS OTP for login or as second factor. Built on a configurable SMS adapter (Twilio, Vonage, etc.).

**Key flows**:
1. User adds phone in security settings → sends verification SMS → confirms
2. On login with MFA: system can send SMS OTP as alternative to TOTP
3. Rate-limited: 3 SMS sends per 10 minutes per user
4. Developers configure SMS adapter:
   ```elixir
   config :my_app, MyApp.Auth, sms_adapter: MyApp.Auth.Adapters.Twilio
   ```

---

## Cross-Cutting Concerns (Must Address in Every Flow)

### Security defaults (on by default, opt-out)
- Email enumeration prevention in all flows (login, register, forgot password, email change)
- CSRF protection integrated with Phoenix's existing token system
- Constant-time comparisons for all token and password validations
- `HttpOnly`, `Secure`, `SameSite=Lax` on all auth cookies
- Argon2id for all password hashing (bcrypt supported with transparent migration)
- Rate limiting on all unauthenticated endpoints

### LiveView integration requirements
Every flow that modifies session state (login, logout, confirm email, verify MFA) must happen via HTTP POST, not LiveView events, because `put_session/3` is only available on `conn`. The pattern:
- LiveView form uses `phx-trigger-action` pointing to an HTTP action
- Controller handles the sensitive state mutation
- Redirects back to LiveView with updated session
The library must provide boilerplate that makes this pattern easy and correct, not something every developer has to figure out independently.

### PubSub / socket disconnect on session events
When a session is revoked (logout all devices, password change, admin revocation), connected LiveView sockets for that user must be disconnected. The library must publish to the app's PubSub channel and provide the `on_mount` hook that subscribes to it:
```elixir
# Library broadcasts:
Phoenix.PubSub.broadcast(MyApp.PubSub, "user:#{user.id}:auth", :logout)
# on_mount hook subscribes and calls push_navigate to login on receipt
```

### Testing helpers
Every flow must be exercisable without a real browser, email server, or SMS provider. Ship ExUnit helpers:
```elixir
import MyApp.Auth.TestHelpers

# In setup:
{:ok, user} = register_confirmed_user(%{email: "test@example.com"})
conn = log_in_user(conn, user)
socket = log_in_socket(socket, user)
{:ok, token} = create_api_key(user, scopes: ["read:all"])
{:ok, _} = enroll_totp(user)           # returns secret + backup codes
org = create_org_with_member(user, role: :admin)
```

### Observability / telemetry
Emit `:telemetry` events for all major operations so teams can pipe into their existing metrics:
- `[:my_app, :auth, :login, :start | :stop | :exception]`
- `[:my_app, :auth, :token, :validated]`
- `[:my_app, :auth, :mfa, :challenge_issued]`
Metadata includes: user_id (if known), ip, provider, outcome.

### Configuration surface philosophy
Single, flat, compile-time config module (not scattered across multiple `config.exs` keys). Every option has a sensible default. Options are validated at startup with helpful error messages. Behavior can be overridden per-request by defining callbacks:
```elixir
defmodule MyApp.AuthConfig do
  use MyApp.Auth.Config

  # static config
  token_ttl session: {2, :hours}, reset: {1, :hour}
  password_min_length 12
  confirm_email_on_registration true

  # dynamic per-request override
  def after_login(conn, user) do
    if user.admin?, do: redirect(conn, to: "/admin"), else: redirect(conn, to: "/dashboard")
  end

  def after_registration(conn, user) do
    MyApp.Analytics.track("user_registered", user_id: user.id)
    conn
  end
end
```

---

## Flow Priority Summary

| Priority | Flow | Personas |
|----------|------|---------|
| P0 | Install & basic email/password auth | All |
| P0 | Protect routes, get current_user everywhere | All |
| P0 | Social login (Google, GitHub minimum) | A, B |
| P0 | Email confirmation | All |
| P0 | Password reset | All |
| P0 | Session security (remember me, timeout, invalidation) | All |
| P1 | TOTP / MFA full lifecycle | B, E |
| P1 | API bearer token auth | C, B, E |
| P1 | Passkeys / WebAuthn | B, E |
| P1 | Organization multi-tenancy + invitations | B, E |
| P1 | Audit logging | B, E |
| P1 | Account lockout + brute-force protection | All |
| P1 | Session management UI | B, E |
| P1 | Email change with re-verification | All |
| P1 | Sudo mode | B, E |
| P2 | Enterprise SSO (SAML/OIDC per org) | E |
| P2 | Magic links / passwordless | A |
| P2 | OAuth2 server (be the IdP) | E, platforms |
| P2 | Phone/SMS OTP | B |
