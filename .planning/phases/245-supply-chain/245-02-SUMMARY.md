---
phase: 245-supply-chain
plan: 02
subsystem: ci
tags: [hex-audit, sarif, deps-tree, supply-chain, bash, jq]
status: complete

requires:
  - phase: 245-01
    provides: bin/deps-audit-tier SARIF library (dat_audit, dat_findings, dat_audit_shape_error, dat_cleanup)
provides:
  - "bin/deps-audit-tier: dat_role, dat_closure (DAT_TREE_OUTPUT, DAT_TREE_STATUS), dat_tier, dat_reason, dat_machine_line; dat_new_sarif_path now sets DAT_SARIF_PATH"
  - "bin/verify-deps-audit: tiered gate, cleanup_all single EXIT trap, D-19 FAIL labels, step-summary table, hygiene reason by exit status, self-test case (e)"
  - "bin/deps-health-report: Blocking — shipped runtime / Non-blocking — dev/test/bench/example sections"
  - "CONTRIBUTING tier policy (D-16 policy change stated) with doc-contract assertions"
affects: [245-03, 245-04, 245-05]

actuals:
  tokens: 16400
  tasks: 3
  commits: 4
plan_head_before: cc8e7bd5ad2d5f8f25552ba9b7228fb0289c6b21
plan_head_after: ad10eb4777d447ecf87d62f5a8566d4a123e54fa

tech-stack:
  added: []
  patterns:
    - "Directory role decided only from the resolved path (pwd -P), no env/flag seam"
    - "Copied-bin temp root in tests so literal `bench` / `examples/threadline_phoenix` args resolve under a temp ROOT (PATTERNS hazard 4)"
    - "Library functions that register temp state set a global instead of printing, so callers never invoke them in a command-substitution subshell"

key-files:
  created: []
  modified:
    - bin/deps-audit-tier
    - bin/verify-deps-audit
    - bin/deps-health-report
    - test/threadline/deps_audit_gate_test.exs
    - test/threadline/deps_health_report_test.exs
    - test/threadline/deps_health_doc_contract_test.exs
    - test/fixtures/deps_audit/vulnerable_lock/README.md
    - CONTRIBUTING.md

decisions:
  - "PATTERNS hazard 4: cases 5/6 copy verify-deps-audit, deps-audit-tier, retry-network and verify-lock-hygiene into <tmp_root>/bin/ and run the copy with literal relative args; no production role seam was added"
  - "D-16 policy change is stated verbatim in CONTRIBUTING: root dev/test-only advisories no longer block a pull request or a release"
  - "A failing deps.tree or empty closure in the gate skips that directory's audit (FAIL line, no untrusted audit); in deps-health it makes the dir unknown and lists findings untiered"
  - "Gate D-19 FAIL lines map the library's shape-error text to the plan's distinct labels and keep the library detail in parentheses, so deps-health keeps its existing wording"

metrics:
  duration: 18min
  completed: 2026-10-25
---

# Phase 245 Plan 02: Tiered dependency-audit gate Summary

`verify-deps-audit` now blocks only on findings in the shipped runtime closure, through the same tier library that tags the deps-health issue. A finding blocks if and only if its directory uses the closure rule and its package is in that directory's `mix deps.tree --only prod --format plain` closure, read only after a successful `--check-locked` fetch. Every bench and example finding is non-blocking. Each finding prints one `deps-audit-finding tier=... dir=... kind=... package=... id=...` line, an `::error::` or `::warning::` annotation, and a step-summary row.

## What shipped

- **Task 1 (tracer, c173c9bf).**
  - `bin/deps-audit-tier` gains `dat_role`, `dat_closure`, `dat_tier`, `dat_reason` and `dat_machine_line`.
  - `bin/verify-deps-audit` sources the library and runs, per directory: hygiene, then fetch, then unlock, then (closure-rule dirs only) deps.tree, then `hex.audit --format sarif --output <fresh path>`.
  - One `cleanup_all` EXIT trap replaces the self-test trap and the `refuse_global_hex_ignores` trap.
  - The fake mix answers `deps.tree` (`FAKE_TREE_<base>`) and SARIF `hex.audit` (`FAKE_SARIF_<base>`, spec `kind:package:id;...`).
  - The D-19 FAIL labels and the step-summary table also landed in this commit.
  - Tracer gate: `<verify>` re-run green, then expansion.
