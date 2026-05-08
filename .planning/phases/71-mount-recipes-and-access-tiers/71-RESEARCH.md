# Phase 71: Mount Recipes & Access Tiers - Research

**Researched:** 2026-05-08 [VERIFIED: current session]
**Domain:** Phoenix operator-surface mount/auth composition for admin and support-read-only access tiers [VERIFIED: user objective + `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md`]
**Confidence:** HIGH [VERIFIED: evidence synthesis in this document]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md`. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

### Locked Decisions

- **D-123: Ship one canonical mount topology and two host-owned recipes, not two products.** Threadline should document one `/audit` mount story that can be adapted for `admin` and `support-read-only`, rather than separate route trees, separate products, or separate top-level doc narratives.
- **D-124: `admin` means the full mounted surface behind the host's authenticated browser/admin boundary plus host `authorize_fn`.** This is the strongest and least surprising recipe for the primary operator audience.
- **D-125: `support-read-only` should reuse the same mounted surface, not a narrower default route tree.** The distinction is narrower effective visibility and stricter data-egress posture, not a second UI shape maintained by Threadline.
- **D-126: `support-read-only` access should flow through host-owned scope, not Threadline-owned roles.** The canonical support recipe should return `{:ok, scope}` from `authorize_fn`, with an explicit example like `%{access: :support_read_only, organization_id: org_id}`. Threadline carries that scope; the host owns what it means.
- **D-127: Exports are the primary read-only footgun and should be stricter than page access in the support recipe.** The canonical `support-read-only` recipe should disable exports by default with `exports: false`. If a host deliberately wants support exports, that is an explicit opt-in and should use `export_authorize_fn`.
- **D-128: Do not teach separate support route trees as the default recipe.** Support-only route subsets, page removal, or alternate mount paths are custom/unclaimed host integrations unless later phases explicitly standardize them.

### Mount / Auth Shape

- **D-129: The canonical docs should recommend `pipe_through [:browser, :admin_auth]` plus `authorize_fn`; not either/or as equal first-class patterns.** Phoenix router auth and Threadline surface auth are complementary layers and should be documented that way.
- **D-130: Publish one shared assigns-shaped `authorize_fn` as the default teaching shape.** The canonical host callback should accept `%{assigns: assigns}` so it works for both LiveView sockets and the export fallback mirror without separate default examples.
- **D-131: Keep `export_authorize_fn` as an advanced override, not the baseline recipe.** It exists for HTTP-specific needs like stricter download policy, signed-request checks, or explicit support-export opt-in, but most adopters should start with one shared callback.
- **D-132: Keep `{:ok, scope}` explicitly opaque and host-owned.** Threadline should not define a role vocabulary, permission enum, or tenancy DSL around it. It is only the scope carrier.
- **D-133: Docs must state that HTTP exports have their own Plug auth boundary because `live_session` / `on_mount` does not cover controller routes.** This is an intentional transport split, not an incidental implementation detail.
- **D-134: Export denials remain HTTP-native (`403` + halt), not LiveView-style redirects.** This preserves least surprise for download endpoints and matches the current `ExportAuthPlug` contract.
- **D-135: The current split example-app `my_authorize_fn/1` pattern should not be the canonical recipe.** It invites silent drift between `%Plug.Conn{}` and `%Phoenix.LiveView.Socket{}` paths and is weaker DX than a shared assigns-shaped callback.

### Scoped Visibility Promise

- **D-136: Keep the support-visibility promise narrow and honest.** Phase 71 should promise that `support-read-only` can carry host-owned scope into investigation flows; it should not promise automatic narrowing everywhere unless the specific screen/query path is explicitly implemented and tested for that scope.
- **D-137: The strongest default is “same surface, narrower effective visibility,” not “hide a few pages.”** This best matches the current architecture, lessons from Oban Web / Ash / Datadog / GitHub-style operator surfaces, and the milestone's host-owns-auth boundary.
- **D-138: Reopen the design only if the phase intends to standardize page-level blocking for support users.** Blocking access to specific pages like `/audit/coverage` or `/audit/policy/redaction` would require a new route-shaping or route-aware authorization contract and is outside the default recipe.

### Fallback Parity Story

- **D-139: Promise parity for core operator questions, not exact UI-to-CLI feature parity.** The phase should keep the mounted surface as the canonical operator story while respecting capture-only adopters through explicit fallback equivalents.
- **D-140: Every canonical mounted workflow should name its best fallback transport inline.** This should happen where the workflow is introduced, not only in a separate appendix or sidebar.
- **D-141: Use dedicated Mix tasks inline only where Threadline already ships them.**
  - incident drill-down -> `mix threadline.incident`
  - current-view export -> `mix threadline.export`
  - coverage -> `mix threadline.health.coverage`
  - policy drift -> `mix threadline.policy.show`
- **D-142: Where no dedicated task exists, document the canonical API equivalent inline instead of implying a missing task should exist.**
  - timeline browse/filter -> `Threadline.timeline/2`, `Threadline.timeline_page/2`
  - actor window -> `Threadline.actor_history/2` plus transaction drill-down helpers
  - row history / as-of -> `Threadline.history/3`, `Threadline.as_of/4`
- **D-143: Add one compact parity table to the operator-surface docs or the new mount/runbook doc.** It should map mounted workflow -> operator question -> fallback path -> guarantee level, while keeping the main narrative surface-first.
- **D-144: Do not create new Phase 71 tasks or features solely to make the fallback story look more symmetrical.** Shared vocabulary and explicit mapping are the goal; fake “full parity” claims are not.

### Documentation Posture

- **D-145: Preserve the surface-first canonical narrative from Phases 68 and 70.** Capture-only stays a respected subordinate path, not a co-equal top-level onboarding or operator track.
- **D-146: Keep one obvious doc path.** Phase 71 should favor one primary mount/runbook story that shows the admin recipe first, then the support-read-only variation, then the fallback equivalents.
- **D-147: Bias toward least surprise and strongest defaults.** For this phase, downstream agents should treat the cohesive researched recommendations below as locked unless they uncover a true high-impact conflict in `security_model`, `semver`, `breaking_public_api`, or `scope_cut`.

### the agent's Discretion

- Exact doc layout across `guides/operator-surface.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, or a new Phase 71 mount/runbook guide, as long as there is one clear canonical source and cross-links stay coherent.
- Exact names used for the two recipes (`admin` / `support-read-only` vs slightly different phrasing), as long as the semantics above remain unchanged.
- Exact shape of the compact parity table, as long as it clearly maps mounted workflow, fallback transport, and guarantee level.
- Exact host example names and snippet wording, as long as the shared assigns-shaped `authorize_fn` pattern and support `exports: false` default remain explicit.

