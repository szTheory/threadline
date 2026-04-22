# Building the gold-standard Elixir/Phoenix authentication library

**Elixir's authentication ecosystem has a glaring gap: no comprehensive, maintained, Phoenix 1.8-compatible auth library exists.** Developers today must wire together 3–5 separate tools — `phx.gen.auth`, Ueberauth or Assent, NimbleTOTP, and piles of custom code — to achieve what Ruby's Rodauth, Laravel's layered stack, or Node's Better Auth deliver out of the box. The Phoenix core team's philosophical commitment to generators over libraries means this gap will not be filled by the framework itself. With Pow effectively dead on Phoenix 1.8+, the window is open for a well-designed library to become the community standard. This report synthesizes the full landscape across ecosystems, community needs, security standards, and architectural patterns to serve as the foundational context document for building that library.

---

## 1. The Elixir auth ecosystem is fragmented and incomplete

### Pow is dead for modern Phoenix

Pow (~1,662 GitHub stars) was the closest thing Elixir had to a "Devise equivalent." Its dependency constraint **explicitly blocks Phoenix 1.8+** (`phoenix >= 1.3.0 and < 1.8.0`, `phoenix_html >= 2.0.0 and < 5.0.0`). The last significant commit was August 2024. No forks are actively porting it to Phoenix 1.8. Pow's architecture — wrapping Ecto schemas behind macros like `use Pow.Ecto.Schema` — is fundamentally at odds with the Phoenix team's philosophy. Dan Schultzer continues maintaining point releases (v1.0.39 in January 2025), but the library is architecturally divergent from where Phoenix is heading. Pow provided registration, login, password reset, email confirmation, persistent sessions, invitations, and OAuth via the companion PowAssent package. All of that capability is now orphaned for anyone on Phoenix 1.8+.

### phx.gen.auth: solid foundation, significant gaps

Phoenix's built-in code generator (`mix phx.gen.auth`) is a **generator, not a library**. It copies code directly into your application — a `User` schema, `UserToken` schema, an `Accounts` context, `UserAuth` plugs, LiveView pages, migrations, and a full test suite. Phoenix 1.8 made substantial improvements: **magic links by default** (registration requires only an email; passwords are optional), a **sudo mode** plug for sensitive operations, and **scopes** (`Accounts.Scope`) as a first-class authorization primitive.

What it covers: registration, login/logout, email confirmation, password reset, remember me, account settings, and magic links. What it explicitly does not cover:

- No OAuth/social login (Google, GitHub, etc.)
- No MFA/2FA (no TOTP, backup codes, WebAuthn)
- No API token authentication (guides show manual implementation)
- No rate limiting on login attempts
- No account lockout
- No passkeys/WebAuthn
- No RBAC beyond basic scopes
- No SSO (SAML/OIDC)
- No session management UI (view/revoke sessions)

The generator approach means **security patches don't auto-update** — developers must manually port changes from Phoenix changelogs. Community member debian3 summarized the frustration: "Gen.auth lacks built-in features such as SSO social login, API authentication, email confirmation, and magic links... the current state makes it difficult to get started due to a lack of documentation and the problem of tests breaking upon customization."

### The supporting cast: Ueberauth, Assent, Guardian, NimbleTOTP

**Ueberauth** (~1,700 stars) is Elixir's Passport.js equivalent with **50+ community strategies** (Google, GitHub, Facebook, Apple, Discord, and many more). But it shows its age: individual strategy packages have inconsistent maintenance, version conflicts between strategies and the core library are reported, and it only handles the OAuth flow — not session management or user creation. Passport.js has 500+ strategies by comparison.

**Assent** (513 stars, by Dan Schultzer of Pow) is the more modern alternative with **20+ built-in providers** in a single package, PKCE support, native OIDC compliance, and framework-agnostic design. It's actively maintained (last updated July 2025) and recommended by community members who've used both: "I've had better experience with assent (without pow) than with ueberauth." Assent is the better foundation for a new library.

**Guardian** (~3,400 stars) handles JWT token-based auth only — encoding, signing, verification, and Plug integration. It provides no user management, no registration, no OAuth, no email flows. Primarily relevant for API authentication with mobile/SPA clients. Maintenance is low-activity.

