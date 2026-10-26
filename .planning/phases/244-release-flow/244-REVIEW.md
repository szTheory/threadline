---
phase: 244-release-flow
reviewed: 2026-10-25T16:35:55Z
depth: standard
round: 2
prior_round: ffbaf4c4
files_reviewed: 9
files_reviewed_list:
  - bin/verify-lock-hygiene
  - bin/verify-deps-audit
  - bin/retry-network
  - mix.exs
  - test/threadline/deps_audit_gate_test.exs
  - test/threadline/retry_network_contract_test.exs
  - test/threadline/hex_pin_contract_test.exs
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 244: Code Review Report (round 2)

**Reviewed:** 2026-10-25T16:35:55Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

This round covers the diff `ffbaf4c4..HEAD` (plans 244-08 and 244-09), with each file read
in full. In scope: the new `bin/verify-lock-hygiene` and how `bin/verify-deps-audit` calls
it, the lazy `RETRY_NETWORK` wiring in `mix.exs`, the WR-01, WR-03 and WR-04 changes in
`bin/retry-network`, and the new tests and mutation controls.

Checks run during the review:
- `mix.exs` copied into directories named `a b"c`, `back\slash`, `` tick`x `` and `plain`.
  `mix help compile` exits 0 in each.
- `bin/verify-lock-hygiene` run on every git-tracked `mix.lock`: 4 locks, 134 `:hex`
  entries, exit 0.
- `bin/verify-lock-hygiene` run on 15 hand-made edge-case locks.
- A process-group SIGTERM sent while a fake `mix` (a real `erl`) was mid-attempt. The
  wrapper exits 143 after one call and leaves no `erl` process behind.

No blocker found. CR-01 is closed. The hygiene check reads the lock as data and never
evaluates it. The new mutation controls do turn red.

Remaining problems:
- The rewritten REL-04 prose still says local and CI "use one Hex version", but
  `MIN_HEX` is only a floor.
- `bin/verify-lock-hygiene` breaks its own exit-status contract in two edge cases.
- The nested-fetch contract now checks the variable name `$RETRY_NETWORK`. No test checks
  what that variable points at.

## Round 1 status

| Round-1 ID | Status | Evidence |
|------------|--------|----------|
| CR-01 | **Confirmed fixed** | `mix.exs:226` makes `"test.setup"` the function capture `&test_setup_fetch/1`. `mix.exs:279-281` computes `retry_network_env/1`'s path only when a task runs. Nothing in `project/0` or `aliases/0` checks the path, and the path never goes into shell text: all five users expand `"$RETRY_NETWORK"` in the child shell (`mix.exs:286,296,309,371,499`). Reproduced: a copied `mix.exs` loads from paths containing a space, `"`, `\` or a backtick. The tests at `test/threadline/retry_network_contract_test.exs:1315-1339` are not vacuous, because the eager-guard mutant fails in the spaced directory. |
| WR-01 | **Confirmed fixed** | `bin/retry-network:134-137` matches `grep -qiF ... 'dependency resolution failed'`. The fixture at `test/threadline/retry_network_contract_test.exs:137` uses Hex's real text. `Hex dependency resolution failed` is a literal in `Elixir.Hex.RemoteConverger.beam` (hex 2.5.1 archive checked). A registry fetch failure raises a different string, `Stopping due to errors` (`Elixir.Hex.Registry.Server.beam`), so the case-insensitive match does not turn that transient failure into a deterministic stop. |
| WR-03 | **Confirmed fixed** | `bin/retry-network:87-89` refuses a base above 30, and `bin/retry-network:158-160` caps each delay at 60s. The cap test at `test/threadline/retry_network_contract_test.exs:211-234` uses base 30, so 60 is always reached (the first delay is 30-60, and every later delay is capped). It also has a non-vacuity assertion. |
| WR-04 | **Confirmed fixed (header option); test gap remains** | `bin/retry-network:28-32` now describes the deferred trap correctly. Reproduced: a process-group TERM during an attempt gives exit 143 with exactly one call. Round 1 also asked for a test that sends TERM while the command is blocked. No such test was added (see R2-IN-02). |

## Warnings

### R2-WR-01: REL-04 prose says local and CI run "one Hex version", but `MIN_HEX` is a floor

