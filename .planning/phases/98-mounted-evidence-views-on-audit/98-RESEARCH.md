# Phase 98: Mounted Evidence Views On `/audit` - Research

**Researched:** 2026-05-26 [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, .planning/ROADMAP.md]
**Domain:** Phoenix LiveView operator-surface evidence views with API/CLI parity and host-owned authorization. [VERIFIED: .planning/ROADMAP.md, lib/threadline/operator_surface/router.ex, lib/threadline/evidence/proof.ex]
**Confidence:** HIGH [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/operator_surface/router.ex, lib/threadline/evidence/proof.ex, test/threadline/evidence/proof_test.exs]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Phase 98 should add one canonical mounted landing page at `/audit/evidence`, not distribute the evidence plane purely across existing policy/coverage/export pages. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-02:** Existing `/audit/coverage`, `/audit/policy/redaction`, `/audit/policy/retention`, and export-related views may deep-link into filtered evidence state, but they should not become independent evidence subsystems with page-local reducers or page-local truth contracts. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-03:** The mounted evidence route remains a sibling inside the existing `/audit` family, matching the repo’s current operator-surface pattern of one canonical entry plus narrower sibling workflows. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-04:** The mounted evidence view should open with a cross-subject overview first: “what can Threadline prove right now?” [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-05:** The default overview should reuse the Phase 97 mental model: latest-per-subject-reference summaries across the fixed evidence inventory, not a subject picker and not a raw history dump. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-06:** Subject-focused views should be secondary drill-downs reached through URL-driven narrowing on the same `/audit/evidence` surface. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-07:** Mounted evidence should treat `latest` as the primary operator entrypoint but keep append-only history available as explicit drill-down. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-08:** History remains canonical truth, but it should not be the default first-class mounted workflow in Phase 98. Doing so would make `/audit` feel like a separate evidence-analysis console and would drift from the overview-first API/CLI contract already locked in Phase 97. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-09:** The mounted UI must state clearly that “latest” is a convenience projection over append-only evidence history, not a second mutable state model. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-10:** The mounted UI should translate the proof into an operator-facing presentation rather than literally mirroring the Mix-task proof document. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-11:** The mounted layer must preserve the exact underlying proof facts, subject inventory, and verdict vocabulary (`proven`, `inferred_posture`, `unsupported`) from the evidence proof contract. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-12:** The machine JSON envelope remains the machine contract; mounted UI layout should not be forced to expose proof-envelope fields such as `format_version` or `proof_type` as first-class UI chrome. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-13:** Parity should be locked through shared presenter/view-model code plus tests, not by making LiveView render the CLI/JSON shape verbatim. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-14:** Mounted evidence should behave like a proof/policy-adjacent surface, not like the broad timeline. It should use an explicit gated / unsupported-view posture rather than automatically inheriting the main `/audit` authorization. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-15:** The gate should stay host-owned and align with the existing coverage/policy style rather than inventing Threadline-owned RBAC or persona semantics. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-16:** When evidence access is denied or unavailable for the current transport/access tier, the mounted surface should render an explicit unsupported state with CLI/API fallback guidance instead of silently hiding the truth surface. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-17:** Support-safe operator sessions must not gain accidental mounted evidence visibility just because they can access the main timeline. The support-scope posture subject makes this boundary especially important. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-18:** Mounted evidence should be a thin LiveView layer over `Threadline.Evidence` and/or `Threadline.Evidence.Proof`, not a second query model. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-19:** Shareable state should live in the URL through `handle_params/3` and normal LiveView navigation patterns, following the current `/audit` surface style. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-20:** Reuse existing operator-surface assets where possible: `SurfaceHeader`, `UnsupportedView`, current coverage/policy enabled flags, and the sibling-route mount pattern already established in the router. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-21:** Do not introduce page-local semantics that reinterpret evidence meaning, host authorization meaning, tenant meaning, or “compliance” meaning beyond what the proof payload and prior phases already lock. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-22:** Research across all five gray areas converged on one coherent shape: `/audit/evidence` as a canonical mounted landing page, overview-first latest-summary default, explicit history drill-down, operator-facing translation of proof facts, and explicit proof/policy-style gating. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **D-23:** No major unresolved architectural decision remains for Phase 98. Planning should proceed from this cohesive recommendation set unless current tree implementation evidence reveals a contradiction. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]

### Claude's Discretion

- Exact query-param vocabulary and route-state shape for subject/history drill-down, as long as it stays URL-driven and additive to the mounted `/audit` family. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- Exact grouping and table/card presentation for the overview screen, as long as the fixed verdict vocabulary and proof boundary remain explicit. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- Exact presenter/view-model module names and file layout, as long as the LiveView layer stays thin over the shared evidence truth model. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- Whether the mounted evidence gate should be a dedicated `evidence_authorize_fn` or reuse the existing policy-style seam, as long as the access boundary stays explicit, host-owned, and testable. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)

