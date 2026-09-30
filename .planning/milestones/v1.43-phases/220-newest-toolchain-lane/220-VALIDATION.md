---
phase: "220"
slug: "newest-toolchain-lane"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-28"
---

# Phase 220 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (workflow-YAML contract tests parse `.github/workflows/*.yml`) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/ci_workflow_parity_contract_test.exs` |
| **Full suite command** | `mix verify.test` (then `mix ci.all` at the phase gate) |
| **Estimated runtime** | ~10 seconds quick; several minutes full |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/ci_workflow_parity_contract_test.exs`, plus `mix compile --warnings-as-errors` for any `lib/` or `test/support/` fix
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** Full suite green locally AND the cited CI dispatch run shows min, current and latest green in one run (or the "not yet" findings record exists)
- **Max feedback latency:** ~10 seconds for the quick command

---

## Per-Task Verification Map

Filled by the planner/executor from the PLAN.md task list. Requirement → test map (from RESEARCH.md):

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| LANE-01 roster | `verify-test` matrix is exactly `[min, current, latest]` | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ extend | ⬜ pending |
| LANE-01 pin shape | `latest` row pins valid and strictly newer than `current` (`latest_row_errors/2`) | contract | same | ✅ extend | ⬜ pending |
| LANE-01 no continue-on-error | No voting lane uses `continue-on-error`; `ci-required.needs` covers every job | contract | same | ✅ extend | ⬜ pending |
| LANE-01 no beta PG | Every `postgres:<tag>` matches the release-version allowlist | contract | same | ✅ extend | ⬜ pending |
| LANE-01 outcome | Suite green on exact pins under `--warnings-as-errors` | CI dispatch | `gh workflow run ci.yml --ref <spike branch>` + cited run ID | n/a (live evidence) | ⬜ pending |
| D-08 warning fixes | Six named files compile clean on 1.20/29 and stay clean on the min lane | compile | `mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| D-17 doc parity | Docs mention "Run test suite (latest)" and the updated support statement | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements (the parity contract test already has the `min_row_errors`/`current_row_errors`/`verify_test_matrix_errors` scaffolding to extend).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push of the spike branch and the workflow dispatch | LANE-01 | Push/dispatch is a maintainer-granted action (classifier-gated), not a verification judgment | Maintainer grants the named branch push + each dispatch; the run ID is then cited automatically |

*All verification judgments are automated; only the push/dispatch grant is handed to the maintainer.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s for the quick command
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
