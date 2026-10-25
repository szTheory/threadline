---
phase: 244-release-flow
plan: 09
subsystem: ci
tags: [ci, hex, mix-exs, retry, gap-closure, packaging]
status: complete

requires:
  - "244-03/244-04: bin/retry-network and the REL-03 nested-fetch contract (5 mix.exs fetches wrapped, tails unwrapped)"
provides:
  - "mix.exs loads from any checkout path: no path computation or guard in project/0 or aliases/0 (CR-01 closed)"
  - "retry_network_env/1 hands bin/retry-network to child shells as RETRY_NETWORK, expanded quoted; test.setup's fetch is the function alias test_setup_fetch/1"
  - "describe \"mix.exs loads from any checkout path (CR-01)\": spaced/quoted/plain load tests, eager-guard mutation control, rule=alias-load-pure, rule=retry-env-pairing"
  - "bin/retry-network: Hex's real `dependency resolution failed` marker (case-insensitive), 60s delay cap, RETRY_NETWORK_BASE_DELAY max 30, RETRY_NETWORK_SLEEP_BIN test seam, accurate signal header (WR-01, WR-03, WR-04)"
affects: [244-10, 244-VERIFICATION]

actuals:
  tokens: 5300
  tasks: 3
  commits: 3
plan_head_before: c3e2f01a93ab902004a359ebb915bbe7b58c720a
plan_head_after: 3c08524bb43cac939b5bf82b23b08b06642715a3

tech-stack:
  added: []
  patterns:
    - "resolve shell-bound paths lazily in task functions and pass them by environment, never interpolated into shell text"
    - "load a copied mix.exs in a child `mix help compile` (MIX_* path vars unset) to test project-load behaviour without in_project/4"
    - "test seam env var for the sleep binary so a backoff cap is proven with zero real sleep"

key-files:
  created: []
  modified:
    - mix.exs
    - bin/retry-network
    - test/threadline/retry_network_contract_test.exs

decisions:
  - "CR-01 fix: the wrapper path travels in RETRY_NETWORK and is resolved only inside fetching task functions; nothing in project/0 or aliases/0 can refuse a checkout path"
  - "WR-04 corrected in the header, not by signal forwarding: process-group signals already reach mix, whose 130/143 is never retried"
  - "The real Hex text is `** (Mix) Hex dependency resolution failed` (Hex.RemoteConverger, hex 2.6.0); matched as `dependency resolution failed` with grep -qiF"

metrics:
  duration: 25min
  completed: 2026-10-25
---

# Phase 244 Plan 09: CR-01 lazy retry wrapper and bin/retry-network review fixes Summary

mix.exs no longer computes or guards the bin/retry-network path at project load. It goes to child shells as `RETRY_NETWORK` and is expanded quoted, so adopters and contributors whose checkout path has a space or quote can load the package again. bin/retry-network now stops on Hex's real resolution-failure text, caps backoff at 60s and documents its signal behaviour accurately.

## What changed

- **mix.exs (Task 1).** Removed `retry_network/0` and its whitespace/quote `Mix.raise`. It ran at load time through the `"test.setup"` alias string in `aliases/0`. Added `retry_network_env/1`, which returns `[{"RETRY_NETWORK", Path.join(__DIR__, "bin/retry-network")} | env]`. It is called only from task functions at run time. `"test.setup"` is now `[&test_setup_fetch/1, "test"]`. `test_setup_fetch/1` runs `bash -c '... cd examples/threadline_phoenix && "$RETRY_NETWORK" mix deps.get'` and raises `test.setup fetch failed (<status>)`. verify_bench, verify_bench_compile, verify_example and verify_hex_evaluator's `steps` now use `\"$RETRY_NETWORK\"` and pass `env: retry_network_env(...)`. verify_example and verify_hex_evaluator keep their `MIX_ENV=test` entry. No compile, ecto or test tail changed. The `package/0` `files:` list is untouched.
- **Contract test (Tasks 1-2).** `@mix_wrapper`, `wrapper_prefix/1` and `wrapper_reference/1` now match `"$RETRY_NETWORK"`, with an optional backslash before each quote. The hex-evaluator chain literal was re-derived from the new line. The nested-fetch inventory is still `{@mix_exs, true} => 5`, and all 6 nested-fetch mutation controls still fire. New block `mix.exs loads from any checkout path (CR-01)`:
  - load tests for a spaced dir, a quoted dir and a plain dir;
  - an eager-guard mutation control (red in a spaced dir, green in a plain dir);
  - `rule=alias-load-pure`: `aliases/0` contains no `#{`;
  - `rule=retry-env-pairing`: each of the 5 functions that expand `$RETRY_NETWORK` runs its `Mix.shell().cmd(` with `retry_network_env`;
  - a mutation control for each of the two rules.
