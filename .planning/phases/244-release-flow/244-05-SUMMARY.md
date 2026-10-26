---
phase: 244-release-flow
plan: 05
subsystem: ci
tags: [ci, hex, toolchain-pin, supply-chain, contract-test, docs]
status: complete

requires:
  - "244-03: bin/retry-network (allowlists `mix local.hex`) and the inline bounded-retry recogniser"
  - "244-04: bin/verify-deps-audit fetches through the wrapper"
provides:
  - "test/threadline/hex_pin_contract_test.exs: hex_pin_errors/3 with rules pin-install-hex-off, pin-step, pin-wrapped, pin-uniform, pin-floor, pin-single, each mutation-proven; @live_scope list (one job today)"
  - "ci.yml verify-deps-audit: setup-beam `install-hex: false`, then `Pin Hex (CI and local must agree)` running `bin/retry-network mix local.hex 2.6.0 --force`"
  - "bin/verify-deps-audit MIN_HEX=\"2.6.0\" (literal); the self-test greps $MIN_HEX"
  - "CONTRIBUTING.md `### Why Hex is pinned in CI` with the 1.1.0 evidence and the pin rule"
affects: [244-06, 244-07, 245]

actuals:
  tokens: 7000
  tasks: 2
  commits: 4
plan_head_before: 1aadabd707430d385a4a58f3e1564edc4798d652
plan_head_after: cdad098465543104e7b0e1054a0edc0b5e10e02b

tech-stack:
  added: []
  patterns:
    - "setup-beam installs no Hex of its own; the next step pins one explicit version, retried"
    - "the local gate's floor is the CI pin, tied by a contract that reads MIN_HEX from the script"
    - "scope the live contract with one module attribute list so a later plan widens it in one line"

key-files:
  created:
    - test/threadline/hex_pin_contract_test.exs
  modified:
    - .github/workflows/ci.yml
    - bin/verify-deps-audit
    - test/threadline/deps_audit_gate_test.exs
    - test/partition_weights.txt
    - CONTRIBUTING.md
    - mix.exs

decisions:
  - "hex_pin_errors takes an optional scope (default :all) so fixtures check every job and the live assertion checks @live_scope only; 244-06 widens @live_scope"
  - "pin-wrapped keys on whether a workspace-root actions/checkout (no `path:`) precedes setup-beam: yes means bin/ is on disk and the wrapper is required, no means the inline bounded retry is required"
  - "the global Hex upgrade was NOT run (dispatch rule forbids replacing the real global Hex archive); every Hex-2.6.0 check ran under an isolated scratchpad MIX_HOME instead, and the global upgrade is handed to the maintainer"

metrics:
  duration: "~40 min"
  completed: 2026-10-25
---

# Phase 244 Plan 05: Hex pinned in the deps-audit job, floor equals the pin Summary

The CI job that caught the 1.1.0 lock mismatch (`verify-deps-audit`) now installs exactly Hex 2.6.0: setup-beam has `install-hex: false`, and the next step runs `bin/retry-network mix local.hex 2.6.0 --force`. `MIN_HEX` in bin/verify-deps-audit is 2.6.0, so a local Hex 2.5.1 now fails `mix verify.deps_audit` with `requires Hex >= 2.6.0, found 2.5.1` instead of accepting a lock CI rejects. A new contract with six mutation-proven rules guards the pin. CONTRIBUTING records the cause with run, commit and version evidence.

## What changed

- **test/threadline/hex_pin_contract_test.exs** (new, async). It defines a pure `hex_pin_errors(workflows, min_hex, scope \\ :all)` over path => workflow text. The parsing helpers are copied from the parity and retry-network tests, including the shared inline-retry recogniser. The rules:
  - `pin-install-hex-off`: every setup-beam step declares `install-hex: false`.
  - `pin-step`: the step right after setup-beam is a retried `mix local.hex X.Y.Z --force`, either through the wrapper or as the inline bounded retry. A bare `mix local.hex` anywhere fails this rule, and so does a version that is not X.Y.Z.
  - `pin-wrapped`: a job with a root checkout before setup-beam must use the wrapper. A job with only a sparse `.toolchain-pin` checkout must use the inline form.
  - `pin-uniform`: all pins name one version.
  - `pin-floor`: every pin equals MIN_HEX, which is read from bin/verify-deps-audit with `^MIN_HEX="([^"]+)"`. The test flunks if that line is absent.
  - `pin-single`: exactly one `mix local.hex` step per job.

  Fixture coverage: a rooted job and a sparse job together pass every rule. The sparse inline fixture passes alone, and the same fixture with an 11-attempt bound fails `pin-step`. There are 8 fixture mutation controls plus a pin-floor control, and 3 live-tree controls (drop install-hex, unretry, pin below MIN_HEX). The live assertion covers `@live_scope = [{ci.yml, verify-deps-audit}]`.
