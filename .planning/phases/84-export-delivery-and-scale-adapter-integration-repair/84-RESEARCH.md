# Phase 84: Export Delivery & Scale Adapter Integration Repair - Research

**Researched:** 2026-05-24
**Domain:** actor-owned export delivery, adapter-backed download resolution, and truthful Oban/S3 integration proof
**Confidence:** HIGH

## Summary

Phase 84 is the final runtime-closure phase for the v1.20 export lane. Phase 83 repaired the built-in queue, lifecycle, and cleanup path, and Phase 82 repaired actor/session handoff on the operator surface. The remaining gaps are the adopter-facing ones the milestone audit still names explicitly:

- `ExportController.download/2` authorizes by actor and job ID, but only knows how to serve a local filesystem path through `storage_adapter.path/1`.
- `Threadline.Storage.S3` correctly answers `{:error, :not_local}` for `path/1`, so completed S3-backed exports cannot be downloaded through the operator surface even though the adapter exposes `download_url/2`.
- `ExportStatusLive` still exposes a partial UI contract: the action label is `Download`, there is no `Expires At` column, and non-ready rows do not reflect the locked Phase 84 operator-surface copy.
- `Threadline.ExportQueue.Oban` and `Threadline.Storage.S3` prove isolated module behavior, but the current tree still lacks truthful startup/config validation and real integration proof for configured adapter flows.

**Primary recommendation:** keep one actor-owned Threadline download route keyed by export job ID, resolve delivery only after authorization, use a small delivery-resolution seam that chooses `send_file` for local storage and redirect-based `download_url/2` for remote storage, validate configured adapters at startup only for static truths they can honestly know, and finish by rewriting the active evidence surface so Phase 79 moves from “implemented” to “satisfied” on the repaired tree.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Actor-owned download authorization | `ExportController` | `Auth` / session handoff | Authorization must stay above backend-specific delivery so the UI contract remains storage-agnostic. |
| Delivery resolution | dedicated export-delivery seam | storage adapters | Local-vs-remote branching is a delivery concern, not a LiveView concern. |
| Remote URL generation | storage adapter | controller | Adapters already own backend-native URL generation via `download_url/2`. |
| Startup validation of configured adapters | `Threadline.Application` | adapter `init/1` callbacks | The library should fail fast for static config/dependency truth without pretending to own host runtime liveness. |
| Oban runtime ownership | host app supervision | Threadline adapter | Threadline integrates with Oban but must not auto-start host infrastructure. |
| Final requirement/evidence closure | planning artifacts | targeted tests/docs | Phase 79 and the milestone audit must reflect current-tree truth after the runtime repair lands. |

## Current Tree Findings

### Verified strengths

- `TimelineLive` already persists actor-owned background export jobs and now fails enqueue requests truthfully after the Phase 83 repair.
- `ExportJob` already contains the lifecycle fields Phase 84 needs for truthful status and expiry display: `started_at`, `completed_at`, `expires_at`, and `error_message`.
- `Threadline.Storage` already exposes the right primitives for the split delivery posture: `path/1` for local backends and `download_url/2` for adapter-backed delivery.
- `examples/threadline_phoenix/lib/threadline_phoenix/application.ex` already demonstrates the correct ownership model for Oban: the host app supervises it.

### Verified gaps

- `lib/threadline/operator_surface/controllers/export_controller.ex` returns `404` whenever the configured storage backend cannot produce a local path, which makes S3-backed completed exports undeliverable.
- `lib/threadline/storage/local.ex` still leaks route knowledge through `download_url/2`, but the actual operator route decision belongs above the storage layer.
- `lib/threadline/operator_surface/live/export_status_live.ex` does not yet match the locked Phase 84 UI contract for button label, placeholder text, status/error treatment, or `Expires At` visibility.
- `lib/threadline/application.ex` starts the built-in runtime children but does not yet validate the configured `storage_adapter` or `export_queue_adapter` through their `init/1` contracts on startup.
- `test/threadline/export_queue/oban_test.exs` and `test/threadline/storage/s3_test.exs` still prove only isolated adapter behavior, not the configured integration posture or stable failure messages expected by adopters.

## Recommended Runtime Shape

### Pattern 1: Keep one canonical download route and branch after auth

`ExportController.download/2` already owns the correct actor-scoped route boundary. Keep that route, but replace the local-only `path/1` assumption with a delivery resolver that runs after:

1. UUID validation,
2. actor ownership lookup,
3. terminal/completed-state checks.

Recommended result shape:

- local storage: resolve `path/1`, then `send_file/3`;
- remote storage: resolve `download_url/2`, then redirect;
- unavailable artifact: return a truthful storage-agnostic failure response.

This preserves one operator affordance while letting each backend stay backend-native.

### Pattern 2: Move operator-route knowledge out of storage adapters

`Threadline.Storage.Local.download_url/2` currently returns a Threadline route string. That is the wrong ownership layer because adapters should describe backend-native delivery, not fabricate operator-surface paths. The repaired shape should make local delivery happen inside the controller path after auth, while remote adapters keep ownership of presigned/external URLs.

