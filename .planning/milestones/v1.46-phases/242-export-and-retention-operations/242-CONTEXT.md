# Phase 242: Export and retention operations - Context

**Gathered:** 2026-10-10  
**Status:** Ready for planning  
**Approval:** The maintainer asked to resume and auto-follow research-backed recommendations. Three targeted reviews plus a cross-cluster adversarial check found no unresolved high-impact product, security, or public-contract choice.

<domain>
## Phase Boundary

Complete the existing operator journeys for actor-owned exports, confirmed retention pruning, and LiveView disconnect/reconnect recovery. Keep the existing Phoenix routes, persisted job/run records, host authorization boundary, storage adapter, retention policy, and private UI primitives. Preserve Phoenix optionality and public 1.x contracts. A narrow internal retention-runner correction is in scope to persist an accepted prune before acknowledgement and keep one run truthful through its terminal result. Do not add public APIs, routes, host role models, dependencies, component packages, or a new retention schema migration.

</domain>

<decisions>
## Implementation Decisions

### Export lifecycle and return journey
- **D-01:** Treat the persisted actor-owned `ExportJob` as the lifecycle source of truth. Reconcile from it on remount/reconnect and distinguish pending, running, failed, completed, expired, and missing-file outcomes. Say queued only after the current queue adapter accepts the job; transport loss is not job failure.
- **D-02:** Preserve the source query through the existing validated filter fields and rebuild a local Timeline URL, including an unfiltered fallback. Do not accept arbitrary return URLs, tenant/scope/cursor data, or draft filters. Keep scoped exports unavailable where the current product contract says so.
- **D-03:** The existing per-request download controller remains authoritative for actor ownership, completion, expiry, and storage delivery. Metadata does not prove that the stored file is still usable. Do not add a storage probe on every page refresh or deduplicate intentional repeat export requests.

### Confirmed retention pruning
- **D-04:** Explain the actual global scope: the configured retention policy removes `AuditChange` rows strictly older than the cutoff at execution in the configured Threadline storage schema; when configured, it can also remove empty `AuditTransaction` rows. Host operator/tenant scope is not a prune filter. Do not imply preview counts, a historical cutoff, or per-tenant pruning because the existing run record does not preserve those facts.
- **D-05:** Preserve the existing destructive confirmation path: require the exact canonical policy name, rederive and constant-time compare it server-side, recheck host authorization, and record the audit action before triggering the prune. The UI gate never replaces server authorization.
- **D-06:** Persist acceptance before acknowledging by creating/updating the existing `RetentionRun` record, then update that same record through queued, running, and completed/failed outcomes. Coalesce another request only while a run is active; retain the PostgreSQL advisory lock for cross-node execution exclusion. Record cumulative completed deletions on partial failure and a safe failure category, never raw database/exception detail. Use existing columns and unconstrained text status: no duplicate tracking row, new route/API, public `Threadline.Retention.purge/1` option, schema migration, or dependency. Do not claim exactly-once execution after an arbitrary lost acknowledgment or explicit later retry.

### Disconnect and reconnect behavior
- **D-07:** Keep the current read-only page visible with a programmatically announced reconnect status and clear stale/availability wording. Disable only mutation controls with a keyboard-safe native disabled state during transport loss and in-flight submission; CSS pointer blocking alone is insufficient. Restore controls only after reconnect and fresh authoritative state. Do not make the entire page inert or steal focus.
- **D-08:** Use persisted export and retention state to reconcile after reconnect. Prevent offline activation and in-flight double submission, but do not replay an uncertain mutation or promise exactly-once behavior without a separate idempotency contract.

### Presentation and implementation boundaries
- **D-09:** Reuse existing Phoenix/LiveView/HEEx patterns, shared status/banner, tokens, and private UI primitives. Keep calm, precise operator language; preserve focus behavior, keyboard/touch access, reduced motion, and responsive layouts. Add no dependency when the existing stack can express the behavior.
- **D-10:** Verify the real mounted journeys: export from source search through delivery and back; confirmation, persisted prune outcome and safe failure; pointer and keyboard behavior across actual disconnect/reconnect; and no accidental duplicate from recovery. Use named verification entrypoints and the smallest meaningful ExUnit/browser regressions.

### the agent's Discretion
- Choose exact concise copy, state grouping/order, and existing components/styles that best express the decisions above.
- Choose the smallest internal runner refactor that creates the existing run record before acknowledgment while preserving documented/public return and error behavior.
- Select focused ExUnit and mounted-browser cases; use actual socket loss where the Phoenix example supports it and describe any unavailable proof honestly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope, requirements, and product authority
- `.planning/ROADMAP.md` — Phase 242 goal, dependencies, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — UIO-01, UIO-05, and UIA-05 acceptance contracts.
- `.planning/PROJECT.md` and `AGENTS.md` — architecture constraints, verification conventions, and research-first workflow.
- `PRODUCT.md` — operator personas, product language, and security boundaries.
- `.planning/UI-MILESTONE-PREFLIGHT.md`, `.planning/research/SUMMARY.md`, and `.impeccable/config.json` — approved code-first UI approach and research cautions.
- `prompts/Threadline Brand Book.txt`, `prompts/audit-lib-domain-model-reference.md`, and `prompts/threadline-elixir-oss-dna.md` — voice, domain boundaries, and engineering/CI expectations.

