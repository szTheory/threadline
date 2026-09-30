---
phase: 215-supply-chain-gate
reviewed: 2026-09-26T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - CONTRIBUTING.md
  - bin/deps-health-report
  - bin/verify-deps-audit
  - test/threadline/deps_audit_contract_test.exs
  - test/threadline/deps_audit_gate_test.exs
  - test/threadline/deps_health_report_test.exs
  - test/threadline/ignore_advisories_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 215: Code Review Report (incremental — gap closure)

**Reviewed:** 2026-09-26
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found (no blockers; 2 warnings, 2 info)

**This report supersedes the earlier `215-REVIEW.md` for the gap-closure delta.**
The original full review (findings CR-01, WR-01..WR-08, IN-01..IN-04) is preserved
in git history at commit `04242721` (`git show 04242721:.planning/phases/215-supply-chain-gate/215-REVIEW.md`).
This incremental review covers plans 215-05/215-06, which closed CR-01 (global
Hex `ignore_advisories`/`ignore_retirements` bypass) and WR-02 (silent
re-resolution of a drifted `mix.lock`). WR-01, WR-03..WR-08, IN-01..IN-04 are
already tracked in `.planning/phases/215-supply-chain-gate/deferred-items.md`
and are not re-reported here except where noted below.

## Summary

Both targeted gaps are genuinely closed, and closed with unusually strong
proof:

- **CR-01 (global Hex ignore bypass):** `bin/verify-deps-audit` now runs
  `refuse_global_hex_ignores` right after the Hex-version floor check and
  before any per-directory audit. It queries `mix hex.config
  ignore_advisories|ignore_retirements` from a freshly `mktemp -d`'d,
  `mix.exs`-free directory under the repo's gitignored `tmp/` (so a
  project's own accountable `hex: [ignore_advisories: ...]` entry is never
  conflated with a global one), fails closed on a non-zero exit, empty
  output, or output not starting with `[`, and refuses on any non-`[]`
  value. I independently reran `bin/verify-deps-audit --self-test` against
  real Hex (not the offline fake-`mix` tests) and it printed `... global Hex
  ignore red ...` and exited 0 — case (c) (a real `HEX_HOME`-redirected
  `mix hex.config ignore_advisories`) is genuinely refused, not just refused
  in a mocked test.
- **WR-02 (silent re-resolution of a drifted lock):** both
  `bin/verify-deps-audit` and `bin/deps-health-report` now fetch with `mix
  deps.get --check-locked` instead of plain `deps.get`. I independently
  reproduced a drifted lock outside the test suite (changed a dep
  constraint so the locked version no longer satisfies it) and confirmed
  `--check-locked` exits 1 and leaves `mix.lock` byte-for-byte unchanged,
  matching the script's own self-test case (d), which I also reran
  successfully against real Hex.
- I checked out the pre-fix (`04242721`) versions of both scripts in place,
  keeping the new tests, and confirmed **21 of the 50 new/changed tests in
  `deps_audit_gate_test.exs` and `deps_health_report_test.exs` fail** against
  the old code — the tests have real teeth, not vacuous assertions. Restoring
  the fixed scripts brings the suite back to 0 failures. `mix test` on all
  four required-reading test files: 71 tests, 0 failures.
- `deps_audit_contract_test.exs`'s `forbidden_hex_surface/1` scan (blocking
  `HEX_IGNORE_ADVISORIES`, `HEX_IGNORE_RETIREMENTS`, `HEX_HOME`, `MIX_HOME`,
  and `hex.config ignore_` in any workflow file) is proven non-vacuous on a
  synthetic positive and I confirmed a live `grep` over
  `.github/workflows/*.yml` matches zero hits, consistent with the test.

No BLOCKER-level defect was found in the gap-closure delta itself. Two
WARNINGs and two INFO items below are new observations from this review pass
(not previously tracked), all quality/robustness rather than exploitable
bypasses.

## Warnings

### WR-215-09: `bin/deps-health-report`'s CR-01 mirror has no live proof against real Hex