- **.github/workflows/ci.yml** `verify-deps-audit`: added `install-hex: false` as the last setup-beam input (the `uses:` line is unchanged), plus a commented step `Pin Hex (CI and local must agree)`. There are still 11 setup-beam references and no new `uses:`.
- **bin/verify-deps-audit**: `MIN_HEX="2.6.0"`, still a literal and still commented as never environment-overridable. A new comment line says the value must equal the CI pin, enforced by hex_pin_contract_test.exs. The self-test grep now uses `$MIN_HEX`.
- **test/threadline/deps_audit_gate_test.exs**: the passing default `FAKE_HEX_INFO` is now `Hex:    2.6.0` in both base envs. The floor assertion is `requires Hex >= 2.6.0`. A new test, "the 1.1.0 local Hex is below the floor CI pins", fakes Hex 2.5.1 and asserts `requires Hex >= 2.6.0, found 2.5.1` with no `deps.get`. `2\.5\.1` now appears exactly twice, on separate lines.
- **CONTRIBUTING.md**: the floor wording changed to 2.6.0 in the freshness section and the job roster row. A new `### Why Hex is pinned in CI` subsection sits at the end of "Dependency freshness policy", after the deps-health doc contract's paragraphs (that contract splits on `\n## `, so the subsection stays inside the section). It gives:
  - failing run 40028641095 and the three-directory `--check-locked` failure
  - commit a3301bed (`[]` manager list) and commit f7fdcaca (restored `[:mix]`)
  - Hex 2.6.0's publish time, 2026-10-23T11:57Z
  - the 2.5.1-accepts / 2.6.0-rejects reproduction
  - the unreproduced `[]` producer, presumed a hand or tool edit (assumption A2)
  - the pin rule, the one-commit bump rule, and the `mix local.hex 2.6.0 --force` upgrade command with its machine-wide scope and how to reverse it
- **mix.exs**: comment changed to "asserts Hex >= 2.6.0".

## Verification

- `mix test` on hex_pin, deps_audit_gate, ci_workflow_parity and retry_network: 159 tests, 0 failures. A wider run that adds deps_health_doc, deps_audit, ci_coverage_doc, ci_topology and community_health: 217 tests, 0 failures after the partition-weight fix.
- RED before GREEN: at 6c1e451e, 8 failures. They were the 4 live hex_pin tests and the 4 floor tests, which expected 2.6.0.
- `bin/verify-deps-audit --self-test` under an isolated MIX_HOME (`<scratch>/mixhome`, Hex 2.6.0) passes: `self-test: ok (vulnerable lock red, old Hex red, global Hex ignore red, lock drift red)`. Under the global Hex 2.5.1 it refuses at the floor, which is the intended signal.
- `mix verify.deps_audit` under the isolated Hex 2.6.0 passes: `3 lockfile(s) audit clean (Hex 2.6.0)`. Under the global 2.5.1 it fails with `requires Hex >= 2.6.0, found 2.5.1`, also intended.
- `mix verify.test`: 32 properties, 3245 tests, 1 failure, 3 excluded. The failure is the known environmental BrowserJourneyEvidenceContractTest one (Playwright CLI is missing).
- `mix verify.format` clean, `mix verify.credo` found no issues, and `bin/verify-repo-hygiene` is clean.
- Acceptance greps all match: `MIN_HEX="2.6.0"` 1, `requires Hex >= 2.5.1` in the script 0, `install-hex: false` 1, the pin run line 1, setup-beam 11, `2\.5\.1` in the gate test 2, no 2.5.1 floor wording left in CONTRIBUTING or mix.exs, `40028641095` 1, `f7fdcaca` 1, `mix local.hex 2.6.0 --force` 2.

## Local Hex: not upgraded (handed to the maintainer)

The plan's Task 2 calls for a one-time global `mix local.hex 2.6.0 --force`. The dispatch rules forbid replacing the real global Hex archive outside an isolated MIX_HOME and say to halt on that step, so it was **not run**.

- `mix hex.info` before: `Hex:    2.5.1` (global; Mix home `<home>/.mix/archives/`). After: unchanged, `Hex:    2.5.1`.
- Isolated `mix hex.info` (`MIX_HOME=<scratch>/mixhome`): `Hex:    2.6.0`.
- **Maintainer action:** run `mix local.hex 2.6.0 --force` once on the dev machine. It is machine-wide, reversible with `mix local.hex 2.5.1 --force`, and changes no repo file. Until then `mix verify.deps_audit`, `bin/verify-deps-audit --self-test` and therefore `mix ci.all` are red locally with `requires Hex >= 2.6.0, found 2.5.1` (RESEARCH Pitfall 6). CI is unaffected because it pins 2.6.0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Missing partition weight for the new test file**
- **Found during:** Task 2 verification (ci_topology_contract_test "committed partition weights cover the complete test inventory")
- **Fix:** added `50 test/threadline/hex_pin_contract_test.exs` (measured 0.05 s) in sorted position in test/partition_weights.txt
- **Commit:** 9e04f613

**2. [Rule 1 - Quality gate] credo --strict flagged job_pin_errors (complexity 14, nesting 3)**
- **Fix:** split it into `after_beam_errors/4`, `version_errors/3` and `wrapped_errors/4` clauses. Behaviour is unchanged and all 17 tests pass.
- **Commit:** 9e04f613

**3. [Rule 3] Self-test and deps-audit verified under an isolated MIX_HOME**
- The Task 1 `<verify>` runs `bin/verify-deps-audit --self-test`, which needs real Hex >= 2.6.0. The plan forbids upgrading the global Hex before Task 1 is green, and the dispatch forbids upgrading it at all. So both real-Hex checks ran with `MIX_HOME=<scratch>/mixhome`: a copy of the Mix home with only the Hex 2.6.0 archive installed.

**4. Task 2 global Hex upgrade not performed.** See the section above. This is a dispatch-rule halt on that one step, not a failure.

### Notes

- The CONTRIBUTING rule states that every workflow pins Hex, but today only verify-deps-audit is pinned. Plan 244-06 pins the remaining setup-beam jobs and widens `@live_scope`. Until then the doc describes the phase's end state.
- The subsection was moved to the end of "Dependency freshness policy". Inserting it in the middle would have put the deps-health paragraphs under the new heading.

## Known Stubs

None.

## Threat Flags

None. The only new network surface is the version-pinned Hex archive fetch, which is already T-244-12/T-244-14.

## Self-Check: PASSED

- FOUND: test/threadline/hex_pin_contract_test.exs
- FOUND: 6c1e451e, 6b2b94a2, 9e04f613, cdad0984 (all ancestors of HEAD)
