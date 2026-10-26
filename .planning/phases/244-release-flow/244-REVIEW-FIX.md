---
phase: 244-release-flow
fixed_at: 2026-10-25T00:00:00Z
review_path: .planning/phases/244-release-flow/244-REVIEW.md
iteration: 1
review_round: 2
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 244: Code Review Fix Report (round 2)

**Fixed at:** 2026-10-25
**Source review:** .planning/phases/244-release-flow/244-REVIEW.md (round 2)
**Iteration:** 1

Finding IDs carry the `R2-` prefix so they do not collide with round-1 IDs.
Scope was critical + warning. The four R2-IN-* info findings were out of scope
and were not touched.

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### R2-WR-01: REL-04 prose says local and CI run "one Hex version", but `MIN_HEX` is a floor

**Files modified:** `CONTRIBUTING.md`, `bin/verify-deps-audit`, `test/threadline/hex_pin_contract_test.exs`
**Commit:** 1b6dd778
**Applied fix:** Option B (keep the floor, make the prose accurate). The "Why Hex is
pinned in CI" section, the `MIN_HEX` comment and the contract-test moduledoc now say
that CI pins Hex exactly, while the local check only refuses an older Hex and allows
a newer one, which is then not what CI runs. The gate code did not change. No
doc-contract test asserted on the old sentences (checked with grep), so no test
assertion needed to change.

### R2-WR-02: `bin/verify-lock-hygiene` breaks its exit-status contract

**Files modified:** `bin/verify-lock-hygiene`, `test/threadline/deps_audit_gate_test.exs`
**Commit:** e0e14b80
**Applied fix:** `malformed/2` now throws, and `check/1` catches the throw and returns
`{:malformed, path, reason}`. `main/1` checks every lock, prints every violation and
every malformed reason, then exits 2 if any lock was malformed, else 1 if any
violation was found, else 0. `hex_entry/2` refuses a name that is not an atom or
string and a version that is not a string (exit 2), so no AST reaches String.Chars.
The header's exit-status block documents the ordering. New tests: three rows in the
fail-closed table (a non-string version with `[]` managers, a non-string version with
`[:mix]` managers, a non-literal name). Each asserts exit 2 and no `** (` crash trace.
Two multi-lock tests cover a violation followed by a missing lock and a missing lock
followed by a violation. Both assert exit 2 and that the FAIL line is printed. All
five new tests failed before the fix and pass after it.

### R2-WR-03: The nested-fetch contract checked the variable name, not where it points

**Files modified:** `test/threadline/retry_network_contract_test.exs`, `mix.exs` (comment only)
**Commit:** 6912fa96
**Applied fix:** Added `rule=retry-env-target`. It extracts the body of
`defp retry_network_env/1` from comment-stripped `mix.exs` and requires it to be
exactly `[{"RETRY_NETWORK", Path.join(__DIR__, "bin/retry-network")} | env]`. A
missing function also fires the rule. The live test also asserts that the bound path
is the `@script` the behaviour half drives, and that the file exists and is
executable. Mutation controls in the file's `mutate_source` style swap the target for
`"env"`, for `"command"` and for a misspelled path. Each one fires the new rule while
`rule=retry-env-pairing` stays green, which shows the gap this rule closes. Another
control renames the function. Live non-vacuity check: binding `mix.exs` to `"env"`
for a moment turned the live rule red, and `mix.exs` was then restored with
`git checkout`. The `mix.exs` comment now names the new rule.

## Verification

All gates ran in the review-fix checkout on branch milestone/v1.47. No separate
temporary worktree was created, because the dispatcher limited all work to that one
checkout. None of these test files needed Postgres, so no database container was
started.

- `mix test test/threadline/hex_pin_contract_test.exs test/threadline/deps_audit_contract_test.exs test/threadline/deps_health_doc_contract_test.exs test/threadline/deps_audit_gate_test.exs`: 92 tests, 0 failures (after R2-WR-01)
- `mix test test/threadline/deps_audit_gate_test.exs`: 51 tests, 5 failures before the R2-WR-02 fix (the new tests); 51 tests, 0 failures after it
- `mix test test/threadline/retry_network_contract_test.exs`: 78 tests, 0 failures (with the live `mix.exs` mutated for a moment: 4 failures, including the live rule)
- Combined final run over all five files above: 175 tests, 0 failures
- `mix format --check-formatted`: clean after each fix
- `mix verify.credo`: no issues after each fix

---

_Fixed: 2026-10-25_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