### Deferred Ideas (OUT OF SCOPE)

- Separate support route trees or support-only page subsets — custom host integrations unless a future phase explicitly standardizes them.
- A Threadline-owned role or permission vocabulary — out of scope for v1.19 and contrary to the host-owns-auth boundary.
- Page-level or route-aware authorization DSL inside Threadline — only revisit if a future phase explicitly scopes that work.
- New Mix tasks or new UI features created solely to claim tighter parity.
- Stronger promises that every screen/query path automatically enforces support scope — defer unless the implementation and tests land in this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTEG-03 | The operator surface has a documented and tested host-owned access pattern for router pipeline checks, LiveView mount checks, and optional scoped investigation queries, without introducing a Threadline-owned user or role model. [VERIFIED: .planning/REQUIREMENTS.md] | Use `pipe_through [:browser, :admin_auth]` plus shared `%{assigns: assigns}` `authorize_fn`, keep `{:ok, scope}` opaque, and lock scope promises to currently tested query paths. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] |
| ADOPT-08 | Threadline ships canonical mount recipes for secure admin and support-read-only operator-surface installs, including router placement, `live_session` / mount-auth expectations, and first verification steps. [VERIFIED: .planning/REQUIREMENTS.md] | Publish one canonical admin recipe first, then a support-read-only variation with `exports: false`, explicit first checks, and inline fallback parity. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] [VERIFIED: lib/threadline/operator_surface/router.ex] |
</phase_requirements>