**File:** `bin/verify-deps-audit:61-65`, `bin/verify-deps-audit:247-249`, `CONTRIBUTING.md:717-720`, `CONTRIBUTING.md:753-754`, `test/threadline/hex_pin_contract_test.exs:3`
**Issue:** This round rewrote the rationale for the Hex pin as toolchain determinism:
- `CONTRIBUTING.md:717`: "CI and every contributor run one Hex version".
- `CONTRIBUTING.md:754`: "a local run uses the same Hex as CI and refuses an older one".
- `bin/verify-deps-audit:64`: "local runs and CI use one Hex version".
- The `hex_pin_contract_test.exs` moduledoc: "CI and local run one chosen Hex version".

The gate does not enforce that. `version_ge "$hex_version" "$MIN_HEX"` (line 247) accepts
any newer Hex. A contributor on Hex 2.7.x passes `mix verify.deps_audit` while CI runs
2.6.0. That is the version-drift situation the section says the pin rules out, now with
local ahead of CI. This round's main purpose was to make the REL-04 explanation accurate,
and this sentence is still false.
**Fix:** Pick one and make the prose and the code agree:
```bash
# Option A: enforce the pin locally (the prose then becomes true)
if [ "$hex_version" != "$MIN_HEX" ]; then
  die "requires Hex $MIN_HEX (the CI pin), found $hex_version; run: mix local.hex $MIN_HEX --force"
fi
```
Option B: keep the floor and say what it does: "CI runs exactly 2.6.0, and a local run
refuses anything older. A newer local Hex is allowed and is not what CI runs." Apply the
same wording to the moduledoc and the script comment.

### R2-WR-02: `bin/verify-lock-hygiene` breaks its exit-status contract: a crash exits 1, and a malformed later lock hides earlier violations

**File:** `bin/verify-lock-hygiene:36-62`, `bin/verify-lock-hygiene:64-76`, `bin/verify-lock-hygiene:103-107`
**Issue:** The header says exit 1 means "an empty build-manager list" and exit 2 means
"malformed ... (fail closed)". Both cases below were reproduced.
1. If a violating entry's version (or name) is not a string literal, line 48 crashes. The
   example lock was `%{"x": {:hex, :x, {:a, :b}, "a", [], [], "hexpm", "b"}}`. Line 48
   interpolates the AST into a string and raises `Protocol.UndefinedError`, so `elixir`
   exits 1 with a stack trace. A malformed lock from an untrusted PR is then reported as a
   hygiene violation, partway through a broken FAIL line, instead of as exit 2 with a clear
   reason. `Enum.at(elems, 2)` is never checked to be a binary.
2. `main/1` calls `check/1` on every path before it prints anything, and `malformed/2`
   halts at once. Run as `verify-lock-hygiene good_with_violation.lock missing.lock`, it
   prints only the `missing.lock` read error and exits 2. The real `[]` violation in the
   first lock is never reported. `bin/verify-deps-audit` passes one lock per call, so the
   gate is not affected. The documented multi-lock CLI in `CONTRIBUTING.md` is affected.

Either way the result is still non-zero, so the gate fails closed. The diagnosis and exit
code are wrong.
**Fix:**
```elixir
version = Enum.at(elems, 2)
unless is_binary(version) do
  malformed(path, ":hex entry #{inspect(name)} has a non-string version: #{Macro.to_string(version)}")
end
# ...and in the FAIL line use inspect/1 for name, so no AST can reach String.Chars
```
For the ordering problem, make `check/1` return `{:malformed, path, reason}` instead of
halting. Print every violation and every malformed reason, then exit 2 if any lock was
malformed, else 1 if any violation was found, else 0. Add an ExUnit case for each problem
next to the existing fail-closed table in `deps_audit_gate_test.exs`.

### R2-WR-03: The nested-fetch contract now checks the variable name, not where the variable points; mutating `retry_network_env/1` removes every retry and keeps the suite green

**File:** `mix.exs:279-281`; `test/threadline/retry_network_contract_test.exs:978`, `test/threadline/retry_network_contract_test.exs:1255-1263`
**Issue:** `wrapper_prefix(@mix_exs)` passes any fetch written as `"$RETRY_NETWORK" mix
deps.get`. `rule=retry-env-pairing` passes any `Mix.shell().cmd` call that mentions
`retry_network_env`. No test asserts what `retry_network_env/1` sets. Suppose it is
changed to
`[{"RETRY_NETWORK", "env"} | env]`, or to `"command"`, or to a wrapper that only `exec`s
its arguments. Then all five nested fetches (`test.setup`, `verify.bench`,
`verify.bench_compile`, `verify.example`, `verify.hex_evaluator`) run `mix deps.get` with no
retry. Every REL-03 rule and the "exactly 5 wrapped" inventory still pass. Before this
round, the
checked text (`#{retry_network()}`) named the function that built the real path, so the
inventory meant something. Now the inventory is one level removed. The test header still
says the contract "pins every nested fetch behind it".

