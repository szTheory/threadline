---
phase: 184-timeline-investigation-flow
reviewed: 2026-06-29T01:13:25Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/ui.ex
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/ui_test.exs
  - examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 184: Code Review Report

**Reviewed:** 2026-06-29T01:13:25Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** clean

## Narrative Findings (AI reviewer)

## Summary

Re-reviewed the current working-tree fixes for the three Phase 184 findings in Timeline export handling, direct download reconnect semantics, and Actor segmented-control markup.

CR-01 is resolved. Invalid Timeline params now preserve the rejected canonical query for context, but `Queue export` and direct CSV/JSON/NDJSON links render only when `export_ready` is true. The forged `request_background_export` path is guarded before the normal export handler and returns without creating an `ExportJob` when `form_error` is present.

WR-01 is resolved. The direct CSV/JSON/NDJSON anchors remain enabled, downloadable, focusable links in the valid-filter path and no longer carry `data-tl-mutating`, so they no longer opt into reconnect-state mutating-control dimming without matching link-disabled semantics.

WR-02 is resolved. `UI.segmented_control/1` now forwards explicit slot `phx-click` and `phx-value-hours` attributes, `ActorLive` renders the actor window selector through the governed `.tl-segment` primitive, and the source/browser tests assert pressed semantics plus absence of `.tl-segmented__item`.

I did not find new blocker or warning issues in the reviewed fix scope. I did not re-run the reported verification commands during this review.

Verification reported by the requester:

- `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/operator_surface/copy_contract_test.exs` => 223 tests, 0 failures
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts tests/operator-find-mobile.spec.ts --grep "Timeline investigation flow|actor mobile exposes"` => 27 tests, 0 failures
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-timeline-investigation-flow.spec.ts` => 27 tests, 0 failures
- `mix verify.example_browser_light tests/operator-timeline-investigation-flow.spec.ts` => 9 tests, 0 failures

All reviewed files meet the Phase 184 quality bar for the prior findings. No issues found.

---

_Reviewed: 2026-06-29T01:13:25Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
