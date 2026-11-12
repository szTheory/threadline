# Roadmap: Threadline

## Milestones

- [ ] **v1.48 Threadline Admin: brand and complete journeys** — Phases 248–253; approved 2026-11-10, pending implementation. Four of34ADM requirements are complete; Phase248 is verified complete, with four complete plans. This planning version does not prescribe the package release version.
- [x] **v1.47 Release on autopilot** — Phases 244–247.1; completed 2026-10-29. Five phases (including gap phase 247.1), 66 plans, 68 tasks, 13/14 requirements; REL-01 deferred-with-trigger (accepted at close). Audit: tech_debt. No package release (no merge changed the shipped package; Hex stays 1.1.0). Roadmap archive: milestones/v1.47-ROADMAP.md; requirements: milestones/v1.47-REQUIREMENTS.md; audit: milestones/v1.47-MILESTONE-AUDIT.md.
- [x] **v1.46 Operator UI Refinement** — Phases 238–243; completed 2026-10-11. Six phases, 27 plans, 49 tasks, 26/26 requirements. Audit: tech_debt, with no unmet requirements or broken flows. Roadmap archive: milestones/v1.46-ROADMAP.md; requirements: milestones/v1.46-REQUIREMENTS.md; audit: milestones/v1.46-MILESTONE-AUDIT.md.
- [x] **v1.45 1.0 API Contract** — Phases 231–237; shipped as 1.0.0 on 2026-10-07. Archive: milestones/v1.45-ROADMAP.md.
- [x] **v1.44 Behavioral Depth: Properties, Twins, Telemetry** — Phases 224–230; shipped as 0.12.0 on 2026-10-02. Archive: milestones/v1.44-ROADMAP.md.
- [x] **v1.43 Supply Chain, CI Economy and Repo Hygiene** — Phases 214–223; shipped as 0.11.1 and 0.11.2 on 2026-09-30. Archive: milestones/v1.43-ROADMAP.md.
- [x] **v1.42 Capture Correctness for Real Table Shapes** — Phases 208–213; shipped as 0.11.0 on 2026-09-26. Archive: milestones/v1.42-ROADMAP.md.
- [x] **v1.41 Green, Clean, and Honest** — Phases 198–207; shipped on 2026-09-24. Archive: milestones/v1.41-ROADMAP.md.
- [x] **v1.40 Automated Operator-UI Critique and Forward-Only Iteration Harness** — Phases 194–197; shipped on 2026-08-27. Archive: milestones/v1.40-ROADMAP.md.
- [x] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** — Phases 189–193; shipped on 2026-07-03. Archive: milestones/v1.39-ROADMAP.md.
- [x] **v1.38 Operator UI Page-by-Page IA and Design-System Polish** — Phases 181–188; shipped on 2026-06-30. Archive: milestones/v1.38-ROADMAP.md.
- [x] **v1.37 Operator Surface Design-System Stress Test and Component System** — Phases 171–180; shipped on 2026-06-20. Archive: milestones/v1.37-ROADMAP.md.
- [x] **v1.36 Operator Surface Light Mode** — Phases 166–170; shipped on 2026-06-14. Archive: milestones/v1.36-ROADMAP.md.
- [x] **v1.35 Unified Logo and Brand Book v2** — Phases 159–165; shipped on 2026-06-12. Archive: milestones/v1.35-ROADMAP.md.
- [x] **v1.34 Local Docker Admin UI DX** — Phases 154–158; shipped on 2026-06-07. Archive: milestones/v1.34-ROADMAP.md.

Earlier milestones are recorded in MILESTONES.md and their archives under milestones/.

## Current Position

v1.48 is active on the current-main planning base `d35b9422`; the published package remains 1.1.0. The maintainer approved the six-phase scope/order and PhoenixStorybook with Phoenix LiveView/HEEx. The first investigation slice is an early proof point; completion requires every existing Admin route/job/state to receive the new design and a supported acceptance disposition.

The approved identity is `brand/BRAND.md` (edition 2026-11-03, approved 2026-11-10), `brand/brand.json` and `brand/assets/README.md`, now deliberately imported into this checkout. Old `brandbook/` consumers remain until their runtime/package/doc/test migration. The retained candidate's 31 edits remain comparison inputs pending Phase 248 disposition. The dated baseline and historical screenshots are provenance, not fresh evidence of this candidate's runtime, advisories or rendered UI.

## Delivery boundaries and gates

