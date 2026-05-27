---
phase: 106
slug: sigra-auth-lane-in-reference-app
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-27
---

# Phase 106 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`examples/threadline_phoenix`) |
| **Config file** | `examples/threadline_phoenix/config/test.exs` (+ Sigra argon2 inject) |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs --max-failures 1` |
| **Full suite command** | `cd examples/threadline_phoenix && mix test` |
| **Repo gate** | `mix verify.example` (repo root) |
| **Estimated runtime** | ~15–30 seconds (example app suite) |

---

## Sampling Rate

- **After every task commit:** Run task `<automated>` verify
- **After every plan wave:** Run `cd examples/threadline_phoenix && mix test`
- **Before phase close:** Full suite + `mix verify.example` green (includes `sigra_auth_flow_test.exs` UAT proxy; `/gsd-verify-work` not required)
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 106-01-01 | 01 | 1 | AUTH-01 | T-106-01 | Sigra migrations applied; `users` table present | migrate | `cd examples/threadline_phoenix && mix ecto.migrate --quiet && mix run -e "ThreadlinePhoenix.Repo.query!(\"SELECT 1 FROM users LIMIT 0\")"` | ⬜ W0 | ⬜ pending |
| 106-01-02 | 01 | 1 | AUTH-02 | T-106-02 | Register/login routes compile; CSRF on forms | compile | `cd examples/threadline_phoenix && mix compile --warnings-as-errors` | ⬜ W0 | ⬜ pending |
| 106-01-03 | 01 | 1 | AUTH-02 | T-106-03 | Provision on register creates org membership | unit | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_provision_test.exs` | ⬜ W0 | ⬜ pending |
| 106-02-01 | 02 | 2 | AUTH-03 | T-106-04 | `current_user` has org UUID + role after login | conn | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs` | ⬜ W0 | ⬜ pending |
| 106-03-01 | 03 | 3 | AUTH-04 | T-106-05 | No faked `assign(:current_user` in tests | grep | `! rg 'assign\(:current_user' examples/threadline_phoenix/test/` | ✅ | ⬜ pending |
| 106-03-02 | 03 | 3 | AUTH-04 | T-106-06 | HTTP capture proves actor_ref from session | conn | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_audit_http_test.exs` | ⬜ W0 | ⬜ pending |
| 106-03-03 | 03 | 3 | AUTH-04 | — | Full regression | suite | `cd examples/threadline_phoenix && mix test && cd ../.. && mix verify.example` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `mix sigra.install Accounts User users --no-live --no-organizations --no-passkeys --no-admin --yes`
- [ ] Phoenix HTML stack (`Layouts`, `core_components`, `:html` in `threadline_phoenix_web.ex`)
- [ ] `RegistrationController` (Sigra 0.2.5 gap)
- [ ] `HelpDesk.provision_default_workspace_for_user/2`
- [ ] `OperatorUser` + `AssignOperatorUser` plug
- [ ] `login_via_sigra/2` in `conn_case.ex`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Session persists across browser reload | ROADMAP SC #1 | Browser UX | `mix phx.server` → register → reload → still logged in |
| Dev mailbox confirmation | AUTH-02 / WALK-01 | Email UI | Visit `/dev/mailbox` after register |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
