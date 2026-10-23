# Phase 239: Investigation entry and transaction composition - Context

**Gathered:** 2026-10-09
**Status:** Ready for planning
**Approval:** Maintainer replied "i approve" to the cohesive recommendation after three targeted parallel advisor reviews. The approved direction is recorded below; do not repeat the discovery interview. Continue through configured planning/verification gates with routine decisions delegated to the agent.

<domain>
## Phase Boundary

Prove one complete home → filtered Timeline → transaction investigation using the established Threadline identity and private Phoenix/HEEx primitives. Own UIS-01/02/03, UII-01/02/03 and UIA-01/02/03/04. Shared presentation and interaction rules become regression conditions for later journeys. Phase 238 is complete; its source-bound evidence is the before baseline. No new backend capability, route, public component/API, authorization model, framework or release is included.
</domain>

<decisions>
## Implementation Decisions

### Entry and search
- **D-01:** Keep Home task-oriented: Timeline is the primary investigation entry, supported row/correlation lookup controls remain visible, and operational destinations remain discoverable. Refine the existing hierarchy rather than introduce a generic dashboard, command-only interface or new job. Explain context as available when recorded; remove the unconditional claim that every change has action/context.
- **D-02:** Keep Timeline's explicit Apply and current primary-filter/advanced-filter structure. Use canonical destination names and sentence case consistently. Applied-filter summaries describe the query that produced the results; field edits are unapplied until submit. A new persistent draft model is not required.
- **D-03:** The URL remains the allowlisted, committed user query, including supported time/schema/table/actor/correlation filters. Apply produces a navigable query state; reload and browser back/forward restore and execute that query. Existing cursor paging remains incremental, bound to the applied query and reset when that query changes. Do not promise restoration of loaded cursor pages or invent new paging APIs. Host authorization scope remains server-owned and enforced independently of URL filters.

### Transaction and exact evidence
- **D-04:** Use a concise semantic transaction summary followed by distinct row-change records. Pair explicitly labeled Before/After values where space permits and stack them with their labels at narrow widths/zoom. Do not force heterogeneous evidence into one wide table or duplicate nested panels. Preserve inserts/deletes, no field evidence, null, absent, omitted and redacted distinctions.
- **D-05:** Keep transaction, action, actor and execution context distinct. A transaction groups database row changes and may link to one action; one action may relate to multiple transactions. Transaction and linked action actors must not be inferred from one another. Display only recorded, authorized context available through existing reads. Missing context is "Not recorded" where accurate; not-found does not prove never-existed versus pruned.
- **D-06:** Shortened identifiers, values and timestamps must have a visible, selectable, keyboard- and touch-reachable full-value reading path with exact timezone information. Title/hover, machine-readable datetime, noscript fallback, and Copy alone are insufficient. Choose a lightweight inline/full-value disclosure using existing primitives; preserve authorized bytes and redaction. Phase 240's Copy reliability work remains separately owned.

### Shared presentation and interaction
- **D-07:** Keep Geist/IBM Plex Mono, existing palette and Threadline tokens/private UI primitives. Consolidate equivalent type/spacing/control roles and repair circular token aliases in their owning source. Establish measurable floors in the UI design contract from the accepted renders, not an arbitrary new palette or blanket component rewrite. Prove the shared changes through the complete investigation journey before expanding them; shared files have one owner.
- **D-08:** Fix the reproduced narrow long-filter overflow while preserving controls and complete evidence access. Verify narrow/intermediate/desktop layouts, 320 CSS-pixel reflow where applicable, short viewports, long unbroken values and actual 200% browser zoom separately. Genuine two-dimensional evidence may scroll locally; whole-page overflow or hidden primary controls is unacceptable. DPR, CSS scaling and resized viewports are not browser zoom proof.
- **D-09:** Preserve Light/Dark/System choices and session persistence across reload and LiveView navigation. Check selected preference separately from computed effective appearance, including OS changes under System; do not introduce a duplicate client-side preference source. Verify served computed styles, not only declarations or class strings.
- **D-10:** Prove visible focus, semantic control names, keyboard/touch reachability, dismissal and focus return for affected controls, including overlapping toast/menu/drawer states and repeated LiveView patches. Shared overlay behavior belongs here; complete row/drawer recovery journeys and their page-specific header fixes remain Phase 240. Frequent interactions stay immediate, reduced-motion behavior must not regress, and no decorative loading choreography is introduced.
- **D-11:** Distinguish pending, empty, failed, denied and completed states. During a changed query, never relabel prior results as the requested scope. Test delayed transitions starting with a nonempty old result set, plus errors and recovery; initial-empty loading alone is not proof. Preserve controls/icons across patches and never announce an accepted operation as completed. New export/prune completion and reconnect mutation proof remain Phase 242.

### Authority, verification and delivery
- **D-12:** Inspect and implement only in retained `.claude/worktrees/v146-operator-preview`, based on refreshed main `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`; approved Phase 238 candidate is `43c5bcfa960b1a10cb07ef997e2231e9615dca6f`. Preserve the original stale `milestone/v1.44` checkout's unrelated edits. Carry planning context deliberately and reconcile custody before evidence runs. Retain baseline bundles and the worktree across Phases 238–243; no blanket reset, branch switch, source merge into the old checkout or worktree cleanup.
- **D-13:** Preserve host authentication/authorization, tenant scope, redaction, public 1.x contracts, routes and Phoenix optionality. Use safe synthetic fixtures and existing reads. Exact-value presentation must not create an alternate data leak; no raw value hidden in DOM/copy attributes may defeat redaction.
- **D-14:** Automate verification and judgment review, with bounded rendered review → corrective batch → confirmation. Use meaningful regressions and established named checks, preserve immutable before evidence, and verify test discovery. No paid critic or routine human UAT. Record exact source/assets/fixture/browser evidence and honest limitations; actual zoom remains unverified until proved. A blocker cannot be waived by a visual-iteration limit. Preparation does not authorize push, publication or new spend.

