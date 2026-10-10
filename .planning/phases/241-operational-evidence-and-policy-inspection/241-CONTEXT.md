# Phase 241: Operational evidence and policy inspection - Context

**Gathered:** 2026-10-10
**Status:** Ready for planning
**Approval:** The maintainer directed the workflow to continue and auto-follow recommendations. Three targeted advisor reviews were synthesized; no unresolved high-impact scope, public-contract, or security decision remains.

<domain>
## Phase Boundary

Refine the existing schema-scoped Audit coverage, Evidence, and Redaction policy operator pages so engineers and support/on-call operators can act on capture gaps, understand what evidence was recorded and what it cannot establish, and compare configured policy with deployed trigger policy. Use the existing Phoenix/LiveView routes, host-managed migration workflow, reads, and private UI primitives. Preserve host authentication, authorization, tenant scope, existing route and public 1.x contracts, redaction behavior, and Phoenix optionality. Do not add backend capabilities, public APIs, routes, a role model, dependencies, a component package, or automatic migration application.

</domain>

<decisions>
## Implementation Decisions

### Schema-scoped capture coverage and migration remediation
- **D-01:** Keep selected-schema coverage as the primary workflow and preserve the validated `?schema=` URL state. Identify every table together with the selected host schema, and keep covered, uncovered, expected-gap, empty, unavailable, and stale last-known results distinct. An inspection failure must never present an empty result as a healthy or confirmed-empty assessment; stale rows must remain visibly labeled with their observation time.
- **D-02:** Make uncovered-table remediation lead to the host-owned generated migration and then the schema-specific coverage verifier. Offer a copyable schema-qualified `mix threadline.gen.triggers --tables SCHEMA.TABLE` command only for conservative identifiers accepted by the generator. For identifiers that cannot be safely rendered as a shell command, keep the exact schema/table visible and provide a manual migration path. The UI never applies a migration.
- **D-03:** Keep cross-schema inventory out of this phase. Preserve the scoped page and direct remediation rather than introducing a broad catalog view or a new health query.

### Evidence projection, proof history, and completeness limits
- **D-04:** Keep the existing latest-projection → subject-reference proof-history flow. Preserve the selected subject and reference in history navigation, distinguish `summary_status` from the proof assessment, and render only bounded, explicitly approved evidence fields. Do not expose arbitrary host-provided `detail`, `provenance`, or raw maps as generic JSON or copy payloads.
- **D-05:** Distinguish no matching Threadline evidence for the selected subject/reference from disabled access and from a failed/unavailable read. No matching record means no Threadline evidence was recorded for that selection; it does not establish that no underlying activity occurred. A read failure must render an unavailable state rather than crash or reuse the empty state.
- **D-06:** Make the evidence claim boundary explicit: a `proven` assessment applies to the recorded snapshot, `inferred_posture` is inferred, and `unsupported` remains unsupported. Latest projection and append-only history describe recorded Threadline evidence; neither proves overall capture completeness or the absence of unrecorded activity. If a later view applies a time range or result cap, label that scope and its completeness limit. Do not add public evidence APIs, new proof statuses, or history pagination in this phase.

### Configured and deployed redaction policy
- **D-07:** Keep the per-table normalized comparison of configured `exclude`, `mask`, and placeholder settings against successfully inspected deployed trigger policy. Lead with actionable drift and keep matching rows available for confirmation; show unreadable/unrecognized trigger state separately from a match.
- **D-08:** Treat a known missing trigger for a configured table as `drift_detected` even when the configured redaction policy is empty; preserve the specific missing-trigger warning and migration remediation. Reserve `could_not_introspect` for an existing deployment that cannot be safely interpreted. Keep the documented three-value public status set; do not add a new enum value. A table may enter the all-clear result only after successful inspection confirms a match.
- **D-09:** Never include raw trigger SQL, audit sample values, or redacted values in the presenter report or rendered UI. Keep copy controls limited to safe policy/remediation text. Verify absence of sensitive canaries in HTML and copy attributes; if a copy affordance is added, test the browser's actual clipboard result too. Policy comparison describes current deployed trigger definitions and does not claim historical rows or downstream exports were redacted.

