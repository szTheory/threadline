---
phase: 74
slug: nyquist-closeout-and-requirement-tracking-repair
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
updated: 2026-05-08T18:30:00Z
---

# Phase 74 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 74 is planning-closeout repair. The main risks are claiming milestone completion on stale counts or rerunning the audit without enough artifact evidence behind PKG-01 and PKG-02.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Planning-artifact checks, ExUnit contract tests for Phase 72 package-closeout proof, and Mix alias verification |
| **Config file** | `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; `.planning/STATE.md`; `.planning/v1.19-MILESTONE-AUDIT.md`; `mix.exs` |
| **Quick run command** | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-20 seconds on a warm cache |
| **Estimated runtime — full** | ~90-150 seconds on a warm cache |

---

## Sampling Rate

- **After Plan 74-01:** run the focused Phase 72 package/doc contract suite.
- **After Plan 74-02 / before final verification:** run `mix verify.compile_no_optional` and `mix ci.all`.
- **Max feedback latency:** 20 seconds for the focused suite, 150 seconds for the full gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 74-01-01 | 01 | 1 | PKG-01, PKG-02 | T-74-01 | Phase 72 has a final validation artifact with explicit proof commands and Nyquist status. | artifact + doc-contract | `rg -n '^nyquist_compliant: true|Quick run command|Compile-no-optional gate' .planning/phases/72-packaging-boundary-scorecard-and-closeout/72-VALIDATION.md && mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 74-01-02 | 01 | 1 | PKG-01, PKG-02 | T-74-02 | Phase 72 summaries expose enough metadata for traceability and audit reconstruction. | artifact verification | `rg -n '^phase: 72|^provides:|^affects:' .planning/phases/72-packaging-boundary-scorecard-and-closeout/72-01-SUMMARY.md .planning/phases/72-packaging-boundary-scorecard-and-closeout/72-02-SUMMARY.md` | ✅ | ✅ green |
| 74-02-01 | 02 | 2 | PKG-01, PKG-02 | T-74-03 | Active milestone files report the repaired final tree consistently and no longer undercount completed work. | planning artifact check | `rg -n 'completed_phases: 6|completed_plans: 16|percent: 100|73\\. Authorization Contract Repair.*3/3|74\\. Nyquist Closeout.*2/2|PKG-01 \\| Phase 74 \\| Complete|PKG-02 \\| Phase 74 \\| Complete' .planning/STATE.md .planning/ROADMAP.md .planning/REQUIREMENTS.md` | ✅ | ✅ green |
| 74-02-02 | 02 | 2 | PKG-01, PKG-02 | T-74-04 | The rerun milestone audit passes on the repaired tree and demotes remaining work to release hygiene. | audit artifact + full gate | `rg -n '^status: passed|requirements: 10/10|phases: 6/6|integration: 4/4|flows: 4/4' .planning/v1.19-MILESTONE-AUDIT.md && mix verify.compile_no_optional && mix ci.all` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-01-PLAN.md`
- [x] `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-02-PLAN.md`
- [x] `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VALIDATION.md`

Wave 0 is complete. Phase 74 exists explicitly as the milestone-closeout repair slice that the audit called for.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review of what still blocks a Hex release | PKG-01, PKG-02 | Release hygiene is separate from milestone implementation and needs an explicit boundary | Confirm the rerun audit names only clean-branch, clean-worktree, CI, versioning, and publish steps as remaining work, not missing milestone implementation. |

---

## Validation Sign-Off

- [x] Both Phase 74 plans have explicit automated verification coverage.
- [x] Phase 72 artifact repair is tied to a focused contract suite.
- [x] The rerun audit is tied to compile-no-optional and full-suite gates.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-08 after the Phase 72 artifact repair, planning-file reconciliation, and final-tree verification gates were recorded.
