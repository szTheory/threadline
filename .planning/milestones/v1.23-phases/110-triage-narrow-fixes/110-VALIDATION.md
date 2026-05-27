---
phase: 110
slug: triage-narrow-fixes
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-27
---

# Phase 110 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.x (Elixir) |
| **Config file** | `mix.exs` aliases `verify.*`, `ci.all` |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/walkthrough_doc_contract_test.exs` |
| **Full suite command** | `mix ci.all` (repo root) |
| **Estimated runtime** | ~60–180 seconds |

---

## Sampling Rate

- **After every task commit:** Run task `<automated>` verify or quick run above
- **After every plan wave:** Run `mix ci.all`
- **Before phase closeout:** L2 validation re-walk logged in `110-RE-WALK-LOG.md`
- **Max feedback latency:** 180 seconds (full `ci.all`)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 110-01-01 | 01 | 1 | FIX-01 | T-110-01 | Landing returns 200 logged-out | integration | `curl -sS -o /dev/null -w '%{http_code}' http://localhost:4000/` | ✅ | ⬜ pending |
| 110-01-02 | 01 | 1 | FIX-01 | — | Finding 0001 marked fixed | grep | `grep 'status: fixed' .planning/v1.23/findings/0001-landing-500-badmap.md` | ✅ | ⬜ pending |
| 110-01-03 | 01 | 1 | FIX-01 | — | CI green | alias | `mix ci.all` | ✅ | ⬜ pending |
| 110-02-01 | 02 | 2 | FIX-03 | — | Findings 0002/0003 exist | grep | `test -f .planning/v1.23/findings/0002-wr-002-cli-syntax.md` | ❌ W0 | ⬜ pending |
| 110-02-02 | 02 | 2 | FIX-03 | T-110-02 | WR window + CLI prose + contracts | unit | quick run command above | ✅ | ⬜ pending |
| 110-02-03 | 02 | 2 | FIX-02 | — | IN-001 §0 voice | grep | `grep -q '§1 Prerequisites' examples/threadline_phoenix/WALKTHROUGH.md` | ✅ | ⬜ pending |
| 110-03-01 | 03 | 3 | FIX-01..03 | T-110-03 | Re-walk log exists | file | `test -f .planning/phases/110-triage-narrow-fixes/110-RE-WALK-LOG.md` | ❌ W0 | ⬜ pending |
| 110-03-02 | 03 | 3 | DEFER-01 | — | SUMMARY deferred seeds table | grep | `grep -q 'Deferred v1.24' .planning/phases/110-triage-narrow-fixes/110-SUMMARY.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- [x] `demo_contract_test.exs` — extend for agent2 window
- [x] `walkthrough_doc_contract_test.exs` — extend for WR-002 CLI literals
- [x] `mix ci.all` — L1 gate

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| L2 validation re-walk WALK-01-04→§5 | FIX-03 / RUN acceptance | Maintainer procedure + browser `/audit` | Fresh clone at `RE_WALK_BASELINE_SHA`; log in `110-RE-WALK-LOG.md` |
| WALK-03-02 UI filter spot-check | FIX-03 | Optional 5-min human confirm post-0001 | Admin login; actor history non-empty in aligned window |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