## Summary

Threadline already has the core implementation seams this phase needs: the router macro enforces a secure mount boundary, `Auth.on_mount/4` accepts `:ok | true | {:ok, scope}` and stores scope on the socket, and `ExportAuthPlug` enforces a separate HTTP export boundary with `403` halts plus synthetic `%{assigns: conn.assigns}` fallback to `authorize_fn`. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]

The main planning risk is not missing infrastructure; it is teaching the wrong canonical recipe. The current example app still demonstrates a split authorizer that pattern-matches `%Plug.Conn{}` and `%Phoenix.LiveView.Socket{}` separately, while the phase context and export fallback contract both point to one shared assigns-shaped callback as the safest default. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

Scope support is real but narrow today: TimelineLive threads `:threadline_scope` into query options and has a focused scoped-mount test, but the current implementation does not prove scope-aware narrowing across every operator screen. Planning should therefore standardize how support scope is carried, while keeping the public promise limited to “same surface, narrower effective visibility where implemented and tested.” [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs] [VERIFIED: rg \"threadline_scope|scope:\" lib/threadline/operator_surface/live lib/threadline]

**Primary recommendation:** Document one `/audit` mount topology with `pipe_through [:browser, :admin_auth]` plus a shared `%{assigns: assigns}` `authorize_fn`; teach `admin` as full access, teach `support-read-only` as the same mount with `{:ok, scope}` and `exports: false`, and lock the wording with new doc-contract coverage before expanding scope promises. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Browser session/admin gate | Frontend Server (SSR) | Browser / Client | The host router pipeline must authenticate the browser request before the LiveView session starts. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| LiveView page authorization | Frontend Server (SSR) | Browser / Client | LiveViews must run their own mount checks because live navigation does not re-run the plug pipeline. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Export-route authorization | Frontend Server (SSR) | — | HTTP export routes are regular `get` routes and therefore need their own plug-equivalent auth boundary outside `live_session`. [VERIFIED: lib/threadline/operator_surface/router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Scope carriage into investigation queries | API / Backend | Frontend Server (SSR) | Threadline stores host-owned scope in assigns, but query narrowing belongs in backend query functions rather than in the browser. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] |
| Capture-only fallback parity | API / Backend | CLI | The fallback surfaces are Mix tasks and core APIs, not alternate browser UI trees. [VERIFIED: guides/operator-surface.md] [VERIFIED: guides/getting-started-saas.md] |
| Role semantics and tenancy meaning | Host application backend | Frontend Server (SSR) | Threadline carries scope but does not define roles, permission enums, or tenancy rules. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] [VERIFIED: guides/integration-contracts.md] |

## Project Constraints (from CLAUDE.md)

