---
phase: 109
slug: maintainer-walkthrough-dry-run
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 109 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual UAT + git path audit (no new ExUnit for walk itself) |
| **Config file** | `.planning/phases/109-maintainer-walkthrough-dry-run/109-VERIFICATION.md` |
| **Quick run command** | `git log "$PHASE_109_START_SHA".."$IMPORT_SHA" --name-only --pretty=format: -- lib/ guides/ examples/ test/ \| sort -u` (expect empty) |
| **Full suite command** | Complete 109-VERIFICATION.md checklist + finding frontmatter audit |
| **Estimated runtime** | ~2–4 hours human walk + 5 min import verification |

---

## Sampling Rate

- **After every walk plan (109-02..04):** Update `109-WALK-CHECKPOINT.json` + section checkpoint table in execution log
- **After plan 109-05:** Run full scope-guard git audit before marking phase planned→executed complete
- **Before `/gsd-verify-work`:** All `0*.md` findings have non-empty `classification` and `walkthrough_step`
- **Max feedback latency:** Section boundary (do not defer findings to next plan)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 109-01-01 | 01 | 1 | FINDINGS-02 | T-109-01 | Execution log records baseline SHA | manual | `grep WALK_BASELINE_SHA 109-EXECUTION-LOG.md` | ✅ | ⬜ pending |
| 109-02-01 | 02 | 2 | RUN-01 | T-109-02 | §1 gate documented | manual | §1 checkpoint in execution log | ✅ | ⬜ pending |
| 109-03-01 | 03 | 3 | RUN-02 | T-109-03 | Four WALK-03 steps attempted or NOT ATTEMPTED with reason | manual | §4 checkpoint table | ✅ | ⬜ pending |
| 109-04-01 | 04 | 4 | RUN-03 | T-109-04 | Three WALK-04 exercises attempted | manual | §5 checkpoint table | ✅ | ⬜ pending |
| 109-05-01 | 05 | 5 | FINDINGS-02 | T-109-05 | Scope guard: no code paths in phase window | unit | `git log` path filter (see 109-VERIFICATION.md) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `109-RESEARCH.md` — validation architecture documented
- [x] `109-CONTEXT.md` — locked execution decisions
- [x] `.planning/v1.23/findings/TEMPLATE.md` — finding format (Phase 108)

*No new ExUnit Wave 0 — walk validates runtime semantics CI cannot see.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Clean-clone WALKTHROUGH walk | RUN-01 | Human follows prose; contract tests don't prove procedure | Execute 109-02 on isolated clone |
| Four `/audit` incidents | RUN-02 | Browser operator surface | Execute 109-03; file finding per WALK-03-0N |
| Evidence CLI + LiveView | RUN-03 | Human reads verdict fields | Execute 109-04 |
| Observe-only discipline | Success criterion 5 | Intent not machine-checkable during walk | Post-walk `git log` path filter in 109-05 |

---

## Validation Sign-Off

- [x] All tasks have manual verify or git audit in 109-VERIFICATION.md
- [x] Sampling continuity: findings at each "If different" trigger
- [x] Wave 0 covers infrastructure (template + research)
- [x] No watch-mode flags
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
