# Phase 84: Export Delivery & Scale Adapter Integration Repair - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair export delivery so completed background exports work correctly across both built-in local storage and adapter-backed storage, while also closing the remaining real integration gap for Oban and S3-backed deployments. This phase closes the broken download path, proves the actor-owned export status/download flow on the repaired tree, and turns the adapter work from “modules exist” into truthful adopter-facing integration.

It does not broaden scope into a new auth model, a general file-serving framework, CDN/productized media delivery, or a Threadline-owned infrastructure stack for Oban/S3.

</domain>

<decisions>
## Implementation Decisions

### Download handoff shape

- **D-01: Keep one canonical operator affordance:** the export status UI should always render the same `Download Export` action against a Threadline-owned route keyed by export job ID, not backend-specific URLs embedded directly in the LiveView.
- **D-02: Resolve delivery after authorization, not before rendering.** The controller-side download path should perform actor/ownership checks first, then resolve delivery based on the configured storage backend.
- **D-03: Use a small delivery-resolution seam above storage adapters.** After authorization, the app should resolve either a local file path for `send_file` or an adapter-issued external URL for redirect, instead of forcing storage adapters to fabricate app routes.
- **D-04: Do not render presigned S3 URLs directly into the status page.** Presigned URLs are bearer tokens, can expire while the UI sits open, and create backend-specific operator behavior that violates the storage-agnostic UI contract.
- **D-05: Local and adapter-backed storage remain equally first-class.** The operator flow must not treat S3 as a special “different UI mode”; storage differences belong behind the delivery-resolution boundary.
- **D-06: `job_id` is the operator-facing identity, not `file_id`.** The route and authorization boundary should stay job-centric; file identifiers remain an internal storage concern.

### Adapter validation and failure posture

- **D-07: Use a split validation posture.** Fail fast at startup for configured adapter dependency/config/contract errors, but fail truthfully at operation time for host-owned runtime or external failures.
- **D-08: Startup validation should only assert static truths the library can honestly know.** Examples: optional dependency present, required adapter config present, expected callback surface available, obvious malformed configuration rejected.
- **D-09: Startup validation must not pretend to own runtime liveness it does not control.** Threadline should not hard-fail boot because Oban has not started yet in the host tree or because AWS/network reachability is unavailable during startup.
- **D-10: Operation-time failures must stay explicit and supportable.** If enqueue, resolution, redirect generation, or object delivery cannot proceed, the row/error surface should tell the truth immediately instead of leaving dead `pending` or fake-download states.
- **D-11: The adapter contract should produce stable, human-readable failure reasons.** These should be fit for flashes, export status errors, and support/debugging rather than low-signal raw exceptions alone.

### Oban ownership boundary

- **D-12: Threadline owns the built-in `Task.Supervisor` runtime path only.** Once adopters opt into `Threadline.ExportQueue.Oban`, Oban itself remains host-owned infrastructure.
- **D-13: Do not auto-start Oban from `Threadline.Application`.** That would fight normal OTP/Phoenix supervision expectations, create boot-order hazards, and blur ownership in a reusable library with optional dependencies.
- **D-14: Threadline should own compatibility proof and truthful failure handling for Oban, not hidden backend lifecycle management.** The library should validate the adapter contract, document the host startup/migration requirements, and verify real enqueue behavior on the current tree.
- **D-15: Support named/host-configured Oban instances explicitly.** Planner may introduce config for `oban_name` and queue naming, but the ownership model must remain “host supervises, Threadline targets.”

### Operator flow and UX truthfulness

- **D-16: The operator surface must remain storage-agnostic.** UI copy, empty/error states, and action labels should not mention local disk, filesystem paths, S3 keys, or backend-specific jargon.
- **D-17: Click-time resolution is the least surprising UX.** Operators should click `Download Export` and either receive the file or be redirected transparently to a valid backend URL; they should not have to reason about backend mode.
- **D-18: Expired or unavailable downloads should fail clearly, not ambiguously.** If a completed job can no longer be served because the artifact expired or resolution failed, the user should get a truthful failure response consistent with the UI spec rather than a broken/dead link.
- **D-19: Actor ownership remains mandatory on the repaired path.** Phase 82’s session/actor handoff decisions apply here without reopening them; download and export-status behavior stay actor-scoped end to end.