### Prior decisions and visual/interaction contracts
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-CONTEXT.md` — identity, route baseline, responsive/accessibility expectations.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-CONTEXT.md` and `239-UI-SPEC.md` — validated URL state, host scope, existing private UI patterns.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-SECURITY.md` — operator threat boundaries.
- `.planning/phases/240-connected-investigation-and-recovery/240-CONTEXT.md` — reconnect, URL recovery, and motion behavior.
- `.planning/phases/241-operational-evidence-and-policy-inspection/241-CONTEXT.md` — most recent operator tone, accessibility, and verification decisions.

### Existing implementation and tests
- `lib/threadline/operator_surface/live/timeline_live.ex`, `timeline_live/filters.ex`, `export_status_live.ex`, and `export_status_live/components.ex` — source query, job status, and download journey.
- `lib/threadline/operator_surface/controllers/export_controller.ex` and `export_auth_plug.ex` — per-request export authorization and delivery.
- `lib/threadline/governance/export_job.ex`, `lib/threadline/export_queue.ex`, `lib/threadline/export_queue/oban.ex`, and `lib/threadline/export/orchestrator.ex` — persisted job and queue lifecycle.
- `lib/threadline/operator_surface/live/retention_history_live.ex`, `lib/threadline/retention.ex`, `lib/threadline/retention/pruner.ex`, `lib/threadline/retention/policy.ex`, and `lib/threadline/governance/retention_run.ex` — confirmation, worker handoff, pruning, policy, and run records.
- `lib/threadline/operator_surface/style/08_overlays_motion.css` and `lib/threadline/operator_surface/ui/overlay.ex` — shared reconnect and confirmation UI.
- `test/threadline/operator_surface/live/export_status_live_test.exs`, `test/threadline/operator_surface/live/retention_history_live_test.exs`, related export controller/pruner tests, and `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`, `operator-phase-178-uat.spec.ts` — current behavior coverage.

### Primary external references used for decisions
- Phoenix LiveView 1.1.26 bindings and JS lifecycle: https://phoenix-live-view.hexdocs.pm/1.1.26/bindings.html and https://phoenix-live-view.hexdocs.pm/1.1.26/Phoenix.LiveView.JS.html — use the installed 1.1.33 behavior as the final compatibility authority.
- Phoenix LiveView security model: https://phoenix-live-view.hexdocs.pm/1.2.9/security-model.html — reauthorize server events; client state is not a security boundary.
- OWASP Authorization Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html — check authorization on every request.
- W3C WCAG 2.2 status messages: https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html — announce state changes without moving focus.
- WAI-ARIA APG Button Pattern: https://www.w3.org/WAI/ARIA/apg/patterns/button/ — expose unavailable control state consistently.
- PostgreSQL 15 advisory locks: https://www.postgresql.org/docs/15/functions-admin.html — advisory locks exclude concurrent work but do not coalesce sequential queued requests.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ExportJob` is persisted before enqueue and is actor-owned; `ExportStatusLive` already polls and the existing controller validates owner, status, expiry, and storage delivery.
- Timeline has validated supported filter parsing and canonical local URL generation; use it to return to the source search.
- `RetentionRun` already has status, deleted count, duration, error message, and timestamps. Its status column is unrestricted text, so a queued state does not require a migration.
- The shared shell already renders a polite reconnect banner from real Phoenix LiveView lifecycle classes.

### Established Patterns and Gaps
- Export reconnect can reconcile from durable rows, but the source-search link needs an unfiltered fallback and should not trust a submitted URL. Queue acceptance and file availability are distinct from completed metadata.
- Prune currently casts to a process and creates the run after worker scheduling; a remount during that gap can miss the accepted operation. Successful purge persists completion, while errors may escape without a terminal run outcome. Existing advisory locks do not solve sequential duplicate requests.
- The shared reconnect CSS currently blocks pointer events only; keyboard activation remains possible. The Timeline export mutation is not marked by that gate, and the confirmation submit needs a native disabled state during loss/in-flight work.
- Retention is global to the selected Threadline storage schema, and its cutoff is computed at execution. Historical policy settings/cutoff are not stored in each run.

### Integration Points
- Export changes connect Timeline query serialization, actor-owned jobs, queue acceptance, status polling, protected HTTP download, and the return link.
- Retention changes connect the typed confirmation, authorization recheck, audit action, trigger handoff, run persistence, advisory locking, terminal result, and history page.
- Reconnect changes connect the shared banner and LiveView lifecycle classes with each mutation control and mounted browser tests.

</code_context>

<specifics>
## Specific Ideas

The maintainer prefers “another copy and paste is better than another dep” and asked for high-quality primary research, adversarial role-lens review, and automatic adoption of clear recommendations. Research converged on persisted-state recovery, current controller authorization, and one persisted retention run as the smallest coherent path. Keep the read-only page available when disconnected; only unavailable mutations pause.

</specifics>

<deferred>
## Deferred Ideas

- Durable client idempotency keys or exactly-once guarantees across lost acknowledgments; this requires a separate public/API and retry contract.
- Persisting a historical policy/cutoff snapshot or preview count per retention run; this would require a schema and product contract change.
- New event/notification infrastructure, storage probes on every render, arbitrary return URLs, tenant-scoped prune semantics, role models, routes, dependencies, or UI component packages.
- Phase 243 integrated verification and release recommendation.

</deferred>

---

*Phase: 242-export-and-retention-operations*
*Context gathered: 2026-10-10*
