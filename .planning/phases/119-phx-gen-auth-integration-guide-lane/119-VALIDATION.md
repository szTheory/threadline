---
phase: 119
slug: phx-gen-auth-integration-guide-lane
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 119 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (deferred to Phase 120); Phase 119 uses grep + format |
| **Config file** | N/A |
| **Quick run command** | `mix format --check-formatted guides/integrations/phx-gen-auth.md guides/upgrade-path.md` |
| **Full suite command** | `mix verify.format` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run format check on modified guide paths
- **After every plan wave:** Run plan `acceptance_criteria` grep commands
- **Before `/gsd-verify-work`:** All grep locks green; format clean
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 119-01-01 | 01 | 1 | AUTH-GUIDE-01 | T-119-01 | Host-owned actor from scope; plug order documented | grep | `grep -F 'PHX-GEN-AUTH-03' guides/integrations/phx-gen-auth.md` | ✅ | ⬜ pending |
| 119-01-02 | 01 | 1 | AUTH-GUIDE-02 | T-119-02 | Admin-only authorize_fn; export footgun | grep | `grep -F 'authorize_fn' guides/integrations/phx-gen-auth.md` | ✅ | ⬜ pending |
| 119-01-03 | 01 | 1 | AUTH-GUIDE-03 | T-119-03 | Non-goals: no phx.gen.auth runner, no user tables | grep | `grep -F 'mix phx.gen.auth' guides/integrations/phx-gen-auth.md` | ✅ | ⬜ pending |
| 119-02-01 | 02 | 2 | AUTH-LANE-01 | T-119-04 | Lane named; reference claim; no matrix row | grep | `grep -F 'phx-gen-auth-reference' guides/upgrade-path.md` | ✅ | ⬜ pending |
| 119-02-02 | 02 | 2 | AUTH-LANE-02 | T-119-05 | Not Sigra-compatible; sigra row untouched | grep | `grep -c 'sigra-reference' guides/upgrade-path.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test files in Phase 119.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guide readability / line count ~70–90 | AUTH-GUIDE-01 | Subjective prose quality | `wc -l guides/integrations/phx-gen-auth.md` — expect 70–95 lines |
| Sigra guide not required to follow phx lane | AUTH-LANE-02 | Cross-doc judgment | Confirm phx guide does not require `Threadline.Integrations.Sigra` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