- None provided in `98-CONTEXT.md`. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SURF-01 | Read-only evidence views live on the existing `/audit` surface rather than a new operator UI family. [VERIFIED: .planning/REQUIREMENTS.md] | Route under the existing `live_session :threadline` sibling tree and reuse current operator-surface components/patterns. [VERIFIED: lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/components/surface_header.ex, lib/threadline/operator_surface/live/coverage_live.ex] |
| SURF-02 | Mounted evidence views show the same evidence facts and boundary language as the library API and Mix-task paths. [VERIFIED: .planning/REQUIREMENTS.md] | Use `Threadline.Evidence.Proof` plus a shared presenter/view-model seam so mounted, Mix, and JSON all derive from the same proof facts and verdict vocabulary. [VERIFIED: lib/threadline/evidence/proof.ex, lib/mix/tasks/threadline.evidence.show.ex, test/threadline/evidence/proof_test.exs, test/mix/tasks/threadline.evidence_show_test.exs] |
| SURF-03 | Host-owned authorization remains the gate for mounted evidence views; Threadline does not introduce RBAC or tenant DSL semantics. [VERIFIED: .planning/REQUIREMENTS.md] | Follow existing `Auth.on_mount/4` capability-flag patterns and unsupported-state fallback patterns rather than adding Threadline-owned personas or hidden inheritance from timeline access. [VERIFIED: lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/components/unsupported_view.ex, lib/threadline/operator_surface/unsupported.ex, guides/operator-surface.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep the capture, semantics, and exploration/operator-surface layers separate; Phase 98 belongs in the exploration/operator-surface layer. [VERIFIED: CLAUDE.md]
- Use the repo’s domain language consistently: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: CLAUDE.md]
- Preserve the host-owned auth boundary and do not widen Threadline into a Threadline-owned auth, tenancy, or compliance platform. [VERIFIED: CLAUDE.md, .planning/REQUIREMENTS.md]
- Prefer named verification entrypoints such as `mix verify.test` and `mix ci.all` in research and plan outputs. [VERIFIED: CLAUDE.md, mix.exs]
- Keep mounted/operator features Phoenix-optional at the package level; the repo already gates operator-surface modules behind `Code.ensure_loaded?(Phoenix.LiveView)`. [VERIFIED: CLAUDE.md, lib/threadline/operator_surface/router.ex, test/threadline/operator_surface/gating_test.exs]
- Do not assume a new capture mechanism, new action semantics, or retention-policy ownership in this phase. [VERIFIED: CLAUDE.md, .planning/ROADMAP.md]
- Keep docs/tests honest: default tests must stay truthful, and contract/doc tests are part of the project’s standard quality bar. [VERIFIED: CLAUDE.md, mix.exs, test/threadline/operator_surface_doc_contract_test.exs]

## Summary

Phase 98 should add one new LiveView route, `/audit/evidence`, inside the existing `threadline_operator_surface/2` route family and keep it read-only, URL-driven, and thin over the already-shipped evidence APIs. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/operator_surface/router.ex, lib/threadline/evidence.ex] The evidence landing view should default to the same overview-first latest-per-subject-reference model already established by `Threadline.Evidence.list_overview/2` and `Threadline.Evidence.Proof.proof_document/2`, then let operators narrow into subject and history drill-downs through `handle_params/3` rather than page-local state reducers. [VERIFIED: lib/threadline/evidence.ex, lib/threadline/evidence/proof.ex, lib/mix/tasks/threadline.evidence.show.ex, test/threadline/evidence/proof_test.exs] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

The most important planning constraint is parity, not new UI capability. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md] The mounted surface must preserve the same fixed subject inventory and verdict vocabulary already proven in the API and Mix-task paths, while translating that proof into operator-readable sections/cards/tables instead of dumping the machine envelope directly into the UI. [VERIFIED: lib/threadline/evidence/subject.ex, lib/threadline/evidence/proof.ex, lib/mix/tasks/threadline.evidence.show.ex, test/mix/tasks/threadline.evidence_show_test.exs] Access should stay explicit and host-owned, following the same unsupported-state posture used by coverage, policy, retention, and export sub-surfaces today. [VERIFIED: lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/live/policy_redaction_live.ex, lib/threadline/operator_surface/live/retention_history_live.ex, lib/threadline/operator_surface/unsupported.ex]

