---
phase: 244-release-flow
reviewed: 2026-10-25T15:33:04Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/deps-health.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - CHANGELOG.md
  - CONTRIBUTING.md
  - bin/date-release-changelog
  - bin/deps-health-report
  - bin/retry-network
  - bin/verify-bump-rehearsal
  - bin/verify-deps-audit
  - mix.exs
  - release-please-config.json
  - test/partition_weights.txt
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/date_release_changelog_test.exs
  - test/threadline/deps_audit_gate_test.exs
  - test/threadline/deps_health_report_test.exs
  - test/threadline/hex_pin_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/retry_network_contract_test.exs
findings:
  critical: 1
  warning: 5
  info: 4
  total: 10
status: issues_found
---

# Phase 244: Code Review Report

**Reviewed:** 2026-10-25T15:33:04Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

I reviewed the hunks changed since `5d83bf24` in the release workflow, CI workflows, bin
scripts, `mix.exs`, release-please config and the new or changed contract tests.
`bin/date-release-changelog` works as described. A copy run dated a seeded block, was
idempotent on a second run, and never puts version or date text into perl source. The
Hex pin contract is not vacuous: it checks the live pin count (17) against the 17
`setup-beam` steps.

The blocker is in `mix.exs`. The new `retry_network/0` guard runs every time the project
loads. Any checkout or dependency path with a space in it now fails every `mix` command,
and that includes adopters who use threadline as a dependency. Both cases were reproduced.

The other findings are in `bin/retry-network`:
- One of its three "deterministic failure" markers can never match Hex's real output, and
  its test passes only because the test output was made up to match it.
- Its backoff has no cap.
- Its signal handling does not match what the script header says.

The known 244-07 problem with the CONTRIBUTING "Why Hex is pinned in CI" cause text is not
reported again here.

## Critical Issues

### CR-01: `retry_network/0` raises during project load, so any path with whitespace or a quote breaks every `mix` command, including for adopters

**File:** `mix.exs:50`, `mix.exs:226-229`, `mix.exs:278-289`
**Issue:** `project/0` calls `aliases()` (line 50). The `"test.setup"` alias interpolates
`#{retry_network()}` into a string literal inside `aliases/0`, so `retry_network/0` runs
every time `Mix.Project` loads, not only when a nested fetch runs. If `__DIR__` contains
whitespace, `'`, `"`, a backtick or `\`, it calls `Mix.raise` before any task runs.
Reproduced in two ways:
- `mix.exs` copied into a directory named `a b`: `mix help compile` and `mix eval` both
  fail with `** (Mix.Error) the checkout path ".../a b/bin/retry-network" contains
  whitespace or a quote`.
- A consumer project with `{:threadline, path: "../"}` pointing at that directory:
  `mix deps.get` fails with `Error while loading project :threadline ... ** (Mix) the
  checkout path ...`.

`mix.exs` ships in the Hex package (`files:` line 561), and Mix runs `project/0` for every
dependency. Once this is released, any adopter whose project path has a space (common on
macOS, and for Windows profile folders named "First Last") can no longer
compile threadline. `bin/` is not even in the package, so the path being checked does not
exist on the adopter's machine. Contributors cloning into such a path are also locked out
of all tooling, including `mix test`.

**Fix:** Do not compute the path during alias definition. Resolve it only when a fetch
actually runs, and pass it through the environment instead of interpolating it into
shell text, so it never needs to be refused:
```elixir
"test.setup": [&test_setup_fetch/1, "test"],

defp test_setup_fetch(_args) do
  run_nested!("cd examples/threadline_phoenix && \"$RETRY_NETWORK\" mix deps.get")
end

defp run_nested!(script, env \\ []) do
  env = [{"RETRY_NETWORK", Path.join(__DIR__, "bin/retry-network")} | env]
  case Mix.shell().cmd("bash -lc " <> shell_quote("set -euo pipefail && " <> script), env: env) do
    0 -> :ok
    status -> Mix.raise("nested fetch failed (#{status})")
  end
