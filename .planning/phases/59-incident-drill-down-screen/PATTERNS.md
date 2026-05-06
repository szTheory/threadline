# Phase 59: Incident Drill-down Screen - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 4
**Analogs found:** 1 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/router.ex` | route | request-response | itself | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | component (LiveView) | UI rendering | None | None |
| `lib/threadline/operator_surface/components.ex` (or similar) | component | UI rendering | None | None |
| Scoped CSS inclusion mechanism | config | request-response | None | None |

## Pattern Assignments

### `lib/threadline/operator_surface/router.ex` (route, request-response)

**Analog:** `lib/threadline/operator_surface/router.ex` (Current file)

**Core pattern: Router Macro and Live Session** (lines 38-43):
```elixir
        import Phoenix.LiveView.Router, only: [live_session: 3]

        live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
          scope unquote(path), alias: Threadline.OperatorSurface do
            # Add new live route here:
            # live "/transactions/:id", TransactionLive, :show
          end
        end
```

## Shared Patterns

### Error Handling / Not Found Pattern
**Source:** `lib/threadline/investigation.ex` (lines 149-152)
**Apply to:** `TransactionLive` mount/params handling
```elixir
  def incident_bundle(transaction_id, opts \\ []) do
    case Query.audit_transaction(transaction_id, Keyword.put(opts, :preload, :action)) do
      nil ->
        {:error, :not_found}
```
*Note: The LiveView should handle `{:error, :not_found}` by assigning a not-found state and rendering the specific empty state defined in the UI-SPEC, rather than crashing or throwing a 404 error page from the host app.*

### Data Transformation Pattern
**Source:** `lib/threadline/change_diff.ex` (lines 62-67)
**Apply to:** Row-level rendering in `TransactionLive`
```elixir
  def from_audit_change(%AuditChange{} = ch, opts \\ []) do
    if Keyword.get(opts, :format) == :export_compat do
      export_compat_map(ch)
    else
      primary_map(ch, opts)
    end
  end
```
*Note: CONTEXT mentions `Threadline.change_diff/2` but the codebase implements this pattern as `Threadline.ChangeDiff.from_audit_change/2`. It will be needed to construct the JSON-friendly diffs per row.*

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md and Phoenix LiveView standard patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/threadline/operator_surface/live/transaction_live.ex` | component | UI rendering | This is the first LiveView component in the Threadline library. Standard Phoenix LiveView `stream/3` and `phx-viewport` (DOM virtualization) should be used as defined in DECISIONS.md. |
| UI Components (`components.ex`) | component | UI rendering | No existing UI components in the library. Use standard HEEx with scoped `.threadline-ui` CSS. |
| Scoped CSS Serving Mechanism | config | request-response | No existing static asset serving pipeline in Threadline. Must establish a new pattern (e.g., custom plug or controller returning CSS payload) similar to LiveDashboard. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/**/*.ex`, `**/*live*.ex`, CSS files
**Files scanned:** 5
**Pattern extraction date:** 2024-05-24