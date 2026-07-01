# Phase 188: close-gap-v1-38-export-queue-and-motion-validation - Context

**Gathered:** 2026-06-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 188 is a narrow v1.38 close-gap phase. It closes the queued Timeline current-view export replay gap and the `.tl-copy` implicit transition-all validation gap found by the v1.38 milestone audit.

The phase owns worker-side replay of persisted Timeline export filters, fail-closed handling for invalid persisted queued export params, preservation of existing Timeline and Exports queue/download UI behavior, `.tl-copy` motion-source hardening, focused source/ExUnit/browser proof where useful, and final closeout evidence showing the audit gaps are closed or honestly reclassified.

This phase may repair the noncanonical Phase 186 `GOV-02` summary metadata if the planner decides that is needed for v1.38 closeout traceability. It must not add routes, redefine route meanings, redesign operator pages, rename stable `data-testid`s, add public component APIs, add Tailwind/shadcn or animation dependencies, change capture/query/auth semantics outside the queued export replay fix, add new motion families, expand screenshot baselines, or introduce runtime redaction/destructive flows.

The Phase 188 UI-SPEC, research, validation strategy, and milestone audit already pre-answer the user-facing implementation decisions. No additional gray-area discussion was needed.

</domain>

<spec_lock>
## UI Design Contract (locked via UI-SPEC.md)

The active design contract is `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-UI-SPEC.md`.

Downstream agents MUST read `188-UI-SPEC.md` before planning or implementing. Do not duplicate or reinterpret its detailed export queue, copywriting, accessibility, motion, responsive, registry-safety, and verification contracts in plans; cite it and implement against it.

**Requirements locked for this phase:** `TIME-01`, `GOV-02`, `A11Y-02`, `MOTION-01`, and `CLOSE-01`.

**In scope from UI-SPEC:** Timeline current-view queue action, carried Timeline context queue action, export worker replay of persisted params, fail-closed invalid params, existing failed export row treatment, `.tl-copy` explicit transition-property contract, source motion guard hardening, optional narrow browser computed-style proof, targeted ExUnit/source verification, and v1.38 closeout evidence.

**Out of scope from UI-SPEC:** new UI screens, new routes, route meaning changes, stable selector churn, broad IA changes, new copy except parser-derived failed-job detail, capture/query/auth semantic changes beyond queued replay parsing, new CSS tokens, new keyframes, `transition: all`, animation libraries, decorative motion, screenshot baseline expansion, and runtime redaction/destructive actions.

</spec_lock>

<decisions>
## Implementation Decisions

### Contract Authority And Scope

- **D-188-01:** Treat `188-UI-SPEC.md`, `188-RESEARCH.md`, `188-VALIDATION.md`, and `.planning/v1.38-MILESTONE-AUDIT.md` as the controlling Phase 188 contract set.
- **D-188-02:** Treat Phase 188 as gap closure, not another operator UI polish pass. Preserve the current visual hierarchy, page anatomy, labels, route paths, stable selectors, feature gates, auth/export boundaries, optional Phoenix/LiveView posture, scoped `data-tl-theme`, and private component boundary.
- **D-188-03:** Keep existing operator labels exactly where UI-SPEC locks them: `Queue export`, `Carry to Exports`, `Queue Timeline export`, `Background export requested. View progress on the Export Status page.`, `Fix Timeline filters before exporting.`, `Export failed.`, `Download export`, and `Reopen source search`.
- **D-188-04:** Do not add new visible export state unless an existing failing test proves it is required. Parser failures should surface inside the existing failed export row treatment.

### Queued Export Replay