- The approved [proposal](research/2026-11-10-brand-admin/milestone-proposal.md), [adversarial closure](research/2026-11-10-brand-admin/milestone-adversarial-review.md), [v1.48 synthesis](research/v1.48-SUMMARY.md), [requirements](REQUIREMENTS.md) and [delivery policy](conventions/research-verification-and-efficiency.md) govern every phase. Initial foundation-first advice in older research is superseded by this approved order; `research/SUMMARY.md` remains historical.
- Phase 248 owns the previously approved fail-closed mount correction and issue #61/#90 diagnosis, bounded compatible remediation and named disposition tracking. The mount contract gates mounted-route acceptance. Unresolved reachable runtime risks block affected acceptance and release; unexplained required-suite failure blocks trustworthy completion claims. Scope approval does not accept residual risk. A remedy requiring a new compatibility policy or larger foundation capability stops the affected path for a consequential decision; independent safe work can continue.
- Broader Safe by default work remains separately queued, including restore/transaction-ID, SQL/CSV/PgBouncer and support-floor proposals. No support-floor, public API, schema, route, config or telemetry change is implied beyond the approved mount policy. Preserve host-owned authentication, tenant scope, audit truth and optional Phoenix/LiveView.
- Use the existing PhoenixStorybook in the example dev/test boundary and shared production LiveView/HEEx components. No React, speculative Fablebook adapter, new runtime dependency, generic second registry, paid critic, new CI job, second demo app, login/white-label API or incidental backend expansion.
- Accessibility, brand, host-route, domain and matched visual checks accompany earlier affected changes. Phase 253 alone owns complete-UI acceptance. Match capture route/scenario/clock/theme/browser/viewport/zoom conditions while recording distinct before/after source and served assets. Static stories, image counts and digests do not establish lifecycle, authorization, database or user-comprehension claims.
- Preserve `workflow.use_worktrees: true`. The historical-root negotiated executor-isolation lookup returned none; this planning checkout does not prove executor binding. Re-resolve supported isolation in the active checkout before executor dispatch and stop dispatch if it cannot be established. Do not silently opt out or execute unisolated concurrent work.
- **Carried REL-01:** the first natural release PR must have its first CI run green without a separate CHANGELOG-dating PR; its landing change includes its own Unreleased prose. [Original evidence](milestones/v1.47-phases/247.1-close-gap-rel-01-rel-02-releasable-type-guard-and-release-pr/247.1-REL01-EVIDENCE.md) remains authoritative. Local readiness cannot complete this live clause. Package version, merge/publish and any residual-risk decision require their actual authority; without live proof the clause stays pending and disclosed.

## Phases

Granularity is `coarse`; the six approved delivery boundaries remain intact because each completes a distinct existing user workflow or prerequisite. Phase IDs are sequential, continuing after completed Phase 247.1.

- [x] **Phase 248: Reconcile the base and safety/proof ownership** - A preserved current-main candidate has fail-closed access and trustworthy affected verification. (completed 2026-11-11)
- [x] **Phase 249: Map jobs, scenarios and the brand contract** - Existing jobs and states have coherent ordinary examples and explicit proof ownership. (completed 2026-11-12)
- [ ] **Phase 250: Brand foundation and first whole investigation** - Support completes one branded investigation through real host routes.
- [ ] **Phase 251: Complete investigation and inspection screens** - Every remaining investigation and inspection job uses the proven design.
- [ ] **Phase 252: Complete operations and connected catalog review** - Export and Retention jobs remain safe and useful catalog states connect to real proofs.
- [ ] **Phase 253: Inclusive integration, docs, package and release readiness** - The complete existing Admin is accepted against current evidence with truthful release limits.

## Phase Details

### Phase 248: Reconcile the base and safety/proof ownership

**Goal**: Maintainers can develop against a preserved current-main candidate whose host mount fails closed and whose advisory and affected-suite evidence is trustworthy.
**Depends on**: Nothing in v1.48 (continues after completed Phase 247.1)
**Requirements**: ADM-01, ADM-02, ADM-03, ADM-04
**Success Criteria** (what must be TRUE):
1. Maintainers can identify the isolated current-main candidate, trace the approved brand source, and find a port/replace/defer decision for every retained UI edit without losing the old checkout.
2. A host mount missing the required authorization contract fails closed with actionable migration guidance; allowed and denied paths demonstrate the approved policy without exposing scoped history.
3. Maintainers can inspect current root/example advisory diagnoses and compatible remedies for issue #61; any unresolved reachable runtime risk names the affected acceptance and release paths it blocks.
4. Maintainers can reproduce and attribute issue #90's current-candidate failure, verify its repair through the affected checks, and distinguish unresolved proof from passing evidence without weakened gates or speculative retries.
**Plans**: 4 (reviewed; four ordered waves)
**UI hint**: yes
**Canonical references**: [Compatibility research input](research/2026-11-10-brand-admin/milestone-compatibility-sequence.md), [dated baseline](research/2026-11-10-brand-admin/milestone-live-baseline.json), [proposal and non-waiver gates](research/2026-11-10-brand-admin/milestone-proposal.md), [host router](../lib/threadline/operator_surface/router.ex), [authorization](../lib/threadline/operator_surface/auth.ex), [mount contracts](../test/threadline/operator_surface/router_test.exs), [advisory gate](../test/threadline/deps_audit_gate_test.exs). Fresh diagnosis belongs to this phase; the dated reports are not a passing receipt.

