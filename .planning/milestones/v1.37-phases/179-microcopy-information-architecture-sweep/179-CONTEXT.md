# Phase 179: Microcopy & information-architecture sweep - Context

**Gathered:** 2026-06-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Sweep the existing `/audit` operator surface copy and information architecture now that the component, group, page, and flow structure is stable. This phase delivers COPY-01, COPY-02, and COPY-03: brand-voice compliance, consistent audit-domain language, and GOV.UK-style least-surprise / progressive disclosure while preserving power-user efficiency.

**In scope:** shell navigation labels and group names; Home task cards; page titles/ledes/meta/trust rails; button/link labels; filter labels/help text; empty/error/warning/success/destructive messages; unsupported-state descriptors; evidence/export/retention/redaction terminology; rendered copy contracts and stress evidence that the copy remains accessible and coherent in dark/light/system.

**Out of scope:** new operator capabilities, route changes, public/host-facing component API, capture/semantics changes, new runtime dependencies, a copy CMS, full i18n, visual redesign, formal WCAG closeout, motion closeout, or milestone adversarial audit. Phase 180 owns the final accessibility/motion/adversarial verification pass.

This phase is editorial and architectural polish over an existing surface, not greenfield UI.

</domain>

<decisions>
## Implementation Decisions

### Navigation and task language
- **D-01:** Use a hybrid IA: **task-led Home, domain-led shell nav**. Keep routes, URL shapes, LiveView modules, and `current` atoms stable. Update visible labels only. Home should speak in user jobs, e.g. "Find what changed", "Check audit readiness", and "Use evidence and exports". The shell nav should use durable buckets: `Overview`, `Investigate` (Timeline), `Audit readiness` (Coverage), and `Evidence & exports` (Evidence, Redaction, Retention, Exports). Keep individual destination nouns visible so Redaction/Retention do not disappear under the group heading.
- **D-02:** Retire broad `Find / Verify / Prove` as the shell's primary grouping language. `Prove` overclaims when it covers redaction, retention, and exports; `Verify` is ambiguous outside the coverage page. Reserve `Proven`, `Inferred`, and `Unsupported` for evidence verdicts, not global IA promises.
- **D-03:** Preserve the Overview entry and page routes. The IA sweep must not break existing Playwright route/nav tests or adopter bookmarks. If tests assert old group labels, update those assertions in the same change as the shell copy.

### Domain terminology rules
- **D-04:** Use **hybrid layered vocabulary**. Visible UI copy uses plain operator nouns; exact Threadline model names appear where precision helps: advanced details, docs, tooltips/titles, ARIA labels, code-ish field labels, error details, and first-use explanatory copy. Avoid leaking CamelCase into primary headings/buttons.
- **D-05:** Apply this glossary consistently:
  - `AuditTransaction` -> "transaction" or "database transaction"; never imply it is the same as a request.
  - `AuditChange` -> "change" or "row-level change"; use "captured change" when capture guarantee matters.
  - `AuditAction` -> "action" or "semantic action"; distinguish it from row changes.
  - `ActorRef` -> "actor" in normal UI; "actor reference" in validation/tooltips/errors when the reference shape matters.
  - `Correlation` -> "correlation id"; explain as the thread that connects request/job/integration activity.
  - row history/as-of -> "Row history" and "Snapshot as of".
  - redaction drift -> "Redaction drift detected".
  - retention window -> always include permanent deletion / pruning consequence when action or trust depends on it.
  - evidence proof -> "Evidence" in navigation and overview; "proof history" only for the append-only evidence detail/history view.
- **D-06:** Keep all visible copy sentence case except fixed domain/code tokens and operation badges (`INSERT`, `UPDATE`, `DELETE`). Replace title-case leaks such as "Invalid Actor Reference", "Action Denied", "Unsupported View", and hyphenated alert titles like "Transaction Not Found - ..." with brand-compliant sentence-case copy.

