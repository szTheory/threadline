# Phase 66: Coverage Dashboard & Mix Task Parity - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 23 (12 new, 11 modified)
**Analogs found:** 22 / 23 (one first-of-its-kind: `Coverage.OnMount` `attach_hook(:handle_info, ...)` polling driver)

## File Classification

### NEW files

| New file | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `lib/threadline/operator_surface/coverage/on_mount.ex` | LiveView on_mount hook | event-driven (timer tick → `attach_hook(:handle_info, ...)` → assign update) | `lib/threadline/operator_surface/auth.ex` | role-match (Auth uses `:handle_params`; Coverage uses `:handle_info` + `Process.send_after`) — first-of-its-kind in this repo |
| `lib/threadline/operator_surface/components/surface_header.ex` | Phoenix.Component (function component) | request-response (assigns → render) | `lib/threadline/operator_surface/style.ex` | role-match (Style is a `Phoenix.Component` rendering `~H` from assigns; SurfaceHeader is the same shape but reads `@coverage`/`@base_path`) |
| `lib/threadline/operator_surface/live/coverage_live.ex` | LiveView module | request-response + URL-param-driven CRUD-read | `lib/threadline/operator_surface/live/timeline_live.ex` | exact (sibling LV in the same `live_session :threadline`) |
| `lib/threadline/health/policy.ex` | Pure-stdlib config validator | transform (config → `:ok` / raise) | `lib/threadline/capture/redaction_policy.ex` | exact (D-32b: explicit precedent) |
| `lib/mix/tasks/threadline.health.coverage.ex` | Mix task (viewer) | request-response (argv → stdout) | `lib/mix/tasks/threadline.verify_coverage.ex` | exact (sibling task; same boot sequence) — `lib/mix/tasks/threadline.export.ex` for `OptionParser` shape |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | doc-contract test | file-I/O (read sources, assert literals) | `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` + `exports_doc_contract_test.exs` | exact (D-35: explicit "mirrors BROWSE-04 and EXPO-05") |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | LiveView integration test | request-response (mount + render assertions + interactions) | `test/threadline/operator_surface/live/timeline_live_test.exs` | exact (sibling LV test; same nested Endpoint/Router/Layouts pattern) |
| `test/threadline/operator_surface/coverage_mix_test.exs` | Mix-task integration test | request-response (`Mix.Task.rerun/2` + `capture_io` + assertions) | `test/threadline/operator_surface/exports_mix_parity_test.exs` | role-match (Mix-task harness; not byte-equality this time — parity flow only) |

### MODIFIED files

| Modified file | Role | Change Type | Analog (for the new bits) | Match Quality |
|---------------|------|-------------|---------------------------|---------------|
| `lib/threadline/health.ex` | lib API | extend `trigger_coverage/1` (`:schema` opt + parameterized SQL + 3rd bucket + `@expected_uncovered_baseline`) | `lib/threadline/continuity.ex:79-92` (parameterized `pg_namespace`-style pattern) | role-match |
| `lib/threadline/telemetry.ex` | telemetry emitter | extend `emit_health_checked/2` → `/3` (additive `expected_uncovered` measurement key) | self (additive, in-place) | exact |
| `lib/threadline/verify/coverage_policy.ex` | CI-gate policy | add one case clause for `{:expected_uncovered, _}` | self (additive, in-place) | exact |
| `lib/mix/tasks/threadline.verify_coverage.ex` | Mix task | additive `--schema=NAME` flag (default `"public"`) | `lib/mix/tasks/threadline.export.ex:39-53` (OptionParser shape) | exact |
| `lib/threadline/operator_surface/router.ex` | Router macro | append `Coverage.OnMount` to `on_mount:` list; add `live("/coverage", CoverageLive, :index)` | self (router.ex:69-76) | exact |
| `lib/threadline/operator_surface/style.ex` | CSS host component | add `--tl-header-height: 36px` + `.threadline-ui-header` + `.surface-badge*` + `.coverage-table*` rules; edit `.timeline-toolbar { top }` | self (style.ex:125-234) | exact |
| `lib/threadline/operator_surface/live/timeline_live.ex` | LiveView | one-line render edit: `<.surface_header coverage={@threadline_coverage} base_path={@base_path} />` directly under `<Threadline.OperatorSurface.Style.css />` | self (timeline_live.ex:191-194) | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | LiveView | same one-line render edit | self (transaction_live.ex:73-76) | exact |
| `lib/threadline/operator_surface/live/actor_live.ex` | LiveView | same one-line render edit | self (actor_live.ex:62-66) | exact |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | LV test | one assertion: surface header renders with expected count badge | self | exact |
| `test/threadline/operator_surface/live/actor_live_test.exs` | LV test | one assertion: surface header renders with expected count badge | self | exact |
| `test/threadline/operator_surface/transaction_live_test.exs` | LV test | one assertion: surface header renders with expected count badge | self | exact |

---

## Pattern Assignments

### `lib/threadline/operator_surface/coverage/on_mount.ex` (LiveView on_mount hook, event-driven polling driver) — FIRST-OF-ITS-KIND

**Analog:** `lib/threadline/operator_surface/auth.ex` — same FILE SHAPE (gating, module wrapper, `on_mount/4` callback, `import Phoenix.LiveView`); the `attach_hook(:handle_info, ...)` + `Process.send_after/3` polling pattern is NEW to this repo. No in-house precedent for cross-LV `:handle_info` glue. Follow Phoenix LiveDashboard's `PageLive` polling primitive (cited in CONTEXT.md "Idiomatic peer projects") and the `phx.gen.auth` `UserAuth` `on_mount` shape.

**File-scope optional-deps gate** (lines 1, 64 of `auth.ex`):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Coverage.OnMount do
    # ...
  end
end
```

**Module preamble pattern** (auth.ex:2-7):
```elixir
defmodule Threadline.OperatorSurface.Auth do
  @moduledoc """
  Authentication contract for the Threadline operator surface.
  """

  import Phoenix.LiveView
```
Coverage.OnMount mirrors: same `import Phoenix.LiveView` (gives `connected?/1` and `attach_hook/4`).

**`on_mount/4` callback signature** (auth.ex:9-44):
```elixir
def on_mount(opts, _params, _session, socket) do
  authorize_fn = Keyword.get(opts, :authorize_fn, fn _socket -> true end)
  repo = Keyword.get(opts, :repo)
  schemas = Keyword.get(opts, :schemas, %{})

  socket =
    socket
    |> Phoenix.Component.assign(:threadline_repo, repo)
    |> Phoenix.Component.assign(:threadline_schemas, schemas)

  try do
    case authorize_fn.(socket) do
      :ok ->
        emit_telemetry(:granted, socket, nil)
        {:cont, socket}
      # ...
    end
  rescue
    _ ->
      halt_unauthorized(socket, :error)
  end
