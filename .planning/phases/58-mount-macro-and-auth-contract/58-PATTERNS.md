# Phase 58: mount-macro-and-auth-contract - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 5
**Analogs found:** 3 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/router.ex` | route/macro | request-response | `lib/threadline/operator_surface.ex` | partial (gating only) |
| `lib/threadline/operator_surface/auth.ex` | hook | request-response | `lib/threadline/operator_surface.ex` | partial (gating only) |
| `test/threadline/operator_surface/router_test.exs` | test | request-response | `test/threadline/plug_test.exs` | role-match |
| `test/threadline/operator_surface/auth_test.exs` | test | request-response | `test/threadline/plug_test.exs` | role-match |
| `mix.exs` | config | static | `mix.exs` | exact |

## Pattern Assignments

### `lib/threadline/operator_surface/router.ex` (route/macro, request-response)

**Analog:** `lib/threadline/operator_surface.ex`

**File-Scope Gating Pattern** (lines 1-2, 22-23):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface do
    # ...
  end
end
```

*(Note: There is no existing macro analog in the codebase that uses AST inspection via `Module.get_attribute(__CALLER__.module, :phoenix_top_scopes)`. The planner must implement this natively as described in CONTEXT D-01).*

---

### `lib/threadline/operator_surface/auth.ex` (hook, request-response)

**Analog:** `lib/threadline/telemetry.ex`

**Telemetry Dispatch Pattern** (lines 45-47):
```elixir
  def transaction_committed(_transaction, opts \\ []) do
    table_count = Keyword.get(opts, :table_count, 0)
    :telemetry.execute([:threadline, :transaction, :committed], %{table_count: table_count}, %{})
  end
```
*Apply to:* The `on_mount` hook in `auth.ex` executing `[:threadline, :operator_surface, :authorize]` with measurements and metadata.

*(Note: Like `router.ex`, this file must also be wrapped in the `if Code.ensure_loaded?(Phoenix.LiveView) do` block).*

---

### `mix.exs` (config, static)

**Analog:** `mix.exs` itself

**Groups For Modules Pattern** (lines 135-144):
```elixir
      groups_for_modules: [
        "Core API": [
          Threadline,
          Threadline.Export,
          # ...
        ],
        Integration: [
          Threadline.Plug,
```
*Apply to:* Add a new group `"Operator Surface"` (or similar) containing `Threadline.OperatorSurface` as described in CONTEXT D-05.

---

## Shared Patterns

### File-Scope Gating
**Source:** `lib/threadline/operator_surface.ex`
**Apply to:** `lib/threadline/operator_surface/router.ex` and `lib/threadline/operator_surface/auth.ex`
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ... do
    # ...
  end
end
```

## No Analog Found

Files with no close match in the codebase (planner should use CONTEXT.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/threadline/operator_surface/router.ex` | macro | auth | No existing routing `defmacro` or `__CALLER__` AST inspection in the codebase |
| `lib/threadline/operator_surface/auth.ex` | hook | auth | No existing `Phoenix.LiveView.on_mount/4` hooks in the codebase |
| `test/threadline/operator_surface/*` | test | auth | No existing LiveView or router macro tests; the doc-contract test for gating relies on `Code.ensure_loaded?` logic unique to this phase |

## Metadata

**Analog search scope:** `lib/threadline/**/*.ex`, `test/**/*.exs`
**Files scanned:** 38+
**Pattern extraction date:** 2026-05-06