### Phase 249: Map jobs, scenarios and the brand contract

**Goal**: Maintainers can trace every supported Admin job and state to its shared renderer and executable proof, using coherent ordinary fictional help-desk scenarios.
**Depends on**: Phase 248
**Requirements**: ADM-05, ADM-06, ADM-07
**Success Criteria** (what must be TRUE):
1. Maintainers can locate every existing route, job, meaningful state and unique supported action in the existing inventory, with its shared renderer, executable proof or reasoned unsupported/not-applicable disposition.
2. Support examples tell consistent ordinary stories across organizations, actors, records, actions, transactions, chronology and return paths while private fixture identities remain stable.
3. Maintainers can select ordinary data separately from named empty, failed, denied, boundary, long-content, Unicode and duplicate-label cases; calendar/reset drift and relevant SEED-008 findings have explicit dispositions.
**Plans**: 4 (independently checked; three ordered waves)

**Wave 1**
- [x] 249-01-PLAN.md — Semantic route, state and proof mapping
- [x] 249-02-PLAN.md — Calendar and canonical reset correction

**Wave 2** *(blocked on 249-02)*
- [x] 249-03-PLAN.md — Write-time seed chronology and snapshot proof

**Wave 3** *(blocked on 249-01, 249-02 and 249-03)*
- [x] 249-04-PLAN.md — Scenario selection, brand references and independent reconciliation

**UI hint**: yes
**Canonical references**: [Approved scope](research/2026-11-10-brand-admin/milestone-proposal.md), [source synthesis and carry triggers](research/v1.48-SUMMARY.md), [brand](../brand/BRAND.md), [brand roles](../brand/brand.json), [host routes](../examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex), [existing journey inventory](../examples/threadline_phoenix/e2e/support/operator-journey-inventory.json), [ordinary fixtures](../examples/threadline_phoenix/test/support/help_desk_fixtures.ex), [demo seed](../examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex), [catalog fixtures](../examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex). The brand-contract map guides later work without closing Phase 250's requirements.

### Phase 250: Brand foundation and first whole investigation

**Goal**: Support can complete the Timeline-to-transaction-to-record-history investigation and return to the original search in a coherent brand-aligned Admin.
**Depends on**: Phase 249; Phase 248 mount and affected-proof gates before mounted-route acceptance
**Requirements**: ADM-08, ADM-09, ADM-10, ADM-11, ADM-12, ADM-13, ADM-14, ADM-16, ADM-17
**Success Criteria** (what must be TRUE):
1. Support sees the unchanged approved spool assets at supported sizes, semantic colors satisfying all eight contrast IDs in both themes, and served licensed Familjen Grotesk/Geist/IBM Plex Mono in their approved roles; offline delivery and host opt-out/system fallback remain usable.
2. Dark-default, full light and System modes apply immediately and resolve on the server through the existing native CSRF-protected theme flow, with artwork, links, focus and control boundaries keeping their distinct roles.
3. Support can find a ticket change, inspect its transaction, exact values and actor, open record history, copy the complete identifier and return with the original search intact through mounted host routes.
4. UI/docs use the approved plain vocabulary while users can distinguish action/change/transaction/request, actor/user and accepted/completed work; exact old/new values, Redacted, left out, null, missing and unavailable remain unambiguous without assurance claims or color-only operation meaning.
5. Displayed times name their zone and compact identifiers retain the full unchanged value, keyboard access and truthful copy success/failure feedback while compatible public names and query contracts remain intact.
**Plans**: 8 plans in 8 ordered waves
**Wave 1**
- [x] 250-01-PLAN.md — Baseline ordinary investigation and durable pair custody (complete 2026-11-12)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 250-02-PLAN.md — Approved semantic tokens and supplied header artwork (complete 2026-11-12)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 250-03-PLAN.md — Local licensed font roles and host fallback (complete 2026-11-12)