**Primary recommendation:** Build `/audit/evidence` as a sibling LiveView that derives mounted overview/latest/history state from `Threadline.Evidence.Proof` plus a shared presenter module, and gate it with an explicit host-owned capability seam that renders `UnsupportedView` plus CLI/API fallback when denied. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex, lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/components/unsupported_view.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Evidence record retrieval and overview/latest/history semantics | API / Backend | Database / Storage | `Threadline.Evidence` and `Threadline.Evidence.Proof` already own the evidence read contract and query semantics over persisted records. [VERIFIED: lib/threadline/evidence.ex, lib/threadline/evidence/proof.ex] |
| Mounted evidence route and operator presentation | Frontend Server (SSR) | Browser / Client | The new `/audit/evidence` page should be a LiveView sibling in the existing mounted surface, with the browser only reflecting server-owned state. [VERIFIED: lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/live/coverage_live.ex] |
| Shareable navigation state for subject/history drill-down | Frontend Server (SSR) | Browser / Client | Current `/audit` patterns keep shareable state in the URL and use `handle_params/3` with patch navigation rather than page-local reducers. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| Authorization for mounted evidence access | Frontend Server (SSR) | API / Backend | Operator-surface access is decided at mount through host-owned callbacks in `Auth.on_mount/4`, with narrower booleans assigned for sub-surfaces. [VERIFIED: lib/threadline/operator_surface/auth.ex, guides/operator-surface.md] |
| Unsupported fallback messaging | Frontend Server (SSR) | — | The mounted surface already centralizes truthful denial/unavailable copy in `UnsupportedView` and `Threadline.OperatorSurface.Unsupported`. [VERIFIED: lib/threadline/operator_surface/components/unsupported_view.ex, lib/threadline/operator_surface/unsupported.ex] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `1.8.7` in `mix.lock`; current Hex package page also shows `1.8.7` updated 2026-05-06. [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/phoenix] | Router/live-session host for `/audit` mounted routes. [VERIFIED: lib/threadline/operator_surface/router.ex] | The repo already mounts the operator surface through `threadline_operator_surface/2`; Phase 98 extends that exact surface instead of adding a new UI family. [VERIFIED: lib/threadline/operator_surface/router.ex, .planning/ROADMAP.md] |
| `phoenix_live_view` | `1.1.30` in `mix.lock`; current Hex package page also shows `1.1.30` updated 2026-05-05. [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/phoenix_live_view] | URL-driven mounted evidence LiveView. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/live/timeline_live.ex] | Official LiveView navigation expects current-view URL changes to flow through `push_patch/2` and `handle_params/3`, which matches the repo’s existing `/audit` browse pattern. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |
| `Threadline.Evidence` | repo-local public API. [VERIFIED: lib/threadline/evidence.ex] | Canonical evidence overview/latest/history reads. [VERIFIED: lib/threadline/evidence.ex] | It already exposes the exact read shapes this phase needs, including `list_overview/2`, `list_latest_subject_refs/3`, and history helpers. [VERIFIED: lib/threadline/evidence.ex] |
| `Threadline.Evidence.Proof` | repo-local proof layer. [VERIFIED: lib/threadline/evidence/proof.ex] | Stable proof facts, verdict vocabulary, and machine envelope. [VERIFIED: lib/threadline/evidence/proof.ex] | It already centralizes proof-document generation for overview/latest/history and is covered by parity-oriented tests. [VERIFIED: lib/threadline/evidence/proof.ex, test/threadline/evidence/proof_test.exs, test/mix/tasks/threadline.evidence_show_test.exs] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_html` | `4.3.0` in `mix.lock`; current Hex versions page shows `4.3.0` as latest listed. [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/phoenix_html/versions] | HEEx link/form primitives used by LiveView templates. [VERIFIED: mix.lock, lib/threadline/operator_surface/live/coverage_live.ex] | Use for mounted evidence links/buttons/forms inside the existing operator surface. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex] |
| `phoenix_pubsub` | `2.2.0` in `mix.lock`. [VERIFIED: mix.lock] | Existing optional Phoenix surface dependency. [VERIFIED: mix.exs] | Reuse as-is if mounted evidence later needs the same LiveView/runtime plumbing as the rest of `/audit`; Phase 98 does not need a new dependency. [VERIFIED: mix.exs, lib/threadline/operator_surface/router.ex] |
| `Threadline.OperatorSurface.Components.SurfaceHeader` | repo-local component. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] | Shared header/badge grammar for mounted `/audit` pages. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex] | Use when the new evidence page should feel like a sibling inside the same operator family. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/operator_surface/live/coverage_live.ex] |
| `Threadline.OperatorSurface.Components.UnsupportedView` | repo-local component. [VERIFIED: lib/threadline/operator_surface/components/unsupported_view.ex] | Truthful explicit denied/unavailable state. [VERIFIED: lib/threadline/operator_surface/components/unsupported_view.ex] | Use whenever evidence access is not granted or not supported for the current mount/transport. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/operator_surface/live/policy_redaction_live.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Canonical `/audit/evidence` sibling route | Spread evidence across `/audit/coverage`, policy, and exports pages | This would violate the locked “one canonical mounted landing page” decision and would encourage page-local evidence truth contracts. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md] |
| Shared presenter/view-model over proof facts | Render the Mix-task proof document verbatim in LiveView | This preserves parity poorly for operators because it pushes machine-envelope fields into UI chrome and couples mounted UX to CLI formatting. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex] |
| Explicit evidence gate with unsupported fallback | Implicitly inherit main timeline access | This risks support-lane overexposure and contradicts the repo’s explicit coverage/policy/export gating pattern. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/operator_surface/auth.ex, guides/operator-surface.md] |

**Installation:**
```bash
mix deps.get
```
No new dependency is recommended for Phase 98; the phase should reuse the optional Phoenix stack and repo-local evidence modules already present on the tree. [VERIFIED: mix.exs, mix.lock, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]

**Version verification:** The repo is already locked to `phoenix 1.8.7`, `phoenix_live_view 1.1.30`, `phoenix_html 4.3.0`, `phoenix_pubsub 2.2.0`, `ecto_sql 3.13.5`, `postgrex 0.22.0`, and `jason 1.4.4`. [VERIFIED: mix.lock] Current Hex package pages show `phoenix 1.8.7`, `phoenix_live_view 1.1.30`, `ecto_sql 3.14.0`, `postgrex 0.22.2`, and `phoenix_html 4.3.0` as the latest listed versions as of 2026-05-26, so this phase should plan against the repo lock rather than bundling an opportunistic dependency upgrade. [CITED: https://hex.pm/packages/phoenix] [CITED: https://hex.pm/packages/phoenix_live_view] [CITED: https://hex.pm/packages/ecto_sql] [CITED: https://hex.pm/packages/postgrex] [CITED: https://hex.pm/packages/phoenix_html/versions]

## Architecture Patterns

### System Architecture Diagram

```text
Browser
  |
  | GET /audit/evidence?subject=...&mode=latest|history
  v
Phoenix Router (`threadline_operator_surface/2`)
  |
  v
