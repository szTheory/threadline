# Phase251: Complete investigation and inspection screens — Context

**Gathered:** 2026-11-12
**Status:** Ready for planning

<domain>
## Phase boundary

Complete the remaining existing investigation and read-only inspection jobs under ADM-15/18/19/20/21/22. Keep existing routes, query names, host authentication/authorization/scope, trigger-backed capture, public1.x integration and single-key record navigation. Phase250's brand foundation, exact valid return-context repair and original matched Acme materialization are accepted; do not repeat their implementation or whole journey as substitute proof for new work.
</domain>

<decisions>
## Implementation decisions

### Validated navigation and snapshot meaning

- **D-01:** Retain250's canonical URL-backed valid filters, explicit unconstrained `from=` intent, path-table identity, direct-entry defaults and UI-link return contract. Host scope always comes from host assigns/callbacks, never query parameters. Exercise the changed lifecycle through existing Home, saved-view, actor/correlation and history owners; keep nonhuman ActorRefs and absent/anonymous no-person-link semantics.
- **D-02:** Unsupported-only Timeline requests and malformed saved filters must not silently turn into broader unfiltered reads. Preserve `FilterParams.parse/1`'s existing allowlist/unknown-key-dropping compatibility for its shared callers; apply the needed UI/saved-view validation at their existing boundaries. Revalidate stored filter values before canonicalization/apply and preserve explicit unconstrained intent. Keep an actual bare Timeline visit's default window separate from deliberate unfiltered Apply. Do not create atoms from input or add new URL/config/API names.
- **D-03:** Preserve250's safe bare-Timeline recovery when retained context is invalid, but make the loss of that context visible on the existing route. Do not claim the original filters survived. Keep valid context exact and keep host scope enforced; an unknown origin never becomes authority. Do not re-open the accepted valid-return fix.
- **D-04:** Missing/blank `as_of` keeps existing latest/default behavior. A malformed nonempty explicit time produces a visible invalid-snapshot state in both standalone and transaction-origin history, without silently choosing latest/current. Preserve valid UTC/offset handling and the distinct deleted-record/before-audit-horizon outcomes. Clearing the existing form must retain its blank/default intent, rather than synthesize a malformed timestamp. Keep the complete record identity and validated return context; no composite-key navigation.

### Scoped inspection and truthful recorded metadata

- **D-05:** Coverage describes only the selected schema and the actual current read. Empty/expected-only results are not global capture-completeness claims. Keep not-audited/incomplete, expected gap, not inspected, host denied, feature unavailable, read unavailable and same-schema stale states distinct. Other schemas remain explicitly uninspected. Keep the shared header aligned with the selected/current snapshot or a truthful unavailable/not-inspected state; never leave a successful custom-schema refresh showing the old public snapshot. Keep schema-specific remediation and all-schema default off.
- **D-06:** Redaction compares configured policy with the currently deployed trigger definition. Align every zero-policy section with “no configured policy to compare”; never combine it with all-clear/full-introspection claims. Show selected schema, successful inspection time/source, and clear Left out/not recorded versus Redacted/replacement meanings. Preserve missing-trigger drift versus unreadable deployment versus unavailable read. Keep stale/failure recovery honest and normalize unexpected schema/read errors to safe copy without raw database diagnostics/SQL. This is current-definition inspection, not historical/export verification.
- **D-07:** Operational Evidence remains subject/reference-scoped latest projection or append-only snapshot history, distinct from row history. Label recorded time as snapshot recording time. Add only a bounded view-private Recorded provenance summary: an exact expected writer/subject-entrypoint pair may be recognized; custom/unknown metadata is summarized without values. Writer/entrypoint are caller-overridable recorded metadata, not verified/authenticated identity. Never render arbitrary provenance/detail maps, actor IDs or canaries; retain genuine no-match/unavailable/retry and no-overall-completeness limits.

### Delivery, proof and ownership

- **D-08:** Use two coherent sequential implementation/proof groups: navigation/history and scoped inspection. Reuse existing production `UI.Page`, `UI.Data`, `UI.Display`, `UI.Form`, `UI.Actions`, brand roles and Phoenix LiveView/HEEx. No new dependency, registry, general engine, adapter, API, login/white-label or global visual redesign. Couple changed markup/signatures to stable inventory IDs, exact source locators and independent/negative controls in each group. Plan required Nyquist/security/code/UI final report schemas and regression owners up front, then use bounded delta confirmations.
- **D-09:** Each changed visual/state boundary gets a small matched before/after capture at the actual route/scenario/source/served-assets/browser/viewport/theme/clock conditions plus behavior/accessibility proof. Preserve250's original data/capsules and label reused source-compatible evidence honestly. Use existing named ExUnit/Node/browser owners and exact nonzero first-attempt case sets; no native clipboard/permission proof, focus theft, new runner or broad matrix by default. Dedicated owned local DB/app custody and prepared locks/tools remain; a consumed full-repeat grant is not renewed. Phase253 still owns real zoom, broad inclusive/error-layout pixels and release readiness.