### Cross-cutting presentation and verification
- **D-10:** Carry forward the approved Threadline identity, equal engineer/operator priority, code-first Impeccable approach, calm and precise domain language, existing tokens and private Phoenix/HEEx primitives, and the current route architecture. Use the most fitting existing representation: responsive table rows for coverage and policy comparison, evidence cards for subject records; do not force unlike evidence into a generic table or nested panels.
- **D-11:** Recheck affected journeys at narrow, intermediate, and desktop sizes, actual browser zoom where available, Light/Dark/System themes, keyboard and touch, visible focus, error/empty/pending/stale states, and reduced motion. Preserve the current boundary between server-owned authorization/scope and validated URL state. Automate behavioral and rendered checks; record tool limitations as evidence gaps, not as passing proof.

### the agent's Discretion
- Choose exact concise status copy, grouping and ordering, disclosure details, and responsive presentation within these decisions and the existing design system.
- Select the smallest meaningful ExUnit and mounted-browser regressions, prove the affected routes and copy paths, and avoid asserting visual structure that does not represent a user task.
- Prefer existing named verification entrypoints and verify that the relevant test files are discovered by CI.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product scope, language, and design authority
- `.planning/ROADMAP.md` — v1.46 delivery boundary, Phase 241 goal, dependencies, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — UIO-02, UIO-03, and UIO-04 acceptance contracts and ownership.
- `.planning/PROJECT.md` — project constraints, architecture, and zero-human-verification policy.
- `PRODUCT.md` — operator personas, JTBD, product language, security boundaries, and evidence limits.
- `.planning/UI-MILESTONE-PREFLIGHT.md` — approved code-first approach, sibling-project lessons, and verification cautions.
- `.planning/research/SUMMARY.md` — approved v1.46 research and scope.
- `.impeccable/config.json` — code-first Impeccable workflow setting.
- `prompts/Threadline Brand Book.txt` — voice and identity authority.
- `prompts/audit-lib-domain-model-reference.md` — domain model, layer boundaries, health/coverage/redaction intent, personas, and explicit uncertainty principles.
- `prompts/threadline-elixir-oss-dna.md` — named verification entrypoints, CI and traceability expectations.

### Previously locked operator decisions
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-CONTEXT.md` — identity, scope, responsive/accessibility expectations, and source-bound verification.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-CONTEXT.md` — URL validation, host-owned scope, truthful states, responsive presentation, and evidence/redaction protections.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-UI-SPEC.md` — existing component, accessibility, interaction, and responsive contracts.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-SECURITY.md` — operator threat boundaries and redaction protections.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-UI-REVIEW.md` — rendered findings and known visual-evidence limits.
- `.planning/phases/240-connected-investigation-and-recovery/240-CONTEXT.md` — exact-value/copy boundaries, host authorization, safe URL state, and motion behavior.

### Domain documentation and prior art
- `guides/domain-reference.md` — stable `mix threadline.policy.show --json` status values and policy evidence limitations.
- `guides/operator-surface.md` — supported operator routes, coverage/policy concepts, and current operator contracts.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView state, URL navigation, lifecycle, and patch behavior.
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md` — Phoenix routing and interface patterns.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — host boundaries, Ecto integration, and system design.
- `prompts/prior-art/SOURCE-CANONICAL.md` — provenance of the local prior-art set.