### Ecosystem and DX posture

- **D-20: Prefer explicit seams over magic.** Threadline should borrow the integrated experience ambition of mature ecosystems, but keep Elixir-library norms: clear contracts, host-owned boundaries, optional dependencies that stay truly optional, and observable failure modes.
- **D-21: Borrow the Active Storage lesson, not the entire framework posture.** The right analogy is authenticated app-owned handoff with backend-specific delivery behind it, not fully absorbing file-serving infrastructure into the library.
- **D-22: Borrow the Swoosh/Finch/Broadway lesson for adapters.** Validate static adapter configuration early, but leave external service/process ownership where the host app expects it.
- **D-23: Keep Phoenix optionality honest.** Nothing in this phase should weaken `capture-only` or make the Phoenix surface a hidden requirement.

### Recommendation-first downstream posture

- **D-24: Downstream planning should treat these decisions as a cohesive recommendation set, not reopen them as equal-weight choices.** The user explicitly prefers research-first, one-shot recommendations with defaults chosen.
- **D-25: Escalate only if planning discovers a genuinely high-impact issue** in the project’s existing categories: `semver`, `security_model`, `breaking_public_api`, or `scope_cut`.

### the agent's Discretion

- Exact module/function names for the delivery-resolution seam, as long as job-centric authorization remains above backend-specific delivery.
- Exact error taxonomy and flash/HTTP messaging, as long as failures stay stable, human-readable, and operator-truthful.
- Exact adapter config keys for Oban target selection and S3/static validation, as long as ownership boundaries remain clear.
- Whether the download path uses redirect-only for remote storage or later leaves room for proxy mode, as long as direct presigned URLs are not rendered into the status page in this phase.

</decisions>

<specifics>
## Specific Ideas

- The strongest cohesive recommendation is:
  one canonical Threadline download route, job-centric auth first, delivery resolution second, local `send_file` for built-in storage, redirect to short-lived adapter URLs for remote storage, no presigned URLs rendered directly into the UI.
- The cleanest long-term seam is to move route knowledge out of `Threadline.Storage.Local.download_url/2` and into an app-owned delivery resolver/controller boundary. Storage adapters should stay backend-native, not fabricate operator-surface routes.
- The right mental model for adapter validation is:
  fail early for obvious misconfiguration, fail truthfully later for host/runtime/network reality.
- The right mental model for Oban is:
  built-in runtime is library-owned; Oban runtime is host-owned infrastructure that Threadline integrates with and verifies honestly.
- Relevant prior-art lessons:
  Rails Active Storage gets the app-owned handoff pattern right; direct public-style URL rendering is a poor fit for actor-owned private exports.
  Swoosh/Finch-style adapter boundaries show the value of clear configuration validation without stealing host runtime ownership.
  Broader audit-library prior art repeatedly warns against opaque magic, hidden runtime assumptions, and UX that looks “configured” until the user clicks the broken path.
- The repo’s existing `.planning/config.json` already leans toward the user’s preferred GSD posture:
  discuss all meaningful gray areas, research first, synthesize one recommendation set, and interrupt only for truly high-impact decisions. This context file carries that posture forward into planning for Phase 84.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract and repaired milestone authority
- `.planning/ROADMAP.md` — Phase 84 goal, success criteria, and ownership boundary versus Phases 79 and 83
- `.planning/REQUIREMENTS.md` — `EXP-03`, `ADAPT-01`, and `ADAPT-02`
- `.planning/STATE.md` — current milestone state and sequencing
- `.planning/v1.20-MILESTONE-AUDIT.md` — the concrete integration gaps this phase closes

### Locked upstream phase context
- `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-UI-SPEC.md` — locked operator-facing visual and interaction contract
- `.planning/phases/83-built-in-async-export-lifecycle-repair/83-CONTEXT.md` — built-in runtime truthfulness, enqueue-failure, lifecycle, and cleanup posture
- `.planning/phases/83-built-in-async-export-lifecycle-repair/83-RESEARCH.md` — runtime repair patterns and verification posture for the built-in lane
- `.planning/phases/82-saved-views-session-handoff-repair/82-CONTEXT.md` — locked actor/session handoff and ownership semantics for the operator surface
- `.planning/phases/79-scale-adapters/79-DISCUSSION.md` — original adapter direction and optional-dependency posture
- `.planning/phases/79-scale-adapters/79-RESEARCH.md` — initial Oban/S3 adapter rationale and pitfalls
- `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md` — implemented vs integrated vs satisfied truth taxonomy

