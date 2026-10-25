---
phase: 244-release-flow
plan: 04
subsystem: ci
tags: [ci, retry, hex, network, mix-aliases, bash, contract-test]
status: complete

requires:
  - "244-03: bin/retry-network and the workflow-level retry contract"
provides:
  - "mix.exs private retry_network/0 (absolute wrapper path, refused if it holds whitespace or a quote) and 5 wrapped nested alias fetches"
  - "The hex-evaluator resolve retries; its compile, ecto and test tail never does"
  - "bin/verify-deps-audit, bin/deps-health-report and bin/verify-bump-rehearsal fetch through bin/retry-network"
  - "Contract rules nested-unwrapped and nested-stale-allowlist over mix.exs and bin/*, plus nested retry-allowlist; @unwrapped_fetch_allowlist with 2 reasoned entries"
affects: [244-05, 244-06, 244-07, 245]

actuals:
  tokens: 5400
  tasks: 2
  commits: 5
plan_head_before: 317ed800701f06246b3a51b91c2cdc4cf7893673
plan_head_after: 3d4ec25c351c2b1350b2c299ce365f4b810e5772

tech-stack:
  added: []
  patterns:
    - "wrap the command, not the step: a fetch nested in an alias or script retries while the rest of its chain does not"
    - "lookahead capture in the wrapper-reference regex, so a second wrapper on the same line (a wrapped test tail) is still scanned"
    - "allowlist-with-reason module attribute plus a stale-entry rule"

key-files:
  created: []
  modified:
    - mix.exs
    - bin/verify-deps-audit
    - bin/deps-health-report
    - bin/verify-bump-rehearsal
    - test/threadline/retry_network_contract_test.exs
    - test/threadline/deps_audit_gate_test.exs
    - test/threadline/deps_health_report_test.exs

decisions:
  - "mix.exs fetches must sit behind the interpolated retry_network() reference; a relative bin/retry-network in mix.exs counts as unwrapped, because every nested alias cds before fetching"
  - "bin/verify-clean-checkout and bin/verify-planning-independent stay unwrapped: they run inside their own clean-clone proofs invoked from ExUnit contract tests, not CI fetch steps"
  - "the bin-scope half of the live nested contract landed in Task 2's RED commit, so Task 1 could go green on mix.exs alone"

metrics:
  duration: "~50 min"
  completed: 2026-10-25
---

# Phase 244 Plan 04: Nested fetches retry, their tests do not Summary

The hex-evaluator resolve now retries a transient hex.pm or network blip, and the `mix compile`, `mix ecto.*` and `mix test` that follow it in the same chain still run once. All five `mix deps.get` calls nested in mix.exs aliases and the three in CI-reached bin scripts go through `bin/retry-network`. A lock mismatch still fails on the first attempt. A contract test fails on any new unwrapped nested fetch and on any stale allowlist entry.

## What changed

- **mix.exs**
  - New private `retry_network/0` returns `Path.join(__DIR__, "bin/retry-network")`. It calls `Mix.raise` if the path holds whitespace, a quote, a backtick or a backslash, because the path is interpolated into `bash -lc '...'` scripts.
  - The five fetches in test.setup, verify_bench, verify_bench_compile, verify_example and verify_hex_evaluator now run `#{retry_network()} mix deps.get`. The two `printf \"n\\n\" |` pipes are gone, since the wrapper feeds `n`. The verify_example comment and a new verify_hex_evaluator comment say so.
  - Everything after the first `&&` is unchanged. The CI step `run: mix verify.hex_evaluator` is not wrapped.
- **bin scripts**
  - bin/verify-deps-audit and bin/deps-health-report now run `"$SCRIPT_DIR/retry-network" "$MIX_BIN" deps.get --check-locked` inside the same `$(...)` capture. The `<<<'n'` is dropped. The `set +e` status capture and every message are unchanged. The comment explains the marker stop and why pipes stay forbidden.
  - bin/verify-bump-rehearsal runs `(cd "$CLONE" && "$ROOT/bin/retry-network" mix deps.get) ||` and keeps its fail message.
  - MIN_HEX is unchanged (244-05 owns it).
- **retry_network_contract_test.exs** (62 tests, up from 51)
  - `nested_fetches/1` scans mix.exs and every regular file under bin/. It drops comment lines, backtick spans and single-quoted printf formats, then matches `mix deps.get` / `"$MIX_BIN" deps.get` as a standalone token.
  - Rules: `nested-unwrapped`, `nested-stale-allowlist`, and a nested `retry-allowlist` (each wrapper reference must run `mix|"$MIX_BIN" deps.get|local.hex`).
  - Live tests: all rules hold. The exact invocation set is pinned: mix.exs 5 wrapped; deps-health-report, verify-bump-rehearsal and verify-deps-audit 1 wrapped each; verify-clean-checkout and verify-planning-independent 1 unwrapped each; no prose. The hex-evaluator chain is pinned verbatim, with no `retry` text after `mix compile`. A fixture test shows that prose shapes are not invocations and that both call shapes are.
  - Mutation controls: unwrapping the hex-evaluator resolve, a relative wrapper path in mix.exs, and an unwrapped fetch appended to bin/verify-deps-audit each fire nested-unwrapped. Wrapping the `mix test` tail fires retry-allowlist. Renaming bin/verify-clean-checkout or removing bin/verify-planning-independent's fetch fires nested-stale-allowlist.