### Existing implementation and tests
- `lib/threadline/operator_surface/live/coverage_live.ex`, `lib/threadline/operator_surface/coverage/on_mount.ex`, `lib/threadline/operator_surface/coverage/snapshot.ex`, `lib/threadline/health/coverage_schemas.ex`, and `lib/threadline/operator_surface/presentation.ex` — schema validation, coverage states, selected-schema navigation, and remediation command generation.
- `lib/threadline/operator_surface/live/evidence_live.ex`, `lib/threadline/evidence.ex`, `lib/threadline/evidence/proof.ex`, `lib/threadline/evidence/subject.ex`, and `lib/threadline/governance/evidence_record.ex` — latest and history reads, proof assessments, allowed subjects, and recorded evidence fields.
- `lib/threadline/operator_surface/live/policy_redaction_live.ex`, `lib/threadline/policy/redaction_presenter.ex`, and `lib/threadline/capture/redaction_policy.ex` — configured/deployed comparison, trigger introspection and normalized redaction rules.
- `test/threadline/operator_surface/live/coverage_live_test.exs`, `test/threadline/operator_surface/live/evidence_live_test.exs`, `test/threadline/operator_surface/live/policy_redaction_live_test.exs`, `test/threadline/policy/redaction_presenter_test.exs`, and `test/threadline/policy/redaction_presenter_catalog_test.exs` — current route and presenter contracts.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`, `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, and `operator-earned-flows.spec.ts` — mounted route states, accessibility, motion, and end-to-end operator journeys.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CoverageLive` already has validated selected-schema URL state, per-table coverage buckets, safe remediation disclosures, a refresh control, and stale last-good labels. `CoverageSchemas` validates host schemas and enumerates available schemas.
- `EvidenceLive` already separates the latest projection from append-only history for a single subject reference; `Evidence.Proof.present_record/1` exposes `proven`, `inferred_posture`, or `unsupported` without requiring generic detail rendering.
- `Policy.RedactionPresenter` already normalizes deployed trigger SQL to policy fields and groups `drift_detected`, `could_not_introspect`, and `config_matches_deployed`; the LiveView has no application copy control.
- `Presentation.coverage_remediation/2`, existing UI data/display primitives, shared tokens, responsive table styles, and route-state Playwright fixtures are reusable.

### Established Patterns and Gaps
- Coverage query parameters are validated against `pg_namespace`; each read is schema-scoped. On initial/cross-schema errors the current zero-count snapshot can still be rendered as “No audited tables found,” so the unknown/unavailable state needs a distinct verdict. Stale last-good data already carries an error and observation time.
- Remediation commands currently auto-generate only for conservative public-schema identifiers; non-public or unusual identifiers fall back to a manual host-migration instruction. The generator accepts schema-qualified names, so a safe schema-qualified command can be added without a new backend API.
- Evidence currently renders the proof assessment and summary status separately, but its query path has no explicit read-error state. An empty result currently says “No evidence records yet”; it must not be reused for a failed read. Subject references may be host-provided maps, so do not expose arbitrary detail/provenance maps.
- Redaction introspection returns normalized policy fields, not raw `pg_proc.prosrc`. A configured table with no trigger and an empty/default policy is currently counted as a match; known missing triggers must be non-green. The docs define the three JSON status values as stable.

### Integration Points
- Coverage corrections connect the coverage verdict, schema selector, remediation disclosure, topbar coverage snapshot, and `CoverageLive` tests.
- Evidence corrections connect query errors, empty states, per-record status/assessment, subject-reference history links, copy/display primitives, and `EvidenceLive` tests.
- Redaction corrections connect presenter status classification and summary counts to the LiveView sections, policy contract docs, status chips, and secret-canary tests.
- Affected pages share the existing shell, tokens and responsive styles; browser proof should use the Phoenix example and the mounted route/accessibility suites.

</code_context>

<specifics>
## Specific Ideas

Research recommended selected-schema triage with an exact safe host-migration command, keeping latest evidence → subject-reference history while stating what a proof assessment does not establish, and retaining the normalized configured-versus-deployed redaction comparison. A known missing trigger is drift even when the configured rule set is empty; only an inspected matching trigger can count toward all-clear. A missing evidence record is not proof that no activity occurred, and a database read failure is unavailable data, not an empty result.

</specifics>

<deferred>
## Deferred Ideas

- All-schema coverage inventory and new health/backend queries — outside the selected-schema inspection scope.
- New evidence public APIs, statuses, pagination, proof signatures, generic raw detail display, or conclusions about unrecorded activity — require separate scope and contract decisions.
- Automatically applying host migrations, adding a new redaction status value, or expanding policy management beyond read-only inspection.
- Export and retention operations remain Phase 242; integrated final review and release recommendation remain Phase 243.

</deferred>

---

*Phase: 241-operational-evidence-and-policy-inspection*
*Context gathered: 2026-10-10*
