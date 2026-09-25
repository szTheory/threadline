---
phase: "204"
slug: "structure"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-23"
---

# Phase 204 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3), LiveViewTest (LV 1.2.11), Playwright via `mix verify.example_browser` |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test <files>` |
| **Full suite command** | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix ci.all` |
| **Compile gate** | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix compile --force --warnings-as-errors` |
| **Estimated runtime** | quick ~30s; full ci.all several minutes (browser lane longest) |

---

## Sampling Rate

- **After every task commit:** compile `--force --warnings-as-errors` + byte lock + size gate + tests pinning the touched file + `mix credo --strict <touched files>`
- **After every plan wave:** `mix verify.test` + `mix verify.dialyzer` + `mix verify.xref_cycles` + `mix verify.compile_no_optional`; after rendered-code waves also `mix verify.example` and `mix verify.example_browser` (exactly the 8 known failures)
- **Before `/gsd-verify-work`:** `MIX_ENV=test mix ci.all` green (browser at 8 known) + `mix verify.bump_rehearsal`
- **Max feedback latency:** ~60 seconds per task

---

## Per-Task Verification Map

| Req | Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-------------------|-------------|--------|
| STRUCT-01 | rendered CSS sha256 + golden equality | contract | `mix test test/threadline/operator_surface/style_byte_lock_test.exs` | ❌ W0 | ⬜ pending |
| STRUCT-02 | segment order = cascade; `@external_resource`; no orphan `.css`; hash unchanged | contract | `mix test test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/brandbook_token_parity_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/rendered_output_contract_test.exs` | partial | ⬜ pending |
| STRUCT-02 | `.css` segments ship in Hex tarball | contract | `mix test test/threadline/release_artifact_contract_test.exs` | ✅ (add assertion) | ⬜ pending |
| STRUCT-03 | file ≤800 / clause ≤120 or named exception; stale exception fails | contract | `mix test test/threadline/source_size_contract_test.exs` | ❌ W0 | ⬜ pending |
| STRUCT-04 | zero banner-comment lines in `lib/**/*.ex` | contract | `mix test test/threadline/source_size_contract_test.exs` | ❌ W0 | ⬜ pending |
| STRUCT-05 | Endpoint/Router only in `test/support` or documented allowlist | contract | `mix test test/threadline/test_structure_contract_test.exs` | ❌ W0 | ⬜ pending |
| STRUCT-06 | no `verify.doc_contract`; no duplicate test step in ci.all | contract | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs` | ✅ (edit) / ❌ guard | ⬜ pending |
| STRUCT-06 | rehearsal derives doc-contract files | script | `mix verify.bump_rehearsal` | ✅ (edit) | ⬜ pending |
| STRUCT-07 | register empty, ceiling 0, Credo clean | contract + lint | `mix test test/threadline/credo_config_contract_test.exs && mix credo --strict` | ✅ (edit) | ⬜ pending |
| D-00b | zero rendered-output change | e2e | `mix verify.example_browser` → exactly 8 known failures | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/style_byte_lock_test.exs` + `test/fixtures/style/operator_surface.css` + README (STRUCT-01)
- [ ] `test/threadline/source_size_contract_test.exs` — file, function, banner, heex guards seeded at measured values (STRUCT-03/04)
- [ ] `test/support` source-family reader before the first extraction
- [ ] `test/support/operator_surface_case.ex` + `test/threadline/test_structure_contract_test.exs` (STRUCT-05)
- [ ] ci.all dedup guard (STRUCT-06)

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