end
```

**Repo resolution pattern carried forward** (timeline_live.ex:19-20 — used as the source-of-truth for repo lookup inside Coverage.OnMount):
```elixir
repo =
  socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
```
Note: `Auth` runs FIRST in the `on_mount:` chain and sets `:threadline_repo`. Coverage.OnMount can read `socket.assigns[:threadline_repo]` directly (preferred) and fall back to `Application.get_env/2` only if absent.

**Polling primitive (NEW pattern)** — based on Phoenix LiveDashboard `PageLive`:
```elixir
def on_mount(opts, _params, _session, socket) do
  interval = poll_interval!(opts, socket)

  socket =
    socket
    |> assign_initial_coverage(socket.assigns[:threadline_repo])
    |> attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)
    |> maybe_schedule_first_tick(interval)

  {:cont, socket}
end

defp maybe_schedule_first_tick(socket, interval) do
  if Phoenix.LiveView.connected?(socket) do
    ref = Process.send_after(self(), :threadline_refresh_coverage, interval)
    Phoenix.Component.assign(socket, :threadline_timer_ref, ref)
  else
    socket
  end
end

defp handle_refresh(:threadline_refresh_coverage, socket) do
  # refetch via Threadline.Health.trigger_coverage(repo: ..., schema: "public")
  # update :threadline_coverage assign; on error keep last-good and set :threadline_coverage_error
  # ALWAYS reschedule via Process.send_after/3
  {:halt, socket}  # halt so other LV handle_info clauses don't see this msg
end

defp handle_refresh(_msg, socket), do: {:cont, socket}  # passthrough
```

**Floor-validation pattern** (D-30a — raise at mount when `interval < 5_000`):
Mirror the `Mix.raise/1` posture from `verify_coverage.ex:78-79`:
```elixir
defp poll_interval!(opts, socket) do
  interval =
    socket.assigns[:threadline_coverage_poll_ms] ||
      Keyword.get(opts, :coverage_poll_ms) ||
      Application.get_env(:threadline, :coverage_poll_ms, 30_000)

  if interval < 5_000 do
    raise ArgumentError,
          "coverage poll interval must be ≥ 5_000 ms; below this, the two pg_* queries become a noisy neighbor on busy schemas (got #{interval})"
  end

  interval
end
```

**Wrapper for refetch (D-30c keep-last-good on error)** — mirror `auth.ex:19-43` `try/rescue` posture:
```elixir
defp refresh_coverage(socket) do
  repo = socket.assigns[:threadline_repo]

  try do
    coverage = Threadline.Health.trigger_coverage(repo: repo)
    snapshot = Threadline.OperatorSurface.Coverage.Snapshot.from_coverage(coverage)

    socket
    |> Phoenix.Component.assign(:threadline_coverage, snapshot)
    |> Phoenix.Component.assign(:threadline_coverage_error, nil)
  rescue
    e ->
      :telemetry.execute([:threadline, :health, :checked, :error], %{}, %{error: Exception.message(e)})

      Phoenix.Component.assign(socket, :threadline_coverage_error, Exception.message(e))
      # keep previous :threadline_coverage assign untouched
  end
end
```

---

### `lib/threadline/operator_surface/components/surface_header.ex` (Phoenix.Component, request-response)

**Analog:** `lib/threadline/operator_surface/style.ex` (file shape — same `Phoenix.Component` + `import Phoenix.Component` + `~H"""..."""`).

**File-scope gate** (style.ex:1, 255):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    # ...
  end
end
```

**Component shape** (style.ex:2-11):
```elixir
defmodule Threadline.OperatorSurface.Style do
  @moduledoc """
  Provides isolated CSS for the Threadline Operator Surface.
  """

  import Phoenix.Component

  def css(assigns) do
    ~H"""
    <style>
      .threadline-ui {
```

`SurfaceHeader.surface_header/1` mirrors: same `import Phoenix.Component`, same `def surface_header(assigns)`, same `~H` template.

**Template literals to produce (D-31a, D-35 — LOCKED)**:
```heex
<header class="threadline-ui-header">
  <span>Threadline</span>
  <%= if @coverage && @coverage.uncovered_count > 0 do %>
    <a class="surface-badge surface-badge--warn" href={"#{@base_path}/coverage"}>
      <%= @coverage.uncovered_count %> uncovered
    </a>
  <% else %>
    <a class="surface-badge surface-badge--ok" href={"#{@base_path}/coverage"}>All covered</a>
  <% end %>
</header>
```

The exact format `{n} uncovered` MUST satisfy doc-contract regex `~r/\d+ uncovered/`; the literal `"All covered"` MUST be present verbatim.

**Anchor-not-live_patch precedent** (timeline_live.ex:236-238):
```elixir
<.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"} download class="download-button">Download CSV</.link>
```
Phase 66 surface header uses plain `<a href={...}>` (D-31d) since the destination is a different LV in the session — full page navigate is correct.

---

### `lib/threadline/operator_surface/live/coverage_live.ex` (LiveView, request-response + URL-param-driven read)

**Analog:** `lib/threadline/operator_surface/live/timeline_live.ex` (sibling LV in same `live_session :threadline`).

**File-scope gate + module declaration** (timeline_live.ex:1-13):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView

    alias Threadline.Export
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.Query
```

**`mount/3` shape with repo resolution + `:base_path`** (timeline_live.ex:18-54):
```elixir
def mount(_params, _session, socket) do
  repo =
    socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()

  scope = socket.assigns[:threadline_scope]

  audited_tables =
    Threadline.Health.trigger_coverage(repo: repo)
    |> Enum.flat_map(fn
      {:covered, name} -> [name]
      _ -> []
    end)
    |> Enum.sort()

  socket =
    socket
    |> stream_configure(:changes, dom_id: fn change -> "change-#{change.id}" end)
    # ... assign base values ...
    |> assign(:base_path, nil)

  {:ok, socket}
end
```

CoverageLive mirrors: same repo resolution, same `:base_path` assign, but reads `:threadline_coverage` already populated by `Coverage.OnMount` (no own `trigger_coverage/1` call at mount).

**`handle_params/3` shape with URL parsing + form_error fallback** (timeline_live.ex:60-91):
```elixir
def handle_params(params, uri, socket) do
  uri_parsed = URI.parse(uri)
  base_path = uri_parsed.path
  socket = assign(socket, :base_path, base_path)

  if params == %{} do
    # default-window canonicalization push_patch
    {:noreply, push_patch(socket, to: "#{base_path}?#{query_string}", replace: true)}
  else
    case FilterParams.parse(params) do
      {:error, message} ->
        socket =
          socket
          |> assign(:form_error, message)
          # ... clear stream + counts ...

        {:noreply, socket}

      {:ok, filters} -> ...
    end
  end
