# Phase 225: Suite Baseline and Partitioned CI - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-30
**Phase:** 225-suite-baseline-and-partitioned-ci
**Areas discussed:** Partition topology, fail-closed gate and Flake Detection, async telemetry tests, baseline protocol
**Mode:** advisor. Four parallel researchers ran, then one roll-up confirm in text mode.

---

## Partition topology

| Option | Description | Selected |
|--------|-------------|----------|
| In-job concurrency | N background `mix test --partitions N` processes inside each `verify-test` lane, one DB per partition | ✓ |
| Matrix fan-out | A `partition` matrix axis. It repeats setup per shard, risks the ≤10% minutes cap, and changes the pinned check names | fallback |

**User's choice:** accepted the recommended set (N=3, confirmed by `--slowest-modules`; all three lanes; `threadline_test#{MIX_TEST_PARTITION}`).
**Notes:** The orchestrator added D-06 (compile once before fan-out) and D-07 (the coverage step
depends on the unsuffixed DB). The topology researcher had missed both. The orchestrator
confirmed that `--slowest-modules` exists on 1.17.3; the baseline researcher had wrongly said it
does not.

## Fail-closed gate and Flake Detection

| Option | Description | Selected |
|--------|-------------|----------|
| Committed `bin/ci-test-partitions` with a runtime `--self-test` plus topology-test shape mutations | Covers both runtime behavior and shape | ✓ |
| Inline `run:` block with a text contract only | Doesn't catch the `wait` exit-code bug | |
| Flake Detection unpartitioned, budget re-derived | Keeps the whole-suite reshuffle on every repeat | ✓ |
| Partition Flake Detection | Weakens detection of order-dependent flakes | |

**User's choice:** accepted.

## Async telemetry tests (SUITE-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow to 3 operator-surface files | The other 7 are blocked by DB writes or app env; they are deferred with reasons | ✓ |
| Full scope with refactor | Config-passing refactor plus DB isolation for 7 files | |
| Isolation: `:telemetry_test` ref-tagging (researcher's pick) | Rejected by the orchestrator: every handler still receives foreign emissions | |
| Isolation: emitter-pid filter helper | Forwards only events emitted by the test process or its `$callers` | ✓ |

**User's choice:** accepted (narrowing is a scope decision made by the maintainer).

## Baseline protocol (SUITE-01)

| Option | Description | Selected |
|--------|-------------|----------|
| CI "before" = run 36730596489 at dd780e68, step-level duration; local detail at 225's start | Consistent with 224; attributes the gain cleanly | ✓ |
| Re-measure a worktree at dd780e68 | Duplicates 224's noisy local runs | |
| Billed minutes from the timing API | Returns 0 on public repos (re-verified) | |
| Proxy of ceil(job seconds / 60) from one shared phase-local script | Same formula before and after | ✓ |
| Copy check-citations.py (4× precedent) | No new CI job | ✓ |

**User's choice:** accepted.

## Claude's Discretion

- Internals of the script, where the self-test step lives, how D-07 is fixed, the commit split, and
  doc wording.

## Deferred Ideas

- Async conversion for the 7 serial files blocked by DB or app-env state.
- Partitioning Flake Detection.
- Matrix fan-out (fallback only).
