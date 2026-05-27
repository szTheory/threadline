---
phase: 105
slug: help-desk-domain-expansion-in-reference-app
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 105 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Scope: `examples/threadline_phoenix/` only — ExUnit + Mix tasks; no `lib/` edits at repo root.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test` in nested example app) |
| **Config file** | `examples/threadline_phoenix/config/test.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_audit_test.exs --max-failures 1` |
| **Full suite command** | `cd examples/threadline_phoenix && mix test` |
| **Coverage command** | `cd examples/threadline_phoenix && mix threadline.verify_coverage` |
| **Repo-root gate** | `mix verify.example` (from repository root) |
| **Estimated runtime** | Quick ~5–15s; full example suite ~30–90s; verify.example ~60–120s |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command from the plan
- **After Plan 01 wave:** `cd examples/threadline_phoenix && mix ecto.migrate --quiet && mix compile --warnings-as-errors`
- **After Plan 02 wave:** `mix threadline.verify_coverage` + quick help_desk test file
- **After Plan 03 wave:** `mix test` + `mix verify.example` from repo root
- **Before `/gsd-verify-work`:** Full suite + coverage + verify.example green
- **Max feedback latency:** 120 seconds (full example test run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 105-01-01 | 01 | 1 | DEMO-01 | T-105-01 | Five help-desk tables migratable | compile/migrate | `cd examples/threadline_phoenix && mix ecto.migrate --quiet && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 105-02-01 | 02 | 2 | DEMO-02, DEMO-04 | T-105-02 | Mask config present before trigger gen | grep | `grep -Fq 'internal_note_body' examples/threadline_phoenix/config/test.exs` | ⬜ W0 | ⬜ pending |
| 105-02-02 | 02 | 2 | DEMO-03 | T-105-03 | All expected tables have triggers | mix | `cd examples/threadline_phoenix && mix threadline.verify_coverage` | ⬜ W0 | ⬜ pending |
| 105-03-01 | 03 | 3 | DEMO-02, DEMO-03 | T-105-04 | Multi-table capture + org meta + action | ExUnit | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_audit_test.exs --max-failures 1` | ⬜ W0 | ⬜ pending |
| 105-03-02 | 03 | 3 | DEMO-04 | T-105-05 | internal_note_body redacted in capture | ExUnit | (same file — mask assertion) | ⬜ W0 | ⬜ pending |
| 105-03-03 | 03 | 3 | Regression | — | Pre-existing example tests pass | integration | `mix verify.example` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline_phoenix/help_desk_audit_test.exs` — created in Plan 03 (may be empty stub until Plan 03 if Plan 02 runs first; Plan 02 must not require it)
- [ ] `test/support/help_desk_fixtures.ex` — org → agent → ticket factory chain

*Existing infrastructure: DataCase, Repo, Threadline install migrations, posts triggers.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|---------------------|
| `/audit/coverage` lists help-desk tables | UI-SPEC | No LiveView test in 105 | After migrate + triggers, open `/audit/coverage` in dev and confirm five tables appear (optional smoke; not phase-blocking) |
| Policy redaction viewer | DEMO-04 | Operator UI not automated in 105 | Confirm `/audit/policy/redaction` lists `ticket_replies` / `internal_note_body` mask config |

*Phase exit is gated on ExUnit + verify_coverage + verify.example, not manual UI.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for quick path
- [ ] `nyquist_compliant: true` set in frontmatter after execution

**Approval:** pending