- **D-188-05:** Keep `ExportJob.query_params` URL-shaped and string-keyed. Do not persist a new typed or UI-only shape that would break `Reopen source search` links or existing queued jobs.
- **D-188-06:** The worker replay path must parse persisted job params through `Threadline.OperatorSurface.Exports.FilterParams.parse/1`, or a small shared wrapper around it, before calling export/query code.
- **D-188-07:** Remove unsafe worker atomization of untrusted job params. `Threadline.Export.Orchestrator` must not use `String.to_atom/1` on persisted `query_params`.
- **D-188-08:** Persisted `from` and `to` params must become `%DateTime{}` filters before `Threadline.Query` receives them, so queued date-bounded exports honor the same current-view window operators saw in Timeline.
- **D-188-09:** Invalid persisted queued params must fail closed. A failed job is acceptable; silently dropping invalid filters or broadening the export is not.
- **D-188-10:** Failed queued replay should preserve the existing failed export row and include the parser-derived reason in the existing error detail. Do not replace object-specific recovery copy with generic failure text.
- **D-188-11:** Direct CSV/JSON/NDJSON downloads, completed job download links, feature gates, auth plug/controller protections, unsupported views, and forged-event rejection remain unchanged. LiveView affordance visibility is not the security boundary.

### Motion Contract

- **D-188-12:** `.tl-copy` keeps the same visible behavior: inline-flex compact copy button, hover color/border change, copied Signal color, static `Copied` chip, and `tl-copy-pulse` copied animation.
- **D-188-13:** Replace `.tl-copy` token-only transition shorthand with an explicit property list. Required properties are `color`, `border-color`, `background-color`, and `box-shadow`; duration is `var(--tl-motion-fast)`; easing is `var(--tl-ease-standard)`.
- **D-188-14:** Strengthen source contracts so `transition: all`, `transition-property: all`, token-only transition shorthand without an explicit property list, and layout-affecting transition properties cannot re-enter the operator surface.
- **D-188-15:** `tl-copy-pulse` remains the only copy-specific animation. Do not add keyframes, motion tokens, animation libraries, decorative motion, row/card entrance churn, or per-page motion experiments.
- **D-188-16:** Optional browser proof, if added, must be narrow: inspect a rendered `.tl-copy` computed `transitionProperty` and assert it excludes `all` and includes the explicit property list. Do not add a screenshot matrix for this phase.

### Verification And Closeout

- **D-188-17:** Plan red tests first for queued replay and motion source contracts: persisted string `from`/`to` job params, invalid persisted datetime failure, canonical string param persistence, and `.tl-copy` implicit transition-all rejection.
- **D-188-18:** Preserve or add focused proof in existing test lanes rather than creating broad new suites. Preferred commands are the targeted `mix test` bundle from `188-VALIDATION.md`, then `mix verify.test`.
- **D-188-19:** Run `mix verify.example_browser` only if the implementation adds or changes browser-observable `.tl-copy` computed-style proof.
- **D-188-20:** If Phase 188 owns the Phase 186 `GOV-02` summary metadata cleanup, repair the noncanonical `requirements:` frontmatter to the expected `requirements-completed:` shape and include it in closeout evidence.
- **D-188-21:** Closeout must rerun the v1.38 milestone audit or record equivalent evidence showing export queue and motion validation gaps are closed or intentionally reclassified. Unrelated residuals must be classified honestly, not hidden.

### Claude's Discretion

