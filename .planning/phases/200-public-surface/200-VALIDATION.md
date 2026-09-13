---
phase: "200"
slug: "public-surface"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-11"
---

# Phase 200 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.17.3; ExDoc 0.40.1; Hex 2.5.1 |
| **Config file** | `test/test_helper.exs` |
| **Wave 0 control command** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix test test/threadline/public_surface_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/community_health_contract_test.exs test/threadline/release_artifact_contract_test.exs --exclude phase200_red --exclude phase200_aggregate -x` |
| **Final contract command** | Run `public_doc_references` and `archive_vocabulary` explicitly, then all four contract files without exclusions after every owner plan finishes. |
| **Docs gate** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=dev mix docs --warnings-as-errors` |
| **Package gate** | Build and unpack to a fresh `mktemp -d /tmp/threadline-hex.XXXXXX` directory with `mix hex.build --unpack --output`, then run the release-artifact contract against that directory |
| **Full suite command** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 DB_PORT=5433 MIX_ENV=test mix ci.all` |
| **Estimated runtime** | Quick contracts: under 30 seconds; full phase gate: project CI duration |

---

## Sampling Rate

- **After every task commit:** Run the narrow contract file owned by the task; include the storage regression whenever adapter delivery behavior changes.
- **After every plan wave:** Run only the completed owners' bounded tags plus `mix compile --warnings-as-errors`; do not invoke `:public_doc_references` or `:archive_vocabulary` while later source/prose owners are still pending.
- **Before `$gsd-verify-work`:** After Plans 200-15 through 200-18 and every prose owner complete, run final Plan 200-14's overall contracts/docs/package/GitHub/CI/clean-clone command, including explicit `:source_module_vocabulary`, `:public_doc_references`, and `:archive_vocabulary` aggregates, `mix ci.all`, `bin/verify-planning-independent` in a committed clean clone with `.planning/` absent, the warnings-as-errors docs gate, a fresh unpacked package scan, and the hosted GitHub smoke/read-back checklist.
- **Max feedback latency:** 30 seconds for task-local contracts; use wave boundaries for full docs/package/CI checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Automated Command / Gate | Status |
|---------|------|------|-------------|------------|-----------------|--------------------------|--------|
| 200-01-01 | 01 | 1 | SURFACE-01–05,07 | T-200-01,02,05 | Source-owned inventories, exact public-doc corpus, and archive controls are non-vacuous and never read .planning at CI runtime | `mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs --exclude phase200_red --exclude phase200_aggregate -x` | ⬜ pending |
| 200-01-02 | 01 | 1 | SURFACE-06,08–11 | T-200-03 | Graph/community controls expose unsafe or unreachable routes | `mix test test/threadline/guide_graph_contract_test.exs test/threadline/community_health_contract_test.exs --exclude phase200_red -x` | ⬜ pending |
| 200-01-03 | 01 | 1 | SURFACE-07 | T-200-04 | Optional-callback regression is isolated | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs --exclude phase200_red -x` | ⬜ pending |
| 200-02-01 | 02 | 2 | SURFACE-07 | T-200-05,06 | Runtime-key reference and its owned public-document references are exact before command sections exist | runtime-key plus `public_doc_refs_config` tags | ⬜ pending |
| 200-02-02 | 02 | 2 | SURFACE-07 | T-200-05,06 | Task/alias reference, complete inventory, and config-reference corpus are exact | command/public-inventory/config-reference tags | ⬜ pending |
| 200-03-01 | 03 | 2 | SURFACE-07 | T-200-06 | Locked one-way D-02 commitment is explicitly confirmed | blocking decision confirmation; no architecture fork | ⬜ pending |
| 200-03-02 | 03 | 2 | SURFACE-07 | T-200-05,06 | Storage/queue docs match supported behavior and contain only existing public references | public inventory + `public_doc_refs_extensions` + warnings-as-errors compile | ⬜ pending |
| 200-03-03 | 03 | 2 | SURFACE-07 | T-200-04 | No-path adapter delivers remotely | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs -x` | ⬜ pending |
| 200-04-01 | 04 | 3 | SURFACE-03,04 | T-200-01 | D-09 hidden/public tracer and six groups | `mix test test/threadline/public_surface_contract_test.exs --only module_visibility_tracer -x` | ⬜ pending |
| 200-04-02 | 04 | 3 | SURFACE-02,05,07 | T-200-02,05,07 | README main, URL extras, design-resource references, release docs gate, and mix.exs offender cleanup | URL-extra + external-design-reference tags | ⬜ pending |
| 200-05-01 | 05 | 4 | SURFACE-01–04,07 | T-200-01,02,05 | Seed audit plus named UI/generator/evidence offenders and exact public references | module-seed + module-reference tags | ⬜ pending |
| 200-05-02 | 05 | 4 | SURFACE-01–04,07 | T-200-01,02,05 | Capture/export audit plus TriggerSQL cleanup and exact public references | capture + capture-reference tags | ⬜ pending |
| 200-06-01 | 06 | 5 | SURFACE-01–04,07 | T-200-01,02,05 | Governance/health audit preserves returned contracts and resolves public references | governance + governance-reference tags | ⬜ pending |
| 200-06-02 | 06 | 5 | SURFACE-01–04,07 | T-200-01,02,05 | Domain-tail audit preserves UI boundary and resolves public references | domain-tail + domain-tail-reference tags | ⬜ pending |
| 200-07-01 | 07 | 6 | SURFACE-01–04,07 | T-200-01,04,05 | Export/coverage audit preserves delivery/polling and resolves references | operator-coverage + reference tags | ⬜ pending |
| 200-07-02 | 07 | 6 | SURFACE-01–04,07 | T-200-01,04,05 | Auth/session audit preserves access behavior and resolves references | operator-plugs + reference tags | ⬜ pending |
| 200-08-01 | 08 | 7 | SURFACE-01–04,07 | T-200-01,02,05 | Remaining operator audit preserves Router and resolves references | operator-helper + reference tags | ⬜ pending |
| 200-08-02 | 08 | 7 | SURFACE-01–05,07 | T-200-01,02,05 | Final visible/group/hidden equality and CHANGELOG references; no full source aggregate yet | module visibility + changelog-reference tags | ⬜ pending |
| 200-09-01–02 | 09 | 3 | SURFACE-06,07,09 | T-200-05,08 | README/example route to sole first-hour owner with exact public references | canonical-owner + adopt-core/example-reference + existing doc contracts | ⬜ pending |
| 200-10-01 | 10 | 4 | SURFACE-06,07,09 | T-200-08,09 | Sole operator owner before Docker work | operator-surface + operator-owner contracts | ⬜ pending |
| 200-10-02 | 10 | 4 | SURFACE-06,07,09 | T-200-08,09 | Operator/Docker owners and Operate graph/references are complete | canonical-owner + operate-reference tags | ⬜ pending |
| 200-11-01 | 11 | 8 | SURFACE-06,07,09 | T-200-05,09 | Evaluate/adoption-planning subgraph and references are complete | evaluate graph + evaluate-reference tags | ⬜ pending |
| 200-11-02 | 11 | 8 | SURFACE-01,06,07 | T-200-01,05,09 | Architecture subgraph uses existing public identifiers | architecture doc/graph/reference contracts | ⬜ pending |
| 200-12-01 | 12 | 9 | SURFACE-01,06,07 | T-200-01,05,09 | Integration contract guide uses existing public identifiers | integration contract + reference tag | ⬜ pending |
| 200-12-02 | 12 | 9 | SURFACE-04–07,09 | T-200-01,05,09 | Exactly 18 guide nodes form the complete graph and native docs render | integration-tail reference + full graph + docs generation/visual check | ⬜ pending |
| 200-13-01 | 13 | 10 | SURFACE-06,07,10 | T-200-05,09 | Newcomer flow, planning independence, and contributor references pass before troubleshooting | contributor-flow + contribute-reference + guide/routing contracts | ⬜ pending |
| 200-13-02 | 13 | 10 | SURFACE-06–08,10 | T-200-05,09 | Exact database repair and contributor routing/references are complete | contributor-troubleshooting + contribute-reference + guide graph | ⬜ pending |
| 200-15-01–02 | 15 | 8 | SURFACE-01,02,07 | T-200-02,05 | Five core matched sources have exact owners, durable rationale, and preserved behavior | `source_vocab_core_runtime` + `source_vocab_core_query_policy` + focused suites | ⬜ pending |
| 200-16-01–02 | 16 | 8 | SURFACE-01,02 | T-200-02,10 | Logo/mechanical/stress matched sources use stable cohorts without geometry, mechanics, structure, or route drift | `source_vocab_operator_infrastructure` + `source_vocab_operator_stress` + focused suites | ⬜ pending |
| 200-17-01–02 | 17 | 8 | SURFACE-01,02 | T-200-02,10 | Five form-oriented LiveViews are clean with form/polling/history/auth/rendering unchanged | `source_vocab_operator_live_forms` + five LiveView suites | ⬜ pending |
| 200-18-01–02 | 18 | 8 | SURFACE-01,02 | T-200-02,10 | Five record-oriented LiveViews are clean with retention/query/timestamp/auth/rendering unchanged | `source_vocab_operator_live_records` + five LiveView suites | ⬜ pending |
| 200-14-01 | 14 | 11 | SURFACE-11 | T-200-03 | Issue/security intake is safe before PR/conduct files exist | `community_health_contract_test.exs --only issue_security_tracer` | ⬜ pending |
| 200-14-02 | 14 | 11 | SURFACE-11 | T-200-03,11–13 | Community aggregate and private-reporting read-back pass within 30 seconds | timed community-health + GitHub enable/read-back | ⬜ pending |
| 200-14-03 | 14 | 11 | SURFACE-11 | T-200-03,12 | Default-branch forms/settings work for a non-maintainer | API read-back plus manual post-merge outsider smoke | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/public_surface_contract_test.exs` — source-derived config/task/alias inventories; exact ownership of every local ExDoc extra, both version-pinned URL-extra targets, and every visible compiled/source module doc; arbitrary module/Mix-command/`:threadline`-key reference validation with bounded owner tags, nonempty sentinels, negative fixtures, and final `public_doc_references`; compiled module visibility; exact six-group coverage.
- [ ] `test/threadline/guide_graph_contract_test.exs` — lane assignment, inbound/outbound/Next steps, owner/caller rules, relative path and anchor resolution, and referenced module/task/config existence, with nonempty `canonical_owner_tracer`, `operator_owner_tracer`, `canonical_owners`, `guide_graph_evaluate`, `guide_graph_architecture`, and `guide_graph` boundaries.
- [ ] `test/threadline/community_health_contract_test.exs` — expected files, YAML schema/routing/safety assertions, contributor troubleshooting, and planning-independence checks, split into `contributor_flow`, `contributor_troubleshooting`, `issue_security_tracer`, and `community_health` boundaries.
- [ ] Extend `test/threadline/release_artifact_contract_test.exs` — normalized external URL extras, external-resource absence, six nonempty disjoint source-owner tags whose union is every currently matched packaged source path, final-only `source_module_vocabulary` and `archive_vocabulary` aggregates, non-vacuity, and temporary phase/decision/requirement/milestone offenders from a static source-owned shape contract that never reads `.planning/` at compile or test runtime.
- [ ] Extend `test/threadline/operator_surface/controllers/export_controller_test.exs` — adapter implementing the behavior without optional `path/1` still delivers an export.
- [ ] Repair the current ExDoc warning baseline before making warnings fatal.
- [ ] Record the post-merge non-maintainer GitHub checklist; no local test can substitute for hosted behavior.

