# Phase 67: Drift-Aware Redaction Admin & Mix Task Parity - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 8 recommended Phase 67 targets
**Analogs found:** 7 / 8 (the missing exact analog is the new `pg_proc.prosrc` drift-introspection parser)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/policy/redaction_presenter.ex` | presenter / utility | transform | `lib/threadline/operator_surface/coverage/snapshot.ex` | role-match |
| `lib/threadline/operator_surface/live/policy_redaction_live.ex` | LiveView | request-response | `lib/threadline/operator_surface/live/coverage_live.ex` | exact |
| `lib/mix/tasks/threadline.policy.show.ex` | Mix task | request-response | `lib/mix/tasks/threadline.health.coverage.ex` + `lib/mix/tasks/threadline.verify_coverage.ex` | exact |
| `lib/threadline/operator_surface/router.ex` | router | request-response | `lib/threadline/operator_surface/router.ex` | exact |
| `lib/threadline/operator_surface/style.ex` | style component | request-response | `lib/threadline/operator_surface/style.ex` | exact |
| `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | doc-contract test | file-I/O | `test/threadline/operator_surface/coverage_doc_contract_test.exs` + `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` + `test/threadline/operator_surface/exports_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | LiveView integration test | request-response | `test/threadline/operator_surface/live/coverage_live_test.exs` | exact |
| `test/threadline/operator_surface/policy_show_mix_test.exs` | Mix-task integration test | request-response | `test/threadline/operator_surface/coverage_mix_test.exs` | exact |

## Pattern Assignments

### `lib/threadline/policy/redaction_presenter.ex` (presenter / transform)

**Recommended role:** pure-stdlib shared reconciliation layer consumed by both the LV and Mix task.

**Primary analog:** `lib/threadline/operator_surface/coverage/snapshot.ex`

**Struct + grouped-state pattern** ([snapshot.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/coverage/snapshot.ex:15)):
```elixir
defstruct covered_count: 0,
          uncovered_count: 0,
          expected_uncovered_count: 0,
          last_checked_at: nil,
          error: nil,
          tables: [covered: [], uncovered: [], expected_uncovered: []]
```

**Presenter reduction pattern** ([snapshot.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/coverage/snapshot.ex:38)):
```elixir
grouped =
  Enum.reduce(coverage, %{covered: [], uncovered: [], expected_uncovered: []}, fn
    {:covered, name}, acc -> Map.update!(acc, :covered, &[name | &1])
    {:uncovered, name}, acc -> Map.update!(acc, :uncovered, &[name | &1])
    {:expected_uncovered, name}, acc -> Map.update!(acc, :expected_uncovered, &[name | &1])
  end)
```

**Apply for Phase 67:** keep the same shape discipline, but replace coverage buckets with the locked policy buckets:
- `config_matches_deployed`
- `drift_detected`
- `could_not_introspect`

**Secondary analogs for configured-policy semantics:**

From `lib/threadline/capture/redaction_policy.ex` ([redaction_policy.ex](/Users/jon/projects/threadline/lib/threadline/capture/redaction_policy.ex:22)):
```elixir
exclude = normalize_columns(Map.get(opts, :exclude, Map.get(opts, "exclude", [])))
mask = normalize_columns(Map.get(opts, :mask, Map.get(opts, "mask", [])))
```

From `lib/threadline/capture/trigger_sql.ex` ([trigger_sql.ex](/Users/jon/projects/threadline/lib/threadline/capture/trigger_sql.ex:54)):
```elixir
exclude = Keyword.get(opts, :exclude, [])
mask = Keyword.get(opts, :mask, [])
placeholder = Keyword.get(opts, :mask_placeholder, RedactionPolicy.default_placeholder())
```

**Recommendation:** normalize `config :threadline, :trigger_capture` into one canonical per-table shape:
- `table`
- `configured.exclude`
- `configured.mask`
- `configured.mask_placeholder`
- `deployed.exclude`
- `deployed.mask`
- `deployed.mask_placeholder`
- `diff.*`
- `status`
- `hint`

This module should stay ungated so capture-only adopters can use `mix threadline.policy.show`.

---

### `lib/threadline/operator_surface/live/policy_redaction_live.ex` (LiveView, request-response)

**Primary analog:** `lib/threadline/operator_surface/live/coverage_live.ex`

**File-scope optional Phoenix gate** ([coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:1)):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.CoverageLive do
```

**Imports / module preamble** ([coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:5)):
```elixir
use Phoenix.LiveView

alias Threadline.OperatorSurface.Coverage.Snapshot
```

**Mount assigns pattern** ([coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:21)):
```elixir
def mount(_params, _session, socket) do
  initial =
    socket.assigns[:threadline_coverage] || Snapshot.empty(DateTime.utc_now())

  socket =
    socket
    |> assign(:base_path, nil)
    |> assign(:schema_param, "public")
    |> assign(:coverage_for_schema, initial)
    |> assign(:form_error, nil)

  {:ok, socket}
end
```