### State, validation, warning, success, and destructive copy
- **D-07:** Use **controlled templates with page-specific domain slots**. Do not build a global copy DSL. Keep repeated state grammar in existing internal components/helpers (`UI.data_state/1`, `UI.empty_state/1`, `UI.error_state/1`, `UI.stale_banner/1`, `Unsupported.descriptor/1`, `Presentation.status_label/1`) and leave page-specific wording near the LiveView that owns the workflow.
- **D-08:** Required copy templates:
  - Validation error: "Enter/select/fix {field label}..." and keep the field label language aligned with the error text.
  - Error: "Could not {load/queue/export/prune} {object}. {Known cause if safe}. {Next action}."
  - Empty first-run: "No {object} yet. {How this becomes populated}."
  - No-data from filters: "No {objects} match these filters. Clear {filter} or widen {time range}."
  - Permission: "You do not have access to this {object}. The {object} exists; your account needs `{capability}`."
  - Unavailable: "{Object} is temporarily unavailable. This is not a permissions issue. Retry, then check {surface/logs}."
  - Redacted/pruned unavailable: state what happened and explicitly say it is not permissions.
  - Stale: "Could not refresh - showing last known {object} from {timestamp}. Retry."
  - Warning: "{Risk} detected. {Consequence}. {Fix before relying on {surface}}."
  - Success/status: "{Object/action} {queued/started/completed}. {Where to follow it or what stays linked}."
  - Destructive modal: "{Action} {object} permanently? This permanently {consequence}. Type `{object identifier}` to confirm." Button label names the consequence, not generic "Continue".
- **D-09:** ARIA roles follow severity, not color. Use `role="alert"` for immediate errors and permission/unavailable states that require attention. Use `role="status"` for loading, stale, success, neutral progress, and routine empty/no-data states. Validation summaries should receive focus and link to affected controls when form validation spans multiple fields.
- **D-10:** Keep exact-value copy affordances strict from Phase 176: displayed/truncated values can be short, but copy targets and zero-JS fallback must expose the full value. This is part of microcopy because "Copy" must never imply a truncated forensic value.

### Progressive disclosure and density
- **D-11:** Use a **layered context budget**. Keep one-line page ledes when they change operator judgment; keep trust rails only where risk/governance is central (Coverage, Evidence, Redaction, Retention, Exports handoff). Dense investigation paths such as Timeline should put filters/results/actions first and demote explanatory legends below the working surface.
- **D-12:** Remove or compress repeated journey prose that competes with primary work. The Timeline legend (`FIND / EXPLAIN / PACKAGE`) is a candidate for sentence-case compression or removal after its value is covered by Home and utility actions. Do not use all-caps instructional prose except operation badges.
- **D-13:** Do not add a user-selectable novice/expert or help/density mode in this phase. That adds state, URL/reconnect semantics, copy variants, and test matrix breadth without current adopter evidence.
- **D-14:** Disclosures must be recoverable and least-surprise. Advanced filter disclosure can open based on active URL params; shareable/recoverable view state stays in URL via `patch` / `handle_params`. Do not hide destructive consequences, permission/no-data/unavailable distinctions, or copyable full IDs inside optional disclosure.

### Implementation and verification posture
- **D-15:** No route churn, dependency churn, public API, or LiveComponent extraction for copy organization. Prefer existing function components, `attr`/`slot` declarations, and small helpers in current modules.
- **D-16:** Add copy-contract coverage rather than relying on screenshots. Planners should include tests that scan rendered operator pages and/or source for: banned vague words, exclamation marks, title-case state headings, old `Find / Verify / Prove` group labels if replaced, exact glossary mappings, ARIA role mismatches for state copy, and the absence of visible CamelCase in primary UI.
- **D-17:** Stress-route evidence should include copy states. If Phase 178 page stories already render the relevant paths, update those stories and ledger/projection only as needed to reflect copy/IA state, not to add new UI capabilities.

