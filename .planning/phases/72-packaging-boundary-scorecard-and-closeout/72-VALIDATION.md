---
phase: 72
slug: packaging-boundary-scorecard-and-closeout
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-08
updated: 2026-05-08T18:30:00Z
---

# Phase 72 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 72 is packaging-closeout work. The main risks are overstating extraction pressure, drifting the stay-in-tree decision across docs/package metadata, or claiming closeout without a complete proof chain.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit doc-contract tests, source-read package-contract checks, and Mix alias verification |
| **Config file** | `mix.exs`; `test/test_helper.exs`; `.github/workflows/ci.yml` |
| **Quick run command** | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~10-20 seconds on a warm cache |
| **Estimated runtime — full** | ~90-150 seconds on a warm cache |

---

## Sampling Rate

- **After every task commit:** run the focused package/doc contract suite listed below.
- **After Wave 1:** run the focused package/doc contract suite plus `mix verify.compile_no_optional`.
- **Before phase verification:** run `mix ci.all`.
- **Max per-task feedback target:** 20 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | PKG-01, PKG-02 | T-72-01 | Upgrade-path guide defines objective extraction triggers and records the v1.19 answer as stay in-tree for now. | doc-contract/readback | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |
| 72-02-01 | 02 | 2 | PKG-02 | T-72-02 | ExDoc module grouping states explicitly that the operator surface remains optional and in-tree. | package-contract | `mix test test/threadline/release_artifact_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `.planning/phases/72-packaging-boundary-scorecard-and-closeout/72-01-PLAN.md`
- [x] `.planning/phases/72-packaging-boundary-scorecard-and-closeout/72-02-PLAN.md`
- [x] `.planning/phases/72-packaging-boundary-scorecard-and-closeout/72-VERIFICATION.md`
- [x] `.planning/phases/72-packaging-boundary-scorecard-and-closeout/72-VALIDATION.md`

Wave 0 is complete. The final validation artifact now exists and records the package-closeout proof contract that was missing during the first audit.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Human review of the package-boundary narrative | PKG-01, PKG-02 | The difference between “objective extraction triggers” and “package-split rhetoric” is partly editorial | Confirm the scorecard reads as evidence-based guidance, keeps the operator surface optional, and preserves the future API guarantee without implying an imminent split. |

---

## Validation Sign-Off

- [x] Both Phase 72 plans have explicit automated verification coverage.
- [x] Focused proof plus compile-no-optional and full-suite gates are recorded.
- [x] Wave 0 artifacts are now complete.
- [x] No watch-mode or manual-only commands are required for the phase gate.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** finalized on 2026-05-08 after the Phase 72 proof surface remained green on the repaired final tree and the missing validation artifact was restored in Phase 74.