- **bin/retry-network (Task 3).**
  - WR-01: the marker is `dependency resolution failed`, matched with `grep -qiF`.
  - WR-03: `RETRY_NETWORK_BASE_DELAY` above 30 is a usage error (exit 2), and each delay is clamped to 60s after jitter. The new `RETRY_NETWORK_SLEEP_BIN` seam (default `sleep`) keeps the background-and-wait shape.
  - WR-04: the header now says a signal during backoff exits at once, while a signal during an attempt is deferred until mix exits. A process-group signal reaches mix, and its 130/143 exit is not retried.

## Evidence

**Red at HEAD (Task 1, before the mix.exs change):** in the CR-01 block, 2 of the 4 tests failed (66 tests, 2 failures, 62 excluded):
- `a directory name with a space loads`: `** (Mix.Error) the checkout path ".../threadline_cr01_12/threadline checkout/bin/retry-network" contains whitespace or a quote`, raised from `mix.exs:282 retry_network/0` via `aliases/0` and `project/0`.
- `a directory name with a single quote loads`: the same error for `threadline's checkout`.

After the fix: `66 tests, 0 failures`.

**Red for the Task 2 rules:** with the pre-fix mix.exs (from `c3e2f01a`) copied in temporarily, `70 tests, 12 failures`. Among them, `rule=alias-load-pure` fired on `"cmd --cd examples/threadline_phoenix #{retry_network()} mix deps.get"`, and `rule=retry-env-pairing` fired. mix.exs was then restored with `git checkout -- mix.exs`.

**Red for Task 3:** with the HEAD bin/retry-network copied in temporarily, `73 tests, 4 failures`: BASE=31 usage error, the 60s cap, the upper-case lock marker and the real Hex marker. The new script was then restored.

**Real Hex text:** `Hex dependency resolution failed`, a literal in `Elixir.Hex.RemoteConverger.beam` from the installed hex-2.6.0 archive (`<home>/.asdf/.../.mix/archives/hex-2.6.0`), found with `strings`. Mix prints it as `** (Mix) Hex dependency resolution failed`.

**Green runs:**
- `mix test test/threadline/retry_network_contract_test.exs`: `73 tests, 0 failures`. The SIGTERM-during-backoff test takes 578.5ms and the cap test 209.9ms.
- `mix test test/threadline/retry_network_contract_test.exs test/threadline/deps_audit_gate_test.exs test/threadline/deps_health_report_test.exs`: `143 tests, 0 failures`.
- `mix help compile` exits 0, and so does `MIX_ENV=test mix compile --warnings-as-errors`.
- `mix verify.bench_compile` exits 0 (`Resolution completed`, `Generated threadline app`, no `unbound variable`, no `refusing`).
- `mix test.setup test/threadline/retry_network_contract_test.exs` exits 0 (`Resolving Hex dependencies...`, `Resolution completed in 0.022s`, then `70 tests, 0 failures`).
- `mix format --check-formatted` is clean, and `mix verify.credo` prints `5781 mods/funs, found no issues.`
- Greps: no non-comment `retry_network()` remains; `grep -c RETRY_NETWORK mix.exs` = 8; `contains whitespace or a quote` is absent from mix.exs; `grep -c 'grep -qiF' bin/retry-network` = 1; `SIGINT/SIGTERM exit 130/143 at once` = 0; `Dependency resolution failed` is absent from both files.

## Task Commits

1. **Task 1 (tracer): lazy RETRY_NETWORK wrapper and CR-01 load tests**: `23ef7071`. The tracer gate re-ran `<verify>`, which passed.
2. **Task 2: alias-load-pure and env-pairing rules**: `f91ec4c2`
3. **Task 3: WR-01, WR-03 and WR-04 in bin/retry-network**: `3c08524b`

## Deviations from Plan

None. The plan was executed as written. Two minor notes:
- Task 2's RED evidence came from running the new rules against the pre-fix mix.exs. A literal RED commit was not possible because Task 1 had already landed the fix.
- Task 1's lazy fix comment and contract-test section comment were reworded to describe the env-passed shape, as the plan asked.

## TDD Gate Compliance

Tasks 2 and 3 are `tdd="true"`. Task 1 shows RED as the recorded failing run at HEAD. Task 2 shows RED as the 12 failures against the pre-fix mix.exs. Task 3 shows RED as the 4 failures against the HEAD script. Each task's tests and implementation went into a single commit per task, following the plan's per-task commit contract. GREEN for each is listed above.

## Known Stubs

None.

## Deferred / Open

- WR-02 (denylist breadth) and WR-05 (release.yml push/token handling) stay deferred to 244-10, as the plan says.
- The full `CI=true mix ci.all` gate is plan 244-10's job.

## Self-Check: PASSED

- FOUND: mix.exs, bin/retry-network, test/threadline/retry_network_contract_test.exs
- FOUND commits: 23ef7071, f91ec4c2, 3c08524b