- Preserve the three-layer split: capture, semantics, and exploration/operations must not be conflated. [VERIFIED: CLAUDE.md]
- Keep auth, roles, and tenancy host-owned; do not introduce a Threadline-owned auth model. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints such as `mix verify.*` and `mix ci.all` in docs and planning. [VERIFIED: CLAUDE.md]
- Keep doc contract tests aligned with public guides and example docs. [VERIFIED: CLAUDE.md]
- Preserve the optional-dependency posture; Phase 71 must not add new hard runtime dependencies. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/ROADMAP.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `threadline` | `0.4.0` [VERIFIED: mix.exs] | Provides `threadline_operator_surface/2`, `Auth.on_mount/4`, export auth, and fallback tasks. [VERIFIED: mix.exs] [VERIFIED: lib/threadline/operator_surface/router.ex] | This phase is documenting the existing in-tree contract, not introducing a new package boundary. [VERIFIED: .planning/ROADMAP.md] |
| `phoenix` | `1.8.7` root tested resolution [VERIFIED: mix.lock] | Router scopes, pipelines, and controller routes for the mounted surface. [VERIFIED: mix.lock] | The repo’s `phoenix-surface` lane is proven against the root lock and CI, so planning should stay inside that shape. [VERIFIED: guides/upgrade-path.md] |
| `phoenix_live_view` | `1.1.30` root tested resolution [VERIFIED: mix.lock] | `live_session`, `on_mount`, and the operator LiveViews. [VERIFIED: mix.lock] | Official LiveView guidance requires plug auth plus mount auth, which matches the current architecture. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| `plug` | repo declares `~> 1.15` [VERIFIED: mix.exs] | Host pipelines and export-route auth plug boundary. [VERIFIED: mix.exs] | Export routes are regular HTTP requests and must be enforced with Plug semantics. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_html` | `4.3.0` root tested resolution [VERIFIED: mix.lock] | Required by the optional surface stack. [VERIFIED: mix.lock] | Use for the `phoenix-surface` lane only. [VERIFIED: guides/upgrade-path.md] |
| `phoenix_pubsub` | `2.2.0` root tested resolution [VERIFIED: mix.lock] | Required by the optional surface stack. [VERIFIED: mix.lock] | Use for the `phoenix-surface` lane only. [VERIFIED: guides/upgrade-path.md] |
| `sigra` | `0.2.5` example tested resolution [VERIFIED: examples/threadline_phoenix/mix.lock] | Request-capture adapter for the `sigra-reference` lane only. [VERIFIED: guides/integrations/sigra.md] | Use only for the reference lane; it is not the operator-surface auth system. [VERIFIED: guides/integrations/sigra.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared `%{assigns: assigns}` `authorize_fn` [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] | Separate `%Plug.Conn{}` and `%Phoenix.LiveView.Socket{}` heads [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] | The split example is easier to drift and weakens export fallback parity. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |
| Same `/audit` tree for admin and support [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] | Separate support-only mount path or route subset [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] | Separate trees create extra maintenance surface and are explicitly unclaimed. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |
| `exports: false` by default for support [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] | Export access inherited automatically from page access [VERIFIED: lib/threadline/operator_surface/router.ex] | Automatic support exports increase data-egress risk and conflict with the phase’s stronger default. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |

**Installation:** [VERIFIED: guides/getting-started-saas.md]
```bash
mix deps.get
```

Host dependency shape for the mounted lane: [VERIFIED: mix.exs] [VERIFIED: guides/upgrade-path.md]
```elixir
{:threadline, "~> 0.4"}
```

## Architecture Patterns

### System Architecture Diagram

The canonical flow should be documented like this, not as a file list. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] [VERIFIED: lib/threadline/operator_surface/router.ex]

```text
Browser request
  -> Phoenix router scope "/audit"
  -> pipe_through [:browser, :admin_auth]
  -> live_session :threadline
  -> Threadline.OperatorSurface.Auth.on_mount(authorize_fn)
  -> LiveView screen
  -> Threadline query/API calls
  -> Repo / audit tables

Browser export click
  -> GET /audit/exports/changes.{csv,json,ndjson}
  -> :threadline_exports pipeline
  -> Threadline.OperatorSurface.ExportAuthPlug
  -> Export controller
  -> Threadline export/query APIs
  -> Repo / audit tables

Support-read-only variation
  -> same router path
  -> same authorize_fn transport shape
  -> returns {:ok, scope}
  -> surface carries scope
  -> only tested/narrowed query paths apply scope
  -> exports disabled by default

Capture-only fallback
  -> operator question
  -> Mix task or core API
  -> Repo / audit tables
```

### Recommended Project Structure

```text
guides/
├── operator-surface.md        # canonical mount/runbook source for Phase 71
├── integration-contracts.md   # callback/export contract reference
├── getting-started-saas.md    # first-hour narrative, cross-link only
├── upgrade-path.md            # support-lane and proof matrix
└── integrations/sigra.md      # Sigra request-capture lane only

