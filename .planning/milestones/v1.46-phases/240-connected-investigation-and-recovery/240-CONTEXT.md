# Phase 240: Connected investigation and recovery - Context

**Gathered:** 2026-10-10
**Status:** Ready for planning
**Approval:** The maintainer directed the workflow to continue and auto-follow researched recommendations. Four targeted parallel advisor reviews were synthesized; no unresolved product-boundary, security-model, or public-contract decision remains.

<domain>
## Phase Boundary

Operators can follow related audit evidence and resume or share a supported investigation without losing its committed query context or trust in the controls. This phase owns UII-04, UII-05, UII-06, UIA-06, and UIA-07 as listed in `.planning/ROADMAP.md`. It refines the existing Phoenix/LiveView operator surface and current routes, records, and private UI primitives. It does not add backend capabilities, routes, public APIs, authorization policy, dependencies, or a new client framework.

</domain>

<decisions>
## Implementation Decisions

### Row history and return paths
- **D-01:** Provide an explicit, predictable return destination for row-history and as-of views. Carry only a bounded, validated origin and supported committed investigation filters on existing URLs; preserve the transaction identity when history opened from a transaction drawer, and retain the selected `as_of` value in the row-history URL. Direct entry without a valid origin remains independently usable and returns to the default Timeline. Browser Back is a convenience, not the only return control.
- **D-02:** Query parameters are untrusted display/navigation state. Accept only the existing allowlisted query fields; never place host authorization scope, tenant identity, or accumulated cursor pages in the URL. Re-evaluate host authorization and scope on every route. Do not promise restoration of cursor pages.
- **D-03:** Keep failure states distinct. A missing or unavailable transaction remains authoritative: do not run child row-history/as-of reads after its parent is known unavailable. On direct row-history read failure, render a retryable unavailable state with the safe return action; do not mislabel it empty, denied, or not found. Preserve the existing distinctions among absent, pruned, and never-captured evidence.

### Actor/correlation pivots and saved searches
- **D-04:** Preserve the current actor and correlation pivots to Timeline using the corresponding supported filters. Keep transactions, actions, actors, and execution contexts distinct; do not imply that an actor owns a transaction or that correlation identifies an incident.
- **D-05:** Keep named saved searches actor-owned under the existing `SavedView` behavior. Save and restore the committed, canonical supported query; unapplied draft edits are not included. Use “saved search” consistently for the user-facing concept.
- **D-06:** Share a search through a clearly named copyable canonical URL rather than sharing a saved-search record. Build it from the currently applied supported query, not unsubmitted filter edits. The URL shares the supported filter definition, not a fixed result set, cursor position, host scope, or access grant; results are recomputed and authorization/scope are enforced by the receiving host. Make that distinction clear in the interface. Do not add server persistence or a public sharing API.

### Copy reliability
- **D-07:** Keep one document-level delegated click handler for copy controls, bound once so it works with fresh direct entry and repeated LiveView patches without duplicate handling. Start clipboard writes directly from the user's action. Use the Clipboard API when available; only confirm success after its promise resolves. If the API is unavailable, the existing legacy fallback may be attempted and success reported only if it confirms. If the API rejects or fallback fails, show accessible, actionable failure feedback and leave the authorized value selectable for manual copying.
- **D-08:** Never turn redacted, absent, omitted, or otherwise non-copyable evidence into a copy affordance. Do not put unauthorized full values in DOM attributes or feedback. Preserve focus and clean up any temporary selection element.

### Motion and interaction
- **D-09:** Keep frequent actions immediate: keyboard activation, Escape dismissal, copy, actor/correlation pivots, saved-search application, filter changes, pagination, and as-of changes. Do not animate changing evidence values or stagger investigation rows.
- **D-10:** Use only brief, interruptible, tokenized spatial motion for occasional drawer changes when the existing lifecycle can safely distinguish pointer/touch from keyboard activation. If that cannot be done without new shared modality state or replay after LiveView patches, make the transition immediate. Respect reduced-motion settings while keeping state and copy feedback clear.

### the agent's Discretion
- Choose the narrow URL representation for the recognized origin and supported committed filters; reject unknown origins and fields and never accept arbitrary return URLs.
- Choose precise accessible status wording and test hooks for copy outcomes, provided success is factual and manual selection remains available after failure.
- Select the smallest owner/test slices for the drawer and state transitions; use current tokens and existing CSS/LiveView patterns and do not create a new motion system.
- Keep any query name or control copy concise, sentence case, and aligned with the Threadline Brand Book and existing operator language.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product and approved scope
- `.planning/PROJECT.md` — product and current milestone direction.
- `.planning/REQUIREMENTS.md` — UII-04/05/06 and UIA-06/07 acceptance contracts.
- `.planning/ROADMAP.md` — Phase 240 boundary, dependencies, and success criteria.
- `PRODUCT.md` — operator personas, JTBD, and product language.
- `.planning/UI-MILESTONE-PREFLIGHT.md` — accepted design and motion posture, sibling-project lessons, verification limits.
- `.planning/research/SUMMARY.md` — approved milestone research and scoped follow-up rationale.
- `.impeccable/config.json` — code-first design workflow setting.

