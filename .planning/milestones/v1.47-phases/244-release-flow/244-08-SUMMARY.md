---
phase: 244-release-flow
plan: 08
subsystem: ci
tags: [ci, hex, mix-lock, supply-chain, gap-closure, docs]
status: complete

requires:
  - "244-05: bin/verify-deps-audit MIN_HEX, the Hex 2.6.0 pin and CONTRIBUTING `### Why Hex is pinned in CI`"
  - "244-07: the isolated REL-04 reproduction (cold vs warm deps/, Hex 2.5.1 and 2.6.0 agree)"
provides:
  - "bin/verify-lock-hygiene: static mix.lock check, exit 0 clean / 1 empty build-manager list / 2 usage or malformed"
  - "bin/verify-deps-audit runs the hygiene check per directory before `deps.get --check-locked`, aggregated into FAILURES"
  - "describe \"lock hygiene (REL-04)\" in deps_audit_gate_test.exs: a3301bed mutation control, f7fdcaca control, warm-fetch masking, live tree, fail-closed edges"
  - "CONTRIBUTING.md records the observed deps/-state mechanism, the pin as toolchain determinism and the hygiene check as the prevention"
affects: [244-09, 244-10, 244-VERIFICATION, 245]

actuals:
  tokens: 5300
  tasks: 3
  commits: 3
plan_head_before: 493a5b0e746f5f84a48e2b22be2401333b6b0eac
plan_head_after: 80c320d02a357397f25aa953cda94575449bf14b

tech-stack:
  added: []
  patterns:
    - "parse an untrusted lock with Code.string_to_quoted/2 (emit_warnings: false), walk the AST, never evaluate"
    - "a static check inside a fetch gate, so cache state cannot change the verdict"

key-files:
  created:
    - bin/verify-lock-hygiene
  modified:
    - bin/verify-deps-audit
    - test/threadline/deps_audit_gate_test.exs
    - CONTRIBUTING.md
    - test/threadline/hex_pin_contract_test.exs
    - .github/workflows/ci.yml

decisions:
  - "REL-04 prevention is a static lock check (bin/verify-lock-hygiene) run by bin/verify-deps-audit, not the Hex pin; the pin stays as toolchain determinism"
  - "A hygiene failure does not skip the directory's fetch and audit, so one gate run reports every failure"

metrics:
  duration: "about 25 min"
  completed: 2026-10-25
---

# Phase 244 Plan 08: REL-04 lock hygiene Summary

A `[]` build-manager list on any `:hex` lock entry now fails `mix verify.deps_audit` locally, whatever the state of deps/. The recorded 1.1.0 cause now matches 244-07's evidence: deps/ state, not Hex version.

## What was built

- **`bin/verify-lock-hygiene`** (Elixir script, mode 0755). It reads each named lock, parses it with `Code.string_to_quoted/2` and walks the map literal. A `:hex` entry whose element 4 is `[]` is a violation (exit 1, one `FAIL <path>: :hex entry <name> <version> has an empty build-manager list ([])` line, then one remediation line). Empty or whitespace-only files count as zero entries. No arguments, an unreadable file, a parse error, a non-map top level, a `:hex` entry with fewer than 5 elements or a non-list manager slot all exit 2. Non-`:hex` entries are skipped. It never fetches and never reads deps/. All command names in its messages sit in backticks, so the nested-fetch detector in retry_network_contract_test.exs ignores them.
- **`bin/verify-deps-audit`** runs it per directory, after the missing-file check and before the fetch. A non-zero status prints the output and adds `FAIL <dir>: lock hygiene exited <status> (...)`. The directory still runs its fetch and audit. `MIN_HEX`, the floor check and `--self-test` are unchanged.
- **Prose**: CONTRIBUTING.md "Why Hex is pinned in CI" now opens with the pin as toolchain determinism, gives the cold/warm deps/ mechanism with Hex 2.5.1 and 2.6.0 behaving the same, keeps the "what wrote `[]` was not reproduced" sentence, and adds a prevention paragraph with the local command. The `MIN_HEX` bullet no longer says a different Hex would judge the lock differently. Comment-only matching edits in ci.yml, the hex_pin_contract_test.exs moduledoc, the deps_audit_gate_test.exs floor-test comment and the `MIN_HEX` comment.

