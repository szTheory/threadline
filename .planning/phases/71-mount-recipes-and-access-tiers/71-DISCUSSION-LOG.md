# Phase 71: Mount Recipes & Access Tiers - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `71-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 71-mount-recipes-and-access-tiers
**Areas discussed:** Access tiers, Mount/auth shape, Fallback parity

---

## Discussion shape (research-first, cohesive recommendations)

User selected `all` gray areas and explicitly reinforced the standing workflow preference:

- research with subagents
- compare pros/cons/tradeoffs
- include ecosystem lessons and footguns
- synthesize one coherent recommendation set
- avoid repeated user arbitration unless the issue is truly high-impact

Three parallel `gsd-advisor-researcher` subagents were dispatched:

1. `Access tiers`
2. `Mount/auth shape`
3. `Fallback parity`

The local project GSD config already matches that preference set:

- `workflow.discuss_use_subagent_research: true`
- `workflow.discuss_default_gray_areas: "all"`
- `workflow.discuss_research_all_gray_areas_default: true`
- `workflow.discuss_default_cohesive_recommendations: true`
- `workflow.discuss_interactive_menus_high_impact_only: true`
- `workflow.discuss_trust_cohesive_research_unless_high_impact: true`

No additional config mutation was needed for this phase.

---

## Access tiers

| Option | Description | Selected |
|--------|-------------|----------|
| Single route tree, host-scoped support, stricter export policy | `admin` and `support-read-only` share one `/audit` mount; support returns `{:ok, scope}` and disables exports by default | ✓ |
| Same full surface for both, no scoped support | Simpler, but weak least-privilege story and misleading “read-only” semantics | |
| Separate support route tree / curated subset | Stronger page-level least privilege, but duplicates routes/docs/tests and drifts from one-obvious-path DX | |
| Threadline-owned per-route / per-page auth vocabulary | More precise, but pushes Threadline into owning permissions and long-term auth-surface complexity | |

**Chosen direction:** One canonical `/audit` mount story with two host-owned recipes.

**Notes:** The strongest default is:

- `admin`: full mounted surface, exports enabled
- `support-read-only`: same mounted surface, `authorize_fn` returns `{:ok, scope}`, exports off by default via `exports: false`

This keeps the difference focused on visibility breadth and data egress, not on inventing a second UI shape or new Threadline roles.

---

## Mount / auth shape

| Option | Description | Selected |
|--------|-------------|----------|
| Shared assigns-shaped `authorize_fn`, optional `export_authorize_fn` only when needed | One host auth function written against `%{assigns: assigns}` works for LiveView and export fallback; `export_authorize_fn` stays advanced | ✓ |
| Separate `authorize_fn` and `export_authorize_fn` from day one | Explicit transport split, but more boilerplate and easier policy drift | |
| Pipeline-only docs bias, `authorize_fn` as optional/advanced | Familiar Phoenix shape, but under-documents the LiveView/export transport boundary and weakens fail-closed clarity | |

**Chosen direction:** Publish one canonical Phoenix recipe:

```elixir
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    repo: MyApp.Repo,
    actor_fn: &MyApp.Audit.actor_from_assigns/1,
    authorize_fn: &MyApp.Audit.authorize_threadline/1
end
```

**Notes:**

- `authorize_fn` should be taught in the shared-shape form `def authorize_threadline(%{assigns: assigns})`.
- `export_authorize_fn` remains an advanced override for HTTP-specific policy differences.
- The current split example-app `my_authorize_fn(%Plug.Conn{})` / `my_authorize_fn(%Phoenix.LiveView.Socket{})` shape should not remain the canonical recipe because it invites silent drift between transports.

---

## Fallback parity

| Option | Description | Selected |
|--------|-------------|----------|
| Core-questions parity with inline equivalents | Surface-first canonical story, with explicit inline Mix-task/API equivalents and one compact parity table | ✓ |
| Exact parity everywhere | Strong slogan, but overpromises and pressures the phase into unnecessary feature work | |
| Separate capture-only runbook only | Keeps main docs cleaner, but makes fallback harder to discover during incidents | |
| Two equal top-level tracks | Explicit, but violates the one-obvious-path rule and doubles drift risk | |

**Chosen direction:** Promise parity for core operator questions, not exact UI-to-CLI feature parity.

**Notes:**

- Inline exact task parity where tasks already exist:
  - incident drill-down -> `mix threadline.incident`
  - export -> `mix threadline.export`
  - coverage -> `mix threadline.health.coverage`
  - policy drift -> `mix threadline.policy.show`
- Inline API parity where no dedicated task exists:
  - timeline -> `Threadline.timeline/2`, `Threadline.timeline_page/2`
  - actor window -> `Threadline.actor_history/2`
  - row history / as-of -> `Threadline.history/3`, `Threadline.as_of/4`
- Add one compact parity table for fast scanning; keep the main story surface-first.

---

## Cross-area synthesis

The research outputs converged on one cohesive Phase 71 recommendation set:

- one canonical `/audit` mount topology
- one shared assigns-shaped `authorize_fn` as the default recipe
- `admin` and `support-read-only` as two host-owned policy recipes over the same mounted surface
- support exports disabled by default
- explicit capture-only equivalents for core operator questions
- no Threadline-owned roles, no second support route tree, no fake “full parity” promise

This set is internally coherent with:

- Phase 68’s surface-first / one-obvious-path rule
- Phase 69’s host-owns-auth and narrow-support-lane policy
- Phase 70’s surface-first reference-path and fallback-parity wording
- current `threadline_operator_surface/2`, `Auth.on_mount/4`, and `ExportAuthPlug` code

---

## High-impact caveat

One caveat remains genuinely high-impact:

- **Do not promise automatic support scoping everywhere unless the implementation and tests explicitly apply it on those screen/query paths.**

If Phase 71 only documents scope carriage and recommended host policy shape, the docs should say exactly that. If Phase 71 wants to promise real narrowing on specific screens or queries, planner/executor work must implement and verify that explicitly.

---

## the agent's Discretion

- Exact guide/file layout for the canonical recipe and parity table
- Exact recipe labels and snippet wording
- Exact doc-contract coverage additions needed to lock the new recipe and parity language

## Deferred Ideas

- Separate support route trees
- Threadline-owned permission vocabulary
- Page-level authorization DSL
- New features or tasks added only for parity symmetry

