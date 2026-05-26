# Phase 98: Mounted Evidence Views On `/audit` - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/live/evidence_live.ex` | mounted read-only LiveView | URL params -> evidence APIs -> grouped view model -> HTML | `lib/threadline/operator_surface/live/policy_redaction_live.ex` + `coverage_live.ex` | strong |
| `lib/threadline/operator_surface/router.ex` | route registration | mount macro -> `/audit` sibling route | existing `/coverage` and `/policy/*` siblings in `router.ex` | exact |
| `lib/threadline/operator_surface/auth.ex` | capability boolean assignment | host callback -> `threadline_*_enabled` assigns | `assign_coverage_enabled/2` + `assign_policy_enabled/2` | exact |
| `lib/threadline/operator_surface/components/surface_header.ex` | mounted navigation badge/header | capability assign -> badge link | existing coverage/retention badge pattern | exact |
| `lib/threadline/operator_surface/unsupported.ex` | unsupported-state descriptor registry | denied capability -> fallback command copy | `coverage_unavailable`, `policy_redaction_unavailable`, `retention_unavailable` | exact |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | mounted feature test | test endpoint/router -> live route -> rendered assertions | `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | exact |
| `test/threadline/operator_surface/auth_test.exs` | auth capability unit tests | callback return -> assign boolean | existing coverage/policy capability tests | exact |
| `lib/threadline/evidence/proof.ex` or shared presenter helper | parity seam | evidence rows -> proof/view labels | existing proof-document mapping in `lib/threadline/evidence/proof.ex` | partial |

## Pattern Assignments

### `lib/threadline/operator_surface/live/evidence_live.ex`

**Primary analog:** `lib/threadline/operator_surface/live/policy_redaction_live.ex`

Use the same read-only mounted shape:

- mount assigns `:base_path` plus page-local view state
- `handle_params/3` owns URL-derived narrowing
- `render/1` branches cleanly between supported and unsupported states
- grouped status sections are rendered with stable labels rather than free-form
  JSON dumps

**Secondary analog:** `lib/threadline/operator_surface/live/coverage_live.ex`

Reuse:

- `base_path` derivation from `uri`
- `SurfaceHeader.surface_header`
- explicit unsupported-state fallback through `UnsupportedView`
- page-local validation for route params before fetching data

### `lib/threadline/operator_surface/router.ex`

**Analog:** existing sibling route registration in `threadline_operator_surface/2`

Pattern:

```elixir
live("/coverage", CoverageLive, :index)
live("/exports", ExportStatusLive, :index)
live("/policy/redaction", PolicyRedactionLive, :index)
live("/policy/retention", RetentionHistoryLive, :index)
```

Phase 98 should add one sibling route in this exact family rather than a nested
secondary mount or a separate LiveView session.

### `lib/threadline/operator_surface/auth.ex`

**Analog:** `assign_coverage_enabled/2` and `assign_policy_enabled/2`

Pattern:

- capability defaults to `false`
- host callback accepts `%{assigns: socket.assigns}` mirror
- `:ok`, `true`, and `{:ok, _scope}` map to enabled
- denial or exceptions fail closed to `false`

If evidence gets its own callback, it should follow this exact boolean-assign
shape.

### `lib/threadline/operator_surface/components/surface_header.ex`

**Analog:** coverage + retention badge links

Pattern:

```elixir
<a :if={@policy_enabled} class="surface-badge surface-badge--ok" href={"#{@base_path}/policy/retention"}>Retention</a>
```

Phase 98 should add evidence navigation as another small, capability-driven
badge/link rather than a page-local nav bar.

### `lib/threadline/operator_surface/unsupported.ex`

**Analog:** `policy_redaction_unavailable`

Pattern:

```elixir
policy_redaction_unavailable: %{
  title: "Unsupported View",
  body: "Policy redaction drift is not available for the current support lane or transport.",
  fallback_label: "Try instead",
  fallback_value: "mix threadline.policy.show"
}
```

Phase 98 should centralize its fallback copy here with the canonical CLI
fallback `mix threadline.evidence.show`.

### `test/threadline/operator_surface/live/evidence_live_test.exs`

**Primary analog:** `test/threadline/operator_surface/live/policy_redaction_live_test.exs`

Reuse this test harness shape:

- dedicated test endpoint + router
- host auth callback controlled via `Application.put_env/3`
- `live(conn, "/audit/...")` assertions for supported and unsupported states
- assertions on locked copy and grouped rendered content

**Secondary analog:** `test/threadline/operator_surface/live/coverage_live_test.exs`

Use coverage-style assertions for:

- rendered header presence
- route/query param behavior
- unsupported-state fallback command

### Shared parity seam

**Analog:** `lib/threadline/evidence/proof.ex`

Phase 97 already centralizes machine verdict mapping there. Phase 98 should not
duplicate that meaning in `EvidenceLive`. If mounted formatting needs a new
shared helper, anchor it next to `Proof` or call into `Proof` so the semantics
stay single-sourced.

## Shared Patterns

### URL-as-state, not process-local state

Source: `TimelineLive` and `CoverageLive`

Use `handle_params/3` and explicit query params for subject/mode/history
navigation so mounted evidence state is linkable and testable.

### Fail-closed capability surfaces

Source: `Auth`, `CoverageLive`, `PolicyRedactionLive`, `RetentionHistoryLive`

Capability-denied screens should render an explicit unsupported state with a CLI
fallback, never a silent omission or broad timeline fallback.

### Thin mounted layer over stable domain APIs

Source: `Mix.Tasks.Threadline.Evidence.Show` + `Threadline.Evidence.Proof`

Keep mounted evidence as a presentation layer over the Phase 96/97 proof path.

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/*`, `lib/threadline/evidence/*`, `test/threadline/operator_surface/live/*`, `test/threadline/operator_surface/auth_test.exs`
**Pattern extraction date:** 2026-05-26