### Earlier locked decisions and evidence
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-CONTEXT.md` — approved identity, boundaries, responsive/accessibility expectations, and code-first defaults.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-UI-REVIEW.md` — drawer-header and edge-case findings carried into this phase.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-CONTEXT.md` — URL allowlist, server-owned scope, actor/action distinction, overlays, reduced motion, and exact evidence decisions.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-UI-SPEC.md` — existing component, motion, accessibility, and responsive contracts.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-REVIEW.md` — WR-03 transaction row-history outage warning and related recovery concerns.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-SECURITY.md` — threat boundaries and redaction protections.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-UI-REVIEW.md` — remaining rendered edge dispositions and visual limits.

### Domain and engineering guidance
- `prompts/audit-lib-domain-model-reference.md` — audit domain model and bounded-context language.
- `prompts/threadline-elixir-oss-dna.md` — idiomatic Elixir/Phoenix and verification expectations.
- `prompts/Threadline Brand Book.txt` — Threadline voice, identity, and continuity.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView navigation and lifecycle patterns.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` — Phoenix interface and routing patterns.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices.md` — system boundaries and host integration.
- `prompts/prior-art/SOURCE-CANONICAL.md` — provenance of the local prior-art set.

### Existing implementation and verification
- `lib/threadline/operator_surface/live/row_history_live.ex` and `row_history_component.ex` — direct history route, as-of state, and history reads.
- `lib/threadline/operator_surface/live/transaction_live.ex` — transaction pivots and row-history drawer.
- `lib/threadline/operator_surface/live/timeline_live.ex`, `timeline_live/filters.ex`, and `timeline_live/helpers.ex` — committed filters, actor/correlation pivots, and saved-search behavior.
- `lib/threadline/query/filter_params.ex` — supported query fields and canonicalization.
- `lib/threadline/governance/saved_view.ex` — actor-owned saved-search data.
- `lib/threadline/operator_surface/script.ex` and `ui/display.ex` — delegated copy behavior and permitted display values.
- `lib/threadline/operator_surface/style/01_tokens.css` and `style/08_overlays_motion.css` — existing motion tokens and overlay transitions.
- `test/threadline/operator_surface/live/row_history_live_test.exs`, `test/threadline/operator_surface/live/timeline_live_test.exs`, `test/threadline/operator_surface/live/actor_live_test.exs`, `test/threadline/operator_surface/transaction_live_test.exs`, and `test/threadline/operator_surface/ui_test.exs` — existing server-rendered contracts.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`, `operator-accessibility.spec.ts`, `operator-route-states.spec.ts`, and `operator-motion.spec.ts` — mounted navigation, accessibility, failure-state, and motion coverage.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RowHistoryLive` and `RowHistoryComponent` already serve direct row-history entry, selected as-of state, and transaction-drawer history.
- `TimelineLive`, `FilterParams`, and `Helpers` already provide committed URL filters, canonicalization, and actor/correlation links.
- `Governance.SavedView` and `TimelineLive` already persist named searches by identifiable actor; anonymous operators do not create, list, apply, or delete these records.
- `OperatorSurface.Script` already uses one guarded document-level delegated listener, while `UI.Display` and transaction diff helpers already suppress redacted or sentinel values.
- `style/08_overlays_motion.css`, the shared motion tokens, and `operator-motion.spec.ts` provide existing motion primitives and reduced-motion contracts.

### Established Patterns
- LiveView `push_patch` and `handle_params` restore committed route/query state. `FilterParams` is the allowlist; URL values never replace server-owned scope.
- Actor and correlation pivots route into Timeline filters. Saved searches patch the canonical query and are loaded under the current actor reference.
- Host authorization, tenant scope, row-history schemas, and scoped reads flow through socket assigns and the existing auth/mount seam.
- Full, authorized display values should remain selectable; clipboard controls are convenience behavior, never a substitute for visible evidence or redaction.

### Integration Points
- Direct row history: `RowHistoryLive`; transaction row history: `TransactionLive` + `RowHistoryComponent`.
- Search and pivots: `TimelineLive`, `TimelineLive.Filters`, `TimelineLive.Helpers`, actor and transaction LiveViews.
- Copy lifecycle: `OperatorSurface.Script`, shared display controls, transaction diff controls, and the operator shell.
- Motion: row-history drawer, shared overlay CSS, and existing motion test fixtures.
- Extend existing ExUnit and Playwright routes/flow suites; verify test discovery through the canonical CI entrypoint.

</code_context>

<specifics>
## Specific Ideas

Four parallel advisor reviews informed these defaults. Row-history should use an explicit safe return path rather than depending only on browser history. Actor-owned named searches remain private; a copyable canonical URL for the currently applied query is the sharing unit. Copy success must be based on the browser outcome, and redacted values remain unavailable. Motion should support occasional spatial drawer changes without delaying frequent actions or animating evidence-value changes. These recommendations preserve current public 1.x contracts and host security boundaries.

</specifics>

<deferred>
## Deferred Ideas

- New backend history capabilities, row-history pagination, composite-key routes, cursor-page restoration, public APIs/routes, authorization changes, and shared saved-search records.
- Copying uncommitted draft filters or implying that a shared query gives the recipient the same rows or permission.
- New dependencies, client frameworks, global input-modality state, broad motion redesign, and paid judging.

</deferred>

---

*Phase: 240-connected-investigation-and-recovery*
*Context gathered: 2026-10-10*