examples/threadline_phoenix/
└── lib/threadline_phoenix_web/router.ex   # runnable proof snippet, not the primary narrative owner

test/threadline/
├── operator_surface_doc_contract_test.exs
├── integration_contracts_doc_contract_test.exs
├── getting_started_saas_doc_contract_test.exs
└── example_phoenix_readme_contract_test.exs
```

### Pattern 1: Dual Boundary Auth

**What:** Use router pipeline auth for the browser boundary and `authorize_fn` for LiveView mount auth. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]

**When to use:** Always for the canonical mounted recipes. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**Example:**
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/security-model.html + lib/threadline/operator_surface/router.ex
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    repo: MyApp.Repo,
    authorize_fn: &MyApp.Audit.authorize_operator/1
end
```

### Pattern 2: Shared Assigns-Shaped Authorizer

**What:** Publish one `%{assigns: assigns}`-shaped callback that works for LiveView sockets and the export fallback mirror. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**When to use:** Default recipe for both `admin` and `support-read-only`. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**Example:**
```elixir
# Source: lib/threadline/operator_surface/export_auth_plug.ex + .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md
def authorize_operator(%{assigns: %{current_user: %{is_admin: true}}}), do: :ok

def authorize_operator(%{assigns: %{current_user: %{support?: true, org_id: org_id}}}) do
  {:ok, %{access: :support_read_only, organization_id: org_id}}
end

def authorize_operator(_), do: false
```

### Pattern 3: Support Exports Disabled By Default

**What:** Reuse the same mount tree but suppress export routes with `exports: false`. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**When to use:** Canonical support-read-only recipe. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**Example:**
```elixir
# Source: lib/threadline/operator_surface/router.ex + .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md
threadline_operator_surface "/",
  repo: MyApp.Repo,
  authorize_fn: &MyApp.Audit.authorize_operator/1,
  exports: false
```

### Anti-Patterns to Avoid

- **LiveView-only authorizer examples:** They break the export fallback teaching story because the fallback mirror is `%{assigns: conn.assigns}`, not a `%Phoenix.LiveView.Socket{}`. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]
- **Treating `pipe_through` and `authorize_fn` as interchangeable:** Official LiveView guidance requires both request-path and mount-path checks for secured live areas. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html]
- **Promising automatic support narrowing everywhere:** Only TimelineLive currently proves a scope-aware path. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs]
- **Teaching a second support route tree as default:** The phase context explicitly marks that as out of scope. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| LiveView auth grouping | Custom per-LiveView ad hoc checks | `live_session` + `on_mount` [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] | Phoenix already defines the correct session boundary and auth lifecycle. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Export-route parity auth | Separate bespoke export permission system | `ExportAuthPlug` plus optional `export_authorize_fn` [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] | The current plug already preserves telemetry, scope, and HTTP-native denial behavior. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| Support read-only page subsets | Custom alternate route tree | Same mounted surface + host scope + `exports: false` [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] | The default requirement is “same surface, narrower visibility,” not two products. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |
| Library-owned role system | Threadline roles/permission DSL | Host-owned scope map [VERIFIED: guides/integration-contracts.md] | The milestone boundary explicitly forbids Threadline-owned auth semantics. [VERIFIED: .planning/REQUIREMENTS.md] |

**Key insight:** The repo already has the security-critical primitives; the planner should spend effort on canonical recipe wording and proof coverage, not on new auth infrastructure. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]

## Common Pitfalls

### Pitfall 1: Split Authorizer Drift

**What goes wrong:** Example code diverges between `%Plug.Conn{}` and `%Phoenix.LiveView.Socket{}` branches, so exports and LiveViews stop enforcing the same policy. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]

**Why it happens:** The current example app teaches separate heads instead of the shared mirror-friendly shape. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]

**How to avoid:** Make the canonical recipe accept `%{assigns: assigns}` and reserve `export_authorize_fn` for explicit advanced overrides only. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]

**Warning signs:** Example docs mention `%Plug.Conn{}` or `%Phoenix.LiveView.Socket{}` in the default authorizer snippet. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]

