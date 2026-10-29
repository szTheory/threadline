---
phase: 244-release-flow
plan: 03
subsystem: ci
tags: [ci, retry, hex, network, github-actions, bash, contract-test]
status: complete

requires:
  - "244-02: release.yml sync job with bin/date-release-changelog (named by rule retry-ref-independent)"
provides:
  - "bin/retry-network: allowlisted retry-with-backoff wrapper for `mix deps.get` / `mix local.hex`"
  - "All 15 workflow `mix deps.get` steps retry: 14 via the wrapper, release.yml publish-hex via an inline bounded loop"
  - "test/threadline/retry_network_contract_test.exs: behaviour tests + rules retry-allowlist, retry-no-test, retry-no-action, retry-path, retry-unwrapped, retry-ref-independent, retry-inline-shape"
  - "inline_retry_shape/1: the single inline-retry recogniser 244-05/244-06 reuse for the Hex pin"
affects: [244-04, 244-05, 244-06, 245]

actuals:
  tokens: 11500
  tasks: 2
  commits: 4
plan_head_before: ce1c2a9c6ad8ecc7186af413f972f5fd2aa91b12
plan_head_after: 77a938cb14432822f9bb7d54d26463a39d16e006

tech-stack:
  added: []
  patterns:
    - "fake `mix` on PATH (CALL_LOG / STDIN_LOG / FAKE_FAIL_TIMES) drives a bash wrapper with no network"
    - "backgrounded `sleep & wait` backoff so a SIGTERM trap fires mid-delay"
    - "inline bounded `for attempt in 1 2 3` retry for jobs that check out a computed ref"

key-files:
  created:
    - bin/retry-network
    - test/threadline/retry_network_contract_test.exs
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - .github/workflows/browser-full.yml
    - .github/workflows/flake-detection.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/partition_weights.txt

decisions:
  - "bin/retry-network backoff sleeps in the background and waits, so SIGINT/SIGTERM exit 130/143 at once instead of after the delay"
  - "retry-unwrapped accepts a step only when inline_retry_shape/1 returns [] (a malformed inline loop counts as unwrapped as well as failing retry-inline-shape)"
  - "retry-ref-independent keys on a workspace-root actions/checkout (no path:) whose ref: contains an expression; bin/verify-release-shape stays allowed in publish-hex"
  - "the publish-hex inline loop's comment avoids naming the wrapper, so release.yml has exactly one retry-network reference (sync job)"

metrics:
  duration: "~40 min"
  completed: 2026-10-25
---

# Phase 244 Plan 03: Retry CI network fetches, never tests Summary

Every `mix deps.get` in the workflows now gets through a short hex.pm or network outage. Fourteen steps run `bin/retry-network mix deps.get`: 3 attempts, 5s then 15s backoff plus jitter, and an allowlist enforced at runtime. The release.yml publish-hex step runs an inline bounded loop that references no repo file. A contract test fails if any test is retried, a retry action appears, or a fetch is left unwrapped.

## What changed

- **bin/retry-network** (new, mode 100755)
  - Usage: `[--attempts N] [--] mix deps.get|local.hex ...`. N must be 1..10 (default 3), and `RETRY_NETWORK_BASE_DELAY` must be a non-negative integer (default 5). Anything else exits 2.
  - Any command other than `mix deps.get` / `mix local.hex` (checked by basename) exits 2 before it runs. The refusal message names the allowlist.
  - Each attempt reads `n` from a `<<<'n'` here-string. Output is merged and streamed through `tee` into a `mktemp` log, and the status comes from `PIPESTATUS[0]`.
  - The loop stops at once on exit 126/127/130/143 or on the markers `mix.lock is out of date`, `Unchecked dependencies` or `Dependency resolution failed`.
  - A trap removes the temp log on every exit path. SIGINT/SIGTERM exit 130/143 without starting another attempt.