end
```

CoverageLive mirrors: parse `?schema=NAME` param, validate via two-layer (regex + `pg_namespace` lookup), assign `:form_error` on failure (D-33a). Use `Ecto.Adapters.SQL.query!/3` parameterized lookup pattern from `continuity.ex:79-92`:
```elixir
defp public_table_exists?(repo, table_name) do
  %{rows: rows} =
    Ecto.Adapters.SQL.query!(
      repo,
      """
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'public' AND table_name = $1
      LIMIT 1
      """,
      [table_name]
    )

  rows != []
end
```
Coverage's schema validator: `SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1`.

**Render shape with `.threadline-ui` wrapper + `Style.css`** (timeline_live.ex:191-194):
```elixir
def render(assigns) do
  ~H"""
  <div class="threadline-ui">
    <Threadline.OperatorSurface.Style.css />

    <header class="timeline-toolbar">
```

CoverageLive mirrors: `<div class="threadline-ui"><Threadline.OperatorSurface.Style.css /><.surface_header coverage={@threadline_coverage} base_path={@base_path} />` followed by `<h2>Coverage — schema: {name}</h2>` + the three-bucket `.coverage-table`.

**Manual refresh handler (D-30b — cancel-and-reschedule)** — uses `Process.cancel_timer/1`. New pattern; no in-repo precedent; standard Elixir/OTP.
```elixir
def handle_event("refresh", _params, socket) do
  if ref = socket.assigns[:threadline_timer_ref] do
    Process.cancel_timer(ref)
  end

  socket = refresh_coverage(socket)
  new_ref = Process.send_after(self(), :threadline_refresh_coverage, poll_interval(socket))

  {:noreply, Phoenix.Component.assign(socket, :threadline_timer_ref, new_ref)}
end
```

**Empty/error state pattern** (timeline_live.ex:243-251, 280-283):
```elixir
<%= if @form_error do %>
  <div class="filter-error" role="alert"><%= @form_error %></div>
<% end %>

<div :if={@cursor == nil and Enum.empty?(@streams.changes.inserts)}
     class="empty-state">
  No changes match these filters in the selected window.
</div>
```
CoverageLive uses `class="filter-error"` for `"Schema '{NAME}' not found."` (D-33a / UI-SPEC line 178).

**Atom-safety carry-forward** (filter_params.ex:84):
```elixir
{String.to_existing_atom(key), value}
```
CoverageLive must NOT contain `String.to_atom\b` (Pitfall 11). Schema names are NOT atomized — they stay binary throughout.

---

### `lib/threadline/health/policy.ex` (pure-stdlib config validator, transform)

**Analog:** `lib/threadline/capture/redaction_policy.ex` — direct precedent named in CONTEXT.md D-32b and D-36.

**File shape** (redaction_policy.ex:1-22):
```elixir
defmodule Threadline.Capture.RedactionPolicy do
  @moduledoc """
  Validates trigger redaction options at codegen time (Mix / `TriggerSQL`).

  Excludes and masks are mutually exclusive per column: a column cannot appear
  in both `:exclude` and `:mask`.
  """

  @max_placeholder_length 200

  @doc "Default JSON-safe mask token baked into generated SQL."
  def default_placeholder, do: "[REDACTED]"

  @doc """
  Validates `:exclude`, `:mask`, and optional `:mask_placeholder`.

  Raises `ArgumentError` if `exclude` and `mask` intersect (message mentions both
  `"exclude"` and `"mask"` and lists an offending column).
  """
  def validate!(opts) when is_list(opts), do: validate!(Map.new(opts))

  def validate!(opts) when is_map(opts) do
    # ...
```

**Keyword-OR-map dual-form intake** (redaction_policy.ex:20-22) — Phase 66's `Health.Policy.validate!/1` mirrors EXACTLY:
```elixir
def validate!(opts) when is_list(opts), do: validate!(Map.new(opts))

def validate!(opts) when is_map(opts) do
  expected = normalize_strings(Map.get(opts, :expected_uncovered_tables, ...))
  audit_anyway = normalize_strings(Map.get(opts, :audit_anyway, ...))
  # raise on non-binary entries, raise on duplicates
  :ok
end
```

**Error-message pattern** (redaction_policy.ex:31-34):
```elixir
raise ArgumentError,
      "exclude and mask overlap on columns: #{cols}. " <>
        "Column #{inspect(sample)} cannot be both excluded and masked."
```
Health.Policy mirrors: `"...:expected_uncovered_tables must contain only binary strings, got: #{inspect(other)}"`.

**No file-scope optional-deps gate** — pure stdlib (D-36).

---

### `lib/mix/tasks/threadline.health.coverage.ex` (Mix task viewer, request-response)

**Analog:** `lib/mix/tasks/threadline.verify_coverage.ex` (same boot sequence, same `resolve_repo!`/`ensure_repo_started!` shape) + `lib/mix/tasks/threadline.export.ex` (for `OptionParser` shape with `--json` boolean + `--schema` string).

**`@shortdoc` + `@moduledoc` + `use Mix.Task`** (verify_coverage.ex:1-26):
```elixir
defmodule Mix.Tasks.Threadline.VerifyCoverage do
  @shortdoc "Checks configured audited tables have Threadline capture triggers (uses Health.trigger_coverage/1)"

  @moduledoc """
  Verifies that tables listed in application config have Threadline audit
  triggers installed, using the same catalog queries as `Threadline.Health.trigger_coverage/1`.

  ## Configuration
  ...

  ## Usage

      mix threadline.verify_coverage

  Prints a `TABLE` / `STATUS` report to stdout, then a line containing `summary:`
  with counts. Exits with status **1** if any expected table is missing or
  uncovered; exits **0** when all expected tables are covered.

  Table names in output are public-schema metadata only (same scope as `Health`).
  """

  use Mix.Task
```

Health.Coverage task mirrors: `@shortdoc "Show trigger coverage for audited tables"` + `## Usage` section listing `mix threadline.health.coverage`, `mix threadline.health.coverage --json`, `mix threadline.health.coverage --schema=NAME` literally (D-35 pins these).

**Boot sequence (REUSE VERBATIM)** — verify_coverage.ex:30-50, 52-70:
```elixir
@impl Mix.Task
def run(_args) do
  Mix.Task.run("app.config", [])
  {:ok, _} = Application.ensure_all_started(:ssl)
  {:ok, _} = Application.ensure_all_started(:postgrex)
  {:ok, _} = Application.ensure_all_started(:ecto_sql)

  repo = resolve_repo!()
  ensure_repo_started!(repo)
  expected = resolve_expected_tables!()

  coverage = Threadline.Health.trigger_coverage(repo: repo)
  violations = CoveragePolicy.violations(coverage, expected)
  counts = CoveragePolicy.summary_counts(coverage, expected)

  print_report(expected, coverage, counts)

  if violations != [] do
    exit({:shutdown, 1})
  end
end

defp resolve_repo! do
  case Application.get_env(:threadline, :ecto_repos, []) do
    [] ->
      Mix.raise(
        "Threadline: set :ecto_repos in config — no Ecto repository is configured to run verify_coverage."
      )

    [repo | _] ->
      repo
  end
end

defp ensure_repo_started!(repo) do
  case repo.start_link() do
    {:ok, _} -> :ok
    {:error, {:already_started, _}} -> :ok
    {:error, reason} -> Mix.raise("Could not start #{inspect(repo)}: #{inspect(reason)}")
  end
end
```

Health.Coverage mirrors **except**:
1. `def run(argv)` (not `_args`) — needs argv for `OptionParser`.
2. Add `OptionParser.parse(argv, strict: [json: :boolean, schema: :string])` — see export.ex:39-53 below.
3. Does NOT call `exit({:shutdown, 1})` — viewer, not gate.

**OptionParser pattern** (export.ex:38-53):
```elixir
def run(argv) do
  {opts, _, _} =
    OptionParser.parse(argv,
      strict: [
        output: :string,
        format: :string,
        json_format: :string,
        max_rows: :integer,
        dry_run: :boolean,
        table: :string,
        from: :string,
        to: :string,
        actor_json: :string
      ],
      aliases: [o: :output]
    )
```

Health.Coverage uses `strict: [json: :boolean, schema: :string]` — short, two-flag form.

**Schema validation at the EDGE (D-33a)** — same two-layer regex + `pg_namespace` lookup as the LV; reuse a shared helper or local function. Use the parameterized SQL pattern from `continuity.ex:79-92`. On failure: `Mix.raise("threadline.health.coverage: schema '#{name}' not found.")`.

**Table-output pattern** (verify_coverage.ex:118-152):
```elixir
defp print_report(expected, coverage, counts) do
  by_table = Map.new(coverage, fn {st, name} -> {name, st} end)

  rows =
    expected
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.map(fn table ->
      status =
        case Map.fetch(by_table, table) do
          {:ok, :covered} -> "covered"
          {:ok, :uncovered} -> "uncovered"
          :error -> "missing"
        end

      {table, status}
    end)

  table_w = max(5, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 5 end))
  table_w = max(table_w, byte_size("TABLE"))

  header = String.pad_trailing("TABLE", table_w) <> "  STATUS"
  rule = String.duplicate("-", String.length(header))

  Mix.shell().info(header)
  Mix.shell().info(rule)

  for {t, st} <- rows do
    Mix.shell().info(String.pad_trailing(t, table_w) <> "  " <> st)
  end

  Mix.shell().info(
    "summary: #{counts.covered}/#{counts.expected} expected tables covered (#{counts.violated} violated)"
  )
end
```

Health.Coverage mirrors but adds a third column `SOURCE` (populated only on `expected` rows: `"baseline"` or `"config"`) and emits the LOCKED footer literal `"Coverage: N covered, M uncovered, K expected uncovered"` (D-34, UI-SPEC line 244). Status literals MUST be `"covered"` / `"uncovered"` / `"expected"` (D-32d, D-35 — pinned by doc-contract).

**JSON output pattern** — `Jason.encode!/1` is a HARD dep. Schema:
```elixir
%{
  "schema" => schema,
  "covered" => covered_list,
  "uncovered" => uncovered_list,
  "expected_uncovered" => [%{"table" => "schema_migrations", "source" => "baseline"}, ...]
}
|> Jason.encode!()
|> IO.puts()
```
Top-level keys (sorted): `["covered", "expected_uncovered", "schema", "uncovered"]`. Entry keys (sorted): `["source", "table"]`. `source ∈ {"baseline", "config"}` — pinned by D-35.

**No optional-deps gate** — pure-stdlib + Jason (HARD dep). Required for capture-only adopters per D-36.

**Atom-safety carry-forward (Pitfall 11)** — refute `String.to_atom\b` in source.

---

### `test/threadline/operator_surface/coverage_doc_contract_test.exs` (doc-contract test, file-I/O)

**Analog:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` + `test/threadline/operator_surface/exports_doc_contract_test.exs`. D-35 names both as "mirrors BROWSE-04 and EXPO-05 patterns."

**Imports + module attribute paths** (timeline_browse_doc_contract_test.exs:1-9):
```elixir
defmodule Threadline.OperatorSurface.TimelineBrowseDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @router_path "lib/threadline/operator_surface/router.ex"
  @lv_path "lib/threadline/operator_surface/live/timeline_live.ex"
  @query_path "lib/threadline/query.ex"
  @transaction_lv_path "lib/threadline/operator_surface/live/transaction_live.ex"
  @actor_lv_path "lib/threadline/operator_surface/live/actor_live.ex"
```

CoverageDocContractTest mirrors: declare `@router_path`, `@coverage_lv_path`, `@on_mount_path`, `@surface_header_path`, `@health_path`, `@mix_task_path`.

**Route literal assertion** (timeline_browse_doc_contract_test.exs:13-18):
```elixir
test "router declares the timeline browse live route at the surface root" do
  router_src = File.read!(@router_path)

  assert String.contains?(router_src, ~s|live("/", TimelineLive, :index)|),
         "expected #{@router_path} to declare `live(\"/\", TimelineLive, :index)` inside the live_session :threadline scope"
end
```
Phase 66 mirrors with the LOCKED literal `live("/coverage", CoverageLive, :index)` (D-35).

**Multiple literal assertions in `describe` block** (exports_doc_contract_test.exs:15-35):
```elixir
describe "button labels (D-22, D-26)" do
  test "TimelineLive renders the three download button labels verbatim" do
    src = File.read!(@lv_path)
    assert String.contains?(src, "Download CSV")
    assert String.contains?(src, "Download JSON")
    assert String.contains?(src, "Download NDJSON")
  end
```
Phase 66 mirrors for: `"All covered"`, `~r/\d+ uncovered/` (regex via `=~`), `"covered"`, `"uncovered"`, `"expected"`, `"baseline"`, `"config"`, `"Coverage — schema:"`.

**Atom-safety refute** (exports_doc_contract_test.exs:251-269):
```elixir
test "ExportController source does NOT call String.to_atom (atom-leak vector closed)" do
  src = File.read!(@controller_path)
  refute src =~ ~r/String\.to_atom\b/
end
```
Phase 66 carries forward for `coverage_live.ex` and the Mix task.

**File-scope gate refute** (timeline_browse_doc_contract_test.exs:94-100):
```elixir
test "timeline live module is wrapped in file-scope Code.ensure_loaded? gate" do
  live_src = File.read!(@lv_path)
  first_line = live_src |> String.split("\n") |> hd()

  assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do",
         "expected line 1 of #{@lv_path} to be the Sentry-idiom file-scope gate, got: #{inspect(first_line)}"
end
```
Phase 66 mirrors for `coverage_live.ex`, `surface_header.ex`, `on_mount.ex` (all `Phoenix.LiveView`-gated).

**Hardcoded baseline assertion (NEW pattern)** — assert the source literal `@expected_uncovered_baseline ~w(schema_migrations)`:
```elixir
test "Threadline.Health hardcoded baseline is exactly schema_migrations (no Oban hardcodes)" do
  src = File.read!(@health_path)

  assert String.contains?(src, ~s|@expected_uncovered_baseline ~w(schema_migrations)|),
         "expected #{@health_path} to declare `@expected_uncovered_baseline ~w(schema_migrations)` per D-32a — growing this list is a CI-visible decision"
end
```

**Mix-task `--json` runtime assertion (NEW)** — `ExUnit.CaptureIO.capture_io/1` + `Mix.Task.rerun/2` + `Jason.decode!/1`:
```elixir
test "mix threadline.health.coverage --json emits the locked schema" do
  output = ExUnit.CaptureIO.capture_io(fn ->
    Mix.Task.rerun("threadline.health.coverage", ["--json"])
  end)

  parsed = Jason.decode!(output)
  assert parsed |> Map.keys() |> Enum.sort() == ["covered", "expected_uncovered", "schema", "uncovered"]

  for entry <- parsed["expected_uncovered"] do
    assert entry |> Map.keys() |> Enum.sort() == ["source", "table"]
    assert entry["source"] in ["baseline", "config"]
  end
end
```
Note `Mix.Task.rerun/2` (not `run/2`) — same single-OS-process gotcha used in Phase 65 (`exports_mix_parity_test.exs:60`).

---

### `test/threadline/operator_surface/live/coverage_live_test.exs` (LV integration test)

**Analog:** `test/threadline/operator_surface/live/timeline_live_test.exs` (sibling LV).

**Nested test-Endpoint/Router/Layouts shape** (timeline_live_test.exs:1-58):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.TimelineLiveTest.Layouts do
    use Phoenix.Component

    def root(assigns) do
      ~H"""
      <html>
        <head><title>Test</title></head>
        <body><%= @inner_content %></body>
      </html>
      """
    end
    # ...
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.Router do
    use Phoenix.Router
    import Phoenix.LiveView.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html"])
      plug(:fetch_session)
      plug(:fetch_live_flash)

      plug(:put_root_layout,
        html: {Threadline.OperatorSurface.TimelineLiveTest.Layouts, :root}
      )
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.TimelineLiveTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline

    @session_options [
      store: :cookie,
      key: "_threadline_key",
      signing_salt: "v8q+QWvj"
    ]

    plug(Plug.Session, @session_options)
    plug(:fetch_session)
    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
    plug(Plug.MethodOverride)
    plug(Plug.Head)
    plug(Threadline.OperatorSurface.TimelineLiveTest.Router)
  end
```

CoverageLiveTest mirrors EXACTLY (rename `TimelineLiveTest` → `CoverageLiveTest` in module names; reuse `threadline_operator_surface("/audit")` macro mount).

**setup_all + setup pattern** (timeline_live_test.exs:111-124):
```elixir
setup_all do
  Application.put_env(:threadline, Threadline.OperatorSurface.TimelineLiveTest.Endpoint,
    secret_key_base: "x" |> String.duplicate(64),
    live_view: [signing_salt: "x" |> String.duplicate(8)],
    render_errors: [view: Threadline.OperatorSurface.TimelineLiveTest.Layouts]
  )

  start_supervised!(@endpoint)
  :ok
end

setup do
  {:ok, conn: Phoenix.ConnTest.build_conn()}
end
```

**Mount + assertion idiom** (timeline_live_test.exs:132-137):
```elixir
defp mount_audit(conn, path \\ "/audit") do
  case live(conn, path) do
    {:ok, _lv, _html} = ok -> ok
    {:error, {:live_redirect, %{to: redirect_path}}} -> live(conn, redirect_path)
  end
end
```

CoverageLive does NOT push_patch on bare `/audit/coverage` (no default-window canonicalization needed), so a plain `Phoenix.LiveViewTest.live(conn, "/audit/coverage")` works.

**Test cases to write (per CONTEXT.md `<canonical_refs>` "Recommended additional integration test")**:
1. mount renders three buckets (covered / uncovered / expected with literal badges).
2. manual "Refresh" click cancels-and-reschedules timer (`render_click(view, "refresh")` → assert new `:threadline_timer_ref`).
3. `?schema=NAME` validation: bad regex → `:form_error` rendered with `"Schema '...' not found."`.
4. `?schema=NAME` validation: unknown schema → same `:form_error`.
5. surface header on three other LVs (Timeline / Transaction / Actor) renders the badge text matching count.

---

### `test/threadline/operator_surface/coverage_mix_test.exs` (Mix-task integration test)

**Analog:** `test/threadline/operator_surface/exports_mix_parity_test.exs`.

**`Mix.Task.reenable/1` setup** (exports_mix_parity_test.exs:51-63):
```elixir
setup do
  @repo.delete_all(AuditChange)
  @repo.delete_all(AuditTransaction)

  if Code.ensure_loaded?(Threadline.Semantics.AuditAction) do
    @repo.delete_all(Threadline.Semantics.AuditAction)
  end

  # Re-enable the Mix task so it can be invoked again in each test case.
  Mix.Task.reenable("threadline.export")

  {:ok, conn: build_conn(), tmp_dir: System.tmp_dir!()}
end
```

CoverageMixTest mirrors: `Mix.Task.reenable("threadline.health.coverage")` in setup. Phase 66 is NOT byte-equality (no controller surface for the Mix task — the LV is its parity surface). Test cases:
1. default table format renders three sections + footer literal.
2. `--json` output decodes to the locked schema (top-level keys, entry keys, source values).
3. `--schema=tenant_42` round-trips through validation (success path).
4. `--schema=invalid;NAME` → `Mix.raise/1` (regex fail).
5. `--schema=nonexistent` → `Mix.raise/1` (catalog fail).

**`capture_io` pattern** (exports_mix_parity_test.exs:74-87):
```elixir
capture_io(fn ->
  Mix.Tasks.Threadline.Export.run([
    "--format",
    "csv",
    "--output",
    tmp_path,
    # ...
  ])
end)
```

CoverageMixTest mirrors: `capture_io(fn -> Mix.Tasks.Threadline.Health.Coverage.run(["--json"]) end)` returns the JSON output as a string.

---

### `lib/threadline/health.ex` (lib API extension)

**Analog:** `lib/threadline/health.ex` (self — additive edit) + `lib/threadline/continuity.ex:79-92` for the parameterized `pg_namespace` query shape.

**Module attribute baseline (NEW, D-32a)** — add at top of module:
```elixir
@audit_tables ~w(audit_transactions audit_changes audit_actions)
@expected_uncovered_baseline ~w(schema_migrations)
```

**Updated `@doc` for `:schema` opt** (D-33c) — extend the existing `## Options` block (health.ex:20-22):
```elixir
@doc """
Returns a list of tagged tuples indicating trigger coverage for all user
tables in the given schema (default `"public"`).