Every discovery-based contract must assert a nonempty result and at least one stable sentinel before exact-set comparison. Archive scanning must also prove rejection by injecting a temporary offender. Graph and inventory extractors require negative fixtures for missing targets/anchors, multiline calls, and dynamic keys.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| HexDocs landing and navigation are usable in light, dark, wide, and narrow contexts | SURFACE-04, SURFACE-05, SURFACE-06 | Visual hierarchy, Mermaid theming, focus order, and overflow need rendered inspection | Generate docs to a temporary output; inspect README landing, sidebar group order, both external project-resource links, Mermaid theme switching, keyboard focus order, descriptive link text, and horizontal code/diagram overflow. Do not change operator UI/CSS. |
| GitHub contribution and vulnerability routes work for an unaffiliated visitor | SURFACE-11 | Repository-hosted state and permissions are not proven by local files | After merge to the default branch, inspect the community profile, open each issue form as a non-maintainer, preview the PR template, verify blank issues are disabled, and confirm private vulnerability reporting is enabled and routable. |

---

## Threat References

- **T-200-01 — Accidental API disclosure:** an internal module/config/task becomes documented and consumers form a compatibility dependency. Mitigate with source-derived exact inventories and negative allowlists.
- **T-200-02 — Artifact leakage:** planning vocabulary or maintainer-only resources ship in the Hex tarball. Mitigate with fresh unpacking, UTF-8 scanning, file-count/sentinel non-vacuity, and injected-positive controls.
- **T-200-03 — Public vulnerability disclosure:** issue templates encourage security reports in public. Mitigate with explicit private-report routing, disabled blank issues, and hosted non-maintainer smoke verification.
- **T-200-04 — Optional-callback crash:** a conforming storage adapter without `path/1` fails at runtime. Mitigate with capability detection and a regression adapter that implements only the required behavior contract.

Applicable ASVS L1 areas are configuration, error handling, file/content handling, and sensitive-report routing. No authentication, authorization, session, cryptographic, or new data-schema boundary is introduced by this phase.

---

## Validation Sign-Off

- [ ] All tasks have an `<automated>` verify or explicit Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks lack automated verification.
- [ ] Wave 0 covers every missing test reference.
- [ ] Discovery contracts include non-vacuity and positive/negative controls.
- [ ] No watch-mode flags are used.
- [ ] Task-local feedback latency is below 30 seconds.
- [ ] Hosted GitHub behavior is verified after merge by a non-maintainer path.
- [ ] `nyquist_compliant: true` and `wave_0_complete: true` are set only after evidence exists.

**Approval:** pending
