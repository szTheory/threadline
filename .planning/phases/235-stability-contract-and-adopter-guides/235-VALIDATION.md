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
| 235-01-01 | 235-01 | 1 | DOCS-02 | T-235-01 | Generated mask guard reaches a real host migration, refuses a nonexistent column, rolls back fully, and the initial guide is in ExDoc. | PostgreSQL migration + guide graph | `mix verify.test test/threadline/capture/trigger_migrate_time_errors_test.exs test/threadline/guide_graph_contract_test.exs` | ✅ existing | ⬜ pending |
| 235-01-02 | 235-01 | 1 | DOCS-02 | T-235-01, T-235-02 | Both invalid options and both key branches fail before DDL; a valid control captures, and the threat guide has bounded proof. | PostgreSQL + doc contract | `mix verify.test test/threadline/capture/trigger_migrate_time_errors_test.exs test/threadline/guides/redaction_contract_test.exs test/threadline/guide_graph_contract_test.exs` | ❌ guide test planned | ⬜ pending |
| 235-02-01 | 235-02 | 2 | CONTRACT-01 | T-235-03 | Stability claims and Phase 234 spec policy match the settled 1.x contract. | doc contract | `mix verify.test test/threadline/guides/stability_contract_test.exs test/threadline/guide_graph_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-02-02 | 235-02 | 2 | DOCS-01 | T-235-04 | An evidence-linked matrix states all install conditions and operational caveats. | doc contract | `mix verify.test test/threadline/guides/table_shapes_contract_test.exs test/threadline/guide_graph_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-03-01 | 235-03 | 2 | CONTRACT-02 | T-235-05 | Live PostgreSQL facts pin required audit columns, types, nullability, and indexes. | PostgreSQL catalog | `mix verify.test test/threadline/storage_catalog_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-03-02 | 235-03 | 2 | CONTRACT-03 | T-235-06 | Literal GUC and function names remain deliberate public contracts. | source/runtime contract | `mix verify.test test/threadline/capture/public_sql_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-04-01 | 235-04 | 2 | CONTRACT-04 | T-235-07 | Export modes and health codes match independent literal pins. | output/set contract | `mix verify.test test/threadline/export_public_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-04-02 | 235-04 | 2 | CONTRACT-04 | T-235-08 | Every Mix-task flag, router option, and documented route is explicitly pinned. | source/set contract | `mix verify.test test/threadline/public_options_contract_test.exs` | ❌ planned | ⬜ pending |
| 235-05-01 | 235-05 | 2 | CONTRACT-05 | T-235-09, T-235-10 | Capture schemas document chosen stable subsets and additive captured-data shapes. | schema/doc contract | `mix verify.test test/threadline/schema_fields_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs` | ❌ schema test planned | ⬜ pending |
| 235-05-02 | 235-05 | 2 | CONTRACT-05 | T-235-09 | Semantic AuditAction subset is checked against its Ecto schema. | schema/doc contract | `mix verify.test test/threadline/schema_fields_contract_test.exs test/threadline/doc_spec_coverage_contract_test.exs` | ❌ schema test planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] In each plan's first affected task, write the named new ExUnit file and a failing claim/assertion before completing its implementation; the established test helper, DataCase, and PostgreSQL migration harness are available.
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

**Approval:** pending execution evidence; plan task mapping complete. Keep `status: draft` and `nyquist_compliant: false` until the focused checks and final `mix ci.all` pass.

## Spec-less probe fallback

All 13 edge rows from the shared probe are assigned in the five PLAN.md `<edge_probe>` sections. CONTRACT-03, CONTRACT-05, and DOCS-02 remain explicitly unclassified/unresolved. The other flagged assumptions are CONTRACT-01 precision/concurrency, CONTRACT-02 encoding, and CONTRACT-04 adjacency. The remaining rows become plan-specific acceptance truths. No generic probe item expands the product scope.

The prohibition recall pass over-produced for each requirement, then removed routine correctness/hygiene candidates. The table records the raw themes; only the values/privacy/safety/transparency items in the PLAN.md `must_haves.prohibitions` remain, all descriptor-less and flagged unverified.

| Requirement | Stage 1 raw candidates (about ten, before precision filtering) | Stage 2 disposition |
|-------------|---------------------------------------------------------------|---------------------|
| CONTRACT-01 | promise UI internals; hide deprecation removal; omit backport cutoff; shift floor; round dates; stale link; broken heading; duplicate text; wrong option type; undocumented trigger exception | Keep misleading public-boundary promise; policy facts are acceptance truths; routine editing/formatting dropped. |
| CONTRACT-02 | certify SQL text alone; search wrong schema; ignore nullability; ignore index validity; accept missing table; stale test DB; wrong type alias; nondeterministic order; bad query; timeout | Keep false installed-catalog claim; catalog correctness and test hygiene handled by task gate. |
| CONTRACT-03 | derive pins from renamed code; hide changed caller; ignore long identifier; stale name sample; duplicate name; wrong quoting; test typo; source scan gap; empty pin; unstable order | Keep self-derived public-name pin; functional/source checks are task acceptance. |
| CONTRACT-04 | derive expected headers; omit action mode; mask missing health code; ignore new task; ignore zero-flag task; route reorder; parser alias drift; stale fixture; header encoding; empty output | Keep self-derived public-set claim; concrete cases are task acceptance. |
| CONTRACT-05 | freeze full struct; promise virtual association; promise JSON bytes; promise key order; omit field; wrong schema; type drift; duplicate field; text drift; unrelated module | Keep over-broad field/serialization promises; schema/doc checks are acceptance. |
| DOCS-01 | hide unique-index rule; claim unlogged durability; claim view support; omit key types; omit 63-byte limit; misstate char padding; broken link; missing matrix row; long example; unsupported screenshot | Keep hidden install/durability condition; named rows and links are acceptance. |
| DOCS-02 | claim prior rows repaired; imply all paths covered; omit WAL; omit host source; omit backups; omit downstream copies; miss invalid mask; miss invalid exclude; leak error row value; stale test link | Keep over-broad privacy and bypass claims; migration regressions and named plaintext locations are acceptance. |

SQL injection and generic data-retention compliance surfaced in recall are canon security/compliance items; the threat model and `$gsd-secure-phase` own them, so they were not minted as bespoke prohibitions.
