# Phase252: Complete operations and connected catalog review — Context

Gathered2026-11-13. Ready for planning. Autonomous discussion completed in one pass after three independent decision-cluster researchers and adversarial synthesis; no unresolved architect decision remains.

<domain>
## Phase boundary

Deliver ADM-23–25: preserve permitted Export jobs, complete safe Retention consequence preview/confirmation/outcomes, and connect the existing PhoenixStorybook catalog to production patterns and existing journey/fixture/route proof. Phase251 is independently complete. No new domain operation, supported public API/config/route/query/schema, dependency, login, white-label option or release authority is introduced. No plain phase SPEC exists; roadmap/requirements and these decisions constrain implementation.
</domain>

<decisions>
## Decisions

- **D-01 — Preserve Export.** Existing scoped immediate CSV/JSON/NDJSON downloads and unscoped actor-owned asynchronous queue are the accepted split. Preserve committed filters, export-specific authorization, current owner/status/file/expiry checks, recovery and completed-only download. Queue acceptance is feedback, not a new persisted accepted status. Prove existing behavior; change Export only for a demonstrated defect. Do not serialize host scope or promise tenant-scoped background jobs.
- **D-02 — Read-only Retention preview.** Use existing Retention.purge/1 with dry_run:true only after event-time operation authorization. Preview creates no AuditAction/RetentionRun and deletes nothing. It covers the worker's configured Threadline audit store globally, not a tenant or a selected host-table schema. Distinguish AuditChange candidates from potentially empty AuditTransaction candidates; disabled empty-transaction cleanup means not included, not zero eligible.
- **D-03 — Bind the actual worker target.** The mount repo/current storage schema can differ from the worker's captured configuration. Add narrow undocumented coordination in the existing @moduledoc false Pruner: an allowlisted PID/repo/storage-schema/sleep snapshot and same-PID expected-target guarded acceptance. Preserve trigger/0 for every existing caller and all supported API/config contracts. Do not use :sys.get_state in web business logic or expose raw worker state. Match mounted target before counting; recheck the original target after counting before revealing counts. Hold the successful snapshot server-side, reauthorize and recheck before confirmation/audit, write the audit request to that target and never resolve a replacement worker for its guarded trigger. Absent/mismatched/restarted/unreadable target means no visible counts or confirm path. Reject unsupported cross-target mutation rather than silently splitting preview/audit/history/deletion across stores; document this defensive correction in Phase253 migration notes.
- **D-04 — Honest estimate.** The two dry-run counts are sequential, not an atomic snapshot; batch_size/max_batches do not constrain them and the worker recomputes its cutoff later. Show actual preview generation time with UTC and exact counts, label them estimates of eligible history, and disclose that data/settings/run limits can change actual removals. Do not invent a returned cutoff, persist preview lineage or guarantee equal final totals. Successful0/0 remains valid and can proceed through explicit confirmation.
- **D-05 — Explicit deliberate execution.** Require server-held successful-preview state before the existing typed confirmation can invoke pruning; caller parameters cannot supply that state. Preserve constant-time typed validation, cancellation, event-time authorization, audit-before-trigger ordering, active-run coalescing and persisted queued/running/completed/failed outcomes. Cancel/remount clears transient confirmation/preview. Prove offline submit and reconnect cannot replay a mutation; require a fresh preview and deliberate action. A worker death after the audit write can leave a request without a run, as existing ordering allows; it must never retarget another worker. Render actual recorded outcomes and their limits, not preview totals as actual deletions.
- **D-06 — Connected production catalog.** Add an Operations category with Export/Retention :page stories in the existing PhoenixStorybook1.2.0 dev/test boundary. Reuse ExportStatusLive.Components.job_history/1 and narrowly share Retention's existing read-only production rendering/preview content through undocumented internal components used by both callers. Do not duplicate business markup. Extend the existing Storybook Fixtures helper with deterministic static assigns referencing existing ordinary/stress/boundary identities. Never invoke Demo.Seed, Repo, file writes or mutations during story rendering; seed modules are side-effectful. Static destructive controls are inert/absent. Link story documentation to existing route/job/source/fixture/proof identities and validate those links against the one current inventory; no second registry/adapter/engine. Story composition cannot prove real permissions, URL lifecycle, downloads, persistence or reconnect.
- **D-07 — Keep evidence at its boundary.** Reuse owning root/example/browser tests and independent declaration/negative controls. Add meaningful fail-first Retention target/preview/no-write/denial/zero/failure/forged-confirmation/restart controls and a retention-specific mounted no-replay/confirm/persisted-outcome case. Extend existing catalog story contract and smoke routes at existing320/375/768 widths. Scoped HTTP tests own export scope filtering where the example support role intentionally denies export. Keep matched changed-state captures small and source/asset/data/clock/browser/theme/viewport bound; destructive outcomes use separately named isolated fixtures and cannot invalidate the preserved visual pair. Capture all relevant operational job/run data as well as canonical audit materialization. Controlled clipboard doubles only.
- **D-08 — Compatibility and scope.** Threadline package stays1.1.0; PhoenixStorybook stays locked1.2.0. Phoenix/HEEx remains the implementation, no React/Fablebook adoption. Reuse approved brand assets/tokens and dense28px heading contract. Existing global primary-fill refinement, broad error pixels/zoom/inclusive use, docs/package/CI/readiness belong253. No new permanent Postgres runner, dependency or workflow job. Preserve original250/251 fixtures and all explicit stops.
- **D-09 — Execution efficiency.** Keep dependent implementation context together through an explicitly recorded supported isolation strategy; do not blindly launch fresh repeated intake per small slice. Maintain plan/task boundaries and required proof/reviews. All checks/apps background, Node22.14.0, owned PG60025 and dedicated252 partitions, ERL_FLAGS +S4:4. Preflight environment/tools/format before bounded runs; retain every invocation and diagnose before retest. The full-root repeat grant is consumed and stopped; no new window/native clipboard/foreground/external/push/merge/publish/version/risk authority is implied. Finalize closeout records and automated judgment disposition before the last independent verifier fingerprint. Six/four prior engine annotations are not new human acknowledgments; retain actual flags without invented enforcement. Finalize/link the run retrospective at actual autonomous closeout.

