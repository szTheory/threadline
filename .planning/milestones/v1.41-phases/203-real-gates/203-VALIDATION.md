---
phase: "203"
slug: "real-gates"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-22"
---

# Phase 203 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib); contract tests at `test/threadline/*_contract_test.exs` |
| **Config file** | `test/test_helper.exs` (always requires Postgres; run `docker compose up -d` first, DB on :5433) |
| **Quick run command** | `DB_PORT=5433 MIX_ENV=test mix test test/threadline/credo_config_contract_test.exs test/threadline/layer_boundary_contract_test.exs` |
| **Full suite command** | `DB_PORT=5433 MIX_ENV=test mix ci.all` |
| **Estimated runtime** | ~30 seconds quick; full `ci.all` several minutes |

---

## Sampling Rate

- **After every task commit:** `mix compile --warnings-as-errors` + touched file's tests + relevant contract test
- **After every plan:** re-measure `mix credo --strict --config-file deps/credo/.credo.exs --format json` (count drops by exactly the plan's scope) + `mix verify.format`
- **Before `/gsd-verify-work`:** `DB_PORT=5433 MIX_ENV=test mix ci.all` green (browser lane at its known 8-failure baseline), `MIX_ENV=dev mix dialyzer --no-check` = 0 errors, `mix verify.xref_cycles` exit 0
- **Max feedback latency:** ~60 seconds per task

---

## Per-Task Verification Map

| Requirement | Behavior | Test Type | Automated Command | File Exists | Status |
|-------------|----------|-----------|-------------------|-------------|--------|
| GATE-01 | `.credo.exs` has no `enabled:`; deltas equal pinned list; effective check set = 69 | contract + CLI | `mix test test/threadline/credo_config_contract_test.exs` | ❌ W0 | ⬜ pending |
| GATE-01/02 | gate live and green | CLI | `mix verify.credo` | ✅ | ⬜ pending |
| GATE-02 | register counts exact, ceiling non-increasing, only allowed disable form, adjacent Phase 204 line | contract | `mix test test/threadline/credo_config_contract_test.exs` | ❌ W0 | ⬜ pending |
| GATE-03 | no `OperatorSurface` reference outside allowlist; scan non-empty | contract | `mix test test/threadline/layer_boundary_contract_test.exs` | ❌ W0 | ⬜ pending |
| GATE-03 | renamed modules keep behaviour (tenant scope, filter codec) | unit/integration | `mix test test/threadline/public_surface_contract_test.exs test/threadline/operator_surface/exports_doc_contract_test.exs` | ✅ | ⬜ pending |
| GATE-04 | 0 compile-connected cycles; no `no_warn_undefined` in lib | CLI + contract | `mix verify.xref_cycles` ; `mix compile --force --warnings-as-errors` | ❌ W0 | ⬜ pending |
| GATE-04 | `:action` preload still works | integration | `mix test test/threadline/investigation_test.exs` | ✅ | ⬜ pending |
| GATE-05 | every lib module has deliberate moduledoc; no stale `file.ex:NN` comments | Credo delta + contract | `mix verify.credo` ; layer_boundary/stale-location scan | ❌ W0 | ⬜ pending |
| D-00b | Dialyzer stays at 0 | CLI | `MIX_ENV=dev mix dialyzer --no-check` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/credo_config_contract_test.exs` — GATE-01/02 (shape, pinned deltas, register, ceiling)
- [ ] `test/threadline/layer_boundary_contract_test.exs` — GATE-03 + GATE-04 `no_warn_undefined` scan (+ GATE-05 stale-location scan)
- [ ] `mix.exs` alias `verify.xref_cycles` + `ci.all` entry + step inside existing `verify-test` CI job (job IDs unchanged)

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