Live session `:threadline`
  |
  +--> `Threadline.OperatorSurface.Auth.on_mount/4`
  |       |
  |       +--> host `authorize_fn` + narrower evidence/policy capability seam
  |       +--> assigns repo/scope/capability booleans
  |
  v
`EvidenceLive.mount/3`
  |
  v
`handle_params/3`
  |
  +--> validate URL params
  +--> choose overview/latest/history request shape
  +--> call shared presenter over `Threadline.Evidence.Proof`
  |
  v
`Threadline.Evidence.Proof.proof_document/2`
  |
  +--> `Threadline.Evidence.list_overview/2`
  +--> `Threadline.Evidence.list_latest_subject_refs/3`
  +--> `Threadline.Evidence.list_subject_ref_history/4`
  |
  v
`threadline_evidence_records` via Ecto repo
  |
  v
Rendered operator view
  |
  +--> overview cards/tables
  +--> subject drill-down links (`push_patch`)
  +--> explicit unsupported state with CLI/API fallback when gated
```
This flow keeps the browser as a navigation client, the LiveView as a thin presenter host, and the evidence/proof modules as the truth owner. [VERIFIED: lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/auth.ex, lib/threadline/evidence.ex, lib/threadline/evidence/proof.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

### Recommended Project Structure

```text
lib/threadline/operator_surface/
├── live/
│   └── evidence_live.ex        # mounted /audit/evidence surface
├── evidence/
│   └── presenter.ex            # shared mounted view-model builder over proof facts
├── unsupported.ex              # add evidence fallback descriptor if needed
└── router.ex                   # sibling route declaration

test/threadline/operator_surface/
├── live/
│   └── evidence_live_test.exs  # mounted behavior, routing, gating
├── evidence/
│   └── presenter_test.exs      # parity-focused view-model tests
└── evidence_doc_contract_test.exs # optional route/doc literal lock if current style prefers separate doc tests
```
This mirrors the repo’s existing split between route/live modules, repo-local presenters, and focused live/doc tests without creating a second UI family. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/live/policy_redaction_live.ex, test/threadline/operator_surface/live/coverage_live_test.exs, test/threadline/operator_surface/policy_show_doc_contract_test.exs]

### Pattern 1: Sibling Mounted Route Inside the Existing Live Session
**What:** Add `/audit/evidence` inside the existing `live_session :threadline` scope next to coverage, exports, and policy routes. [VERIFIED: lib/threadline/operator_surface/router.ex, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**When to use:** Always for Phase 98, because SURF-01 and D-01/D-03 lock reuse of the current operator surface. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Example:**
```elixir
# Source: repo pattern in lib/threadline/operator_surface/router.ex
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, opts},
    {Threadline.OperatorSurface.Coverage.OnMount, opts}
  ] do
  scope path, alias: Threadline.OperatorSurface.Live do
    live "/", TimelineLive, :index
    live "/coverage", CoverageLive, :index
    live "/policy/redaction", PolicyRedactionLive, :index
    live "/policy/retention", RetentionHistoryLive, :index
    live "/evidence", EvidenceLive, :index
  end
end
```
The code sample is prescriptive for route shape, even though `EvidenceLive` does not exist yet. [VERIFIED: lib/threadline/operator_surface/router.ex]

### Pattern 2: URL-As-State With `handle_params/3`
**What:** Keep shareable evidence navigation in the URL and reload only the params-driven slice on patch navigation. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
**When to use:** For overview filters, subject narrowing, mode switching (`latest` vs `history`), and bounded history drill-down. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex]
**Example:**
```elixir
# Source: Phoenix LiveView live navigation docs + repo timeline pattern
def handle_params(params, _uri, socket) do
  request = Presenter.request_from_params(params)
  model = Presenter.build(request, repo: socket.assigns.threadline_repo)

  {:noreply,
   socket
   |> assign(:request, request)
   |> assign(:model, model)}
end

def handle_event("show-subject", %{"subject" => subject}, socket) do
  {:noreply, push_patch(socket, to: "#{socket.assigns.base_path}?subject=#{subject}")}
end
```
The important part is the split of URL validation/state selection in `handle_params/3` instead of in disconnected local reducer logic. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

### Pattern 3: Shared Presenter/View Model Over Proof Facts
**What:** Convert proof documents or proof-derived records into operator-facing sections without letting LiveView invent new evidence semantics. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex]
**When to use:** For overview grouping, verdict badges, “latest is a projection over history” copy, and CLI/API fallback labels. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Example:**
```elixir
# Source: repo proof contract in lib/threadline/evidence/proof.ex
def build(request, opts) do
  document = Threadline.Evidence.Proof.proof_document(request, opts)

  %{
    title: title_for(document),
    mode: document["mode"],
    claim_status: document["claim_assessment"]["status"],
    groups: group_records(document["records"]),
    latest_projection_note: latest_projection_note(document["mode"])
  }
