---
phase: 166-unfreeze-token-lane-mechanism
reviewed: 2026-06-13T01:39:15Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - test/threadline/operator_surface/router_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
findings:
  critical: 0
  blocker: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 166: Code Review Report

**Reviewed:** 2026-06-13T01:39:15Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** clean

## Summary

Standard code review for the Phase 166 operator-surface theme mechanism is clean after remediation. The review gate initially found two critical issues in files touched by this phase; both were pre-existing in the base tree and were fixed in follow-up commit `76a7f51`.

## Remediation Closed

### CR-01: Export authorize callback exceptions enable export actions

- **Status:** fixed
- **Commit:** `76a7f51`
- **Files:** `lib/threadline/operator_surface/auth.ex`, `test/threadline/operator_surface/live/timeline_live_test.exs`
- **Resolution:** `exports_enabled_for_socket?/3` now fails closed (`false`) when `export_authorize_fn` raises, preserving LiveView access while hiding export affordances and ignoring forged queue events.
- **Verification:** `mix test test/threadline/operator_surface/live/timeline_live_test.exs` - 35 tests, 0 failures.

### CR-02: Actor routes can exhaust the VM atom table

- **Status:** fixed
- **Commit:** `76a7f51`
- **Files:** `lib/threadline/operator_surface/live/actor_live.ex`, `test/threadline/operator_surface/live/actor_live_test.exs`
- **Resolution:** Actor route kind parsing now uses `String.to_existing_atom/1` only and routes unknown kinds to the invalid actor reference branch without creating atoms.
- **Verification:** `mix test test/threadline/operator_surface/live/actor_live_test.exs` - 10 tests, 0 failures; `rg -n 'String\.to_atom\b' lib/threadline/operator_surface/live/actor_live.ex` - no matches.

## Final Review Notes

- `theme:` macro validation is compile-time and literal, with `:dark` as the default and invalid literals raising the required allowed-value message.
- `data-tl-theme` is server-rendered from one normalized assign and appears on all ten operator LiveView roots.
- Light/system CSS is scoped to `.threadline-ui[data-tl-theme=...]`; no JavaScript, localStorage, head script, cookie, or runtime `theme-toggle` mechanism was added.
- The active shell-nav inset is token-backed through `--tl-color-accent-inset`, and the dark raw rgba remains only as the dark token declaration.

## Verification Evidence

- `mix compile --warnings-as-errors` - PASS.
- `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/live/start_live_test.exs` - PASS, 44 tests, 0 failures.
- `mix test test/threadline/operator_surface/live/actor_live_test.exs` - PASS, 10 tests, 0 failures.
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs` - PASS, 35 tests, 0 failures.
- Source greps for `theme-toggle`, bare root `<div class="threadline-ui">`, and `String.to_atom` in ActorLive returned no matches; `data-tl-theme={@threadline_theme}` appears on ten roots.

---

_Reviewed: 2026-06-13T01:39:15Z_
_Reviewer: Codex (standard review after gsd-code-reviewer findings were remediated)_
_Depth: standard_
