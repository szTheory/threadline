# Phase 81: Retention Runtime Closure - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the runtime and evidence gaps left after Phase 76 so retention pruning works end to end on the shipped library path. This phase is not a new retention feature phase: the pruner, run tracking, and Retention History LiveView already exist. Phase 81 must wire them into a built-in supervised runtime, keep the manual trigger and history UI flowing through that same runtime path, and produce the missing Phase 76 verification and validation closure in the repaired milestone format.

</domain>

<decisions>
## Implementation Decisions

### Runtime ownership

- **D-01: Retention pruning must become a library-owned supervised runtime by default.** The adopter should not need to manually start `Threadline.Retention.Pruner`, and the Retention History LiveView must not depend on a process that only exists in tests or ad hoc host code.
- **D-02: The runtime path stays on the built-in OTP/default stack.** Keep the `Threadline.Retention.Pruner` + PostgreSQL advisory-lock approach from Phase 76 rather than introducing Oban, external schedulers, or a second runtime abstraction.
- **D-03: The supervised process should be singular and named, matching the current LiveView call site.** The UI trigger path should continue to talk to the named pruner process rather than bypassing it with direct `Threadline.Retention.purge/1` calls or one-off tasks.

### Trigger and operator flow

- **D-04: Manual “Run Pruning Batch” must execute through the same supervised path as scheduled pruning.** The operator UI is a trigger into the runtime, not a separate execution mechanism.
- **D-05: Retention History should stay a lightweight monitor, not a control panel redesign.** Keep the existing page shape, polling model, and copy unless a small runtime-status tweak is needed to reflect the repaired supervision path.
- **D-06: The current DB-backed run tracking remains the source of truth.** `threadline_retention_runs` is already the audit trail for pruning activity; Phase 81 should prove it through the supervised runtime rather than inventing a second status channel.

### Failure and recovery posture

- **D-07: Preserve the crash-recovery model already implied by the pruner.** Stale `running` rows should continue to be reconciled by the pruner on startup rather than adding a more complex abandonment workflow or UI-only heuristics.
- **D-08: Preserve cluster-safe singleton execution.** The advisory-lock guard remains the concurrency control for scheduled and manual runs; Phase 81 should wire startup around it, not replace it.

### Verification closure

- **D-09: Phase 81 owns the missing closeout evidence for Phase 76.** Deliver a real `76-VERIFICATION.md` proving the repaired runtime path and normalize `76-VALIDATION.md` into the expected closeout shape instead of treating the existing summaries as sufficient evidence.
- **D-10: Proof must be end-to-end on the repaired tree.** Verification needs to cover the supervised startup path, manual trigger behavior through the runtime, and retention-history visibility on the same current tree that milestone status files now describe.

### the agent's Discretion

- Exact child-spec shape and config key names for the supervised pruner startup, as long as the default library path exists without manual host wiring.
- Whether the pruner is always started and self-noops when retention is disabled, or conditionally started from config, as long as the default shipped runtime story is coherent and verified.
- Small UI/status wording adjustments needed to reflect the runtime repair, provided the page does not turn into a broader UX redesign.
- Exact verification command breakdown and artifact wording, as long as the evidence is current-tree, end-to-end, and milestone-closeout-ready.

</decisions>

<specifics>
## Specific Ideas

- The repaired story should be: enable retention config, start the `:threadline` application, and pruning is operational through the built-in supervised path.
- The strongest success proof is the Retention History flow using the same named supervised pruner that periodic scheduling uses, not a special test-only process or direct function call.
- Phase 81 should explicitly avoid “feature theater”: no new retention controls, no alternate scheduler path, no new storage layer. This is runtime closure plus evidence closure.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone contract and repaired authority layer
- `.planning/ROADMAP.md` — Phase 81 goal, success criteria, and ownership boundary versus Phases 82-84
- `.planning/REQUIREMENTS.md` — RET-01, RET-02, and RET-03 traceability now assigned to Phase 81
- `.planning/STATE.md` — current milestone status and next-step framing after Phase 80
- `.planning/v1.20-MILESTONE-AUDIT.md` — exact runtime and evidence gaps this phase must close
- `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md` — current-tree truth-repair posture and verification taxonomy

### Prior Phase 76 intent and evidence surface
- `.planning/phases/76-batched-retention-and-ui/76-RESEARCH.md` — original recommended pruner model and retention-flow assumptions
- `.planning/phases/76-batched-retention-and-ui/76-01-SUMMARY.md` — pruner, advisory lock, and run-tracking implementation summary
- `.planning/phases/76-batched-retention-and-ui/76-02-SUMMARY.md` — Retention History LiveView and manual trigger summary
- `.planning/phases/76-batched-retention-and-ui/76-VALIDATION.md` — existing validation stub that must be normalized into final closeout shape
- `.planning/phases/76-batched-retention-and-ui/76-UI-SPEC.md` — existing UI copy and interaction contract for the retention page

### Runtime code path that must become operational by default
- `mix.exs` — currently lacks an OTP `mod:` application startup path for a supervised retention runtime
- `lib/threadline/retention/pruner.ex` — current named GenServer, advisory-lock logic, startup cleanup, and manual `:prune` cast handling
- `lib/threadline/retention.ex` — current run tracking, purge loop, and retention policy flow
- `lib/threadline/operator_surface/live/retention_history_live.ex` — manual trigger and polling monitor that currently assume a named pruner exists
- `lib/threadline/operator_surface/router.ex` — mounted Retention History route that already exposes the operator surface entry point
- `lib/threadline/governance/retention_run.ex` — persistence contract for retention run state

### Verification targets
- `test/threadline/retention/pruner_test.exs` — current runtime-focused test surface
- `test/threadline/operator_surface/live/retention_history_live_test.exs` — current UI/runtime interaction coverage
- `config/config.exs` — default retention posture in non-test environments
- `config/test.exs` — current test retention config assumptions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Retention.Pruner` already contains the core runtime behavior this phase needs: periodic scheduling, advisory-lock singleton protection, startup stale-run cleanup, and manual trigger support.
- `Threadline.Retention.purge/1` already records `threadline_retention_runs` rows and updates them on completion.
- `RetentionHistoryLive` already mounts under the operator surface, polls the DB, and casts `:prune` to the named pruner.
- Existing pruner and LiveView tests already cover much of the intended behavior; they should be reshaped to prove the default supervised runtime path instead of only manually started test wiring.

### Established Patterns
- Threadline’s repaired milestone posture requires current-tree proof, not historical-plan inference.
- v1.20 keeps built-in OTP defaults first and optional external adapters second; retention should follow that same posture.
- Operator surface pages are already mounted and styled; this phase should preserve that established surface rather than redesigning it.

### Integration Points
- The missing integration seam is application supervision: the retention runtime exists in isolated code and tests but is not started by the library by default.
- The key operator integration path is `/audit/policy/retention` -> `GenServer.cast(Threadline.Retention.Pruner, :prune)` -> `Threadline.Retention.purge/1` -> `threadline_retention_runs`.
- Closeout integration also includes planning artifacts: Phase 76 needs a verification file and a finalized validation artifact that reflect the repaired runtime truth.

</code_context>

<deferred>
## Deferred Ideas

- Additional retention policy UX, scheduling controls, or configuration dashboards — out of scope for this closure phase
- Export-runtime supervision patterns — owned by Phase 83
- Saved-view actor/session handoff repair — owned by Phase 82
- S3/Oban adapter runtime closure — owned by Phase 84

</deferred>

---

*Phase: 81-retention-runtime-closure*
*Context gathered: 2026-05-23*
