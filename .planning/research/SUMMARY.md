# Research Summary: Threadline v1.21 - Scoped Support / Operator Proof (Option 2)

**Domain:** Phoenix-hosted support/operator adoption lane
**Researched:** 2026-05-24
**Overall confidence:** HIGH

## Executive Summary

Option 2 is the right v1.21 shape if the milestone is framed as **proof plus limited productization**, not as "Threadline now ships a full support console." The repo already contains the essential primitives: a secure mount boundary, shared `%{assigns: assigns}` authorization, an opaque host-owned `scope`, a `scope_query_fn` seam, support-vs-admin example wiring, export denial parity, and focused scope tests for timeline, actor, transaction, and export flows. The highest-leverage work is to turn that from "callback pattern plus prose" into a first-party lane with clearer recipes, tighter proof, and fewer adopter footguns.

The core thesis is simple: **productize the mount contract, not the auth model**. Threadline should make the support-safe `/audit` lane easy to mount, reason about, and verify, while keeping tenancy, RBAC, org membership, impersonation, and page-policy semantics host-owned. In Phoenix terms, that means leaning further into the idiomatic split Phoenix itself recommends: authenticate in plugs, authorize again in LiveView `on_mount`, keep HTTP export auth separate, and push domain-specific visibility into Ecto query composition rather than UI-only branching.

The main reason to choose Option 2 now is adoption leverage. This repo's remaining Phoenix SaaS question is no longer "can `/audit` exist?" but "can support staff use `/audit` safely enough that adopters will trust the pattern?" First-party mount recipes, clearer denial/fallback UX, a polished example app, and one or two narrow API affordances can answer that without opening a second product surface.

The main reason **not** to overextend Option 2 is that the repo is still one step away from an honest "fully productized support lane" claim. The biggest current gap is row-history/as-of support: `RowHistoryComponent` calls `Threadline.history/3` and `Threadline.as_of/4` directly, without the support scope seam. That means v1.21 should either scope that path, disable it for support, or explicitly exclude it from the support-lane promise. Anything broader than that starts drifting into a Threadline-owned tenancy/RBAC DSL, which would be a strategic mistake.

## Key Findings

**Thesis:** Choose Option 2 only as a narrow adopter-proof milestone: make the support lane runnable, documented, and testable, but keep all authorization semantics and tenant meaning host-owned.

**Stack:** Keep the existing optional Phoenix/LiveView stack and current Plug/Ecto patterns. No new required runtime dependencies are justified for this milestone.

**Architecture:** Standardize one support-safe composition pattern around `pipe_through` + `authorize_fn` + `scope_query_fn`, with HTTP export auth kept separate and row visibility enforced in queries, not UI-only checks.

**Critical pitfall:** Do not claim a general support lane until row-history/as-of is either scoped or disabled for scoped operators.

## Requested Evaluation

### 1. Thesis

Choose Option 2 if v1.21 is explicitly about **adoption proof and support-lane ergonomics**, not deeper operator product scope. "Limited productization" should mean:

1. Ship canonical first-party mount recipes for admin-only, shared `/audit`, and optional separate support tree.
2. Tighten denial/fallback behavior so allowed, denied, and out-of-scope states are predictable across LiveView and HTTP.
3. Polish docs and the example app until adopters can copy one honest path.
4. Add only narrow surface controls that keep the support claim honest, such as `exports: false`-style switches for any unscoped workflow.

It should **not** mean Threadline learns roles, org hierarchies, impersonation semantics, policy DSLs, or page-by-page authorization rules.

### 2. Pros

- High leverage on the biggest remaining Phoenix adoption gap.
- Builds on already-shipped seams instead of inventing a second architecture.
- Fits Phoenix/Plug/LiveView best practices: plug auth first, mount auth second, query scoping in Ecto.
- Improves adopter trust more than another generic feature family would.
- Keeps the package-boundary story clean: better lane proof, no new package, no new hard deps.

### 3. Cons / Risks

- Easy to overclaim and accidentally imply Threadline owns support authorization.
- Row-history/as-of is not yet honestly support-safe on the current seam.
- Same-tree admin/support mounts can confuse adopters unless denial rules are very explicit.
- Docs and example app can drift into Sigra-specific or one-host-specific storytelling if not kept narrowly framed.

### 4. Architectural Implications

- Treat `scope_query_fn` as the only row-visibility seam. Do not fork authorization logic per page.
- Keep `authorize_fn` about allow/deny plus opaque scope handoff; keep `scope_query_fn` about query narrowing.
- Preserve the Phoenix split between LiveView auth and sibling HTTP export auth.
- Add support-lane proof only for surfaces that actually participate in scoped query enforcement.

