# Phase 79: Scale Adapters - Pattern Map

**Mapped:** 2024-05-23
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` | config | N/A | `mix.exs` (existing optional deps) | exact |
| `lib/threadline/export_queue.ex` | behaviour | async/queue | `lib/threadline/storage.ex` (existing) | exact |
| `lib/threadline/storage.ex` | behaviour | file-I/O/storage | `lib/threadline/storage.ex` (existing) | exact |
| `lib/threadline/export_queue/oban.ex` | adapter/service | async/queue | `lib/threadline/export_queue/task_adapter.ex` | exact |
| `lib/threadline/storage/s3.ex` | adapter/service | file-I/O/storage | `lib/threadline/storage/local.ex` | exact |

## Pattern Assignments

### `mix.exs` (config)

**Analog:** `mix.exs`

**Optional Dependencies Pattern** (lines 48-61):
```elixir
  defp deps do
    [
      # ... existing deps ...
      {:phoenix, "~> 1.7", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      # ADD NEW DEPS HERE:
      # {:oban, "~> 2.15", optional: true},
      # {:ex_aws, "~> 2.4", optional: true},
      # {:ex_aws_s3, "~> 2.4", optional: true},
      # {:hackney, "~> 1.18", optional: true},
      # {:sweet_xml, "~> 0.7", optional: true}
    ]
  end
```

---

### `lib/threadline/export_queue/oban.ex` (adapter/service, async/queue)

**Analog:** `lib/threadline/export_queue/task_adapter.ex`

**Behaviour implementation pattern** (lines 11-17):
```elixir
  @behaviour Threadline.ExportQueue

  @doc """
  Enqueues the export job by spawning a supervised task.
  """
  @impl true
  def enqueue(job_id, opts \\ []) do
```

**Error handling pattern** (lines 20-31):
```elixir
    try do
      case Task.Supervisor.start_child(...) do
        {:ok, _pid} -> :ok
        {:error, reason} -> {:error, reason}
      end
    catch
      :exit, _reason ->
        {:error, :supervisor_not_started}
    end
```

---

### `lib/threadline/storage/s3.ex` (adapter/service, file-I/O/storage)

**Analog:** `lib/threadline/storage/local.ex`

**Behaviour implementation pattern** (lines 12-16):
```elixir
  @behaviour Threadline.Storage

  @impl true
  def put(content, opts \\ []) do
    file_id = Keyword.get_lazy(opts, :file_id, fn -> Ecto.UUID.generate() <> ".csv" end)
```

**Error handling / Tuple return pattern** (lines 19-32):
```elixir
    with :ok <- File.mkdir_p(Path.dirname(path)) do
      if is_binary(content) and File.regular?(content) do
        case File.cp(content, path) do
          :ok -> {:ok, file_id}
          {:error, reason} -> {:error, reason}
        end
      else
        # ...
      end
    end
```

---

### `lib/threadline/export_queue.ex` and `lib/threadline/storage.ex` (behaviour)

**Analog:** Themselves (already exist in codebase, need to ensure `init/1` is added per discussion)

**Behaviour Definition Pattern** (from `lib/threadline/storage.ex`, lines 10-21):
```elixir
  @type file_id :: String.t()
  @type path_or_content :: String.t() | binary()
  @type options :: keyword()

  @doc """
  Puts a file into storage.
  """
  @callback put(path_or_content(), options()) :: {:ok, file_id()} | {:error, term()}
```
*(Planner note: Ensure `init(opts)` or similar `@callback` is added to these behaviours to support the safeguard pattern from Phase 79).*

---

## Shared Patterns

### Optional Dependency Gating (Soft-deps)
**Source:** `.planning/phases/79-scale-adapters/79-DISCUSSION.md` (and observed in `lib/threadline/operator_surface.ex`)
**Apply to:** All new adapter files (`Oban` and `S3`)
```elixir
  def init(opts) do
    unless Code.ensure_loaded?(ExAws.S3) do
      raise """
      Threadline.Storage.S3 requires the :ex_aws and :ex_aws_s3 dependencies.
      Please add them to your mix.exs:
        {:ex_aws, "~> 2.0"},
        {:ex_aws_s3, "~> 2.0"}
      """
    end
    # Proceed with initialization...
  end
```
*(Pattern note: `Code.ensure_loaded?/1` is the canonical Threadline pattern for checking optional dependencies, avoiding compile-time crashes when optional libraries are missing.)*

## Metadata

**Analog search scope:** `lib/threadline/**/*.ex`, `mix.exs`
**Files scanned:** 60 files in `lib/threadline`, plus `mix.exs`
**Pattern extraction date:** 2024-05-23
