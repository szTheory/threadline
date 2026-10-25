---
phase: 245-supply-chain
fixed_at: 2026-10-25T00:00:00Z
review_path: .planning/phases/245-supply-chain/245-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 245: Code Review Fix Report

**Fixed at:** 2026-10-25
**Source review:** .planning/phases/245-supply-chain/245-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (WR-01..WR-03; Info findings IN-01..IN-07 out of scope)
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: A renamed Hex dependency (`hex:` option) is mis-tiered as non-blocking (latent fail-open)

**Files modified:** `bin/deps-audit-tier`, `test/threadline/deps_audit_gate_test.exs`
**Commit:** 7ef15d30
**Applied fix:** After `dat_closure` has built the app-name closure and passed the empty check, it reads `<dir>/mix.lock` in one `sed` pass. For every `"app": {:hex, :pkg, ...}` entry where `pkg != app` and the app is in the closure, it adds `pkg` to the closure file. This only adds names, so the empty-closure check is unchanged. The header comment now says the file holds app names plus renamed package names. New gate test "case 3b": the fake tree lists `foo`, the lock maps `foo` to `:foo_bar`, and a SARIF advisory for `foo_bar` must exit 1 with `tier=blocking`. Against the old code it failed (`tier=non-blocking`, exit 0).
**Status:** fixed: requires human verification (tiering logic change)

### WR-02: The live-tree closure contract re-implements the parser

**Files modified:** `test/threadline/deps_audit_gate_test.exs`
**Commit:** 216f3a23
**Applied fix:** The D-23 live test now runs `bash -c` that sources `bin/deps-audit-tier`, calls the real `dat_closure` on the repo root, and asserts on the closure file it writes. The Elixir re-parse is gone. The test also asserts that the transitive-only deps `db_connection` and `decimal` are present; real `deps.tree` prints both only on nested `|   |-- ` lines. The fake `deps.tree` now prints the first name as a top-level `|-- ` line and every later name as a nested child (`|   |-- `, with the last one `` |   `-- ``). So cases 1-3 (for example, case 2's transitive `plug_crypto`) now go through nested parsing. Mutation check: dropping the space from the bash glyph class made 31 tests fail, including cases 1-3 and the live test.

### WR-03: The D-29 doc contract only checks a subset

**Files modified:** `test/threadline/deps_health_doc_contract_test.exs`
**Commit:** 03dc8320
**Applied fix:** The test parses the CONTRIBUTING "highest wins ...: `advisory` > ... > `clean`" precedence sentence. It asserts that the classes listed there equal `RANK_NAMES` in reverse (highest first). That is set equality plus the D-25 order. The test also refutes `` `outdated` `` in the policy section. Mutation check: inserting `` > `stale` `` into the CONTRIBUTING chain fails the new test. The old test passed that change.

## Verification

All checks ran in the `quality-baseline` git worktree (branch `milestone/v1.47`, with its own `deps/` and `_build/`), and they are reproducible from that tree. No nested review-fix worktree was created: the caller had already isolated this run in that worktree, and a fresh worktree would have had no dependencies for the gates.

- `mix test test/threadline/deps_audit_gate_test.exs`: 80 tests, 0 failures
- `mix test test/threadline/deps_health_report_test.exs`: green (run with the gate file after WR-01; 140 tests, 0 failures combined)
- `mix test test/threadline/deps_health_doc_contract_test.exs`: 25 tests, 0 failures
- `bash -n bin/deps-audit-tier`: OK. `shellcheck` reports only the pre-existing SC2034 notes for the library's exported globals.
- `mix verify.format`: exit 0
- `mix verify.credo`: no issues

None of these tests need Postgres.

---

_Fixed: 2026-10-25_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
