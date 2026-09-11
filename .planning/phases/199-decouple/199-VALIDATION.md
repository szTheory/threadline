---
phase: "199"
slug: "decouple"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-10"
---

# Phase 199 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on the pinned current Elixir/OTP lane; Playwright for e2e capture/path behavior |
| **Config file** | `test/test_helper.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs -x` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Quick contracts under 60 seconds; full local/CI gate under the Phase 198 20-minute budget after a warm PLT; cold Dialyzer time must be measured |

---

## Sampling Rate

- **After every task commit:** Run the focused contract file changed plus `mix verify.format`.
- **After every plan wave:** Run `mix verify.test` and every gate introduced or changed in that wave; after Dialyxir lands also run `mix dialyzer --list-unused-filters`.
- **Before `$gsd-verify-work`:** A disposable committed-tree clone must pass `mix deps.get --check-locked`, exact clean-status checks, `mix ci.all` with `.planning/` renamed away, and unpacked-Hex negative assertions.
- **Max feedback latency:** 60 seconds for focused contracts; 20 minutes for the warm full gate. The cold PLT build is measured separately and sets its own CI timeout.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 199-01-01 | 01 | 1 | DECOUPLE-01, DECOUPLE-02 | T-199-01, T-199-02 | Required evidence cannot resolve outside its root or pass when absent | contract/integration | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs -x` | ❌ W0 | ⬜ pending |
| 199-01-02 | 01 | 1 | DECOUPLE-01, DECOUPLE-02 | T-199-03 | Fixture bytes and cross-dataset joins survive the move; fixtures stay out of Hex | contract/package | `mix test test/threadline/operator_surface/mechanical_checker_test.exs test/threadline/operator_surface/critic_trust_test.exs -x` | ✅ extend | ⬜ pending |
| 199-02-01 | 02 | 2 | DECOUPLE-03, DECOUPLE-04 | T-199-04 | Deletion preserves durable evidence and leaves no live missing-path citation | contract/doc | `mix test test/threadline/removed_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs -x` | ❌ W0 / ✅ extend | ⬜ pending |
| 199-03-01 | 03 | 2 | DECOUPLE-05, DECOUPLE-06 | T-199-05 | Shared ignores cannot hide reviewed evidence; child formatter ownership does not overlap | contract/CLI | `mix format --check-formatted` | ✅ framework / ❌ topology contract | ⬜ pending |
| 199-03-02 | 03 | 2 | DECOUPLE-05 | T-199-06 | A dependency fetch leaves an exact clean disposable clone | integration | `mix deps.get --check-locked` followed by exact `git status --porcelain=v1 --untracked-files=all` assertion | ❌ W0 proof harness | ⬜ pending |
| 199-04-01 | 04 | 3 | DECOUPLE-07, DECOUPLE-08 | T-199-07, T-199-08 | Strict ignores cannot broaden or accumulate silently; incomplete PLTs remain visible | contract/static analysis | `mix test test/threadline/dialyzer_ignore_contract_test.exs -x && mix dialyzer --list-unused-filters` | ❌ W0 | ⬜ pending |
| 199-05-01 | 05 | 4 | DECOUPLE-01, DECOUPLE-05, DECOUPLE-07 | T-199-09 | Aggregate CI blocks on Dialyzer and records valid cold/warm evidence | CI/E2E | `mix ci.all` in a disposable clone with `.planning/` renamed away | ❌ final proof | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` — fixture presence, parseability, non-vacuity, cross-dataset joins, byte identity, immutable/generated separation, containment, and zero executable `.planning` dataset literals.
- [ ] Extend `test/threadline/operator_surface/mechanical_checker_test.exs` — remove the absent-directory success contract and require explicit floors/scorecard input for repository gates.
- [ ] `test/threadline/dialyzer_ignore_contract_test.exs` — strict tuple/comment shape, duplicate/broad-filter rejection, tighten-only ceiling, unused filters, and positive controls.
- [ ] `test/threadline/removed_artifact_contract_test.exs` — tracked root-script absence and no active citation to removed paths.
- [ ] Formatter-topology contract — root subdirectories plus child-specific inputs with no overlap.
- [ ] Disposable-clone proof harness — clean dependency fetch and `.planning`-absent `mix ci.all` without making CI depend on planning artifacts.

Wave 0 tests may be red only inside an explicitly staged TDD plan. The atomic fixture move must not leave the branch with half-migrated readers.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authoritative cold-PLT and cache-hit measurements on the pinned current CI image | DECOUPLE-07 | Local Elixir/OTP does not exactly match the required current CI toolchain; timing must come from the real runner | Run the new CI job once with no matching PLT cache and once with a cache hit; record SHA, image, exact toolchain, hashes, wall time, peak memory, and job URLs in `CONTRIBUTING.md` |

All other phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Focused feedback latency < 60 seconds and warm full-gate latency < 20 minutes
- [ ] `nyquist_compliant: true` set in frontmatter after validation

**Approval:** pending
