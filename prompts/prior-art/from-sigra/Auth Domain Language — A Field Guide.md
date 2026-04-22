# Auth Domain Language — A Field Guide

> You're a senior engineer. You don't need auth explained like a tutorial. You need the *vocabulary* to think and talk about it precisely, the *mental models* to reason about the subtle parts, and a *map* of how everything connects. That's what this is.
>
> Read it front to back once. Then use it as a reference.

---

## Part 1 — The Big Picture

### Authentication vs. Authorization

These two words get conflated constantly. They are completely different problems.

**Authentication** answers: *"Who are you?"*
You prove your identity. The system decides whether to believe you.

**Authorization** answers: *"Are you allowed to do this?"*
The system decides what an authenticated identity may access or perform.

Most auth libraries only do authentication. Authorization (RBAC, permissions, policies) is a separate layer built on top. This library is primarily an authentication library. It gives you identity context; what you do with that context is your app's business.

A useful analogy: a hotel keycard system. Authentication is the front desk checking your ID and issuing a keycard. Authorization is the keycard opening room 412 but not room 413. Two separate systems, two separate decisions.

---

### Identity vs. User vs. Account

These three nouns are often treated as synonyms. They're not.

**Identity** is the abstract concept: the claim "this is who I am." An identity can be asserted in many ways — password, Google account, passkey, SAML assertion from your employer's SSO. One human person may have many identities attached to the same account.

**User** is the application-level entity: the row in your database. It has a name, preferences, subscription status, etc. It's the domain object your application cares about.

**Account** is the auth-level entity: the record tracking authentication credentials and security state. In simple apps, User and Account are the same row. In sophisticated systems they're separate. This library keeps them merged by default but the distinction matters when you add SSO or OAuth — one User can have multiple authentication identities linked to it.

Practical consequence: when a user logs in with Google, you need to:
1. Receive an OAuth identity from Google
2. Find the User in your database that this identity belongs to
3. Create an application session for that User

Steps 1 and 3 are auth. Step 2 is your application's account-linking logic.

---

### The Two Root Problems Auth Solves

Every auth feature in this library ultimately solves one of two root problems:

**Problem 1: Proving identity over the network.**
Networks are untrusted. HTTP is stateless. You can't just "know" who's on the other end. Every authentication flow is a protocol for convincing the server that the entity making a request is who they claim to be.

**Problem 2: Staying authenticated across requests.**
Once identity is proven, you don't want to re-prove it on every request. You need a way to carry the proof forward. That carrier is called a **session** or a **token**. Most of auth's complexity lives here.

---

## Part 2 — Core Nouns

### Credential

A credential is *something you use to prove identity*. There are three classical categories:

| Category | What it is | Examples |
|---|---|---|
| Something you **know** | A secret only you know | Password, PIN, security question |
| Something you **have** | A physical or software object | Phone (TOTP app), hardware key, email inbox |
| Something you **are** | Biometrics | Face ID, fingerprint (handled by the OS, not your app) |

A **password** is a knowledge credential. It's hashed before storage — the server never stores what you typed, only a one-way transformation of it.

A **TOTP code** is a possession credential — you have to have the authenticator app (which has the secret) to generate the correct code.

A **passkey** is a cryptographic possession credential — your device holds a private key; the server holds the matching public key.

An **OAuth token** from Google is a delegation credential — you're proving identity *by having Google vouch for you*.

---

### Session

A session is the server's record that authentication happened.

After a user logs in, the server:
1. Creates a session record (in the database, or encodes one into a signed token)
2. Gives the client a **session identifier** — typically a random token stored in a cookie

On every subsequent request:
1. The client sends the session identifier
2. The server looks it up and finds the associated user
3. The request is treated as authenticated

**Session = the evidence that login occurred.** Destroy the session (logout) and the evidence is gone — the next request from the same browser is unauthenticated.

The session identifier itself is just a random string. Its value comes entirely from the server-side record it references. This is important: if you delete the database record, the cookie in the browser is useless. This is how "log out everywhere" works.

---

### Token

"Token" is overloaded to the point of meaninglessness. In auth it just means "a string that represents something." What it represents depends on context.

The tokens you'll deal with in this library:

**Session token** — opaque random string, stored in a cookie. References a server-side session record. The most common token type for web apps.

**Password reset token** — single-use signed string, sent via email. Valid for ~60 minutes. Proves the user controls the email address.

**Email confirmation token** — same pattern as reset token. Proves email ownership.

**Remember-me token** — like a session token but long-lived (30–60 days), stored in a separate cookie. References a `remember` context record in the database.

**Magic link token** — single-use signed string sent via email. Proves email ownership *and* serves as authentication in one step.

