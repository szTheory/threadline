---
phase: 203-real-gates
plan: 02
subsystem: capture / CI gates
status: complete
tags: [gate-04, xref, compiler-suppression, contract-test, ci]
requires: [203-01]
provides:
  - Threadline.NoWarnUndefinedContractTest (GATE-04 source + elixirc_options scan)
  - mix verify.xref_cycles (compile-connected cycle gate, in ci.all and CI verify-test)
affects: [203-03, 203-06]
tech-stack:
  added: []
  patterns:
    - "Delete-not-relocate pin: scan lib/** AND project elixirc_options"
    - "Runtime-assembled needle so the guard never carries the literal it forbids"
key-files:
  created:
    - test/threadline/no_warn_undefined_contract_test.exs
  modified:
    - lib/threadline/capture/audit_transaction.ex
    - mix.exs
    - .github/workflows/ci.yml
    - test/threadline/ci_topology_contract_test.exs
    - CONTRIBUTING.md
    - guides/configuration-and-commands.md
    - guides/evaluating-threadline.md
    - guides/adoption-pilot-backlog.md
decisions:
  - "GATE-04 'cycle resolved' = zero compile-connected xref cycles + zero no_warn_undefined; the runtime AuditTransaction<->AuditAction association edge stays by design (D-18)"
  - "verify.xref_cycles alias is formatter-wrapped across three lines (mix format line length), so the plan's single-line grep acceptance is satisfied by the topology contract's separate key + command pins instead"
metrics:
  duration: 4min
  completed: 2026-09-22
  tasks: 2
  files: 9
commits: 6
plan_head_before: 88cc785e35210c1e3b0e88c5e7a00fdc218fac9b
actuals:
  tokens: 3600
  tasks: 2
  commits: 6
---

# Phase 203 Plan 02: Delete no_warn_undefined papering + compile-connected cycle gate Summary

Deleted the no-op `@compile {:no_warn_undefined, Threadline.Semantics.AuditAction}` from `AuditTransaction`, pinned its absence (lib and `elixirc_options`) with a contract test, and added `mix verify.xref_cycles` (`xref graph --format cycles --label compile-connected --fail-above 0`) to `ci.all` and the CI `verify-test` job on both lanes.

Plan base SHA: `88cc785e35210c1e3b0e88c5e7a00fdc218fac9b` (also stored in the git dir as `gsd-203-02-base`).

## Tasks

| Task | Name | Commits | Files |
|------|------|---------|-------|
| 1 | Delete suppression and pin its absence | 78f23c99 (deletion, 1 line), 73e1f37c (contract test) | audit_transaction.ex, no_warn_undefined_contract_test.exs |
| 2 | Wire cycle gate into ci.all + verify-test | 14e1d799 (mix.exs), 71f414d5 (ci.yml), f9cd10f0 (topology test), 39ca9f3d (docs) | mix.exs, ci.yml, ci_topology_contract_test.exs, 4 docs |

## Verification

- TDD RED: contract test failed naming `lib/threadline/capture/audit_transaction.ex` before the deletion; GREEN after.
- `mix compile --force --warnings-as-errors`: clean (106 files, 0 warnings).
- `mix test` no_warn_undefined + investigation + audit_transaction + query: 83 tests, 0 failures (`:action` preload intact).
- `mix verify.xref_cycles`: "No cycles found", exit 0.
- ci_topology + ci_workflow_parity + optional_deps contracts: 34 tests, 0 failures.
- `mix verify.doc_contract`: 134 tests, 0 failures; adoption_pilot + evaluating_threadline doc contracts: 13 tests, 0 failures.
- `mix verify.format`: clean.
- Full `mix verify.test`: 1699 tests, 0 failures, 1 excluded (pgbouncer_topology).
- Credo full-default `--strict --config-file deps/credo/.credo.exs`: 484 (unchanged); new contract test file has 0 findings.
- CI job keys: base..HEAD diff of ci.yml adds/removes no job key (fail-closed check exit 0).
- Backstop (unverified locally): Elixir 1.15 / OTP 26 min lane — `compile --warnings-as-errors` and the xref flags are proven only by the CI `verify-test (min)` lane (A-GATE-04).

## Runtime cycles (informational, D-18)

`mix xref graph --format cycles` (all labels) reports 3 runtime cycles of length 2, none compile-connected:

- `lib/threadline/investigation.ex` <-> `lib/threadline.ex`
- `lib/threadline/capture/audit_transaction.ex` <-> `lib/threadline/semantics/audit_action.ex` (the accepted `belongs_to :action` / `has_many :transactions` edge)
- `lib/threadline/capture/audit_transaction.ex` <-> `lib/threadline/capture/audit_change.ex`

## Deviations from Plan

**1. [Rule 3 - Blocking] `verify.xref_cycles` alias formatted across three lines**
- **Found during:** Task 2
- **Issue:** the single-line alias exceeds the formatter line length; `mix verify.format` would fail. The plan's acceptance grep for the one-line form therefore prints `0`.
- **Fix:** accepted `mix format` output (key and command string on separate lines). The topology contract pins the key and exact command separately, so the gate's intent holds.
- **Commit:** 14e1d799

Otherwise executed as written.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: test/threadline/no_warn_undefined_contract_test.exs
- FOUND commits: 78f23c99, 73e1f37c, 14e1d799, 71f414d5, f9cd10f0, 39ca9f3d
