---
phase: "208"
slug: "identifier-foundation"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-25"
---

# Phase 208 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17.3) + StreamData 1.4 (`ExUnitProperties`) |
| **Config file** | `test/test_helper.exs` (excludes only `:pgbouncer_topology`) |
| **Quick run command** | `mix test test/threadline/capture/naming_test.exs test/threadline/capture/naming_property_test.exs test/threadline/mix/ test/threadline/storage_schema_test.exs test/mix/tasks/threadline/` |
| **Full suite command** | `mix verify.test` (phase gate: `mix ci.all`; run `mix dialyzer --plt` first if the PLT missed) |
| **Estimated runtime** | ~30 seconds quick; several minutes full |

---

## Sampling Rate

- **After every task commit:** Run the quick run command
- **After every plan wave:** Run `mix verify.test`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| NAME-01 (message) | TBD | TBD | NAME-01 | V5 input validation | Oversized/invalid identifier raises naming role, value, byte count; never "storage schema" | unit | `mix test test/threadline/storage_schema_test.exs` | ✅ (add cases) | ⬜ pending |
| NAME-01 (task) | TBD | TBD | NAME-01 | DDL injection via `--tables` | `gen.triggers --tables <70-byte>` raises `Mix.Error` with same fragments | Mix task | `mix test test/mix/tasks/threadline/gen_triggers_test.exs` | ✅ (add case) | ⬜ pending |
| NAME-01 (cut) | TBD | TBD | NAME-01 | — | Overflowing trigger name cut to 63; fitting names byte-identical | unit | `mix test test/threadline/capture/naming_test.exs` | ❌ W0 | ⬜ pending |
| NAME-01 (migration) | TBD | TBD | NAME-01 | — | Migration name/module ≤ 63 bytes; ordinal bump; order-insensitive hash | unit | `mix test test/threadline/mix/trigger_migration_test.exs` | ✅ (add cases) | ⬜ pending |
| NAME-05 (golden) | TBD | TBD | NAME-05 | — | D-05 golden literal rows frozen | unit | `mix test test/threadline/capture/naming_test.exs` | ❌ W0 | ⬜ pending |
| NAME-05 (property) | TBD | TBD | NAME-05 | Cross-table function sharing | ≤63, regex, determinism, injectivity under biased generators | property | `mix test test/threadline/capture/naming_property_test.exs` | ❌ W0 | ⬜ pending |
| CONF-02 (resolver) | TBD | TBD | CONF-02 | Writing to unexpected dir | Precedence `--migrations-path` > `--repo` `:priv` > default | unit | `mix test test/threadline/mix/migrations_path_test.exs` | ❌ W0 | ⬜ pending |
| CONF-02 (tasks) | TBD | TBD | CONF-02 | — | Both tasks write/detect reruns in custom priv path | Mix task | `mix test test/mix/tasks/threadline/` | ✅ (add cases) | ⬜ pending |
| REL-01 (config) | TBD | TBD | REL-01 | — | `bump-minor-pre-major == true` | contract | `mix test test/threadline/changelog_contract_test.exs` | ✅/❌ | ⬜ pending |
| REL-01 (ordering) | TBD | TBD | REL-01 | — | Config commit precedes first releasable commit | git check | `git log --reverse --format=%h main..milestone/v1.42 -- release-please-config.json \| head -1` | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/threadline/capture/naming_test.exs` — golden rows and unit edges
- [ ] `test/threadline/capture/naming_property_test.exs` — StreamData properties, `async: true`
- [ ] `test/threadline/mix/migrations_path_test.exs` — precedence with a stub repo module
- [ ] `{:stream_data, "~> 1.4", only: :test}` + `mix deps.get` (commit `mix.lock`)

---

## Manual-Only Verifications

All phase behaviors have automated verification. (REL-01 ordering is a scripted `git log` check recorded in VERIFICATION.md.)

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