**Wave 4** *(blocked on Wave 3 completion)*
- [ ] 250-04-PLAN.md — Immediate native theme selection

**Wave 5** *(blocked on Wave 4 completion)*
- [ ] 250-05-PLAN.md — Owned docs, favicon and package assets

**Wave 6** *(blocked on Wave 5 completion)*
- [ ] 250-06-PLAN.md — Timeline filters and typed shared state

**Wave 7** *(blocked on Wave 6 completion)*
- [ ] 250-07-PLAN.md — Exact transaction/history values and identity

**Wave 8** *(blocked on Wave 7 completion)*
- [ ] 250-08-PLAN.md — Matched after proof and independent review
**UI hint**: yes
**Canonical references**: [Approved foundation and slice](research/2026-11-10-brand-admin/milestone-proposal.md), [identity](../brand/BRAND.md), [machine-readable roles](../brand/brand.json), [supplied assets](../brand/assets/README.md), [migration parity contract](../test/threadline/brandbook_token_parity_test.exs), [theme tokens](../lib/threadline/operator_surface/style/01_tokens.css), [logo](../lib/threadline/operator_surface/components/logo.ex), [font boundary](../lib/threadline/operator_surface/fonts.ex), [theme controller](../lib/threadline/operator_surface/controllers/theme_controller.ex), [investigation journey](../examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts), [presentation](../lib/threadline/operator_surface/presentation.ex). This slice does not close the milestone.

### Phase 251: Complete investigation and inspection screens

**Goal**: Engineers and support staff complete all remaining existing investigation and inspection jobs with scoped context, exact audit meaning and the new shared design.
**Depends on**: Phase 250
**Requirements**: ADM-15, ADM-18, ADM-19, ADM-20, ADM-21, ADM-22
**Success Criteria** (what must be TRUE):
1. Timeline filters, saved views, direct entry, reload, browser back and return links preserve validated query state and host scope.
2. Home lookups and actor/correlation pivots reach the intended scoped history, including non-human and absent actors; supported record/transaction history and as-of paths retain exact identity, deletion/history-gap meaning and return context without new composite-key navigation.
3. Audited-table inspection shows current schema-specific facts and actionable remediation, distinguishing not audited, not inspected, denied and unavailable without an all-schema default.
4. Redaction inspection distinguishes configured from deployed policy and provenance, replaced from left-out values, and supported empty/error recovery paths.
5. Operational Evidence inspection preserves subject scope, observation/provenance and genuine availability limits; it does not call every evidence record record history.
**Plans**: 0 (not planned)
**UI hint**: yes
**Canonical references**: [Approved complete-screen scope](research/2026-11-10-brand-admin/milestone-proposal.md), [domain meanings](../prompts/audit-lib-domain-model-reference.md), [Home](../lib/threadline/operator_surface/live/start_live.ex), [Timeline](../lib/threadline/operator_surface/live/timeline_live.ex), [Actor](../lib/threadline/operator_surface/live/actor_live.ex), [record history](../lib/threadline/operator_surface/live/row_history_live.ex), [audited tables](../lib/threadline/operator_surface/live/coverage_live.ex), [Redaction](../lib/threadline/operator_surface/live/policy_redaction_live.ex), [Evidence](../lib/threadline/operator_surface/live/evidence_live.ex), [route/state browser proof](../examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts), [existing journey inventory](../examples/threadline_phoenix/e2e/support/operator-journey-inventory.json).

### Phase 252: Complete operations and connected catalog review

**Goal**: Operators complete permitted Export and Retention jobs safely through the new interface, and maintainers can review shared production patterns in the connected PhoenixStorybook catalog.
**Depends on**: Phase 251
**Requirements**: ADM-23, ADM-24, ADM-25
**Success Criteria** (what must be TRUE):
1. Operators can export the scoped source query with separate authorization, distinguish queued/accepted/completed/failed states, follow recovery links and download only completed authorized output.
2. Operators can preview Retention consequences, explicitly confirm or cancel, and inspect persisted outcomes; event-time authorization and reconnect protection prevent automatic mutation replay.
3. Maintainers can review useful primitives, patterns, assemblies and screen states in the existing dev/test-only PhoenixStorybook, linked to the existing fixture/journey inventory and mounted-route proofs while reusing production components without a second registry.
**Plans**: 0 (not planned)
**UI hint**: yes
**Canonical references**: [Approved operations/catalog scope](research/2026-11-10-brand-admin/milestone-proposal.md), [export status](../lib/threadline/operator_surface/live/export_status_live.ex), [download controller](../lib/threadline/operator_surface/controllers/export_controller.ex), [retention history](../lib/threadline/operator_surface/live/retention_history_live.ex), [Retention domain](../lib/threadline/retention.ex), [catalog root](../examples/threadline_phoenix/storybook/index.exs), [catalog boundary](../test/threadline/operator_surface/storybook_boundary_test.exs), [catalog browser proof](../examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts), [complete operation journeys](../examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts).

