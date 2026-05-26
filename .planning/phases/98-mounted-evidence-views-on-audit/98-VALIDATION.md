---
phase: 98
slug: mounted-evidence-views-on-audit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-26
---

# Phase 98 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveView tests |
| **Config file** | `mix.exs`, `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` |
| **Full suite command** | `mix verify.test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
- **After every plan wave:** Run `mix verify.test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 98-01-01 | 01 | 1 | SURF-01 | T-98-01 / T-98-02 | `/audit/evidence` renders only read-only overview/history state and preserves URL-driven navigation | liveview | `MIX_ENV=test mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 98-02-01 | 02 | 2 | SURF-02 | T-98-03 | mounted labels and fallback copy preserve `proven`, `inferred_posture`, and `unsupported` semantics without query drift | liveview | `MIX_ENV=test mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ❌ W0 | ⬜ pending |
| 98-02-02 | 02 | 2 | SURF-03 | T-98-04 | host-owned evidence callback fails closed to explicit unsupported state when denied | unit + liveview | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/live/evidence_live_test.exs` — mounted proof for overview, drill-down, and unsupported-state flows
- [ ] `test/threadline/operator_surface/auth_test.exs` — extend capability-boolean coverage for evidence gating

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual scan of evidence landing-page hierarchy against `98-UI-SPEC.md` | SURF-01, SURF-02 | Copy order and scanability are easier to confirm from rendered HTML/live page than from unit assertions alone | Mount `/audit/evidence`, verify title `What can Threadline prove right now?`, verify verdict labels, `View history`, and unsupported fallback copy render in the intended order |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