end
```
Mounted UI should consume a view model like this, not raw CLI strings and not direct Ecto rows spread through templates. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex]

### Anti-Patterns to Avoid

- **Page-local evidence reducers:** They create a second truth contract beside `Threadline.Evidence` and `Threadline.Evidence.Proof`. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **Implicit timeline auth inheritance:** Coverage/policy/export are already explicitly capability-gated; evidence should follow that pattern. [VERIFIED: lib/threadline/operator_surface/auth.ex, guides/operator-surface.md]
- **History-first landing UX:** The locked decision is overview-first latest summary with history as drill-down. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- **Literal proof-envelope dumping in HEEx:** `format_version` and `proof_type` are machine-contract fields, not first-class UI chrome. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex]
- **Subject expansion beyond the fixed inventory:** Evidence subjects are closed and validated through `Threadline.Evidence.Subject`. [VERIFIED: lib/threadline/evidence/subject.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Evidence query semantics | Direct LiveView SQL or ad hoc Ecto query fragments | `Threadline.Evidence` helpers | They already centralize allowed filters and latest/history semantics with explicit `repo:` handling. [VERIFIED: lib/threadline/evidence.ex] |
| Proof vocabulary and parity | Separate mounted verdict logic | `Threadline.Evidence.Proof` | The proof layer already standardizes `proven`, `inferred_posture`, and `unsupported` and is covered by tests. [VERIFIED: lib/threadline/evidence/proof.ex, test/threadline/evidence/proof_test.exs] |
| Evidence authorization model | Threadline-owned RBAC or tenant DSL | Host `authorize_fn` plus an explicit evidence/policy-style capability seam | The repo deliberately keeps auth/scope meaning host-owned and opaque. [VERIFIED: guides/operator-surface.md, lib/threadline/operator_surface/auth.ex, .planning/REQUIREMENTS.md] |
| Unsupported fallback UX | Inline copy duplicated per page | `UnsupportedView` plus `Threadline.OperatorSurface.Unsupported` descriptors | Existing mounted policy/coverage/export surfaces already use this truthful fallback pattern. [VERIFIED: lib/threadline/operator_surface/components/unsupported_view.ex, lib/threadline/operator_surface/unsupported.ex, lib/threadline/operator_surface/live/coverage_live.ex] |
| Live navigation state machine | Custom client-side router logic | LiveView `push_patch/2` plus `handle_params/3` | Official LiveView docs and current repo code both treat current-view URL changes this way. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] |

**Key insight:** This phase is mostly composition work over already-shipped evidence truth, not a new data model or new authorization system. [VERIFIED: .planning/ROADMAP.md, lib/threadline/evidence.ex, lib/threadline/operator_surface/auth.ex]

## Common Pitfalls

### Pitfall 1: Mounted/API/CLI Truth Drift
**What goes wrong:** The LiveView shows grouped or labeled evidence differently than the proof JSON or Mix task, so operators see different meaning depending on transport. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Why it happens:** The UI derives verdicts, subject names, or status language independently instead of consuming shared proof facts. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex]
**How to avoid:** Add a shared presenter over `Threadline.Evidence.Proof` and test it directly, then keep LiveView thin. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, test/threadline/evidence/proof_test.exs]
**Warning signs:** UI-only status atoms, duplicated verdict mapping, or test coverage that asserts strings only in one transport. [VERIFIED: lib/threadline/evidence/proof.ex, test/mix/tasks/threadline.evidence_show_test.exs]

### Pitfall 2: Accidental Support-Lane Overexposure
**What goes wrong:** A support-scoped session that can browse the main timeline gains evidence visibility without an explicit host decision. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Why it happens:** The route inherits broad `/audit` access instead of following the repo’s narrower capability-flag pattern. [VERIFIED: lib/threadline/operator_surface/auth.ex, guides/operator-surface.md]
**How to avoid:** Add an explicit evidence gate and render `UnsupportedView` with CLI/API fallback guidance when denied. [VERIFIED: lib/threadline/operator_surface/components/unsupported_view.ex, lib/threadline/operator_surface/unsupported.ex, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Warning signs:** No evidence-specific boolean/callback, hidden nav links instead of truthful denial, or tests that only exercise happy-path admin access. [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs, test/threadline/operator_surface/live/policy_redaction_live_test.exs]

### Pitfall 3: History Becomes the Unofficial Default
**What goes wrong:** The mounted route effectively behaves like an analyst console because deep history is the first view operators hit. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Why it happens:** The planner optimizes for completeness and forgets the locked overview-first requirement. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**How to avoid:** Make `mode=latest` or no mode the default request shape and demote history to links/buttons from overview cards/tables. [VERIFIED: lib/threadline/evidence/proof.ex, lib/mix/tasks/threadline.evidence.show.ex]
**Warning signs:** The root route immediately requests `list_history/2`, or the main heading is row-history language instead of “what can Threadline prove right now?”. [VERIFIED: lib/threadline/evidence.ex, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]

### Pitfall 4: Machine Envelope Leaks Into UI Chrome
**What goes wrong:** Operators see proof-wrapper details such as `format_version` or `proof_type` as primary page furniture. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Why it happens:** The mounted view is treated as a JSON viewer rather than an operator surface. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**How to avoid:** Keep the JSON envelope as the machine contract and surface only operator-facing meaning, fallback guidance, and history/latest context. [VERIFIED: lib/threadline/evidence/proof.ex, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
**Warning signs:** UI mockups or tests asserting `format_version` in visible content. [VERIFIED: lib/threadline/evidence/proof.ex]

### Pitfall 5: Unvalidated URL Params
**What goes wrong:** Bad subject/mode/history params produce crashes or inconsistent slices. [VERIFIED: lib/mix/tasks/threadline.evidence.show.ex, lib/threadline/evidence.ex]
**Why it happens:** `handle_params/3` trusts incoming params or bypasses the existing subject/filter validation boundary. [VERIFIED: lib/threadline/evidence/subject.ex, lib/threadline/evidence.ex] [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
**How to avoid:** Parse route params into the same bounded request shape the proof layer expects, and reject unsupported subjects or malformed subject-ref state early. [VERIFIED: lib/mix/tasks/threadline.evidence.show.ex, lib/threadline/evidence/subject.ex]
**Warning signs:** `String.to_existing_atom/1` on query params, raw `Jason.decode!` on URL fragments without guards, or direct use of user params inside query branches. [ASSUMED]

## Code Examples

Verified patterns from official sources and the current tree:

### Current-View Patch Navigation
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/live-navigation.html
def handle_event("show-history", _params, socket) do
  {:noreply, push_patch(socket, to: socket.assigns.base_path <> "?mode=history")}
end

def handle_params(params, _uri, socket) do
  {:noreply, assign(socket, :params, params)}
end
```
This is the right primitive when `/audit/evidence` stays inside the same LiveView and only the params change. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]