## Evidence

- Live tree: `bin/verify-lock-hygiene mix.lock bench/mix.lock examples/threadline_phoenix/mix.lock test/fixtures/deps_audit/vulnerable_lock/mix.lock` printed `verify-lock-hygiene: 4 lock(s), 134 :hex entries clean`, exit 0. No arguments: exit 2.
- Real gate: `mix verify.deps_audit` printed `verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0)`, exit 0, with no `lock hygiene` line.
- `grep -v '^[[:space:]]*#' bin/verify-lock-hygiene | grep -c 'eval_'` printed 0. No tracked mix.lock changed.
- Negative prose grep at HEAD before editing: 5 matches (CONTRIBUTING.md:727, :739, ci.yml:184, :185, hex_pin_contract_test.exs:7). After: none. `git diff` of ci.yml touches comment lines only.

## Tests

| Run | Result |
|-----|--------|
| Task 1 RED: `mix test test/threadline/deps_audit_gate_test.exs`, before the script existed | `34 tests, 4 failures` (3 `:enoent` on the missing script, 1 gate exit 0 on the `[]` lock) |
| Task 1 GREEN: same file | `34 tests, 0 failures` |
| Task 2: deps_audit_gate + deps_audit_contract + retry_network_contract | `114 tests, 0 failures` |
| Task 3: hex_pin, deps_audit_contract, deps_health_doc, ci_workflow_parity, deps_audit_gate, retry_network_contract | `205 tests, 0 failures` |
| Every test file that reads CONTRIBUTING.md (19 files) | `313 tests, 0 failures` |
| `mix format --check-formatted` | exit 0 |
| `mix verify.credo` | `5774 mods/funs, found no issues.` |

The 6-entry inventory assertion in retry_network_contract_test.exs passed unchanged.

## TDD Gate Compliance

Task 1 (tracer) ran red before the script existed (4 failures, above) and green after. Task 2's tests were written after Task 1's implementation, so they passed on first run; they cover behaviour Task 1 already implemented (fail-closed edges, live tree). No implementation change was needed for Task 2. The tracer feedback gate re-ran Task 1's automated verify and it passed before expansion.

## Deviations from Plan

**1. [Rule 1 - Bug] Gate-test assertion text**
- **Found during:** Task 1
- **Issue:** The plan's expected `FAIL one: lock hygiene` assumed `$d` is the dir basename. The gate prints the argument as given, and the tests pass absolute paths.
- **Fix:** The test asserts `FAIL #{d1}: lock hygiene`.
- **Commit:** 01c1a7c7

**2. [Rule 1 - Bug] Parser warnings flooded the output**
- **Found during:** Task 1
- **Issue:** `Code.string_to_quoted/2` warns on every quoted keyword key in a lock (about 90 KB on the root lock).
- **Fix:** Pass `emit_warnings: false`, as Mix does when it reads a lock.
- **Commit:** 01c1a7c7

**3. [Rule 2 - Fail closed] Two-element `:hex` tuple**
- **Found during:** Task 1
- **Issue:** A 2-tuple is a raw tuple in the AST, not `{:{}, _, elems}`, so `{:hex, :x}` would have been skipped as a non-`:hex` entry.
- **Fix:** A dedicated clause exits 2. Covered by a Task 2 test.
- **Commit:** 01c1a7c7

## Known Stubs

None.

## Open

- `test/partition_weights.txt` was not touched. deps_audit_gate_test.exs gained about 18 tests (roughly 5 s more wall time, async). 244-10's full `CI=true mix ci.all` run will show whether its partition needs a reweigh.
- REL-04's requirement text still reads "If Hex version drift is the cause, CI pins the Hex version". REQUIREMENTS.md was not edited here. The verifier decides whether to re-word it.

## Self-Check: PASSED

- FOUND: bin/verify-lock-hygiene (mode 0755)
- FOUND: 01c1a7c7, b8726ac8, 80c320d0 (all ancestors of HEAD)
