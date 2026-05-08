---
phase: 67
slug: drift-aware-redaction-admin-mix-task-parity
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
completed: 2026-05-07
---

# Phase 67 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 67 adds one shared reconciliation core, one Mix parity surface, one LiveView surface, and one contract/docs slice. The critical risk is false confidence from permissive `pg_proc.prosrc` parsing, so the validation plan biases toward fail-closed parser tests plus parity/contract assertions.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + `Threadline.DataCase` + `Phoenix.LiveViewTest` + pure source-reading doc-contract tests |
| **Config file** | `test/test_helper.exs`; `mix.exs` aliases (`verify.test`, `verify.compile_no_optional`, `ci.all`) |
| **Quick run command** | `mix test test/threadline/policy/redaction_presenter_test.exs test/threadline/operator_surface/policy_show_mix_test.exs --trace` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick** | ~5–15 seconds depending on parser fixture vs Mix/LV integration path |
| **Estimated runtime — wave merge** | ~30–60 seconds using all Phase 67 test files |
| **Estimated runtime — full `mix ci.all`** | ~90 seconds on a warm cache |

---

## Sampling Rate

- **After every task commit:** run the task-scoped command from the verification map below.
- **After every plan wave:** run the full Phase 67 file set plus `mix verify.compile_no_optional`.
- **Before `/gsd-verify-work`:** `mix ci.all` must be green.
- **Max per-task feedback target:** 15 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 67-01-01 | 01 | 1 | REDN-03, REDN-04 | Shared presenter normalizes configured policy, validates deployed trigger language/shape, parses only known Threadline fragments, and fails closed to `:could_not_introspect` on unsupported bodies. | unit | `mix test test/threadline/policy/redaction_presenter_test.exs --trace` | ❌ W0 | ⬜ pending |
| 67-01-02 | 01 | 1 | REDN-04 | Repo-backed introspection proves `pg_trigger -> pg_proc.prosrc` retrieval against actual Threadline-generated SQL and classifies missing triggers as drift. | unit (DB-touching) | `mix test test/threadline/policy/redaction_presenter_catalog_test.exs --trace` | ❌ W0 | ⬜ pending |
| 67-02-01 | 02 | 2 | REDN-05 | `mix threadline.policy.show` is viewer-not-gate, reuses the shared presenter, emits stable JSON enums, and preserves canonical section/alphabetical ordering. | Mix integration | `mix test test/threadline/operator_surface/policy_show_mix_test.exs --trace` | ❌ W0 | ⬜ pending |
| 67-03-01 | 03 | 2 | REDN-03, REDN-04 | `PolicyRedactionLive` is file-scope gated, renders three locked sections with count headers, preserves alphabetical intra-section ordering, and shows exact configured/deployed sets without sample values. | LV integration | `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs --trace` | ❌ W0 | ⬜ pending |
| 67-03-02 | 03 | 2 | REDN-03 | Route literal and style wiring compile cleanly and stay green when Phoenix is absent. | compile + optional-deps gate | `mix compile --warnings-as-errors && mix verify.compile_no_optional` | ✅ (extends existing router/style surfaces) | ⬜ pending |
| 67-04-01 | 04 | 3 | REDN-05 | Doc-contract test pins route/status/JSON/no-sample-values invariants and distinguishes gated vs ungated files. | doc-contract | `mix test test/threadline/operator_surface/policy_show_doc_contract_test.exs --trace` | ❌ W0 | ⬜ pending |
| 67-04-02 | 04 | 3 | REDN-05 | Docs stay aligned with exact route and Mix command literals; README/doc-contract surfaces remain green. | doc-contract | `mix test test/threadline/operator_surface/policy_show_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs --trace` | ✅ (extends existing docs and doc-contract coverage) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The following files are new and must be created during execution:

- [x] `test/threadline/policy/redaction_presenter_test.exs`
- [x] `test/threadline/policy/redaction_presenter_catalog_test.exs`
- [x] `test/threadline/operator_surface/policy_show_mix_test.exs`
- [x] `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- [x] `test/threadline/operator_surface/policy_show_doc_contract_test.exs`

Wave 0 confirmation items:

- [x] Canonical ordering ownership is resolved in research: shared reconciler owns section rank + alphabetical intra-section ordering.
- [x] Missing deployed trigger classification is resolved in research: `drift_detected`, not `could_not_introspect`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None required for release gate | — | All locked Phase 67 behaviors are intended to have automated coverage | Manual browser review of `/audit/policy/redaction` is optional only |

---

## Validation Sign-Off

- [x] All planned tasks have explicit automated verification coverage or compile gates.
- [x] Sampling continuity: no long gap without parser/Mix/LV/doc-contract feedback.
- [x] Wave 0 covers all new test-file requirements.
- [x] No watch-mode flags.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** completed on 2026-05-07.
