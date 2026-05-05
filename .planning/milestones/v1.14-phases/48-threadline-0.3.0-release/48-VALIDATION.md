---
phase: 48
slug: threadline-0.3.0-release
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for release-surface sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix shell helpers |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs` |
| **Full suite command** | `mix verify.release` |
| **Estimated runtime** | ~30-60 seconds excluding first-time deps/docs build |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs`
- **After every plan wave:** Run `bin/verify-release-shape && MIX_ENV=dev mix docs`
- **Before `$gsd-verify-work`:** `mix verify.release` must be green from a clean working tree
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | REL-01, REL-02 | T-48-03, T-48-04 | Release narrative, version literals, and ExDoc routing stay aligned with the published `0.3.0` story. | unit / doc-contract | `mix test test/threadline/readme_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/performance_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs` | ✅ planned | ⬜ pending |
| 48-01-02 | 01 | 1 | REL-02, REL-03 | T-48-02, T-48-05 | Package files, guide extras, module grouping, and `ci.all` exclusions fail loudly on drift without requiring a DB. | unit / doc-contract | `mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ planned | ⬜ pending |
| 48-01-03 | 01 | 1 | REL-03 | T-48-01, T-48-05 | `mix verify.release` stays clean-tree-gated and release-scoped while composing metadata, doc, and tarball checks. | shell / smoke | `mix help | grep -F "mix verify.release" && mix verify.release` | ✅ planned | ⬜ pending |
*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `48-RESEARCH.md` resolves the module-grouping question so execution does not carry an open taxonomy decision.
- [x] `48-VALIDATION.md` exists with Nyquist-compliant quick/full commands before execution begins.
- [x] The plan’s release gate uses only pure file-read contracts plus docs/tarball checks; no Postgres-backed test is required by `verify.release`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The `0.3.0` changelog reads as a coherent adoption release instead of a packaging-only bump. | REL-01 | Narrative quality and emphasis are editorial judgments. | Read the final `## [0.3.0]` section in `CHANGELOG.md` and confirm the opener plus subsection ordering reflect SaaS onboarding, Sigra, performance, incident response, and upgrade notes. |
| The README still feels compact and library-first after the new routing changes. | REL-01, REL-02 | Link prominence and cognitive load are not fully machine-checkable. | Read `README.md` from top to bottom and confirm the quickstart, Sigra guide, and deeper operator guides are routed in the intended order. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
