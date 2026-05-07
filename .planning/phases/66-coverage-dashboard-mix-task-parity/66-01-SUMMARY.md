---
phase: 66
plan: 01
subsystem: capture-introspection
tags:
  - elixir
  - threadline
  - health
  - telemetry
  - coverage
  - capture-introspection
requires: []
provides:
  - "Threadline.Health.trigger_coverage/1 :schema opt + three-bucket return shape"
  - "Threadline.Health.Policy.validate!/1 (pure-stdlib config validator)"
  - "Threadline.Telemetry.emit_health_checked/3 (additive expected_uncovered measurement)"
  - "Threadline.Telemetry.emit_health_checked_error/1 ([:threadline, :health, :checked, :error] sibling event)"
  - "Threadline.Verify.CoveragePolicy.violations/2 — additive {:ok, :expected_uncovered} -> [] case clause"
affects:
  - "66-02 coverage dashboard LV (reads three-bucket shape + telemetry events)"
  - "66-03 mix threadline.health.coverage parity Mix task (reads :schema opt + three-bucket shape)"
  - "66-05 doc-contract test (pins @expected_uncovered_baseline literal)"
tech-stack:
  added: []
  patterns:
    - "parameterized $1 binds for pg_* catalog queries (mirrors Continuity.public_table_exists?)"
    - "pg_namespace join for cross-schema isolation (Pitfall 1 fix)"
    - "Application.get_env/3 fall-through for adopter health config"
    - "@expected_uncovered_baseline ~w(schema_migrations) hardcoded module attr (D-32a literal)"
    - "Telemetry sibling :error event (mirrors :authorize :granted/:denied/:error)"
    - "Keyword OR map dual-form intake (mirrors Capture.RedactionPolicy.validate!/1)"
key-files:
  created:
    - "lib/threadline/health/policy.ex"
    - "test/threadline/health/policy_test.exs"
  modified:
    - "lib/threadline/health.ex"
    - "lib/threadline/telemetry.ex"
    - "lib/threadline/verify/coverage_policy.ex"
    - "test/threadline/health_test.exs"
    - "test/threadline/telemetry_test.exs"
    - "test/threadline/verify_coverage_policy_test.exs"
    - "test/threadline/readme_doc_contract_test.exs"
decisions:
  - "Replaced emit_health_checked/2 in place with /3 (single in-tree caller updated in lockstep)"
  - "Auto-fixed README doc-contract test (Rule 1 — directly-caused regression from three-bucket shape change)"
  - "Test path is test/threadline/verify_coverage_policy_test.exs (single file), NOT test/threadline/verify/coverage_policy_test.exs (subdir) per the plan's literal acceptance criterion"
metrics:
  duration: ~22 min
  completed: 2026-05-07T17:35:49Z
  tasks: 4
  files: 9
  tests_added: 13
  full_suite: "433 tests / 0 failures (1 excluded — pgbouncer_topology)"
---

# Phase 66 Plan 01: Coverage Dashboard Lib Foundation Summary

The lib-tier infrastructure for Phase 66's coverage dashboard ships clean: `Threadline.Health.trigger_coverage/1` accepts a `:schema` keyword opt (default `"public"`) with both inner SQL queries parameterized via `$1` binds, the new third-bucket `{:expected_uncovered, name}` variant computed from a hardcoded `~w(schema_migrations)` baseline plus adopter-configurable `expected_uncovered_tables` minus `audit_anyway`, a `pg_namespace` join that closes the cross-schema trigger leak (Pitfall 1) proven by a regression test creating two schemas with the same-named table; new pure-stdlib `Threadline.Health.Policy.validate!/1` mirrors `Capture.RedactionPolicy.validate!/1` shape exactly (keyword OR map dual-form intake, raises `ArgumentError` with key + offending value); telemetry shape additive — `[:threadline, :health, :checked]` measurements gain an `expected_uncovered` integer, sibling event `[:threadline, :health, :checked, :error]` debuts for D-30c poll-failure UX, both proven non-breaking by an old-shape destructure regression test; `Threadline.Verify.CoveragePolicy.violations/2` gains one case clause `{:ok, :expected_uncovered} -> []` so the existing CI gate doesn't flag the new bucket as missing.

## What Shipped

### (a) `:schema` opt is live, parameterized, and namespace-joined

`Threadline.Health.trigger_coverage/1` now accepts `:schema` (default `"public"`). Both inner SQL queries are parameterized:

- `fetch_all_user_tables/2`: `SELECT tablename FROM pg_tables WHERE schemaname = $1` with `[schema]` bind.
- `fetch_threadline_covered_tables/2`: now joins `pg_namespace` and filters `n.nspname = $1` with `[schema]` bind. Without this join, a Threadline trigger named `threadline_audit_users` in `tenant_42.users` would leak into the `public` covered set whenever the `public.users` table also existed (Pitfall 1).

