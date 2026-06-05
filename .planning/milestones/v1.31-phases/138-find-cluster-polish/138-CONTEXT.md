# Phase 138: find-cluster-polish - Context

**Gathered:** 2026-06-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Polish the existing Find cluster operator surfaces: Timeline, Transaction, Row-history, Actor, and the Coverage fixes explicitly assigned to Phase 138. The phase applies the Phase 136 design-system primitives and the Phase 138 UI contract to close audit findings F-201(render), F-401, F-402, F-403, F-404, F-405, F-501, F-502, F-504, F-505, F-701, F-702, F-703, F-704, F-705, and F-706.

This is a UI polish phase only. It must not add new backend product behavior, new public query APIs, new screens, new routes, schema changes, Tailwind, shadcn, icon dependencies, or Phase 140 earned flows.

</domain>

<spec_lock>
## Requirements (locked via UI-SPEC.md)

**The UI design contract is locked.** See `.planning/phases/138-find-cluster-polish/138-UI-SPEC.md` for full visual hierarchy, copy, primitive, color, spacing, typography, and audit-finding closure requirements.

Downstream agents MUST read `.planning/phases/138-find-cluster-polish/138-UI-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from UI-SPEC.md):** Timeline, Transaction, Row-history, Actor, and the Coverage fixes explicitly owned by Phase 138; local Phoenix LiveView `.tl-*` primitives; filter, diff, correlation, actor, row-history, and coverage remediation consistency.

**Out of scope (from UI-SPEC.md):** new backend features, new screens, schema changes, Tailwind, shadcn, icon dependencies, third-party registry blocks, and broad mobile/nav architecture work owned by later phases.

</spec_lock>

<decisions>
## Implementation Decisions

### 1. Find cluster model
- **D-01:** Treat Phase 138 as the Find investigation path, not five unrelated pages. Timeline owns the filtered result set and active investigation context; Transaction explains what changed together; Row-history explains point-in-time record state; Actor explains touched-record blast radius; Coverage explains whether Timeline answers are complete enough to trust.
- **D-02:** Keep the operator's next pivot visible and conventional: `Open transaction`, `Open row history`, `Open in timeline`, `Queue export`, `View activity`, or `Add capture` guidance. Do not invent new flow labels that imply Phase 140 capabilities.
- **D-03:** The Find cluster serves P1/P2 incident and support lookup jobs first, while Coverage serves P4 operational confidence. Product language should reinforce Threadline's brand promise: make system history followable under pressure.

### 2. Timeline journey and dense-first treatment
- **D-04:** Use the hybrid recommendation from advisor research: demote the `FIND / EXPLAIN / PACKAGE` journey strip by default unless a label can link to a real existing destination. It must not look like clickable stat cards when it is inert.
- **D-05:** Do not make `PACKAGE` imply the Phase 140 closed export loop. In Phase 138, packaging remains the existing Timeline export affordance or existing Exports surface only.
- **D-06:** Make dense and mobile Timeline states show the active filter summary and rows sooner. Orientation chrome can remain, but it must not become the first-scan handle or push useful results far below the fold.
- **D-07:** Empty Timeline copy uses the locked recovery nudge: widen the time range, clear the table filter, or explain future-window emptiness when matching data exists outside the selected window. Scoped views must keep the authorized-record caveat.
- **D-08:** Disabled anonymous actor-id input gets an inline `n/a for anonymous` hint. Long correlation IDs and table names use middle truncation, full `title`, and copy affordance where interactive.

### 3. Diff and value primitive convergence
- **D-09:** Add shared pure value-formatting helpers in `Threadline.OperatorSurface.Presentation` for UI value semantics, while keeping Transaction and Row-history markup local. This is value convergence, not a new component framework.
- **D-10:** The value helper must distinguish absent, present `nil`, omitted/prior-state, redacted strings, timestamps, booleans/numbers, maps/lists, and ordinary strings. Do not collapse these into `inspect/1` output.
- **D-11:** Transaction INSERT rows render inserted column values when `field_changes` has `after` values. If no fields exist, render diagnostic empty copy tied to capture/coverage, not a blank diff area.
- **D-12:** Transaction before/after rows use an explicit `before -> after` treatment. Row-history snapshots use the same value tokens but remain stable sorted key/value rows, not transaction-style diffs.
- **D-13:** Row-history snapshot values render muted `null` for nil and formatted timestamps instead of raw `nil` or quoted ISO strings. String values remain HTML-escaped and deterministic.

### 4. Coverage remediation model
- **D-14:** Move repeated consequence copy such as `Timeline may be incomplete` out of each row action cell and into a section-level callout. Action cells contain actions or compact remediation only.
- **D-15:** Uncovered Coverage rows get a compact real remediation affordance: prefer `Add capture` guidance with a copyable or revealable CLI command/hint. `View activity` may stay secondary when it is useful, but it is not a substitute for remediation.
- **D-16:** The browser must not pretend it can mutate host code. `Add capture` is guidance, not an in-browser fix. Copy should point to the Mix-task/migration path and verify-coverage follow-up.
- **D-17:** Expected gaps get deliberate muted/warning treatment, not neutral bare text. They do not get the same urgent fix action as uncovered rows; they can expose source/reason and `View activity` when appropriate.
- **D-18:** Fix Coverage grammar and count ownership: `1 expected gap`, `2 expected gaps`, and avoid echoing the same readiness count across multiple equally strong UI elements.

### 5. Actor blast-radius rows
- **D-19:** Use transaction-led Actor rows with compact inline blast-radius metadata. Example shape: `UPDATE tickets - 3 changes - Transaction <id>`. For mixed transactions: `UPDATE tickets + 2 tables - 7 changes`.
- **D-20:** Keep detailed field proof behind `Open transaction`; Actor rows are summaries, not mini transaction reports.
- **D-21:** Avoid N+1 queries and public API churn. If row summaries require visible-page preloads or a focused presenter/helper, keep that local to the operator surface unless planning proves a reusable query boundary is necessary.
- **D-22:** If summary data is unavailable, render an honest fallback such as `Changes unavailable` plus `Open transaction`; do not show only the first table/op without a `+ N tables` indicator.
- **D-23:** Actor time-window segmented controls must expose selected state with `[aria-pressed="true"]` Thread Blue active styling already established by Phase 136/138 UI contracts.

### 6. Primitive strictness and implementation shape
- **D-24:** Prefer pure `Presentation` helpers for derived labels, secondary refs, value tokens, coverage remediation labels, actor transaction summaries, count grammar, and truncation metadata.
- **D-25:** Prefer small Phoenix function components only when repeated markup appears in 2+ Find surfaces. Do not introduce LiveComponents for static organization or a broad component system.
- **D-26:** CSS stays scoped in `Threadline.OperatorSurface.Style` with `.threadline-ui` / `.tl-*`. New classes must be token-backed, dark-first, accessible on hover/focus, and consistent with the brand book's composed, precise, non-flashy direction.
- **D-27:** Keep LiveViews thin. LiveViews orchestrate assigns, streams, URL state, and events; presentation helpers/components own display decisions; query/domain changes remain out of scope unless required to close a locked finding without N+1 behavior.

### the agent's Discretion
- Exact helper names and module grouping are left to planning. Bias toward `Presentation` helper functions first; extract function components only after repeated markup is obvious.
- Exact Timeline layout order can be finalized with screenshots, provided rows appear sooner and the journey strip no longer reads as inert clickable cards.
- Exact Coverage command copy can be finalized during planning after verifying the existing generator/task syntax. The UI must avoid commands that interpolate `schema.table` incorrectly.
- Exact Actor summary computation can be finalized during planning, provided summaries do not cause N+1 queries, public API churn, or misleading first-table-only labels.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked phase and milestone artifacts
- `.planning/phases/138-find-cluster-polish/138-UI-SPEC.md` — locked visual/copy/primitive contract; MUST read before planning.
- `.planning/milestones/v1.31-UI-AUDIT.md` — Phase 134 baseline findings; Phase 138 owns F-201(render), F-401, F-402, F-403, F-404, F-405, F-501, F-502, F-504, F-505, F-701, F-702, F-703, F-704, F-705, and F-706.
- `.planning/milestones/v1.31-PERSONAS-IA.md` — locked P1-P5, J1-J11, EF1-EF5; Find cluster serves P1/P2/P4 paths and keeps Phase 140 earned flows deferred.
- `.planning/phases/137-prove-cluster-polish/137-CONTEXT.md` — prior primitive and per-screen polish decisions: one status owner, secondary refs, empty/error/dense state treatment, and `Presentation` helper preference.
- `.planning/phases/136-design-system-hardening/136-CONTEXT.md` — dark-only, token, status/verdict, color-reservation, and primitive decisions Phase 138 must consume.
- `.planning/phases/135-seed-enrichment-ia-lock-in/135-CONTEXT.md` — seed and IA decisions that make actor/op/diff variety reachable; F-201 render, F-703 render, and Coverage fully-covered state deferred to Phase 138.
- `.planning/ROADMAP.md` — Phase 138 goal, success criteria, and dependency on Phase 137.
- `.planning/REQUIREMENTS.md` — POLISH-FIND requirement and v1.31 non-goals.

### Current code
- `lib/threadline/operator_surface/live/timeline_live.ex` — Timeline filters, journey strip, row stream, saved views, export actions, empty/error states, actor/correlation rendering.
- `lib/threadline/operator_surface/live/transaction_live.ex` — Transaction heading, actor/correlation context, row-level diff rendering, row-history link.
- `lib/threadline/operator_surface/live/row_history_component.ex` — Row-history drawer, as-of `datetime-local`, row timeline, snapshot value rendering.
- `lib/threadline/operator_surface/live/actor_live.ex` — Actor heading, time-window segmented control, transaction stream, empty states.
- `lib/threadline/operator_surface/live/coverage_live.ex` — Coverage summary, uncovered/expected/covered rows, remediation area, pluralization and action cells.
- `lib/threadline/operator_surface/presentation.ex` — shared presentation helper home for value tokens, secondary refs, status labels/modifiers, truncation, count grammar, and actor summaries.
- `lib/threadline/operator_surface/style.ex` — scoped CSS tokens and `.tl-*` primitive catalog.
- `lib/threadline/operator_surface/script.ex` — dependency-free copy affordance behavior via `[data-tl-copy]`.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — Timeline LiveView behavior/copy tests.
- `test/threadline/operator_surface/transaction_live_test.exs` — Transaction LiveView behavior/copy tests.
- `test/threadline/operator_surface/row_history_component_test.exs` — Row-history component tests.
- `test/threadline/operator_surface/live/actor_live_test.exs` — Actor LiveView tests.
- `test/threadline/operator_surface/live/coverage_live_test.exs` — Coverage LiveView tests.
- `test/threadline/operator_surface/presentation_test.exs` — direct helper coverage.
- `test/threadline/operator_surface/style_contract_test.exs` — design-system/token contract coverage.

### Prompt corpus and ecosystem grounding
- `prompts/audit-lib-domain-model-reference.md` — Threadline product model: separate capture, semantics, and exploration/operations; excellent exploration and operational confidence.
- `prompts/threadline-elixir-oss-dna.md` — OSS DX bar: verification as product surface, doc contracts, actionable errors, pitfalls ledger, named Mix entrypoints.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem lessons from Carbonite, PaperTrail, ExAudit, JaVers, django-auditlog, Envers, Audit.NET; avoid missed writes, opaque storage, context propagation footguns, and weak operator UX.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView idioms: thin LiveViews, URL state, streams, function components before LiveComponents, small JS.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — OSS library DX guidance when planning docs/tests/commands.
- `prompts/Threadline Brand Book.txt` — brand direction: precise, composed, lucid, "follow what happened", not flashy/cyberpunk/compliance-bureaucratic.

### External prior-art lessons considered
- GitHub/GitLab audit logs — list rows expose actor/action/target/time/resource hints; details remain behind drill-in.
- Datadog Audit Trail — searchable audit-event rows prioritize current query context and event/resource/action attributes; useful for Timeline and Actor row density.
- GitLab/AWS/Datadog exports — filtered audit views can export, but Phase 138 must not imply the Phase 140 closed export loop.
- JaVers and PaperTrail — object history works best when diffs and snapshots use consistent value semantics while preserving the distinction between changed rows and reconstructed state.
- Phoenix/Ecto Mix task conventions — remediation should point developers toward generator/migration/verification commands rather than vague warnings.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Presentation.secondary_ref/2`: use for actor refs, transaction IDs, record IDs, correlation IDs, and long table names where values are secondary metadata.
- `Presentation.truncate_middle/2`: reuse for long IDs; avoid `short_id/2` hard prefix truncation for UUID-like values where verification matters.
- `Presentation.status_label/1` and `Presentation.status_modifier/1`: existing status vocabulary entrypoint; extend carefully for expected-gap and coverage status treatment.
- `Presentation.human_time/2` and `Presentation.exact_time/1`: base for formatted timestamp tokens.
- `[data-tl-copy]` / `.tl-copy`: existing dependency-free copy affordance; use for transaction/correlation IDs and copyable remediation commands where useful.
- `.tl-alert`, `.tl-empty`, `.tl-secondary-ref`, `.tl-target-row`, `.tl-change`, `.tl-chip`, `.tl-table`, `.tl-segmented`: existing primitives to consume before adding new classes.

