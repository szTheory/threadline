---
phase: 106-sigra-auth-lane-in-reference-app
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - examples/threadline_phoenix/README.md
  - examples/threadline_phoenix/config/dev.exs
  - examples/threadline_phoenix/config/test.exs
  - examples/threadline_phoenix/lib/threadline_phoenix/accounts.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/components/core_components.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/help_desk_dev_controller.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_controller.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/registration_controller.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/session_controller.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/operator_user.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/plugs/assign_operator_user.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  - examples/threadline_phoenix/lib/threadline_phoenix_web/user_auth.ex
  - examples/threadline_phoenix/mix.exs
  - examples/threadline_phoenix/test/support/conn_case.ex
  - examples/threadline_phoenix/test/support/fixtures/auth_fixtures.ex
  - examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_http_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/help_desk_provision_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues
---

# Phase 106: Code Review Report

**Reviewed:** 2026-05-27  
**Depth:** standard  
**Files Reviewed:** 20 (from plans 01–03 `key-files`)  
**Status:** issues (2 warnings, 3 informational)

## Summary

Phase 106 delivers the intended Sigra auth lane: registration with help-desk provisioning, `OperatorUser` scope bridge on `/audit`, `login_via_sigra/2`, and HTTP audit capture proof. Router authorization callbacks are unchanged; impersonation uses impersonator admin policy per D-106-02f. Scoped tests pass (8 tests, 0 failures).

Two warnings are worth fixing before Phase 107 seeds rely on the dev capture route or production-like hardening: cross-org ticket access in `HelpDeskDevController`, and silent provisioning failures on login.

## Findings

### WR-001: HelpDeskDevController does not bind ticket to organization

**Severity:** warning  
**File:** `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/help_desk_dev_controller.ex`

The `ticket_reply/2` `with` chain loads `org` and `ticket` independently and only checks that the caller has an `Agent` row for `org.id`. It never asserts `ticket.organization_id == org.id`. An agent in org A who knows another org’s ticket UUID can pass `organization_id` for A and mutate a ticket in org B.

**Mitigation today:** Route is compiled only when `dev_routes: true` (dev/test config); `prod.exs` does not enable it.

**Recommendation:** Add `ticket.organization_id == org.id` to the `with` chain (or scope `Repo.get` on both keys). Keeps AUTH-04 proof honest and safe if `dev_routes` is ever mis-set.

### WR-002: Login ignores help-desk provision failures

**Severity:** warning  
**File:** `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/session_controller.ex`

```elixir
_ = HelpDesk.provision_default_workspace_for_user(to_string(user.id))
```

Discards `{:error, reason}`. Users can authenticate without membership; `/audit` then yields `current_user` with `organization_id: nil` and `role: nil` → 403. Registration path surfaces provision errors; login does not, so support/debugging diverges and legacy users without membership get a confusing dead end until manual DB fix.

**Recommendation:** Mirror registration: on `{:error, reason}`, flash a generic message and halt login, or log and redirect with a recoverable message.

### IN-001: Registration error flash may leak internal details

**Severity:** info  
**File:** `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/registration_controller.ex`

`"Workspace setup failed: #{inspect(reason)}"` can expose constraint names or DB errors to the browser. HEEx flash escaping prevents XSS; disclosure is still undesirable in a shared demo.

**Recommendation:** Log `reason` server-side; show a stable user-facing string.

### IN-002: Register and provision are not one transaction

**Severity:** info  
**Files:** `registration_controller.ex`, `help_desk.ex`

Sigra user insert succeeds before `provision_default_workspace_for_user/2`. On provision failure the account exists but is not logged in. Login safety-net (WR-002) usually repairs this; not a hard lockout.

**Recommendation:** Accept for reference app, or wrap provision in compensating logic on failure.

### IN-003: Deterministic CLOAK_KEY in dev/test config

**Severity:** info  
**Files:** `config/dev.exs`, `config/test.exs`

Fixed `CLOAK_KEY` via `System.put_env` is appropriate for local example app ergonomics. Document that production must use runtime secrets (already implied by comments).

## Positive observations

- **Impersonation (D-106-02f):** `OperatorUser` derives desk `role` and `is_admin` from `impersonating_from` when present; aligns with fail-closed surface policy.
- **Idempotent provisioning:** `HelpDesk.provision_default_workspace_for_user/2` and tests cover create + idempotency.
- **Pipeline order:** `/audit` uses `[:browser, :operator_browser, :operator_auth]`; `my_authorize_fn/1` and `scope_operator_query/3` bodies unchanged.
- **AUTH-04 proof:** `help_desk_audit_http_test.exs` uses `Sandbox.unboxed_run/2` to avoid sandbox txid/`actor_ref` reuse; asserts captured `actor_ref`.
- **Test hygiene:** No `assign(:current_user` in example test tree; `login_via_sigra/2` defaults to HTTP login.
- **Dormant Sigra settings:** Stub routes return 404 without exposing MFA/settings UI in the walkthrough.

## Verification

```bash
cd examples/threadline_phoenix && mix test \
  test/threadline_phoenix/help_desk_provision_test.exs \
  test/threadline_phoenix/help_desk_audit_http_test.exs \
  test/threadline_phoenix_web/operator_surface_test.exs
```

Result: **8 tests, 0 failures**

## Recommendation

Address **WR-001** and **WR-002** before Phase 107 (`demo.seed` / `demo.reset`) if seeds or docs exercise `/dev/help_desk/ticket_reply`. Informational items can ride with 107 or a small 106.x fix plan.

---

_Reviewed: 2026-05-27_  
_Reviewer: Cursor (gsd-code-reviewer)_  
_Depth: standard_
