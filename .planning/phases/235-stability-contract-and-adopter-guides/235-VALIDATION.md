---
phase: "235"
slug: "stability-contract-and-adopter-guides"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-06"
---

# Phase 235 — Validation Strategy

> Feedback contract for the compatibility tests, migration guard, and adopter documentation in this phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit; PostgreSQL integration tests through the existing `Threadline.DataCase` and migration harness |
| **Config file** | `test/test_helper.exs`, `config/test.exs`, and existing database test support |
| **Quick run command** | `mix verify.test <focused test path>` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Focused contracts: under 30 seconds; full verification: use current CI timing |

---

## Sampling Rate

- **After every task commit:** Run the task's focused `mix verify.test` target and `mix verify.format` when Elixir files change.
- **After every plan wave:** Run the focused suites for changed contracts and `mix ci.all` at the final verification gate.
- **Before `$gsd-verify-work`:** Run `mix ci.all`.
- **Max feedback latency:** 60 seconds for focused feedback; full-suite latency is measured from CI rather than assumed.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 235-01-01 | TBD | TBD | CONTRACT-01 | — | Stability claims match the settled 1.x contract and do not imply undocumented guarantees. | doc contract | `mix verify.test test/threadline/guides/stability_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-01-02 | TBD | TBD | CONTRACT-02 | — | Live PostgreSQL catalog facts pin required audit columns, types, nullability, and shipped indexes. | PostgreSQL integration | `mix verify.test test/threadline/storage_schema_migration_contract_test.exs` | ✅ existing | ⬜ pending |
| 235-01-03 | TBD | TBD | CONTRACT-03 | — | Literal GUC and trigger-function names remain deliberate, attributable public contracts. | contract | `mix verify.test test/threadline/capture/public_sql_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-01-04 | TBD | TBD | CONTRACT-04 | — | Export, health, task, and operator surfaces retain explicitly pinned additive sets. | contract | `mix verify.test test/threadline/public_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-01-05 | TBD | TBD | CONTRACT-05 | — | Documented stable schema fields remain present while additive fields and JSONB keys remain allowed. | schema/doc contract | `mix verify.test test/threadline/schema_fields_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-02-01 | TBD | TBD | DOCS-01 | — | The adopter can determine eligibility and caveats from a concise evidence-linked shape matrix. | doc contract | `mix verify.test test/threadline/guides/table_shapes_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-02-02 | TBD | TBD | DOCS-02 | T-235-01 | Generated migrations reject absent mask/exclude columns before trigger DDL; failed host migrations leave no partial trigger state. | PostgreSQL migration integration | `mix verify.test test/threadline/capture/trigger_migrate_time_errors_test.exs` | ✅ existing | ⬜ pending |
| 235-02-03 | TBD | TBD | DOCS-02 | T-235-01 | Redaction guide scopes claims to proven paths and names residual plaintext locations and migration rollout limits. | doc/security contract | `mix verify.test test/threadline/guides/redaction_contract_test.exs` | ❌ planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add or extend focused ExUnit contract tests named in the task map where they do not yet exist.
- [ ] Reuse the existing PostgreSQL migration harness for redaction guard regressions; no new framework or dependency is expected.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | Guide claims and required evidence links are covered by focused document-contract assertions. | Review remains useful during planning, but no behavior is designated manual-only. |

---

## Validation Sign-Off

- [ ] Every planned task has an `<automated>` verification or a Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers missing test files and fixtures.
- [ ] No watch-mode flags.
- [ ] Focused feedback latency is at most 60 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter after validation.

**Approval:** pending plan task mapping
