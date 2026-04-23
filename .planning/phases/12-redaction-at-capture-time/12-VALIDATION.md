---
phase: 12
slug: redaction-at-capture-time
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.x) |
| **Config file** | `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/capture/trigger_redaction_test.exs` |
| **Full suite command** | `MIX_ENV=test mix ci.all` |
| **Estimated runtime** | ~2–5 minutes (PG-dependent) |

---

## Sampling Rate

- **After every task commit:** Run quick command when `trigger_redaction_test.exs` exists; otherwise `MIX_ENV=test mix test test/threadline/capture/trigger_changed_from_test.exs test/threadline/capture/trigger_test.exs`
- **After every plan wave:** Run `MIX_ENV=test mix ci.all`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | REDN-01, REDN-02 | T-12-01-01 / — | No `set_config` / `SET LOCAL` in trigger_sql | grep | `! grep -nE 'set_config|\\bSET LOCAL\\b' lib/threadline/capture/trigger_sql.ex` | ✅ | ⬜ pending |
| 12-01-02 | 01 | 1 | REDN-01, REDN-02 | T-12-01-02 | Overlap fails at codegen | mix | `MIX_ENV=test mix run -e 'Application.ensure_all_started(:threadline); Threadline.Capture.RedactionPolicy.validate!(exclude: [\"x\"], mask: [\"x\"])'` exits non-zero | ✅ | ⬜ pending |
| 12-02-01 | 02 | 2 | REDN-01, REDN-02 | — | Payloads match exclude/mask semantics | integration | `MIX_ENV=test mix test test/threadline/capture/trigger_redaction_test.exs` | ❌ W0 | ⬜ pending |
| 12-02-02 | 02 | 2 | REDN-01, REDN-02 | — | Docs contain semantics | grep | `grep -F 'exclude' README.md guides/domain-reference.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Existing `Threadline.DataCase` + `AuditChange` schema — reuse
- [ ] `test/threadline/capture/trigger_redaction_test.exs` — integration coverage for INSERT/UPDATE/DELETE + mask + exclude
- [ ] `test/threadline/capture/trigger_redaction_policy_test.exs` — pure Elixir tests for config validation (optional same file if preferred)

*Wave 0 completes when new test files exist and first green `mix test` path is recorded in plan 02 SUMMARY.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Code review Path B | Roadmap SC4 | Human judgment | Reviewer confirms no unsafe session coupling in generated trigger path per `12-CONTEXT.md` D-15 |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency under CI budget
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