**Header + page wrapper pattern** ([coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:83)):
```heex
<div class="threadline-ui">
  <Threadline.OperatorSurface.Style.css />
  <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
    coverage={@threadline_coverage}
    base_path={@base_path}
    error={@threadline_coverage_error}
  />
```

**State-grouped table rendering pattern** ([coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:117)):
```heex
<table class="coverage-table">
  <thead>
    <tr><th>TABLE</th><th>STATUS</th><th>SOURCE</th></tr>
  </thead>
  <tbody>
    <%= for table <- @coverage_for_schema.tables[:covered] do %>
```

**Error banner / conservative fallback pattern** ([coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:106)):
```heex
<%= if @threadline_coverage_error do %>
  <div class="truncation-banner warning" role="status">
    Coverage check failed at <%= now_label() %> — showing last successful result from <%= last_label(@coverage_for_schema.last_checked_at) %>.
  </div>
<% end %>
```

**Operational-safe edge validation pattern** ([coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:158)):
```elixir
sql = "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1"

case Ecto.Adapters.SQL.query!(repo, sql, [schema]) do
  %{rows: []} -> {:error, "Schema '#{schema}' not found."}
  %{rows: _} -> {:ok, schema}
end
```

**Apply for Phase 67:**
- keep the same file-scope gate and `Threadline.OperatorSurface.Style.css` wrapper.
- mount a shared presenter result instead of ad hoc LV-only diffs.
- render three visible sections in the locked order: `Drift detected`, `Could not introspect`, `Config matches deployed`.
- keep table/detail rendering inside `.threadline-ui`; use local disclosure only, no URL state.
- never render sample values; only columns, placeholders, reasons, and hints.

---

### `lib/mix/tasks/threadline.policy.show.ex` (Mix task, request-response)

**Primary analog:** `lib/mix/tasks/threadline.health.coverage.ex`

**Viewer semantics + `--json` usage doc pattern** ([threadline.health.coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.health.coverage.ex:1)):
```elixir
@shortdoc "Show trigger coverage for audited tables"

@moduledoc """
...
    mix threadline.health.coverage
    mix threadline.health.coverage --json
    mix threadline.health.coverage --schema=NAME
...
"""
```

**Boot sequence pattern** ([threadline.health.coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.health.coverage.ex:35)):
```elixir
{opts, _, _} = OptionParser.parse(argv, strict: [json: :boolean, schema: :string])
...
Mix.Task.run("app.config", [])
{:ok, _} = Application.ensure_all_started(:ssl)
{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)
```

**Repo-start and edge-validation pattern** ([threadline.health.coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.health.coverage.ex:62), [threadline.verify_coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.verify_coverage.ex:64)):
```elixir
repo = resolve_repo!()
ensure_repo_started!(repo)
validate_schema!(repo, schema)
```

**Aligned table output pattern** ([threadline.health.coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.health.coverage.ex:102)):
```elixir
table_w = max(24, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 5 end))
status_w = 12

header =
  String.pad_trailing("TABLE", table_w) <>
    "  " <> String.pad_trailing("STATUS", status_w) <> "  SOURCE"
```

**Stable additive JSON pattern** ([threadline.health.coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.health.coverage.ex:130)):
```elixir
payload = %{
  "schema" => schema,
  "covered" => Enum.sort(covered),
  "uncovered" => Enum.sort(uncovered),
  "expected_uncovered" => Enum.sort_by(expected_uncovered, & &1["table"])
}
```

**Gate vs viewer distinction to preserve** ([threadline.health.coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.health.coverage.ex:58), [threadline.verify_coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.verify_coverage.ex:59)):
```elixir
# viewer
:ok
```

```elixir
if violations != [] do
  exit({:shutdown, 1})
end
```

**Apply for Phase 67:**
- default output should stay viewer-style: one summary line, one aligned table, extra detail blocks only for drift/introspection failures.
- `--json` is the machine contract.
- do not exit non-zero for drift alone.
- the task should consume the same presenter output as the LiveView.

---

### `lib/threadline/operator_surface/router.ex` (route wiring)

**Primary analog:** current coverage route wiring in `lib/threadline/operator_surface/router.ex`

**Existing route insertion point** ([router.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/router.ex:69)):
```elixir
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, unquote(opts)},
    {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
  ] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/", TimelineLive, :index)
    live("/coverage", CoverageLive, :index)
```

**Recommendation:** add the Phase 67 route as a sibling LV under the existing operator-surface scope, following the same literal doc-contract posture as `/coverage`. Recommended literal:
```elixir
live("/policy/redaction", PolicyRedactionLive, :index)
```

