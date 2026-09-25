# Phase 201: Rendered Output - Context

**Gathered:** 2026-09-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove Threadline-owned planning vocabulary from every browser-visible operator surface while preserving the exact element structure, information architecture, layout, interaction behavior, and visual appearance already at HEAD. This includes visible phase/decision/requirement/taxonomy labels, planning-provenance DOM attributes, emitted CSS provenance comments, and the roadmap-named historical test filenames.

This is a cleanup-and-proof phase, not an operator-UI redesign. It does not change Plug, Ecto, PostgreSQL, capture/query/auth semantics, public APIs, operator workflows, components, styling, themes, navigation, scorecard floors, or release automation. Arbitrary adopter data is not censored merely because its content resembles a phase number. Tier-A recapture and paid critic scoring remain forbidden.

</domain>

<decisions>
## Implementation Decisions

### Browser Metadata Boundary

- **D-01:** Treat the roadmap's `grep -rn 'data-jtbd'` as a concrete minimum probe, not as a narrowing of RENDER-02. Remove the complete co-located planning taxonomy from all seven affected rendered nodes: `data-earned-flow="EF*"`, `data-persona="P*"`, and `data-jtbd="J*"`. Leaving either sibling taxonomy behind would preserve the same provenance leak under a different attribute name.
- **D-02:** Do not replace the removed taxonomy with a parallel metadata scheme by default. Migrate tests to behavior-first selectors: existing form IDs, routes and outcomes, roles, labels, visible actions, and existing task-oriented `data-testid` values. A new neutral `data-testid` is permitted only when a selector audit proves that no unique semantic or existing stable selector can express the behavior.
- **D-03:** LiveView tests should use `Phoenix.LiveViewTest` selector/form helpers rather than raw HTML substring assertions where the migration naturally touches an assertion. Playwright tests should prefer role, label, text, and stable task selectors over CSS selectors encoding implementation or roadmap taxonomy.

### Stress-Harness Vocabulary

- **D-04:** `/audit/__stress` remains a dev/test-only maintainer and OSS-contributor tool. Its primary job is to select, reproduce, compare, capture, and verify named UI states across themes and viewports; it is not an adopter-facing operator workflow and must not be rewritten as one in this phase.
- **D-05:** Retain durable testing language and exact artifact correlation where it serves that job: stable story IDs, fixture keys, ledger IDs and schema values, cohort identifiers, `Ledger item`, `Origin cohort`, `Refute Twin`, graded-ladder terminology, and rung terminology. Pair machine identifiers with plain-language scenario copy where needed for orientation.
- **D-06:** Remove or permanently reject project-management chronology and opaque roadmap taxonomies from browser-owned copy and metadata: phase/milestone numbers, decision/requirement IDs, `Owner phase`, `J*`, `EF*`, `P*`, `DATA-*`, and equivalent planning provenance. Stable non-rendered fixture keys and engineering terms are not banned merely for being technical.
- **D-07:** Preserve the stress harness's existing authorization, dev/test-only availability, production fail-closed behavior, sanitized synthetic fixtures, DOM structure, classes, styling, dark/light/system behavior, and responsive behavior. Readable maintainer vocabulary must not broaden access or introduce production audit data.

### Already-Landed Cleanup

- **D-08:** Accept, attribute, and guard the rendered-copy and emitted-CSS cleanup that arrived with the Phase 200 integration. Granular commit `5752e357` owns the CSS provenance-comment cleanup; granular commit `1a5fbef2` owns the rendered stress-copy/cohort cleanup; their relevant blobs are byte-identical in integration commit `18fe87f5` and remain unchanged at discussion time.
- **D-09:** Do not revert and replay those correct changes, manufacture inverse commits, squash them again, or rewrite history for phase-number ownership. Treat current HEAD as Phase 201's implementation baseline, record the attribution in durable verification evidence, and implement only the residual inventory.
- **D-10:** The already-landed visible labels are accepted as the final copy for this phase. Planning may verify and guard them but must not reopen their wording, IA, layout, component structure, or visual treatment absent a newly discovered RENDER violation.

### Regression Proof and Release Handoff

