# Phase 137: prove-cluster-polish - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Polish the existing Prove cluster LiveViews: Evidence, Exports, Policy Redaction, and Retention. The phase applies the Phase 136 design-system primitives, closes the Phase 134 Prove findings, improves empty/error/dense states, and records per-touchpoint decisions.

This is a UI polish phase only. It must not add routes, backend product behavior, new queries, new export creation flows, retention semantics, redaction policy behavior, Tailwind/shadcn, icon dependencies, or a replacement CSS architecture.

</domain>

<spec_lock>
## Requirements (locked via UI-SPEC.md)

**The UI design contract is locked.** See `137-UI-SPEC.md` for full visual hierarchy, copy, primitive, color, spacing, typography, and audit-finding closure requirements.

Downstream agents MUST read `137-UI-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from UI-SPEC.md):** Evidence, Exports, Policy Redaction, and Retention; audit findings F-503, F-506, F-601(style), F-602(style), F-603, F-604, F-605, F-606, F-607, F-608; local Phoenix LiveView `.tl-*` primitives.

**Out of scope (from UI-SPEC.md):** new routes, backend product behavior, replacement CSS architecture, third-party registry/component blocks, icon dependencies, and new product flows.

</spec_lock>

<decisions>
## Implementation Decisions

### 1. Prove cluster model
- **D-01:** Treat Phase 137 as one P3/P4 Prove workflow, not four unrelated pages. Evidence answers "can Threadline prove it?", Redaction and Retention answer "is the proof safe to trust?", and Exports answers "what is ready to hand off?"
- **D-02:** Use Redaction as the baseline pattern for the cluster: grouped sections, one semantic status owner, summary-before-detail, `details` disclosure where appropriate, explicit remediation links, and detail content that never outranks the operator's proof/readiness signal.
- **D-03:** Do not merge Redaction and Retention. They share policy adjacency but serve different operator moments: trust-before-capture vs. confirm-after-purge.

### 2. Export readiness model
- **D-04:** Exports hierarchy is derived download readiness, not raw `ExportJob.status`. Keep persisted job state unchanged; readiness is presentation logic derived from `status`, `file_path`, and `expires_at`.
- **D-05:** Group/sort export jobs by readiness: `Ready to hand off`, `Preparing`, `Needs attention`, `Unavailable`, newest first within each group. A single readiness-ranked list is acceptable only if grouped rendering proves too much churn, but raw newest-first is not sufficient.
- **D-06:** Completed + unexpired + file path is the only state that gets the solid primary action: `Download export`. Expired, failed, pending, and running jobs must not visually resemble ready downloads.
- **D-07:** Each export card has one primary action slot:
  - Downloadable completed job: success status owner + solid `Download export`.
  - Pending/running job: neutral/muted `Preparing download`.
  - Completed but expired/unavailable job: muted `Export expired` or `File unavailable`.
  - Failed job: danger status owner + inset `.tl-alert` + secondary/danger `Reopen source search`.
- **D-08:** `Reopen source search` stays secondary and present when query params exist. It must not compete with the ready download action and must be the recovery path for failed jobs.

### 3. Retention destructive-action safety
- **D-09:** Retention is context-first. The page title is `What was purged, and did it succeed?`; summary metrics, latest-completed/latest-status context, and warning copy visually precede the destructive prune action on desktop and mobile.
- **D-10:** `Run retention prune` uses secondary/outline danger styling, not solid primary red. Use the locked confirmation copy: `Confirm retention prune. This permanently deletes older audit records; review the latest completed run and failure count first.`
- **D-11:** Keep the LiveView event thin: `handle_event("prune_now", ...)` continues to re-check policy access and call `Pruner.trigger/0`. Do not add modal, typed confirmation, new retention backend behavior, or URL-backed safety flow in this phase.
- **D-12:** Retention failure count appears once as the count owner and links to the first failed run when that row is in the rendered list. Prefer a native fragment anchor with `:target`/scroll-margin styling over custom JS. If no failures exist, render the metric as plain `0`.
- **D-13:** Compute "latest completed run" separately from "latest run" when needed. A queued or failed latest row must not visually justify a destructive prune action.

### 4. Evidence proof-card hierarchy
- **D-14:** Evidence cards are status-led. Order each card as verdict owner, subject label, secondary outcome/status, muted mono subject ref, recorded time, actions.
- **D-15:** Raw JSON subject refs remain visible as secondary scan detail, not hidden by default. They use muted mono text, middle truncation, and full value via `title`/copy affordance where interactive.
- **D-16:** `Open proof history` is the first Evidence action. Support navigation (`Open exports`, `Review retention`, `Check redaction`, etc.) follows as secondary context.
- **D-17:** Do not widen `Threadline.Evidence.Proof` for F-506. Failed export evidence is a presentation distinction only: for `export_delivery` records with failed summary/context, the leading display label should read `Failed export evidence` or `Evidence of failed export` instead of generic `Unsupported`.

### 5. Primitive strictness and implementation shape
- **D-18:** Phase 137 consumes Phase 136 primitives first. Add only narrow shared helpers for repeated semantic patterns that appear in 2+ surfaces or are explicitly cross-surface in the contract.
- **D-19:** Prefer pure `Threadline.OperatorSurface.Presentation` helpers for derived readiness, display labels, status modifiers, explicit empty placeholders, and middle-truncated actor/subject values.
- **D-20:** Prefer small Phoenix function components only for repeated markup such as status badges, mono values, time labels, and alerts. Do not introduce LiveComponents for static markup organization, a broad internal component framework, or a Prove-only status vocabulary.
- **D-21:** CSS architecture stays scoped in `Threadline.OperatorSurface.Style` with `.threadline-ui` / `.tl-*`. New classes must map to the locked token system and avoid one-off Prove semantics where an existing primitive fits.

### 6. Empty, error, and dense states
- **D-22:** Empty and error states are diagnostic for OSS adopters. Use locked copy from `137-UI-SPEC.md`; include the relevant Mix task/API hint and next-screen link where the surface owns recovery.
- **D-23:** Avoid generic `No data`, `No results`, `Nothing here`, and bare dash placeholders. Use explicit muted labels such as `Not started`, `Pending`, `No expiration`, `Export expired`, or `File unavailable`.
- **D-24:** Dense states preserve the scan order: status/readiness owner, title or subject, actor/subject ref, time, one action slot. Payloads, query params, configured/deployed details, and historical metadata stay secondary.
- **D-25:** One status owner per card/row. Avoid strong row/card stripes plus equally strong badges unless the stripe only anchors focus/selection.

### the agent's Discretion
- Exact helper/module split is left to planning. Bias toward `Presentation` helper functions first; extract function components only where repeated markup is clear.
- Exact readiness rank order inside non-ready groups can be finalized during planning, provided `Ready to hand off` always leads and expired/failed/pending/running never resemble downloadable jobs.
- Exact CSS class names are flexible if they remain `.tl-*`, token-backed, and reusable beyond a single screen where appropriate.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked phase and milestone artifacts
- `.planning/phases/137-prove-cluster-polish/137-UI-SPEC.md` — locked visual/copy/primitive contract; MUST read before planning.
- `.planning/milestones/v1.31-UI-AUDIT.md` — Phase 134 baseline findings; Phase 137 owns F-503, F-506, F-601(style), F-602(style), F-603, F-604, F-605, F-606, F-607, F-608.
- `.planning/milestones/v1.31-PERSONAS-IA.md` — locked P1-P5, J1-J11, EF1-EF5; Prove cluster serves P3/P4 and J5-J8/J10.
- `.planning/phases/135-seed-enrichment-ia-lock-in/135-CONTEXT.md` — seed/IA decisions and deferred notes that affect empty/dense state reachability.
- `.planning/phases/136-design-system-hardening/136-CONTEXT.md` — dark-only, token, status/verdict, and primitive decisions Phase 137 must consume.
- `.planning/ROADMAP.md` — Phase 137 goal, success criteria, and dependency on Phase 136.
- `.planning/REQUIREMENTS.md` — POLISH-PROVE requirement and milestone non-goals.

### Current code
- `lib/threadline/operator_surface/live/evidence_live.ex` — Evidence card hierarchy, proof-history/support actions, subject-ref display.
- `lib/threadline/operator_surface/live/export_status_live.ex` — export job list, refresh behavior, action slot, actor/query param display.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` — strongest Prove-cluster baseline: grouped sections, details disclosure, remediation links.
- `lib/threadline/operator_surface/live/retention_history_live.ex` — retention summary, prune action, failed-run table.
- `lib/threadline/operator_surface/presentation.ex` — status labels/modifiers, truncation, export summary/query helpers; likely home for derived presentation helpers.
- `lib/threadline/operator_surface/style.ex` — scoped CSS tokens and `.tl-*` primitive catalog.
- `lib/threadline/evidence/proof.ex` — proof vocabulary; do not widen for presentation-only failed export labeling.
- `test/threadline/operator_surface/live/evidence_live_test.exs` — Evidence LiveView copy/hierarchy tests.
- `test/threadline/operator_surface/live/export_status_live_test.exs` — Exports LiveView status/action tests.
- `test/threadline/operator_surface/live/retention_history_live_test.exs` — Retention LiveView safety/copy tests.
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs` — Redaction baseline tests.
- `test/threadline/operator_surface/style_contract_test.exs` — design-system/token contract coverage.

### Prompt corpus and ecosystem grounding
- `prompts/audit-lib-domain-model-reference.md` — Threadline product model: batteries-included Phoenix/Ecto/PostgreSQL audit platform; excellent exploration and operational confidence.
- `prompts/threadline-elixir-oss-dna.md` — OSS quality bar and developer ergonomics expectations.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem lessons for audit products and narrow, honest claims.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView idioms; prefer HEEx/function components/helpers over framework churn.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — OSS library DX and contributor surface guidance.
- `prompts/Threadline Brand Book.txt` — dark "night infrastructure with luminous signal lines" brand direction.

### External prior-art lessons considered
- GitLab audit events — export the current filtered audit view as CSV; reinforces source-search/export continuity.
- AWS CloudTrail Event History — searchable recent event history with CSV/JSON download; reinforces export as handoff from a filtered investigation.
- Datadog Audit Trail — CSV export from selected audit-event query/columns; reinforces filtered-view-to-deliverable mental model.
- Atlassian Statuspage — explicit component status vocabulary and top-level status calculation; reinforces one status owner and readable status states.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Presentation.status_label/1` and `Presentation.status_modifier/1`: existing status vocabulary entrypoint; extend carefully so interactive link/action blue does not become generic status color.
- `Presentation.truncate_middle/2`: reuse for actor refs, UUIDs, subject refs, and query-param values. Full values need `title` and copy affordance where interactive.
- `Presentation.query_pairs/1` and `Presentation.export_summary/1`: existing export query/value presentation helpers; extend for readiness grouping rather than duplicating in HEEx.
- `SurfaceHeader` and `UnsupportedView`: existing function component precedent; new function components should follow this lightweight style if needed.
- Redaction `details` rows: local model for summary-before-detail and explicit remediation links.