...

## Options

- `:repo` — required `Ecto.Repo` module
- `:schema` — optional schema name string (default `"public"`). Programmatic callers
  are responsible for sanitizing or trusting their own input — this function does
  NOT validate `:schema` against `pg_namespace`. Surfaces that take untrusted input
  (LV / Mix task) MUST validate at the edge.

Returns `[{:covered | :uncovered | :expected_uncovered, table_name}]`.
"""
```

**Parameterized query pattern (NEW)** — replace existing `'public'` literals (health.ex:55-71) with `$1` binds. The `fetch_threadline_covered_tables/1` query MUST also gain a `pg_namespace` join (per RESEARCH §"three observations load-bearing for Phase 66"):
```elixir
defp fetch_all_user_tables(repo, schema) do
  sql = "SELECT tablename FROM pg_tables WHERE schemaname = $1"
  %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [schema])
  List.flatten(rows)
end

defp fetch_threadline_covered_tables(repo, schema) do
  sql = """
  SELECT DISTINCT c.relname
  FROM pg_trigger t
  JOIN pg_class c ON t.tgrelid = c.oid
  JOIN pg_namespace n ON c.relnamespace = n.oid
  WHERE t.tgname LIKE 'threadline_audit_%' AND n.nspname = $1
  """

  %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [schema])
  List.flatten(rows)
end
```

**Three-bucket result computation (NEW, D-32)** — replace the `Enum.map/2` branch in `trigger_coverage/1` (health.ex:37-46):
```elixir
expected_set =
  MapSet.new(@expected_uncovered_baseline)
  |> MapSet.union(MapSet.new(configured_expected))
  |> MapSet.difference(MapSet.new(audit_anyway))

result =
  all_tables
  |> Enum.reject(&(&1 in @audit_tables))
  |> Enum.map(fn table ->
    cond do
      MapSet.member?(expected_set, table) -> {:expected_uncovered, table}
      MapSet.member?(covered_set, table) -> {:covered, table}
      true -> {:uncovered, table}
    end
  end)
```

**Telemetry call site update (D-32e)** — health.ex:48-50 becomes:
```elixir
covered_count = Enum.count(result, &match?({:covered, _}, &1))
uncovered_count = Enum.count(result, &match?({:uncovered, _}, &1))
expected_uncovered_count = Enum.count(result, &match?({:expected_uncovered, _}, &1))
Threadline.Telemetry.emit_health_checked(covered_count, uncovered_count, expected_uncovered_count)
```

---

### `lib/threadline/telemetry.ex` (additive `/3` arity)

**Analog:** `lib/threadline/telemetry.ex:60-66` (self).

Existing (telemetry.ex:60-66):
```elixir
@doc false
def emit_health_checked(covered, uncovered) do
  :telemetry.execute(
    [:threadline, :health, :checked],
    %{covered: covered, uncovered: uncovered},
    %{}
  )
end
```

Phase 66 (replace direct, since exactly ONE in-tree caller per RESEARCH):
```elixir
@doc false
def emit_health_checked(covered, uncovered, expected_uncovered) do
  :telemetry.execute(
    [:threadline, :health, :checked],
    %{covered: covered, uncovered: uncovered, expected_uncovered: expected_uncovered},
    %{}
  )
end
```

Update `@moduledoc` event-shape paragraph (telemetry.ex:16-17): note the `expected_uncovered` measurement is additive.

---

### `lib/threadline/verify/coverage_policy.ex` (additive case clause)

**Analog:** `lib/threadline/verify/coverage_policy.ex:23-37` (self).

Existing (coverage_policy.ex:23-37):
```elixir
def violations(coverage, expected_tables)
    when is_list(coverage) and is_list(expected_tables) do
  by_table = Map.new(coverage, fn {status, name} -> {name, status} end)

  expected_tables
  |> Enum.uniq()
  |> Enum.flat_map(fn table ->
    case Map.fetch(by_table, table) do
      :error -> [{:missing, table}]
      {:ok, :uncovered} -> [{:uncovered, table}]
      {:ok, :covered} -> []
    end
  end)
  |> Enum.sort_by(fn {kind, name} -> {violation_rank(kind), name} end)
end
```

Phase 66 adds ONE case clause (per D-32f) — `:expected_uncovered` is treated as covered-equivalent for the verify gate when the table is NOT in the adopter's `:expected_tables`:
```elixir
case Map.fetch(by_table, table) do
  :error -> [{:missing, table}]
  {:ok, :uncovered} -> [{:uncovered, table}]
  {:ok, :covered} -> []
  {:ok, :expected_uncovered} -> []  # NEW: bucket exists, intentional non-audit; not a violation
end
```

---

### `lib/mix/tasks/threadline.verify_coverage.ex` (additive `--schema=NAME` flag)

**Analog:** `lib/mix/tasks/threadline.export.ex:38-53` (OptionParser shape).

Existing `def run(_args)` (verify_coverage.ex:31) becomes `def run(argv)`:
```elixir
def run(argv) do
  {opts, _, _} =
    OptionParser.parse(argv, strict: [schema: :string])

  schema = opts[:schema] || "public"
  validate_schema!(schema)  # same regex + pg_namespace lookup as Health.Coverage Mix task

  Mix.Task.run("app.config", [])
  # ... existing boot sequence ...

  coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
  # ... existing report path ...
end
```
The schema validator helper can be shared between the two Mix tasks (Claude's Discretion: planner picks file location — recommend `lib/mix/tasks/threadline/schema_validator.ex` or inline-private in each task; the redaction precedent (`lib/threadline/capture/redaction_policy.ex`) suggests sibling-module is the project preference).

---

### `lib/threadline/operator_surface/router.ex` (append on_mount + add live route)

**Analog:** `lib/threadline/operator_surface/router.ex:67-76` (self).

Existing (router.ex:67-76):
```elixir
import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]

live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/", TimelineLive, :index)
    live("/transactions/:id", TransactionLive, :show)
    live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
    live("/actors/:kind/:id", ActorLive, :show)
  end
end
```

Phase 66:
```elixir
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, unquote(opts)},
    {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
  ] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/", TimelineLive, :index)
    live("/coverage", CoverageLive, :index)
    live("/transactions/:id", TransactionLive, :show)
    live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
    live("/actors/:kind/:id", ActorLive, :show)
  end
end
```
Order of `on_mount:` list MATTERS: `Auth` runs first (sets `:threadline_repo`), then `Coverage.OnMount` (reads `:threadline_repo` to query).

---

### `lib/threadline/operator_surface/style.ex` (CSS rule additions)

**Analog:** `lib/threadline/operator_surface/style.ex:125-234` (self).

**Existing `.timeline-toolbar`** (style.ex:125-132) gets ONE-LINE EDIT (`top: 0` → `top: var(--tl-header-height, 36px)`):
```elixir
.threadline-ui .timeline-toolbar {
  position: sticky;
  top: var(--tl-header-height, 36px);  # CHANGED FROM: top: 0;
  background: var(--tl-color-main);
  border-bottom: 1px solid var(--tl-color-secondary);
  padding: var(--tl-spacing-md);
  z-index: 1;
}
```

**Existing CSS-variable block to extend** (style.ex:12-32) — add `--tl-header-height: 36px` inside `.threadline-ui` declaration block.

**Existing amber palette to MIRROR** (style.ex:226-234, the `.truncation-banner.warning` rule) — Phase 66's `.surface-badge--warn` reuses the same `#FEF3C7 / #92400E / #F59E0B` triplet for visual continuity (UI-SPEC §"Color rationale"):
```elixir
.threadline-ui .truncation-banner.warning {
  background: #FEF3C7;            /* amber-50 */
  color: #92400E;                 /* amber-800 */
  border-left: 3px solid #F59E0B; /* amber-500 */
}
```

New rules to add (UI-SPEC §"CSS New Rules Summary", lines 305-323):
```css
.threadline-ui-header             { /* sticky top:0 z-index:2 height: 36px ... */ }
.threadline-ui .surface-badge     { /* pill base: 12px font, 12px border-radius, 4px 8px padding */ }
.threadline-ui .surface-badge--ok { /* text-muted, transparent bg, secondary border */ }
.threadline-ui .surface-badge--warn { /* amber palette — copy literals from .truncation-banner.warning */ }
.threadline-ui .coverage-table    { /* width 100%, border-collapse: collapse */ }
.threadline-ui .coverage-table th { /* label header */ }
.threadline-ui .coverage-table td { /* cell padding sm md */ }
.threadline-ui .coverage-row--covered    { /* transparent bg */ }
.threadline-ui .coverage-row--uncovered  { /* rgba(239,68,68,0.06) destructive tint */ }
.threadline-ui .coverage-row--expected   { /* secondary bg, muted text */ }
```

---

### `lib/threadline/operator_surface/live/timeline_live.ex` (one-line render edit)

**Analog:** timeline_live.ex:191-194 (self).

Existing render opening:
```elixir
def render(assigns) do
  ~H"""
  <div class="threadline-ui">
    <Threadline.OperatorSurface.Style.css />

    <header class="timeline-toolbar">
