---
phase: "205"
slug: "release-reconciliation"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-24"
---

# Phase 205 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `205-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3) plus shell/git gates |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `DB_PORT=5433 mix test test/mix/tasks/threadline/install_test.exs test/threadline/changelog_contract_test.exs test/threadline/storage_schema_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/release_control_plane_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_all_dedup_contract_test.exs test/threadline/public_surface_contract_test.exs` |
| **Full suite command** | `DB_PORT=5433 mix test` (research candidate: 1786 tests, 0 failures, 1 excluded) |
| **Estimated runtime** | ~30 s quick, ~140 s full |

---

## Sampling Rate

- **After the merge commit:** compile `--warnings-as-errors`, format check, quick run. Credo is expected red until the follow-up fix commit.
- **After the fix commit:** the quick run plus credo, then the full suite.
- **After all commits:** dialyzer, xref cycles, `release.pins --check`, `verify.example`, bump rehearsal (it clones the committed HEAD), and `verify.release` in a clean clone.
- **Before `/gsd-verify-work`:** full suite must be green.
- **Max feedback latency:** 140 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 205-01-* | 01 | 1 | RELEASE-02 | — | N/A | git | `git merge-base --is-ancestor v0.10.1 HEAD && test "$(git rev-list --count HEAD..origin/main)" = 0` | n/a | ⬜ pending |
| 205-01-* | 01 | 1 | RELEASE-02 | T-205 release token | #46's release.yml token scoping preserved | structural | `grep -n 'sync-release-pr-pins:' .github/workflows/release.yml` | ✅ | ⬜ pending |
| 205-01-* | 01 | 1 | RELEASE-02 | — | N/A | contract + task | `MIX_ENV=dev mix release.pins --check` | ✅ | ⬜ pending |
| 205-01-* | 01 | 1 | RELEASE-02 | — | N/A | rehearsal | `DB_PORT=5433 mix verify.bump_rehearsal` (expects 0.10.1 -> 0.11.0) | ✅ | ⬜ pending |
| 205-01-* | 01 | 1 | RELEASE-05 | — | N/A | contract | `DB_PORT=5433 mix test test/threadline/changelog_contract_test.exs test/threadline/release_distribution_doc_contract_test.exs` | ✅ | ⬜ pending |
| 205-01-* | 01 | 1 | RELEASE-05 | — | N/A | release | `mix verify.release` in a `git clone --no-local` copy | ✅ | ⬜ pending |
| 205-01-* | 01 | 1 | (202 CR-01) | — | Installer advice cannot produce a split-brain install | unit | `DB_PORT=5433 mix test test/mix/tasks/threadline/install_test.exs` | ✅ (arrives with merge) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Optional: a release.yml contract assertion pinning the `sync-release-pr-pins` job (research Open Question 1).

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 140s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