### Established Patterns
- Phoenix LiveView HEEx templates with assigns and small helpers are the local idiom. Avoid LiveComponents unless there is real state/lifecycle value.
- `ExportStatusLive` currently streams one flat `:jobs` list. If grouped readiness uses assigned bounded lists instead of one stream, planning must account for refresh/reset behavior deliberately.
- Retention and export refresh loops are already periodic LiveView refreshes. Do not introduce client-side JS unless native anchors/CSS cannot solve the local problem.
- Empty states already use `.tl-empty`; Phase 137 should upgrade copy and action affordances, not invent a second empty-state primitive.

### Integration Points
- Exports: add derived readiness helper(s), grouped rendering, one primary action slot, inset alert styling, actor/query truncation.
- Evidence: add status-led card rendering, failed export evidence display label, muted subject-ref value treatment.
- Retention: reorder summary/context/action, outline danger CTA, confirmation copy, failed-run anchor target.
- Redaction: mostly preserve; use as reference and only adjust if Phase 136 primitive changes require local alignment.
- Tests: update old labels and add assertions for question-form titles, ready-only primary download, explicit unavailable placeholders, failed export alert inset, retention confirmation copy, and title/truncation affordances.

</code_context>

<specifics>
## Specific Ideas

- The page-title copy is locked: Exports `What's ready to hand off?`; Retention `What was purged, and did it succeed?`; Evidence keeps `What can Threadline prove right now?`; Redaction keeps assurance framing.
- Readiness group labels should be operator-facing, not schema-facing: `Ready to hand off`, `Preparing`, `Needs attention`, `Unavailable`.
- Failure recovery copy should point to the next action: failed export cards recover through `Reopen source search`; retention runtime failure points to starting the supervisor or `mix threadline.retention.purge --dry-run`.
- GitLab/AWS/Datadog prior art all point to the same UX lesson: filtered investigation and export handoff should feel connected. Phase 137 prepares Exports for that; Phase 140 owns the actual closed loop.

</specifics>

<deferred>
## Deferred Ideas

- Full Timeline/Evidence to Exports closed loop is Phase 140 (EF3/F-1002), not Phase 137.
- Typed confirmation, modal confirmation, or sudo-mode for retention prune is deferred to Phase 140 or a future safety flow if needed.
- URL-backed failed-run focus (`?focus=failed`) is deferred unless retention investigation becomes a larger flow.
- Mobile nav preservation and broad responsive fixes remain Phase 142, except local Phase 137 ordering bugs such as retention context before prune.
- Full accessibility sweep remains Phase 143, though Phase 137 must preserve label text, focus rings, non-color-only status meaning, and hit targets.
- The low-confidence todo `Capture direct demo and UI polish` was reviewed but not folded; it is milestone background already represented by the Phase 134/135/136 artifacts.

</deferred>

---

*Phase: 137-prove-cluster-polish*
*Context gathered: 2026-06-04*
