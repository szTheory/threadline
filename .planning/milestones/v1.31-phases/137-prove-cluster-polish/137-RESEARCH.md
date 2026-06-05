# Phase 137: "Prove" Cluster Polish - Research

**Researched:** 2026-06-04
**Status:** Ready for planning
**Mode:** inline fallback after `gsd-phase-researcher` model dispatch failed

## Research Complete

Phase 137 is a narrow UI polish pass over four existing Phoenix LiveViews:

- `EvidenceLive`
- `ExportStatusLive`
- `PolicyRedactionLive`
- `RetentionHistoryLive`

The phase must consume Phase 136's local `.threadline-ui` / `.tl-*` primitive system and the locked `137-UI-SPEC.md`. It must not add routes, backend product behavior, new queries, export creation flows, retention semantics, redaction policy behavior, Tailwind/shadcn, icons, or a replacement CSS architecture.

## Source Findings

### Evidence

Current file: `lib/threadline/operator_surface/live/evidence_live.ex`

Current behavior:

- Title already matches the locked question-form title: `What can Threadline prove right now?`.
- Empty state is already close to the locked copy and references `mix threadline.evidence.show`.
- Cards currently render verdict chip plus `summary_status` in the title, then the raw JSON subject ref at full mono weight, then subject/time/action links.
- `Open proof history` is rendered after `Filter to subject`, but the context requires proof history to be the first Evidence action.
- `build_row/1` delegates verdict vocabulary to `Threadline.Evidence.Proof.present_record/1`; Phase 137 should not widen `Threadline.Evidence.Proof` for failed export evidence. The failed export distinction is presentation-only.

Planning implications:

- Add derived display fields in `EvidenceLive.build_row/1` or `Presentation` for a status-led order: verdict owner, subject label, secondary outcome/status, muted mono subject ref, recorded time, actions.
- Preserve raw subject ref visibility, but render it as secondary scan detail with `Presentation.truncate_middle/2`, full `title`, and preferably a small copy affordance if the existing `.tl-copy` primitive can be reused without introducing JS churn.
- Reorder Evidence actions so `Open proof history` is first when present, then support actions (`Open exports`, `Review retention`, `Check redaction`, etc.), then subject filtering if still needed.
- For `export_delivery` records whose summary/context indicates failure, derive a display label such as `Failed export evidence` or `Evidence of failed export` so F-506 does not present a failed export as generic `Unsupported`.

### Exports

Current file: `lib/threadline/operator_surface/live/export_status_live.ex`

Current behavior:

- Title is still `Export Status`, not the locked `What's ready to hand off?`.
- Jobs are streamed as one flat newest-first `:jobs` stream from `fetch_jobs/1`.
- Downloadable completed jobs render a solid primary button labeled `Download`.
- Pending/running jobs render `Preparing download`.
- Completed-but-unavailable jobs render `Expired` or `File unavailable`.
- Failed jobs render a flush-ish custom `.tl-job__note--error`, not the canonical `.tl-alert`.
- `Reopen search` is always rendered as a secondary source action when query params are present, but the locked label is `Reopen source search`.
- Actor labels render full `type/id` values and can dominate card titles on narrow screens.

Planning implications:

- Add pure presentation helpers in `Threadline.OperatorSurface.Presentation` for export readiness:
  - `export_readiness/1` returning `:ready`, `:preparing`, `:needs_attention`, or `:unavailable`.
  - `export_readiness_label/1` returning `Ready to hand off`, `Preparing`, `Needs attention`, or `Unavailable`.
  - `export_readiness_rank/1` so ready jobs always sort/group first, newest first within group.
  - `export_action_label/1` returning `Download export`, `Preparing download`, `Export expired`, `File unavailable`, or a recovery label for failed jobs.
- Group rendering should prefer assigned grouped lists over the current stream if grouping by readiness is clearer. If streams are retained, the planner must explicitly account for refresh/reset behavior and avoid stale grouping on `:refresh`.
- Completed + unexpired + file path is the only state that gets `tl-button--primary`.
- Failed jobs should render a danger status owner, inset `.tl-alert tl-alert--error`, and a secondary/danger `Reopen source search` recovery action when query params exist.
- Actor refs and query params should use `Presentation.truncate_middle/2`, full `title`, and secondary/mono treatment.
- Empty state must use locked copy: heading `No export jobs queued`, body `Queue an export from Timeline, then return here to download the completed packet or reopen the source search.`

### Retention

Current file: `lib/threadline/operator_surface/live/retention_history_live.ex`

Current behavior:

- Title is still `Retention History`, not the locked `What was purged, and did it succeed?`.
- The destructive prune button is in the page header, before summary/context, and uses `tl-button--primary tl-button--danger`.
- Confirmation copy is `Prune: Are you sure...`, not the locked confirmation copy.
- Summary derives `latest_status` from the first newest row, not separately from latest completed run.
- Failure count is a metric only and is not linked to the first failed run.
- Table uses `-` placeholders for deleted count and duration.
- Empty state is `No Retention History`, not the locked diagnostic copy.
- `handle_event("prune_now", ...)` is correctly thin and should stay that way.

Planning implications:

- Move the destructive prune control below the summary/context block on desktop and mobile, using `tl-button tl-button--secondary tl-button--danger`, not solid primary red.
- Use exact confirmation copy: `Confirm retention prune. This permanently deletes older audit records; review the latest completed run and failure count first.`
- Extend `summarize_runs/1` to compute latest run and latest completed run separately. A queued or failed latest row must not justify the destructive action.
- Make `failure_count` appear once as the count owner. If at least one failed run is in the rendered list, link the metric to a native fragment target for that row.
- Add row ids/classes needed for `:target`/scroll-margin styling; avoid custom JS.
- Replace `-` with explicit muted labels such as `Pending` or `Not started`.
- Empty state must use locked copy: heading `No retention runs yet`, body `Configure retention, run a dry-run first, then trigger a prune to record evidence here.`
- Runtime failure copy should include `Retention runtime is not started. Start the retention supervisor or use mix threadline.retention.purge --dry-run before retrying.`

### Policy Redaction

Current file: `lib/threadline/operator_surface/live/policy_redaction_live.ex`

Current behavior:

- Redaction is the strongest Prove-cluster baseline and already uses grouped sections, details disclosure, explicit drift language, and remediation links.
- Title/lede are still `Policy redaction drift` and a direct assurance sentence; the UI-SPEC says Redaction keeps assurance framing.
- Section empty labels are acceptable structurally but should be checked against the locked diagnostic empty/error tone.

Planning implications:

- Preserve Redaction's structure and use it as the baseline pattern for Exports and Retention.
- Only adjust Redaction if Phase 136 primitive changes require local alignment or if locked empty/error copy/test coverage is missing.
- Avoid changing presenter behavior or redaction policy semantics.

## Shared Helper and CSS Findings

Current files:

- `lib/threadline/operator_surface/presentation.ex`
- `lib/threadline/operator_surface/style.ex`

Reusable helper assets:

- `Presentation.status_label/1`
- `Presentation.status_modifier/1`
- `Presentation.truncate_middle/2`
- `Presentation.query_pairs/1`
- `Presentation.export_summary/1`
- `Presentation.human_time/2`
- `Presentation.exact_time/1`

Reusable CSS assets:

- `.tl-button`, `.tl-button--primary`, `.tl-button--secondary`, `.tl-button--ghost`, `.tl-button--danger`
- `.tl-chip` semantic variants
- `.tl-alert` semantic variants
- `.tl-empty`
- `.tl-job`, `.tl-record-card`, `.tl-summary-grid`, `.tl-table`
- `.tl-copy` exists and can support copy affordance if existing behavior is adequate

Recommended implementation shape:

- Prefer pure `Presentation` helpers for derived readiness, labels, ranks, display refs, and unavailable placeholders.
- Prefer small private function components inside each LiveView only where markup repeats locally, such as `time_label/1`, status/action slots, or mono ref values.
- Add small `.tl-*` classes only where existing primitives cannot express the locked contract, for example `.tl-job-group`, `.tl-ref`, `.tl-retention-context`, or `:target` styling for failed retention rows.
- Do not introduce LiveComponents for static markup organization.
- Do not introduce icons or third-party components.

## Test and Verification Surface

Primary tests to update or add:

- `test/threadline/operator_surface/live/evidence_live_test.exs`
- `test/threadline/operator_surface/live/export_status_live_test.exs`
- `test/threadline/operator_surface/live/retention_history_live_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `test/threadline/operator_surface/style_contract_test.exs`

Likely assertions:

- Evidence:
  - keeps `What can Threadline prove right now?`
  - `Open proof history` appears before support/filter actions in rendered card order
  - subject refs are middle-truncated in visible text and full value is available through `title`
  - failed export evidence display label is not generic `Unsupported`
- Exports:
  - title is `What's ready to hand off?`
  - empty state uses `No export jobs queued` and mentions Timeline/download/reopen source search
  - ready jobs are grouped before preparing/attention/unavailable jobs
  - only completed + unexpired + file path jobs render `Download export` as solid primary
  - expired/unavailable jobs render `Export expired` or `File unavailable`, not a primary download
  - failed jobs render `.tl-alert--error` and `Reopen source search`
  - actor refs use truncated visible text with full `title`