- **Workflows:** only `run:` values changed.
  - ci.yml: 8 steps use `bin/retry-network mix deps.get` and 3 example-dir steps use `../../bin/retry-network mix deps.get`.
  - release.yml: the sync `Fetch dependencies` step uses the wrapper. publish-hex `Install dependencies` is now the inline `for attempt in 1 2 3` loop (`mix deps.get <<<'n'`, `sleep $((attempt * 10))` between attempts, giving-up line on stderr, `exit 1`).
  - browser-full.yml and flake-detection.yml: 1 step each.
  - The count of `uses:` lines is unchanged in every file (50/14/6/4/...). No step names or job ids changed, and no step was inserted.
- **ci_workflow_parity_contract_test.exs**
  - `run_step_class/1` now accepts an optional `(../)*bin/retry-network ` prefix for `:deps_get`.
  - New fixture test: the whole build-cache fixture with wrapped fetches (root and `../../` forms) still passes every D-07 rule.
  - New fixture test: a wrapped `mix compile` classifies as neither `:compile` nor `:deps_get`.
- **retry_network_contract_test.exs** (new, 51 tests)
  - Behaviour matrix through a fake `mix`: covers the bullets above, plus a SIGTERM-mid-backoff test (exit 143, 1 call, no temp file, under 15s with a 30s base delay).
  - The seven rules run on the live tree, with a test that the live tree has exactly 14 wrapper-form fetches and 1 inline one, and a publish-hex positive control.
  - Mutation controls cover every rule, including the publish-hex and example-dir unwraps, wrapper / date-release-changelog in publish-hex, and four inline-shape breakages.

## Verification

- Task 1 verify (retry_network, ci_workflow_parity, ci_topology): 114 tests, 0 failures. The tracer gate re-ran it green before expansion.
- Task 2 verify (retry_network, ci_workflow_parity, ci_topology, release_control_plane, ci_action_runtime, ci_token_permissions, plus flake_classifier): 230 tests, 0 failures.
- RED before GREEN for both tasks. The Task 1 RED had 27 failures (wrapper absent). The Task 2 RED had 4 failures (14 sites unwrapped).
- `mix verify.format`, `mix verify.credo` (no issues) and `bin/verify-repo-hygiene` (clean) all pass.
- `mix verify.test`: 3215 tests, 1 failure. The failure is environmental: BrowserJourneyEvidenceContractTest reports "Playwright CLI is missing", because this checkout has no `examples/threadline_phoenix/e2e/node_modules`. It does not involve these changes.
- Acceptance greps:
  - 0 `run: mix deps.get` lines left in any workflow.
  - ci.yml has 3 `../../` lines and 8 root wrapper lines.
  - release.yml, browser-full.yml and flake-detection.yml have 1 `retry-network` reference each.
  - numstat is 10/10 for ci.yml in Task 2 (plus 1/1 in Task 1) and 1/1 each for browser-full.yml and flake-detection.yml. release.yml changes only the sync run line and the publish-hex run block.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Registered the new test file in test/partition_weights.txt**
- **Found during:** Task 1
- **Issue:** `ci_topology_contract_test` "committed partition weights cover the complete test inventory" fails for any test file that has no weight.
- **Fix:** Added a hand-measured `1300 test/threadline/retry_network_contract_test.exs` row in sorted order, as 244-01 did. The weights file was not regenerated.
- **Commit:** a5dc793b

**2. [Rule 1 - Bug] Control anchor moved from verify-credo to verify-pgbouncer-topology**
- **Found during:** Task 1
- **Issue:** The "wrap `mix compile`" mutation control assumed verify-credo runs `mix compile --warnings-as-errors`, but it does not.
- **Fix:** Anchored the control in verify-pgbouncer-topology, where the line is unique.
- **Commit:** a5dc793b

Also: the release.yml line numbers in the plan (170, 492) had moved to 175 and 505 after 244-01/02. The count of 15 sites matched, so nothing was adjusted.

## Notes

- REL-03 stays pending. This plan covers the workflow-level fetches. 244-04 covers fetches nested inside mix aliases and bin scripts.
- actionlint reports pre-existing shellcheck style findings at release.yml lines 275, 341 and 726. None of those steps were touched here.

## Self-Check: PASSED

- FOUND: bin/retry-network (100755), test/threadline/retry_network_contract_test.exs
- FOUND commits: f4072de9, a5dc793b, 08770451, 77a938cb