```

Phase 66:
```elixir
def render(assigns) do
  ~H"""
  <div class="threadline-ui">
    <Threadline.OperatorSurface.Style.css />
    <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
      coverage={@threadline_coverage}
      base_path={@base_path}
    />

    <header class="timeline-toolbar">
```

The `:threadline_coverage` assign is sourced by `Coverage.OnMount` (the `live_session :threadline` `on_mount` chain), so the assign is already populated at render time. NO change to `mount/3` or any other function in `timeline_live.ex`. The datalist call at line 30 stays bare per D-33b.

---

### `lib/threadline/operator_surface/live/transaction_live.ex` + `actor_live.ex` (one-line render edits each)

**Analogs:** transaction_live.ex:73-76 / actor_live.ex:62-66 (self).

Existing TransactionLive render opening (transaction_live.ex:73-76):
```elixir
def render(assigns) do
  ~H"""
  <div class="threadline-ui">
    <Threadline.OperatorSurface.Style.css />
```

Phase 66 (same one-line edit for both files):
```elixir
def render(assigns) do
  ~H"""
  <div class="threadline-ui">
    <Threadline.OperatorSurface.Style.css />
    <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
      coverage={@threadline_coverage}
      base_path={@base_path}
    />
```

ActorLive uses the same edit at the same place (actor_live.ex:64-65). RowHistoryComponent inherits via TransactionLive's render — NO separate edit needed (per CONTEXT.md `<deferred>` "Surface header on RowHistoryComponent specifically — inherits via TransactionLive's render automatically").

---

## Shared Patterns

### File-scope optional-deps gate (Phoenix.LiveView)
**Source:** `lib/threadline/operator_surface/auth.ex:1, 64` (paired with `lib/threadline/operator_surface/style.ex:1, 255`, `timeline_live.ex:1, 350`).
**Apply to:** `coverage/on_mount.ex`, `components/surface_header.ex`, `live/coverage_live.ex`.
**Apply NOT to:** `lib/threadline/health/policy.ex`, `lib/mix/tasks/threadline.health.coverage.ex` (pure-stdlib; required for capture-only adopters per D-36).
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.<X> do
    # ...
  end
end
```
Doc-contract test pins `first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do"` (timeline_browse_doc_contract_test.exs:94-100 pattern).

### Repo resolution
**Source:** `lib/threadline/operator_surface/live/timeline_live.ex:19-20`.
**Apply to:** `coverage/on_mount.ex` (initial coverage fetch), `coverage_live.ex` (mount), schema validator helpers in both Mix tasks.
```elixir
repo =
  socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
```
Mix tasks use `verify_coverage.ex:52-62`'s `resolve_repo!/0` helper instead.

### `.threadline-ui` wrapper + `<Style.css />` first
**Source:** `lib/threadline/operator_surface/live/timeline_live.ex:191-194`, transaction_live.ex:74-76, actor_live.ex:64-65.
**Apply to:** every LV render block. CoverageLive opens with this; the three sibling LVs already do this and gain `<.surface_header />` directly under `<Style.css />`.
```heex
<div class="threadline-ui">
  <Threadline.OperatorSurface.Style.css />
  <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
    coverage={@threadline_coverage}
    base_path={@base_path}
  />
  <!-- page-specific content -->
</div>
```

### Atom-safety (`String.to_existing_atom` only; refute `String.to_atom\b`)
**Source:** `lib/threadline/operator_surface/exports/filter_params.ex:84` (uses `String.to_existing_atom/1`); `test/threadline/operator_surface/exports_doc_contract_test.exs:251-269` (refute pattern).
**Apply to:** Schema name parsing in `coverage_live.ex` and the new Mix task. Schema names stay as binaries — never atomized. Doc-contract test refutes `String.to_atom\b` on both source files (Pitfall 11 carry-forward).

### Parameterized SQL with `pg_namespace` lookup
**Source:** `lib/threadline/continuity.ex:79-92` (parameterized `information_schema.tables` lookup).
**Apply to:** `health.ex` (both internal queries — `pg_tables` and `pg_trigger`-`pg_class`-`pg_namespace`); both Mix tasks' schema validator helper; CoverageLive's schema validator (D-33a).
```elixir
%{rows: rows} =
  Ecto.Adapters.SQL.query!(
    repo,
    """
    SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1
    """,
    [schema_name]
  )

rows != []
```

### Two-layer schema validation (regex first, catalog second)
**Source:** D-33a (no in-house precedent — first use); regex pattern is locked: `~r/\A[a-z_][a-z0-9_]{0,62}\z/`.
**Apply to:** CoverageLive `handle_params/3` schema validation; both Mix tasks' schema validation. Validate at the EDGE only — `Threadline.Health.trigger_coverage/1` does NOT validate `:schema` (per D-33a).

### Mix-task boot sequence
**Source:** `lib/mix/tasks/threadline.verify_coverage.ex:30-69`.
**Apply to:** new `Mix.Tasks.Threadline.Health.Coverage`. Reuse verbatim:
```elixir
Mix.Task.run("app.config", [])
{:ok, _} = Application.ensure_all_started(:ssl)
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

repo = resolve_repo!()
ensure_repo_started!(repo)
```
Plus `resolve_repo!/0` and `ensure_repo_started!/1` private helpers (verify_coverage.ex:52-69).

### `Mix.Task.reenable/1` in test setup
**Source:** `test/threadline/operator_surface/exports_mix_parity_test.exs:60`.
**Apply to:** new `coverage_mix_test.exs` setup block. `Mix.Task.run/2` no-ops on second call within the same OS process; `Mix.Task.reenable/1` lets each test case re-invoke.

### Doc-contract literal pinning
**Source:** `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:13-18` + `exports_doc_contract_test.exs:15-69`.
**Apply to:** new `coverage_doc_contract_test.exs`. Pure source-reading via `File.read!/1` + `String.contains?/2` + `=~ ~r/.../`. No DB, no LV bootup (except for the `--json` schema runtime assertion which does need `Mix.Task.rerun/2` + `Jason.decode!/1`).

### Telemetry-event-name literal in metadata
**Source:** `lib/threadline/operator_surface/auth.ex:57-61` (existing `[:threadline, :operator_surface, :authorize]`).
**Apply to:** New error event `[:threadline, :health, :checked, :error]` per D-30c (raised inside Coverage.OnMount's `try/rescue`).

### Config namespacing: `config :threadline, :health, ...`
**Source:** existing precedent — `config :threadline, :verify_coverage, expected_tables: [...]` (cited in verify_coverage.ex:73-113).
**Apply to:** Phase 66's three new keys live under `:health`:
```elixir
config :threadline, :health,
  expected_uncovered_tables: ["oban_jobs", "oban_peers", "oban_producers"],
  audit_anyway: []
```
And separately (interval is global, NOT under `:health`, per D-30a):
```elixir
config :threadline, :coverage_poll_ms, 30_000
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/threadline/operator_surface/coverage/on_mount.ex` | LV on_mount hook | event-driven (timer tick → `attach_hook(:handle_info, ...)` → assign update) | The `attach_hook(:handle_info, ...)` cross-LV polling pattern is FIRST-OF-ITS-KIND in this repo. `Threadline.OperatorSurface.Auth` provides the file shape and `on_mount/4` callback signature, but Auth uses neither `Process.send_after/3` nor `attach_hook/4`. Use `Phoenix.LiveDashboard` `PageLive` and `phx.gen.auth` `UserAuth` (cited in CONTEXT.md `<canonical_refs>` "Idiomatic peer projects") as ecosystem precedents. The polling primitive itself (`Process.send_after/3` + `Process.cancel_timer/1` + `attach_hook/4`) is plain stdlib + LV 1.0 API — no novel machinery, just no in-house example yet. |

The recommended `Threadline.OperatorSurface.Coverage.Snapshot` struct (Claude's Discretion item) also has no in-house analog — it is a bare `defstruct` with `[:covered_count, :uncovered_count, :expected_uncovered_count, :last_checked_at, :error]`. No precedent needed.

---

## Metadata

**Analog search scope:**
- `lib/threadline/operator_surface/` (full subtree — auth, router, style, live/*, controllers/*, exports/*, export_auth_plug)
- `lib/threadline/health.ex`, `telemetry.ex`, `verify/coverage_policy.ex`, `continuity.ex`, `capture/redaction_policy.ex`
- `lib/mix/tasks/` (full directory — verify_coverage, export, gen.triggers, retention.purge, incident, install, continuity)
- `test/threadline/operator_surface/` (full subtree — doc-contract tests, live/*, exports/*, controllers/*, *mix*)

**Files scanned:** 22

**Key in-repo conventions surfaced:**
1. Operator-surface modules ALL gate on `Phoenix.LiveView` at file scope (line 1 + closing `end`).
2. Repo resolution is consistently `socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()`.
3. CSS isolation via `<div class="threadline-ui"><Threadline.OperatorSurface.Style.css />` — no Tailwind, no layout component.
4. Doc-contract tests are pure source-reading (no DB, no bootup) except for runtime-output assertions (Jason schema check).
5. Mix tasks all share the `resolve_repo!/0` + `ensure_repo_started!/1` boot pattern.
6. Atom safety via `String.to_existing_atom/1` only; doc-contract refutes `String.to_atom\b` on every surface that takes untrusted input.
7. The amber `#FEF3C7 / #92400E / #F59E0B` triplet is the project's "data-loss-adjacent warning" palette (Phase 65 `.truncation-banner.warning` → Phase 66 `.surface-badge--warn` reuses identically).

**Pattern extraction date:** 2026-05-07