### Current code seams
- `lib/threadline/operator_surface/controllers/export_controller.ex` — current local-only download implementation and actor-owned download path
- `lib/threadline/operator_surface/live/export_status_live.ex` — export status action rendering and actor-scoped list semantics
- `lib/threadline/operator_surface/live/timeline_live.ex` — export request path, enqueue error handling, and actor-owned job creation
- `lib/threadline/storage.ex` — storage contract shape
- `lib/threadline/storage/local.ex` — built-in local storage behavior and current route-leaking `download_url/2`
- `lib/threadline/storage/s3.ex` — S3 behavior, non-local path semantics, and presigned URL capability
- `lib/threadline/export_queue.ex` — queue adapter contract shape
- `lib/threadline/export_queue/oban.ex` — Oban adapter boundary and current assumptions
- `lib/threadline/application.ex` — built-in runtime startup behavior and the current place where configured adapter init/validation may need to hook in
- `lib/threadline/governance/export_job.ex` — export job lifecycle fields that remain the delivery source of truth

### Tests and example path
- `test/threadline/operator_surface/controllers/export_controller_test.exs` — current download expectations and actor checks
- `test/threadline/operator_surface/live/export_status_live_test.exs` — export status UI expectations
- `test/threadline/export_queue/oban_test.exs` — current adapter-level Oban proof
- `test/threadline/storage/s3_test.exs` — current adapter-level S3 proof
- `examples/threadline_phoenix/lib/threadline_phoenix/application.ex` — host-owned Oban startup precedent
- `examples/threadline_phoenix/README.md` — public example narrative for operator surface and host-owned posture
- `guides/operator-surface.md` — current operator surface integration contract
- `guides/integration-contracts.md` — host-owned boundary and callback seam contract

### Product/DX philosophy and prior-art references
- `prompts/threadline-elixir-oss-dna.md` — Threadline OSS quality bar, optional-dependency honesty, and verification posture
- `prompts/audit-lib-domain-model-reference.md` — product thesis and “hardest to get wrong, easiest to operate” principle
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem lessons around correctness, context, and operator UX
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ExportController.download/2` already provides the correct actor-owned HTTP boundary; the missing piece is backend-aware delivery after authorization.
- `ExportStatusLive` already has the right storage-agnostic operator copy and action slot; the phase should preserve that contract rather than inventing new UI variants.
- `Threadline.Application` already distinguishes library-owned built-in runtime startup from host-owned example-app infrastructure, which is the correct ownership shape to preserve.
- `Threadline.ExportQueue` and `Threadline.Storage` already expose `init/1`, giving Phase 84 a natural place to formalize startup-time validation for configured adapters.

### Established Patterns
- Threadline prefers one truthful path over many magical fallback paths.
- The project consistently treats operator UX, docs, and verification artifacts as part of the product surface, not incidental paperwork.
- Optional dependencies are in-tree but must stay truly optional and compile-clean for adopters who never enable them.
- Actor identity, authorization, and scoped visibility are already intentionally separated. Phase 84 should preserve that rather than smuggling new auth assumptions into storage or queue adapters.

### Integration Points
- Repair the download path so storage differences are resolved behind one actor-owned controller boundary.
- Connect startup-time adapter validation to the configured `storage_adapter` and `export_queue_adapter` without stealing host runtime ownership.
- Align the example app, docs, and verification surface around host-owned Oban startup plus truthful Threadline integration proof.
- Extend Phase 79 from “adapter modules exist” into “the real export flow works with those adapters on the repaired tree.”

</code_context>

<deferred>
## Deferred Ideas

- Full proxy/stream-through-app mode for remote object storage instead of redirect-based remote delivery
- Download analytics/audit trail beyond the existing export job lifecycle truth surface
- Broader generalized file-delivery framework behavior outside Threadline export artifacts
- Threadline-owned lifecycle management for Oban or cloud infrastructure
- CDN/productized public asset delivery semantics

</deferred>

---

*Phase: 84-export-delivery-and-scale-adapter-integration-repair*
*Context gathered: 2026-05-24*
