# Phase 106: Sigra Auth Lane in Reference App - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 106-Sigra Auth Lane in Reference App
**Areas discussed:** Org bootstrap on signup, Sigra scope → current_user bridge, Auth UI surface, Test authentication strategy

---

## Org bootstrap on signup

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-create workspace on signup | `Ecto.Multi` org + membership + agent after registration | ✓ |
| Signup form with company name | User-chosen org name/slug at register | |
| Seed-only bootstrap | Orgs only from `demo.seed`, signup creates user only | |
| Invite/join only | No self-serve tenant creation | |
| Mirror Sigra organizations table | Dual org model in auth + help-desk | |
| Post-signup onboarding wizard | Separate “create workspace” step | |
| Hybrid auto-create + demo.seed | Shared `provision_default_workspace` for both paths | ✓ (paired) |

**User's choice:** Auto-provision on signup + shared helper for Phase 107 seeds (advisor research + user request for one-shot coherent recommendations).

**Notes:** Default role `agent`; `is_admin` global not on membership; idempotent provision; UUID in audit meta not slug.

---

## Sigra scope → current_user bridge

| Option | Description | Selected |
|--------|-------------|----------|
| Plug after fetch_current_scope | `AssignOperatorUser` before operator_auth | ✓ |
| Login callback only | Set current_user at log_in_user | |
| LiveView on_mount only | LV-specific assign | |
| Session-cache current_user | put_session at login | |
| Extend router to read current_scope | Change authorize_fn contract | |
| Config demo-admin plug | Fake admin in dev router | |

**User's choice:** `ThreadlinePhoenixWeb.OperatorUser` plug + `build_operator_user/2`; one membership query per request; impersonation fail-closed on desk roles; no router semantic changes.

**Notes:** API pipeline unchanged; lib Sigra adapter read-only for surface auth.

---

## Auth UI surface

| Option | Description | Selected |
|--------|-------------|----------|
| sigra.install --no-live --no-organizations --no-passkeys --no-admin | Controller HEEx auth slice | ✓ |
| Full Sigra install (live, orgs, passkeys, admin) | Maximum generator surface | |
| Hand-rolled session controller | Custom auth without generator | |
| phx.gen.auth | Phoenix built-in auth | |
| LiveView auth pages | RegistrationLive / SessionLive | |

**User's choice:** Narrow Sigra install + minimal HTML/gettext/mailbox bootstrap + stub home page; dormant advanced routes OK.

**Notes:** App scaffold was --no-html; WALK-01 needs register/login/logout + dev mailbox confirm.

---

## Test authentication strategy

| Option | Description | Selected |
|--------|-------------|----------|
| login_via_sigra/2 for browser tests | Real POST login or session API | ✓ |
| Keep sigra_conn for API tests | Post-plug boundary for Integrations.Sigra | ✓ |
| Keep DataCase help_desk_audit_test | Fast capture regression | ✓ |
| Add help_desk_audit_http_test | ConnCase real session proof | ✓ |
| Migrate operator_surface_test off assign | Replace faked current_user | ✓ |
| Remove sigra_conn entirely | All tests through HTML login | |
| Replace DataCase with ConnCase only | Single integration layer | |
| Capybara E2E | Full browser automation | |

**User's choice:** Layered pyramid — DataCase (many) + sigra_conn API (some) + login_via_sigra HTTP (few); ~3–5 new HTTP tests; no Capybara.

**Notes:** AUTH-04 explicitly calls out assign(:current_user) for new help-desk tests; lib operator_surface tests unchanged.

---

## Claude's Discretion

- Auto-org naming strategy
- Dev seed role promotion (`support` vs `agent` for walkthrough)
- Sigra registration hook placement
- login_via_sigra :http vs :session default
- Minimal HTTP route for help-desk AUTH-04 proof

## Deferred Ideas

Listed in CONTEXT.md `<deferred>` — invites, org switcher, Sigra org tables, full LV auth, phx.gen.auth, ticket UI, 106b lib changes unless contract gap.
