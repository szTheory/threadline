# Phase 81: Retention Runtime Closure - Research

**Researched:** 2026-05-23
**Domain:** OTP application startup, retention runtime wiring, and current-tree closeout evidence
**Confidence:** HIGH

## Summary

Phase 81 is a runtime-closure phase, not a new retention-feature phase. The current tree already has the core retention pieces:

- `Threadline.Retention.purge/1` performs batched deletes and records `threadline_retention_runs`.
- `Threadline.Retention.Pruner` provides periodic scheduling, startup stale-run cleanup, advisory-lock singleton behavior, and a manual `:prune` cast path.
- `RetentionHistoryLive` already mounts at `/audit/policy/retention` and triggers the named pruner.

The missing seam is application supervision. `mix.exs` does not declare an OTP application module, so the library never starts a built-in pruner process. That leaves the retention UI and default runtime story dependent on tests, ad hoc host code, or direct mix-task invocations. The audit explicitly calls this out as the gap for RET-01 through RET-03.

**Primary recommendation:** introduce a library-owned `Threadline.Application` that conditionally starts `Threadline.Retention.Pruner` from the built-in app tree when retention is configured and an Ecto repo is available. Keep the named pruner process and advisory-lock model intact, add a small explicit trigger/status API so the LiveView can talk to the supervised runtime safely, then close Phase 76 with current-tree verification and normalized Nyquist validation artifacts.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Built-in retention runtime startup | OTP application | Retention backend | The runtime exists already, but it needs an application child-spec path to be active by default. |
| Manual prune trigger path | Operator surface | Retention runtime | The UI should continue to trigger the same named pruner process used by scheduled runs. |
| Cluster-safe singleton execution | PostgreSQL advisory lock | GenServer | The existing `pg_try_advisory_lock` approach already solves multi-node concurrency; Phase 81 should preserve it. |
| Phase 76 closure evidence | Planning artifacts | Current tree tests/code | The audit gap is partly runtime wiring and partly missing verification/validation artifacts. |

## Current Tree Findings

### Verified current strengths

- `lib/threadline/retention/pruner.ex` already contains:
  - periodic `Process.send_after/3` scheduling,
  - startup cleanup for stale `running` rows,
  - manual `handle_cast(:prune, ...)`,
  - `Repo.checkout/1` around advisory-lock acquisition and release.
- `lib/threadline/retention.ex` already inserts and updates `Threadline.Governance.RetentionRun` rows around real purge execution.
- `lib/threadline/operator_surface/live/retention_history_live.ex` already polls `threadline_retention_runs` and triggers the named pruner process rather than calling `Threadline.Retention.purge/1` directly.

### Verified gaps

- `mix.exs` has no `mod: {Threadline.Application, []}` entry, so `:threadline` has no built-in supervision tree.
- `config/config.exs` defines retention policy defaults but no runtime-startup contract such as interval/sleep/startup options.
- Retention tests and LiveView tests manually `start_supervised!` the pruner, which proves the code works in isolation but also proves the runtime is not provided by the library by default.
- Phase 76 has summaries plus a stub `76-VALIDATION.md`, but no `76-VERIFICATION.md` and no normalized closeout artifact shape.

## Recommended Runtime Shape

### Pattern 1: Conditional child-spec startup from `Threadline.Application`

Create `Threadline.Application` and set `mod: {Threadline.Application, []}` in `mix.exs`. The application should:

- read the configured repo from `Application.get_env(:threadline, :ecto_repos, [])`,
- read retention config from `Application.get_env(:threadline, :retention, [])`,
- start `Threadline.Retention.Pruner` only when retention runtime can be meaningfully configured,
- avoid crashing on capture-only adopters that do not mount Phoenix or do not enable retention.

Recommended default posture:

- If `retention.enabled` is `true` and a repo exists, start the pruner.
- If retention is disabled or no repo exists, start no retention child and log nothing or only low-noise debug information.

This preserves Threadline's optional-surface posture while making the retention runtime "just work" once the adopter opts into retention.

### Pattern 2: Explicit pruner API for UI/runtime handshake

The LiveView currently does a raw `GenServer.cast(Threadline.Retention.Pruner, :prune)`. That keeps the path aligned with scheduled pruning, but it gives the UI no clean way to reason about runtime availability.

Recommended improvement:

- add a small public API such as `Threadline.Retention.Pruner.trigger/0` and optionally `started?/0`,
- keep the implementation routed to the same named process,
- have the LiveView use the API so tests can assert the supervised runtime path rather than a fire-and-forget raw cast.

### Pattern 3: Repaired-tree evidence closure for Phase 76

Do not treat old 2024 summaries as closure. Phase 81 should create:

- `76-VERIFICATION.md` with current-tree proof for:
  - built-in supervision,
  - manual trigger using the named runtime path,
  - retention history observing the same runtime path,
  - targeted tests proving RET-01 through RET-03;
- `76-VALIDATION.md` rewritten into the Nyquist frontmatter/per-task map shape used by repaired closeout phases.

## Common Pitfalls

### Pitfall 1: Always starting the pruner even when retention is disabled

This would create a default background process that immediately no-ops forever. It is not fatal, but it weakens the library's optional-runtime posture and complicates tests. Prefer conditional startup tied to retention enablement and repo presence.

### Pitfall 2: Fixing the UI with a direct `Threadline.Retention.purge/1` bypass

That would satisfy the button superficially while violating the locked phase decision that manual and scheduled pruning share the same supervised runtime path.

### Pitfall 3: Breaking test isolation with a new application supervisor

Once `:threadline` owns a named pruner, tests that manually start the same process can collide. The execution plan must update tests/configuration so they either rely on the application-owned child or explicitly disable auto-start in the cases that need manual control.

### Pitfall 4: Closing RET requirements with docs only

The audit gap is real runtime behavior plus missing artifacts. The verification report must be based on targeted runtime and UI tests on the repaired tree, not just prose copied from older summaries.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Quick run | `mix test test/threadline/retention/pruner_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs` |
| Phase gate | `mix test test/threadline/retention/pruner_test.exs test/threadline/retention_test.exs test/threadline/operator_surface/live/retention_history_live_test.exs --max-failures 1` |

### Requirement Map

| Req ID | Runtime truth to prove | Expected evidence |
|--------|------------------------|-------------------|
| RET-01 | Built-in supervised startup runs the pruner on the default stack | application/runtime tests plus current-tree verification report |
| RET-02 | Purge runs still create and finalize `threadline_retention_runs` rows through that runtime path | retention tests plus verification artifact |
| RET-03 | `/audit/policy/retention` manual trigger and history page use the supervised runtime path | LiveView test plus verification artifact |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/v1.20-MILESTONE-AUDIT.md`
- `.planning/phases/81-retention-runtime-closure/81-CONTEXT.md`
- `.planning/phases/76-batched-retention-and-ui/76-RESEARCH.md`
- `.planning/phases/76-batched-retention-and-ui/76-01-SUMMARY.md`
- `.planning/phases/76-batched-retention-and-ui/76-02-SUMMARY.md`
- `mix.exs`
- `config/config.exs`
- `config/test.exs`
- `lib/threadline/retention.ex`
- `lib/threadline/retention/pruner.ex`
- `lib/threadline/operator_surface/live/retention_history_live.ex`
- `test/threadline/retention/pruner_test.exs`
- `test/threadline/operator_surface/live/retention_history_live_test.exs`

## RESEARCH COMPLETE
