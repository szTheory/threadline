# Phase 83: Built-In Async Export Lifecycle Repair - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the built-in async export runtime so Threadline's default export path actually enqueues, executes, tracks, and cleans up background exports without requiring Oban, S3, or extra host wiring. This phase is a runtime-closure and evidence-closure phase for the built-in export lane. It does not broaden scope into adapter-backed delivery semantics, S3 download integration, or new export UX owned by Phase 84.

</domain>

<decisions>
## Implementation Decisions

### Runtime ownership

- **D-01: The built-in export runtime is library-owned on the default path.** `Threadline.Application` should start both the built-in export `Task.Supervisor` and `Threadline.Export.CleanupTask` whenever Threadline has a configured repo, following the same runtime-ownership posture used in Phase 81 for retention.
- **D-02: Do not add a new false-by-default `:exports.enabled` gate for the built-in runtime.** Export status and background export UI already present a shipped feature surface; requiring a second hidden switch would recreate the exact least-surprise failure this phase is meant to close.
- **D-03: Keep built-in runtime first and optional adapters second.** The built-in `Task.Supervisor` path must work by default; Oban and S3 remain explicit scale adapters and should not weaken or complicate the default runtime story in this phase.

### Enqueue failure behavior

- **D-04: Preserve the export job row, but fail it immediately if enqueue/startup fails.** After inserting a `pending` export row, the request path must check the queue adapter result. If enqueue fails, update the row to `failed`, persist a clear error message, and surface the failure to the operator instead of leaving a dead `pending` row.
- **D-05: Do not delete or roll back the job row on enqueue failure.** The governance row is part of the operator/support truth surface; losing it would make runtime failures harder to diagnose and would weaken the auditability of export requests.
- **D-06: Any later stale-`pending` recovery is secondary hardening, not the primary correctness path.** If a narrow crash window later justifies a recovery sweep, it should complement immediate enqueue failure handling rather than excuse silent limbo states.

### Lifecycle timestamps and expiry semantics

- **D-07: `started_at` means actual execution start, not enqueue time.** Set it on the `pending -> running` transition inside the orchestrator when the job really begins execution.
- **D-08: `expires_at` is terminal retention, not queue lease time.** Do not set it at enqueue. Set it only when the job reaches a terminal state so cleanup reflects retention of completed or failed artifacts/rows, not queue delay or runtime duration.
- **D-09: Apply export retention TTL from terminal time for all terminal states.** Completed jobs get `completed_at` plus `expires_at`; failed jobs also get `expires_at` so the export status table does not become an immortal junk drawer of operational failures.
- **D-10: Cleanup remains DB-driven.** `threadline_export_jobs` stays the lifecycle source of truth, and cleanup should delete artifacts through the storage behaviour using DB rows rather than relying on filesystem mtimes or storage listing APIs.

### Cleanup and recovery posture

- **D-11: `CleanupTask` owns both expired-artifact cleanup and abandoned-running reconciliation.** Startup reconciliation for stale `running` rows is part of the shipped runtime contract and should happen from the supervised cleanup worker, not via ad hoc test-only or operator-only flows.
- **D-12: Cleanup queries must target terminal rows explicitly.** Do not sweep every row with `expires_at < now`; constrain cleanup to the relevant terminal statuses and non-null expiry fields.

### Operator and DX posture

- **D-13: The operator surface must tell the truth immediately.** Background export request flows should not flash success and redirect to `/exports` if the built-in runtime could not accept the job.
- **D-14: Error semantics should be explicit and supportable.** Persist stable, human-readable failure reasons on export jobs so operators and maintainers can diagnose startup/config/runtime issues from the status page and DB state.
- **D-15: This phase should bias toward least surprise for adopters.** If Threadline ships a built-in export queue adapter and a built-in export status page, the default library runtime should make them operational without extra supervision code in the host app.

### the agent's Discretion

- Exact config key names for export retention interval/TTL and cleanup interval, as long as the built-in runtime works by default and the settings remain runtime-configurable.
- Exact child-spec naming and supervision-tree ordering for the export `Task.Supervisor` and `CleanupTask`, as long as the named built-in queue path is truthful and crash recovery still runs on startup.
- Exact UX copy for enqueue failure flashes and status-page error text, as long as the operator is not misled into thinking a dead `pending` job is healthy.
- Whether stale `pending` recovery is deferred entirely or implemented as secondary hardening in this phase, as long as immediate enqueue failures are handled synchronously and visibly.

</decisions>

<specifics>
## Specific Ideas