- **D-11:** Add an exhaustive, source-derived, zero-allowlist contract over Threadline-owned shipped LiveView templates and emitted CSS for the forbidden attributes and static planning-vocabulary classes. Add representative rendered-output coverage and a synthetic positive control proving the guard fails on a seeded offender. Do not rely only on assertions at today's known locations or on a count floor.
- **D-12:** Scope static-copy checks to Threadline-owned templates, fixtures, and emitted assets. Do not scan or reject arbitrary actor names, row values, audit metadata, or other host-supplied content merely because it contains text resembling `Phase 2`, `D-04`, or another forbidden pattern.
- **D-13:** Produce bounded, one-time pre/post structural evidence for every touched rendered surface. After excluding text nodes and the explicitly removed nonvisual attributes, node count, tags, classes, IDs, and nesting must remain identical. Do not create a permanent whole-DOM snapshot corpus that freezes incidental LiveView markup.
- **D-14:** Preserve the mechanical floor with byte hashes of the unchanged committed operator-surface fixture/scorecard corpus and `mix verify.mechanical` against that unmodified corpus. The Phase 198 probe proved that the checker is blind to text content and width, so it is necessary floor evidence but not sufficient layout evidence.
- **D-15:** Use the existing desktop/mobile responsive, overflow, accessibility, and screenshot checks as the layout/visual complement. Do not generate new screenshot baselines, regenerate Tier-A scorecards, introduce pixel-baseline churn, or invoke any paid/LLM critic path.
- **D-16:** Keep implementation changes atomic and independently revertible, following the milestone rule that source and affected contract tests move together and contract-heavy changes remain bisectable. Rename the remaining roadmap-named historical test files to durable behavior names; do not broaden this into a repository-wide cleanup of non-rendered historical comments.
- **D-17:** Phase 202 receives a browser surface that is clean by construction: the source/output guard is green, the residual attribute inventory is zero, accepted landed cleanup is ratified, normalized structure is unchanged, the mechanical floor is green on unchanged fixtures, and no forbidden recapture or critic path ran.

### the agent's Discretion

- Exact behavior-first selector chosen at each affected test site, following the priority in D-02 and adding a new `data-testid` only with a documented uniqueness gap.
- Exact contract-test module/file placement, positive-control fixture shape, and static-pattern implementation, provided the guard is exhaustive, source-derived, zero-allowlist, non-vacuous, and independent of `.planning/` at runtime.
- Exact normalized structural-signature representation and evidence artifact name, provided it compares the required node/tag/class/ID/nesting shape and excludes only text plus the explicitly removed attributes.
- Exact durable filenames for the remaining roadmap-named tests and the number of plans, provided history is preserved with `git mv` and the cleanup/proof tiers remain independently bisectable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and Phase Authority

- `.planning/ROADMAP.md` §"Phase 201: Rendered Output" and cross-cutting invariants — goal, two-tier sequencing, known offenders, zero-visual-change boundary, and forbidden recapture path.
- `.planning/REQUIREMENTS.md` §"Rendered Output" — RENDER-01 through RENDER-06 verbatim.
- `.planning/PROJECT.md` §"Current Milestone: v1.41 Green, Clean, and Honest" and §"Key Decisions" — public-library posture, rendered-vocabulary defect, and project vision.
- `.planning/STATE.md` §"Current Position" and §"Decisions" — current phase state and accumulated milestone constraints.
- `.planning/phases/198-green-bringup/198-CONTEXT.md` — binding measurement decision, atomic contract-test convention, and no-recapture boundary.
- `.planning/phases/198-green-bringup/198-01-SUMMARY.md` — executed proof that `MechanicalChecker` is insensitive to rendered text and width, plus the resulting Phase 201 sizing implication.
- `.planning/audits/198-mechanical-sensitivity.md` — full controlled probe, signals, results, and positive controls supporting the mechanical-floor interpretation.
- `.planning/phases/199-decouple/199-CONTEXT.md` — source-owned fixture topology, explicit-input evidence readers, positive-control guard pattern, and planning-independent runtime-test requirement.
- `.planning/phases/200-public-surface/200-CONTEXT.md` — durable-language policy, public-surface boundary, current brand authority, and explicit deferral of rendered-output closure to Phase 201.

### Current Product, Domain, and Brand Authority