### Reviewed Todos
- **coverage-schema-card-declutter** was matched at low confidence for Phase 179 but is already folded into and completed by Phase 176 DATA-05. Do not fold it into this phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` - COPY-01, COPY-02, COPY-03; v1.37 invariants: no public component API, zero new runtime dependencies, inline assets, brand voice, banned vocabulary, domain language, WCAG direction.
- `.planning/ROADMAP.md` - Phase 179 goal, dependencies, and success criteria.
- `.planning/PROJECT.md` - project value, current milestone posture, brand/design-system context, and key decisions.
- `.planning/STATE.md` - current Phase 179 status and deferred todo context.

### Prior phase context
- `.planning/phases/176-data-display-operator-patterns/176-CONTEXT.md` - state taxonomy, exact-copy guarantee, destructive confirmation tiers, one-card-boundary rule, data display terminology.
- `.planning/phases/177-component-groups-meta-components/177-CONTEXT.md` - group/meta-component conventions, data panel state coordination, trust rails, motion/disclosure constraints.
- `.planning/phases/178-per-page-flow-stress-pass-all-11-pages/178-CONTEXT.md` - all 11 page stories, footgun guards, shared shell, reconnect banner, page stress verification posture.

### Brand and domain source
- `brandbook/brand-book.md` - current brand voice, writing rules, UX microcopy patterns, non-color-alone rule, card guidance, current brand truth. Prefer this over older `prompts/Threadline Brand Book.txt`.
- `prompts/audit-lib-domain-model-reference.md` - canonical nouns, UI IA recommendations, personas/JTBD, operator/admin workflows, audit footguns, and exploration/ops layer principles.
- `prompts/threadline-elixir-oss-dna.md` - explicit composition, verification as product surface, actionable errors, doc contracts, fail-closed posture, library DX.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` - idiomatic LiveView: function components, URL state, streams, forms, expected failures as UI state, security checks on mount/events.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` - structured error/DX patterns and library ergonomics.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` - Plug/Ecto/Phoenix correctness and process footguns.