### Established Patterns
- Phoenix LiveView HEEx templates with assigns, streams, and small helpers are the local idiom. Avoid broad component churn.
- URL state is already core to Timeline filters and Transaction row-history patch routes; preserve this shareable-state pattern.
- Timeline and Actor streams should remain bounded and stable. Do not add per-row N+1 summary work.
- Phase 137 established `Presentation` helpers as the preferred home for derived presentation logic and kept static markup out of LiveComponents.
- Empty/error states use `.tl-empty` and `.tl-alert`; Phase 138 upgrades copy and actions rather than inventing replacements.

### Integration Points
- Timeline: demote/deep-link journey strip only where destinations are real; improve empty/future-window copy; add anonymous actor-id hint; apply secondary refs and copy to long actor/correlation/table values; make dense/mobile rows appear sooner.
- Transaction: add value-token rendering for diffs; render INSERT field values; constrain short-result layout; make copy controls read enabled.
- Row-history: share value-token semantics with Transaction; format nulls/timestamps; keep as-of control dark and Signal Cyan only for as-of/thread-path emphasis.
- Actor: add compact blast-radius metadata to transaction rows; selected segmented state via `[aria-pressed="true"]`; preserve `Open transaction` as the detailed pivot.
- Coverage: move repeated consequence copy to callout; add real remediation guidance for uncovered rows; style expected gaps deliberately; fix count grammar.
- Tests: add direct helper tests for value tokens, actor summaries, and count grammar; add LiveView assertions for locked copy, selected states, truncation/title/copy affordances, and remediation labels.

