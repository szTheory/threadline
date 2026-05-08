# Feature Research — Threadline v1.19 "Integration Breadth"

**Domain:** Subsequent-milestone feature additions for a shipped Elixir audit library with an in-tree optional LiveView operator surface.
**Researched:** 2026-05-07
**Confidence:** HIGH for Phoenix/LiveView mount-auth patterns; MEDIUM for extraction-threshold heuristics because those are ecosystem pattern inferences rather than one formal standard.

## Executive framing

For OSS infrastructure libraries, "integration breadth" milestones usually do four things and stop there:

1. Add **mountable host patterns** that fit the host app's router, pipeline, and LiveView session model.
2. Add **auth adapters / resolver hooks** that keep identity and policy host-owned instead of teaching the library a user model.
3. Add **copy-pasteable runbooks and examples** so adopters can reach a secure first mount without reading the source.
4. Define **extraction-readiness criteria** for a future companion package only when version-matrix pressure and release-cadence pressure are real.

Comparable Elixir surfaces follow this shape: Phoenix LiveDashboard expects the host to protect routes with its own pipeline; LiveView expects auth checks both in the Plug pipeline and LiveView `on_mount`; Oban Web and Usher expose mount macros plus resolver/on-mount customization rather than shipping an app-owned auth model. That is the right model for Threadline v1.19 as well.

## Table Stakes

Features adopters should expect from a serious host/framework integration milestone.

| Feature | Why Expected | Complexity | Depends on shipped Threadline capability |
|---------|--------------|------------|------------------------------------------|
| **Documented mount recipes for the main host shapes**: Phoenix router scope, browser/admin pipeline, `live_session`, and capture-only/CLI-only installs | OSS operator surfaces are expected to show exactly where the mount goes and what pipeline assumptions exist | Low | `Threadline.OperatorSurface.Router`, compile-time fail-closed mount contract, current `/audit` routes, Mix-task parity |
| **LiveView auth hook pattern, not just Plug auth wording**: show how host auth runs in both pipeline and LiveView mount | Current Phoenix guidance is explicit that LiveViews need their own checks, not only router protection | Medium | Existing `:authorize_fn`, scope threading in investigation queries, mount-time telemetry |
| **Adapter contract for current-user/current-actor extraction** with one stable callback shape and examples for common host auth setups | Adopters expect to map host identity into the library without modifying core internals | Medium | Existing actor/action capture model, `Threadline.Plug`, prior host integration work, `actor_history/2` and incident views |
| **Read-only access tiers**: clear pattern for `admin`, `support-read-only`, and `unauthorized` outcomes | Comparable dashboards expose host-controlled access levels before adding richer UI features | Medium | Existing read-only surface posture, `:authorize_fn` outcome handling, policy viewers, export endpoints |
| **CSP / socket / reverse-proxy mount notes** for the operator surface | Mountable LiveView surfaces routinely need nonce, socket-path, and websocket/proxy guidance | Low | Existing optional Phoenix/LiveView surface and upgrade-path docs |
| **Runnable example updates** proving the recommended host pattern end to end | OSS adopters expect the example app to be the canonical recipe, not a toy that drifts from docs | Low | `examples/threadline_phoenix`, current admin-pipeline mount, existing doc-contract posture |
| **Install-to-first-investigation runbook**: add dep, mount, secure, verify, answer one incident | The integration milestone should reduce time-to-first-use, not just add API knobs | Low | `mix threadline.incident`, timeline/history/as-of/actor APIs, `/audit` surface, export parity |

## Differentiators

Features that would make v1.19 unusually strong without violating the current package boundary.

| Feature | Value Proposition | Complexity | Depends on shipped Threadline capability |
|---------|-------------------|------------|------------------------------------------|
| **First-party auth adapter modules for the 2-3 most likely host patterns** instead of docs-only snippets | Cuts adoption friction sharply; follows the resolver/adapter pattern used by comparable dashboards | Medium | Existing auth-agnostic callback boundary; prior Sigra/host wiring work; optional deps discipline |
| **Resolver-style integration boundary for the operator surface** that separates `resolve_user`, `resolve_access`, and optional scope narrowing | Makes Threadline easier to embed across host auth systems without teaching it app roles | Medium | Existing `:authorize_fn` and scope threading; read-only surface contract |
| **Opinionated "secure-by-default mount packs"**: copy-paste recipes for `phx.gen.auth` admin pipeline, Basic Auth emergency mount, and support-read-only mount | Adopters want proven patterns, not a menu of abstractions | Low | Existing fail-closed mount checks, telemetry auth event, example app |
| **Operator runbook parity across UI and CLI**: every recommended mount pattern names the equivalent Mix-task workflow | Preserves value for capture-only adopters and keeps the web surface from becoming mandatory | Low | `mix threadline.incident`, `mix threadline.export`, `mix threadline.health.coverage`, `mix threadline.policy.show` |
| **Extraction-readiness scorecard** for `threadline_web` | Lets maintainers defer the split until evidence exists, instead of arguing from taste | Low | Existing optional-dep packaging, in-tree surface, lifecycle docs, example app |