### Pitfall 2: Assuming `live_session` Protects Export GET Routes

**What goes wrong:** Export endpoints are mounted but receive weaker auth than the LiveViews. [VERIFIED: lib/threadline/operator_surface/router.ex]

**Why it happens:** `live_session` / `on_mount` only covers live routes, not controller `get` routes. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html]

**How to avoid:** Keep the export controller scope outside `live_session` and behind `ExportAuthPlug`; document this as intentional transport split. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]

**Warning signs:** Docs say exports “reuse LiveView auth automatically” without mentioning `ExportAuthPlug` or `export_authorize_fn`. [VERIFIED: guides/integration-contracts.md]

### Pitfall 3: Overclaiming Support Scope

**What goes wrong:** Docs imply all screens are narrowed for support users when only timeline-level scope plumbing is proven. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [VERIFIED: rg \"threadline_scope|scope:\" lib/threadline/operator_surface/live lib/threadline]

**Why it happens:** `{:ok, scope}` exists at the auth layer, which makes it easy to overgeneralize downstream behavior. [VERIFIED: lib/threadline/operator_surface/auth.ex]

**How to avoid:** Promise scope carriage broadly, but promise scope enforcement only on the specific screen/query paths that have implementation plus tests. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**Warning signs:** Support recipe wording says “all investigations are automatically tenant-filtered” without new tests. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

### Pitfall 4: Treating Read-Only as “Hide a Few Pages”

**What goes wrong:** Planning turns `support-read-only` into page surgery or route pruning instead of data-egress and scope policy. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**Why it happens:** Operator surfaces often tempt teams to model read-only as navigation differences first. [CITED: https://hexdocs.pm/oban_web/limiting_access.html]

**How to avoid:** Keep one route tree; make support stricter through host scope and `exports: false` by default. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

**Warning signs:** Plan proposes `/audit/support` or removing screens by default. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

## Code Examples

Verified patterns from repo contract and official docs:

### Canonical Admin Mount
```elixir
# Source: https://hexdocs.pm/phoenix_live_view/security-model.html + lib/threadline/operator_surface/router.ex
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    repo: MyApp.Repo,
    authorize_fn: &MyApp.Audit.authorize_operator/1
end
```

### Canonical Support-Read-Only Mount
```elixir
# Source: lib/threadline/operator_surface/router.ex + .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    repo: MyApp.Repo,
    authorize_fn: &MyApp.Audit.authorize_operator/1,
    exports: false
end
```

### Optional Support Export Override
```elixir
# Source: lib/threadline/operator_surface/export_auth_plug.ex
threadline_operator_surface "/",
  repo: MyApp.Repo,
  authorize_fn: &MyApp.Audit.authorize_operator/1,
  export_authorize_fn: &MyApp.Audit.authorize_operator_export/1
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Route auth alone for LiveView areas | Router auth plus mount auth [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] | Current Phoenix LiveView guidance [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] | Plans must treat `pipe_through` and `authorize_fn` as complementary, not substitutes. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| Read-only as separate dashboards or page subsets | Same surface with scoped access and stricter action/data-egress policy [CITED: https://hexdocs.pm/oban_web/limiting_access.html] | Current Oban Web access model [CITED: https://hexdocs.pm/oban_web/limiting_access.html] | Phase 71 should standardize one mount plus support scope, not two products. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |
| Custom export auth logic per endpoint | Shared auth contract with optional override and fallback mirror [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] | Already present in Threadline v0.4.0 tree [VERIFIED: mix.exs] | Phase work is documentation/testing, not new security code. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |

**Deprecated/outdated:**

- Split example-app authorizer as the canonical teaching shape: outdated for this phase because it weakens the intended shared-callback story. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md]

## Assumptions Log

All claims in this research were verified or cited in this session; no user confirmation is required for the documented recommendations.

## Open Questions (RESOLVED)

1. **Which screen/query paths should become scope-aware in this phase?**
   - Resolution: keep the docs narrow and honest. Phase 71 standardizes host-owned scope carriage and only promises scoped behavior where code/tests already prove it today; broader page-by-page narrowing is not part of the default Phase 71 contract.
   - Verified basis: TimelineLive already carries scope into query options and has a scoped-mount test, while the rest of the surface does not yet have equivalent visible proof. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [VERIFIED: test/threadline/operator_surface/live/timeline_live_test.exs] [VERIFIED: rg \"threadline_scope|scope:\" lib/threadline/operator_surface/live lib/threadline]

2. **Where should the single canonical recipe live?**
   - Resolution: keep `guides/operator-surface.md` as the canonical mount/runbook source for Phase 71.
   - Verified basis: `guides/operator-surface.md` is already scoped to mount/auth/screens, while `guides/getting-started-saas.md` and the example README are better kept as cross-linking narrative/proof surfaces rather than full duplicate runbooks. [VERIFIED: guides/operator-surface.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: examples/threadline_phoenix/README.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | docs/tests/verification | ✓ [VERIFIED: `elixir --version`] | `1.19.5` [VERIFIED: `elixir --version`] | — |
| Mix | verification entrypoints | ✓ [VERIFIED: `mix --version`] | `1.19.5` [VERIFIED: `mix --version`] | — |
| PostgreSQL | default `mix test` path via `test/test_helper.exs` | ✓ [VERIFIED: `pg_isready`] | accepts on `5432` [VERIFIED: `pg_isready`] | — |
| Docker | local DB bootstrap if needed | ✓ [VERIFIED: `docker --version`] | `29.4.1` [VERIFIED: `docker --version`] | direct local PostgreSQL already works. [VERIFIED: `pg_isready`] |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local environment probes]

**Missing dependencies with fallback:**
- None. [VERIFIED: local environment probes]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`. [VERIFIED: mix.exs] [VERIFIED: `elixir --version`] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` [VERIFIED: local test run on 2026-05-08, 53 tests, 0 failures] |
| Full suite command | `mix ci.all` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTEG-03 | Router pipeline + LiveView mount + export auth boundaries remain host-owned and tested. [VERIFIED: .planning/REQUIREMENTS.md] | doc contract + unit + integration | `mix test test/threadline/integration_contracts_doc_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` | ✅ [VERIFIED: test files] |
| ADOPT-08 | Canonical admin/support recipes, router placement, `live_session` expectations, and first verification steps stay locked in docs. [VERIFIED: .planning/REQUIREMENTS.md] | doc contract | `mix test test/threadline/operator_surface_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` | ✅ [VERIFIED: test files] |

### Sampling Rate

- **Per task commit:** Run the focused Phase 71 doc/auth suite above. [VERIFIED: local test run on 2026-05-08, 53 tests, 0 failures]
- **Per wave merge:** Run `mix verify.test` plus `mix verify.doc_contract`. [VERIFIED: mix.exs]
- **Phase gate:** Run `mix ci.all`. [VERIFIED: mix.exs]

### Wave 0 Gaps

- [ ] `test/threadline/mount_recipes_doc_contract_test.exs` — lock the new admin vs support-read-only recipe wording, `exports: false` default, shared `%{assigns: assigns}` authorizer example, and parity table literals. [VERIFIED: current test inventory lacks a dedicated Phase 71 recipe contract]
- [ ] Extend `test/threadline/example_phoenix_readme_contract_test.exs` and/or `test/threadline/getting_started_saas_doc_contract_test.exs` to reject the split `%Plug.Conn{}` / `%Phoenix.LiveView.Socket{}` canonical example. [VERIFIED: current example router still uses split heads]
- [ ] Add at least one focused test for support-export opt-in via `export_authorize_fn` if the plan chooses to document that advanced override with concrete code. [VERIFIED: current export auth tests cover dispatch, not a named support-export recipe]
- [ ] Decide whether Phase 71 includes broader scope-aware screens; if yes, add matching tests before docs promise them. [VERIFIED: rg \"threadline_scope|scope:\" lib/threadline/operator_surface/live lib/threadline]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] | Host router pipeline plus session auth. [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| V3 Session Management | yes [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] | `live_session` boundaries with mount-time validation. [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html] |
| V4 Access Control | yes [VERIFIED: lib/threadline/operator_surface/auth.ex] | Host-owned `authorize_fn`, optional `export_authorize_fn`, and `{:ok, scope}` carriage. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| V5 Input Validation | yes [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] | Reuse `Threadline.Query.validate_timeline_filters!/1` and export filter parsing rather than custom screen-local validation. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] |
| V6 Cryptography | no [VERIFIED: phase scope and code surface] | No cryptographic feature is introduced in this phase. [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Mounted operator UI reachable without host auth | Elevation of Privilege | Require `pipe_through` before mount and keep `authorize_fn` fail-closed. [VERIFIED: lib/threadline/operator_surface/router.ex] [CITED: https://hexdocs.pm/phoenix_live_view/security-model.html] |
| Export endpoints weaker than page access | Information Disclosure | Keep export routes behind `ExportAuthPlug`; default support recipe sets `exports: false`. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |
| Support user sees cross-tenant data because scope promise outruns implementation | Information Disclosure | Keep docs narrow and add tests before claiming broader scope-aware screens. [VERIFIED: lib/threadline/operator_surface/live/timeline_live.ex] [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |
| Divergent auth logic between LiveView and HTTP transports | Tampering / Elevation of Privilege | Standardize one shared assigns-shaped callback and reserve `export_authorize_fn` for deliberate divergence only. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: .planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/71-mount-recipes-and-access-tiers/71-CONTEXT.md` - locked decisions, scope boundary, recipe requirements.
- `.planning/REQUIREMENTS.md` - `INTEG-03` and `ADOPT-08` contract.
- `.planning/ROADMAP.md` - phase goal and success criteria.
- `CLAUDE.md` - project constraints and verification conventions.
- `guides/operator-surface.md` - current public mount/auth/screen contract.
- `guides/integration-contracts.md` - current callback/export contract.
- `guides/getting-started-saas.md` - current surface-first walkthrough.
- `guides/upgrade-path.md` - support-lane matrix and tested resolutions.
- `guides/integrations/sigra.md` - Sigra reference-lane boundary.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - current runnable mount/auth example.
- `lib/threadline/operator_surface/router.ex` - secure mount and export-route contract.
- `lib/threadline/operator_surface/auth.ex` - LiveView auth and scope contract.
- `lib/threadline/operator_surface/export_auth_plug.ex` - HTTP export auth and mirror fallback contract.
- `lib/threadline/operator_surface/live/timeline_live.ex` - current scope-aware query path.
- `test/threadline/operator_surface/auth_test.exs` - auth contract behavior.
- `test/threadline/operator_surface/export_auth_plug_test.exs` - export auth parity behavior.
- `test/threadline/operator_surface/live/timeline_live_test.exs` - scoped mount proof.
- `mix.exs`, `mix.lock`, `examples/threadline_phoenix/mix.lock`, `.github/workflows/ci.yml` - version/proof/verification anchors.
- Phoenix LiveView security model - https://hexdocs.pm/phoenix_live_view/security-model.html
- Phoenix LiveView router docs - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html

### Secondary (MEDIUM confidence)

- Oban Web limiting access guide - https://hexdocs.pm/oban_web/limiting_access.html
- Oban Web resolver docs - https://hexdocs.pm/oban_web/Oban.Web.Resolver.html
- Phoenix LiveDashboard router docs - https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.Router.html
- Phoenix LiveDashboard overview - https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all recommended pieces are already present in repo code, lockfiles, or official Phoenix docs.
- Architecture: HIGH - the dual-boundary auth model is directly verified by current code and official LiveView guidance.
- Pitfalls: HIGH - each pitfall is grounded in either the current example/docs gap or explicit official transport-boundary guidance.

**Research date:** 2026-05-08
**Valid until:** 2026-06-07