</code_context>

<specifics>
## Specific Ideas

- Timeline row-first dense model: active filter summary, status/count, then rows; orientation/journey becomes supporting context, not the active handle.
- Journey strip copy can remain as a caption/legend if demoted; deep links are allowed only when existing destinations are real and do not imply new flows.
- Transaction diff examples should read like `status: closed -> open`, `closed_at: 2026-06-04, 12:30 PM UTC -> null`, and INSERT rows should show inserted fields instead of an empty diff box.
- Coverage uncovered row copy should be concrete but honest: `Add capture` / `Generate trigger migration` plus verify coverage follow-up. The exact command must be verified during planning.
- Actor row examples: `UPDATE tickets - 3 changes - Transaction <id>` and `DELETE ticket_replies + 2 tables - 7 changes`.

</specifics>

<deferred>
## Deferred Ideas

- Home record-first lookup, Home correlation paste/deep-link, first-class row-history entry from Home, and closed Timeline/Evidence to Exports loop remain Phase 140 earned flows.
- Broad mobile nav architecture and full responsive sweep remain Phase 142, except local Phase 138 fixes needed to make Timeline dense/mobile states scannable.
- Full accessibility sweep remains Phase 143, though Phase 138 must preserve labels, focus rings, non-color-only status meaning, and hit targets.

### Reviewed Todos (not folded)
- `Capture direct demo and UI polish` — matched Phase 138 only by the generic keyword `polish` with score 0.2. Reviewed but not folded; it is milestone background already represented by Phase 134 audit, Phase 135 seed/IA lock, Phase 136 design-system hardening, and the Phase 138 UI-SPEC.

</deferred>

---

*Phase: 138-find-cluster-polish*
*Context gathered: 2026-06-04*