**API key** — long-lived opaque token, typically formatted like `myapp_live_<random>`. Used in `Authorization: Bearer` headers. Never expires automatically unless you configure it to.

**Personal access token (PAT)** — user-created API key with an optional expiry and scope list. Think GitHub's PATs.

**TOTP secret** — not a token you send, but a shared secret stored (encrypted) in your database and in the user's authenticator app. Used to generate and verify 6-digit codes.

**OAuth authorization code** — short-lived code (seconds) returned by an OAuth provider after user consent. You exchange it for an access token. Never stored; never reused.

**OAuth access token** — proves to a third-party provider (Google, GitHub) that the user authorized your app. Used for API calls to that provider. Not used to authenticate requests to your app.

**JWT (JSON Web Token)** — a self-contained signed token encoding claims in JSON. The server can verify it without a database lookup. Commonly used for API authentication when you want stateless verification.

> **The key distinction: opaque vs. self-describing**
>
> An opaque token (session token, API key) is meaningless on its own — it's a reference to a server-side record. Fast to issue, requires a database lookup to verify, easy to revoke instantly.
>
> A self-describing token (JWT) encodes its own payload — the server reads it without a database lookup. Fast to verify, harder to revoke (you have to wait for expiry or maintain a blocklist).
>
> For web sessions: use opaque tokens. For stateless APIs and microservices: JWTs have merit. For most Phoenix apps: opaque tokens everywhere.

---

### Scope

A scope is a named permission that limits what a token allows.

Scopes are associated with tokens, not with users. A user might be an admin, but an API key they issue might only have `read:contracts` — narrower than the user's full permissions.

Common scope patterns:
- `read:all` / `write:all` — broad, legacy style
- `contracts:read` / `contracts:write` — resource-first (GitHub-style)
- `admin` / `billing` / `reporting` — role-based scopes

When a request arrives with a bearer token, you check two things: (1) is the token valid? (2) does it have the required scope? Both must pass.

---

### Factor

A "factor" in multi-factor authentication refers to a credential category. Two-factor authentication (2FA) means using credentials from two different categories.

Most 2FA setups are:
- Factor 1: password (something you know)
- Factor 2: TOTP code (something you have — your phone)

If both factors are from the same category (e.g., password + security question) that's not truly 2FA, just two knowledge factors. Real 2FA requires crossing category boundaries.

The library supports: password + TOTP, password + passkey, password + SMS OTP, password + email OTP. Passkey alone can be a single-factor or effectively MFA if the device uses biometrics to unlock the key.

---

### Claim

A claim is an assertion about an identity, typically embedded in a JWT.

```json
{
  "sub": "user_01HX...",      ← subject (who this is about)
  "iss": "myapp.com",         ← issuer (who created this token)
  "aud": "myapp.com",         ← audience (who should accept it)
  "exp": 1734567890,          ← expiry (unix timestamp)
  "iat": 1734481490,          ← issued at
  "email": "jon@example.com", ← custom claim
  "role": "admin"             ← custom claim
}
```

Claims are signed (with HMAC or RSA) but not encrypted — they're base64-encoded, readable by anyone who has the token. Never put secrets in claims.

---

### Provider

In the OAuth context, a "provider" is the external service that authenticates a user on your behalf.

Google is an OAuth provider. GitHub is an OAuth provider. Your company's Okta is an OAuth provider (or SAML identity provider — slightly different protocol).

When a user "logs in with Google," Google is doing the authentication. They're vouching to your app that this person is who they claim to be. Your app receives an OAuth callback with a user ID, email, and profile info. You trust this because you initiated the flow and can verify the cryptographic signature on the response.

---

### Tenant / Organization

In multi-tenant SaaS, a **tenant** is an isolated unit of users who share data within that unit but are separated from other tenants. For B2B SaaS, a tenant is usually a company.

**Organization** is the common Phoenix/Rails term for a tenant with members. An organization has:
- An identity (name, slug)
- Members (users who belong to it, with roles)
- Settings (including auth settings like SSO config)
- Data (your actual application data, scoped to this org)

The auth library manages organization membership and invitations. Your application manages the organization's data.

---

## Part 3 — Core Verbs

### Register

Creating a new identity in the system. Registration collects credentials (email + password, or delegated to OAuth). The key questions:
- What do you collect at registration? (email only? name? username?)
- Is email confirmation required before access is granted?
- Is the registration open (anyone) or invite-only?

Registration creates a User record and a set of initial credentials.

---

### Authenticate

Verifying a claimed identity. The user presents credentials; the system checks them. A successful authentication creates a session.

Authentication can be:
- **Direct** — you verify credentials yourself (password against hash, TOTP code against secret)
- **Delegated** — you outsource verification to a third party (OAuth: "Google, is this really alice@gmail.com?")
- **Federated** — for enterprise SSO, the user's organization's IdP asserts identity (SAML/OIDC)

