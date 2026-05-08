# Stack Note — Threadline v1.19 Integration Breadth

**Scope:** stack additions and compatibility posture for broader host/framework integration patterns  
**Researched:** 2026-05-07  
**Confidence:** HIGH for current package versions and dependency posture; MEDIUM for extraction timing because that depends on adopter pressure, not just code shape

## Recommendation

v1.19 should **not add new required runtime dependencies** to `threadline`. The right move is to keep the current split:

- `threadline` core/runtime: `ecto_sql`, `postgrex`, `jason`, `nimble_csv`, `plug`, `telemetry`
- optional operator surface in-tree: `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub`
- host-only integrations: auth libs, web server choice, background jobs, mailers, etc.

The milestone should focus on **explicit compatibility contracts and adapter patterns**, not on widening the dependency graph.

## Current posture to keep

| Area | Current dep/range | Current upstream | v1.19 posture |
|---|---|---:|---|
| Core DB | `ecto_sql ~> 3.10` | 3.13.5 | Keep |
| Postgres driver | `postgrex ~> 0.17` | 0.22.1 | Keep |
| Plug boundary | `plug ~> 1.15` | 1.19.1 | Keep |
| JSON | `jason ~> 1.4` | 1.4.5 | Keep |
| CSV export | `nimble_csv ~> 1.2` | 1.3.0 | Keep |
| Telemetry | `telemetry ~> 1.2` | 1.4.1 | Keep |
| Optional Phoenix | `phoenix ~> 1.7` | 1.8.7 | Keep |
| Optional LiveView | `phoenix_live_view ~> 1.0` | 1.1.30 | Keep |
| Optional HTML | `phoenix_html ~> 4.0` | 4.3.0 | Keep |
| Optional PubSub | `phoenix_pubsub ~> 2.1` | 2.2.0 | Keep |

Why: these ranges already cover the current ecosystem while preserving the existing `mix compile --no-optional-deps` contract.

## Concrete v1.19 additions

1. Add a **documented support matrix** and mirror it in CI:
   - Plug-only / no Phoenix
   - Phoenix 1.7 + LiveView path, no Sigra
   - Phoenix 1.8 + LiveView path, no Sigra
   - Phoenix 1.8 + Sigra path

2. Treat **Sigra as a host-only adapter target**, not a library dependency:
   - keep `Threadline.Integrations.Sigra` shape-based and soft-loaded
   - do **not** add `:sigra` to `threadline` deps
   - update the example app and docs from the stale `{:sigra, "~> 0.2"}` pin to the current Sigra line; current Hex release is `1.20.0` and describes itself as for Phoenix `1.8+`

3. Keep the **optional-dependency strategy** exactly as-is for Phoenix-facing code:
   - `optional: true` in `mix.exs`
   - `Code.ensure_loaded?` gates around Phoenix/LiveView-only modules
   - retain `verify.compile_no_optional`

4. If v1.19 adds more host adapters, keep them in one of two buckets only:
   - **shape-based in-tree adapter modules** for host state extraction
   - **docs/example integrations** for host frameworks that do not justify code

## Version-compatibility implications

- `threadline` already requires Elixir `~> 1.15`, which aligns cleanly with Phoenix 1.8 docs. That means the library does **not** need to preserve older Phoenix 1.7-on-older-Elixir combinations.
- The Phoenix optional ranges are broad enough for both Phoenix 1.7 and 1.8, but **Sigra is now a Phoenix 1.8+ story**. That needs to be stated explicitly instead of implying that every auth adapter works across the whole Phoenix range.
- Server choice should stay host-owned. The library should not depend on `bandit` or `cowboy`; those belong only in example hosts or adopter apps.
- Background jobs should stay host-owned. Do not add `oban` to `threadline` for exports, saved views, or adapter plumbing.

## Extraction-readiness decision

Do **not** extract `threadline_web` in v1.19 unless one of these becomes true:

1. The Phoenix/LiveView surface needs a different release cadence than core capture/query code.
2. The support matrix becomes materially larger than the current optional-deps model can cover sanely.
3. Web-only dependencies or abstractions need to grow beyond `phoenix` + `live_view` + `html` + `pubsub`.
4. Real adopters need framework-specific behavior that would force core to carry host-specific baggage.

If extraction does become justified, the package boundary should be:

- `threadline`: unchanged core/runtime deps only
- `threadline_web`: depends on `threadline` plus `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub`

Even then, **do not** add `phoenix_ecto`, `bandit`, `cowboy`, `oban`, `sigra`, or `phoenix_live_dashboard` as package deps unless the extracted package directly uses them in shipped code. Those remain host concerns.

## What v1.19 should not add

- No new required runtime deps in `threadline`
- No `:sigra` dep in library `mix.exs`
- No `:oban`-backed exports or scheduler surface
- No web-server deps (`bandit`, `cowboy`) in core
- No auth-framework deps beyond soft adapters and docs
- No extraction just to make the package graph “cleaner” on paper

## Sources

- Current repo: [mix.exs](/Users/jon/projects/threadline/mix.exs), [examples/threadline_phoenix/mix.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/mix.exs), [lib/threadline/integrations/sigra.ex](/Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex), [lib/threadline/operator_surface/router.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/router.ex)
- Phoenix `1.8.7`: https://hex.pm/packages/phoenix
- Phoenix LiveView `1.1.30`: https://hex.pm/packages/phoenix_live_view
- Phoenix HTML `4.3.0`: https://hex.pm/packages/phoenix_html
- Phoenix PubSub `2.2.0`: https://hex.pm/packages/phoenix_pubsub
- Plug `1.19.1`: https://hex.pm/packages/plug
- Ecto SQL `3.13.5`: https://hex.pm/packages/ecto_sql
- Postgrex `0.22.1`: https://hex.pm/packages/postgrex
- Jason `1.4.5`: https://hex.pm/packages/jason
- NimbleCSV `1.3.0`: https://hex.pm/packages/nimble_csv
- Telemetry `1.4.1`: https://hex.pm/packages/telemetry
- Sigra `1.20.0`: https://hex.pm/packages/sigra