- Retention:
  - title is `What was purged, and did it succeed?`
  - empty state uses `No retention runs yet`
  - prune button label is `Run retention prune`
  - prune button uses secondary/outline danger classes, not `tl-button--primary tl-button--danger`
  - `data-confirm` contains the locked permanent-delete warning
  - context/summary appears before the destructive control in rendered order
  - failure count links to the first failed row when present
  - `-` placeholders are replaced with explicit muted labels
  - `prune_now` still calls `Pruner.trigger/0` and does not gain backend semantics
- Redaction:
  - section order and details disclosure remain stable
  - assurance copy and remediation links remain present
- Style contract:
  - dark-only assertions stay intact
  - semantic status tokens remain border-backed
  - if new classes are added, assert they are `.tl-*` and token-backed where useful

Suggested verification commands:

- `mix test test/threadline/operator_surface/live/evidence_live_test.exs`
- `mix test test/threadline/operator_surface/live/export_status_live_test.exs`
- `mix test test/threadline/operator_surface/live/retention_history_live_test.exs`
- `mix test test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `mix test test/threadline/operator_surface/style_contract_test.exs`
- `mix test`

## Validation Architecture

Phase 137 should be validated with source-level LiveView tests plus a targeted style contract. The acceptance evidence should prove the locked UI contract rather than rely on screenshots alone.

Dimensions:

1. **Contract copy:** exact question-form titles, empty/error copy, action labels, and confirmation text.
2. **Readiness semantics:** derived export readiness groups, one primary action slot, and ready-only primary download behavior.
3. **Destructive-action safety:** retention context-before-action ordering, secondary/outline danger styling, and unchanged thin LiveView event.
4. **Status ownership:** each card/row has one semantic owner; no duplicate failure count owner.
5. **Ref/value handling:** actor refs, UUIDs, subject refs, and query values use muted mono middle truncation with full value discoverability.
6. **Audit finding closure:** F-503, F-506, F-601(style), F-602(style), F-603, F-604, F-605, F-606, F-607, and F-608 each map to at least one test assertion or source assertion.

## Recommended Plan Decomposition

### Plan 01: Shared Prove presentation primitives

Create or extend shared presentation helpers first:

- export readiness/rank/labels/actions
- actor/subject/query value display helpers if useful
- explicit empty/unavailable placeholder labels
- narrow `.tl-*` CSS additions for grouped export sections, ref values, inset alerts, and retention fragment focus

This should be Wave 1 because Exports, Evidence, and Retention can consume these helpers.

### Plan 02: Exports readiness polish

Apply derived readiness grouping, ready-only primary download, failed alert inset, `Reopen source search`, actor/query truncation, locked title, and locked empty/error copy.

This likely closes F-602, F-603, F-604, F-605, F-607, and F-608 for Exports.

### Plan 03: Retention safety polish

Move context before destructive action, demote prune action styling, lock confirmation copy, compute latest completed separately, link failure count to failed row, replace placeholders, and lock empty/error copy.

This closes F-601(style), F-606, F-607, F-608, and the mobile ordering risk F-806 insofar as Phase 137 owns local ordering.

### Plan 04: Evidence hierarchy polish and Redaction alignment

Reorder Evidence cards/actions, de-emphasize raw subject refs, add failed export evidence display label, preserve Redaction baseline, and add any small Redaction primitive alignment required by Phase 136.

This closes F-503 and F-506 while avoiding backend proof vocabulary expansion.

## Key Risks

- **Stream grouping risk:** Exports currently uses `phx-update="stream"`. Grouping by readiness may not compose cleanly with a single stream. Planning should either replace with assigned grouped lists plus explicit refresh assignment, or specify how stream resets keep groups correct.
- **Time-dependent readiness risk:** Expiration depends on `DateTime.utc_now/0`; tests should use future/past datetimes with enough margin and avoid brittle exact-now assertions.
- **Retention latest-run risk:** The newest row can be queued/failed while an older completed row is the latest completed run. Summary code must model both.
- **Backend creep risk:** Failed export evidence is a display label only; do not alter `Threadline.Evidence.Proof` subject semantics unless a test proves it is already the presentation layer.
- **CSS creep risk:** The design system is local `.tl-*`; avoid page-specific one-offs when a reusable primitive or modifier is enough.
- **Accessibility debt:** Full a11y sweep is Phase 143, but Phase 137 must preserve labels, focusable links/buttons, text status labels, and non-color-only status meaning.

## Planning Inputs Checklist

- Must read `137-CONTEXT.md` and `137-UI-SPEC.md`.
- Must cite requirement `POLISH-PROVE` in plan frontmatter.
- Must include all decisions D-01 through D-25 in plan `must_haves`, `truths`, or concrete task acceptance criteria.
- Must include threat-model blocks because security enforcement is enabled by default.
- Must include exact verification commands per touched test file.
- Must avoid new routes, new backend behavior, new product flows, icon dependencies, and CSS architecture churn.

## RESEARCH COMPLETE
