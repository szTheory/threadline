---
phase: 137
slug: prove-cluster-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 137 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveViewTest |
| **Config file** | `mix.exs`; test support in `test/support` |
| **Quick run command** | `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/style_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | quick target ~20-45 seconds; full suite project-dependent |

---

## Sampling Rate

- **After every task commit:** Run the quick target for the touched LiveView/test files.
- **After every plan wave:** Run `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs test/threadline/operator_surface/style_contract_test.exs`.
- **Before `$gsd-verify-work`:** `mix test` must be green or the summary must record explicit pre-existing failures.
- **Max feedback latency:** 60 seconds for targeted LiveView/style checks where feasible.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 137-01-01 | shared-primitives | 1 | POLISH-PROVE | T-137-01 / — | Presentation helpers do not expose hidden data or add unsafe action states | unit/source | `mix test test/threadline/operator_surface/style_contract_test.exs` | ✅ | ⬜ pending |
| 137-02-01 | exports | 2 | POLISH-PROVE | T-137-02 / — | Only downloadable completed exports receive primary download affordance | LiveView | `mix test test/threadline/operator_surface/live/export_status_live_test.exs` | ✅ | ⬜ pending |
| 137-03-01 | retention | 2 | POLISH-PROVE | T-137-03 / — | Destructive prune remains guarded by authorization, confirmation, and context-before-action UI | LiveView | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` | ✅ | ⬜ pending |
| 137-04-01 | evidence-redaction | 2 | POLISH-PROVE | T-137-04 / — | Evidence display changes do not widen proof semantics or redaction policy behavior | LiveView | `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/live/policy_redaction_live_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework installation is expected.

The planner should still include test-first or same-wave test updates for:

- `test/threadline/operator_surface/live/evidence_live_test.exs`
- `test/threadline/operator_surface/live/export_status_live_test.exs`
- `test/threadline/operator_surface/live/retention_history_live_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `test/threadline/operator_surface/style_contract_test.exs`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 375px dense card readability | POLISH-PROVE | Automated LiveView tests prove source behavior; visual wrapping may still need browser inspection | Capture or inspect Evidence, Exports, Retention, and Redaction at 375px after implementation; actor/subject refs must not become the visual lead |
| Retention context-before-action on mobile | POLISH-PROVE | Source order can be tested, but final mobile perception benefits from viewport inspection | Confirm summary/latest-completed/failure context visually precedes `Run retention prune` at 375px |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for targeted checks
- [ ] `nyquist_compliant: true` set in frontmatter when planner/executor confirms coverage

**Approval:** pending
