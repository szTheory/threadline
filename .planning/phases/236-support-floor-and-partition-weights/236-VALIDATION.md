---
phase: "236"
slug: "support-floor-and-partition-weights"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-07"
---

# Phase 236 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Mix/Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` |
| **Full suite command** | `mix ci.all` against PostgreSQL 15 |
| **Estimated runtime** | ~15 minutes (observed full gate: about 12 minutes) |

---

## Sampling Rate

- **After every task commit:** Run every automated command mapped to that task below; use the focused topology and guide contracts for additional quick feedback
- **After every plan wave:** Run `mix ci.all` against PostgreSQL 15 when the wave changes the support floor or shared test behavior; otherwise run the quick command in Test Infrastructure
- **Before `$gsd-verify-work`:** Full suite must be green against PostgreSQL 15
- **Max feedback latency:** 60 seconds for focused contract tests

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Pass / failure signal | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-----------------------|-------------|--------|
| 236-01-01 | 01 | 1 | FLOOR-01, FLOOR-02 | T-236-01, T-236-02 | Min-lane PostgreSQL is exactly 15 and the source-derived support table detects drift | topology + doc contracts | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | Exit 0 passes; nonzero detects min-lane drift, ineffective mutation controls, or a guide/source mismatch | ✅ topology existing; guide contract created in task | ✅ pass (27 tests) |
| 236-01-01 | 01 | 1 | FLOOR-01, FLOOR-02 | T-236-01, T-236-02 | Changed ExUnit contracts and mix.exs follow the formatter contract | format | `mix verify.format` | Exit 0 passes; nonzero reports unformatted changed files | ✅ existing alias | ✅ pass (also passed in `mix ci.all`) |
| 236-01-02 | 01 | 1 | FLOOR-01 | T-236-02 | README and Unreleased breaking entry agree with the guide and state the adopter action | doc contract + mutation control | `mix verify.test test/threadline/guides/upgrade_path_contract_test.exs` | Exit 0 passes; nonzero detects an absent or stale floor, guide link, upgrade action, or ineffective mutation control | ✅ created by 236-01-01 | ✅ pass (2 tests) |
| 236-02-01 | 02 | 2 | CI-01 | T-236-03 | Removing one measured test path makes the completeness contract fail; regenerated weights cover the final inventory | contract + mutation control | `DB_HOST=127.0.0.1 DB_PORT=55433 mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | Exit 0 passes; nonzero detects missing, malformed, or duplicate weights, or an ineffective omission control | ✅ existing topology contract; extended | ✅ pass (27 tests; omission control names the missing path) |
| 236-02-01 | 02 | 2 | CI-01 | T-236-03, T-236-04 | Every discovered test runs exactly once through the partition runner on PostgreSQL 15 | partitioned integration | `DB_HOST=127.0.0.1 DB_PORT=55433 mix verify.test_partitioned` | Exit 0 passes; nonzero detects a skipped or duplicate test, swallowed partition failure, or failing partitioned test | ✅ existing alias and runner | ✅ pass (265 files; 3,051 tests) |
| 236-02-02 | 02 | 2 | FLOOR-01, FLOOR-02, CI-01 | T-236-04 | The complete verification chain passes against a recorded PostgreSQL 15 server | integration | `TMPDIR=<fresh temp dir> DB_HOST=127.0.0.1 DB_PORT=55433 npm_config_cache=<private temp cache> mix ci.all` | Exit 0 passes after the server-version precheck; nonzero detects a failed root, example, compile, Dialyzer, or browser gate | ✅ existing tooling | ✅ pass (exit 0) |

*Task IDs and waves match 236-01-PLAN.md and 236-02-PLAN.md. Each runnable PLAN `<automated>` check has its own row; the PostgreSQL 15 server-version precheck in 236-02-02 remains a required acceptance condition.*

## Recorded Evidence (2026-10-07)

- `PGPASSWORD=postgres psql -h 127.0.0.1 -p 55433 -U postgres -d threadline_test -Atqc 'SHOW server_version_num'` returned `150018` (PostgreSQL 15.18).
- `DB_HOST=127.0.0.1 DB_PORT=55433 bin/ci-test-partitions --write-weights` completed its traced root run with 3,051 tests and 0 failures, writing 264 paths. The standard run excludes `pgbouncer_topology_test.exs`; `MIX_ENV=test THREADLINE_PGBOUNCER_TOPOLOGY=1 DB_HOST=127.0.0.1 DB_PORT=55434 mix test --slowest-modules 1000 test/threadline/pgbouncer_topology_test.exs` passed both tests through transaction-pooling PgBouncer on the same PostgreSQL 15 server, with a measured 113.5 ms module time recorded as 114 ms. The final sorted file contains exactly 265 paths.
- The focused topology and guide contracts passed together (27 tests, 0 failures). The 49-test CI workflow parity contract also passed after its stale PostgreSQL 14 minimum assertion was corrected. The guide contract passed independently after its Credo warnings were removed.
- `DB_HOST=127.0.0.1 DB_PORT=55433 npm_config_cache=<private temp cache> mix verify.test_partitioned` passed: 265 files assigned once across four partitions; 3,051 tests, 0 failures. Partition counts were 841, 877, 829, and 504.
- The final `mix ci.all` ran with PostgreSQL 15.18 and a fresh `TMPDIR` to avoid a pre-existing shared-temp directory collision. It exited 0: root 3,051 tests + 32 properties (0 failures, 3 excluded); example 132 tests (0 failures); Dialyzer passed and its slice suite had 17 tests (0 failures, 16 excluded); browser 316 passed, 26 skipped. Two browser cases were reported flaky after passing on retry.
- Port 55433 was used because an unrelated PostgreSQL 16 container already owned port 55432. The runner implementation, median fallback, and exactly-once assignment check were left unchanged.

---

## Wave 0 Requirements

- [x] `test/threadline/guides/upgrade_path_contract_test.exs` — created test-first by 236-01-01, before support-table edits
- [x] `test/threadline/ci_topology_contract_test.exs` — topology control created by 236-01-01; weight-completeness control added by 236-02-01 before regeneration
- [x] Existing ExUnit and PostgreSQL fixtures cover all phase requirements; no framework installation is required

---

## Manual-Only Verifications

All phase behaviors have automated verification. The PostgreSQL 15 full-suite run is an integration gate, not a manual-only check.

---

## Validation Sign-Off

- [x] All four tasks and all six PLAN `<automated>` checks have task-map coverage or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 60s for focused contract tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** Automated validation complete; no manual-only checks are required.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