**NimbleTOTP** (by Dashbit) is a focused 4-function library implementing RFC 6238 TOTP codes. It generates secrets, creates otpauth URIs for QR codes, generates verification codes, and validates them. It does **not** handle backup codes, MFA enrollment flows, enforcement logic, UI, database integration, or rate limiting. Developers must build the entire 2FA lifecycle manually.

### Other notable libraries

**NimbleZTA** (December 2025, by José Valim/Dashbit) handles Zero Trust Authentication for internal apps behind Cloudflare, GCP IAP, or Tailscale — not relevant for public-facing user auth. **Magic Auth** (January 2025) is a new library focused narrowly on magic link auth for rapid prototyping. **Boruta** implements an OAuth2/OIDC server (acting as a provider). **Coherence** and **Phauxth** are effectively dead. **Permit** (by Curiosum) handles authorization (RBAC), not authentication.

### What the community is saying right now

The dominant pattern in 2025–2026 is: start with `phx.gen.auth`, manually integrate Assent or Ueberauth for social login, add NimbleTOTP for 2FA, and write custom code for everything else. This means **days to weeks building auth infrastructure** that takes hours in other frameworks.

José Valim himself acknowledged the tension: "I have thought about launching 'Devise for Phoenix' probably hundreds of times... I never found a proper way to approach the problem." His conclusion was that generators beat libraries because "I don't want to see my Ecto schema fields hidden behind a macro." This philosophy is deeply embedded in Phoenix's DNA, and any new library must respect it.

The top 5 community pain points are: (1) no single comprehensive solution, (2) OAuth requires significant manual plumbing, (3) MFA has no integrated solution, (4) generated code doesn't auto-update with security patches, and (5) API authentication is a second-class citizen. **No RFC, proposal, or community initiative** for a comprehensive auth library exists as of April 2026.

---

## 2. Prior art reveals what "gold standard" actually means

### Devise: the cautionary tale of magic

Ruby's Devise (v5.0.3, ~24,000 stars, **270 million downloads**) defined the "batteries-included auth library" category. Its 10 modules cover every basic auth need:

**database_authenticatable** (bcrypt password storage and verification), **registerable** (sign-up, edit, delete account), **recoverable** (password reset via email tokens), **rememberable** (persistent "remember me" cookies), **trackable** (sign-in count, timestamps, IP logging), **validatable** (email/password format validation), **confirmable** (email verification with grace period), **lockable** (account lockout after N failed attempts with email/time unlock), **timeoutable** (idle session expiration), and **omniauthable** (OmniAuth social login integration).

The `devise-two-factor` gem (v6.3.0) adds TOTP with encrypted secret storage and backup codes, but no WebAuthn or SMS. OmniAuth integration auto-generates OAuth routes and provides a callback controller pattern.

**Devise's weaknesses are instructive.** The library hides controllers, views, and routes inside the gem — described as "a mini Rails app inside a Rails app." Customization requires subclassing internal controllers, understanding parameter sanitizer patterns, and navigating multi-layer configuration spread across initializers, model declarations, controller overrides, and route configurations. No built-in MFA, no JSON API support, no rate limiting (only account lockout), and tight Rails coupling. These are the exact mistakes to avoid.

### Rodauth: the architectural gold standard

Jeremy Evans' Rodauth (v2.43.0, ~1,800 stars) is widely considered **architecturally superior to Devise** despite having a fraction of its users. It offers **40+ features** organized as self-contained plugins:

Core authentication (login, logout, create/close account, change password/login, reset password, verify account, remember, lockout). **Built-in MFA** — TOTP, WebAuthn (with autofill, passwordless login, and account verification), SMS codes, and recovery codes. Passwordless authentication via email links and WebAuthn. Advanced password features including **Argon2id support**, password complexity checks, common password blocking, password reuse prevention, password expiration, and a remarkable **`update_password_hash` feature** for transparent migration between hash algorithms. Session management with active session tracking, single-session enforcement, and expiration. **Full JSON API and JWT support** for every feature, including refresh tokens and CORS. Audit logging. And a unique **Internal Request API** for programmatic auth operations in background jobs or admin tools.

Rodauth's key architectural innovations that a new Elixir library should emulate:

**Encapsulated auth object.** All auth logic lives in a single `Rodauth::Auth` instance per request — not spread across models, controllers, and routes. This is the single most important design decision.

**Uniform configuration DSL.** Every method supports both static values and dynamic per-request blocks: `login_redirect "/dashboard"` or `password_minimum_length { internal_request? ? 3 : 15 }`. No multi-layer configuration confusion.

