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
| **Quick run command** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix test test/threadline/public_surface_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/community_health_contract_test.exs test/threadline/release_artifact_contract_test.exs` |
| **Docs gate** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=dev mix docs --warnings-as-errors` |
| **Package gate** | Build and unpack to a fresh `mktemp -d /tmp/threadline-hex.XXXXXX` directory with `mix hex.build --unpack --output`, then run the release-artifact contract against that directory |
| **Full suite command** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.17.3-otp-27 DB_PORT=5433 MIX_ENV=test mix ci.all` |
| **Estimated runtime** | Quick contracts: under 30 seconds; full phase gate: project CI duration |

---

## Sampling Rate

- **After every task commit:** Run the narrow contract file owned by the task; include the storage regression whenever adapter delivery behavior changes.
- **After every plan wave:** Run all four public-surface contract files, `mix compile --warnings-as-errors`, `mix docs --warnings-as-errors`, and the unpacked-package gate.
- **Before `$gsd-verify-work`:** Run `mix ci.all`, the explicit docs gate, a fresh unpacked package scan, and the hosted GitHub smoke/read-back checklist.
- **Max feedback latency:** 30 seconds for task-local contracts; use wave boundaries for full docs/package/CI checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 200-01-01 | 01 | 1 | SURFACE-01, SURFACE-03, SURFACE-04, SURFACE-07 | T-200-01 | Public surface inventory cannot pass vacuously | compiled-doc and AST contract | `mix test test/threadline/public_surface_contract_test.exs` | ❌ W0 | ⬜ pending |
| 200-01-02 | 01 | 1 | SURFACE-02, SURFACE-05 | T-200-02 | Published archive excludes internal vocabulary/resources | artifact integration | `mix test test/threadline/release_artifact_contract_test.exs` | ✅ extend | ⬜ pending |
| 200-01-03 | 01 | 1 | SURFACE-06, SURFACE-09 | — | Documentation graph cannot hide broken or unreachable routes | graph contract | `mix test test/threadline/guide_graph_contract_test.exs` | ❌ W0 | ⬜ pending |
| 200-01-04 | 01 | 1 | SURFACE-08, SURFACE-10, SURFACE-11 | T-200-03 | Reporting routes do not disclose vulnerabilities publicly | community contract | `mix test test/threadline/community_health_contract_test.exs` | ❌ W0 | ⬜ pending |
| 200-02-01 | 02 | 2 | SURFACE-07 | T-200-04 | Adapter without optional `path/1` cannot crash delivery | regression | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs` | ✅ extend | ⬜ pending |
| 200-03-01 | 03 | 2 | SURFACE-01–05 | T-200-01, T-200-02 | Visible modules and packaged files equal explicit allowlists | contract + docs build | `mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs && MIX_ENV=dev mix docs --warnings-as-errors` | ❌ W0 / ✅ extend | ⬜ pending |
| 200-04-01 | 04 | 2 | SURFACE-06, SURFACE-08–10 | — | Canonical procedures remain reachable, exact, and non-duplicated | graph + community contract | `mix test test/threadline/guide_graph_contract_test.exs test/threadline/community_health_contract_test.exs` | ❌ W0 | ⬜ pending |
| 200-05-01 | 05 | 3 | SURFACE-02, SURFACE-05, SURFACE-11 | T-200-02, T-200-03 | Release and community-health surfaces are safe in local artifacts | artifact + structural contract | `mix test test/threadline/community_health_contract_test.exs test/threadline/release_artifact_contract_test.exs` | ❌ W0 / ✅ extend | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/public_surface_contract_test.exs` — source-derived config/task/alias inventories, public-doc vocabulary, compiled module visibility, and exact six-group coverage with nonempty sentinels.
- [ ] `test/threadline/guide_graph_contract_test.exs` — lane assignment, inbound/outbound/Next steps, owner/caller rules, relative path and anchor resolution, and referenced module/task/config existence.
- [ ] `test/threadline/community_health_contract_test.exs` — expected files, YAML schema/routing/safety assertions, contributor troubleshooting, and planning-independence checks.
- [ ] Extend `test/threadline/release_artifact_contract_test.exs` — normalized external URL extras, external-resource absence, full UTF-8 archive vocabulary scan, non-vacuity, and a temporary injected offender.
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