### Existing Unsupported-State Pattern
```elixir
# Source: lib/threadline/operator_surface/live/policy_redaction_live.ex
<%= if @threadline_policy_enabled do %>
  ...normal page...
<% else %>
  <Threadline.OperatorSurface.Components.UnsupportedView.unsupported_view
    descriptor={Unsupported.descriptor(:policy_redaction_unavailable)}
    base_path={@base_path}
  />
<% end %>
```
Mounted evidence should follow this same explicit denied/unavailable posture instead of silently disappearing. [VERIFIED: lib/threadline/operator_surface/live/policy_redaction_live.ex]

### Proof-Based Mounted Presenter Entry
```elixir
# Source: lib/threadline/evidence/proof.ex
request = [subject: "retention_run", mode: :latest]
document = Threadline.Evidence.Proof.proof_document(request, repo: repo)
status = document["claim_assessment"]["status"]
records = document["records"]
```
This is the stable parity boundary Phase 98 should consume before any UI grouping or translation. [VERIFIED: lib/threadline/evidence/proof.ex, test/threadline/evidence/proof_test.exs]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Full reload or ad hoc state changes for current-page filtering | `push_patch/2` plus `handle_params/3` for same-LiveView navigation. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] | Current LiveView docs for v1.1.30. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html] | Phase 98 should keep evidence drill-down URL-driven and shareable instead of building a page-local reducer. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] |
| Human-only evidence view | Stable wrapped proof document with verdict vocabulary and machine JSON output. [VERIFIED: lib/threadline/evidence/proof.ex, lib/mix/tasks/threadline.evidence.show.ex] | Shipped in Phase 97 on 2026-05-26 project state. [VERIFIED: .planning/STATE.md] | Mounted evidence can now plan against a fixed parity boundary instead of inventing one. [VERIFIED: lib/threadline/evidence/proof.ex, test/mix/tasks/threadline.evidence_show_test.exs] |
| Broad route auth with hidden page absence | Explicit sub-surface capability booleans plus `UnsupportedView` fallback. [VERIFIED: lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/components/unsupported_view.ex] | Present on current `/audit` coverage/policy/export tree. [VERIFIED: lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/live/policy_redaction_live.ex, lib/threadline/operator_surface/live/export_status_live.ex] | Evidence access should be planned as another explicit capability, not implied timeline access. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md] |

**Deprecated/outdated:**

- New operator UI family for evidence: rejected by milestone and phase contracts in favor of reuse of the existing `/audit` family. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- Literal CLI-document rendering in the mounted surface: rejected in favor of shared presenters over proof facts. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Raw URL-param anti-patterns such as unsafe JSON decoding or atom conversion are the most likely implementation mistakes if Phase 98 bypasses the existing request-shape validation seam. [ASSUMED] | Common Pitfalls | Low; the plan should still add explicit param validation tests, which would catch this regardless. |

## Open Questions

1. **Should evidence use a new `evidence_authorize_fn` or reuse the existing policy-style seam?**
   - What we know: current `Auth.on_mount/4` already assigns separate booleans for exports, coverage, and policy surfaces, and Phase 98 leaves this exact seam to agent discretion. [VERIFIED: lib/threadline/operator_surface/auth.ex, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
   - What's unclear: whether the planner wants API expansion in the router/auth contract now, or a minimal reuse of the policy-style gate for evidence. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
   - Recommendation: prefer the smallest explicit seam that keeps host ownership and testability obvious; reuse the policy-style pattern unless naming clarity or docs/tests become materially worse. [VERIFIED: lib/threadline/operator_surface/auth.ex, guides/operator-surface.md]

2. **What exact query-param vocabulary should the URL expose for subject/history drill-down?**
   - What we know: the route must stay URL-driven and additive to `/audit`, and the proof layer already has the concepts `subject`, `subject_ref`, `mode`, `from`, `to`, and `limit`. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/evidence/proof.ex, lib/mix/tasks/threadline.evidence.show.ex]
   - What's unclear: whether `subject_ref` should be represented as multiple stable keys, a compact encoded form, or a hybrid subject-specific param scheme. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
   - Recommendation: keep the URL human-readable and additive, and avoid shipping a generic JSON blob in the query string unless the subject-ref diversity makes explicit keys unworkable. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build and test the mounted evidence LiveView plus repo-local proof modules. [VERIFIED: mix.exs] | ✓ [VERIFIED: local shell probe `elixir --version`] | `1.19.5` [VERIFIED: local shell probe `elixir --version`] | — |