**File:** `bin/deps-health-report:124-209`
**Issue:** `bin/verify-deps-audit` proves its `refuse_global_hex_ignores`
logic against **real** Hex via `--self-test` case (c) (a genuine
`HEX_HOME`-redirected `mix hex.config ignore_advisories`, run as a CI step).
`bin/deps-health-report`'s `check_hex_suppression`/`read_global_hex_ignore`
is a near-verbatim copy of that same logic, but it is exercised only through
`deps_health_report_test.exs`'s fake `MIX_BIN` — never against a real `mix
hex.config` call. The two functions are believed identical today (a test
asserts the literal string `ignore_advisories ignore_retirements` appears in
both files), but nothing catches the two implementations silently diverging
in behavior against real Hex's actual output format (e.g. a future Hex
version changing how it wraps long lists, or prefixes output) — the weekly
lane could regress to reporting `clean` under an active global suppression
without any test failing, since the only thing anchoring correctness against
real Hex lives in the *other* script's self-test.
**Fix:** Either (a) extract `read_global_hex_ignore` +
`refuse_global_hex_ignores`/`check_hex_suppression` into one shared sourced
file both scripts `source`, so there is only one implementation to prove
against real Hex, or (b) add a `bin/deps-health-report --self-test` mode
(mirroring case (c)/(d) of `bin/verify-deps-audit --self-test`) so the
report script's suppression detection is proven against real Hex too, not
only against a hand-written fake.

### WR-215-10: duplicated ~45-line `read_global_hex_ignore` implementation invites drift

**File:** `bin/verify-deps-audit:257-283`, `bin/deps-health-report:137-163`
**Issue:** The two files carry byte-for-byte identical (modulo variable
naming) implementations of the Hex-config-reading/parsing logic (ANSI
stripping, blank-line filtering, multi-line-value joining, `[`-prefix
detection). This is exactly the kind of security-relevant parsing logic
where a future edit to one copy (e.g. tightening the `[`-prefix check, or
handling a new Hex output quirk) is easy to make in one file and forget in
the other, silently reopening the gap in whichever script is missed. The
existing contract test (`deps_health_report_test.exs`: "the suppression key
literal is present in both...") only checks for a substring match, not that
the logic is the same — it would not catch a semantic divergence.
**Fix:** Factor the shared function(s) into a small sourced library (e.g.
`bin/lib/hex-config-refusal.sh`) that both `bin/verify-deps-audit` and
`bin/deps-health-report` source, and update the contract test to assert
both scripts source the same file rather than asserting a literal
substring.

## Info

### IN-215-05: a wrapped Hex line starting with `[` before the real value could cause a false-positive refusal

**File:** `bin/verify-deps-audit:270-274`, `bin/deps-health-report:150-154`
**Issue:** `read_global_hex_ignore` finds "the first non-blank line that
starts with `[`" and treats everything from there onward as the value,
explicitly to tolerate a warning line preceding the real `[...]` list. If a
future/alternate Hex client ever emits a bracket-led warning or notice line
(e.g. `[warning] ...`) ahead of the real answer, that line — not the actual
list — would be captured as "the value," and since it won't equal `[]`, the
gate would refuse with a message like `global Hex config sets
ignore_advisories to [warning] ...`, i.e. a false-positive hard failure on a
clean config. This fails in the *safe* direction (blocks a green run rather
than permitting a bypass), so it is not a BLOCKER, but it is untested against
that specific shape and would present as a confusing, unrelated-looking CI
outage if it ever happened.
**Fix:** Anchor the value-start detection to a line that looks like `[]` or
`["`/`[{`-prefixed (a real Elixir list-of-strings/maps opener) rather than
any line starting with `[`, or add an explicit test fixture for a
bracket-led warning line to lock in the current (safe but surprising)
behavior.

### IN-215-06: self-test case (d)'s "drift" is produced via constraint-string substitution, not a genuine independent resolution

**File:** `bin/verify-deps-audit:174-185`
**Issue:** Minor, non-blocking observation. Case (d) drifts the fixture by
string-replacing `== 1.19.1` with `~> 1.19.2` inside `mix.exs`, which happens
to work because the fixture's dependency line is exactly `{:plug, "==
1.19.1"}`. This is fragile against a future edit to the fixture's `mix.exs`
formatting (e.g. added whitespace, reordered deps, a version bump) silently
turning the substitution into a no-op — `orig_mix_exs == drifted_mix_exs`,
which would make case (d) trivially pass by "drifting" nothing at all
(`deps.get --check-locked` would then legitimately succeed, and the
`die "lock drift was not refused"` branch would fire because
`drift_status` would be 0, not because the intended scenario failed to
materialize the way its name implies). I confirmed today's fixture does
trigger a real drift (reran `--self-test` successfully), so this is not
live, only a maintainability trap.
**Fix:** Add a guard immediately after the substitution — e.g. `[
"$drifted_mix_exs" != "$orig_mix_exs" ] || die "self-test setup: drift
substitution was a no-op — fixture mix.exs no longer contains '== 1.19.1'"`
— so a future fixture edit that silently defeats the substitution fails
loudly instead of passing case (d) vacuously.

## Verification performed (beyond static reading)

- Reran `bin/verify-deps-audit --self-test` against real Hex/Mix: passed,
  printing all four case confirmations.
- Reproduced a genuine `mix.lock`/`mix.exs` drift outside the fixture
  (separate scratch project) and confirmed `deps.get --check-locked` exits 1
  while `mix.lock` is left untouched, matching WR-02's claimed fix.
- Confirmed `mix hex.config ignore_advisories` from a fresh, `mix.exs`-free
  directory with a throwaway `HEX_HOME` prints `[]` with exit 0 by default,
  matching both scripts' "clean" baseline assumption.
- Confirmed `${value#[}` (used to test "does value start with `[`") behaves
  as a literal-character prefix strip in bash, not a bracket-expression glob
  — no bug there.
- Checked out the pre-fix (`04242721`) `bin/verify-deps-audit` and
  `bin/deps-health-report` in place (working tree only, restored
  afterwards; `test/*` left at HEAD) and reran
  `deps_audit_gate_test.exs` + `deps_health_report_test.exs`: 21 of 50 tests
  failed, confirming the new assertions actually exercise the fix rather
  than being tautological. Restored the fixed scripts; suite is back to 0
  failures, verified with a second full run of all four required-reading
  test files (71 tests, 0 failures).
- Confirmed no `.github/workflows/*.yml` file references
  `HEX_IGNORE_ADVISORIES`, `HEX_IGNORE_RETIREMENTS`, `HEX_HOME`, `MIX_HOME`,
  or `hex.config ignore_`, matching `deps_audit_contract_test.exs`'s claim.
- Confirmed `mix.exs`'s `verify.deps_audit` alias still shells to
  `bin/verify-deps-audit` with no arguments, and `ci.yml`'s
  `verify-deps-audit` job runs both `mix verify.deps_audit` and
  `bin/verify-deps-audit --self-test` with no `if:`/`continue-on-error:`/
  `services:` and is present in `ci-required`'s `needs:`.

## Findings carried over (status check only, not re-reported)

Per the task instructions, the following prior findings are already tracked
in `deferred-items.md` and were not re-investigated in depth, but are noted
here for completeness:

- CR-01 and WR-02 — **now resolved** by 215-05/215-06 (see Summary above).
- WR-03 (missing-`mix.lock` reported `clean`) — deferred-items.md marks this
  `status: mitigated` by the same WR-02 `--check-locked` fix (a missing lock
  now fails closed via the same code path as a drifted one).
- WR-01, WR-04..WR-08, IN-01..IN-04, and the "Runtime MIX_EXS / MIX_HOME
  redirection" item — unchanged by this gap-closure delta; still open per
  `deferred-items.md`.

---

_Reviewed: 2026-09-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
