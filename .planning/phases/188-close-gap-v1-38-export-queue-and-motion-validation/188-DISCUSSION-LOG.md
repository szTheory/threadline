# Phase 188: close-gap-v1-38-export-queue-and-motion-validation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-30
**Phase:** 188-close-gap-v1-38-export-queue-and-motion-validation
**Areas discussed:** none - existing contracts pre-answered user-facing gray areas

---

## No Remaining User-Facing Gray Areas

The workflow loaded the active v1.38 project context, prior phase context, Phase 188 UI-SPEC, research, validation strategy, milestone audit, and relevant source/test touchpoints.

The scout found that the Phase 188 UI-SPEC, research, validation file, and milestone audit already lock the decisions a downstream planner needs:

- Phase scope is narrow gap closure for queued Timeline current-view export replay and `.tl-copy` motion validation.
- Persisted `ExportJob.query_params` must remain URL-shaped and string-keyed.
- Worker replay must use the allowlisted `FilterParams` parser or a small shared wrapper.
- Invalid persisted params must fail closed and render through the existing failed export row treatment.
- Existing Timeline and Exports labels, actions, routes, selectors, auth/export gates, and direct download behavior must be preserved.
- `.tl-copy` must keep its current visual behavior while replacing implicit transition-all shorthand with explicit properties.
- Verification should use focused ExUnit/source/browser proof and closeout evidence, not broad screenshot expansion.

Because no unsettled user-facing implementation choices remained, no interactive gray-area questions were asked.

## Claude's Discretion

- Exact plan count, wave ordering, helper names, and internal error-return shape.
- Whether `FilterParams.parse/1` is called directly by `Threadline.Export.Orchestrator` or through a small shared helper.
- Whether to add optional browser computed-style proof for `.tl-copy`, as long as source-contract proof is present and UI-SPEC boundaries are preserved.
- Whether Phase 188 owns the Phase 186 `GOV-02` summary metadata cleanup as part of closeout traceability.

## Deferred Ideas

- Broad screenshot baseline expansion.
- New routes, workflows, public component APIs, Tailwind/shadcn, animation dependencies, new motion families, and stable selector churn.
- Runtime redaction destructive flow.
- Real assistive-technology certification without explicit real AT UAT.
