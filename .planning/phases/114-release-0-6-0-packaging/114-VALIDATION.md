---
phase: 114
slug: release-0-6-0-packaging
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
---

# Phase 114 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/release_artifact_contract_test.exs` (wave 1) / `mix verify.doc_contract` (wave 2) |
| **Full suite command** | `mix ci.all` |
| **Release pre-flight** | `mix verify.release` (requires clean git tree) |
| **Estimated runtime** | ~15s per wave quick gate; ~60–120s for `verify.release` |

---

## Sampling Rate

- **After every task commit:** Run plan wave quick command from table below
- **After every plan wave:** Run wave command + `mix compile --warnings-as-errors` if `mix.exs` changed
- **Before `/gsd-verify-work`:** `mix ci.all` green; `mix verify.release` on clean tree
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 114-01-01 | 01 | 1 | REL-01 | — | N/A | unit | `mix test test/threadline/release_artifact_contract_test.exs` (partial after version) | ✅ | ⬜ pending |
| 114-01-02 | 01 | 1 | REL-01 | — | N/A | unit | `bin/verify-release-shape` | ✅ | ⬜ pending |
| 114-01-03 | 01 | 1 | REL-02 | — | N/A | unit | `mix test test/threadline/release_artifact_contract_test.exs` | ✅ | ⬜ pending |
| 114-02-01 | 02 | 2 | REL-04 | — | N/A | contract | `mix verify.doc_contract` | ✅ | ⬜ pending |
| 114-03-01 | 03 | 3 | REL-03 | — | N/A | release | `mix verify.release` | ✅ | ⬜ pending |
| closeout | — | — | REL-01–04 | — | N/A | ci | `mix ci.all` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new test framework setup.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `git tag` + `git push` + Hex publish | REL-03 adjunct | Human maintainer gate | Follow CONTRIBUTING post-merge checklist |
| `mix verify.release` on dirty tree | REL-03 | Alias fails by design | Commit or use clean worktree |

---

## Validation Sign-Off

- [x] All tasks have verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s per wave
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
