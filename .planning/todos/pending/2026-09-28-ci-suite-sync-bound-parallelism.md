---
created: 2026-09-28T01:30:00Z
title: Cut CI wall clock by making the test suite less sync-bound
area: ci
files:
  - test/test_helper.exs
  - .github/workflows/ci.yml
  - .github/workflows/flake-detection.yml
  - .planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md
---

## Problem

Measured on Flake Detection run 36359135268 (land branch at 0d000785): one full
`mix test` pass takes about 209 s on a hosted runner, and **about 191 s of it is
synchronous** (async about 17 s). That is roughly 91% serial, across 2460 tests.
82 `async: false` declarations are spread across the test tree, and the project
has no SQL Sandbox by design, so DB-touching tests serialize.

That serial core is paid on every lane that runs the suite: the ci.yml test job,
each of Flake Detection's 13 passes, and each ci.all rehearsal. It is also why
218-05's 15-repeat budget overran: it was sized at about 165 s per repeat, and the
real figure is about 209 s.

The maintainer asked for efficient, non-flaky CI as a first-class goal
(2026-09-28), and wants low-hanging fruit that reduces Actions runtime.

## Candidate levers (measure before adopting; each with a cited run)

1. **Serial-core audit.** Classify every `async: false` module by *why* it is
   serial: global DB state, telemetry handlers, Application env, named
   processes. Many can go async with per-test schemas or prefixes, unique
   telemetry handler ids, or `start_supervised`.
2. **Partition the serial core across a matrix** (`mix test --partitions N` with
   `MIX_TEST_PARTITION`). Each partition needs its own DB (the repo is already
   `threadline_test#{MIX_TEST_PARTITION}`-shaped?). Check the wall-clock gain
   against the extra runner-minutes.
3. **Slowest-test report.** `mix test --slowest 25` on CI to find outliers.
4. **Cold first run (268 s vs 209 s).** A deps-only `_build` cache is
   Phase 219. Confirm 219 also removes this cold penalty.
5. Feed the result into Phase 222 (SEED-006 change-aware lanes) and Phase 221
   (fastest-to-red ordering) rather than duplicating them.

## Where it fits

Candidate to fold into Phase 219's measurement, or as a new phase after 222 in
v1.43 if the serial-core audit shows a large win. Otherwise it is a seed for the
next milestone. Keep the "honest default tests" rule (CLAUDE.md): nothing
leaves default `mix test` silently.
