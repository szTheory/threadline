---
phase: "222"
slug: "seed-006-change-aware-lanes-conditional"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 222 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Python 3 stdlib self-tests (`--self-test`) + a phase-local `verify-phase.sh` gate; existing ExUnit suite via `mix ci.all` |
| **Config file** | none — standalone scripts under `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/` |
| **Quick run command** | `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --self-test && python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py --self-test` |
| **Full suite command** | `bash .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh && mix ci.all` |
| **Estimated runtime** | ~5 seconds quick; `mix ci.all` several minutes |

---

## Sampling Rate

- **After every task commit:** Run the quick run command (tool self-tests) plus `check-citations.py` on the in-progress `222-DECISION.md`
- **After every plan wave:** Run the phase `verify-phase.sh`
- **Before `/gsd-verify-work`:** `verify-phase.sh` and `mix ci.all` must be green
- **Max feedback latency:** 10 seconds (quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 222-01-xx | 01 | 1 | SCOPE-01 (re-measure) | — | N/A | self-test + data | `python3 .../tools/inert-share.py --self-test && python3 .../tools/inert-share.py --window 30d-now` | ❌ W0 | ⬜ pending |
| 222-01-xx | 01 | 1 | SCOPE-01 (minute gate) | — | N/A | self-test + data | `python3 .../tools/remeasure-222.py --self-test` | ❌ W0 | ⬜ pending |
| 222-0x-xx | 01/02 | 1-2 | SCOPE-01 (decision record) | — | N/A | mechanical | `python3 .../tools/check-citations.py .../222-DECISION.md` | ❌ W0 | ⬜ pending |
| 222-0x-xx | 02 | 2 | SCOPE-01 (closure pins, D-09) | — | gate cannot be laundered | existing ExUnit | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/release_control_plane_contract_test.exs` | ✅ | ⬜ pending |
| 222-0x-xx | 02 | 2 | whole repo | — | no hygiene regression | full suite | `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tools/inert-share.py` + `tools/inert-allowlist.txt` — copied from 214, `WINDOWS` extended with `since-214` / `30d-now`
- [ ] `tools/check-citations.py` (phase-number regex admits 222), `tools/summarize-ci.py`, `tools/collect-ci-runs.sh` — copied from 218/219
- [ ] `tools/remeasure-222.py` — new, D-02 minute-gate arithmetic with `--self-test`
- [ ] `raw/prs/` — fresh `gh` snapshot
- [ ] `tools/verify-phase.sh` — one-command phase gate

---

## Manual-Only Verifications

All phase behaviors have automated verification. (D-07's `status: closed` tolerance was confirmed by reading gsd-tools source during research — recorded as a finding, not a phase artifact.)

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