### 5. DX / UX Implications

- Adopters need a copy-pasteable recipe, not a concept lecture.
- Support operators need predictable UX:
  pipeline denial = host-owned redirect/403,
  mount denial = fail closed,
  out-of-scope resource = hidden/not found,
  export denial = hidden button plus HTTP `403`.
- Example app should show both the happy admin path and the constrained support path with realistic fixtures.

### 6. Recommended Phase Shape If Chosen

1. **Lane Contract and Scope Inventory**
   - Freeze the exact support-lane claim.
   - Inventory which screens are truly scope-aware today.
   - Decide whether row-history is scoped in this milestone or disabled for support.

2. **First-Party Mount Recipes**
   - Canonicalize shared-tree and separate-support-tree recipes.
   - Keep one shared `%{assigns: assigns}` authorizer story.
   - Document when to use `export_authorize_fn` versus `exports: false`.

3. **Denial / Fallback UX Closure**
   - Align LiveView denial, export denial, hidden affordances, and out-of-scope states.
   - Add only narrow API affordances needed for least surprise.

4. **Example App and Docs Proof**
   - Make the example app the runnable support-lane proof, not just a mention.
   - Add fixture-backed support scenarios and route-level verification.

5. **Final Proof and Lifecycle Docs**
   - Upgrade-path, operator-surface, SaaS quickstart, and example README all teach the same lane.
   - Verification should name what is supported and what remains intentionally host-owned.

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Claim Narrowing and Surface Audit** - lock the support-lane promise before adding code.
   - Addresses: lane definition, support-safe screen inventory, row-history gap.
   - Avoids: overclaiming broad support-safe access.

2. **Mount Recipes and Minimal API Controls** - make the host composition path copy-pasteable.
   - Addresses: first-party mount recipes, any `exports: false`-style support switches.
   - Avoids: accidental drift into policy DSL territory.

3. **Denial Semantics and UX Proof** - make failure behavior unsurprising.
   - Addresses: LiveView deny path, export `403`, hidden affordances, out-of-scope not-found behavior.
   - Avoids: leaking identifiers or confusing operators.

4. **Example-App Proof and Docs Closure** - make the lane runnable and staging-honest.
   - Addresses: example fixtures, tests, guide alignment, adoption proof.
   - Avoids: docs that outrun repo evidence.

**Phase ordering rationale:**
- The lane claim must be narrowed before UX polish, or the team will polish the wrong surface.
- Mount recipes and small API controls come before doc polish because the docs should describe the final copy-paste path.
- Example proof comes after semantics are locked so the repo only proves one coherent story.

**Research flags for phases:**
- Phase 1: needs explicit review of which screens are safe to claim for support.
- Phase 2: likely needs one narrow public-option decision; keep it additive.
- Phase 3: standard Phoenix/Plug patterns, low research risk.
- Phase 4: low technical risk, but high wording-drift risk.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | This milestone should reuse the current stack and idioms rather than change infrastructure. |
| Features | HIGH | The repo already points to this exact adopter gap and already contains most of the seam. |
| Architecture | HIGH | Phoenix LiveView security guidance and the current repo converge on the same split of concerns. |
| Pitfalls | HIGH | The row-history scope gap and RBAC-overreach risk are concrete, repo-visible issues. |

## Gaps to Address

- Decide whether support-lane row history is in or out for v1.21.
- Decide whether one narrow public option is needed for unavailable workflows on support mounts.
- Confirm whether LiveView mount denial should stay rooted at `/` or become mount-configurable for better host ergonomics.

## Sources

- Local repo:
  - `guides/operator-surface.md`
  - `guides/integration-contracts.md`
  - `guides/upgrade-path.md`
  - `examples/threadline_phoenix/README.md`
  - `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
  - `lib/threadline/operator_surface/auth.ex`
  - `lib/threadline/operator_surface/export_auth_plug.ex`
  - `lib/threadline/operator_surface/router.ex`
  - `lib/threadline/operator_surface/live/row_history_component.ex`
  - `lib/threadline/operator_surface/scope.ex`
  - `test/threadline/operator_surface/auth_test.exs`
  - `test/threadline/operator_surface/export_auth_plug_test.exs`
  - `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`
- Official docs:
  - Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
  - Phoenix LiveView router: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html
  - Phoenix routing: https://hexdocs.pm/phoenix/routing.html
  - Plug.Conn: https://hexdocs.pm/plug/Plug.Conn.html
  - Ecto.Query: https://hexdocs.pm/ecto/Ecto.Query.html
