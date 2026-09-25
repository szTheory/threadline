---
phase: "206"
slug: "installer-migration-versions"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-24"
---

# Phase 206 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3 / OTP 27.3) |
| **Config file** | `test/test_helper.exs` (only `pgbouncer_topology` excluded by default) |
| **Quick run command** | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/mix/tasks/threadline/install_test.exs` |
| **Contract batch** | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/mix/tasks/threadline/install_test.exs test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/code_walkthrough_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs` |
| **Full suite command** | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test` |
| **Estimated runtime** | quick ~5s (incl. compile); full suite several minutes |

---

## Sampling Rate

- **After every task commit:** quick run + `mix format --check-formatted` + `mix credo --strict <changed files>`
- **After every plan wave:** contract batch + `mix compile --force --warnings-as-errors` + `mix verify.xref_cycles`
- **Before `/gsd-verify-work`:** full suite green, `mix verify.format`, `mix verify.credo`, `MIX_ENV=dev mix verify.dialyzer`, `MIX_ENV=dev mix docs --warnings-as-errors`
- **Max feedback latency:** ~10 seconds (quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 206-01-xx | 01 | 1 | CR-01 | — | Fresh install: 3 prefixes 14-digit, valid, unique, audit<semantics<governance | unit | quick run (case 1) | ✅ file / ❌ W0 case | ⬜ pending |
| 206-01-xx | 01 | 1 | CR-01 | — | Future-dated host migration `20991231235959` → all new versions greater and valid | unit | quick run (case 2) | ❌ W0 | ⬜ pending |
| 206-01-xx | 01 | 1 | WR-03 | — | Partial re-run: governance > seeded pair, no fresh advice, D-07 note present | unit | quick run (case 3) | ❌ W0 | ⬜ pending |
| 206-01-xx | 01 | 1 | CR-01 (gen.triggers) | — | install + gen.triggers same run: 4 prefixes unique and increasing | unit | quick run (case 4) | ❌ W0 | ⬜ pending |
| 206-01-xx | 01 | 1 | CHANGELOG | — | Entry shape + archive vocabulary scan pass | contract | contract batch | ✅ | ⬜ pending |

*Task IDs are finalized by the planner. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Four new cases in `test/mix/tasks/threadline/install_test.exs`, run **RED against unmodified code** before the fix (record failure output in SUMMARY).

No framework install is needed; the existing tmp-dir + `Mix.Shell.Process` harness covers the rest.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.* (An optional manual probe — install then gen.triggers in a tmp dir, four distinct prefixes — duplicates case 4.)

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