### Phase 253: Inclusive integration, docs, package and release readiness

**Goal**: Maintainers can establish that every existing Admin job works in the new design under the supported inclusive-use conditions, and can assess current documentation, package and release readiness honestly.
**Depends on**: Phase 252; all unresolved Phase 248 affected acceptance/release gates remain binding
**Requirements**: ADM-26, ADM-27, ADM-28, ADM-29, ADM-30, ADM-31, ADM-32, ADM-33, ADM-34
**Success Criteria** (what must be TRUE):
1. Users complete changed controls and whole jobs with correct accessible names, keyboard order, actual focused target, visible focus and focus return; representative ordinary/high-risk jobs work at narrow/reflow, embedded-container widths and real browser zoom measured against the intended container.
2. Both themes, touch, selected forced-colors states and reduced motion preserve supported interaction and operation/status meaning without color-only or motion-only feedback.
3. Readers find the new identity and truthful language consistently in current README/guides/example docs/ExDoc; working assets, anchors, code contracts and migrated tests agree, and the package ships only needed assets/fonts/licenses while optional Phoenix/LiveView, host CSS/font/script and dev/test Storybook boundaries hold.
4. Maintainers can reconcile every existing route/job/state disposition with current behavior, database, host-route and browser proof, matched before/after capture identities and bounded independent design/copy review; required existing canonical gates and CI establish the exact candidate without new jobs, redundant cross-product runs or weakened checks.
5. Maintainers receive migration notes, evidence limits, measured CI/CD conclusions and a truthful package/release recommendation that keeps unresolved safety/proof gates and REL-01 visible; local readiness grants no version bump, risk acceptance, merge or publication authority and cannot complete the live next-release clause.
**Plans**: 0 (not planned)
**UI hint**: yes
**Canonical references**: [Approved acceptance](research/2026-11-10-brand-admin/milestone-proposal.md), [verification/DX research](research/2026-11-10-brand-admin/milestone-verification-dx.md), [delivery defaults](conventions/research-verification-and-efficiency.md), [README](../README.md), [Admin guide](../guides/operator-surface.md), [example README](../examples/threadline_phoenix/README.md), [package boundary](../mix.exs), [optional-dependency contract](../test/threadline/optional_deps_contract_test.exs), [journey evidence contract](../test/threadline/browser_journey_evidence_contract_test.exs), [accessibility proof](../examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts), [actual zoom proof](../examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts), [CI topology](../.github/workflows/ci.yml), [carried live-release evidence](milestones/v1.47-phases/247.1-close-gap-rel-01-rel-02-releasable-type-guard-and-release-pr/247.1-REL01-EVIDENCE.md).

## Progress

Execution order:248→249→250→251→252→253. Phase248 is verified complete (15/15 truths,ADM01–04), all four plans are GSD-reconciled, and the accepted plain repeat passed. The automated transparency judgment remains visibly non-authoritative; external receipts and publication stay unclaimed. Totals:six phases,two complete,eight currently planned plans,eight complete plans. Phase250 discussion/planning now proceeds under the original autonomous scope.

| Phase | Plans Complete | Status | Completed |
| --- | --- | --- | --- |
| 248. Reconcile the base and safety/proof ownership | 4/4 | Complete    | 2026-11-11 |
| 249. Map jobs, scenarios and the brand contract | 4/4 | Complete    | 2026-11-12 |
| 250. Brand foundation and first whole investigation | 3/8 | In progress | - |
| 251. Complete investigation and inspection screens | 0/0 | Pending | - |
| 252. Complete operations and connected catalog review | 0/0 | Pending | - |
| 253. Inclusive integration, docs, package and release readiness | 0/0 | Pending | - |

## Next

Phase249 is independently complete at48/48 unique truths, with clean current formal review and no open review findings. Continue Phase250 brand foundation and the first whole investigation; reuse approved current brand, coherent fixtures and the existing private foundation/adversarial preparation. No user acknowledgment is needed. Preserve full-repeat, external action and publication authority limits.