Downstream agents may choose the exact plan count, wave ordering, helper names, whether `FilterParams.parse/1` is called directly or through a small shared helper, whether failed replay is represented by a raised exception or explicit error tuple internally, and whether to add the optional `.tl-copy` browser computed-style proof. These choices must preserve the locked decisions above and the UI-SPEC contract.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` - Phase 188 exists as v1.38 close-gap work after the milestone audit.
- `.planning/REQUIREMENTS.md` - v1.38 invariants, `TIME-01`, `GOV-02`, `A11Y-02`, `MOTION-01`, `CLOSE-01`, traceability, and out-of-scope constraints.
- `.planning/PROJECT.md` - active v1.38 posture, optional Phoenix/LiveView boundary, no public component API, no root Tailwind/shadcn, and no-regression decisions.
- `.planning/STATE.md` - current workflow state and Phase 188 session status.
- `.planning/v1.38-MILESTONE-AUDIT.md` - source of the queued export, `.tl-copy`, `GOV-02` metadata, and closeout gaps Phase 188 must close.
- `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-UI-SPEC.md` - primary UI/design/accessibility/motion/verification contract.
- `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-RESEARCH.md` - implementation research, stack verification, source findings, parser recommendation, and alternatives considered.
- `.planning/phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-VALIDATION.md` - validation strategy, Wave 0 requirements, targeted commands, and closeout proof expectations.

### Prior Phase Context

- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-CONTEXT.md` - motion governance, proof posture, closeout evidence, screenshot boundary, and residual classification rules.
- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-UI-SPEC.md` - prior accessibility/motion/docs/closeout UI contract that Phase 188 must preserve.
- `.planning/phases/186-detail-governance-and-export-surfaces/186-CONTEXT.md` - export/download affordance decisions, feature-gate boundaries, failed export row treatment, and governance/export workflow posture.
- `.planning/phases/186-detail-governance-and-export-surfaces/186-UI-SPEC.md` - Exports page labels, failed-job recovery, direct download, queue action, and retention/redaction boundaries.
- `.planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md` - proof and no broad screenshot expansion posture carried into v1.38 closeout.
- `.planning/phases/184-timeline-investigation-flow/184-CONTEXT.md` - Timeline current-view workflow, URL-backed filters, export handoff, copy/motion posture, and proof strategy.
- `.planning/phases/184-timeline-investigation-flow/184-UI-SPEC.md` - Timeline export/carry behavior that Phase 188 receives and must not redesign.

### Product And Design-System References

- `DESIGN-SYSTEM.md` - private operator design-system projection, motion posture, and stress/screenshot status.
- `brandbook/tokens.css` - token source referenced by UI-SPEC; do not add Phase 188 token families.
- `lib/threadline/operator_surface/style.ex` - scoped product CSS contract and `.tl-copy` transition target.
- `.planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md` - prior motion inventory that identifies `.tl-copy` intended transition properties.

### Export Replay Source Targets

- `lib/threadline/export/orchestrator.ex` - queued worker replay target; currently atomizes persisted params and must parse allowlisted URL params.
- `lib/threadline/operator_surface/exports/filter_params.ex` - canonical allowlisted Timeline/export URL-param parser to reuse.
- `lib/threadline/operator_surface/live/timeline_live.ex` - Timeline current-view `Queue export` action, `request_background_export`, and job creation source.
- `lib/threadline/operator_surface/live/export_status_live.ex` - carried Timeline context panel, `Queue Timeline export`, canonical query param persistence, job list, and source search links.
- `lib/threadline/operator_surface/controllers/export_controller.ex` - direct download parser/auth boundary to preserve.
- `lib/threadline/governance/export_job.ex` - persisted job schema with `query_params`.
- `lib/threadline/query.ex` - date filters apply only when `from`/`to` are `%DateTime{}` values.

### Existing Tests To Build On

- `test/threadline/export/orchestrator_test.exs` - add queued replay regression and invalid persisted params failure proof.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - preserves Timeline current-view queue action and canonical job shape.
- `test/threadline/operator_surface/live/export_status_live_test.exs` - preserves carried context panel, `Queue Timeline export`, job rendering, failed job treatment, and source search behavior.
- `test/threadline/operator_surface/exports/filter_params_test.exs` - parser contract and atom-safety proof.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` - direct export route/download behavior that must remain unchanged.
- `test/threadline/operator_surface/exports_doc_contract_test.exs` - shared parser/doc/source contracts.
- `test/threadline/operator_surface/style_contract_test.exs` - CSS, motion, reduced-motion, layout-affecting transition, and no-transition-all source contracts.
- `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` - optional narrow browser computed-style proof for `.tl-copy`.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` - keyboard-reachable export path proof if a browser path is amended.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` - Timeline/detail/export earned-flow handoff proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.Exports.FilterParams.parse/1` already allowlists accepted URL keys, parses datetime-local `from`/`to` values into `%DateTime{}`, collapses actor params into `ActorRef`, ignores unknown keys, and avoids atom creation from arbitrary strings.
- `FilterParams.canonical_query/1` and `URI.decode_query/1` already produce the string-keyed query map shape that `ExportStatusLive` stores and uses to rebuild Timeline source search links.
- `ExportStatusLive.timeline_filter_context/1` already validates carried context before rendering the `timeline-export-context` panel or `Queue Timeline export`.
- `TimelineLive` already gates `Queue export` behind valid filters and exports-enabled state and stores current filters as a job query map.
- `style_contract_test.exs` already scans `style.ex` for transition declarations, layout-affecting motion properties, approved keyframes, reduced-motion behavior, and `.tl-copy` sizing.
- `operator-motion.spec.ts` already contains computed-style motion proof patterns that can be extended narrowly if browser proof is chosen.

### Established Patterns

- Operator UI stays in private Phoenix LiveView function components with scoped `.threadline-ui` CSS. No public component API, Tailwind, shadcn, React, or runtime animation dependency is appropriate here.
- URL state is the durable handoff shape for Timeline filters, Exports source recovery, saved views, and current-view export queueing.
- Direct downloads are secured by controller/auth plug behavior. LiveView buttons/links are affordances, not security boundaries.
- Source contracts are the fastest authority for CSS/motion regression prevention; browser tests are used only where computed behavior matters.
- Broad Playwright, screenshot, and example-app residuals are classified in verification artifacts instead of expanded or hidden during narrow close-gap work.
- Stable selectors listed in UI-SPEC must be preserved unless a failing existing proof demonstrates a narrow additional hook is unavoidable.

### Integration Points

- `Threadline.Export.Orchestrator.prepare_filters/2` is the main replay integration point. It should convert stored job params into validated query filters before `Threadline.Export.stream_export_rows/2`.
- `Threadline.Query.timeline_base_query/1` is the downstream behavior that requires `%DateTime{}` `from`/`to` filters to enforce date bounds.
- `ExportJob.query_params` must remain compatible with `ExportStatusLive.timeline_search_path/2`, `Presentation.query_pairs/1`, and existing job list rendering.
- `.tl-copy` changes happen in `style.ex` and must be paired with source contract updates in `style_contract_test.exs`.
- Closeout evidence should update or cite `.planning/v1.38-MILESTONE-AUDIT.md` output without reopening unrelated v1.38 polish scopes.

</code_context>

<specifics>
## Specific Ideas

- No new user preferences were collected in this discussion. The current phase is pre-decided by `188-UI-SPEC.md`, `188-RESEARCH.md`, `188-VALIDATION.md`, and `.planning/v1.38-MILESTONE-AUDIT.md`.
- The strongest implementation shape is two narrow lanes: queued export replay correctness and motion-source contract hardening, followed by a closeout/audit evidence pass.
- If invalid persisted params fail at replay, prefer an error message that is useful in the existing failed job detail, such as the parser-derived invalid datetime text, while keeping the existing `Export failed.` heading and recovery action.

</specifics>

<deferred>
## Deferred Ideas

- Broad screenshot baseline expansion remains deferred.
- New routes, new operator workflows, route meaning changes, public component APIs, Tailwind/shadcn, animation libraries, and new motion families remain out of scope.
- Runtime redaction destructive flow remains deferred unless a future phase explicitly scopes capture/storage semantics.
- Real assistive-technology certification remains deferred unless real AT UAT is explicitly run and recorded.
- No todo artifacts matched Phase 188, so none were folded or reviewed.

</deferred>

---

*Phase: 188-close-gap-v1-38-export-queue-and-motion-validation*
*Context gathered: 2026-06-30*