### the agent's Discretion
- Exact copy, token-role consolidation, local layout breakpoints and full-value disclosure mechanics within the approved identity and accessibility contract.
- Plan granularity, fixtures, meaningful failure controls and the smallest reliable browser-zoom proof mechanism. Treat a tool limitation as a proof gap, not a claim that emulation is equivalent.
- Native semantics, lifecycle-safe implementation and test placement; prefer current patterns and no new dependency. Keep advanced filters available without adding mandatory UI state solely to indicate a draft.
</decisions>

<canonical_refs>
## Canonical References

Downstream agents must read these before planning or implementing. Paths are relative to the retained implementation worktree unless they explicitly describe the original checkout.

### Approved scope and product
- `.planning/ROADMAP.md` — Phase 239 goal, ten requirements, later phase ownership.
- `.planning/REQUIREMENTS.md` — full acceptance interpretation and exclusions.
- `.planning/PROJECT.md` — current milestone and zero-human-verification constraint.
- `PRODUCT.md`, `.impeccable/config.json` — equal engineer/operator priority; code-first refinement.
- `AGENTS.md` — architecture, domain and research/verification rules.
- `prompts/audit-lib-domain-model-reference.md` — distinct capture/semantics/exploration concepts.
- `prompts/threadline-elixir-oss-dna.md` — named checks and CI/OSS conventions.
- `prompts/Threadline Brand Book.txt` — identity and voice authority.

### Existing evidence and targeted research
- `.planning/UI-MILESTONE-PREFLIGHT.md`, `.planning/research/SUMMARY.md` — completed sibling lessons; do not repeat a generic research fanout.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-HANDOFF.md` — source custody, commands, limits and ownership.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-EXECUTION-POINTER.json` — portable source and preservation identity.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-BASELINE-FINDINGS.md` — complete acceptance dispositions.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md` — exact accepted bundles and observations.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-UI-REVIEW.md` — confirmed overflow, copy/label review, token debt and future owners.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-INTEGRATION-NOTES.md` — Bash 5 full-suite convention and disclosed PostgreSQL planner sensitivity.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-ENTRY.md` — query/history and home decision research.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-EVIDENCE.md` — composition, cardinality and exact access research.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-INTERACTION.md` — shared responsive/theme/focus/result-state research.

Primary documentation URLs are retained in advisor reports (Phoenix LiveView, W3C Reflow/Resize Text/Keyboard/Status Messages, APG dialogs/menu buttons and browser documentation). Use the repository's installed versions for concrete APIs.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/threadline/operator_surface/ui/{page,actions,form,overlay,data,display}.ex` — private shared primitives, native forms, result states and references.
- `lib/threadline/operator_surface/presentation.ex` — identifiers, timestamps and evidence-state formatting.
- `lib/threadline/operator_surface/style/01_tokens.css` through `09_responsive.css` — owning token, control, layout, overlay and responsive layers.

### Established Patterns
- `lib/threadline/operator_surface/live/timeline_live.ex` and `live/timeline_live/{filters,helpers}.ex` — explicit Apply, URL parameters, streams and incremental cursors.
- `lib/threadline/query/filter_params.ex` — supported query allowlist; host authorization is separate.
- `lib/threadline/operator_surface/auth.ex`, `session_plug.ex`, `controllers/theme_controller.ex` and `script.ex` — host/session/theme and LiveView lifecycle seams.

### Integration Points
- `lib/threadline/operator_surface/live/start_live.ex`, `live/timeline_live.ex`, `live/transaction_live.ex` — this phase's complete journey.
- `test/threadline/operator_surface/live/start_live_test.exs`, `live/timeline_live_test.exs`, `test/threadline/operator_surface/transaction_live_test.exs`, `presentation_test.exs`, `ui_test.exs`, `style_contract_test.exs` — existing behavioral and shared contracts.
- `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts`, `operator-accessibility.spec.ts`, `operator-route-states.spec.ts` and evidence support — real mounted behavior and source-bound capture seams.
</code_context>

<specifics>
## Specific Inputs

Three targeted advisors found no unresolved architectural choice. Alternatives considered: all filters visible, auto-apply search, table-centric transaction evidence, route-local style fixes and new client theme state. The maintainer approved the coherent existing-pattern recommendation instead.

Phase 238's 375px long-filter capture measured document width 1924px for a 232-character value: a reproduced layout defect. Empty paper/ink aliases are confirmed token debt, not a blanket contrast failure. Its delayed-query probe started empty; it does not establish stale nonempty-scope safety. Exact time metadata and abbreviated identifiers still need user-readable full access with JS enabled.

Use Scrypath's post-closeout focus/loading/cascade lessons and Mailglass/Accrue's zoom, scope identity, test discovery and immutable-baseline lessons already recorded in the preflight. Preserve their evidence maturity qualifiers.
</specifics>

<deferred>
## Deferred Ideas

- Phase 240: connected row/actor/correlation/saved-search recovery, page-specific row/drawer overlap, fresh-entry and patched Copy/failure reliability, purposeful motion refinements.
- Phase 241: coverage/evidence/redaction inspection; Phase 242: exports/retention/reconnect mutation journeys; Phase 243: integrated candidate/release recommendation.
- New cursor-history restoration, composite-key routes, bounded row-history APIs, backend capabilities, rebrand/framework/dependency changes, public UI APIs, paid judging and publication.
</deferred>