SQL-injection refute holds: `grep -E "nspname = '#|schemaname = '#"` on `lib/threadline/health.ex` returns nothing; the previous `'public'` literal is gone.

### (b) Three-bucket return shape verified across 11 test cases

`trigger_coverage/1` returns `[{:covered | :uncovered | :expected_uncovered, table_name}]`. The truth-on-the-ground rule (`:covered` checked BEFORE `:expected_uncovered` in the cond) prevents a covered table from being mistakenly bucketed as expected if an adopter mis-configures it. Tests cover:

- baseline `{:expected_uncovered, "schema_migrations"}` (D-32a)
- configured `expected_uncovered_tables` flow into bucket (D-32b)
- `audit_anyway` removes baseline entry (D-32c override-to-audit escape hatch)
- `:schema` default `"public"` parity with explicit
- backward-compat: `{:covered, name} in coverage` membership check (Continuity line 71 pattern)
- `@tag :schema_isolation` regression: creates `tenant_iso` schema + same-named table in two schemas, trigger only in `public`; asserts `public` sees `:covered` and `tenant_iso` sees `:uncovered` (Pitfall 1 fix). Per CLAUDE.md "honest default tests," this is NOT excluded from default `mix test` — if the test DB rejects schema creation, it fails loudly.

### (c) Telemetry shape additive — additive measurement + new error sibling event

`Threadline.Telemetry.emit_health_checked/3` (replacing `/2`) emits `[:threadline, :health, :checked]` with `%{covered, uncovered, expected_uncovered}` measurements. An old-shape destructure regression test proves subscribers reading `%{covered: c, uncovered: u}` continue to work (Map destructure is forgiving of extras).

New sibling event `[:threadline, :health, :checked, :error]` emitted by `Threadline.Telemetry.emit_health_checked_error/1` with `%{error: message}` metadata supports D-30c keep-last-good poll UX in Plan 02's LV.

The single in-tree caller (`Threadline.Health.trigger_coverage/1`) updates in lockstep — confirmed by `grep -c "emit_health_checked(covered, uncovered)" lib/threadline/telemetry.ex == 0`.

### (d) `Threadline.Health.Policy` validator ready for adopter config

Pure-stdlib `Threadline.Health.Policy.validate!/1` ships at `lib/threadline/health/policy.ex` with NO file-scope `Code.ensure_loaded?` gate (D-36 — capture-only adopters need this). Mirrors `Threadline.Capture.RedactionPolicy.validate!/1` shape exactly: keyword OR map dual-form intake, raises `ArgumentError` mentioning the key + offending entry on bad input. Eight behaviors covered (10 test cases including dual-form parity):

- empty keyword OR map → `:ok`
- non-binary entry in `:expected_uncovered_tables` → raises mentioning `:expected_uncovered_tables` AND offending atom
- duplicate entry → raises mentioning duplicate
- non-binary entry in `:audit_anyway` → raises mentioning `:audit_anyway` AND offending integer
- unknown top-level key → raises with the key name
- non-keyword/non-map shape (Pitfall 9 regression) → raises with clear "expected a keyword list or map" message

Adopters validate at boot in `application.ex`:

```elixir
Threadline.Health.Policy.validate!(Application.get_env(:threadline, :health, []))
```

### (e) `Verify.CoveragePolicy` extended with one case clause

`Threadline.Verify.CoveragePolicy.violations/2` gains `{:ok, :expected_uncovered} -> []` (D-32f). For tables in `:expected_tables`, the existing semantics are unchanged — `:missing`/`:uncovered`/`:covered` paths are untouched. The new clause only matters when an adopter's expected table happens to land in the `:expected_uncovered` bucket; treating it as covered-equivalent prevents false positives for the CI gate.

### (f) Backward-compat callsites verified

- `lib/threadline/continuity.ex:71` — `if {:covered, table_name} in coverage do`: regression-tested directly via `assert {:covered, "threadline_ci_coverage_canary"} in coverage` in the new health test suite.
- `TimelineLive` datalist line 30 — pattern matches against `{:covered, name}`; behavior unchanged because the datalist filters by `&match?({:covered, _}, &1)` which is still satisfied.
- README doc-contract test had to widen its allowed-tag list (Rule 1 fix, see Deviations).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] README doc-contract test asserted old two-bucket shape**
- **Found during:** Full-suite verification after Task 4
- **Issue:** `test/threadline/readme_doc_contract_test.exs:111` asserted `Enum.all?(cov, &match?({tag, _} when tag in [:covered, :uncovered], &1))` — once `schema_migrations` rolled into the new `:expected_uncovered` bucket, this test failed.
- **Fix:** Widened the allowed-tag list to `[:covered, :uncovered, :expected_uncovered]` (additive — old tags still pass).
- **Files modified:** `test/threadline/readme_doc_contract_test.exs`
- **Commit:** `f2fa942`
- **Rationale:** Direct regression caused by Task 3's three-bucket shape change. The README's public-API contract has not changed (the function still returns `{tag, table}` tuples, just with three tags instead of two). Auto-fix per Rule 1 — fixing in lockstep with the breaking change is correct.

