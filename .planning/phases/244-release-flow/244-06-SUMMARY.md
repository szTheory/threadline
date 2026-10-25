---
phase: 244-release-flow
plan: 06
subsystem: ci
tags: [ci, hex, toolchain-pin, supply-chain, contract-test, release]
status: complete

requires:
  - "244-05: hex_pin_contract_test.exs (rules pin-install-hex-off, pin-step, pin-wrapped, pin-uniform, pin-floor, pin-single) and the verify-deps-audit tracer pin"
  - "244-03: bin/retry-network allowlisting `mix local.hex`, and the inline bounded-retry shape"
provides:
  - "All 17 erlef/setup-beam steps (ci.yml 11, release.yml 3, browser-full, flake-detection, deps-health) set `install-hex: false` and are followed directly by `Pin Hex (CI and local must agree)`"
  - "14 wrapper-form pins (`bin/retry-network mix local.hex 2.6.0 --force`), 3 inline bounded-retry pins in release.yml's sparse .toolchain-pin jobs"
  - "hex_pin_contract_test.exs live scope = every job in every workflow, with a 17-pinned-step count"
  - "ci_workflow_parity_contract_test.exs @matrix_beam_inputs admits exactly `install-hex: false` as a fifth input"
affects: [244-07, 245]

actuals:
  tokens: 5000
  tasks: 2
  commits: 4
plan_head_before: cb59f495424a999b7004cc5a2146557afb41e99c
plan_head_after: 0a435e6147e8bf47bb21857d85dcb8c7ce66f1ac

tech-stack:
  added: []
  patterns:
    - "live contract scope `:all` plus an exact pinned-step count, so a parse that finds no jobs cannot pass vacuously"
    - "job-scoped mutation controls (mutate_job/5) keep anchors unique once every job carries the same pin text"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/release.yml
    - .github/workflows/browser-full.yml
    - .github/workflows/flake-detection.yml
    - .github/workflows/deps-health.yml
    - test/threadline/hex_pin_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs

decisions:
  - "Hex pin contract live scope is `:all` (every job in every workflow) with @live_pin_count 17; scope entries may also be {path, :all}"
  - "release.yml sparse-job pins use the inline bounded retry (3 attempts, `<<<'n'`, 10s/20s sleeps, exit 1) placed between setup-beam and the ref checkout, so release_control_plane anchors are untouched"
  - "The parity control 'setup-beam moved below the target-ref checkout' now moves setup-beam alone past the pin step, keeping its meaning"

metrics:
  duration: "~35 min"
  completed: 2026-10-25
---

# Phase 244 Plan 06: Hex 2.6.0 pinned in every CI job Summary

Every CI job now pins Hex 2.6.0, the same version as the local floor. All 17 setup-beam steps set `install-hex: false`, and the next step installs Hex 2.6.0 with a retry. 14 jobs do that through `bin/retry-network`. The three release.yml jobs that start from a sparse `.toolchain-pin` checkout use an inline bounded retry instead. The hex pin contract now checks every job in every workflow and requires exactly 17 pinned steps.

## What changed

- **.github/workflows/ci.yml**: the 10 remaining setup-beam steps each gained `install-hex: false` as their last `with:` line. A `Pin Hex (CI and local must agree)` step running `bin/retry-network mix local.hex 2.6.0 --force` follows each one. This covers verify-format, compile-no-optional, hex-evaluator, pgbouncer-topology, credo, bump-rehearsal, dialyzer, the verify-test matrix (all three lanes), capture and example-browser. The diff is 40 additions and 0 deletions. There are still 11 `uses: erlef/setup-beam@v1` lines.
- **.github/workflows/release.yml**: sync-release-pr-pins, publish-hex and smoke-published each gained `install-hex: false`. Each also gained a pin step directly after setup-beam and before the ref checkout. That step runs the inline loop: `for attempt in 1 2 3`, `mix local.hex 2.6.0 --force <<<'n'`, sleep `attempt * 10`, then a giving-up line and `exit 1`. A two-line comment explains why the loop is inline: bin/ only arrives with the ref checkout, and a recovery run may check out a tag that lacks it. The diff is 48 additions and 0 deletions. The `persist-credentials: false$` count is still 7.
- **browser-full.yml, flake-detection.yml, deps-health.yml**: each gained `install-hex: false` and the wrapper pin step. The browser-full and flake pins copy setup-beam's `if: steps.gate.outputs.decision == 'run'`.
- **test/threadline/hex_pin_contract_test.exs**:
  - `@live_scope :all` and `@live_pin_count 17`.
  - New `pinned_beam_count/2`, which counts setup-beam steps directly followed by a recognised pin.
  - New `mutate_job/5` and `move_pin_after_first_cache/3`. The live controls are now job-scoped because the pin text repeats in every job.
  - Controls: deps-audit drop install-hex fires `pin-install-hex-off`; unretry fires `pin-step`; pin below MIN_HEX fires `pin-floor`; the verify-test matrix drop install-hex fires `pin-install-hex-off`; the verify-format pin moved past its first cache fires `pin-step`; a bare release pin in publish-hex fires `pin-step`; a wrapper release pin in smoke-published fires `pin-wrapped`; an inline browser-full pin fires `pin-wrapped`.
