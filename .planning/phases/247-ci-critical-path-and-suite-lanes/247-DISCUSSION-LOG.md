# Phase 247: CI critical path and suite lanes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-26
**Phase:** 247-ci-critical-path-and-suite-lanes
**Areas discussed:** Sequencing/landing, CI-01 slow specs, CI-02 browser split, CI-03 lanes + partitions, CI-04 hang detection

Method: research-then-recommend (CLAUDE.md). Three parallel researchers (CI-01/02, CI-03, CI-04) plus an orchestrator cross-cutting and adversarial pass; one coherent recommendation set presented with a single confirm.

---

## Adversarial corrections applied during synthesis

- CI-04 research proposed a new default-excluded `:hang_watchdog` tag — rejected: `zero_skips_contract_test` allows exactly two exclude gates. Replaced with a normal default test over a runtime-built sandbox.
- CI-04 research proposed a committed `test/fixtures/hang/hang_test.exs` — rejected: plain `mix test` would discover it under `test/`.
- CI-03 timing formatter and CI-04 hang watchdog merged into one CI-only formatter module.
- Landing v1.47 to main surfaced as a forced prerequisite (gates are measured on main; 160 commits unlanded).

## Confirmation

| Option | Description | Selected |
|--------|-------------|----------|
| Lock it (Recommended) | Write CONTEXT.md with the set, incl. landing inside 247 under the standing merge grant | ✓ |
| Lock, but no landing in 247 | Landing 244–246 becomes a separate step | |
| Adjust something | Change a decision first | |

**User's choice:** Lock it (Recommended)

## Alternatives considered (per cluster)

- CI-01: custom reporter / `reportSlowTests` / `--reporter` flag — rejected for JSON-report reuse via `tsx` script.
- CI-02: separate jobs / `--shard` / blob reporter + `merge-reports` / per-leg reconciliation — rejected for same-id matrix + JSON fan-in.
- CI-03: path convention / manifest / ExUnit env exclude / one-off CI weights job / lowering N — rejected for `@moduletag :repo_contract` + script-level filter + CI-timing ingest.
- CI-04: `--trace` / SIGQUIT crash dump / GNU `timeout` / relying on job timeout — rejected for in-VM formatter watchdog + portable bash watchdog.

## Claude's Discretion

Names of new modules/jobs/artifacts, fan-in Node strategy, final timeouts after data, measurement script location, optional `with_timeout/2` helper.

## Deferred Ideas

Playwright workers > 1; rebalancing current-only steps; change-aware lanes (SEED-006); `Mix.shell().cmd` signal forwarding.