### Pattern 3: Validate configured adapters at startup for static truths only

Phase 79 added `init/1`; Phase 84 should finally invoke it from the library-owned startup path. Recommended behavior:

- when a repo exists, call the configured `storage_adapter.init/1` and `export_queue_adapter.init/1` with their config;
- allow those callbacks to verify dependency presence, required static config, and obvious malformed options;
- do not attempt to prove Oban supervision or AWS/network reachability during startup.

This gives adopters fast, actionable failure for configuration mistakes without stealing host ownership.

### Pattern 4: Make Oban integration truthful instead of magical

`Threadline.ExportQueue.Oban` should support explicit host-configured targeting such as `oban_name` and queue name, then normalize runtime failures into stable supportable error messages. Threadline should prove the configured enqueue path works when the host app actually starts Oban, but it should not start Oban from `Threadline.Application`.

### Pattern 5: Close the evidence loop on the repaired tree

Phase 84 is the first phase that can honestly mark `EXP-03`, `ADAPT-01`, and `ADAPT-02` as satisfied. The active evidence surface should therefore:

- author a Phase 84 verification report for end-to-end delivery and adapter startup truth,
- upgrade `79-VERIFICATION.md` and `79-VALIDATION.md` from “implemented but unsatisfied” to repaired final-tree closure,
- keep the milestone wording precise enough that future audits can recompute the satisfied state from tests and code rather than from summaries alone.

## Common Pitfalls

### Pitfall 1: Rendering backend-native URLs directly into LiveView

That leaks bearer URLs into HTML, creates expiry races, and breaks the storage-agnostic UI contract. Resolve remote URLs only on click inside the controller.

### Pitfall 2: Treating `download_url/2` as a replacement for authorization

The route and actor ownership checks still belong to Threadline. Adapters should only decide how a completed, already-authorized export is delivered.

### Pitfall 3: Using startup validation to claim host runtime ownership

Failing on a missing dependency or bucket config is correct. Failing because Oban has not started yet or because AWS is unreachable at boot would be a false ownership boundary.

### Pitfall 4: Closing ADAPT requirements with unit tests alone

The repaired final tree must prove configured-path behavior, not just isolated adapter callbacks. Mock-only tests are not enough for final satisfaction claims.

### Pitfall 5: Updating milestone evidence without rewriting the old Phase 79 truth

If Phase 84 lands but `79-VERIFICATION.md` still says “implemented, not satisfied,” the active planning surface becomes internally contradictory again.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Targeted ExUnit controller, LiveView, adapter, docs, and planning-artifact verification |
| Quick run | `mix test test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/s3_test.exs --max-failures 1` |
| Phase gate | `mix ci.all` |

### Requirement Map

| Req ID | Runtime truth to prove | Expected evidence |
|--------|------------------------|-------------------|
| EXP-03 | Completed exports are deliverable end to end across local and adapter-backed storage while preserving actor ownership. | controller/LiveView tests plus `84-VERIFICATION.md` |
| ADAPT-01 | Configured Oban adapter has truthful startup validation and real enqueue-path integration proof on the repaired tree. | adapter/application tests, example/docs proof, and upgraded `79-VERIFICATION.md` |
| ADAPT-02 | Configured S3 adapter participates in the operator download flow through `download_url/2` instead of local-path assumptions. | controller/S3 tests plus upgraded `79-VERIFICATION.md` |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/v1.20-MILESTONE-AUDIT.md`
- `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-CONTEXT.md`
- `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-UI-SPEC.md`
- `.planning/phases/83-built-in-async-export-lifecycle-repair/83-CONTEXT.md`
- `.planning/phases/83-built-in-async-export-lifecycle-repair/83-RESEARCH.md`
- `.planning/phases/82-saved-views-session-handoff-repair/82-CONTEXT.md`
- `.planning/phases/79-scale-adapters/79-RESEARCH.md`
- `.planning/phases/79-scale-adapters/79-VERIFICATION.md`
- `.planning/phases/79-scale-adapters/79-VALIDATION.md`
- `lib/threadline/operator_surface/controllers/export_controller.ex`
- `lib/threadline/operator_surface/live/export_status_live.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/storage.ex`
- `lib/threadline/storage/local.ex`
- `lib/threadline/storage/s3.ex`
- `lib/threadline/export_queue.ex`
- `lib/threadline/export_queue/oban.ex`
- `lib/threadline/application.ex`
- `lib/threadline/governance/export_job.ex`
- `test/threadline/operator_surface/controllers/export_controller_test.exs`
- `test/threadline/operator_surface/live/export_status_live_test.exs`
- `test/threadline/export_queue/oban_test.exs`
- `test/threadline/storage/s3_test.exs`
- `examples/threadline_phoenix/lib/threadline_phoenix/application.ex`
- `examples/threadline_phoenix/README.md`
- `guides/operator-surface.md`
- `guides/integration-contracts.md`

## RESEARCH COMPLETE