**Database security innovation.** Rodauth stores password hashes in a separate table accessible only via PostgreSQL `SECURITY DEFINER` functions. Even if the application database is fully compromised via SQL injection, password hashes remain protected. This is unique among auth libraries.

**HMAC-protected tokens.** Email tokens use HMAC so leaked database tokens are useless without the HMAC secret. Account IDs are embedded in tokens to limit brute-force scope.

**Feature self-containment.** Each feature is one file containing all its routes, methods, configuration, and templates. No action-at-a-distance.

The companion `rodauth-rails` gem bridges it into Rails with generators for migrations, configuration, views, and mailers — proving that Rack middleware + framework bridge is a viable architecture.

### Better Auth: the modern benchmark

Better Auth (26,100 stars, launched September 2024) has become **the definitive JavaScript auth library** after Auth.js v5 never left beta and Lucia was deprecated in March 2025. Better Auth absorbed Auth.js in September 2025 and raised a **$5M seed round** from Y Combinator and Peak XV. It's the most relevant modern benchmark.

Better Auth's plugin architecture is its defining innovation. The core handles email/password auth, social OAuth, session management, and email verification. Everything else is a composable plugin: `twoFactor()` for TOTP/SMS/backup codes, `passkey()` for WebAuthn, `magicLink()` for passwordless, `organization()` for teams with roles and invitations, `admin()` for user management and impersonation, `apiKey()` for scoped API keys, `sso()` for SAML enterprise SSO, `scim()` for directory sync, and even `stripe()` for payment integration. Plugins can define custom API endpoints, extend database schemas, add middleware, and fire hooks — with full TypeScript type propagation from server to client.

Its database approach is notable: **accepts raw database connections** (PostgreSQL pools, SQLite files, MySQL connections) alongside ORM adapters, plus a CLI that auto-generates schemas and runs migrations. This reduces the adapter abstraction that killed Lucia (whose maintainer explicitly cited adapter complexity as the reason for deprecation).

### Django Allauth: the feature completeness standard

Django Allauth (10,300 stars, 65+ releases in 2024–2025) sets the standard for feature completeness. It supports **100+ social providers**, built-in MFA (TOTP, WebAuthn/passkeys, recovery codes, "trust this browser"), email verification, phone verification, a headless API mode with JWT support, and even an **identity provider module** (OAuth2/OIDC server). Its architecture splits into discrete Django apps: `allauth.account`, `allauth.socialaccount`, `allauth.mfa`, `allauth.headless`, `allauth.idp`, and `allauth.usersessions`.

Key design patterns worth borrowing: progressive authentication states (partially authenticated pending 2FA), email-based social account linking with configurable trust per provider, account enumeration prevention as a first-class feature, and a session tracking system that detects IP/user-agent changes.

### Laravel: the layered architecture model

Laravel's auth ecosystem demonstrates how to serve different complexity levels with a **layered architecture**:

**Breeze** generates minimal auth scaffolding (registration, login, password reset, email verification) directly into the project — fully modifiable, no library dependency. **Jetstream** adds 2FA, session management, API tokens via Sanctum, and team management as an opinionated full-stack scaffold. **Fortify** provides the headless backend that Jetstream consumes — all auth logic without any UI. **Sanctum** handles API tokens (simple opaque bearer tokens in database) and SPA authentication (cookie-based sessions). **Passport** provides a full OAuth2 server when you need to be an identity provider.

The key insight: **progressive complexity with clear boundaries**. A developer starts with Breeze, upgrades to Jetstream when they need teams/2FA, adds Sanctum for API auth, and reaches for Passport only when building an OAuth2 server. Each layer has a single responsibility. All packages are first-party, guaranteed compatible.

### Go's service-oriented approach

Go's ecosystem favors auth-as-a-service. **Ory Kratos** (11,000+ stars) is a standalone identity service with HTTP/gRPC APIs covering login, registration, MFA, social sign-in, passwordless, session management, and account recovery. **Ory Hydra** (15,000+ stars) is a certified OAuth2/OIDC server that deliberately excludes user management. **Authboss** is the closest to a traditional library, with modular auth features (auth, confirm, recover, register, remember, lock, expire, OAuth2, 2FA) and interface-based storage abstraction. The lesson from Go: the service/middleware pattern has merit for separation of concerns, and interface-based storage abstraction (rather than ORM coupling) enables maximum flexibility.