### Plan-acceptance-criteria path mismatch (informational)

The plan's Task 4 acceptance criteria reference `test/threadline/verify/coverage_policy_test.exs` (with a `verify/` subdirectory). The actual file in this repo lives at `test/threadline/verify_coverage_policy_test.exs` (no subdir). The new test for the additive case clause was added to the canonical existing path. All other acceptance criteria (grep counts on `:expected_uncovered`, regression of pre-existing tests) were verified against the actual file path. No file moved.

### Telemetry placeholder during Task 2 → Task 3 transition (informational)

Per the plan's Task 2 action notes ("RESEARCH §`emit_health_checked/2` confirms exactly ONE in-tree caller, which Plan 01 Task 3 updates in lockstep, so direct replacement is cleanest"), the Telemetry GREEN commit had to keep compilation green between Task 2 and Task 3 commits. Solution: the `lib/threadline/health.ex` call site temporarily passed `0` for the third arg, which Task 3's full rewrite immediately replaced with the computed `expected_uncovered_count`. No tests observed the placeholder (the HLTH-05 telemetry test asserts `is_integer(expected_uncovered)` after Task 3 ships the real value).

## Tasks → Commits

| Task | Description | Commit(s) |
| ---- | ----------- | --------- |
| 1 (RED+GREEN) | `Threadline.Health.Policy` validator | `34dc7b7` test, `f6d44ee` feat |
| 2 (RED+GREEN) | Telemetry `/3` arity + `:error` sibling event | `55f66fe` test, `a602e8d` feat |
| 3 (RED+GREEN) | `trigger_coverage/1` :schema + 3-bucket + namespace join | `85653f0` test, `3aad968` feat |
| 4 | `CoveragePolicy.violations/2` additive clause | `cdc854d` feat (test + impl combined) |
| Rule 1 fix | README doc-contract test widening | `f2fa942` fix |

## Plan-Level Verification Results

| Check | Status |
| ----- | ------ |
| `mix test test/threadline/health/policy_test.exs test/threadline/telemetry_test.exs test/threadline/health_test.exs test/threadline/verify_coverage_policy_test.exs --trace` | 35 tests / 0 failures |
| `mix verify.format` | clean |
| `mix verify.compile_no_optional` | clean (none of this plan's files require Phoenix) |
| Full `mix test` (no regressions) | 433 tests / 0 failures (1 excluded — `pgbouncer_topology`) |
| SQL-injection refute (`grep -E "nspname = '#\|schemaname = '#" lib/threadline/health.ex`) | empty |
| `'public'` literal removed (`grep -F "schemaname = 'public'" lib/threadline/health.ex`) | empty |

## TDD Gate Compliance

Tasks 1, 2, and 3 all observed RED → GREEN order — RED commits each fail with a clear "function undefined" or behavior-mismatch error before the GREEN feat commit ships. Task 4 was a 4-line additive case clause + one test; per the plan's `<task type="auto">` (no `tdd="true"` flag), this was committed as one combined feat without a separate RED gate, but the test was authored alongside the impl and runs green via `mix test test/threadline/verify_coverage_policy_test.exs`.

## Self-Check: PASSED

**Files created:**
- FOUND: lib/threadline/health/policy.ex
- FOUND: test/threadline/health/policy_test.exs

**Files modified:**
- FOUND modifications in lib/threadline/health.ex (HEAD vs main: rewrote trigger_coverage/1 + 2 helpers + new helper + module attr + moduledoc)
- FOUND modifications in lib/threadline/telemetry.ex (replaced /2 with /3, new emit_health_checked_error/1, expanded @moduledoc)
- FOUND modifications in lib/threadline/verify/coverage_policy.ex (added one case clause)
- FOUND modifications in test/threadline/health_test.exs (added 6 new tests, 11 total)
- FOUND modifications in test/threadline/telemetry_test.exs (added 3 new tests, 7 total)
- FOUND modifications in test/threadline/verify_coverage_policy_test.exs (added 1 new test, 7 total)
- FOUND modifications in test/threadline/readme_doc_contract_test.exs (Rule 1 fix — widened tag allowlist)

**Commits:**
- FOUND: 34dc7b7 (test Task 1)
- FOUND: f6d44ee (feat Task 1)
- FOUND: 55f66fe (test Task 2)
- FOUND: a602e8d (feat Task 2)
- FOUND: 85653f0 (test Task 3)
- FOUND: 3aad968 (feat Task 3)
- FOUND: cdc854d (feat Task 4)
- FOUND: f2fa942 (Rule 1 fix)