| Mix | Named verification commands and focused tests. [VERIFIED: CLAUDE.md, mix.exs] | ✓ [VERIFIED: local shell probe `mix --version`] | `1.19.5` [VERIFIED: local shell probe `mix --version`] | — |
| PostgreSQL | Integration/live tests and `Threadline.Test.Repo` boot path. [VERIFIED: test/test_helper.exs, test/support/repo.ex] | ✓ [VERIFIED: local shell probes `psql --version`, `pg_isready`] | `14.17`; local server accepting connections on `/tmp:5432`. [VERIFIED: local shell probes `psql --version`, `pg_isready`] | — |
| Phoenix optional surface stack | Mounted `/audit` evidence page itself. [VERIFIED: mix.exs, lib/threadline/operator_surface/router.ex] | ✓ in repo lock. [VERIFIED: mix.lock, test/threadline/operator_surface/gating_test.exs] | `phoenix 1.8.7`, `phoenix_live_view 1.1.30`, `phoenix_html 4.3.0`, `phoenix_pubsub 2.2.0`. [VERIFIED: mix.lock] | Capture-only adopters keep API/CLI access and skip mounted evidence entirely. [VERIFIED: mix.exs, guides/operator-surface.md] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local shell probes, mix.lock]

**Missing dependencies with fallback:**
- None for this repo environment. [VERIFIED: local shell probes, mix.lock]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with real PostgreSQL integration tests and Phoenix LiveView tests on the current tree. [VERIFIED: test/test_helper.exs, test/support/data_case.ex, test/threadline/operator_surface/live/coverage_live_test.exs] |
| Config file | `test/test_helper.exs` plus `test/support/data_case.ex`. [VERIFIED: test/test_helper.exs, test/support/data_case.ex] |
| Quick run command | `mix test test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1` before new Phase 98 tests exist, then add the new evidence-live/presenter tests to this band. [VERIFIED: mix.exs, test/threadline/evidence/proof_test.exs, test/mix/tasks/threadline.evidence_show_test.exs, test/threadline/operator_surface/auth_test.exs] |
| Full suite command | `mix verify.test` for the named repo proof band, with `mix ci.all` as the broader gate when docs/contracts change. [VERIFIED: CLAUDE.md, mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SURF-01 | `/audit/evidence` mounts inside the existing operator-surface route family and defaults to an overview-first read-only experience. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md] | integration/live | `mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ❌ Wave 0 |
| SURF-02 | Mounted evidence uses the same proof facts, subject inventory, and verdict vocabulary as API/CLI paths. [VERIFIED: .planning/REQUIREMENTS.md, lib/threadline/evidence/proof.ex, test/mix/tasks/threadline.evidence_show_test.exs] | unit + integration | `mix test test/threadline/operator_surface/evidence/presenter_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ❌ Wave 0 |
| SURF-03 | Mounted evidence access is host-owned and renders an explicit unsupported state when not granted. [VERIFIED: .planning/REQUIREMENTS.md, lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/components/unsupported_view.ex] | integration/live | `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/evidence/presenter_test.exs --max-failures 1` once those files exist. [ASSUMED]
- **Per wave merge:** `mix verify.test`. [VERIFIED: mix.exs]
- **Phase gate:** `mix verify.test`, and add `mix ci.all` if the phase updates docs or existing doc-contract assertions. [VERIFIED: mix.exs, test/threadline/operator_surface_doc_contract_test.exs]

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/live/evidence_live_test.exs` — mounted route, overview default, history drill-down, unsupported-state posture, and URL-param validation. [VERIFIED: test/threadline/operator_surface/live/coverage_live_test.exs, test/threadline/operator_surface/live/policy_redaction_live_test.exs]
- [ ] `test/threadline/operator_surface/evidence/presenter_test.exs` — proof-to-view-model parity for verdicts, subject grouping, and latest/history notes. [VERIFIED: test/threadline/evidence/proof_test.exs]
- [ ] Route/doc lock coverage for `/audit/evidence` in the repo’s doc-contract style, either by extending `test/threadline/operator_surface_doc_contract_test.exs` or by adding a focused evidence doc-contract file. [VERIFIED: test/threadline/operator_surface_doc_contract_test.exs, test/threadline/operator_surface/coverage_doc_contract_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Authentication remains host-owned and outside Threadline’s meaning boundary for this phase. [VERIFIED: .planning/REQUIREMENTS.md, guides/operator-surface.md] |
| V3 Session Management | no | Phase 98 consumes the existing operator-surface session handoff but does not define session semantics. [VERIFIED: guides/operator-surface.md, lib/threadline/operator_surface/auth.ex] |
| V4 Access Control | yes | Host `authorize_fn` plus an explicit evidence capability seam and unsupported-state fallback. [VERIFIED: lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/components/unsupported_view.ex, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md] |
| V5 Input Validation | yes | Validate URL params against bounded subject/mode/filter shapes before evidence queries. [VERIFIED: lib/threadline/evidence.ex, lib/threadline/evidence/subject.ex, lib/mix/tasks/threadline.evidence.show.ex] |
| V6 Cryptography | no | This phase renders persisted evidence and does not introduce new crypto primitives. [VERIFIED: .planning/ROADMAP.md, lib/threadline/evidence.ex] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized evidence visibility through inherited timeline access | Elevation of privilege | Explicit host-owned evidence gating and `UnsupportedView` fallback instead of implied inheritance. [VERIFIED: lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/components/unsupported_view.ex, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md] |
| Param tampering on subject/history filters | Tampering | Use bounded request parsing and existing subject/filter validation before calling `Threadline.Evidence`. [VERIFIED: lib/threadline/evidence.ex, lib/threadline/evidence/subject.ex, lib/mix/tasks/threadline.evidence.show.ex] |
| Mounted/API/CLI verdict drift | Repudiation | Centralize proof facts in `Threadline.Evidence.Proof` and test presenter parity. [VERIFIED: lib/threadline/evidence/proof.ex, test/threadline/evidence/proof_test.exs] |
| UI overclaiming host-owned semantics | Spoofing | Preserve the fixed verdict vocabulary and keep host auth/tenant semantics out of mounted interpretation. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md] |
| Evidence-subject expansion into compliance workflow scope | Tampering | Keep subject inventory closed through `Threadline.Evidence.Subject`. [VERIFIED: lib/threadline/evidence/subject.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md` - locked route, UX, parity, and auth decisions for this phase. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md]
- `.planning/REQUIREMENTS.md` - `SURF-01`, `SURF-02`, and `SURF-03` requirement contract. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/MILESTONE-ARC.md`, `.planning/research/v1.22-policy-evidence-plane.md` - milestone scope, current state, and non-goal boundary. [VERIFIED: .planning/ROADMAP.md, .planning/PROJECT.md, .planning/STATE.md, .planning/MILESTONE-ARC.md, .planning/research/v1.22-policy-evidence-plane.md]
- `CLAUDE.md` - project constraints, verification entrypoints, and domain-language rules. [VERIFIED: CLAUDE.md]
- `guides/operator-surface.md` - mount/auth/fallback contract and mounted workflow parity philosophy. [VERIFIED: guides/operator-surface.md]
- `guides/domain-reference.md` - evidence proof vocabulary and machine contract language. [VERIFIED: guides/domain-reference.md]
- `lib/threadline/evidence.ex`, `lib/threadline/evidence/subject.ex`, `lib/threadline/evidence/proof.ex` - canonical evidence query, subject inventory, and proof contract. [VERIFIED: lib/threadline/evidence.ex, lib/threadline/evidence/subject.ex, lib/threadline/evidence/proof.ex]
- `lib/mix/tasks/threadline.evidence.show.ex` - current CLI parity shape and request vocabulary. [VERIFIED: lib/mix/tasks/threadline.evidence.show.ex]
- `lib/threadline/operator_surface/router.ex`, `auth.ex`, `components/surface_header.ex`, `components/unsupported_view.ex`, `unsupported.ex`, and current LiveViews - established mounted surface patterns. [VERIFIED: lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/components/surface_header.ex, lib/threadline/operator_surface/components/unsupported_view.ex, lib/threadline/operator_surface/unsupported.ex, lib/threadline/operator_surface/live/timeline_live.ex, lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/live/policy_redaction_live.ex, lib/threadline/operator_surface/live/retention_history_live.ex]
- `mix.exs`, `mix.lock`, `test/test_helper.exs`, `test/support/data_case.ex`, and current evidence/operator-surface tests - dependency, environment, and validation architecture verification. [VERIFIED: mix.exs, mix.lock, test/test_helper.exs, test/support/data_case.ex, test/threadline/evidence/proof_test.exs, test/mix/tasks/threadline.evidence_show_test.exs, test/threadline/operator_surface/auth_test.exs, test/threadline/operator_surface/live/coverage_live_test.exs, test/threadline/operator_surface/live/policy_redaction_live_test.exs, test/threadline/operator_surface/live/retention_history_live_test.exs, test/threadline/operator_surface_doc_contract_test.exs]
- Phoenix LiveView docs - live navigation, `push_patch/2`, and `handle_params/3` guidance. [CITED: https://hexdocs.pm/phoenix_live_view/live-navigation.html]
- Hex package pages for Phoenix stack version currency. [CITED: https://hex.pm/packages/phoenix] [CITED: https://hex.pm/packages/phoenix_live_view] [CITED: https://hex.pm/packages/ecto_sql] [CITED: https://hex.pm/packages/postgrex] [CITED: https://hex.pm/packages/phoenix_html/versions]

### Secondary (MEDIUM confidence)

- None. [VERIFIED: research session source inventory]

### Tertiary (LOW confidence)

- None beyond the explicitly labeled assumptions in the Assumptions Log. [VERIFIED: research session source inventory]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 98 should reuse the repo’s existing Phoenix/LiveView optional stack and repo-local evidence modules; no new dependency choice is required. [VERIFIED: mix.exs, mix.lock, lib/threadline/evidence.ex, lib/threadline/operator_surface/router.ex]
- Architecture: HIGH - the route shape, overview-first workflow, parity boundary, and explicit gating posture are already locked in `98-CONTEXT.md` and match current `/audit` patterns. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/auth.ex, lib/threadline/operator_surface/live/timeline_live.ex]
- Pitfalls: HIGH - the main failure modes are explicit in locked decisions and are reinforced by existing coverage/policy/export surface patterns. [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md, lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/live/policy_redaction_live.ex, lib/threadline/operator_surface/live/export_status_live.ex]

**Research date:** 2026-05-26 [VERIFIED: current session date]
**Valid until:** 2026-06-25 for repo-local patterns; 2026-06-02 for upstream package-version currency. [VERIFIED: mix.lock] [CITED: https://hex.pm/packages/phoenix] [CITED: https://hex.pm/packages/phoenix_live_view]