---

## 3. Comprehensive feature requirements for a Phoenix auth library

### Core authentication flows

**Email/password** with Argon2id hashing (OWASP's gold standard — memory-hard, GPU/ASIC resistant; `argon2_elixir` via Comeonin). Support bcrypt as a fallback with transparent migration between algorithms on login. NIST-compliant password policies: minimum 8 characters with MFA, maximum 64+, no composition rules, no forced rotation, strength meter support. **Magic links/passwordless email** — already the Phoenix 1.8 default direction. **Passkeys/WebAuthn** — the Wax library provides the FIDO2 primitives for Elixir; wrap it with a complete registration/authentication ceremony flow. **Social OAuth** — table-stakes providers are Google, GitHub, and Microsoft (Tier 1), then Apple and Facebook (Tier 2). Build on Assent's 20+ built-in strategies with a clean integration layer. **Phone/SMS OTP** — support it but discourage as primary MFA due to SIM swap risks.

### Session management

Server-side sessions with **database-backed token storage** (the `phx.gen.auth` pattern — token reference in cookie, data in database). Support for JWT/bearer tokens for API clients only. Remember-me via separate long-lived signed cookie (60-day default). **Active session tracking** — store IP, user agent, last-active timestamp per session; expose a UI for users to view and revoke sessions. Invalidate all sessions on password change. Session idle timeout (configurable, 30-minute default) and absolute timeout (24-hour default). Support `SameSite=Lax`, `HttpOnly`, and `Secure` cookie flags by default.

### Security features

**Argon2id** as the default hashing algorithm with a 200–500ms target hash time. Brute force protection via **both IP-based and account-based rate limiting** (use Hammer or ETS; 10 attempts/minute/IP, 5 failed attempts/account before CAPTCHA/lockout). Temporary account lockout (15–30 minutes, never permanent — permanent lockout is a DoS vector). **Email enumeration prevention** by default: generic messages on login failure, registration sends email to existing address rather than revealing existence, constant-time comparisons, dummy hash computation for nonexistent accounts. CSRF protection integrated with Phoenix's existing CSRF infrastructure. Secure password reset flows with HMAC-protected, time-limited, single-use tokens. Suspicious login detection (new IP/device triggers email notification).

### Multi-factor authentication

**TOTP** via NimbleTOTP or a reimplementation (RFC 6238, SHA-1, 6-digit, 30-second step, 1-step skew tolerance). **Backup/recovery codes** — generate 8–10 single-use codes at enrollment, SHA-256 hash before storage, display once, track usage, allow regeneration. **WebAuthn as second factor** and as passwordless primary factor. **Email OTP** (6-digit codes sent via email). SMS OTP as an option with security warnings. **MFA enforcement policies** — require for admin roles, encourage for all users, support step-up authentication for sensitive operations. **"Trust this browser"** cookie to skip MFA on trusted devices (14-day default, à la Django Allauth).

### User management

Email confirmation with both link and code verification. Email change with re-verification (send to new address, keep old until confirmed). Password change with current password verification. **Account deletion** with configurable data handling (soft delete, hard delete, anonymization). Profile management hooks (the library shouldn't own profile fields, but should provide callbacks for profile updates).

### Multi-tenancy and authorization

**Organizations/teams** as a first-class concept with a `memberships` join table carrying tenant-scoped roles. Default RBAC roles: owner, admin, member, viewer — with support for custom roles. **Invitation flow**: admin sends signed invitation token with org/email/role/expiration; if user exists, add membership; if new, create account + membership. Support "verified domains" for auto-join. **Enterprise SSO per organization** — each org can configure its own SAML 2.0 or OIDC provider, with just-in-time user provisioning and optional SSO-only enforcement that disables password login.

### API authentication

**API keys**: cryptographically random (32+ bytes), stored as SHA-256 hashes, shown only once at creation, with human-readable prefixes (`myapp_live_abc123...`), scopes, expiration dates, and rotation support (allow 2 concurrent active keys). **Personal access tokens** (GitHub PAT-style): user-scoped, inherit user permissions filtered by granted scopes, with configurable expiration. **OAuth2 server capability** (acting as an identity provider): Authorization Code flow with PKCE, client credentials for M2M, scoped access tokens + refresh tokens. Boruta already exists for this in Elixir and could be integrated.

### Phoenix-specific integrations

**LiveView compatibility** is critical. The auth flow must work across both HTTP (Plug pipeline for `conn`) and WebSocket (`on_mount` hooks for sockets). Login/logout actions must happen via HTTP POST (not LiveView events) because `put_session` isn't available in LiveView handlers — use `phx-trigger-action`. Group routes with `live_session` blocks sharing auth requirements. Broadcast disconnect on logout: `Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})`. Build on Phoenix 1.8's Scope struct pattern, extending it to carry organization context. **Oban integration** for background email delivery, session cleanup, and token expiration jobs. **Absinthe/GraphQL** middleware for auth context injection. **Phoenix Channels** authentication via Guardian-style token verification or session-based auth in the socket connect callback.

### UI components and developer experience

**Pre-built LiveView components** for login, registration, forgot password, MFA setup/verification, session management, and OAuth buttons — styled with Tailwind CSS by default. **Headless mode** — all logic works without any UI; components are optional. **Mix tasks/generators**: `mix auth.install` (initial setup with migrations, schemas, config), `mix auth.gen.oauth` (add social login), `mix auth.gen.mfa` (add 2FA support), `mix auth.gen.api` (add API key support). **Testing helpers**: `log_in_user/2`, `register_user/1`, `setup_totp/1`, `create_api_key/2` for ExUnit. **Migration generation** per feature (like Rodauth's per-feature table approach).

---

## 4. Architecture: the hybrid approach

### Library + generator is the right model

The Elixir community strongly favors code generators. José Valim's philosophy — "I don't want to see my Ecto schema fields hidden behind a macro" — is non-negotiable context. But a pure generator has a fatal flaw: **security patches don't propagate**. The right model is a **hybrid**: security-critical code lives in the library (password hashing, token generation/verification, TOTP validation, WebAuthn ceremonies, HMAC operations, rate limiting logic), while customizable application code is generated (routes, controllers/LiveViews, templates, Ecto schemas, context modules).

This means: `mix auth.install` generates files you own and modify freely, but those files call into library functions for all security-sensitive operations. When a vulnerability is found in token verification, you update the library dependency — no manual patching. When you want to add a field to the registration form, you edit the generated LiveView — no fighting framework internals.

### Plug/Router integration

Follow Rodauth's middleware pattern adapted for Phoenix. Define an `AuthPlug` that runs in the Plug pipeline, creates a per-request auth context object (similar to Rodauth's `Auth` instance), and makes it available as `conn.assigns.auth` and `socket.assigns.auth`. This object handles all auth operations without polluting the User schema with auth methods. Router integration via a `require_auth` plug, `require_mfa` plug, `require_role` plug, and `require_sudo` plug that compose in Phoenix router pipelines.

### Database schema design

Follow Rodauth's principle of **separate tables per concern**, not Devise's "everything on the users table":

The core tables needed are: **users** (id, email, hashed_password, confirmed_at, locked_at, failed_login_attempts), **user_tokens** (user_id, hashed token, context like "session"/"confirm"/"reset", sent_to, timestamps), **oauth_accounts** (user_id, provider, provider_uid, encrypted access/refresh tokens, expiration), **passkey_credentials** (user_id, credential_id, public_key, sign_count, friendly_name), **mfa_credentials** (user_id, type, encrypted secret, hashed backup codes, enabled_at), **organizations** (name, slug, JSONB settings for SSO config), **memberships** (user_id, organization_id, role), **invitations** (organization_id, email, role, hashed token, expiration), **api_keys** (user_id, organization_id, hashed_key, key_prefix, scopes, expiration, revoked_at), and **audit_log** (user_id, organization_id, action, JSONB metadata with IP/user-agent).

Use UUIDs for primary keys. Use `citext` for email columns. Encrypt sensitive fields (OAuth tokens, TOTP secrets) at the application level with Cloak/Vault. Hash tokens before storage. Index heavily: `user_tokens(token, context)`, `oauth_accounts(provider, provider_uid)`, `api_keys(hashed_key)`.

### Extensibility without forking

Adopt a **behaviour + callback architecture** inspired by Rodauth's DSL and Better Auth's plugin system. Define Elixir behaviours for each auth concern (`AuthLib.PasswordAuth`, `AuthLib.OAuth`, `AuthLib.MFA`). Generated modules implement these behaviours with default implementations. Developers override specific callbacks without touching library internals. Support a plugin system where third-party packages can register new auth methods, schema extensions, and routes. Use Phoenix's existing hook points: `on_mount` for LiveView, Plug pipelines for HTTP, and PubSub for cross-process events.

### Multi-database support

Build on Ecto's adapter system. Target **PostgreSQL as the primary** (leveraging `citext`, JSONB, and potentially security-definer functions à la Rodauth). Support MySQL and SQLite via conditional migration generation (detect adapter, generate appropriate SQL). Avoid PostgreSQL-specific features in the core library; isolate them behind adapter modules.

---

## 5. What the community specifically wants

### Recurring themes from ElixirForum, Reddit, and HN (2024–2026)

The single most common request is an **integrated OAuth/social login** that works with `phx.gen.auth` out of the box. Developer woylie on ElixirForum described building "an identity provider this year with passwords, passkeys, OIDC (Google/Apple), TOTP, recovery codes, and support for multiple email addresses per user" — using `phx.gen.auth` + `ueberauth` + `nimble_totp` + `wax`. That's four libraries plus extensive custom code for what should be a standard auth setup.

The second most common request is **complete MFA that actually works end-to-end**: enrollment UI, QR code generation, backup codes, enforcement policies, and session handling for the "pending 2FA" state. NimbleTOTP's 4-function API leaves everything else to the developer.

Developers migrating from Rails, Laravel, or Django consistently express surprise at the manual effort required. A Go developer evaluating Phoenix wrote: "I would prefer not to have to write my own auth system, especially with security considerations in mind." Mike Zornek criticized Phoenix 1.8's magic-link-only default: "this adds friction to the deployment of Phoenix toy projects... Requiring the developer to acquire transactional email services is one more thing to deploy."

No RFC or community proposal for a comprehensive auth library exists. Dashbit's strategy is focused "nimble" libraries (NimbleTOTP, NimbleZTA) rather than a monolithic solution. The gap is explicitly waiting to be filled.

---

## 6. Competitive positioning: what makes this library win

### The elevator pitch

"The authentication library Phoenix deserves — comprehensive, secure, and extensible without magic. Start with one command, ship with social login, MFA, and API keys. Security updates flow through dependency bumps, not manual patches. Own your code, trust your auth."

### Non-negotiables for community adoption

**Phoenix 1.8+ native** with full LiveView integration, scopes, and magic link support. **Hybrid library + generator** — security in the dependency, UX in your codebase. **Integrated OAuth** — Google, GitHub, Microsoft, Apple working in under 10 minutes via Assent. **Built-in MFA** — TOTP + backup codes + WebAuthn, with complete enrollment flows and LiveView components. **API authentication** — API keys and bearer tokens without reaching for Guardian or rolling your own. **Email enumeration prevention and rate limiting** on by default. **Comprehensive test helpers** so auth doesn't break when you customize.

### Nice-to-haves that differentiate

Passkey/WebAuthn as a primary passwordless login method. Organization/team multi-tenancy with RBAC. Enterprise SSO (SAML/OIDC per organization). OAuth2 server capability. Audit logging. Session management UI component. Admin impersonation. "Trust this browser" for MFA. SCIM directory sync.

### What makes it better than everything that exists

Better than **phx.gen.auth** because it adds OAuth, MFA, API keys, rate limiting, and security patch propagation. Better than **Pow** because it works on Phoenix 1.8+, embraces generators over macros, and includes MFA/passkeys. Better than **the Ueberauth/NimbleTOTP patchwork** because it provides an integrated experience instead of requiring developers to wire 4 libraries together. Better than **Devise** because it avoids hidden magic, uses a unified configuration surface, and includes MFA and API support natively. Inspired by **Rodauth's architecture** (encapsulated auth object, per-feature tables, HMAC tokens, uniform DSL) and **Better Auth's plugin system** (composable features, typed configuration, auto-generated schemas), adapted for Elixir's functional paradigm and Phoenix's Plug/LiveView architecture.

The library that wins the Elixir community will be the one that respects José Valim's "own your code" philosophy while solving the practical reality that most Phoenix developers spend days building auth infrastructure that should take minutes. The hybrid approach — security as a library, application code as a generator, extensibility as behaviours and plugins — is the architecture that threads this needle.