end
```
Then use `"$RETRY_NETWORK" mix deps.get` in `verify_bench`, `verify_bench_compile`,
`verify_example` and `verify_hex_evaluator`. Add a contract test that loads `mix.exs`
from a directory whose name contains a space. If the update to
`retry_network_contract_test.exs`'s `wrapper_prefix/1` regex is missed, that test can still
pass while the guard is broken.

## Warnings

### WR-01: The `Dependency resolution failed` marker never matches Hex's real message, and its test passes only on made-up output

**File:** `bin/retry-network:117-120`; `test/threadline/retry_network_contract_test.exs:132-150`
**Issue:** `grep -qF` matches case-sensitively. Hex's actual resolution failure is raised
as `Hex dependency resolution failed`, with a lower-case `d`. That string is in
`Elixir.Hex.RemoteConverger.beam` in the Hex 2.5.1 archive, and no `Dependency resolution
failed` string exists there. So a real version-conflict failure, which a retry cannot fix,
runs all 3 attempts with 5s and 15s backoff instead of stopping after the first. The
contract test passes because its fixture prints `** (Mix) Dependency resolution failed`,
a string written to match the script's grep rather than taken from Hex.
**Fix:** Match on the actual text, case-insensitively, and use real Hex output in the test:
```bash
grep -qiF -e 'mix.lock is out of date' -e 'Unchecked dependencies' \
  -e 'dependency resolution failed' "$log"
```
Change the fixture to `** (Mix) Hex dependency resolution failed`, copied from Hex's
real output.

### WR-02: The denylist still retries common failures that are not network problems

**File:** `bin/retry-network:112-122`
**Issue:** Every nonzero exit other than 126, 127, 130 and 143, and other than the three
markers, is treated as transient. That covers deterministic failures that `deps.get` hits
often:
- `Registry checksum mismatch against lock` (the `verify_hex_evaluator` comment at
  `mix.exs:498-506` mentions this exact case)
- `No package with name ...` / `No matching version`
- A `mix.exs` compile error (`** (CompileError)`)
- `Request failed (403)` / `(401)` authentication errors

Each of these costs 2 extra attempts and about 20s or more. The header says "retry a
network dependency fetch", but in practice the script retries any fetch failure.
**Fix:** Add these markers to the not-retried list, matched case-insensitively, with one
real-output fixture per marker in `retry_network_contract_test.exs`. A safer long-term
option is an allowlist of transient signatures, such as `timeout`, `econnrefused`,
`nxdomain`, `closed`, and HTTP 5xx or 429 responses, retrying only on those.

### WR-03: Exponential backoff has no cap: `--attempts 10` can sleep for about 13.6 hours

**File:** `bin/retry-network:67-68`, `bin/retry-network:137-140`
**Issue:** The script accepts `--attempts` up to 10, and the delay is `base * 3^(attempt-1)`
with no ceiling. At the default base of 5, attempts 2 to 10 wait 5, 15, 45, 135, 405,
1215, 3645, 10935 and 32805 seconds, about 49,000 seconds in total. A caller who raises
`--attempts` would leave a CI job hanging until the job timeout, and a local run would
look stuck. `RETRY_NETWORK_BASE_DELAY` has no upper bound either.
**Fix:** Cap each delay and validate the base:
```bash
max_delay=60
delay=$((base * 3 ** (attempt - 1)))
[ "$delay" -gt "$max_delay" ] && delay=$max_delay
```
Also reject `RETRY_NETWORK_BASE_DELAY` values above a small bound, for example 30.

### WR-04: "SIGINT/SIGTERM exit 130/143 at once" is false while the command is running

**File:** `bin/retry-network:22`, `bin/retry-network:95-105`
**Issue:** Bash defers trap handlers until the foreground pipeline (`"$@" <<<'n' 2>&1 | tee
"$log"`) finishes. A SIGTERM sent only to the wrapper's PID does nothing until `mix` exits,
and `cleanup` never signals the running `mix`. Examples of such a signal are `timeout`,
`kill <pid>`, or a supervisor that does not signal the whole process group. The immediate
exit the comment promises only happens during the backgrounded `sleep`. The contract test
appears to cover only signals during the sleep.
**Fix:** Run the attempt in the background, forward signals to it, and `wait`:
```bash
"$@" <<<'n' > >(tee "$log") 2>&1 &
cmd_pid=$!
trap 'kill -TERM "$cmd_pid" 2>/dev/null; cleanup; exit 143' TERM
wait "$cmd_pid"; status=$?
```
Alternatively, correct the header so it describes only the backoff window, and add a test
that sends TERM while the fake mix is blocked.

### WR-05: The sync job's push step runs git hooks and config that compiled dependency code could have planted, with `PUSH_TOKEN` in its environment and URL (pre-existing; phase 244 makes the job push more often)

**File:** `.github/workflows/release.yml:187-226`
**Issue:** `persist-credentials: false` keeps the token out of `.git/config` while
dependency code compiles (`mix deps.get` / `mix release.pins`). Those same steps can still
write `.git/hooks/pre-commit` or `pre-push`, or set `core.hooksPath` or `url.*.insteadOf`
in `.git/config`. The push step then runs `git commit` and `git push` with `PUSH_TOKEN` in
the step environment, and the token is embedded in the push URL that a `pre-push` hook
receives as `$2`. That means a compromised dependency can read the PAT. Phase 244 makes this
more likely: the date step now produces a diff on every release-PR regeneration (with
`always-update: true`, on every push to main), so the commit and push run each time
instead of only on minor bumps. The new `date-no-token` rule checks the date step and does
not cover this path.
**Fix:** Turn off hooks and config indirection for the authenticated commands:
```bash
git -c core.hooksPath=/dev/null commit -m "..."
git -c core.hooksPath=/dev/null -c url.https://github.com/.insteadOf= \
  push "https://x-access-token:${PUSH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" HEAD:...