- `prompts/prior-art/SOURCE-CANONICAL.md` — precedence and provenance for the applicable prompt research corpus.
- `prompts/threadline-elixir-oss-dna.md` — verification-as-product-surface, named gates, contract-test, release-hygiene, and contributor-DX patterns.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — durable domain language, host ownership, optional-surface boundary, and rejection of planning chronology in public explanations.
- `prompts/audit-lib-domain-model-reference.md` §10-13 — operator, contributor, maintainer and adopter personas; JTBDs; user journeys; and domain-language requirements.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem lessons and adopter/operator ergonomics.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView testing, accessibility, state, and integration guidance.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — public-library boundaries, explicit contracts, testability, and least-surprise guidance.
- `brandbook/brand-book.md` — current and superseding source of truth for Threadline voice, durable nouns, UX microcopy, visual principles, accessibility posture, and dark/light/system behavior.
- `CLAUDE.md` — repository architecture, domain language, verification entrypoints, and contributor conventions.

### Rendered Sources and Tests

- `lib/threadline/operator_surface/live/start_live.ex` — two affected home-flow nodes and their existing form IDs/semantic actions.
- `lib/threadline/operator_surface/live/export_status_live.ex` — two affected export-context sections and existing task-oriented `data-testid` hooks.
- `lib/threadline/operator_surface/live/evidence_live.ex` — affected Evidence-to-Exports handoff action.
- `lib/threadline/operator_surface/live/row_history_live.ex` — affected shell root and row-history behavior.
- `lib/threadline/operator_surface/live/timeline_live.ex` — affected Timeline-to-Exports action.
- `lib/threadline/operator_surface/live/stress_live.ex` — already-cleaned visible headings, durable maintainer labels, and stress render structure.
- `lib/threadline/operator_surface/stress_fixtures.ex` — stable story/fixture/cohort vocabulary and synthetic-data boundary.
- `lib/threadline/operator_surface/style.ex` — emitted CSS whose planning-provenance comments were already removed.
- `lib/threadline/operator_surface/mechanical_checker.ex` — deterministic floor checker and explicit fixture-input seam.
- `test/threadline/operator_surface/live/start_live_test.exs` — affected source assertions and available LiveView behavior selectors.
- `test/threadline/operator_surface/live/export_status_live_test.exs` — affected export-context assertions.
- `test/threadline/operator_surface/live/evidence_live_test.exs` — affected Evidence handoff assertions.
- `test/threadline/operator_surface/live/row_history_live_test.exs` — affected row-history assertions.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — affected Timeline handoff assertions.
- `test/threadline/operator_surface/stress_router_test.exs` — accepted durable stress labels and negative assertions for superseded visible planning copy.
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` — cross-page behavior proof currently coupled to earned-flow taxonomy.
- `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` — mobile home-flow behavior currently coupled to earned-flow taxonomy.
- `examples/threadline_phoenix/e2e/tests/operator-shell-home-phase183.spec.ts` — home behavior and one roadmap-named historical test surface.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` — responsive behavior currently coupled to earned-flow taxonomy.
- `test/threadline/phase06_nyquist_ci_contract_test.exs` — remaining roadmap-named historical test filename to rename durably.
- `test/threadline/forward_only_gate_doc_contract_test.exs` — remaining roadmap-named test filename to evaluate and rename according to durable behavior.
- `test/fixtures/operator_surface/` — immutable source-owned ledger, scorecard, golden, and refute corpus whose bytes must remain unchanged.

### External Ecosystem References Consulted

- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html` — idiomatic semantic/form/element testing APIs.
- `https://playwright.dev/docs/locators` — user-facing locator priority and test-ID fallback.
- `https://html.spec.whatwg.org/multipage/dom.html#embedding-custom-non-visible-data-with-the-data-*-attributes` — semantics and intended scope of custom `data-*` attributes.
- `https://storybook.js.org/docs/writing-stories/naming-components-and-hierarchy` — readable maintainer hierarchy over stable technical story identity.
- `https://opentelemetry.io/docs/specs/semconv/general/semantic-convention-groups/` — stable identifiers paired with human-readable descriptions.
- `https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html` — direct, task-oriented language for Phoenix developer tooling.
- `https://www.w3.org/WAI/WCAG22/Understanding/headings-and-labels.html` — descriptive and accessible heading/label requirements.
- `https://docs.github.com/en/pull-requests/reference/pull-request-merges` — squash-integration semantics used in landed-work attribution.
- `https://git-scm.com/docs/git-revert` and `https://git-scm.com/docs/git-bisect` — why inverse replay would worsen rather than clarify this history.
- `https://playwright.dev/docs/test-snapshots` — rendering-environment sensitivity and the reason not to create a new permanent pixel corpus.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Existing stable selectors: `#tl-record-lookup`, `#tl-correlation-lookup`, task-oriented export-context `data-testid`s, routes, link/button names, labels, and outcome assertions can replace most planning-taxonomy selectors without adding DOM metadata.
- `Phoenix.LiveViewTest` helpers already support selector-, form-, and behavior-oriented assertions; affected ExUnit tests can migrate without introducing a new helper dependency.
- The Playwright suites already exercise earned flows, responsive behavior, and mobile navigation; they can preserve the same user jobs using accessible locators and route/result assertions.
- `MechanicalChecker.run/1` accepts explicit source-owned fixture input and the committed `test/fixtures/operator_surface/` corpus is immutable, enabling byte-hash plus floor proof without recapture.
- Existing contract tests use set equality, zero allowlists, and deliberate positive controls; Phase 201 should reuse that non-vacuous contract pattern.
- `StressFixtures` already separates stable IDs/fixture keys from scenario copy, enabling readable maintainer labels without identifier churn.

### Established Patterns

- Verification is a contributor-facing product surface: use named existing gates and actionable failures instead of folklore commands.
- Critical invariants are executable tests with positive controls, not comments or counts.
- Threadline uses stable domain nouns and active, plainspoken copy; release chronology and roadmap shorthand do not belong in browser output.
- Optional Phoenix/LiveView integration stays host-friendly and does not expand the root library's public API or required dependency boundary.
- Source and contract changes remain atomic and bisectable; correct landed history is attributed rather than replayed.
- Fixture and scorecard readers are explicit and planning-independent; no new guard may depend on `.planning/` at runtime.

### Integration Points

- Seven rendered nodes across five LiveViews currently carry the same three-attribute taxonomy, for 21 residual planning-provenance attributes total.
- Five LiveView test files assert the taxonomy directly; four Playwright specs use `data-earned-flow` as a locator and must preserve behavior through selector migration.
- The Phase 200 integration already removed the known visible stress headings and emitted CSS provenance comments. Old labels now appear only in negative regression assertions; `style.ex` has no remaining phase/decision vocabulary.
- Phase 199 already retired `test/threadline/ia_lock_doc_contract_test.exs`; the current tree contains the two remaining roadmap-named filename candidates.
- Phase 202 depends on this phase, so its release handoff must be a deterministic zero-vocabulary proof rather than a claim based on manual inspection.

</code_context>

<specifics>
## Specific Ideas

- Governing policy: **Browser output uses durable product or testing language—never roadmap taxonomy. Tests identify behavior—not planning history. Existing correct cleanup stays landed, and narrow mechanical contracts prevent regression.**
- Optimize for the actual persona at each surface. Production operator pages speak in Threadline domain nouns and task verbs; `/audit/__stress` speaks clearly to maintainers while preserving exact artifact identities needed for debugging.
- The current brand book, not older prompt-era brand material, governs wording and visual constraints: calm, exact, useful, inspectable, and resistant to unnecessary redesign pressure.
- The user requested one cohesive expert recommendation after broad subagent research and explicitly accepted the complete recommendation package without piecemeal redesign.
- Relevant design pillars considered: correctness, auditability, least surprise, public-library boundaries, maintainer and adopter DX, accessibility, privacy, security, performance/CI cost, test stability, responsive behavior, dark/light/system consistency, durable domain language, release safety, bisectability, and future evolvability.

</specifics>

<deferred>
## Deferred Ideas

- A fully adopter-facing stress laboratory or broader stress-harness IA/copy redesign would require its own future UI phase if the harness is ever promoted into a supported product surface.
- Runtime per-operator theme switching remains demand-gated under the existing brand/theme decision and is unrelated to this zero-visual-change cleanup.
- Repository-wide removal of historical identifiers from non-rendered test descriptions, comments, fixtures, and maintainer artifacts remains outside Phase 201; only the roadmap-named filenames and browser/emitted surfaces are in scope.
- No Plug, Ecto, database, capture/query/auth, public-API, or new operator capability was added; discussion stayed within the fixed phase boundary.

</deferred>

---

*Phase: 201-Rendered Output*
*Context gathered: 2026-09-13*
