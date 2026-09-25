---
phase: quick-260924-taj
plan: 01
subsystem: test
tags: [credo, gate, test-hygiene]
requires: []
provides: [green-credo-strict]
affects: [verify-credo CI job]
tech-stack:
  added: []
  patterns: [top-of-module alias for nested Mix task modules]
key-files:
  created: []
  modified:
    - test/threadline/capture/trigger_rerun_test.exs
decisions:
  - "Placed `alias Mix.Tasks.Threadline.Gen.Triggers` above `alias Threadline.Capture.{...}` to keep aliases alphabetical"
metrics:
  duration: ~1m
  completed: 2026-09-24
status: complete
requirements: [GATE-01, GATE-02]
actuals:
  tokens: 400
  tasks: 1
  commits: 1
plan_head_before: 0700557f92aa267fa1960dde06a98f0596d66727
---

# Quick 260924-taj: Alias Gen.Triggers in trigger rerun test Summary

Fixed the two `Credo.Check.Design.AliasUsage` findings that made `mix credo --strict` exit 2. The test now has `alias Mix.Tasks.Threadline.Gen.Triggers` at the top, and both call sites use `Triggers.run(...)`. Test behavior is unchanged.

## Pre-change credo (live finding list)

`MIX_ENV=test mix credo --strict` exited 2 with exactly 2 findings, both in this file. There were no findings in any other file:
- `test/threadline/capture/trigger_rerun_test.exs:279:25` (in `generate!`)
- `test/threadline/capture/trigger_rerun_test.exs:219:11` (in `assert_raise`)

## Verification (after the change)

| Command | Result | Exit |
|---|---|---|
| `mix credo --strict` | "3525 mods/funs, found no issues." | 0 |
| `mix verify.credo` | "3525 mods/funs, found no issues." | 0 |
| `mix format --check-formatted` | clean | 0 |
| `mix test test/threadline/capture/trigger_rerun_test.exs` | "9 tests, 0 failures" | 0 |
| Plan verify #2 (grep counts 0/2, commit subject, single-file commit) | passed | 0 |

All commands ran with `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test`.

## Commits

- `c960cefa` test: alias Gen.Triggers in trigger rerun test (touches only `test/threadline/capture/trigger_rerun_test.exs`)

## Deviations from Plan

None. The plan was executed as written.

Note: `.planning/WINDOWS.md` and `.planning/config.json` were already modified in the working tree before this task started. They were not touched or staged.

## Self-Check: PASSED

- FOUND: test/threadline/capture/trigger_rerun_test.exs
- FOUND: c960cefa