### Discretion

Choose private helper/component names, smallest file/task decomposition, existing selectors and readable copy consistent with the exact boundaries above. No architectural menu or routine maintainer UAT is needed.
</decisions>

<canonical_refs>
## Canonical references

Read relevant current sections and actual owners; reuse accepted evidence without whole historical PROJECT/STATE/brand re-intake. Roadmap252/ADM23–25 are the scope. Peer memos and adversarial target-seam follow-up supply evidence; this coherent decision set controls any earlier alternative in a memo.
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/conventions/research-verification-and-efficiency.md`
- `.planning/research/2026-11-10-brand-admin/milestone-proposal.md`
- `.planning/research/2026-11-10-brand-admin/milestone-product-scope.md`
- `.planning/research/2026-11-13-phase252/exports.md`
- `.planning/research/2026-11-13-phase252/retention.md`
- `.planning/research/2026-11-13-phase252/catalog.md`
- `.planning/research/2026-11-13-phase252/adversarial.md`
- `brand/BRAND.md`
- `brand/brand.json`
- `brand/assets/README.md`
- `prompts/audit-lib-domain-model-reference.md`
- `prompts/threadline-elixir-oss-dna.md`
- `lib/threadline/operator_surface/live/export_status_live.ex`
- `lib/threadline/operator_surface/live/export_status_live/components.ex`
- `lib/threadline/operator_surface/controllers/export_controller.ex`
- `lib/threadline/operator_surface/live/retention_history_live.ex`
- `lib/threadline/retention.ex`
- `lib/threadline/retention/pruner.ex`
- `examples/threadline_phoenix/storybook/index.exs`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex`
- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`
- `test/fixtures/operator_surface/route-inventory.json`
- `test/fixtures/operator_surface/source-surface-checklist.json`
- `test/threadline/operator_surface/storybook_boundary_test.exs`
- `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs`
- `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`

</canonical_refs>

<code_context>
## Existing code insights

Export already has scoped immediate reads, a separately authorized queue/download and mounted ordinary lifecycle owners. Retention domain already supports dry-run counts; the UI lacks their preview and server-held preview gate. Pruner captures repo/schema at startup; the mounted reader and audit request currently resolve separately, requiring explicit target coordination. Existing shared mutation script guards reconnect, but Retention needs its own mounted proof. Current catalog covers foundations through patterns; an Operations branch plus production read-only sharing closes the screen-state/journey connection. Source and proof identities remain the existing inventory's responsibility.
</code_context>

<deferred>
## Deferred

Scoped asynchronous exports/durable preview lineage require separate future contracts and are not included. Global palette, broad inclusive/error-state pixels, docs/package/release readiness remain253. The generic todo matcher scored the ephemeral-Postgres-wrapper todo0.9 from broad keywords; inspection shows it is CI infrastructure, not an ADM23–25 job. It is reviewed, not folded into252; existing owned ephemeral PostgreSQL already supplies isolated local checks. Live REL-01 remains an external next-natural-release clause. No new release authority.
</deferred>