### Operator surface code
- `lib/threadline/operator_surface/components/surface_header.ex` - shell nav groups, destination labels, coverage stale/status chip copy, theme picker labels.
- `lib/threadline/operator_surface/ui.ex` - `page_header`, `shell`, `empty_state`, `error_state`, `loading_state`, `stale_banner`, `data_state`, `pager`, `ref`, `toolbar`, `data_panel`, destructive/modal primitives.
- `lib/threadline/operator_surface/presentation.ex` - status labels, operation labels, time labels, query/filter summaries, export summaries, coverage remediation copy.
- `lib/threadline/operator_surface/unsupported.ex` and `lib/threadline/operator_surface/components/unsupported_view.ex` - unsupported/denied/unavailable descriptor copy that currently contains title-case leaks.
- `lib/threadline/operator_surface/live/start_live.ex` - Home task cards, system health row, earned row-history and correlation shortcuts, saved searches.
- `lib/threadline/operator_surface/live/timeline_live.ex` - primary investigation command surface, filters, active filter summary, export utilities, empty/no-data copy, journey legend.
- `lib/threadline/operator_surface/live/transaction_live.ex`, `actor_live.ex`, `row_history_live.ex`, `row_history_component.ex` - transaction/change/actor/row-history/as-of terminology and detail-page breadcrumbs.
- `lib/threadline/operator_surface/live/coverage_live.ex` - coverage/readiness labels, remediation copy, stale coverage copy.
- `lib/threadline/operator_surface/live/evidence_live.ex` - evidence/proof/history/context wording.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex` - redaction assurance/drift/config-vs-deployed terminology.
- `lib/threadline/operator_surface/live/retention_history_live.ex` - retention/prune/destructive copy and permanent deletion language.
- `lib/threadline/operator_surface/live/export_status_live.ex` - export handoff, carried Timeline/Evidence context, statuses and failures.
- `lib/threadline/operator_surface/stress_fixtures.ex` and `lib/threadline/operator_surface/live/stress_live.ex` - page/state/group stress stories that should reflect the final copy.

### Tests and verification assets
- `test/threadline/operator_surface/surface_header_test.exs` and `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` - shell/nav label and active-state coverage.
- `test/threadline/operator_surface/page_header_test.exs`, `breadcrumb_test.exs`, and `pager_test.exs` - header, breadcrumb, pager copy contracts.
- `test/threadline/operator_surface/ui_test.exs`, `component_contract_test.exs`, and `data_state_mapping_wave0_test.exs` - state components and role/copy behavior.
- `test/threadline/operator_surface/presentation_test.exs` - shared status/operation/time/filter label helpers.
- `test/threadline/operator_surface/live/*_test.exs` - rendered copy contracts for the 11 operator pages.
- `test/threadline/operator_surface/stress_fixtures_test.exs`, `stress_router_test.exs`, `stress_ledger_test.exs`, and `ui_stress_test.exs` - stress fixture and ledger/projection parity.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`, `operator-responsive-mobile-first.spec.ts`, `operator-prove-mobile.spec.ts`, `operator-phase-178-uat.spec.ts`, and `operator-stress.spec.ts` - real-browser coverage for accessible labels, mobile nav, dense surfaces, and stress route rendering.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `UI.page_header/1` already supports title, rich heading, lede, meta, actions, and breadcrumbs. Use it to standardize one-line ledes and avoid hand-rolled title/lede patterns.
- `SurfaceHeader.surface_header/1` centralizes shell IA. The desired nav/group changes are mostly copy-only here.
- `UI.data_state/1` and siblings already encode the Phase 176 state taxonomy. Extend/correct copy there before duplicating state messages across pages.
- `Presentation.status_label/1`, `operation_label/1`, `human_time/2`, `checked_label/1`, and export/filter helpers are the right place for repeated labels.
- `Unsupported.descriptor/1` is a high-leverage place to fix title-case and vague unsupported/error copy across disabled features.
- Existing stress fixtures already model state/page paths. Use them as copy evidence rather than creating a separate storybook or new runtime dependency.

### Established Patterns
- Internal function components with strict attrs/slots are preferred over LiveComponents or new public APIs.
- URL-driven state is already used for Timeline filters, Evidence subject/history modes, Exports handoff, and row-history/as-of links. Continue that pattern.
- Copyable refs bind the full value to `data-tl-copy`; the visible label can be short, but the copy target cannot be shortened.
- Verification in this milestone is ratchet-based: write guard-first tests, then fix copy/IA to green.
- Brandbook is the current brand source. Older prompt brand material is background only.

### Integration Points
- Nav relabeling touches `surface_header.ex`, Home copy in `start_live.ex`, and Playwright/ExUnit tests that assert nav labels/groups.
- State copy touches `ui.ex`, `unsupported.ex`, page LiveViews, and component/render tests.
- Domain terminology touches `presentation.ex`, all page LiveViews, doc-contract tests, and stress fixtures where story labels surface in `/audit/__stress`.
- Progressive disclosure changes likely touch Timeline command/legend copy, trust rails, page ledes, and any tests that assert dense/mobile layout text.

</code_context>

<specifics>
## Specific Ideas

- External examples reinforce the chosen direction: GitHub audit log centers actor/action/time with query/export; AWS CloudTrail separates recent event history from longer-term trails/Lake and makes export/search explicit; Datadog Audit Trail uses facets, dashboards, saved views, and CSV export; Linear keeps recent audit browsing simple and points advanced queries to API; Stripe exposes account activity through security history/activity logs. The lesson is: primary UI should be searchable, filterable, and plain, while exact fields/facets stay available for power users.
- GOV.UK error guidance supports field-linked, direct error copy and focused error summaries. Apply the pattern to LiveView forms and filter validation without copying GOV.UK visual design.
- User requested subagent research across all gray areas and a one-shot recommendation that is coherent across architecture, UX, DX, and project vision. The locked recommendations are intentionally not a menu: hybrid IA, hybrid vocabulary, controlled copy templates, and layered disclosure work together.

</specifics>

<deferred>
## Deferred Ideas

- Persistent novice/expert help or density mode - defer until real adopter research proves the split is needed.
- Full i18n or externalized copy registry - defer; not needed for this internal operator surface and would add architecture weight.
- New operator capabilities, new filters, new export workflows, or new evidence/retention/redaction features - defer to separate phases if needed.
- Formal accessibility/motion/adversarial closeout - Phase 180.

### Reviewed Todos (not folded)
- `coverage-schema-card-declutter.md` - already realized by Phase 176 DATA-05; no Phase 179 action.

</deferred>

---

*Phase: 179-Microcopy & information-architecture sweep*
*Context gathered: 2026-06-19*
