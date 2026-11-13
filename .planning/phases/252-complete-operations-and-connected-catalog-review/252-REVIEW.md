---
phase: 252-complete-operations-and-connected-catalog-review
reviewed: 2026-11-13T13:02:30Z
depth: deep
reviewed_revision: e79f7837e6e9817e739933c85d9579f436f42446
runtime_revision: 7cca0a1830949c31fec4a90d2719ef1f0fcb4056
baseline_revision: b1888177648ef468c6d2bfc1cc1645f860fd2e4b
files_reviewed: 19
files_reviewed_list:
  - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
  - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex
  - examples/threadline_phoenix/storybook/index.exs
  - examples/threadline_phoenix/storybook/operations/exports.story.exs
  - examples/threadline_phoenix/storybook/operations/index.exs
  - examples/threadline_phoenix/storybook/operations/retention.story.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
  - lib/threadline/operator_surface/live/export_status_live/components.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/retention_history_live/components.ex
  - lib/threadline/retention/pruner.ex
  - test/fixtures/operator_surface/route-inventory.json
  - test/fixtures/operator_surface/source-surface-checklist.json
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/retention/pruner_test.exs
  - test/threadline/retention_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
  necessity: 0
status: issues_found
---

# Phase 252: Code Review Report

**Reviewed:** 2026-11-13T13:02:30Z  
**Depth:** deep  
**Files Reviewed:** 19  
**Status:** issues_found

## Summary

The frozen manifest identifies `e79f7837e6e9817e739933c85d9579f436f42446` against baseline `b1888177648ef468c6d2bfc1cc1645f860fd2e4b`; all 19 manifest file hashes match this checkout. The source review traced the Retention preview through authorization, sequential dry-run counts, server-held confirmation, audit, and exact-PID dispatch. It also checked story discovery, shared rendering, fixture purity, route/source links, and Export's default rendering behavior. `Pruner.trigger/0` remains unchanged; the optional Export renderer ID preserves existing live IDs by default.

The source implements the intended read-only preview/error states and static Operations catalog boundary, but it presents placeholder or unknown deletion counts as actual zero outcomes and one partial catalog scenario reports a completed timestamp with no completed run. These are source-level defects in the U3 partial/outcome criteria. The three descriptorless prohibition intents remain flagged-unverified; this review does not invent enforcement or a human approval. The supplied browser receipts/capsules are bound to runtime `7cca0a1830949c31fec4a90d2719ef1f0fcb4056`; they do not replace pixel review. This reviewer did not run tests, builds, browser checks, or database work and makes no pixel, native clipboard, full-root, foreground, or hosted-acceptance claim.

## Source-side UI criteria and limits

- **U1 Export:** the default job-history renderer and live DOM IDs remain unchanged; the additive optional ID is used by static stories to avoid duplicate IDs. Export routes, jobs, and actions remain shared with the production renderer.
- **U2 Retention preview:** source has distinct pending, unavailable, successful-zero, cleanup-disabled, and server-held confirmation states. It checks authorization around the async read and refuses a changed mounted/worker target before confirmation and dispatch.
- **U3 Retention history:** nil fields and completed zero have separate labels, but active placeholder zeros and unknown failed outcomes are overstated by CR-01. The partial static scenario's completion summary is incorrect as described by WR-01.
- **U4 catalog:** the Operations branch is discoverable from the existing PhoenixStorybook index; deterministic static fixtures call shared read-only renderers and do not invoke Repo, Demo.Seed, file writes, or Retention mutation controls. The story copy explicitly limits what static composition proves.

These are source-intent observations across the 30 U1–U4 criteria; they do not score visual quality or establish the rendered dimensions/behavior of every state. The descriptorless prohibitions remain unresolved and flagged: ADM-23 must not imply an unscoped background export is tenant-scoped or acceptance is persisted completion; ADM-24 must not imply sequential estimates are atomic, guaranteed removals, or recorded outcomes; ADM-25 must not present static stories as proof of permissions, query results, downloads, persistence, or reconnect safety. No enforcement descriptor or approval status is inferred.

## Narrative Findings (AI reviewer)

### CR-01: BLOCKER — Progress or unknown deletion counts are presented as final outcomes

**Severity:** BLOCKER  
**File:** `lib/threadline/operator_surface/live/retention_history_live/components.ex:81, 140-144`; `lib/threadline/operator_surface/live/retention_history_live.ex:608-620`; `lib/threadline/retention/pruner.ex:185-200, 230-243`; `lib/threadline/retention.ex:401-415`; static case: `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex:321-326`  
**Impact:** Queued and newly running rows start with `deleted_count: 0`; the purge later checkpoints progress after batches, and successful completion is the point that records a final total. The shared renderer labels every non-nil value “Deleted Rows” and includes active rows in the “Recorded rows deleted” aggregate without saying those values are in-progress checkpoints. On failure, the last checkpoint can be incomplete, while a missing count is converted to zero in “0 rows were deleted before the failure.” The static failed case also intentionally has no count. Operators can therefore mistake progress or an unknown failure outcome for a final zero and make another destructive decision based on it.
**Fix:** Make the presentation status-aware without changing persistence or public APIs: label queued/running values as pending or explicitly “deleted so far,” and exclude active records from a final-outcome aggregate or qualify the aggregate as progress. For failed runs, label a known checkpoint as an incomplete last-recorded count and missing counts as “Not recorded”; only present zero as a final outcome where the backend can prove it. Persist partial totals only when they can be measured exactly.

### WR-01: WARNING — Partial Retention story claims a completed run that is absent

**Severity:** WARNING  
**File:** `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex:305-316, 385-390`  
**Impact:** The `:partial` fixture contains one pending run with no start or completion timestamp, but `latest_completed` is always calculated from the separate `ordinary` completed fixture. The shared story renderer consequently displays a “Latest completed run” date for a scenario whose records contain no completed run.
**Fix:** Find the latest completed entry from the scenario's `runs` and use “No completed run yet” when none exists, matching the live summary logic. Assert the rendered `:partial` scene keeps this state distinct.

---

_Reviewed: 2026-11-13T13:02:30Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: deep_