---

### Authorize

Checking whether an authenticated identity is permitted to perform an action. This is NOT this library's primary job, but the library sets up the context (current_user, current_org, role) that your authorization layer uses.

The three common authorization patterns you'll build on top of this library:
- **Role-based (RBAC)**: user has a role; role has permissions. "Admin can delete; viewer cannot."
- **Attribute-based (ABAC)**: permission depends on attributes of both the user and the resource. "User can edit this contract if they're the assignee or an admin."
- **Organization-scoped**: the user's role is relative to an organization. User X is an admin in Org A but a viewer in Org B.

---

### Confirm

Verifying that the user controls a communication channel (email, phone). Confirmation proves "this email address is real and belongs to this person."

Confirmation tokens are sent out-of-band (via email or SMS). The user proves receipt by clicking the link or entering the code.

---

### Revoke

Invalidating a credential or session before its natural expiry. You revoke:
- A specific session (logout from one device)
- All sessions for a user (logout everywhere, or on password change)
- An API key (token compromised)
- An OAuth grant (user wants to disconnect their Google account)
- An invitation (before it's accepted)
- An MFA backup code (after it's used — single-use)

Revocation for opaque tokens is instant — delete the database record. Revocation for JWTs requires a blocklist or waiting for expiry, which is why JWTs are harder to revoke.

---

### Rotate

Replacing a credential with a new one while invalidating the old one. You rotate:
- API keys (periodic security practice, or after suspected exposure)
- Refresh tokens (many OAuth providers issue a new refresh token on each use)
- Signing keys (the secret used to sign tokens)

Key rotation is operationally important: your app should support having two valid signing keys simultaneously during the rotation period, so old tokens remain valid while new ones are issued with the new key.

---

### Enroll

Registering a new authentication method for an existing user. Distinct from initial registration.

Examples:
- Enrolling a TOTP authenticator app (generating a secret, getting the user to confirm with their first code)
- Enrolling a passkey (running the WebAuthn registration ceremony)
- Enrolling a phone number for SMS OTP

Enrollment typically requires the user to be already authenticated (you can't enroll an MFA method without first proving you're the account owner).

---

### Challenge

Presenting an MFA prompt to a user who has passed the first factor but not yet the second.

The challenge state is "partially authenticated" — the user has proven their password, but hasn't yet proven possession of their second factor. The session should record this state. The user should not have full access until the challenge is passed.

This is a distinct session state: `mfa_pending: true`. Routes that require full authentication should reject this state and redirect to the MFA challenge page.

---

### Provision (JIT Provisioning)

Just-in-time user creation when an enterprise SSO user logs in for the first time. The user exists in the company's IdP (Okta, Azure AD) but not yet in your database. When their SAML assertion arrives, you create the user record on the fly — "provisioned just in time."

The alternative is pre-provisioning via SCIM: the IdP pushes user records to your app before they ever log in.

---

## Part 4 — The Main Flows, Explained

### Flow 1: Email/Password Registration + Confirmation

```
User fills form
  → Validate input (email format, password strength)
  → Check email uniqueness (constant-time to prevent enumeration)
  → Hash password with Argon2id
  → Create user row (confirmed_at = nil)
  → Generate confirmation token (random bytes, HMAC-signed, hashed for storage)
  → Send confirmation email (async via Oban)
  → Create session OR redirect to "check your email"
  → [User clicks email link]
  → Validate token (lookup hash, check expiry, check single-use)
  → Set confirmed_at = now
  → Consume token (delete record)
  → Create session → redirect to app
```

**The subtle parts:**
- You hash the token before storing it. The email contains the raw token; the database has only the hash. If your database is breached, the tokens in it are useless.
- Sending the email asynchronously is critical — don't make the user wait for SMTP.
- Enumeration prevention: if the email is already taken, still show "check your email" (send the email to the address saying "someone tried to register with your address"). Don't tell the form submitter that the email exists.

---

### Flow 2: Login (Email/Password)

```
User submits email + password
  → Look up user by email (constant-time: always do this, even if not found)
  → Hash the submitted password with Argon2id and compare to stored hash
  → If no match: increment failed_attempts, check lockout threshold, return generic error
  → If match: check account lockout (locked_at), check confirmed (if required)
  → Generate session token (random bytes, HMAC-signed)
  → Store hashed token in user_tokens table (context: "session")
  → Set cookie: session_token=<raw_token>; HttpOnly; Secure; SameSite=Lax
  → If MFA enrolled: set session mfa_pending=true, redirect to MFA challenge
  → If no MFA: redirect to app
```

**The subtle parts:**
- **Always run the password hash** even if the user isn't found. Argon2id is slow by design (200–500ms). If you skip it for unknown users, response time differences leak whether an email is registered. This is a timing oracle attack.
- **Never say "wrong password" vs "no account"**. Both should return "invalid email or password."
- **MFA creates a two-phase session.** Phase 1: password verified, `mfa_pending: true`. Phase 2: second factor verified, full session. Your route protection must check which phase the session is in.

---

### Flow 3: OAuth / Social Login

The OAuth 2.0 Authorization Code flow has more steps than most developers realize. Here's what actually happens when a user clicks "Log in with Google":

```
1. YOUR APP: Generate a random state parameter + PKCE verifier
   → Store state in session to prevent CSRF
   → Redirect user to Google's authorization endpoint:
      https://accounts.google.com/o/oauth2/auth
        ?client_id=YOUR_CLIENT_ID
        &redirect_uri=https://yourapp.com/auth/google/callback
        &response_type=code
        &scope=email profile
        &state=<random>
        &code_challenge=<PKCE hash of verifier>

2. GOOGLE: User authenticates with Google (not your app)
   → User approves permission scopes
   → Google redirects back to your app with an authorization code:
      https://yourapp.com/auth/google/callback?code=4/abc...&state=<same random>

3. YOUR APP (server-side): Validate state matches (CSRF check)
   → Exchange code for tokens (POST to Google's token endpoint):
      code + client_secret + PKCE verifier → access_token + id_token
   → Parse the id_token (JWT) to get user info:
      { sub: "1234567890", email: "alice@gmail.com", name: "Alice" }

4. YOUR APP: Account linking decision
   → Look up oauth_accounts table by {provider: "google", uid: "1234567890"}
   → Found: log in the associated user
   → Not found, email matches: prompt to link (or auto-link, configurable)
   → Not found, no email match: create new user + oauth_account record

5. YOUR APP: Create session → redirect to app
```

**The subtle parts:**
- **Your app never sees the user's Google password.** Google handles that entirely.
- **The authorization code is single-use and short-lived (~60 seconds).** Never store it.
- **PKCE (Proof Key for Code Exchange)** prevents an attacker who intercepts the callback URL from stealing the code. The server generates a verifier, sends a hash of it to Google, then sends the original verifier when exchanging the code. Google checks they match. No one who just saw the URL can redeem the code.
- **State parameter** prevents CSRF. Generate it fresh per flow, store in session, validate on callback.
- **OAuth access tokens** (from Google) are not your session tokens. They're for calling Google's APIs on the user's behalf. Your session is separate.

---

### Flow 4: MFA — TOTP Enrollment

```
1. User navigates to security settings → "Enable authenticator app"
2. Server: generate 20-byte random secret → base32 encode it
   → Build otpauth URI: otpauth://totp/YourApp:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=YourApp
   → Return QR code of that URI + raw secret for manual entry
   → DO NOT save to database yet

3. User scans QR code in their authenticator app (Google Authenticator, 1Password, etc.)
   → App stores the secret and starts generating 6-digit codes

4. User enters the current 6-digit code to confirm enrollment
5. Server: validate the code (does it match what the secret generates right now ±1 window?)
   → If valid: encrypt the secret, save to mfa_credentials, mark MFA enabled
   → Generate 8 backup codes (random, hashed, single-use), show them once
   → If invalid: don't save anything, ask user to retry
```

**Why you show backup codes exactly once:** The codes are hashed before storage. You literally cannot show them again because you only store hashes. The user must save them now.

**Why ±1 window:** TOTP codes change every 30 seconds. If a user generates a code and the server receives it 1 second after the window rolls over, it would fail. Allowing the previous and next window handles clock drift gracefully.

---

### Flow 5: MFA — Login Challenge

```
User completes password login
  → Server checks: mfa_credentials exists for this user?
  → Yes: create partial session (mfa_pending: true), redirect to /auth/mfa
  → User enters 6-digit TOTP code
  → Server validates code (and checks it hasn't been used this window — replay prevention)
  → If valid: upgrade session to fully authenticated, redirect to original destination
  → If backup code: validate hash, mark code as used, upgrade session
  → If invalid: increment MFA attempt counter, rate-limit after 5 failures
```

**Replay prevention:** TOTP codes are valid for 30 seconds. If an attacker intercepts a code and tries to use it, you need to reject it. Store the last-used TOTP timestamp (and code value) and reject any code generated at the same timestamp. This is called "preventing replay attacks."

---

### Flow 6: Password Reset

```
User submits email on "forgot password" form
  → Show "if that address is registered, check your email" (ALWAYS, regardless)
  → Look up user by email
  → If not found: done (but still show success message — enumeration prevention)
  → If found: generate reset token, hash it, store with context "reset" + 60-min TTL
  → Send email with raw token as URL param: /auth/reset?token=<raw>

User clicks link
  → Extract token from URL
  → Hash it → look up in user_tokens where context = "reset"
  → Not found / expired: show "this link is invalid or expired"
  → Found: show new password form (keep token in hidden field or session)

User submits new password
  → Validate token again (double-check it hasn't been used between page load and submit)
  → Hash new password
  → Update user record
  → Delete ALL session tokens for this user (security: invalidate all active logins)
  → Delete the reset token (consume it)
  → Create new session → redirect to app with success message
```

**The double-validate on submit** is important. If you check the token only when rendering the form, an attacker with the token URL has an unlimited window to try passwords. Check again on submit, and make the form submission itself consume the token.

---

### Flow 7: API Authentication (Bearer Token)

```
Client sends:  GET /api/contracts  Authorization: Bearer myapp_live_abc123...

Server pipeline:
  → BearerAuth plug: extract token from header
  → Hash the token (you never store raw tokens)
  → Look up in api_keys where hashed_key = <hash>
  → Not found: 401 Unauthorized
  → Found: check revoked_at is nil, check expires_at hasn't passed
  → Check required scope: does token.scopes include "contracts:read"?
  → No scope: 403 Forbidden
  → Yes: set conn.assigns.current_user = api_key.user, conn.assigns.token = api_key
  → Continue to controller
```

**The prefix trick:** API keys are formatted as `myapp_live_abc123...`. The prefix `myapp_live_` is stored in plaintext alongside the hash. This lets you:
- Scan leaked credentials in public repos (GitHub Secret Scanning, etc.)
- Let users recognize which key they're looking at in logs
- Distinguish test vs. live keys

The prefix doesn't help an attacker because the actual secret is the long random suffix.

---

### Flow 8: Remember Me (Persistent Sessions)

```
User checks "remember me" on login
  → Create normal session token (30-min or 2-hour TTL by default)
  → Also create a separate remember token (random, hashed, stored with context "remember")
  → Set two cookies:
      _session_token: <session_token>; Expires=session (browser session)
      _remember_token: <remember_token>; Expires=60-days; HttpOnly; Secure

On a request where session_token cookie is missing or expired:
  → Check for _remember_token cookie
  → Hash it → look up in user_tokens where context = "remember"
  → Found: generate a new session token, set session cookie → user is transparently re-authenticated
  → Not found / expired: redirect to login

On logout:
  → Delete BOTH tokens and BOTH cookies
```

**Why two separate tokens?** If you extend the session cookie's expiry to 60 days, a stolen cookie has a 60-day window. By keeping the session short-lived and using a separate remember token to regenerate sessions, you limit the damage window of a stolen session cookie to the session's natural TTL.

---

### Flow 9: Invitation Flow (Multi-Tenant)

```
Admin invites alice@example.com as :admin

Server:
  → Create invitation record: {org_id, email, role, token_hash, expires_at=7-days}
  → Send email with raw token: /invitations/accept?token=<raw>

Alice clicks link:
  → Hash token → look up invitation (check expiry, not already accepted)
  → Is alice already a user? (look up by email)
  
  Path A — Existing user:
    → Show "Join OrgName as Admin?" confirmation
    → Alice confirms → create membership record → mark invitation accepted → log in → redirect to org

  Path B — New user:
    → Show registration form pre-filled with alice's email
    → Alice sets password → user created + confirmed → membership created → log in → redirect to org
```

**Invitation token security:** Same pattern as reset tokens — HMAC-signed, single-use, hashed before storage. If you invalidate the invitation (admin cancels it), just delete the record. The token in the email becomes useless.

---

## Part 5 — Security Concepts, Demystified

### Password Hashing: Why Argon2id and Not MD5/SHA256

MD5 and SHA256 are *fast* hash functions. That's great for checksums. It's terrible for passwords — an attacker with a GPU can try billions of MD5 hashes per second.

Password hashing algorithms are deliberately *slow*. Argon2id is the current gold standard:
- **Memory-hard**: requires a lot of RAM to compute, making GPU attacks expensive
- **Tunable cost**: you set how much time (and RAM) it takes — aim for 200–500ms on your server
- **Configurable argon2id parameters**: time cost (iterations), memory cost, parallelism

bcrypt (older) is still fine. It's CPU-hard but not memory-hard. Argon2id is strictly better. This library defaults to Argon2id, supports bcrypt for legacy users, and transparently migrates bcrypt hashes to Argon2id on next login.

Never write your own password hashing. Use the library. That includes never storing passwords in "encrypted" form — encryption is reversible. Hashing is not. Passwords must be hashed, not encrypted.

---

### Constant-Time Comparison

When you compare a submitted token to a stored hash, naive string comparison leaks timing information:

```
# BAD — returns early on first mismatch, leaks how many characters matched
stored_hash == submitted_hash

# GOOD — always compares all bytes, takes the same time regardless
Plug.Crypto.secure_compare(stored_hash, submitted_hash)
```

An attacker sending thousands of requests can measure response time differences down to microseconds and infer how close their guess is. This is a timing attack. `Plug.Crypto.secure_compare/2` prevents it. The library uses this everywhere — you don't need to think about it.

---

### HMAC-Protected Tokens

When you put a token in an email, you're trusting the recipient's email inbox. What if the database is breached?

Without HMAC protection: attacker reads hashed tokens from `user_tokens` table → can't reverse the hash → useless. ✓

But what if you *didn't* hash them? Attacker reads raw tokens → can use them → catastrophic.

What if you hash them *and* the attacker can brute-force short random tokens? That's why tokens must be long enough (32+ bytes of randomness = 256 bits, unbrutable) *and* hashed before storage.

HMAC adds another layer: the token is signed with a server-side secret. Even if someone somehow crafted a valid-looking token, without the HMAC secret it's rejected. This is what `Phoenix.Token.sign/4` does under the hood.

---

### Email Enumeration

Enumeration means letting an attacker figure out whether an email address is registered by observing your app's behavior.

**Bad (reveals registration status):**
- Login: "No account found with that email"
- Forgot password: "We couldn't find that email address"
- Registration: "That email is already taken"

**Good (reveals nothing):**
- Login: "Invalid email or password"
- Forgot password: "If that email is registered, you'll receive a link"
- Registration: send an email to the address saying "someone tried to register with your address" instead of showing an error

Why does enumeration matter? Attackers use it to build lists of valid emails for phishing. In high-security contexts, the *existence* of a user account can be sensitive information.

---

### CSRF (Cross-Site Request Forgery)

CSRF is when an attacker tricks a logged-in user's browser into making a request to your app.

Example: you're logged into YourApp. You visit evil.com, which contains:
```html
<form action="https://yourapp.com/account/delete" method="POST">
  <input type="hidden" name="confirm" value="true">
</form>
<script>document.forms[0].submit()</script>
```

Your browser sends the request, including your YourApp session cookie, because cookies are sent with all requests to their domain by default.

**CSRF tokens** prevent this: YourApp embeds a secret token in every form. On POST, it checks for the token. Evil.com can't read YourApp's page source (same-origin policy), so it can't get a valid CSRF token.

Phoenix includes CSRF protection built in. This library doesn't need to reimplement it — it uses `Phoenix.Controller.protect_from_forgery` for all its forms.

`SameSite=Lax` (set on cookies by default) also mitigates most CSRF by preventing cookies from being sent in cross-site POST requests.

---

### Rate Limiting vs. Account Lockout

These are two different defenses against brute-force attacks, and you need both.

**Rate limiting** is per-IP: after N failed requests from an IP in a window, return 429. Stops automated attacks from a single source. Implemented with a counter in ETS or Redis (the Hammer library).

**Account lockout** is per-account: after N failed logins for a specific account, lock it temporarily. Stops distributed attacks (many IPs, one target) and protects high-value accounts.

Why not just account lockout? A malicious actor can deliberately lock out every account by submitting wrong passwords, creating a denial-of-service.

Why not just rate limiting? A distributed botnet can spread attempts across thousands of IPs, each under the rate limit.

Use both. Rate limit is the first line; account lockout is the second.

**Never use permanent lockout.** Permanent lockout = denial of service attack vector. Always use temporary lockout with exponential backoff or a fixed window.

---

### Session Fixation

Session fixation is an attack where an attacker sets a known session ID on the victim's browser *before* they log in, then after login, the victim is sharing a session with the attacker.

Prevention: **always generate a new session token after login.** Don't reuse the pre-login session identifier. The library does this automatically.

---

### Sudo Mode

Even with a valid session, you shouldn't allow high-impact operations (change password, delete account, view full API keys) without re-confirming identity. The session might be from a shared computer, or the user might have stepped away.

Sudo mode: before protected routes, check if the user authenticated within the last N minutes. If not, redirect to a confirmation step (re-enter password or TOTP code), then redirect back.

This pattern is used by GitHub ("Confirm access"), AWS, and npm. It's not a complete additional login — just a freshness check.

---

## Part 6 — Phoenix-Specific Concepts

### conn vs. socket — The Two Worlds

Phoenix has two distinct request contexts:

**`conn` (Plug.Conn)** — HTTP requests. Controllers, traditional requests, form submissions. This is the standard web request/response cycle. Session manipulation (`put_session`, `get_session`, `delete_session`) lives here.

**`socket` (Phoenix.LiveView.Socket)** — WebSocket connections. LiveView. Long-lived bidirectional connection established once and then updated via diffs. No traditional request/response cycle. **You cannot call `put_session` in a LiveView.**

The implication for auth:

Any action that needs to *change* session state (login, logout, MFA verify) must happen via HTTP, not LiveView. The pattern is:
1. Use `phx-trigger-action` on a LiveView form to submit it as a regular HTTP POST
2. The controller handles the session mutation
3. Redirect back to LiveView

But reading auth context works fine in LiveView — you use `on_mount` hooks that run when the LiveView mounts, which check the session from the HTTP connection that established the WebSocket.

---

### on_mount Hooks

`on_mount` is how LiveView routes get auth protection. It runs before the LiveView process starts, with access to the connection session.

```elixir
live_session :authenticated,
  on_mount: [{MyApp.Auth, :ensure_authenticated}] do
  live "/dashboard", DashboardLive
  live "/settings", SettingsLive
end
```

The library provides several named hooks:
- `:ensure_authenticated` — redirects to login if not logged in
- `:ensure_mfa_complete` — redirects to MFA challenge if `mfa_pending`
- `:load_current_user` — sets `current_user` on socket without requiring auth
- `:ensure_org_member` — checks org membership from URL params

After the hook runs, `socket.assigns.current_user` is available in your LiveView.

---

### PubSub and Logout Propagation

The problem: a user has 3 browser tabs open. They log in on their phone and revoke all sessions. The 3 tabs still show the app — their WebSocket connections are alive and session-checked only at mount time.

The solution: broadcast a logout event via PubSub when sessions are invalidated. Each LiveView subscribes to the user's auth channel at mount time. On receiving the event, the LiveView redirects to the login page.

```
lib revokes session
  → Phoenix.PubSub.broadcast(App.PubSub, "user:#{user.id}:auth", :logout)

Each LiveView's on_mount hook subscribed to this topic
  → handle_info(:logout, socket) → push_navigate(socket, to: "/login")
```

This is why logout-everywhere actually disconnects open tabs. Without this, users stay "logged in" visually until they navigate or refresh.

---

### The Router: Pipelines and Scopes

Phoenix router plugs run in pipelines. Auth lives in the router as plugs that run before reaching your controllers or LiveViews.

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :protect_from_forgery
  plug MyApp.Auth.LoadCurrentUser    ← always runs: populates current_user or nil
end

pipeline :authenticated do
  plug MyApp.Auth.RequireAuth        ← blocks and redirects if no current_user
end

pipeline :require_mfa do
  plug MyApp.Auth.RequireMFAComplete ← blocks if mfa_pending
end

scope "/", MyAppWeb do
  pipe_through [:browser]
  live "/", LandingLive              ← public, no auth required
  get "/login", AuthController, :login_form
end

scope "/app", MyAppWeb do
  pipe_through [:browser, :authenticated, :require_mfa]
  live "/dashboard", DashboardLive   ← requires full auth + complete MFA
end
```

The key insight: `LoadCurrentUser` runs everywhere (public pages can check `if @current_user`). `RequireAuth` only runs on protected routes (redirects if `current_user` is nil).

---

## Part 7 — The Database Schema, Explained

### Why multiple tables instead of one users table

The naive approach: put everything on `users`. Email, hashed_password, confirmed_at, reset_token, remember_token, totp_secret, failed_login_attempts...

This breaks down because:
1. Each token type has different lifetime and semantics — mixing them in one table is confusing
2. Users may have multiple sessions, multiple OAuth accounts, multiple passkeys — can't be one column
3. Security sensitive data (TOTP secrets, OAuth tokens) deserves isolation
4. You can JOIN to users table but you can also JOIN FROM any direction

The better model — one table per concern:

**`users`** — the domain entity. Email, `confirmed_at`, `locked_at`, `failed_login_attempts`. The minimum auth metadata that belongs here.

**`user_tokens`** — all temporary tokens keyed by context: `"session"`, `"reset"`, `"confirm"`, `"remember"`. One table, context column distinguishes them. Each row: `user_id`, `hashed_token`, `context`, `sent_to` (for email tokens), `inserted_at`. Token lookup: find where `hashed_token = $1 AND context = 'reset' AND inserted_at > now() - interval '1 hour'`.

**`oauth_accounts`** — links users to external OAuth identities. `user_id`, `provider` ("google"), `provider_uid` ("1234567890"), encrypted `access_token` and `refresh_token`, `token_expires_at`, `profile_data` (JSONB). Unique on `{provider, provider_uid}`.

**`passkey_credentials`** — WebAuthn credentials. `user_id`, `credential_id` (bytes), `public_key` (bytes), `sign_count`, `name` ("MacBook Face ID"), `last_used_at`.

**`mfa_credentials`** — `user_id`, `type` ("totp", "webauthn"), `encrypted_secret`, `backup_codes` (array of hashed codes), `enabled_at`.

**`organizations`** — `name`, `slug`, `settings` (JSONB, includes SSO config).

**`memberships`** — `user_id`, `organization_id`, `role`. Unique on `{user_id, organization_id}`.

**`invitations`** — `organization_id`, `email`, `role`, `hashed_token`, `expires_at`, `accepted_at`.

**`api_keys`** — `user_id`, `organization_id` (optional), `hashed_key`, `key_prefix`, `name`, `scopes` (array), `expires_at`, `last_used_at`, `revoked_at`.

**`audit_log`** — `user_id`, `organization_id`, `action`, `ip`, `user_agent`, `metadata` (JSONB), `inserted_at`. Append-only. Never updated.

---

## Part 8 — Quick Reference: Terms That Confuse Everyone

| Term | What it actually means |
|---|---|
| **Authentication** | Proving who you are |
| **Authorization** | Checking what you can do |
| **Session** | Server-side record that login happened; client has a reference token |
| **JWT** | A self-contained token encoding claims; verifiable without a DB lookup |
| **Bearer token** | Any token sent in the `Authorization: Bearer` header |
| **OAuth** | A protocol for *delegated* access, not direct authentication |
| **OIDC** | OpenID Connect — OAuth extended with an `id_token` for authentication |
| **SAML** | Enterprise SSO protocol; XML-based; older than OIDC; still dominant in enterprise |
| **PKCE** | Prevents authorization code interception in OAuth flows |
| **TOTP** | Time-based One-Time Password; 6-digit codes that change every 30 seconds |
| **HOTP** | Counter-based OTP; parent of TOTP; don't use directly |
| **WebAuthn/FIDO2** | Browser API for passkeys; public-key crypto; hardware or biometric backed |
| **Passkey** | A WebAuthn credential stored in your OS/browser/password manager |
| **MFA** | Multiple factor authentication; credentials from 2+ different categories |
| **2FA** | Two-factor authentication; specific case of MFA |
| **SSO** | Single sign-on; authenticate once, access multiple apps |
| **IdP** | Identity Provider; the system asserting identity in federated auth (Okta, Azure AD) |
| **SP** | Service Provider; your app, receiving assertions from the IdP |
| **Claim** | An assertion in a JWT: `{ "role": "admin" }` is a claim |
| **Scope** | A named permission on a token; limits what the token can do |
| **Revoke** | Invalidate a credential before natural expiry |
| **Rotate** | Replace a credential with a new one, invalidating the old |
| **Enroll** | Register an auth method (passkey, TOTP) for an existing user |
| **Provision** | Create a user account, often automatically (JIT provisioning from SSO) |
| **Sudo mode** | Re-confirm identity before a sensitive action, even if already logged in |
| **Enumeration** | Using app responses to discover which emails/usernames are registered |
| **Timing attack** | Inferring secret data from differences in response time |
| **CSRF** | Forging a request from a victim's browser using their existing session |
| **Session fixation** | Attacker sets a known session ID before login to hijack post-login session |
| **Argon2id** | Current best-practice password hashing algorithm; memory-hard |
| **bcrypt** | Older but still acceptable password hashing; CPU-hard only |
| **HMAC** | Hash-based Message Authentication Code; proves a value was created by someone holding the secret |
| **Salt** | Random value mixed into password hash to prevent precomputed attacks; Argon2id handles this automatically |
| **Rainbow table** | Precomputed table of hash → password mappings; salting defeats them |
| **Replay attack** | Reusing a captured credential (token, TOTP code) after it was legitimately used |

---

## Appendix — Mental Models Worth Keeping

**Tokens are not secrets.** A token is just a lookup key. Its value comes from what the server records it as valid. The token itself can be seen in transit (though HTTPS prevents this in practice) — what matters is that it's unforgeable and that the server has the authority to accept or reject it.

**Never store what you send.** Any token that goes outside your server (email, cookie, URL) should be hashed before storage. You look it up by hashing the incoming value and comparing to stored hashes.

**Destroy evidence, don't just deny access.** When revoking, delete the database record. Don't just set a `revoked` flag — that's a logical record of a dead token. Deleting forces a clean lookup miss. (Exception: audit logs — those you keep forever, append-only.)

**Defense in depth means redundancy.** Rate limiting AND account lockout. Email tokens AND HMAC signing. Session validation AND CSRF tokens. Auth security is not about one perfect mechanism; it's about multiple overlapping defenses where bypassing one doesn't give an attacker the keys.

**The happy path is 5% of the code.** The other 95% is: token expired, email not confirmed, account locked, MFA pending, OAuth provider returned no email, concurrent reset requests, session race conditions, user navigated back after logout. The quality of an auth library is judged by how gracefully it handles these edges.