## Anti-Features

Features this milestone should explicitly not build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **A Threadline-owned auth system, user schema, or role model** | Breaks the library's auth-agnostic boundary and duplicates the host app's job | Keep identity extraction and authorization in adapters / callbacks / host pipelines |
| **Broad UI expansion unrelated to adoption breadth** such as saved views, workflow state, or policy editing | Adds product surface without making integration easier | Keep v1.19 focused on mount, auth, examples, and extraction criteria |
| **Forcing a `threadline_web` split now** | Premature split adds release and compatibility overhead before live-adopter evidence exists | Define readiness criteria now; extract only when thresholds are met |
| **Adding heavy required framework deps to core** | Reverses the optional-deps posture that keeps capture-only adopters lightweight | Keep Phoenix/LiveView and any auth-specific code optional and isolated |
| **Per-framework feature divergence** where one host path gets more capability than the generic path | Creates long-term support drag and confuses adopters about the real contract | Keep all adapters thin and all investigation capability behind stable core APIs |

## Category Notes

### Mount / runbook patterns

This is the primary table-stakes category. The milestone should leave behind one canonical mount recipe per supported host shape, each with:

- router snippet
- pipeline / `live_session` assumptions
- auth hook placement
- first verification command
- equivalent CLI fallback

Complexity: **Low** if docs/example only; **Medium** if the mount macro grows new integration options.

### Auth adapters

This is the highest-leverage differentiator, but only if adapters stay thin. The good pattern is:

- host resolves identity
- Threadline receives actor/access data through callbacks
- Threadline narrows queries and gatechecks the surface
- Threadline never owns user persistence or login flows

Complexity: **Medium**. Most work is contract design, examples, and test coverage, not novel runtime behavior.

### Extraction-readiness criteria

This should be treated as a feature of the milestone because it changes roadmap confidence. `threadline_web` becomes justified when most of these are true:

| Criterion | Signal | Why it matters |
|-----------|--------|----------------|
| **Version-matrix pressure** | frequent compatibility work across `phoenix`, `phoenix_live_view`, and core `threadline` | Separate release cadence starts paying for itself |
| **Dependency pressure** | web-only deps or assets evolve faster than capture/query core | Core package stays smaller and more stable if split |
| **Adopter repetition** | multiple live adopters copy the same mount/auth glue | A companion package can freeze and own that integration surface |
| **Support surface growth** | web-specific bugs/docs/changelog entries dominate milestone work | Signals the operator surface has become its own product surface |
| **Core API stability** | investigation/query APIs are stable enough that a web package can depend on them cleanly | Prevents extracting on shifting foundations |

Complexity: **Low** to define, **High** to act on. v1.19 should define the criteria, not force the extraction.

## Dependencies and sequencing

Feature dependency shape for this milestone:

```text
Existing capture/query/operator APIs
  -> mount recipes and runbooks
  -> auth adapter contract
  -> example app parity
  -> extraction-readiness scorecard
```

Recommended MVP order:

1. **Mount and runbook hardening**
2. **Auth adapter contract plus 1-2 first-party adapters**
3. **Example app parity and doc-contract coverage**
4. **`threadline_web` extraction-readiness scorecard**

Defer anything that needs a new product model, background infra, or policy mutation UI.

## Sources

- Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
- Phoenix LiveView `on_mount` docs: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1
- Phoenix LiveDashboard installation/auth pattern: https://hexdocs.pm/phoenix_live_dashboard/Phoenix.LiveDashboard.html
- Oban Web router/resolver pattern: https://hexdocs.pm/oban_web/Oban.Web.Router.html
- Oban Web resolver behavior: https://hexdocs.pm/oban_web/Oban.Web.Resolver.html
- Usher dashboard router/auth pattern: https://hexdocs.pm/usher_web/Usher.Web.Router.html