- **Fake-mix suites**
  - `RETRY_NETWORK_BASE_DELAY=0` is in both base env lists of deps_audit_gate_test.exs and in deps_health_report_test.exs `run_report/2`.
  - New assertions: FAKE_FAIL `one:deps.get` makes exactly 3 `deps.get --check-locked` calls. FAKE_LOCK_DRIFT makes exactly 1 call and the output contains `mix.lock is out of date`. A root deps.get failure in the health report makes exactly 3 calls and still classifies `unknown`. No existing assertion was removed. The `n\nn\nn\n` stdin and no-pipe-into-$MIX_BIN guards pass unchanged.

## Verification

- RED before GREEN for both tasks. Task 1 RED had 5 failures (mix.exs unwrapped). Task 2 RED had 4 failures (3 bin sites unwrapped, and the 3-attempt assertions in both suites).
- `mix test` on retry_network_contract, deps_audit_gate and deps_health_report: 114 tests, 0 failures. The tracer gate re-ran Task 1's verify green before Task 2.
- `bin/verify-deps-audit --self-test`: ok in about 12s. Case (d) lock drift stops on the marker, so no backoff runs.
- `bash -n` passes on all three edited scripts.
- Wave gate:
  - `mix verify.hex_evaluator` exits 0 with 19 tests, 0 failures. The log shows `cd priv/ci/hex_evaluator && (mix deps.unlock threadline || true) && <repo>/bin/retry-network mix deps.get && mix compile ... && mix test`.
  - `mix verify.bump_rehearsal` from a plain `git clone --no-local` under `<scratch>/` at eedf620a exits 0 with "Bump rehearsal OK" and "tree identity: MATCH".
- `mix verify.format`, `mix verify.credo` (no issues) and `bin/verify-repo-hygiene` (clean) all pass.
- `mix verify.test`: 3227 tests, 1 failure. It is the known environmental BrowserJourneyEvidenceContractTest failure ("Playwright CLI is missing", no e2e node_modules in this checkout).
- Acceptance greps: mix.exs has 0 `printf \"n` and 5 `retry_network()} mix deps.get`, and the full hex-evaluator chain grep finds 1. ci.yml has 1 `run: mix verify.hex_evaluator`. With `grep -F`, the `retry-network" "$MIX_BIN" deps.get --check-locked` count is 1 in each script. verify-bump-rehearsal has 1 `bin/retry-network" mix deps.get`. Neither script pipes into `"$MIX_BIN"`. `MIN_HEX="2.5.1"` appears once.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The wrapper-reference scan consumed the rest of the line**
- **Found during:** Task 1 GREEN
- **Issue:** The "wrap the `mix test` tail" control did not fire. The first `#{retry_network()}` match captured the whole line, so the second reference on that line was never scanned.
- **Fix:** The rest of the line is now captured in a lookahead, so every reference is scanned.
- **Commit:** 9baa4b6e

**2. [Rule 3 - Blocking] Bin-scope live assertions moved to Task 2's RED commit**
- **Found during:** Task 1
- **Issue:** The Task 1 behavior block expects the live tree to show 3 wrapped bin fetches, but the plan wraps them in Task 2. Task 1's verify could not pass with them in place.
- **Fix:** Task 1 shipped the detector, the mix.exs live tests and every mutation control. The all-files live rule and the exact invocation-set test came in with Task 2's RED.
- **Commits:** f33105d0, a088f825

**3. [Rule 1 - Lint] Prose fixtures rewritten as `~S` heredocs**
- **Found during:** wave gate (`mix verify.credo`, 2 readability issues)
- **Fix:** The fixture strings are now sigils. Behaviour is unchanged.
- **Commit:** 3d4ec25c

Also: verify-bump-rehearsal's fetch had moved from line 461 to line 498 since the plan was written. The site itself matched. The plan's non-fixed `grep -c` for the `"$MIX_BIN"` shape prints 0 on macOS BSD grep. `grep -cF` prints the expected 1.

The `--self-test` change was not needed. No self-test case reaches a fetch that fails without a marker, and the run did not slow down.

## Notes

- REL-03 is complete. The workflow fetches (244-03) and the nested fetches, including the hex-evaluator resolve, retry with backoff. No test is ever retried. The contract enforces both, and the hex-evaluator gate passed live.
- REL-02 stays pending until 244-07's live proof.
- Running the test.setup fetch shape by hand populated examples/threadline_phoenix/deps in this checkout. That directory is gitignored.

## Self-Check: PASSED

- FOUND files: mix.exs, bin/verify-deps-audit, bin/deps-health-report, bin/verify-bump-rehearsal, test/threadline/retry_network_contract_test.exs, test/threadline/deps_audit_gate_test.exs, test/threadline/deps_health_report_test.exs
- FOUND commits: f33105d0, 9baa4b6e, a088f825, eedf620a, 3d4ec25c