- **test/threadline/ci_workflow_parity_contract_test.exs**: `"install-hex: false"` is added to `@matrix_beam_inputs`, with a comment. There are two new matrix controls: `install-hex: true` must fail, and an extra unknown `install-rebar: false` input next to install-hex must fail. The existing `rebar3-version` control still fails too. The `setup_beam_steps - 1 == 11` assertion is unchanged.

## Verification

- RED before GREEN:
  - Task 1 red at 84bc4d53: 4 failures (3 hex-pin live tests and the parity matrix control).
  - Task 2 red at 96ff461f: 5 failures (the live count and assertion plus the release and browser-full controls).
- Task 1 verify (hex_pin, ci_workflow_parity, ci_topology, ci_action_runtime, retry_network): 172 tests, 0 failures.
- Task 2 verify (the same files plus release_control_plane and ci_token_permissions): 227 tests, 0 failures.
- `mix verify.test`: 32 properties, 3250 tests, 1 failure, 3 excluded. The only failure is the known environmental BrowserJourneyEvidenceContractTest one ("Playwright CLI is missing").
- `mix verify.format` exits 0. `mix verify.credo` found no issues. `bin/verify-repo-hygiene` is clean.
- All acceptance greps match:

  | Check | Result |
  |-------|--------|
  | ci.yml `install-hex: false` | 11 |
  | ci.yml wrapper pin lines | 11 |
  | ci.yml setup-beam lines | 11 |
  | release.yml `install-hex: false` | 3 |
  | release.yml `<<<'n'` pins | 3 |
  | release.yml bare `run: mix local.hex` | 0 |
  | release.yml `for attempt in 1 2 3` | 4 |
  | wrapper pin in each of browser-full, flake-detection, deps-health | 1 each |
  | `install-hex: false` across all workflows | 17 |
  | release.yml `persist-credentials: false$` | 7 (unchanged) |
  | workflow diffs | additions only |
  | `uses:` / `id:` lines changed | none |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Stale control] The parity control "setup-beam moved below the target-ref checkout" no longer matched**
- **Found during:** Task 2 verify (ci_workflow_parity_contract_test "release jobs read the toolchain pin from the workflow's own commit")
- **Issue:** The control replaced the contiguous text `toolchain_checkout <> beam_step <> target_checkout`. The pin step now sits between setup-beam and the target checkout, so the replacement changed nothing and the test's own "control did not change the input" guard failed.
- **Fix:** The control now destructures `[toolchain_checkout, beam_step, hex_pin_step | _]` and asserts that the third step runs `mix local.hex`. It then moves setup-beam alone below the target checkout. The control means the same thing as before and still turns the contract red.
- **Files modified:** test/threadline/ci_workflow_parity_contract_test.exs
- **Commit:** 0a435e61

**2. [Scope] The live-tree controls are now job-scoped.** The 244-05 controls anchored on text that was unique in ci.yml. Once every job carries the pin, that text appears 11 times. `mutate_job/5` now finds the anchor inside one named job and asserts it is unique there.

## Open assumption

A3: the matrix `min` lane (Elixir 1.15.8 / OTP 26.2.5.21) and the `latest` lane (1.20.4 / 29.1.1) install and run Hex 2.6.0 through `mix local.hex 2.6.0 --force`. Only the phase PR's own CI run after the maintainer pushes can confirm this.

## Known Stubs

None.

## Threat Flags

None. The only network surface is the version-pinned Hex archive fetch (T-244-15/T-244-17). No new `uses:` was added, and the credential-bearing release steps are untouched (T-244-16).

## Self-Check: PASSED

- FOUND: test/threadline/hex_pin_contract_test.exs, .github/workflows/{ci,release,browser-full,flake-detection,deps-health}.yml
- FOUND: 84bc4d53, 9ead808c, 96ff461f, 0a435e61 (all ancestors of HEAD)
