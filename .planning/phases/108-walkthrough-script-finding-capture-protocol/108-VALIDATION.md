---
phase: 108
slug: walkthrough-script-finding-capture-protocol
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 108 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (example app + root doc contracts) |
| **Config file** | `examples/threadline_phoenix/test/test_helper.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs --max-failures 1` |
| **Full suite command** | `cd /Users/jon/projects/threadline && mix verify.test` |
| **Estimated runtime** | ~30–90 seconds (demo contract + optional walkthrough contract) |

---

## Sampling Rate

- **After every task commit:** Run quick run command when task modifies seed or tests
- **After every plan wave:** Run quick run command + grep checks from plan verify blocks
- **Before `/gsd-verify-work`:** `mix verify.test` from repo root
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 108-01-01 | 01 | 1 | WALK-04 | T-108-01 | Demo evidence rows use walk-* refs only | unit | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ | ⬜ pending |
| 108-02-01 | 02 | 1 | FINDINGS-01 | — | N/A | grep | `test -f .planning/v1.23/findings/TEMPLATE.md && test -f .planning/v1.23/findings/README.md` | ❌ W0 | ⬜ pending |
| 108-03-01 | 03 | 2 | WALK-01, WALK-02 | — | N/A | grep | `grep -q 'WALK-01' examples/threadline_phoenix/WALKTHROUGH.md` | ❌ W0 | ⬜ pending |
| 108-04-01 | 04 | 3 | WALK-03 | — | N/A | grep | `grep -q 'WALK-03-04' examples/threadline_phoenix/WALKTHROUGH.md` | ❌ W0 | ⬜ pending |
| 108-05-01 | 05 | 4 | WALK-04 | T-108-02 | Walkthrough does not quote plaintext internal secret | grep+unit | `grep -q 'walk-demo-redaction-policy' examples/threadline_phoenix/DEMO-MANIFEST.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs`
- `mix demo.seed` / `mix demo.reset` tasks (Phase 107)

No Wave 0 stubs required.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cold-clone maintainer walk | RUN-01..03 | Phase 109 scope | Execute WALKTHROUGH on clean clone; file findings only |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
