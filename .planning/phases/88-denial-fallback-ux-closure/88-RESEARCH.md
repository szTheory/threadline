# Phase 88 Research: Denial / Fallback UX Closure

**Date:** 2026-05-25
**Status:** Ready for planning

## Scope

Phase 88 closes the remaining support-lane denial and fallback UX gaps on the
single canonical `/audit` tree. The direct contract comes from `AUTH-01`,
`UX-01`, and `UX-02` in `.planning/REQUIREMENTS.md`, plus the locked product
decisions in `88-CONTEXT.md` and `88-UI-SPEC.md`.

## Current Tree Observations

### What already exists

- `TimelineLive` already hides export affordances when
  `@threadline_exports_enabled` is false.
- `ExportAuthPlug` already keeps HTTP export/download requests
  server-authoritative with plain-text `403 forbidden`.
- `UnsupportedView` already gives the right shared shell:
  `role="status"`, title/body, optional fallback, and `Back to Timeline`.
- `ExportStatusLive`, `CoverageLive`, `PolicyRedactionLive`, and
  `RetentionHistoryLive` already branch cleanly between supported and
  unsupported/denied states.
- LiveView tests already lock the key literals and route shapes for those
  surfaces.

### Where the drift is

- `lib/threadline/operator_surface/unsupported.ex` only exposes global
  constants, so unsupported surfaces cannot express per-surface copy and
  fallback rules without hard-coded strings in each LiveView.
- Fallback transports are currently pasted inline into the LiveViews, which
  makes copy drift likely across docs, tests, and future unsupported surfaces.
- Export denial currently uses a generic example fallback
  (`mix threadline.export --dry-run --table posts`) even though the context for
  Phase 88 explicitly rejects fake-example guidance as the default posture.
- The current docs already teach the single-tree support lane, but the denial
  and fallback wording is scattered and not yet locked as a deliberate product
  contract.

## Recommended Implementation Shape

### 1. Keep one shared unsupported shell, but move to descriptors

Do not fork bespoke templates per screen. Keep
`Threadline.OperatorSurface.Components.UnsupportedView` as the rendering shell,
but evolve `Threadline.OperatorSurface.Unsupported` into a descriptor/fallback
registry that can answer:

- which title/body pair applies
- whether the state is denial or unavailability
- which fallback label/value to show
- whether the fallback is exact, generic, or operational-only

This matches the current codebase shape and minimizes UI churn.

### 2. Preserve the hidden-normal-flow, explain-on-direct-route posture

- `TimelineLive` should keep hiding export affordances when export auth denies
  access.
- Direct visits to `/audit/exports` should keep rendering `Action Denied`.
- HTTP export/download endpoints must continue returning plain-text `403` via
  `ExportAuthPlug`; Phase 88 should add proof, not soften that boundary.

This is the cleanest way to satisfy `UX-01` without inventing disabled controls
 or a second support route tree.

### 3. Split exact fallback generation from generic unsupported-state cleanup

The current tree can support two layers of fallback work:

- shared per-surface descriptors for coverage, policy, retention, and export
- stronger export-specific fallback generation when the current filter state can
  be expressed truthfully as `mix threadline.export --dry-run ...`

That second part is meaningfully more specific than the generic unsupported
shell cleanup, so it should be isolated in its own plan.

### 4. Prefer exact export fallback only when the current state is safe to encode

The safest rule is:

- if export filters are present and can be mapped losslessly into the current
  CLI flag set, show the exact command
- otherwise, fall back to the generic truthful export transport hint
- never invent placeholder commands that do not reflect the current operator
  state

On the current tree, that "exact" subset is limited to `--table`, `--from`,
and `--to`. Filters such as `actor_kind`, `actor_id`, and `correlation_id`
must fall back to a generic truthful export hint unless the CLI contract is
expanded in a later phase. This should be implemented behind a helper rather
than scattered into the LiveView template.

### 5. Keep coverage/policy/retention fallbacks truthful but not overclaimed

- Coverage may stay generic unless the current tree can genuinely reproduce the
  same view shape.
- Policy redaction can stay direct with `mix threadline.policy.show`.
- Retention should stay explicitly operational rather than claiming historical
  parity.

Those rules are already encoded in `88-CONTEXT.md`; the implementation should
make them visible in one shared contract.

## Testing Guidance

### Existing tests to extend

- `test/threadline/operator_surface/live/timeline_live_test.exs`
  for hidden export affordances on support-scoped mounts.
- `test/threadline/operator_surface/live/export_status_live_test.exs`
  for denied export route behavior and fallback copy.
- `test/threadline/operator_surface/live/coverage_live_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `test/threadline/operator_surface/live/retention_history_live_test.exs`
- `test/threadline/operator_surface/controllers/export_controller_test.exs`
  for the preserved HTTP `403` export boundary.
- doc-contract tests for `guides/operator-surface.md`,
  `examples/threadline_phoenix/README.md`, and
  `guides/getting-started-saas.md`.

### Specific proof to add

- export denial shell uses locked `Action Denied` wording and a truthful
  fallback source
- generic unsupported shells use per-surface descriptors instead of copied
  strings
- support-scoped timeline still hides export affordances
- direct HTTP export requests still fail with plain-text `403`
- docs teach: hide in normal flow, explain on direct route, export HTTP remains
  authoritative, and fallback transports are named explicitly

## Plan Split Recommendation

### Plan 88-01

Shared denial/unavailability descriptor contract plus LiveView/test wiring:

- descriptor/fallback registry in `Unsupported`
- shared shell updates in `UnsupportedView` if needed
- wire `ExportStatusLive`, `CoverageLive`, `PolicyRedactionLive`, and
  `RetentionHistoryLive`
- preserve timeline hidden-affordance behavior
- add or tighten LiveView/controller tests for parity

### Plan 88-02

Export-specific exact fallback derivation and doc/contract lock:

- derive exact `mix threadline.export --dry-run ...` fallback only for the
  currently supported CLI subset (`table`, `from`, `to`)
- retain generic fallback when exact parity is not available
- align operator docs and example guidance
- update doc-contract tests so the denial/fallback posture becomes sticky

## Risks

- If exact export fallback generation is implemented inline in the LiveView
  template, copy and flag logic will drift quickly.
- If Phase 88 changes HTTP export behavior instead of merely proving it,
  it risks violating the locked `AUTH-01` boundary.
- If docs are updated without matching test locks, the repo will drift back
  toward contradictory support-lane guidance.

## Conclusion

The lowest-risk path is to keep the current shared unsupported-state
architecture, centralize per-surface descriptors, preserve hidden export
affordances plus hard HTTP `403` denial, and isolate exact export fallback
generation and doc locking into a second plan.