Keep this inside the existing `live_session :threadline`; do not create a second session for a read-only sibling page.

---

### `lib/threadline/operator_surface/style.ex` (style extension)

**Primary analog:** existing coverage-page additions in `lib/threadline/operator_surface/style.ex`

**Header badge patterns to preserve** ([style.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:254)):
```css
.threadline-ui-header {
  position: sticky;
  top: 0;
  z-index: 2;
  height: var(--tl-header-height, 36px);
}

.threadline-ui .surface-badge--warn {
  background: #FEF3C7;
  color: #92400E;
  border-left: 3px solid #F59E0B;
}
```

**Coverage table pattern** ([style.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:297)):
```css
.threadline-ui .coverage-page {
  padding: var(--tl-spacing-md);
}

.threadline-ui .coverage-table {
  width: 100%;
  border-collapse: collapse;
  margin-top: var(--tl-spacing-md);
}
```

**Apply for Phase 67:**
- extend the same `.threadline-ui` namespace; do not add a separate stylesheet module.
- follow the coverage page’s low-noise read-only styling.
- add new section and row classes under the same namespace, with drift and introspection rows visually louder than matches.
- reuse `.truncation-banner.warning` tone for “could not introspect” and rerun guidance unless a clearer dedicated warning class is needed.

---

### `test/threadline/operator_surface/policy_show_doc_contract_test.exs` (doc-contract)

**Primary analogs:**
- `test/threadline/operator_surface/coverage_doc_contract_test.exs`
- `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs`
- `test/threadline/operator_surface/exports_doc_contract_test.exs`

**Coverage doc-contract harness pattern** ([coverage_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_doc_contract_test.exs:13)):
```elixir
use ExUnit.Case, async: false

import ExUnit.CaptureIO

@router_path "lib/threadline/operator_surface/router.ex"
@coverage_lv_path "lib/threadline/operator_surface/live/coverage_live.ex"
@mix_task_path "lib/mix/tasks/threadline.health.coverage.ex"
```

**Source-reading route literal assertion** ([coverage_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_doc_contract_test.exs:27)):
```elixir
assert String.contains?(src, ~s|live("/coverage", CoverageLive, :index)|)
```

**File-scope gate enforcement pattern** ([coverage_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_doc_contract_test.exs:266), [timeline_browse_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:81)):
```elixir
first_line = src |> String.split("\n") |> hd()

assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do"
```

**Runtime `Mix.Task` JSON-schema assertion pattern** ([coverage_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_doc_contract_test.exs:160)):
```elixir
output =
  capture_io(fn ->
    Mix.Tasks.Threadline.Health.Coverage.run(["--json"])
  end)

parsed = Jason.decode!(output)
```

**Atom-safety / SQL-injection refute pattern** ([coverage_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_doc_contract_test.exs:206)):
```elixir
refute src =~ ~r/String\.to_atom\b/
refute src =~ ~r/nspname = '#/
```

**Apply for Phase 67:** lock at least:
- route literal for `/policy/redaction`
- LiveView state literals: `Config matches deployed`, `Drift detected`, `Could not introspect`
- Mix task usage literals: `mix threadline.policy.show`, `--json`
- JSON status enums: `config_matches_deployed`, `drift_detected`, `could_not_introspect`
- no-sample-values invariants across LV and Mix task sources
- file-scope Phoenix gate on the new LV
- no file-scope Phoenix gate on the shared presenter and Mix task

---

### `test/threadline/operator_surface/live/policy_redaction_live_test.exs` (LiveView integration)

**Primary analog:** `test/threadline/operator_surface/live/coverage_live_test.exs`

**Nested Layouts / Router / Endpoint harness** ([coverage_live_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/live/coverage_live_test.exs:1)):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.CoverageLiveTest.Layouts do
    use Phoenix.Component
```

**Endpoint boot pattern** ([coverage_live_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/live/coverage_live_test.exs:69)):
```elixir
setup_all do
  Application.put_env(:threadline, Threadline.OperatorSurface.CoverageLiveTest.Endpoint,
    secret_key_base: "c" |> String.duplicate(64),
    live_view: [signing_salt: "c" |> String.duplicate(8)],
    render_errors: [view: Threadline.OperatorSurface.CoverageLiveTest.Layouts]
  )
```

**Runtime assertion style** ([coverage_live_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/live/coverage_live_test.exs:97)):
```elixir
{:ok, _view, html} = live(conn, "/audit/coverage")

