---
phase: "223"
slug: "close-v1-43-audit-debt"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-29"
---

# Phase 223 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`) plus the bash self-test `bin/verify-repo-hygiene --self-test` |
| **Config file** | `mix.exs` aliases (`verify.test`, `verify.repo_hygiene`, `ci.all`) |
| **Quick run command** | `mix test test/threadline/release_control_plane_contract_test.exs test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs && bin/verify-repo-hygiene --self-test && bin/verify-repo-hygiene` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~30 seconds quick; several minutes full |

---

## Sampling Rate

- **After every task commit:** Run the touched test file(s), `bin/verify-repo-hygiene --self-test`, and a live `bin/verify-repo-hygiene` (must stay exit 0)
- **After every plan wave:** Run `mix ci.all`
- **Before `/gsd-verify-work`:** `mix ci.all` green, `bin/verify-repo-hygiene` green, and `grep -c '| open |' .planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` prints `0`
- **Max feedback latency:** 60 seconds (quick)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 223-B | TBD | 1 | 216 CR-01 | T-223 | Every release.yml checkout sets `persist-credentials: false` unless allowlisted; allowlisted jobs run no mix | unit (text-parse + mutation controls) | `mix test test/threadline/release_control_plane_contract_test.exs` | ✅ extend | ⬜ pending |
| 223-C | TBD | 1 | 217 R2-* | T-223 | Guard rejects broad literals, newline paths; family 6 anchored; Linux Claude family detected | self-test + unit | `bin/verify-repo-hygiene --self-test && mix test test/threadline/repo_hygiene_guard_test.exs test/threadline/repo_hygiene_contract_test.exs` | ✅ extend | ⬜ pending |
| 223-D | TBD | 2 | 217 disposition | — | No `open` rows | grep | `grep -c '| open |' .planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` | ✅ | ⬜ pending |
| 223-A | TBD | 3 | SUP-01 | — | 0.11.2 published via production-hex approval | manual (maintainer grants) | `gh release view v0.11.2` | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push, PR edit (#60 override), merges, `production-hex` approval | SC-1 | Needs the maintainer's explicit named grants; publish is one-way | Follow D-04 sequence and CONTRIBUTING "Maintainer manual checklist (release)" |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