```
A stronger option is to move commit and push into a separate job that downloads only the
staged files as an artifact and never runs Mix.

## Info

### IN-01: `--date` and the derived date are checked for shape only, not for a real calendar date

**File:** `bin/date-release-changelog:44`, `bin/date-release-changelog:73-75`, `bin/date-release-changelog:100`
**Issue:** `2026-13-45` passes `DATE_RE` and would be written as the release heading.
**Fix:** Also run `date -u -d "$DATE" +%F` (GNU) and require the output to equal `$DATE`,
or do the same check in perl.

### IN-02: `--check` uses exit 1 both for "rename pending" and for every refusal

**File:** `bin/date-release-changelog:122-144`
**Issue:** A caller using `--check` cannot tell "would date" apart from "ambiguous or
empty CHANGELOG". Both exit 1.
**Fix:** Use a separate status for "rename pending", for example 3, and document it in
the exit-status header.

### IN-03: `bin/retry-network`'s `basename == mix` check couples the `MIX_BIN` hook used by two scripts

**File:** `bin/retry-network:78-81`; `bin/verify-deps-audit:335`; `bin/deps-health-report:246`
**Issue:** Both scripts now pass `"$MIX_BIN"` to the wrapper. A `MIX_BIN` whose file
name is not exactly `mix` (for example a versioned shim such as `mix-1.17`) is now
refused with exit 2 and reported as a fetch failure. Before this phase it worked.
**Fix:** Document the constraint next to `MIX_BIN=` in both scripts, or add an explicit
`RETRY_NETWORK_ALLOW_MIX_BIN` escape that still requires `deps.get` / `local.hex` as the
subcommand.

### IN-04: A placeholder-only Unreleased block also stops the install-pin sync

**File:** `.github/workflows/release.yml:199-205`
**Issue:** The date step runs before the push step, so when it fails, the pins that
`mix release.pins` already rewrote are never pushed either. The release PR then fails
twice: on `verify-release-shape`, and on the pin contract when it is a minor bump. The
second failure hides the actual cause. CONTRIBUTING only mentions the CHANGELOG failure.
**Fix:** Either push the pins before dating, or add `continue-on-error` and fail the job
after the push. Or document in CONTRIBUTING that the pins also go stale in this state.

---

_Reviewed: 2026-10-25T15:33:04Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