- The coherent built-in story should be: start the `:threadline` application with a repo configured, request a background export from the timeline, and the job either enters a real built-in runtime path or fails truthfully right away.
- The recommended mental model is closer to mature job systems such as Oban/Sidekiq/BullMQ on lifecycle truth: active jobs are not expiring, terminal jobs are retained for a bounded period, and cleanup is driven from durable job state rather than storage scanning.
- The strongest DX lesson from the repo's prior-art prompts is that supportability matters as much as raw correctness: preserving a failed row with a clear reason is better than deleting evidence or silently marooning work in `pending`.
- The user's current GSD preference is already effectively encoded in `.planning/config.json`: research first, synthesize one cohesive recommendation set, and interrupt only on genuinely high-impact decisions. This phase should carry that posture forward into planning rather than reopening these choices unless a breaking public API or security-model issue appears.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract and audit driver
- `.planning/ROADMAP.md` — Phase 83 goal, success criteria, and the boundary between built-in lifecycle repair and Phase 84 adapter-backed delivery work
- `.planning/REQUIREMENTS.md` — `EXP-01`, `EXP-02`, and `EXP-04` ownership and the milestone's built-in OTP default posture
- `.planning/STATE.md` — current milestone sequence and next-step framing
- `.planning/v1.20-MILESTONE-AUDIT.md` — the exact built-in export runtime and cleanup gaps this phase must close

### Prior locked context and precedent
- `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md` — current-tree truth-repair posture and status taxonomy
- `.planning/phases/81-retention-runtime-closure/81-CONTEXT.md` — precedent for library-owned supervised runtime on the default path
- `.planning/phases/78-async-exports-ui/78-RESEARCH.md` — original export-runtime architecture assumptions and pitfalls
- `.planning/phases/79-scale-adapters/79-DISCUSSION.md` — locked decision that Oban/S3 are optional in-tree scale adapters, not the default runtime

### Runtime code paths to repair
- `lib/threadline/application.ex` — current supervision tree that must start the built-in export runtime
- `lib/threadline/export_queue/task_adapter.ex` — built-in queue adapter contract and `:supervisor_not_started` failure mode
- `lib/threadline/export/orchestrator.ex` — lifecycle transition point for `running`, `completed`, `failed`, and expiry metadata
- `lib/threadline/export/cleanup_task.ex` — startup reconciliation and expired-artifact cleanup worker
- `lib/threadline/governance/export_job.ex` — persisted lifecycle fields and changeset surface
- `lib/threadline/governance/migration.ex` — schema contract for `threadline_export_jobs`
- `lib/threadline/operator_surface/live/timeline_live.ex` — operator request path that currently ignores enqueue results
- `lib/threadline/operator_surface/live/export_status_live.ex` — operator status semantics that depend on truthful lifecycle state
- `lib/threadline/storage.ex` — storage behaviour proving cleanup should be driven by DB rows, not storage listing
- `lib/threadline/storage/local.ex` — built-in local storage deletion path and file-id semantics

### Prompt and prior-art guidance
- `.planning/config.json` — discussion posture and “cohesive recommendation” preference already encoded for GSD
- `prompts/threadline-elixir-oss-dna.md` — OSS/DX posture around verification, least surprise, and operator supportability
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — product thesis and operator-surface lessons for audit tooling
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — OTP/runtime and state-placement guidance
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — library API, runtime ownership, and configuration ergonomics guidance
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` — Phoenix layer boundaries and least-surprise web posture
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView UX, state truthfulness, and failure-surfacing guidance

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.ExportQueue.TaskAdapter` already centralizes the built-in enqueue contract; this phase should make that contract truthful rather than inventing a second queue path.
- `Threadline.Export.CleanupTask` already contains both abandoned-running reconciliation and expiry cleanup logic; it needs supervision and tighter lifecycle semantics, not replacement.
- `Threadline.Governance.ExportJob` already has the right core lifecycle fields (`started_at`, `completed_at`, `expires_at`, `error_message`) for a durable export-state model.
- Phase 81 already established the exact project-level precedent for fixing a shipped runtime path by moving it under `Threadline.Application`.

### Established Patterns
- Threadline favors built-in OTP defaults first and optional adapters second.
- The project treats runtime truth, verification artifacts, and operator-facing supportability as first-class product surfaces.
- Actor-owned operator flows and LiveView status pages assume DB-backed lifecycle truth, not implicit process state.

### Integration Points
- `Threadline.Application` must connect repo availability to export runtime supervision.
- `TimelineLive` must connect operator intent to truthful enqueue outcomes instead of unconditional success flashes.
- `Orchestrator` must connect lifecycle transitions to persisted timestamps and expiry data that `CleanupTask` can trust.
- Cleanup semantics must remain compatible with Phase 84's later adapter-backed storage/delivery work by staying DB-driven and storage-behaviour-based.

</code_context>

<deferred>
## Deferred Ideas

- S3-backed download flow and `download_url/2`-based delivery semantics — Phase 84
- Oban startup/runtime proof and full adapter-backed queue closure — Phase 84
- New export UX beyond making the current status and request path truthful — out of scope for this repair phase
- Any broader retention/export archive policy redesign beyond the built-in terminal TTL needed to make cleanup operational

</deferred>

---

*Phase: 83-built-in-async-export-lifecycle-repair*
*Context gathered: 2026-05-23*
