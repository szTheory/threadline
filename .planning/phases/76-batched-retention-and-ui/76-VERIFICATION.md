---
phase: 76-batched-retention-and-ui
verified: 2026-05-23T14:26:00Z
status: passed
score: 4/4 truths verified
overrides_applied: 1
---

# Phase 76: Batched Retention & UI — Verification Report

**Phase Goal:** Prove on the current tree that retention pruning now runs through a built-in supervised runtime path, records real execution in `threadline_retention_runs`, and exposes that same path through the Retention History LiveView.

**Verified:** 2026-05-23T14:26:00Z
**Status:** passed
**Re-verification:** Yes — verified after Phase 81 repaired the missing supervised-runtime path and current-tree closeout evidence

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `:threadline` now declares `mod: {Threadline.Application, []}` and the application starts `Threadline.Retention.Pruner` from the built-in supervision tree when retention is enabled and an Ecto repo is configured. | ✓ VERIFIED | `mix.exs`; `lib/threadline/application.ex`; `test/threadline/retention/pruner_test.exs` |
| 2 | The named pruner still owns the scheduled purge path, including interval/sleep runtime options and PostgreSQL advisory-lock singleton protection. | ✓ VERIFIED | `lib/threadline/retention/pruner.ex`; `test/threadline/retention/pruner_test.exs` |
| 3 | Real purge execution still writes completed `threadline_retention_runs` rows with deleted-count and duration metadata on the repaired runtime path. | ✓ VERIFIED | `lib/threadline/retention.ex`; `test/threadline/retention_test.exs` |
| 4 | `RetentionHistoryLive` now triggers pruning through `Threadline.Retention.Pruner.trigger/0`, so the manual "Run Pruning Batch" CTA uses the same supervised runtime path as scheduled pruning. | ✓ VERIFIED | `lib/threadline/operator_surface/live/retention_history_live.ex`; `test/threadline/operator_surface/live/retention_history_live_test.exs` |

**Score:** 4/4 truths verified

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| RET-01 | 76-01, 81-01 | Implement a batched, autovacuum-aware retention pruner that runs on the default library path. | ✓ SATISFIED | `mix.exs`; `lib/threadline/application.ex`; `lib/threadline/retention/pruner.ex`; `test/threadline/retention/pruner_test.exs` |
| RET-02 | 76-01, 81-01 | Track retention runs in `threadline_retention_runs` with completion metadata from real execution. | ✓ SATISFIED | `lib/threadline/retention.ex`; `test/threadline/retention_test.exs` |
| RET-03 | 76-02, 81-01 | Provide a Retention History LiveView that observes and triggers the repaired supervised runtime path. | ✓ SATISFIED | `lib/threadline/operator_surface/live/retention_history_live.ex`; `test/threadline/operator_surface/live/retention_history_live_test.exs` |

### Commands Run On Final Tree

1. Built-in runtime wiring and trigger-path proof

```bash
rg -n 'mod: \{Threadline.Application|Threadline.Retention.Pruner|interval_ms|sleep_ms|def trigger|started\?' \
  mix.exs \
  lib/threadline/application.ex \
  lib/threadline/retention/pruner.ex
```

Result: PASS

2. Retention History runtime-path proof

```bash
rg -n 'Run Pruning Batch|Pruner.trigger|Retention History|threadline_retention_runs' \
  lib/threadline/operator_surface/live/retention_history_live.ex \
  test/threadline/operator_surface/live/retention_history_live_test.exs \
  test/threadline/retention_test.exs
```

Result: PASS

3. Targeted repaired-runtime tests

```bash
mix test test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1
```

Result: PASS

### Verification Notes

- This artifact intentionally replaces the earlier summary-only truth surface. The current proof is the repaired tree itself: `Threadline.Application` owns the pruner startup, `Threadline.Retention.Pruner` remains the singleton runtime, and the LiveView button talks to that runtime explicitly.
- The closeout language stays inside Phase 81's repair boundary. It does not claim any saved-view, export-lifecycle, Oban, or S3 closure owned by Phases 82-84.

### Gaps Summary

No blocking gaps remain for RET-01 through RET-03 on the current tree. Later milestone blockers remain outside Phase 76's retention scope and are still owned by Phases 82-84.