### Agent discretion

Routine private implementation and reversible copy/layout corrections follow these evidence-supported defaults under the existing autonomous authorization. No architect-level decision remains unresolved and no user acknowledgement is required. Do not infer risk, release or external-action authority.
</decisions>

<canonical_refs>
## Canonical references

- `.planning/REQUIREMENTS.md` — ADM-15/18/19/20/21/22 and remaining phase boundaries.
- `.planning/ROADMAP.md` — approved251/252/253 jobs and canonical source/proof owners.
- `.planning/PROJECT.md` — current milestone and standing constraints; use current sections.
- `.planning/conventions/research-verification-and-efficiency.md` — research, compatibility, useful automated gates and measured efficiency.
- `prompts/audit-lib-domain-model-reference.md`; `prompts/threadline-elixir-oss-dna.md` — capture/semantics/operations distinctions and OSS practices.
- `brand/BRAND.md`; `brand/brand.json`; `brand/assets/README.md` — signed-off authority; preserve existing old consumers until their owner migrates them.
- `.planning/research/2026-11-10-brand-admin/milestone-proposal.md`; `.planning/research/2026-11-10-brand-admin/milestone-product-scope.md` — complete-screen scope.
- `.planning/research/2026-11-12-phase251/navigation.md`; `.planning/research/2026-11-12-phase251/inspection.md`; `.planning/research/2026-11-12-phase251/adversarial.md` — current-source independent drift/role research; tests named there are owners, not fresh receipts.
- `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md`; `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-UI-SPEC.md`; `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-PAIR-EVIDENCE.md`; `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-VERIFICATION.md`; `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-REVIEW-DISPOSITION.md` — accepted foundation, proof and retained253 observations.
- `lib/threadline/query/filter_params.ex`; `lib/threadline/operator_surface/live/start_live.ex`; `lib/threadline/operator_surface/live/timeline_live.ex`; `lib/threadline/operator_surface/live/timeline_live/helpers.ex`; `lib/threadline/operator_surface/live/actor_live.ex`; `lib/threadline/operator_surface/live/transaction_live.ex`; `lib/threadline/operator_surface/live/row_history_live.ex`; `lib/threadline/operator_surface/live/row_history_component.ex` — navigation and snapshot owners.
- `lib/threadline/operator_surface/live/coverage_live.ex`; `lib/threadline/operator_surface/live/policy_redaction_live.ex`; `lib/threadline/operator_surface/live/evidence_live.ex`; `lib/threadline/operator_surface/coverage/snapshot.ex`; `lib/threadline/health.ex`; `lib/threadline/policy/redaction_presenter.ex`; `lib/threadline/evidence.ex` — inspection/query boundaries.
- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`; `test/fixtures/operator_surface/route-inventory.json`; `test/fixtures/operator_surface/source-surface-checklist.json`; `test/threadline/operator_surface/rendered_output_contract_test.exs` — stable IDs and coupled independent coverage.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`; `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`; `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts`; `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts`, plus their named ExUnit owners — extend existing proof boundaries.
</canonical_refs>

<code_context>
## Existing code insights

There are no current `.planning/codebase` maps; targeted current-source research supplies the scout. Existing URL parsing/canonicalization, query validation, host-owned auth/scope, typed shared states, current font/theme/control components and bounded metadata projections are reusable. Current source at `af4ec7afe606b193eb634d64b5451d9d1a1639b2` confirms the original prefetch return-context defect was repaired in250; Home/Actor and the three inspection pages remain unchanged from the earlier static scan. Shared CSS/UI.Data/browser harness/inventory changed, so only compatible evidence is reused.

Integration stays in the current LiveViews/components and existing tests. No new backend query layer is needed. Home still performs only its existing record/correlation lookups; actor discovery uses existing pivots and filters. Query allowlisting is not host authorization. Catalog fixtures prove static composition only, never a mounted/authorized read.
</code_context>

<specifics>
## Specific ideas

Use actual ordinary help-desk scenarios and separate stress/error fixtures. Facts and selected results remain primary; filters/shell stay tools. Preserve the approved four fonts/supplied artwork/roles and source-bound limits. Source/read time and recorded provenance must not become authenticity/completeness promises.
</specifics>

<deferred>
## Deferred ideas

Export/Retention and connected catalog252; inclusive cross-route/zoom/error pixels, the generic Retry-label refinement, full reconciliation/docs/package/release readiness253. Live REL-01 remains pending its natural release trigger. Authenticated provenance, new actor lookup, composite keys, login/white-label, React/Fablebook and publication remain outside approved251 scope.

### Reviewed todos, not folded

“Run the local gate on its own ephemeral Postgres (bin/with-test-postgres)” matched broad keywords at0.9. The permanent wrapper remains separately queued under the approved fixed phase boundary; this phase reuses the already-owned isolated local PostgreSQL. Keyword score does not authorize a new runner/CI infrastructure project.
</deferred>