assert html =~ "Coverage — schema: public"
assert html =~ "<th>TABLE</th>"
assert html =~ ~r/Coverage: \d+ covered, \d+ uncovered, \d+ expected uncovered/
```

**Apply for Phase 67:** mirror this file structure and assert:
- the three section headings appear in the locked order
- alphabetical ordering within sections
- exact configured vs deployed `exclude` and `mask` sets are visible
- placeholder metadata appears when relevant
- `could not introspect` rows show the rerun hint
- no raw sample values appear in rendered HTML

---

### `test/threadline/operator_surface/policy_show_mix_test.exs` (Mix integration)

**Primary analog:** `test/threadline/operator_surface/coverage_mix_test.exs`

**Re-enable pattern** ([coverage_mix_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_mix_test.exs:17)):
```elixir
setup do
  Mix.Task.reenable("threadline.health.coverage")
  Mix.Task.reenable("threadline.verify_coverage")
  :ok
end
```

**Human-output assertion pattern** ([coverage_mix_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_mix_test.exs:25)):
```elixir
output =
  capture_io(fn ->
    Mix.Tasks.Threadline.Health.Coverage.run([])
  end)

assert output =~ "TABLE"
assert output =~ "STATUS"
```

**JSON-contract assertion pattern** ([coverage_mix_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_mix_test.exs:58)):
```elixir
parsed = Jason.decode!(output)

assert parsed |> Map.keys() |> Enum.sort() ==
         ["covered", "expected_uncovered", "schema", "uncovered"]
```

**Apply for Phase 67:** assert:
- default output summary counts
- `TABLE / STATUS / CONFIG / DEPLOYED / HINT` headers
- detail blocks only for drift/introspection failures
- JSON keyset and status enums
- viewer exit semantics remain zero on drift
- no sample values appear in either human or JSON output

## Shared Patterns

### Shared presenter first, surfaces second

**Source patterns:** [snapshot.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/coverage/snapshot.ex:38), [coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:172), [threadline.health.coverage.ex](/Users/jon/projects/threadline/lib/mix/tasks/threadline.health.coverage.ex:50)

Both the operator page and the Mix task should consume one shared presenter result. Phase 66 already demonstrates the shape:
- lib builds normalized data
- LV renders it
- Mix task renders the same facts differently

Do not duplicate drift comparison logic in both surfaces.

### Redaction semantics must copy capture truth, not reinvent it

**Source patterns:** [redaction_policy.ex](/Users/jon/projects/threadline/lib/threadline/capture/redaction_policy.ex:22), [trigger_sql.ex](/Users/jon/projects/threadline/lib/threadline/capture/trigger_sql.ex:54)

Configured and deployed policy comparison must preserve the existing semantics:
- `exclude` and `mask` remain separate buckets
- `mask_placeholder` is first-class
- overlap rules come from `Threadline.Capture.RedactionPolicy.validate!/1`

### Operator-surface route/style/doc-contract posture

**Source patterns:** [router.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/router.ex:69), [style.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/style.ex:254), [coverage_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_doc_contract_test.exs:27)

Phase 67 should extend the same operator-surface conventions:
- add one sibling LV route under the existing `live_session :threadline`
- use the existing `.threadline-ui` CSS namespace
- lock route literals, state strings, JSON enums, and safety refutes with a doc-contract test

### Optional Phoenix gating is file-scope

**Source patterns:** [coverage_live.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/live/coverage_live.ex:1), [surface_header.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/components/surface_header.ex:1), [coverage_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface/coverage_doc_contract_test.exs:292)

Apply the file-scope gate only to Phoenix-dependent files. Keep the shared presenter and Mix task ungated.

## No Exact Analog Found

| File / Concern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| `lib/threadline/policy/redaction_presenter.ex` drift-introspection internals | presenter / parser | transform | No existing module parses deployed trigger redaction back out of `pg_proc.prosrc`; use `Threadline.Capture.TriggerSQL` as the semantic source of truth, but the conservative reverse-parse logic is first-of-its-kind in this repo. |

## Recommended Phase 67 Files

- `lib/threadline/policy/redaction_presenter.ex`
- `lib/threadline/operator_surface/live/policy_redaction_live.ex`
- `lib/mix/tasks/threadline.policy.show.ex`
- `lib/threadline/operator_surface/router.ex`
- `lib/threadline/operator_surface/style.ex`
- `test/threadline/operator_surface/policy_show_doc_contract_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `test/threadline/operator_surface/policy_show_mix_test.exs`

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/**`, `lib/mix/tasks/**`, `lib/threadline/capture/**`, `test/threadline/operator_surface/**`, `guides/**`, `.planning/phases/66-*`

**Key patterns identified:**
- Shared pure-stdlib presenter/snapshot modules feed both LV and Mix surfaces.
- Viewer Mix tasks use `OptionParser`, repo boot, aligned table output, and stable additive `--json`.
- Operator-surface pages use file-scope Phoenix gating, `.threadline-ui` styling, route literals pinned by doc-contract tests, and no sample-value leakage.