- **Task 2 (RED 4db7b364, GREEN 948b5b15).**
  - The tests cover:
    - D-23 cases 1-11, plus a copied-root `.` control proving that copied roots still block;
    - every D-19 FAIL line, including OTP below 27;
    - deps.tree running only after the fetch;
    - one machine line per finding and the step-summary rows;
    - the hygiene exit 1 and exit 2 reasons;
    - the live `--only prod` closure contract.
  - The hygiene FAIL text now branches on the exit status.
  - Self-test (a) asserts the `tier=blocking` machine line. New case (e) proves the downgrade on real Hex.
  - The header and the fixture README are updated.
  - `dat_audit_shape_error` already recognised `:json module is not available` (from 245-01), so it needed no change.
- **Task 3 (ad10eb47).**
  - `bin/deps-health-report` tiers each finding and writes the two sections (`- none` when empty). A deps.tree failure or an empty closure makes that directory unknown, and its findings stay untiered.
  - Eight new report tests (case 12).
  - CONTRIBUTING covers the SARIF gate, the per-directory tier rule, the D-16 policy-change sentence, D-17, D-20 and D-21, and the issue sections, with doc-contract assertions.

Unchanged: the ci.yml `verify-deps-audit` job (no `issues: write`), the example app's cloak `hex_audit_ignores` entries, `CANONICAL_DIRS` and `MIN_HEX`.

## Verification

- `bin/verify-deps-audit --self-test` (real Hex) printed: `verify-deps-audit self-test: ok (vulnerable lock red, old Hex red, global Hex ignore red, lock drift red, test-only advisory non-blocking)`
- `mix verify.deps_audit` on the real tree printed: `verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0; 0 non-blocking finding(s))`
- Task 2 set (gate, deps_audit_contract, hex_pin_contract, ci_token_permissions): 129 tests, 0 failures.
- Task 3 set (deps_health_report, deps_health_doc_contract, deps_audit_gate): 156 tests, 0 failures.
- Full default `mix test`: 32 properties, 3353 tests, 0 failures, 3 excluded.
- The following all pass:
  - `mix format --check-formatted`
  - `mix verify.credo` (no issues)
  - `bash -n` on all three scripts
  - `bin/verify-repo-hygiene` (exit 0)
  - every acceptance grep
- shellcheck reports only info/warning notes, of the kinds already present in these scripts (SC1007, SC2015, SC2016, SC2329, SC1091).
- No `tmp/deps-audit-sarif.*` dirs are left after the suite runs.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `dat_new_sarif_path` leaked every SARIF temp dir**
- **Found during:** Task 1 (the call-order test asserts that each SARIF dir is removed).
- **Issue:** both consumers called it as `sarif_path="$(dat_new_sarif_path)"`. A command substitution is a subshell, so the `DAT_TMP_DIRS+=` registration was lost and `dat_cleanup` removed nothing. 565 leaked `<repo>/tmp/deps-audit-sarif.*` dirs had built up from the 245-01 deps-health tests.
- **Fix:** the function now sets `DAT_SARIF_PATH` and is called directly, in bin/deps-health-report as well. The leaked gitignored dirs were removed.
- **Files modified:** bin/deps-audit-tier, bin/deps-health-report, bin/verify-deps-audit
- **Commit:** c173c9bf

**2. Ordering: the single trap, D-19 labels and step summary landed in Task 1, not Task 2.** `dat_cleanup` has to run from the trap as soon as the gate creates SARIF dirs, and the labels were written along with the audit block. Task 2's tests pin them.

**3. Test-fake details (within the plan's intent)**
- The fake `deps.tree` defaults to `telemetry`, so the existing clean-path tests keep a non-empty closure. `__EMPTY__` gives an empty closure.
- The fake `hex.audit` has `__NOFILE__`, `__NOJSON__` and `__MALFORMED__` sentinels, `raw:<fingerprint>` specs and a `FAKE_AUDIT_EXIT_<base>` override.
- The fake mix script now uses `~S"""`.
- The hygiene reason tests use the real `bin/verify-lock-hygiene` on a real lock text (exit 1 for an empty manager list, exit 2 for an unparseable lock), not a fake script.
- The deps-health tests use `vulnerable_lock.json` for bench (plug and plug_crypto) instead of a new benchee fixture. This pins the per-directory rule with a package name that is also in the runtime closure.
- The existing canonical-dirs test now groups calls by `deps.get --check-locked`, because only the root runs deps.tree.

No partition-weight change: no test file was added.

## Known Stubs

None.

## Deferred Issues

None.

## Self-Check: PASSED

- All 8 modified files exist.
- Commits c173c9bf, 4db7b364, 948b5b15 and ad10eb47 are ancestors of HEAD.
