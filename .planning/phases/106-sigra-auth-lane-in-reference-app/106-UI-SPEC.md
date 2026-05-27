---
phase: 106
slug: sigra-auth-lane-in-reference-app
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-27
reviewed_at: 2026-05-27
---

# Phase 106 — UI Design Contract

> Minimal controller-first auth chrome for `examples/threadline_phoenix/`. Operator `/audit` surfaces inherit Phase 98/105 styling unchanged. This contract covers register, login, logout, and a sparse home page only.

---

## Phase UI Boundary

| In scope (Phase 106) | Out of scope (deferred) |
|----------------------|-------------------------|
| Sigra install (`mix sigra.install` controller mode, no orgs/LiveView/passkeys/admin) | Full Sigra LiveView auth suite, passkeys, admin users |
| Register, login, logout routes + HEEx templates | Ticket inbox, agent console (`Phase 109`) |
| Minimal `PageController` home (links to register/login or `/audit`) | Org switcher, invite/join UX |
| Bootstrap Phoenix HTML stack (`Layouts`, `core_components` `<.input>`, Gettext, Swoosh dev mailbox) | Parallel CSS/Tailwind for `/audit` |
| Session persists across reload (Sigra `UserAuth`) | `phx.gen.auth` parallel lane |

**Rule:** Do not fork generated `UserAuth` unless sub-phase **106b** documents a Sigra contract gap.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | Phoenix 1.8 default (`core_components.ex`, `Layouts`) |
| Preset | none — functional auth forms only |
| Component library | `<.input>`, `<.button>`, `<.flash>` from generated `core_components` |
| Icon library | `<.icon name="hero-*">` only when install adds icons |
| Font | `system-ui, -apple-system, sans-serif` (Phoenix default) |

**Operator surface:** Inherit `105-UI-SPEC.md` / Phase 98 tokens for `/audit` — no new operator styling in 106.

---

## Routes & Screens

| Route | Screen | Purpose |
|-------|--------|---------|
| `GET /` | Home | Unauthenticated: links to register, login. Authenticated: link to `/audit` |
| `GET/POST /users/register` | Register | Create Sigra user; triggers help-desk workspace provision |
| `GET/POST /users/log_in` | Login | Establish DB session |
| `DELETE /users/log_out` | Logout | Clear session |

Dormant generated routes (reset, MFA, passkey) may exist post-install but are **undocumented** in walkthrough until needed.

---

## Layout & Forms

- All auth templates wrap in `<Layouts.app flash={@flash} current_scope={@current_scope}>` per Phoenix 1.8 guidelines.
- Use `<.simple_form>` / `<.input>` for email, password fields — no custom raw `<input>` unless install requires it.
- Flash errors on failed login/register; success flash on logout optional.
- No marketing chrome, hero sections, or multi-column layouts.

---

## Email (dev)

- Swoosh dev mailbox at `/dev/mailbox` for registration confirmation (WALK-01 in Phase 108).
- Test env: `Swoosh.Adapters.Test` — no real SMTP.

---

## Accessibility

- Forms: associated labels via `<.input field={@form[:email]} />`.
- Focus order: email → password → submit.
- Error messages in flash or inline field errors from changeset.

---

## Visual Non-Goals

- No brand illustration, gradients, or dark mode toggle.
- No org name field on signup (auto-provision help-desk org).
- No styling parity with operator surface — auth pages are utilitarian scaffolding.

---

*Derived from `106-CONTEXT.md` D-106-03. Operator surface visual contract remains `105-UI-SPEC.md`.*