A typo in the path (`bin/retry_network`) would fail loudly with 127. The silent case needs
an executable stand-in, which is why this is a warning and not a blocker.
**Fix:** Pin the binding itself. For example:
```elixir
test "rule=retry-env-target: RETRY_NETWORK is bin/retry-network under __DIR__", %{live: live} do
  [body] = Regex.run(~r/defp retry_network_env\(env \\\\ \[\]\) do\n(.*?)\n  end/s, live[@mix_exs], capture: :all_but_first)
  assert String.trim(body) == ~S|[{"RETRY_NETWORK", Path.join(__DIR__, "bin/retry-network")} \| env]|
end
```
Add a mutation control that swaps the path for `"env"` and expects the rule to fire.

## Info

### R2-IN-01: verify-deps-audit's hygiene FAIL line blames an empty manager list for every non-zero status

**File:** `bin/verify-deps-audit:338-341`
**Issue:** The FAIL line always says "an empty build-manager list in mix.lock passes
against a warm deps/ ...". That is also printed for exit 2 (a parse error or unreadable
lock), for 127 (`elixir` not on PATH, because the script's shebang is
`#!/usr/bin/env elixir`), and for an exit-1 crash (R2-WR-02). The hygiene output above it
shows the real cause, but the summary line points the operator at the wrong fix.
**Fix:** Branch on the status:
```bash
case "$hygiene_status" in
  1) why="an empty build-manager list in mix.lock passes against a warm deps/ and fails CI's cold fetch" ;;
  *) why="the lock could not be checked (malformed, unreadable, or elixir missing)" ;;
esac
FAILURES+=("FAIL $d: lock hygiene exited $hygiene_status ($why; see the lines above)")
```

### R2-IN-02: No test covers a signal during an attempt (the WR-04 header claim)

**File:** `bin/retry-network:28-32`; `test/threadline/retry_network_contract_test.exs:236`
**Issue:** The only signal test sends TERM during the backoff. The new header sentence
says a process-group signal during an attempt exits with no retry. This review confirmed
that by hand, but nothing in the suite would catch a regression. The header also gives a
slightly wrong reason. A BEAM that gets SIGTERM shuts down gracefully, so mix does not
necessarily exit 130/143. What prevents the retry is the wrapper's own deferred trap,
which runs once the pipeline returns.
**Fix:** Add a test that starts the wrapper in its own process group (`bash -c 'set -m;
... & kill -TERM -- -$!'`), with a fake mix that sleeps. Assert exit 143, exactly one call
and no temp file left behind. Reword the header: "the wrapper's trap runs when the attempt
returns, so no further attempt starts."

### R2-IN-03: Stale `verify.deps_audit` alias comment

**File:** `mix.exs:190-194`
**Issue:** The comment says the gate "asserts Hex >= 2.6.0, then runs `deps.unlock
--check-unused` + `hex.audit`". It leaves out the new lock-hygiene step, the
`deps.get --check-locked` step and the global hex.config refusal. The script header was
updated. This comment was not.
**Fix:** Point to the script header instead of listing the steps, or list all of them.

### R2-IN-04: The CR-01 load tests cover only a space and a single quote

**File:** `test/threadline/retry_network_contract_test.exs:1315-1328`
**Issue:** Round 1's guard rejected whitespace, `'`, `"`, a backtick and `\`. The new tests
cover only the first two. `rule=alias-load-pure` only looks for `#{` inside `aliases/0`.
A non-interpolating load-time call (`[some_guard(), "test"]`) or a check added to
`project/0`, `docs/0` or `package/0` would get past it. The load tests catch those only
when the directory name contains one of the characters tested. This review loaded
`mix.exs` from directories containing `"`, a backtick and `\`, and all exit 0 today.
**Fix:** Turn the load tests into a table over `["a b", "a'b", ~S(a"b), "a`b", ~S(a\b)]`.

---

_Reviewed: 2026-10-25T16:35:55Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
