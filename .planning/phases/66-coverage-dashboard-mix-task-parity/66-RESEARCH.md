# Phase 66: Coverage Dashboard & Mix Task Parity - Research

**Researched:** 2026-05-07
**Domain:** Polled LiveView wrapping `Threadline.Health.trigger_coverage/1` + every-page surface header pill driven by a `live_session` `on_mount` hook + parity Mix task with `--json` and `--schema=NAME` flags + an additive `:schema` keyword on the lib API + a hardcoded `["schema_migrations"]` baseline plus host-configurable `:expected_uncovered_tables` policy
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Refresh mechanism (D-30 family)**
- **D-30** — New `Threadline.OperatorSurface.Coverage.OnMount` hook drives polling for every LV in the `live_session :threadline` block — no PubSub, no GenServer. The hook mirrors `Threadline.OperatorSurface.Auth` (gated on `Phoenix.LiveView`). At mount: fetch coverage, assign `:threadline_coverage`, schedule first tick via `Process.send_after(self(), :threadline_refresh_coverage, interval)` (guarded by `connected?(socket)`), and `attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)` so the tick is intercepted across every LV without per-LV `handle_info` boilerplate. Mounted in `router.ex` via `live_session :threadline, on_mount: [{Auth, opts}, {Coverage.OnMount, opts}]`. Does NOT use `Phoenix.PubSub`. Does NOT introduce a GenServer.
- **D-30a** — Default poll interval `30_000` ms. Override via `config :threadline, :coverage_poll_ms` (global) or socket-assign `:threadline_coverage_poll_ms` (per-mount). Floor `5_000` ms — raise at mount below that with a clear message.
- **D-30b** — Manual "Refresh" button on `CoverageLive` only (cancels timer ref, refetches, reschedules). Surface-header pages have NO manual button.
- **D-30c** — On-poll-error UX: keep last-good assign, set `:threadline_coverage_error`, ALWAYS reschedule. Inline yellow strip on dashboard; "stale" tooltip on header. Emit `[:threadline, :health, :checked, :error]` telemetry on failure. Existing `[:threadline, :health, :checked]` continues to fire on success.
- **D-30d** — Forward-compat escape hatch (`config :threadline, :coverage_source, {:pubsub, MyApp.PubSub}`) documented in `@moduledoc` but NOT shipped in v1.18.

**Surface header (D-31 family)**
- **D-31** — New shared `Phoenix.Component` `Threadline.OperatorSurface.Components.SurfaceHeader.surface_header/1`, gated on `Phoenix.LiveView`, invoked atop each LV's existing `<div class="threadline-ui">` wrapper. Reads `@threadline_coverage` from parent LV's assigns (sourced by D-30's hook). Zero per-LV polling.
- **D-31a** — Visual treatment:
  - `uncovered_count == 0` → `<a class="surface-badge surface-badge--ok" href={"#{@base_path}/coverage"}>All covered</a>` (text-muted, no fill). NEVER hide.
  - `uncovered_count > 0` → `<a class="surface-badge surface-badge--warn" href={"#{@base_path}/coverage"}>{n} uncovered</a>` (amber `#FEF3C7` / `#92400E` / `#F59E0B` — same palette as Phase 65's truncation warning).
  - `:threadline_coverage_error` set → small "stale (last checked Xs ago)" indicator next to the badge.
- **D-31b** — Header always queries `"public"` schema. Multi-schema is opt-in via URL on `CoverageLive` only.
- **D-31c** — Header sits OUTSIDE / ABOVE Phase 65's `.timeline-toolbar`. Phase 65's sticky toolbar gets `top: var(--tl-header-height, 36px)` so it docks below the surface header.
- **D-31d** — Click-through is a plain anchor (`<a href={…}>`), not `live_patch`.

**Expected-uncovered policy (D-32 family)**
- **D-32** — Three-bucket return shape: `Threadline.Health.trigger_coverage/1` returns `[{:covered | :uncovered | :expected_uncovered, table_name}]`. Existing pattern matches on `{:covered, _}` / `{:uncovered, _}` keep working — additive.
- **D-32a** — Hardcoded baseline = `["schema_migrations"]` only, codified as `@expected_uncovered_baseline ~w(schema_migrations)` module attribute on `Threadline.Health`. Oban tables are NOT baselined.
- **D-32b** — Adopter-configurable additions via `config :threadline, :health, expected_uncovered_tables: [...]`. Validated by new `Threadline.Health.Policy.validate!/1` (mirrors `Threadline.Capture.RedactionPolicy.validate!/1` shape).
- **D-32c** — Override-to-audit escape hatch — `config :threadline, :health, audit_anyway: ["schema_migrations"]`.
- **D-32d** — LV badge literals: `"covered"` (green), `"uncovered"` (red), `"expected"` (gray, neutral). Tooltip on `expected` reads literal source ("Baseline: schema_migrations" or "Configured via :expected_uncovered_tables").
- **D-32e** — Telemetry shape additive: `Threadline.Telemetry.emit_health_checked/2` becomes `/3` with `expected_uncovered_count` arg. The `[:threadline, :health, :checked]` event metadata gains an `expected_uncovered` key.
- **D-32f** — Backward-compat update to `Threadline.Verify.CoveragePolicy.violations/2`: ADD one case clause for `{:expected_uncovered, _table}` → ignore (treat as covered-equivalent for tables NOT in `:expected_tables`).

**Schema scope (D-33 family)**
- **D-33** — URL `?schema=NAME` on the LV, `--schema=NAME` on Mix tasks, regex + `pg_namespace` validated. Single mechanism; same name, same validation contract on both surfaces. `CoverageLive` page header renders `"Coverage — schema: tenant_42"`.
- **D-33a** — Validation lives at the LV/Mix EDGE, not in `Threadline.Health`. Two-layer:
  1. Regex `~r/\A[a-z_][a-z0-9_]{0,62}\z/` — malformed input never reaches a query.
  2. Catalog lookup `SELECT 1 FROM pg_namespace WHERE nspname = $1` (parameterized; never interpolated). Unknown → LV `:form_error` "Schema 'X' not found"; Mix `Mix.raise/1` exits 1.
- **D-33b** — `TimelineLive` datalist consumer (`timeline_live.ex:30`) stays bare — no `:schema` argument. Out of Phase 66 scope.
- **D-33c** — Lib API change: `Threadline.Health.trigger_coverage/1` accepts `:schema` keyword opt, default `"public"`. Replace hardcoded `'public'` literal in BOTH inner SQL queries with parameterized binds. Both queries must filter by `pg_namespace.nspname = $1` joined to `pg_class.relnamespace`.

**Mix task (D-34)**
- **D-34** — New `Mix.Tasks.Threadline.Health.Coverage` task — table format default + `--json` flag + `--schema=NAME` flag. Mirrors `mix threadline.verify_coverage` boot sequence but does NOT exit 1 on uncovered (viewer, not gate).
  - Default: three-section table with `TABLE` / `STATUS` (literal `covered`/`uncovered`/`expected`) / `SOURCE` (`baseline` / `config`, populated only on `expected`). Footer `Coverage: N covered, M uncovered, K expected uncovered`.
  - `--json`: `{"schema": "public", "covered": [...], "uncovered": [...], "expected_uncovered": [{"table": "...", "source": "baseline" | "config"}]}`.
  - File location: `lib/mix/tasks/threadline.health.coverage.ex`. Module name: `Mix.Tasks.Threadline.Health.Coverage`.

**Doc-contract test (D-35)**
- **D-35** — Pure source-reading doc-contract test at `test/threadline/operator_surface/coverage_doc_contract_test.exs`. Pins LV route literal, surface header literals (`"All covered"`, `~r/\d+ uncovered/`), three badge literals (`"covered"`, `"uncovered"`, `"expected"`), Mix-task help text + flags, Mix-task `--json` schema (top-level keys + `expected_uncovered` entry keys + `source ∈ {"baseline", "config"}`), hardcoded baseline list (`@expected_uncovered_baseline ~w(schema_migrations)`), atom-safety refute, `mix verify.compile_no_optional` greenness.

**Optional-deps posture (D-36)**
- **D-36** — `mix verify.compile_no_optional` stays green. Two new files gate on `Phoenix.LiveView`: `coverage/on_mount.ex`, `components/surface_header.ex`, `live/coverage_live.ex`. Mix task and `Threadline.Health.Policy` are pure-stdlib, no gating. No new hard deps; `phoenix_pubsub` stays `optional: true`.

### Claude's Discretion

- Exact CSS rule names within the `.threadline-ui` namespace beyond the locked literals.
- Exact keyset/struct shape of the `:threadline_coverage` socket assign (recommend a `Threadline.OperatorSurface.Coverage.Snapshot` struct).
- Exact wording of the on-poll-error inline strip.
- Whether `Threadline.Health.Policy.validate!/1` lives at `lib/threadline/health/policy.ex` (recommended) or inline.
- Exact column widths / alignment of the Mix-task default table format.
- Exact CHANGELOG wording for the `:health_checked` telemetry-event metadata change.
- Whether the page-header timestamp on `CoverageLive` is static or 1Hz-driven (recommend static).
- Whether the surface header brand label is `"Threadline"` wordmark only.

### Deferred Ideas (OUT OF SCOPE)

- PubSub-based single-source coverage broadcast (escape hatch documented for v1.19+).
- `:persistent_term` cache for opportunistic external pokes.
- TimelineLive datalist refactor to read `:threadline_coverage`.
- Schema selector dropdown / multi-schema view / tabbed `:schema` route.
- Drift surface header on Phoenix-host pages outside `/audit/...`.
- Coverage history / "covered since when" timestamps.
- Per-table "why was this table flagged?" detail page.
- "Audit me" inline button on uncovered rows.
- Surface header on RowHistoryComponent (inherits via TransactionLive automatically).
- `mix threadline.health.coverage` exit code on uncovered (CI gate is `mix threadline.verify_coverage`).
- Adding `oban_*` to the hardcoded baseline.
- Surface header showing per-schema counts.
- Phase 67 forward-compat for the redaction admin badge layout.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| **COV-01** | Coverage dashboard LV at `/audit/coverage` rendering `Threadline.Health.trigger_coverage/1` with separate covered / uncovered lists, expected-uncovered marked (e.g. `schema_migrations`), uncovered count surfaced in the surface header. | §"SC1 Implementation Approach" — three-bucket render in `CoverageLive`; surface header pill via shared `Phoenix.Component` driven by `live_session` `on_mount` hook; reuses `.threadline-ui` namespace + Phase 65 amber palette for warn variant. |
| **COV-02** | `:schema` arg on `trigger_coverage/1` (default `"public"`); LV refreshes on configurable poll (default 30s); `:health_checked` telemetry signal hookable for refresh. | §"SC2 Implementation Approach" — `:schema` keyword opt + parameterized `pg_namespace.nspname = $1` joins; `Process.send_after` per-LV polling intercepted by an `attach_hook(:handle_info, ...)` callback in `Coverage.OnMount`; existing telemetry event remains hookable (subscribers receive metadata gain `expected_uncovered` key, additive only). |
| **COV-03** | `mix threadline.health.coverage` parity task (table format + `--json`); doc-contract test locks LV route literal + Mix-task help text + output schema. | §"SC3 Implementation Approach" — new `Mix.Tasks.Threadline.Health.Coverage` mirroring `Mix.Tasks.Threadline.VerifyCoverage` boot sequence but without exit-1 semantics; pure source-reading doc-contract test mirroring `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` (BROWSE-04) and `exports_doc_contract_test.exs` (EXPO-05). |

</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Three-layer architecture** — Phase 66 is mostly *exploration/operations* layer (the dashboard + Mix task + surface badge + telemetry) plus one *capture-adjacent* edit (`Threadline.Health.trigger_coverage/1` accepts `:schema` and returns a third bucket). Do not pollute the capture layer with UI concerns.
- **Domain language** — Use `AuditTransaction` / `AuditChange` / `AuditAction` / `AuditContext` / `ActorRef` / `Correlation` consistently. (Phase 66 itself does not touch the semantics layer; this matters mainly in `@moduledoc` cross-references.)
- **Verification entrypoints** — `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all` must remain canonical citations.
- **OSS DNA** — stable CI job IDs (do not rename `id:` fields); doc-contract tests for README literals stay aligned; named verify aliases; `mix verify.compile_no_optional` is part of `ci.all` and every UI phase MUST stay green when `Phoenix.LiveView` is absent.
- **Honest default tests** — never silently exclude heavy suites from `mix test`. Do NOT add `:slow` to the exclude list.

## Phase Overview

Phase 66 ships a polled `CoverageLive` at `/audit/coverage` that wraps `Threadline.Health.trigger_coverage/1` and renders three buckets — covered, uncovered, expected-uncovered — together with an every-page "uncovered count" pill in a new shared surface header so an operator notices drift from any LV in the operator surface. To make `Health.trigger_coverage/1` correct for non-`public` adopters it grows an additive `:schema` keyword opt (default `"public"`); both inner SQL queries become parameterized against `pg_namespace.nspname = $1`. Polling is per-LV `Process.send_after` driven by a new `Threadline.OperatorSurface.Coverage.OnMount` hook attached to the existing `live_session :threadline` block, so every LV in the session inherits the refresh without per-LV `handle_info` boilerplate (zero PubSub, zero GenServer, `phoenix_pubsub` stays `optional: true`). A parity `mix threadline.health.coverage` task mirrors the `mix threadline.verify_coverage` boot sequence but is a viewer (no exit-1 on uncovered) and adds `--json` + `--schema=NAME` flags. A pure source-reading doc-contract test pins the LV route literal, the Mix-task help text + output schema, and the three badge state literals. The phase preserves backward compatibility for two existing pattern-match callsites (`Threadline.Continuity.assert_capture_ready!/2` does `if {:covered, table_name} in coverage do`; the new third tuple variant is purely additive and never replaces an existing tuple shape).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `trigger_coverage/1` `:schema` opt + parameterized SQL + third tuple variant | **Capture-adjacent (Health)** | — | The lib API is the single source of truth; UI / Mix / future callers all read from it. |
| Three-bucket policy union (baseline + `:expected_uncovered_tables` minus `:audit_anyway`) | **Operations layer (Health + Health.Policy)** | — | Pure, deterministic, host-configurable; lives next to capture but not inside it. |
| Per-LV polling via `Process.send_after` + `attach_hook(:handle_info, ...)` | **Operator surface (Coverage.OnMount)** | LV process | LV-process-local timer; zero supervision-tree change; zero new hard deps. |
| Surface header pill render | **Operator surface (shared Phoenix.Component)** | — | Reads from parent LV's assigns; no own state, no own poll. |
| Coverage table render (three buckets, three badge literals) | **Operator surface (CoverageLive)** | — | Reads `:threadline_coverage` assign + `?schema=` URL param. |
| Schema validation (regex + `pg_namespace` lookup) | **Operator surface edge (LV `handle_params`/Mix task)** | — | Validation at the EDGE; `Threadline.Health` lib API does NOT validate `:schema` — programmatic callers are responsible for sanitizing. |
| Mix-task viewer with `--json` + `--schema=NAME` | **Operations layer (Mix.Tasks.Threadline.Health.Coverage)** | Capture/Semantics (consumes `Health.trigger_coverage/1`) | Pure-stdlib OptionParser + `Jason.encode!/1`; no Phoenix deps; capture-only adopters use this. |
| Telemetry emission additive (`expected_uncovered_count`) | **Operations layer (Threadline.Telemetry)** | — | Existing `[:threadline, :health, :checked]` event metadata grows additively; old subscribers reading only `covered`/`uncovered` keep working. |
| Doc-contract test pinning literals | **Test infrastructure** | — | Pure source-reading (`File.read!` + `String.contains?` + `Regex.scan`); no DB, no LV bootup. |

## Existing Code to Reuse / Extend

### `Threadline.Health.trigger_coverage/1` — `lib/threadline/health.ex` (CURRENT FORM)

```elixir
@audit_tables ~w(audit_transactions audit_changes audit_actions)

def trigger_coverage(opts) do
  repo = Keyword.fetch!(opts, :repo)

  all_tables = fetch_all_user_tables(repo)
  covered_tables = fetch_threadline_covered_tables(repo)

  covered_set = MapSet.new(covered_tables)

  result =
    all_tables
    |> Enum.reject(&(&1 in @audit_tables))
    |> Enum.map(fn table ->
      if MapSet.member?(covered_set, table) do
        {:covered, table}
      else
        {:uncovered, table}
      end
    end)

  covered_count = Enum.count(result, &match?({:covered, _}, &1))
  uncovered_count = Enum.count(result, &match?({:uncovered, _}, &1))
  Threadline.Telemetry.emit_health_checked(covered_count, uncovered_count)

  result
end

defp fetch_all_user_tables(repo) do
  sql = "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
  %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [])
  List.flatten(rows)
end

defp fetch_threadline_covered_tables(repo) do
  sql = """
  SELECT DISTINCT c.relname
  FROM pg_trigger t
  JOIN pg_class c ON t.tgrelid = c.oid
  WHERE t.tgname LIKE 'threadline_audit_%'
  """

  %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [])
  List.flatten(rows)
end
```

**Three observations load-bearing for Phase 66:**

1. **`fetch_threadline_covered_tables/1` is currently SCHEMA-AGNOSTIC** — it joins `pg_trigger` to `pg_class.oid` but never filters by namespace. A trigger named `threadline_audit_*` on `tenant_42.users` AND on `public.users` would BOTH appear in the result. After the `:schema` opt lands, this query MUST add a `pg_namespace` join filtered by `nspname = $1` so cross-schema results don't leak into the covered set. **This is a load-bearing correctness fix that the `:schema` opt brings.** [VERIFIED via reading `lib/threadline/health.ex:62-71`]

2. **`fetch_all_user_tables/1` interpolates `'public'` as a string literal**, NOT a parameterized bind. Both queries become parameterized against `$1` (pg_tables.schemaname AND pg_namespace.nspname).

3. **`@audit_tables` exclusion is unconditional and stays so.** `audit_transactions` / `audit_changes` / `audit_actions` are NEVER in the result regardless of bucket — they are Threadline's own infrastructure tables. The third bucket (`:expected_uncovered`) is for the ADOPTER's bookkeeping tables (e.g. `schema_migrations`, `oban_jobs`).

### Existing pattern-match callsites — backward compatibility ceiling

| Callsite | Pattern | Phase 66 impact |
|----------|---------|-----------------|
| `lib/threadline/continuity.ex:71` | `if {:covered, table_name} in coverage do` (membership test) | UNCHANGED — third tuple variant is purely additive; `{:covered, name}` membership semantics unchanged. |
| `lib/threadline/operator_surface/live/timeline_live.ex:30-35` | `Enum.flat_map/2` keeping `{:covered, name}` only | UNCHANGED — falls through `_ -> []` branch for the new `{:expected_uncovered, name}` tuples; datalist still shows only covered tables. |
| `lib/threadline/verify/coverage_policy.ex:25-35` | `Map.new(coverage, fn {status, name} -> {name, status} end)` | UNCHANGED structurally; ADD one case clause for `:expected_uncovered` per D-32f (treat as covered-equivalent for tables NOT in `:expected_tables`). |
| `lib/mix/tasks/threadline.verify_coverage.ex:118-121` | `case Map.fetch(by_table, table) do {:ok, :covered} -> "covered"; {:ok, :uncovered} -> "uncovered"; :error -> "missing" end` | UNCHANGED — only iterates `expected_tables` so `:expected_uncovered` tuples never reach this case. |
| `test/threadline/health_test.exs:11-14` | `match?({:covered, name} ...)` OR `match?({:uncovered, name} ...)` | UPDATE — extend to also accept `{:expected_uncovered, name}` so the test reflects the new shape. |
| `test/threadline/health_test.exs:54` | `assert_receive {:telemetry, %{covered: covered, uncovered: uncovered}}` | UPDATE — extend metadata destructure to include `expected_uncovered`. |

**Backward-compat conclusion:** The third tuple is additive. No existing pattern-match callsite breaks. One new case clause in `Verify.CoveragePolicy.violations/2` (D-32f). Two minor test updates.

### `Threadline.Telemetry.emit_health_checked/2` — `lib/threadline/telemetry.ex:60`

```elixir
def emit_health_checked(covered, uncovered) do
  :telemetry.execute(
    [:threadline, :health, :checked],
    %{covered: covered, uncovered: uncovered},
    %{}
  )
end
```

**Phase 66 change (D-32e):** become `/3` with `expected_uncovered` measurement. There is exactly ONE in-tree caller (`Threadline.Health.trigger_coverage/1` itself), so the cleanest update is direct replacement of `/2` with `/3`. Old external subscribers that destructure `%{covered: c, uncovered: u}` keep working (additive measurement key). Update the `@moduledoc` event-shape paragraph.

### `Threadline.OperatorSurface.Auth.on_mount/4` — `lib/threadline/operator_surface/auth.ex` (file shape precedent)

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Auth do
    @moduledoc """
    Authentication contract for the Threadline operator surface.
    """

    import Phoenix.LiveView

    def on_mount(opts, _params, _session, socket) do
      authorize_fn = Keyword.get(opts, :authorize_fn, fn _socket -> true end)
      ...
    end
  end
end
```

`Coverage.OnMount` mirrors this shape EXACTLY:
- File-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end end` wrapper.
- `import Phoenix.LiveView` at the top of the inner module (gives `connected?/1` and `attach_hook/4`).
- `on_mount/4` callback signature.
- Same opts-keyword-list parameter shape (forwarded by the macro from the caller).

### Macro mount + live_session block — `lib/threadline/operator_surface/router.ex:67-76` (CURRENT FORM)

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

**Phase 66 edits:**
1. Append `{Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}` to the `on_mount:` list — order matters (Auth runs first, sets `:threadline_repo` + `:threadline_scope`; Coverage.OnMount uses `:threadline_repo` to query).
2. Add `live("/coverage", CoverageLive, :index)` inside the existing `scope` block.

### `Mix.Tasks.Threadline.VerifyCoverage` — `lib/mix/tasks/threadline.verify_coverage.ex` (boot sequence precedent)

The new `Mix.Tasks.Threadline.Health.Coverage` reuses verbatim:

```elixir
def run(_args) do
  Mix.Task.run("app.config", [])
  {:ok, _} = Application.ensure_all_started(:ssl)
  {:ok, _} = Application.ensure_all_started(:postgrex)
  {:ok, _} = Application.ensure_all_started(:ecto_sql)

  repo = resolve_repo!()
  ensure_repo_started!(repo)
  ...
end

defp resolve_repo! do
  case Application.get_env(:threadline, :ecto_repos, []) do
    [] -> Mix.raise("Threadline: set :ecto_repos in config — ...")
    [repo | _] -> repo
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

The new task differs only in:
- Adds `OptionParser.parse(argv, strict: [json: :boolean, schema: :string])`.
- Does NOT exit 1 on uncovered (it's a viewer).
- Calls `Threadline.Health.trigger_coverage(repo: repo, schema: schema)`.
- Renders either three-section table OR `Jason.encode!/1` of the JSON schema.

### `Threadline.Capture.RedactionPolicy.validate!/1` — `lib/threadline/capture/redaction_policy.ex` (precedent for `Health.Policy.validate!/1`)

The new `Threadline.Health.Policy` mirrors:
- Accepts keyword OR map (`def validate!(opts) when is_list(opts), do: validate!(Map.new(opts))`).
- Raises `ArgumentError` with a clear message on bad input.
- Pure-stdlib (no `Phoenix.LiveView` gate).
- Lives at `lib/threadline/health/policy.ex` (sibling pattern matches `lib/threadline/capture/redaction_policy.ex`).

### `Threadline.OperatorSurface.Style.css/1` — `lib/threadline/operator_surface/style.ex` (CSS extension target)

Existing CSS-variable-themed `.threadline-ui` namespace. Phase 66 ADDS:
- `--tl-header-height: 36px` (new CSS variable on `.threadline-ui`).
- `.threadline-ui-header` (sticky `top: 0`, `z-index: 2`).
- `.surface-badge` + `.surface-badge--ok` + `.surface-badge--warn`.
- `.coverage-table`, `.coverage-row--covered/uncovered/expected`.
- EDIT existing `.timeline-toolbar` rule: `top: 0` → `top: var(--tl-header-height, 36px)`.

### `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` — pure source-reading test precedent

```elixir
defmodule Threadline.OperatorSurface.TimelineBrowseDocContractTest do
  use ExUnit.Case, async: true

  @router_path "lib/threadline/operator_surface/router.ex"
  @lv_path "lib/threadline/operator_surface/live/timeline_live.ex"
  ...

  test "router declares the timeline browse live route at the surface root" do
    router_src = File.read!(@router_path)
    assert String.contains?(router_src, ~s|live("/", TimelineLive, :index)|), ...
  end
end
```

`coverage_doc_contract_test.exs` follows the same shape: `File.read!/1` + `String.contains?/2` + `Regex.scan/2` over module source. Mix-task `--json` schema assertion is the one part that requires actually invoking the task at runtime (`ExUnit.CaptureIO.capture_io/1` + `Mix.Task.rerun/2` + `Jason.decode!/1`).

### `test/threadline/operator_surface/live/timeline_live_test.exs:1-60` — nested test-Endpoint shape

The CoverageLive integration test reuses this structure:
- Define a nested `…CoverageLiveTest.Layouts` `Phoenix.Component` for `root/1` + `render/2`.
- Define a nested `…CoverageLiveTest.Router` with a `:browser` pipeline + `Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")` invocation.
- Define a nested `…CoverageLiveTest.Endpoint` with session + `Plug.Parsers` + the router.
- `start_supervised(@endpoint)` in setup.
- `Phoenix.LiveViewTest.live(conn, "/audit/coverage")` for mount assertions.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix.LiveView | `~> 1.0` (mix.exs:58) | `attach_hook/4` for cross-LV `handle_info` interception; `connected?/1` guard for `Process.send_after`; `on_mount/4` callback shape | Already declared optional dep; `attach_hook/4` is the idiomatic primitive for shared on_mount-driven assigns since LV 0.18+ and stable in 1.0. [VERIFIED: lib/mix.exs:58; CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#attach_hook/4] |
| Phoenix.Component | bundled with phoenix_live_view | `Threadline.OperatorSurface.Components.SurfaceHeader.surface_header/1` function component | Already used by `Threadline.OperatorSurface.Style`; same shape. [VERIFIED: lib/threadline/operator_surface/style.ex:7] |
| Phoenix.LiveView.Router | bundled | `live("/coverage", CoverageLive, :index)` registration inside existing `live_session :threadline` | Already imported by surface router macro. [VERIFIED: lib/threadline/operator_surface/router.ex:67] |
| `Threadline.Health.trigger_coverage/1` | n/a | Three-bucket coverage source | The lib API the dashboard wraps. Phase 66 EDITS it for `:schema` + third bucket. [VERIFIED: lib/threadline/health.ex:29] |
| `Threadline.Telemetry.emit_health_checked` | n/a | Successful-poll telemetry hook (existing `:health, :checked` event) | Already an idiomatic external-subscription point; subscribers only need extend their `%{covered, uncovered}` destructure to also read `expected_uncovered`. [VERIFIED: lib/threadline/telemetry.ex:60] |
| `Process.send_after/3` + `Process.cancel_timer/1` | stdlib | Per-LV polling primitive; manual-refresh cancel-and-reschedule | Stable since OTP 18; idiomatic for "tick every N ms" LV polling (Phoenix LiveDashboard pattern). [CITED: hexdocs.pm/elixir/Process.html] |
| `OptionParser.parse/2` | stdlib | `--json` boolean + `--schema=NAME` string parsing in the Mix task | Standard sibling-task convention (`mix threadline.export` line 39 already uses this shape). [VERIFIED: lib/mix/tasks/threadline.export.ex:39] |
| `Jason` | `~> 1.4` (mix.exs:53) | `Jason.encode!/1` for `--json` flag | Already a HARD dep; consistent with `Threadline.Export` JSON path. [VERIFIED: lib/mix.exs:53] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Ecto.Adapters.SQL.query!/3` | `~> 3.10` (mix.exs:51) | Parameterized `pg_namespace` lookup for D-33a schema validation | Already used by `Threadline.Health` and `Threadline.Continuity.public_table_exists?/2`. [VERIFIED: lib/threadline/continuity.ex:80-89] |
| `Phoenix.LiveView.attach_hook/4` | bundled with LV 1.0 | `attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)` so the on_mount-emitted `:threadline_refresh_coverage` message is intercepted across every LV in the session | The idiomatic cross-LV glue for shared session behavior; zero per-LV `handle_info` boilerplate. [CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#attach_hook/4] |
| `Phoenix.Component.assign/3` | bundled | Update `:threadline_coverage` snapshot on each tick | Standard LV assign primitive. |
| `Calendar.strftime/2` | stdlib | "Last checked Xs ago" timestamp formatting | Stdlib since 1.11; reused by `Filename.for/2`. [VERIFIED: lib/threadline/operator_surface/exports/filename.ex:44] |
| `Phoenix.LiveViewTest` (`live/2`, `render/1`, `render_click/2`) | bundled | LV integration test cases for mount + manual refresh + `?schema=` validation | Pattern mirrors `actor_live_test.exs` and `timeline_live_test.exs:1-90`. |
| `ExUnit.CaptureIO.capture_io/1` | bundled | Suppress `Mix.shell().info/1` chatter from the new Mix task in tests | Already used by `mix threadline.export` test suite. [VERIFIED: test/mix/tasks/threadline/] |
| `Mix.Task.rerun/2` | bundled | Re-run the new task across multiple test cases (single-OS-process gotcha) | `Mix.Task.run/2` no-ops on second call; same gotcha Phase 65's parity test hit (RESEARCH §P-11). |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-LV `Process.send_after` + `attach_hook` (D-30) | Single `GenServer` source-of-truth + `Phoenix.PubSub.broadcast/3` | Adds hard `phoenix_pubsub` dep AND a supervision-tree change. CONTEXT.md D-30 explicitly rejects both for v1.18; documented as forward-compat escape hatch (D-30d) for v1.19+ if 50+ tab scale demands it. |
| `attach_hook(:handle_info, ...)` in Coverage.OnMount | Per-LV `def handle_info(:threadline_refresh_coverage, ...)` clauses | Multiplies boilerplate across 4 LVs (Timeline / Transaction / Actor / Coverage). `attach_hook` is the idiomatic primitive since LV 0.18+ for exactly this case. |
| `Threadline.Health.Policy` validates `:schema` opt | Validation only at LV/Mix edge (D-33a) | Per CONTEXT.md, lib API stays thin — `Health.trigger_coverage/1` does NOT validate `:schema`; programmatic callers are responsible. Two-layer regex+catalog validation lives at the surfaces that take untrusted input. Document explicitly in `@doc`. |
| Hardcode Oban tables in baseline | `:expected_uncovered_tables` config (D-32a) | Hardcoding seeds silent drift on hypothetical `oban_jobs` domain tables (e.g. an analytics platform that audits its own job records). Adopters who use Oban add `["oban_jobs", "oban_peers", "oban_producers"]` themselves. |
| URL `?schema=NAME` (D-33) | In-page schema selector / multi-schema view / tabbed `:schema` route | Speculative complexity for the 5%; URL param matches Phase 64's existing `?from=&to=&table=` LV idiom and is parity-clean with the Mix task `--schema=NAME` flag. |
| `:json` boolean flag on the Mix task | `--format json` (matches `mix threadline.export`) | `--json` is shorter and matches the precedent set by `mix threadline.policy.show` (Phase 67) per the same milestone — keep symmetry across v1.18 viewer Mix tasks. The `--format`-style flag is overkill for two output modes (table vs JSON). |
| New telemetry event `[:threadline, :coverage, :refreshed]` for LV poll ticks | Reuse existing `[:threadline, :health, :checked]` (D-30c) | The existing event already fires on every `trigger_coverage/1` call — that's exactly when the LV polls. A separate event would double-emit. Per D-30c, ADD `[:threadline, :health, :checked, :error]` for failures (since failures don't currently emit anything). |

**Installation:** No new deps. Phase 66 lands inside the existing optional-deps envelope. `mix verify.compile_no_optional` MUST stay green.

**Version verification:**
- `Phoenix.LiveView.attach_hook/4` available since LV 0.18 (introduced in 2022); declared `~> 1.0` in mix.exs is well above the floor. [VERIFIED: lib/mix.exs:58; CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#attach_hook/4]
- `:telemetry` `~> 1.2` (mix.exs:56) is a HARD dep — the existing `[:threadline, :health, :checked]` event flows through it. No bump needed. [VERIFIED: lib/mix.exs:56]
- `Jason` `~> 1.4` (mix.exs:53) — `Jason.encode!/1` for the `--json` Mix-task output. No bump needed. [VERIFIED: lib/mix.exs:53]

## Architecture Patterns

### System Architecture Diagram

```
                                  Operator browser
                                          │
                       ┌──────────────────┴──────────────────┐
                       │                                      │
                       ▼                                      ▼
         GET /audit (TimelineLive)                  GET /audit/coverage
         GET /audit/transactions/:id                  (CoverageLive)
         GET /audit/actors/:kind/:id                          │
                       │                                      │
                       └──────────────────┬───────────────────┘
                                          │
                                          ▼
                       ┌──────────────────────────────────────────┐
                       │ Phoenix Router                           │
                       │  live_session :threadline,               │
                       │    on_mount: [                           │
                       │      {Threadline.OperatorSurface.Auth,   │
                       │        opts},                            │
                       │      {Threadline.OperatorSurface.        │
                       │        Coverage.OnMount, opts}    ◄─NEW │
                       │    ]                                     │
                       │  do                                      │
                       │   live "/", TimelineLive, :index         │
                       │   live "/transactions/:id", ...          │
                       │   live "/actors/:kind/:id", ...          │
                       │   live "/coverage", CoverageLive, :index │
                       │  end                                     │
                       └─────────────────┬────────────────────────┘
                                          ▼
                       ┌──────────────────────────────────────────┐
                       │ Threadline.OperatorSurface.              │
                       │   Coverage.OnMount.on_mount/4            │
                       │  • repo = socket.assigns.threadline_repo │
                       │  • interval = config + assign override + │
                       │      floor 5_000ms                       │
                       │  • snapshot = fetch_coverage(repo,       │
                       │      "public")  ── try/rescue            │
                       │  • assign(:threadline_coverage, snap)    │
                       │  • if connected?(socket):                │
                       │     timer_ref = Process.send_after(self, │
                       │       :threadline_refresh_coverage, int) │
                       │     attach_hook(:threadline_coverage_    │
                       │       refresh, :handle_info,             │
                       │       &handle_refresh/2)                 │
                       └───────────────┬──────────────────────────┘
                                       │ (every LV in :threadline session inherits)
                                       ▼
   ┌──────────────────────────────────────────────────────────────────┐
   │ Per-LV render: <.surface_header coverage={@threadline_coverage}  │
   │                  base_path={@base_path} />                       │
   │   → renders .surface-badge--ok ("All covered") if uncovered == 0│
   │   → renders .surface-badge--warn ("{n} uncovered") if > 0        │
   │   → small "stale" indicator if :threadline_coverage_error set    │
   └──────────────────────────────────────────────────────────────────┘

   Tick (every interval ms in EVERY LV process):
   ───────────────────────────────────────────────
   :threadline_refresh_coverage → handle_refresh/2 (attached hook)
     → fetch_coverage → update :threadline_coverage assign
     → reschedule via Process.send_after
     → on error: keep last-good, set :threadline_coverage_error,
                 emit [:threadline, :health, :checked, :error],
                 ALWAYS reschedule

   CoverageLive only:
   ────────────────────
   handle_event("refresh", _, socket):
     Process.cancel_timer(socket.assigns.threadline_timer_ref)
     fetch_coverage immediately
     reschedule

   handle_params(%{"schema" => schema}, _, socket):
     1. validate regex \A[a-z_][a-z0-9_]{0,62}\z
     2. SELECT 1 FROM pg_namespace WHERE nspname = $1
     3. invalid → assign :form_error "Schema 'X' not found"
     4. valid → fetch_coverage with :schema = NAME

                   (Capture-only adopter path)
   ┌──────────────────────────────────────────────────────────────────┐
   │ mix threadline.health.coverage [--json] [--schema=NAME]          │
   │   1. Mix.Task.run("app.config", []) + start :ssl/:postgrex/      │
   │      :ecto_sql                                                   │
   │   2. resolve_repo!() + ensure_repo_started!(repo)                │
   │   3. validate --schema (regex + pg_namespace) — Mix.raise on bad │
   │   4. coverage = Threadline.Health.trigger_coverage(              │
   │        repo: repo, schema: schema)                               │
   │   5. if --json: Jason.encode!(%{schema, covered, uncovered,      │
   │                                  expected_uncovered}) |> IO.puts │
   │      else: render TABLE / STATUS / SOURCE table                  │
   │   6. EXIT 0 ALWAYS (viewer, not gate)                            │
   └──────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
lib/threadline/
├── health.ex                                    # EDIT: :schema opt, third bucket, telemetry +1
├── health/
│   └── policy.ex                                # NEW: validate!/1 for :expected_uncovered_tables / :audit_anyway
├── telemetry.ex                                 # EDIT: emit_health_checked/2 → /3
├── verify/
│   └── coverage_policy.ex                       # EDIT: one additive case for :expected_uncovered
└── operator_surface/
    ├── router.ex                                # EDIT: append Coverage.OnMount, add /coverage route
    ├── style.ex                                 # EDIT: --tl-header-height, surface-badge*, coverage-*
    ├── coverage/
    │   └── on_mount.ex                          # NEW: Phoenix.LiveView gated; attach_hook polling
    ├── components/
    │   └── surface_header.ex                    # NEW: Phoenix.LiveView gated; .surface-badge pill
    └── live/
        ├── coverage_live.ex                     # NEW: Phoenix.LiveView gated; three-bucket table
        ├── timeline_live.ex                     # EDIT: one-line <.surface_header /> render addition
        ├── transaction_live.ex                  # EDIT: one-line <.surface_header /> render addition
        └── actor_live.ex                        # EDIT: one-line <.surface_header /> render addition

lib/mix/tasks/
├── threadline.health.coverage.ex                # NEW: viewer Mix task; pure stdlib
└── threadline.verify_coverage.ex                # EDIT: additive --schema=NAME flag

test/threadline/operator_surface/
├── coverage_doc_contract_test.exs               # NEW: pure source-reading literal pin
├── coverage_mix_test.exs                        # NEW: Mix-task --json + --schema integration
└── live/
    ├── coverage_live_test.exs                   # NEW: LiveViewTest mount + refresh + ?schema=
    ├── timeline_live_test.exs                   # EDIT: one assertion that .surface-badge renders
    ├── transaction_live_test.exs                # EDIT: same
    └── actor_live_test.exs                      # EDIT: same
```

### Pattern 1: `live_session` `on_mount` + `attach_hook` for cross-LV polling

```elixir
# lib/threadline/operator_surface/coverage/on_mount.ex
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Coverage.OnMount do
    @moduledoc """
    Polls Threadline.Health.trigger_coverage/1 once per LV in the
    :threadline live_session. Default 30_000 ms; override via
    `config :threadline, :coverage_poll_ms` (global) or socket assign
    :threadline_coverage_poll_ms (per-mount). Floor 5_000 ms — raises below.

    Forward-compat: when :coverage_source is {:pubsub, _}, this hook
    can be made a no-op. Out of v1.18 scope; documented for v1.19+.
    """

    import Phoenix.LiveView
    alias Threadline.OperatorSurface.Coverage.Snapshot

    @default_interval 30_000
    @floor_interval 5_000

    def on_mount(_opts, _params, _session, socket) do
      interval = resolve_interval(socket)

      if interval < @floor_interval do
        raise ArgumentError,
              "coverage poll interval must be >= #{@floor_interval} ms; got #{interval}"
      end

      socket = assign(socket, :threadline_coverage, fetch_snapshot(socket, "public"))

      socket =
        if connected?(socket) do
          ref = Process.send_after(self(), :threadline_refresh_coverage, interval)

          socket
          |> assign(:threadline_timer_ref, ref)
          |> attach_hook(
            :threadline_coverage_refresh,
            :handle_info,
            &handle_refresh/2
          )
        else
          socket
        end

      {:cont, socket}
    end

    defp handle_refresh(:threadline_refresh_coverage, socket) do
      socket = assign(socket, :threadline_coverage, fetch_snapshot(socket, "public"))
      ref = Process.send_after(self(), :threadline_refresh_coverage, resolve_interval(socket))
      socket = assign(socket, :threadline_timer_ref, ref)
      {:halt, socket}
    end

    defp handle_refresh(_msg, socket), do: {:cont, socket}

    defp fetch_snapshot(socket, schema) do
      repo = socket.assigns[:threadline_repo]
      now = DateTime.utc_now()

      try do
        coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
        Snapshot.from_coverage(coverage, last_checked_at: now)
      rescue
        e ->
          Threadline.Telemetry.emit_health_checked_error(Exception.message(e))
          previous = socket.assigns[:threadline_coverage] || Snapshot.empty(now)
          %{previous | error: Exception.message(e)}
      end
    end

    defp resolve_interval(socket) do
      socket.assigns[:threadline_coverage_poll_ms] ||
        Application.get_env(:threadline, :coverage_poll_ms, @default_interval)
    end
  end
end
```

`{:halt, socket}` from `handle_refresh/2` STOPS message dispatch to per-LV `handle_info` clauses — the on_mount hook owns this message exclusively. Other `handle_info` messages fall through with `{:cont, socket}`.

[CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#attach_hook/4]

### Pattern 2: `Threadline.Health.trigger_coverage/1` with `:schema` parameterization

```elixir
# lib/threadline/health.ex (POST-PHASE-66 SHAPE)
@expected_uncovered_baseline ~w(schema_migrations)

def trigger_coverage(opts) do
  repo = Keyword.fetch!(opts, :repo)
  schema = Keyword.get(opts, :schema, "public")

  all_tables = fetch_all_user_tables(repo, schema)
  covered_tables = fetch_threadline_covered_tables(repo, schema)
  expected_uncovered = compute_expected_uncovered()

  covered_set = MapSet.new(covered_tables)
  expected_set = MapSet.new(expected_uncovered)

  result =
    all_tables
    |> Enum.reject(&(&1 in @audit_tables))
    |> Enum.map(fn table ->
      cond do
        MapSet.member?(covered_set, table) -> {:covered, table}
        MapSet.member?(expected_set, table) -> {:expected_uncovered, table}
        true -> {:uncovered, table}
      end
    end)

  covered_count = Enum.count(result, &match?({:covered, _}, &1))
  uncovered_count = Enum.count(result, &match?({:uncovered, _}, &1))
  expected_uncovered_count = Enum.count(result, &match?({:expected_uncovered, _}, &1))

  Threadline.Telemetry.emit_health_checked(
    covered_count, uncovered_count, expected_uncovered_count
  )

  result
end

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
  WHERE t.tgname LIKE 'threadline_audit_%'
    AND n.nspname = $1
  """

  %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [schema])
  List.flatten(rows)
end

defp compute_expected_uncovered do
  health_cfg = Application.get_env(:threadline, :health, [])
  configured = Keyword.get(health_cfg, :expected_uncovered_tables, [])
  audit_anyway = Keyword.get(health_cfg, :audit_anyway, [])

  (@expected_uncovered_baseline ++ configured)
  |> Enum.uniq()
  |> Enum.reject(&(&1 in audit_anyway))
end
```

[CITED: postgresql.org/docs/current/catalog-pg-namespace.html — pg_namespace.nspname is the canonical schema-name column for `pg_class.relnamespace` joins]

### Pattern 3: Surface header `Phoenix.Component`

```elixir
# lib/threadline/operator_surface/components/surface_header.ex
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Components.SurfaceHeader do
    @moduledoc false
    use Phoenix.Component

    attr :coverage, :map, required: true
    attr :base_path, :string, required: true

    def surface_header(assigns) do
      ~H"""
      <header class="threadline-ui-header">
        <span class="brand">Threadline</span>
        <%= if @coverage.uncovered_count == 0 do %>
          <a class="surface-badge surface-badge--ok" href={"#{@base_path}/coverage"}>All covered</a>
        <% else %>
          <a class="surface-badge surface-badge--warn" href={"#{@base_path}/coverage"}>
            <%= @coverage.uncovered_count %> uncovered
          </a>
        <% end %>
        <%= if @coverage.error do %>
          <span class="stale-indicator">stale (last checked <%= seconds_ago(@coverage.last_checked_at) %>s ago)</span>
        <% end %>
      </header>
      """
    end
  end
end
```

### Pattern 4: Mix-task `--json` schema (D-34)

```elixir
# Output literal:
%{
  "schema" => "public",
  "covered" => ["users", "posts"],
  "uncovered" => ["orders"],
  "expected_uncovered" => [
    %{"table" => "schema_migrations", "source" => "baseline"},
    %{"table" => "oban_jobs", "source" => "config"}
  ]
}
|> Jason.encode!()
|> IO.puts()
```

The `source` field discriminates baseline vs adopter-config provenance — `jq '.expected_uncovered[] | select(.source == "config")'` answers "what did my host config exempt?" without touching the LV.

### Anti-Patterns to Avoid

- **Hand-rolled GenServer for "single source of truth" coverage broadcaster** — CONTEXT.md D-30 explicitly rejects. Per-LV polling at 30s × N≈10 tabs is cheap; the GenServer + PubSub architecture is the v1.19+ escape hatch (D-30d).
- **`String.to_atom/1` on user-supplied `schema` param** — atom-leak vector (Pitfall 11 carry-forward from Phase 65). Schema param is never converted to atom; it stays a binary string parameterized into SQL.
- **Interpolating `:schema` into SQL** — must always be `$1` parameterized. `pg_namespace.nspname = '#{schema}'` is a SQL injection vector even with regex pre-validation.
- **Hardcoding `["schema_migrations", "oban_jobs", ...]` in lib** — D-32a explicitly forbids growing the baseline. Adopter-declared via `config :threadline, :health, expected_uncovered_tables: [...]`.
- **Per-LV `handle_info(:threadline_refresh_coverage, ...)` clauses** — multiplies boilerplate; D-30 + the `attach_hook(:handle_info, ...)` pattern eliminates this.
- **Stopping the poll on error** — D-30c locks "ALWAYS reschedule." A transient DB blip must not silently freeze the count.
- **Multiplying the manual "Refresh" button across all LVs** — D-30b locks it to `CoverageLive` only.
- **`live_patch` (instead of plain `<a href={…}>`) on the surface header click-through** — destination is a different LV module; `live_patch` is for same-LV patches. D-31d locks plain anchor.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cross-LV `handle_info` interception | Per-LV `handle_info(:threadline_refresh_coverage, ...)` boilerplate | `attach_hook(:handle_info, &fun/2)` in `Coverage.OnMount` | Idiomatic since LV 0.18+; one source of truth. |
| Schema validation regex authoring | Custom validation rules | `~r/\A[a-z_][a-z0-9_]{0,62}\z/` (PostgreSQL identifier rule, conservative subset) | PostgreSQL identifier max length is 63 chars; the conservative subset matches `pg_namespace.nspname` casing PostgreSQL itself emits without quoting. Do NOT support quoted-identifier schemas (`"My Schema"`); they break `pg_proc.prosrc` introspection downstream (Phase 67 anchor) anyway. |
| JSON encoding | Hand-rolled string concatenation | `Jason.encode!/1` | Already a HARD dep; consistent with `Threadline.Export`. |
| Coverage policy validation | Inline checks scattered across modules | `Threadline.Health.Policy.validate!/1` (pattern from `Threadline.Capture.RedactionPolicy.validate!/1`) | Single source of truth; raises on bad config at start time. |
| Telemetry event additions | Hand-rolled supervisor + new event tree | Reuse `[:threadline, :health, :checked]` (additive metadata) + ADD `[:threadline, :health, :checked, :error]` (new sibling event for failures) | Minimizes external-subscriber friction; existing handlers keep working. |
| Filename / timestamp formatting on the dashboard | Custom strftime calls | `Calendar.strftime/2` (stdlib) | Already used by `Threadline.OperatorSurface.Exports.Filename`. |
| Mix-task table column padding | Hand-rolled column-width calculation | Sibling pattern in `mix threadline.verify_coverage` (`String.pad_trailing/2` after `Enum.max/1` over byte_size) | Already idiomatic; copy verbatim. |

**Key insight:** Phase 66's "new mechanism" surface area is small — one new on_mount module, one new function component, one new LV, one new Mix task, one new Health.Policy validator. Everything else is `EDIT` of an existing file (Health, Telemetry, Verify.CoveragePolicy, router, style, three sibling LVs, the existing verify_coverage Mix task). The optional-deps gating posture, the doc-contract test posture, the boot-sequence boilerplate, the Mix-task table-formatting helpers, the LV nested-Endpoint test infrastructure — all of these have direct precedents inside this codebase that should be copied verbatim.

## Runtime State Inventory

> Phase 66 is a code/config-only addition. There is no rename, refactor, migration, or runtime-state change. **Step 2.5 is N/A.**

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by grep over `lib/` for any data-store key naming. The `:threadline_coverage` socket assign and `Coverage.OnMount`-managed timer ref live ONLY in the LV process; nothing is persisted. | None. |
| Live service config | None — verified by reading `lib/threadline/operator_surface/router.ex`. The `live_session :threadline` block adds the new on_mount hook entry; no external service config carries the existing one. | None. |
| OS-registered state | None — Phase 66 ships in-process; no scheduled tasks, daemons, launchd plists, etc. | None. |
| Secrets / env vars | None — no new secret keys; no env-var name changes. The `:expected_uncovered_tables` and `:coverage_poll_ms` config knobs live in `runtime.exs` namespaces only. | None. |
| Build artifacts | None — three new lib files, three test files, two edited Mix tasks. Standard `mix compile` flow. | None. |

## Implementation Approach

### SC1 (COV-01) — Coverage dashboard LV at `/audit/coverage` + every-page surface header

**What to build:**
1. **`lib/threadline/health/policy.ex`** — Pure-stdlib validator for `:expected_uncovered_tables` and `:audit_anyway`. Mirrors `Threadline.Capture.RedactionPolicy.validate!/1` shape (accept keyword OR map; raise `ArgumentError` on non-binary entries / duplicates / unknown keys).
2. **`lib/threadline/health.ex`** (EDIT) —
   - Add `@expected_uncovered_baseline ~w(schema_migrations)` module attribute.
   - Add `:schema` keyword opt with default `"public"` (but used by SC2; structural change here).
   - Compute the third bucket via `compute_expected_uncovered/0` (baseline ++ configured, minus `:audit_anyway`, deduped).
   - Return three-tuple shape `[{:covered | :uncovered | :expected_uncovered, name}]`.
   - Update `@moduledoc` + `@doc` for the three-bucket return shape.
   - Cross-link from `@moduledoc` to the new `mix threadline.health.coverage` task (added in SC3).
3. **`lib/threadline/telemetry.ex`** (EDIT) — `emit_health_checked/2` becomes `/3` (additive `expected_uncovered_count` arg). Single in-tree caller is `Health.trigger_coverage/1`. Old external subscribers reading `%{covered, uncovered}` keep working (additive measurement). Also add `emit_health_checked_error/1` for D-30c (LV poll-error case).
4. **`lib/threadline/verify/coverage_policy.ex`** (EDIT) — ADD one case clause for `{:expected_uncovered, _}` in `Map.new(coverage, fn {status, name} -> {name, status} end)` consumers; treat as covered-equivalent for tables NOT in `:expected_tables`.
5. **`lib/threadline/operator_surface/coverage/on_mount.ex`** (NEW) — `Phoenix.LiveView`-gated module per Pattern 1.
6. **`lib/threadline/operator_surface/components/surface_header.ex`** (NEW) — `Phoenix.LiveView`-gated function component per Pattern 3.
7. **`lib/threadline/operator_surface/live/coverage_live.ex`** (NEW) — `Phoenix.LiveView`-gated LV with three-bucket render, three-state badges, manual refresh affordance, on-error inline strip, schema validation error rendering.
8. **`lib/threadline/operator_surface/router.ex`** (EDIT) — append `Coverage.OnMount` to `on_mount:` list; add `live("/coverage", CoverageLive, :index)` inside scope.
9. **`lib/threadline/operator_surface/style.ex`** (EDIT) — add `--tl-header-height: 36px` variable; new `.threadline-ui-header`, `.surface-badge`, `.surface-badge--ok`, `.surface-badge--warn`, `.coverage-table`, `.coverage-row--covered/uncovered/expected` rules; EDIT existing `.timeline-toolbar` to use `top: var(--tl-header-height, 36px)`.
10. **`lib/threadline/operator_surface/live/{timeline,transaction,actor}_live.ex`** (EDIT) — single render edit each: `<.surface_header coverage={@threadline_coverage} base_path={@base_path} />` directly under `<Threadline.OperatorSurface.Style.css />`. (TimelineLive's existing `:base_path` assign works as-is; for TransactionLive / ActorLive verify the regex-derived `base_path` matches.)

**Where to mount:** `Threadline.OperatorSurface.Coverage.OnMount` is added to the `on_mount:` list in `live_session :threadline` AFTER `Auth` (Auth populates `:threadline_repo`; Coverage.OnMount reads it).

**Three-bucket render:** `CoverageLive` partitions the snapshot's coverage list into three sections (covered / uncovered / expected_uncovered) and renders one row per table with a status badge (`"covered"` / `"uncovered"` / `"expected"`) and, for the `expected` bucket only, a `SOURCE` column (`baseline` for entries in `@expected_uncovered_baseline`, `config` for entries in `:expected_uncovered_tables`). The footer renders `"Coverage: N covered, M uncovered, K expected uncovered"`.

### SC2 (COV-02) — `:schema` opt + 30s poll + telemetry hookable

**What to build:**
1. **`Health.trigger_coverage/1` `:schema` opt** (covered in SC1.2) — both inner SQL queries become parameterized: `pg_tables WHERE schemaname = $1` and the trigger query gets a new `JOIN pg_namespace n ON c.relnamespace = n.oid WHERE ... AND n.nspname = $1`. Document at the `@doc`: lib does NOT validate `:schema`; programmatic callers are responsible. **This is the load-bearing schema-introspection correctness fix; the existing trigger query joins only `pg_trigger ↔ pg_class` so cross-schema results would otherwise leak.**
2. **30s default poll** (covered in SC1.5) — `Coverage.OnMount` per Pattern 1; `@default_interval 30_000`; floor `5_000`; configurable via `config :threadline, :coverage_poll_ms` or socket assign `:threadline_coverage_poll_ms`.
3. **Telemetry hookable** — Existing `[:threadline, :health, :checked]` event continues to fire on every successful `trigger_coverage/1` (which is the LV poll path). Subscribers extend `%{covered: c, uncovered: u}` destructure to also read `expected_uncovered`. Document the metadata gain in CHANGELOG and `Threadline.Telemetry` `@moduledoc`. NEW sibling event `[:threadline, :health, :checked, :error]` fires on LV poll failures (D-30c) so adopters can alert.
4. **Schema validation at the LV edge** (D-33a) — `CoverageLive.handle_params/3`:
   - If `?schema=NAME` absent → query `"public"`.
   - If present: regex `~r/\A[a-z_][a-z0-9_]{0,62}\z/` first; on mismatch assign `:form_error "Schema 'X' not found."` and render the `.filter-error` div instead of the coverage table.
   - On regex match: `Ecto.Adapters.SQL.query!(repo, "SELECT 1 FROM pg_namespace WHERE nspname = $1", [schema])` (parameterized!); if `rows == []` same `:form_error` flow.
5. **Manual refresh on `CoverageLive` only** (D-30b) — `phx-click="refresh"` on a small "Refresh" anchor; handler cancels timer ref, refetches immediately, reschedules.

**Backward-compat ceiling:** The `:schema` default of `"public"` keeps every existing caller (TimelineLive datalist line 30, `mix threadline.verify_coverage`, `Threadline.Continuity.assert_capture_ready!/2`, README quickstart fixtures, all existing tests) running unchanged.

### SC3 (COV-03) — Mix task parity + doc-contract test

**What to build:**
1. **`lib/mix/tasks/threadline.health.coverage.ex`** (NEW) — `Mix.Tasks.Threadline.Health.Coverage`. Mirrors `mix threadline.verify_coverage` boot sequence (`Mix.Task.run("app.config", [])` + start `:ssl/:postgrex/:ecto_sql` + `resolve_repo!/0` + `ensure_repo_started!/1`). Adds `OptionParser.parse(argv, strict: [json: :boolean, schema: :string])`. Validates `--schema=NAME` per D-33a (regex + `pg_namespace`); `Mix.raise/1` on bad input (exits 1 — but this is INPUT validation, not a coverage gate; uncovered tables exit 0). Calls `Threadline.Health.trigger_coverage(repo: repo, schema: schema)`. Renders either:
   - Default: three-section table `TABLE | STATUS | SOURCE` per Pattern 4's table form; footer `"Coverage: N covered, M uncovered, K expected uncovered"`.
   - `--json`: `Jason.encode!(%{schema: schema, covered: [...], uncovered: [...], expected_uncovered: [%{table: ..., source: "baseline" | "config"}, ...]})` printed to stdout.
   Exit code 0 always (viewer, not gate).
2. **`lib/mix/tasks/threadline.verify_coverage.ex`** (EDIT) — additive `--schema=NAME` flag with the same validation contract as D-33a; default behavior unchanged. The task remains the CI gate.
3. **`test/threadline/operator_surface/coverage_doc_contract_test.exs`** (NEW) — pure source-reading test pinning:
   - LV route: `live("/coverage", CoverageLive, :index)` in `router.ex`.
   - Surface header literals: `"All covered"` and `~r/\d+ uncovered/` in `surface_header.ex`.
   - Three badge state literals: `"covered"`, `"uncovered"`, `"expected"` in `coverage_live.ex`.
   - Mix-task `@shortdoc` and the `## Usage` section in `lib/mix/tasks/threadline.health.coverage.ex` (locks `mix threadline.health.coverage`, `mix threadline.health.coverage --json`, `mix threadline.health.coverage --schema=NAME` literals).
   - Mix-task `--json` schema invocation: `ExUnit.CaptureIO.capture_io/1` + `Mix.Task.rerun("threadline.health.coverage", ["--json"])` + `Jason.decode!/1`; assert top-level keys are exactly `["covered", "expected_uncovered", "schema", "uncovered"]` (sorted) and that `expected_uncovered` entries have keys `["source", "table"]` with `source ∈ {"baseline", "config"}`.
   - Hardcoded baseline literal: `@expected_uncovered_baseline ~w(schema_migrations)` in `health.ex`.
   - Atom-safety refute: `refute String.contains?(src, "String.to_atom\\b")` over `coverage_live.ex` and the new Mix task source.
   - Optional-deps file gates: `if Code.ensure_loaded?(Phoenix.LiveView)` present at line 1 of `on_mount.ex`, `surface_header.ex`, `coverage_live.ex`.
4. **Recommended LV integration test** — `test/threadline/operator_surface/live/coverage_live_test.exs`. LiveViewTest cases:
   - Mount renders three buckets when at least one expected-uncovered table exists.
   - Manual "Refresh" click cancels-and-reschedules timer (verify timer ref changes).
   - `?schema=NAME` validation: regex-fail (`?schema=Public`) → 422-style `:form_error`; pg_namespace-miss (`?schema=nonexistent`) → same; valid (`?schema=public`) → renders coverage.
   - Surface header renders on Timeline / Transaction / Actor LVs (extend `timeline_live_test.exs`, `transaction_live_test.exs`, `actor_live_test.exs` with one assertion each).
5. **Recommended Mix-task integration test** — `test/threadline/operator_surface/coverage_mix_test.exs`. Cases:
   - Default table format prints three sections + footer line.
   - `--json` produces JSON-decodable output with the exact key set asserted in the doc-contract test (parity test, not byte-equality since formats differ).
   - `--schema=public` passes; `--schema=Public` fails with regex error; `--schema=nonexistent` fails with pg_namespace error.
   - `Mix.Task.reenable("threadline.health.coverage")` in setup so each case can re-invoke.

## Key Decisions / Tradeoffs

| Decision | Rationale | Recommendation |
|----------|-----------|----------------|
| `:threadline_coverage` shape: bare map vs struct | A struct (`Threadline.OperatorSurface.Coverage.Snapshot` with keys `covered_count`, `uncovered_count`, `expected_uncovered_count`, `last_checked_at`, `error`, `tables` keyed by bucket) gives Dialyzer + autocomplete benefits; doc-contract test can pin its keys. CONTEXT.md leaves this to Claude's discretion. | **Recommend struct** at `lib/threadline/operator_surface/coverage/snapshot.ex` (no Phoenix gate; pure stdlib). Add `from_coverage/2` constructor + `empty/1` for the on-error fallback. |
| `Health.Policy` location | `lib/threadline/health/policy.ex` (sibling under `health/` subdirectory) vs inline inside `health.ex`. Precedent: `lib/threadline/capture/redaction_policy.ex` IS a sibling file. | **Recommend `lib/threadline/health/policy.ex`** — matches the redaction-policy precedent. |
| `--json` flag name | `--json` vs `--format json` (matches `mix threadline.export`). | **Recommend `--json` boolean flag** per CONTEXT.md D-34. Two output modes (table / JSON) don't justify the `--format` ceremony; `--json` is shorter and matches the v1.18 viewer-Mix-task convention REDN-05 will reuse. |
| Schema validation when `pg_namespace` lookup fails (DB error vs unknown schema) | If `Ecto.Adapters.SQL.query!` itself raises (e.g. repo down), should we surface "DB unavailable" vs "schema not found"? | **Recommend let `query!` exception bubble** — the on-poll-error path (D-30c) already handles transient DB blips. The "schema not found" form_error is only for the case where the query SUCCEEDS but returns zero rows. |
| LV "Last checked Xs ago" — static or 1Hz timer | Static re-renders on each 30s tick; smoother UX with 1Hz timer but adds another `Process.send_after` per LV. | **Recommend static** per CONTEXT.md hint (Claude's discretion). Operator notice grain is 30s; sub-second smoothness is not load-bearing. |
| `:schema` default in lib API | `"public"` keeps all existing callers backward-compat. | **`"public"` per D-33c (locked).** Document at `@doc`: "lib does NOT validate `:schema`; programmatic callers are responsible." |
| Order of `on_mount` hooks in `live_session :threadline` | Auth must run first (sets `:threadline_repo` + `:threadline_scope`). Coverage.OnMount reads `:threadline_repo`. | **Recommend `on_mount: [{Auth, opts}, {Coverage.OnMount, opts}]`** in that order. Document the dependency in `Coverage.OnMount` `@moduledoc`. |
| Surface header on RowHistoryComponent | RowHistoryComponent is a `Phoenix.LiveComponent` rendered INSIDE TransactionLive; it inherits `<.surface_header />` from the parent's render block. | **No edit needed.** Note explicitly in PLAN.md to avoid redundant work. |
| `[:threadline, :health, :checked, :error]` sibling event | New event for D-30c poll failures so adopters can alert. | **Recommend ADD as a new sibling event** (not a measurement on the success event); document in `Threadline.Telemetry` `@moduledoc` alongside the existing event. |

## Files to Create / Modify

### Create

| Path | Purpose | Gating |
|------|---------|--------|
| `lib/threadline/health/policy.ex` | `Threadline.Health.Policy.validate!/1` for `:expected_uncovered_tables` + `:audit_anyway` config validation | None — pure stdlib |
| `lib/threadline/operator_surface/coverage/on_mount.ex` | `Coverage.OnMount.on_mount/4` polling hook | `if Code.ensure_loaded?(Phoenix.LiveView)` |
| `lib/threadline/operator_surface/coverage/snapshot.ex` | `Snapshot` struct shape for `:threadline_coverage` socket assign (recommended, Claude's discretion) | None — pure stdlib |
| `lib/threadline/operator_surface/components/surface_header.ex` | Shared `surface_header/1` function component | `if Code.ensure_loaded?(Phoenix.LiveView)` |
| `lib/threadline/operator_surface/live/coverage_live.ex` | `CoverageLive` — three-bucket dashboard | `if Code.ensure_loaded?(Phoenix.LiveView)` |
| `lib/mix/tasks/threadline.health.coverage.ex` | Parity Mix task (viewer; `--json` + `--schema=NAME`) | None — pure stdlib (capture-only adopters use this) |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | Pure source-reading literal pin (D-35) | None — `use ExUnit.Case, async: true` |
| `test/threadline/operator_surface/live/coverage_live_test.exs` | LiveViewTest mount + refresh + ?schema= cases | Wrapped in `if Code.ensure_loaded?(Phoenix.LiveView)` per timeline_live_test.exs precedent |
| `test/threadline/operator_surface/coverage_mix_test.exs` | Mix-task integration: default table + `--json` schema + `--schema=NAME` plumbing | None — `use ExUnit.Case, async: false` (Mix task in-process gotcha; `Mix.Task.reenable` in setup) |

### Modify

| Path | Change |
|------|--------|
| `lib/threadline/health.ex` | Add `@expected_uncovered_baseline`; `:schema` opt with default `"public"` + parameterize both inner SQL queries with `pg_namespace` join; compute and emit third bucket; update `@moduledoc` + `@doc` for three-bucket shape |
| `lib/threadline/telemetry.ex` | `emit_health_checked/2` → `/3` (additive `expected_uncovered_count`); add `emit_health_checked_error/1` for poll failures; update `@moduledoc` event-shape paragraph |
| `lib/threadline/verify/coverage_policy.ex` | One additive case clause for `{:expected_uncovered, _}` in `violations/2` |
| `lib/threadline/operator_surface/router.ex` | Append `{Coverage.OnMount, opts}` to `on_mount:` list; add `live("/coverage", CoverageLive, :index)` inside scope |
| `lib/threadline/operator_surface/style.ex` | New `--tl-header-height: 36px`; new `.threadline-ui-header`, `.surface-badge`, `.surface-badge--ok`, `.surface-badge--warn`, `.coverage-table`, `.coverage-row--covered/uncovered/expected`; EDIT `.timeline-toolbar` to use `top: var(--tl-header-height, 36px)` |
| `lib/threadline/operator_surface/live/timeline_live.ex` | Single one-line render edit: `<.surface_header coverage={@threadline_coverage} base_path={@base_path} />` directly under `<Threadline.OperatorSurface.Style.css />` |
| `lib/threadline/operator_surface/live/transaction_live.ex` | Same one-line edit; verify `:base_path` assign is set in `handle_params/3` for the regex-derived path |
| `lib/threadline/operator_surface/live/actor_live.ex` | Same one-line edit |
| `lib/mix/tasks/threadline.verify_coverage.ex` | Add `--schema=NAME` flag with same validation contract as D-33a; default behavior unchanged |
| `test/threadline/health_test.exs` | Extend `match?/2` test to also accept `{:expected_uncovered, name}`; extend telemetry destructure to read `expected_uncovered` |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | Add one assertion that `<.surface_header />` renders the badge text |
| `test/threadline/operator_surface/live/transaction_live_test.exs` | Same |
| `test/threadline/operator_surface/live/actor_live_test.exs` | Same |
| `guides/operator-surface.md` | New `## Coverage dashboard` section: route literal, polling defaults + override config, three badge meanings, multi-schema `?schema=` usage, `:expected_uncovered_tables` config example |
| `guides/domain-reference.md` | Update `## Trigger coverage (operational)` section: three-bucket return shape, `:schema` opt, new Mix-task name |
| `guides/production-checklist.md` | Add `## Coverage drift visibility` subsection cross-linking to dashboard + Mix task |
| `CHANGELOG.md` | v1.18 entry: `Threadline.Health.trigger_coverage/1` API change (additive `:schema` opt; additive third tuple bucket; backward-compat preserved); new `mix threadline.health.coverage`; new operator-surface header; new `:expected_uncovered_tables` / `:audit_anyway` config |
| `README.md` (minor) | Cross-link to coverage dashboard in operator-surface bullet; verify `test/threadline/readme_doc_contract_test.exs` literals don't shift |

## Failure Modes / Landmines

### Pitfall 1: Cross-schema trigger leak in `fetch_threadline_covered_tables/1`
**What goes wrong:** The current SQL joins `pg_trigger ↔ pg_class.oid` but never filters by namespace. An adopter with the same logical-table name in BOTH `public` AND `tenant_42` schemas (one with triggers, one without) would see the covered set bleed across schemas. The `:schema` opt MUST add `JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = $1`.
**Why it happens:** Schema-agnostic SQL is the path of least resistance during the original v1.0 implementation; works correctly only because most adopters have a single audited schema (`public`).
**How to avoid:** Add the `pg_namespace` join + parameterized `$1` filter in BOTH inner queries. Add a test case that creates the same table name in two schemas and asserts only the queried schema's triggers are reflected.
**Warning signs:** A non-`public` adopter's dashboard shows tables as covered when they're not (or vice versa).

### Pitfall 2: SQL injection via `:schema` keyword
**What goes wrong:** A tempting-but-wrong refactor uses `"WHERE n.nspname = '#{schema}'"` interpolation. CONTEXT.md D-33a + D-33c are explicit: parameterize `$1`. Even with edge-side regex pre-validation, defense-in-depth requires the lib API to never interpolate.
**Why it happens:** Interpolation reads more naturally than `Ecto.Adapters.SQL.query!(repo, sql, [schema])`.
**How to avoid:** Doc-contract test refute: `refute String.contains?(File.read!("lib/threadline/health.ex"), ~s|nspname = '#|)`.
**Warning signs:** any `'#{` or `\#{` substring inside the SQL strings in `health.ex`.

### Pitfall 3: `String.to_atom/1` on `:schema` URL param
**What goes wrong:** The atom table is shared process-wide and capped at 1M atoms by default. An attacker can flood the LV with `?schema=evil_1`, `?schema=evil_2`, ..., `?schema=evil_N` to exhaust it. Carry-forward from Phase 65's Pitfall 11.
**Why it happens:** Pattern-matching on atomized schema names looks idiomatic.
**How to avoid:** Schema params are NEVER converted to atoms. They stay binary strings, parameterized into SQL. Doc-contract test refute: `refute String.contains?(src, "String.to_atom\\b")` over `coverage_live.ex` and the Mix task source.
**Warning signs:** Any `String.to_atom/1` or `:erlang.binary_to_atom/2` call near schema handling.

### Pitfall 4: Polling never resumes after a transient DB blip
**What goes wrong:** A naive implementation that does `Process.send_after` only in the success branch silently freezes when `Health.trigger_coverage/1` raises. The dashboard count is wedged at the last good value forever — except it's not visibly wedged because there's no error indicator.
**Why it happens:** The `try/rescue` happy path returns the same shape, the error path returns nothing → the schedule call lives in the success branch.
**How to avoid:** D-30c — ALWAYS reschedule. Wrap fetch in `try/rescue`; on rescue, set `:threadline_coverage_error`, emit `[:threadline, :health, :checked, :error]`, AND reschedule. Add a test case that mocks `query!` to raise once, then succeed; assert the LV shows the error band on tick 1 and recovers on tick 2.
**Warning signs:** Coverage badge becomes stale and never updates.

### Pitfall 5: Per-LV `Process.send_after` interval drift on a long-lived session
**What goes wrong:** `Process.send_after` is a one-shot. If the on_mount or handle_refresh path forgets to reschedule, polling stops. Easy to miss when adding new branches.
**Why it happens:** No central tick loop; rescheduling is a manual responsibility on every code path.
**How to avoid:** ALL branches of `handle_refresh/2` MUST reschedule. Store the new ref in `:threadline_timer_ref` so manual refresh can cancel cleanly. Pin the schedule shape via doc-contract grep: `assert String.contains?(src, "Process.send_after(self(), :threadline_refresh_coverage,")`.
**Warning signs:** Polling stops after one tick; no errors in logs.

### Pitfall 6: Manual refresh races a pending tick
**What goes wrong:** User clicks "Refresh" 100ms before a scheduled tick. Without `Process.cancel_timer`, both fire — two `Health.trigger_coverage/1` calls in quick succession. Probably OK on a small DB but pathological on a 10k-table schema.
**Why it happens:** Storing the timer ref but never canceling on manual refresh.
**How to avoid:** D-30b — `handle_event("refresh", _, socket) do Process.cancel_timer(socket.assigns.threadline_timer_ref); … end`. `cancel_timer` is idempotent on a fired timer (returns `false`), so it's safe to call unconditionally.
**Warning signs:** Two telemetry events within ~100ms after a manual refresh click.

### Pitfall 7: `live_session` `on_mount` order matters
**What goes wrong:** If `Coverage.OnMount` runs BEFORE `Auth`, `socket.assigns[:threadline_repo]` is nil and `Health.trigger_coverage(repo: nil)` raises `KeyError`.
**Why it happens:** `live_session` runs `on_mount` callbacks in list order; the v1.17 router only had `[{Auth, opts}]`, so this is a new precedent.
**How to avoid:** D-30 locks order: `on_mount: [{Auth, opts}, {Coverage.OnMount, opts}]`. Document in `Coverage.OnMount` `@moduledoc`. Add an integration test that covers an adopter who supplies `:authorize_fn`-with-scope AND mounts the surface — assert `:threadline_coverage` is set on first render.
**Warning signs:** First render of any LV in the session blows up with `KeyError: key :threadline_repo not found`.

### Pitfall 8: `Mix.Task.run/2` no-op on second test invocation
**What goes wrong:** `Mix.Task.run/2` is single-OS-process; subsequent test cases silently get an empty output.
**Why it happens:** Mix-internal task-already-run cache.
**How to avoid:** `Mix.Task.reenable("threadline.health.coverage")` in `setup` block; or use `Mix.Task.rerun/2`. Same gotcha Phase 65's parity test hit.
**Warning signs:** Second test case in the same module silently passes with empty stdout.

### Pitfall 9: `Application.get_env(:threadline, :health, [])` returning a non-keyword
**What goes wrong:** An adopter writes `config :threadline, :health, %{expected_uncovered_tables: ["foo"]}` (map instead of keyword) — `Keyword.get/3` returns nil, the baseline-only path executes silently, and the adopter wonders why their config doesn't take effect.
**Why it happens:** Lax config conventions in Elixir.
**How to avoid:** `Threadline.Health.Policy.validate!/1` is called at start time (host's `application.ex`) OR lazily inside `compute_expected_uncovered/0` with a clear `raise ArgumentError` on non-keyword input. Add a doc-contract test that pins the recommended `Threadline.Health.Policy.validate!(Application.get_env(:threadline, :health, []))` call site in the README.
**Warning signs:** Adopter says "I added `:expected_uncovered_tables` and the dashboard still shows the table as uncovered."

### Pitfall 10: TimelineLive's existing `Threadline.Health.trigger_coverage(repo: repo)` datalist call returns the third bucket
**What goes wrong:** The Phase 64 datalist code at `timeline_live.ex:30-35` does `Enum.flat_map/2` with `{:covered, name} -> [name]; _ -> []`. The new `{:expected_uncovered, name}` tuples fall through `_ -> []`, which is correct — they shouldn't appear in the autocomplete because nobody can filter timeline rows by an UNCAPTURED table. But this needs a regression test to prove.
**Why it happens:** Easy to miss the implicit fall-through guarantee.
**How to avoid:** Add a test case to `timeline_live_test.exs` that mocks `trigger_coverage/1` to return all three tuple variants and asserts the datalist contains only the `{:covered, _}` names.
**Warning signs:** `expected_uncovered` table names suddenly appear in the timeline filter datalist after Phase 66 ships.

### Pitfall 11: `mix verify.compile_no_optional` regression
**What goes wrong:** A Phase 66 file forgets the file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule … end end` wrapper. `mix verify.compile_no_optional` fails at CI on the GitHub Actions stable-id job.
**Why it happens:** Routine; the wrapper is easy to forget.
**How to avoid:** Doc-contract test asserts `String.starts_with?(File.read!("lib/threadline/operator_surface/coverage/on_mount.ex"), "if Code.ensure_loaded?(Phoenix.LiveView)")` (and same for `surface_header.ex` + `coverage_live.ex`). Mix task and `Health.Policy` are explicitly NOT gated (pure stdlib).
**Warning signs:** GitHub Actions `verify-compile-no-optional` job turns red.

### Pitfall 12: `Threadline.Health.Policy.validate!/1` is silently lazy
**What goes wrong:** If validation only happens at `compute_expected_uncovered/0` call time (i.e. inside `trigger_coverage/1`), bad config raises at the FIRST poll tick instead of at app boot. A 10-minute delay between `mix release` and the first dashboard tick is enough to hide the bug.
**Why it happens:** Easier to write the lazy validator than to require explicit boot-time invocation.
**How to avoid:** Document the recommended call site in the README quickstart: `Threadline.Health.Policy.validate!(Application.get_env(:threadline, :health, []))` in the host's `application.ex` `start/2`. Add a doc-contract test for the snippet. Guide-section copy: "validate at boot or lazy at first poll, your choice — but at minimum, validate at boot in production."
**Warning signs:** Production config error caught only after the first dashboard tick fires.

### Pitfall 13: Timing-dependent test flakiness with `Process.send_after`
**What goes wrong:** Test does `live(conn, "/audit/coverage")`, sleeps 100ms, asserts the badge re-renders with new data. CI is slow; the assertion fires before the tick. Test is flaky.
**Why it happens:** Real-time scheduling in tests.
**How to avoid:** In tests, set `:threadline_coverage_poll_ms` to a low value (e.g. via socket assign or the `:threadline` Application env in test setup) AND use `LiveView.assert_redirect`-style polling helpers OR inject the timer ref via the on_mount opts so the test can `send(pid, :threadline_refresh_coverage)` directly. RECOMMENDATION: expose a test seam — `Coverage.OnMount` reads its interval from `Application.get_env(:threadline, :coverage_poll_ms, 30_000)` so test setup can set it once.
**Warning signs:** `coverage_live_test.exs` flakes intermittently.

### Pitfall 14: Empty-schema render is confusing
**What goes wrong:** A fresh adopter mounts the surface but hasn't run `mix threadline.gen.triggers` yet — `trigger_coverage/1` returns `[{:uncovered, "users"}, {:uncovered, "posts"}, …]`. The dashboard shows a wall of red and the surface badge says "N uncovered" everywhere — useful, but disorienting on day one.
**Why it happens:** Loud-confirmation UX is correct (D-31a) but the empty-state for "no triggers installed yet" is undercommunicated.
**How to avoid:** Empty-state copy in `CoverageLive` when ALL tables are uncovered: `"No audited tables found for schema 'X'. Run mix threadline.gen.triggers to set up capture."` (UI-SPEC §"Empty state"). Surface header still shows "N uncovered" — accurate. Add to `guides/operator-surface.md` first-mount expectations.
**Warning signs:** New adopters file issues like "the dashboard is stuck on red."

## Validation Architecture

> Validation Architecture per Nyquist 8-dimension framework. `workflow.nyquist_validation` is absent in `.planning/config.json` → treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit 1.15+ (bundled with Elixir) + `Phoenix.LiveViewTest` |
| Config file | `mix.exs` aliases (`verify.test`, `verify.compile_no_optional`, `ci.all`); `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/health_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs --trace` |
| Full suite command | `mix test` (or `mix verify.test`) |
| Compile-no-optional | `mix verify.compile_no_optional` |
| Full CI | `mix ci.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COV-01 | LV at `/audit/coverage` renders three buckets (covered / uncovered / expected) | LV integration | `mix test test/threadline/operator_surface/live/coverage_live_test.exs -x` | ❌ Wave 0 |
| COV-01 | Surface header pill renders on Timeline / Transaction / Actor with same `uncovered_count` | LV integration | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/transaction_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs -x` | Partial (extend existing) |
| COV-01 | Surface header literal `"All covered"` when uncovered == 0 | doc-contract | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs:<line>` | ❌ Wave 0 |
| COV-01 | Three badge state literals `"covered"` / `"uncovered"` / `"expected"` | doc-contract | same as above | ❌ Wave 0 |
| COV-02 | `Threadline.Health.trigger_coverage/1` accepts `:schema` opt; default `"public"` | unit | `mix test test/threadline/health_test.exs -x` | Partial (extend existing) |
| COV-02 | Both inner SQL queries are parameterized (no string interpolation of schema) | doc-contract refute | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs:<line>` | ❌ Wave 0 |
| COV-02 | `pg_namespace` join filter prevents cross-schema trigger leak | unit (DB-touching) | `mix test test/threadline/health_test.exs:<line> --include schema_isolation` | ❌ Wave 0 |
| COV-02 | LV refreshes every 30s by default; configurable via `config :threadline, :coverage_poll_ms` | LV integration with low interval | `mix test test/threadline/operator_surface/live/coverage_live_test.exs:<line>` | ❌ Wave 0 |
| COV-02 | Floor 5_000 ms — raises below | unit | `mix test test/threadline/operator_surface/coverage/on_mount_test.exs` | ❌ Wave 0 |
| COV-02 | `[:threadline, :health, :checked]` event metadata gains `expected_uncovered`; existing `covered`/`uncovered` measurements unchanged | unit (telemetry attach) | `mix test test/threadline/health_test.exs:<line>` | Partial (extend existing) |
| COV-02 | `[:threadline, :health, :checked, :error]` fires on poll failure | LV integration with mocked failure | `mix test test/threadline/operator_surface/live/coverage_live_test.exs:<line>` | ❌ Wave 0 |
| COV-02 | On poll error, last-good assign preserved; ALWAYS reschedule | LV integration | same | ❌ Wave 0 |
| COV-02 | `?schema=NAME` URL validation: regex pre-check + `pg_namespace` lookup; bad input → `:form_error` | LV integration | same | ❌ Wave 0 |
| COV-02 | `?schema=` parameterized into SQL (refute interpolation) | doc-contract refute | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs:<line>` | ❌ Wave 0 |
| COV-03 | `mix threadline.health.coverage` default table format prints three sections + footer | Mix integration | `mix test test/threadline/operator_surface/coverage_mix_test.exs:<line>` | ❌ Wave 0 |
| COV-03 | `mix threadline.health.coverage --json` produces valid JSON with exact key set | Mix integration | same | ❌ Wave 0 |
| COV-03 | `mix threadline.health.coverage --schema=NAME` validation parity with LV | Mix integration | same | ❌ Wave 0 |
| COV-03 | Mix task exits 0 even when uncovered tables exist (viewer, not gate) | Mix integration | same | ❌ Wave 0 |
| COV-03 | `mix threadline.verify_coverage --schema=NAME` (additive flag) — default behavior unchanged | Mix integration | `mix test test/threadline/verify_coverage_task_test.exs` | Partial (extend existing) |
| COV-03 | doc-contract test pins LV route literal | doc-contract | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs:<line>` | ❌ Wave 0 |
| COV-03 | doc-contract test pins Mix-task help text | doc-contract | same | ❌ Wave 0 |
| COV-03 | doc-contract test pins JSON output schema (top-level keys + entry keys + source enum) | doc-contract | same | ❌ Wave 0 |
| COV-03 | doc-contract test pins hardcoded baseline literal `~w(schema_migrations)` | doc-contract | same | ❌ Wave 0 |
| COV-03 | doc-contract test refutes `String.to_atom\b` over CoverageLive + Mix task | doc-contract refute | same | ❌ Wave 0 |
| COV-03 | `mix verify.compile_no_optional` stays green | CI | `mix verify.compile_no_optional` | Existing |
| COV-03 | `mix ci.all` stays green | CI | `mix ci.all` | Existing |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/health_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs --trace`
- **Per wave merge:** `mix test test/threadline/health_test.exs test/threadline/operator_surface/ --trace` (full operator-surface suite + Health unit tests)
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/threadline/operator_surface/coverage_doc_contract_test.exs` — covers COV-01 / COV-02 / COV-03 literal pinning
- [ ] `test/threadline/operator_surface/live/coverage_live_test.exs` — covers COV-01 mount, COV-02 poll + manual refresh + `?schema=`, COV-02 on-error UX
- [ ] `test/threadline/operator_surface/coverage_mix_test.exs` — covers COV-03 default + `--json` + `--schema=NAME`
- [ ] `test/threadline/operator_surface/coverage/on_mount_test.exs` — covers COV-02 floor 5_000ms validation, schedule shape
- [ ] Extension to `test/threadline/health_test.exs` — covers COV-02 `:schema` opt, three-bucket return shape, telemetry shape change, schema-isolation regression test
- [ ] Extension to `test/threadline/operator_surface/live/{timeline,transaction,actor}_live_test.exs` — covers COV-01 surface header rendering on sibling LVs

*All Wave 0 gaps are NEW test files or extensions — no framework install needed; ExUnit + Phoenix.LiveViewTest are already configured for the project.*

### Validation Dimensions (Nyquist 8)

| Dimension | Coverage in Phase 66 |
|-----------|----------------------|
| **D1 Behavioral correctness** | LV integration tests for mount + refresh + `?schema=` + manual refresh; unit tests for `Health.trigger_coverage/1` three-bucket return + `:schema` opt; Mix-task integration tests. |
| **D2 Contract / API stability** | Doc-contract test (COV-03 anchor) pins LV route literal, Mix-task help text + flags, `--json` schema, three badge literals, hardcoded baseline literal. Pure source-reading; CI fails on any literal drift. |
| **D3 Backward compatibility** | Two existing pattern-match callsites (`Continuity.assert_capture_ready!/2`, TimelineLive datalist) verified by existing tests. Telemetry shape change is additive; one-clause case extension to `Verify.CoveragePolicy.violations/2`. |
| **D4 Security / safety** | Atom-safety refute (`String.to_atom\b` regex refute over CoverageLive + Mix task); SQL injection refute (`'#{` substring refute over `health.ex`); two-layer schema validation (regex + `pg_namespace` parameterized lookup); read-only ceiling preserved (no runtime policy edits). |
| **D5 Observability** | `[:threadline, :health, :checked]` metadata gains `expected_uncovered` (additive); new `[:threadline, :health, :checked, :error]` event for D-30c poll failures; both telemetry-asserted in tests. |
| **D6 Performance** | Floor 5_000ms on poll interval; capped per-LV cost (two `pg_*` queries are bounded sub-second on normal schemas); per-LV polling at N≈10 tabs realistic ceiling. (No formal perf test — out of v1.18 scope, observable via the existing `:health, :checked` event timing.) |
| **D7 Operational hygiene** | `mix verify.compile_no_optional` stays green (CI assertion); GitHub Actions stable job IDs unchanged; `phoenix_pubsub` stays `optional: true`; `mix ci.all` end-to-end exercise. |
| **D8 Documentation** | `guides/operator-surface.md` `## Coverage dashboard` section; `guides/domain-reference.md` `## Trigger coverage (operational)` update; `CHANGELOG.md` v1.18 entry; doc-contract test for README + Mix-task help; recommended boot-time `Health.Policy.validate!/1` call site documented. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All Phase 66 code | ✓ | 1.18+ (CLAUDE.md `~> 1.15`) | — |
| PostgreSQL | `pg_namespace`, `pg_trigger`, `pg_class`, `pg_tables` introspection | ✓ (test config) | 12+ (Threadline lib floor; CONTEXT.md does not bump) | — |
| `phoenix_live_view` (optional dep) | LV-side surfaces | ✓ (already declared `~> 1.0`) | ~> 1.0 | Capture-only adopters compile cleanly without it; Mix task is the parity surface. |
| `phoenix` (optional dep) | The `live_session` macro | ✓ (already declared `~> 1.7`) | ~> 1.7 | Same as above. |
| `Jason` | `--json` Mix-task output | ✓ (HARD dep `~> 1.4`) | ~> 1.4 | — |
| `Ecto.SQL` | All `pg_*` introspection | ✓ (HARD dep `~> 3.10`) | ~> 3.10 | — |

**Missing dependencies with no fallback:** none.

**Missing dependencies with fallback:** none — every dep is already available in the appropriate optional/hard envelope.

## Security Domain

> `security_enforcement` is not explicitly disabled in `.planning/config.json` → enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuses Phase 57 / v1.17 `:authorize_fn` contract via `Threadline.OperatorSurface.Auth.on_mount/4`; Phase 66's `Coverage.OnMount` runs AFTER Auth in the `on_mount` chain. |
| V3 Session Management | yes | Reuses Phase 57 / v1.17 `live_session` `:threadline` semantics; no new session model. |
| V4 Access Control | yes | The `Auth.on_mount/4` v1.17 contract still applies — `:authorize_fn`-returned scope is on `socket.assigns[:threadline_scope]`. Coverage data is GLOBAL (single trust boundary per Threadline lib), so coverage queries do NOT need scope filtering. Document this explicitly in `Coverage.OnMount` `@moduledoc`. |
| V5 Input Validation | yes | `?schema=NAME` URL param + `--schema=NAME` Mix flag — two-layer regex `~r/\A[a-z_][a-z0-9_]{0,62}\z/` + `pg_namespace` parameterized lookup at the LV/Mix EDGE (D-33a). |
| V6 Cryptography | no | No crypto in scope. |

### Known Threat Patterns for Phoenix LiveView + Ecto + PostgreSQL stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via `:schema` interpolation | Tampering | Parameterized `$1` binds in BOTH inner SQL queries; doc-contract refute on `'#{` substring; PROHIBITED to interpolate schema names into SQL strings. |
| Atom table exhaustion via `?schema=NAME` | DoS | NEVER call `String.to_atom/1` on the schema param; doc-contract refute on `String.to_atom\b` regex over CoverageLive + Mix task. |
| Unrestricted schema enumeration | Information disclosure | The `pg_namespace` lookup is a YES/NO oracle; an attacker can't enumerate all schemas, only confirm/deny one at a time. The error message says "Schema 'X' not found" which leaks no information beyond what was already supplied. |
| Bypass of `:authorize_fn` via `Coverage.OnMount` | Spoofing | Coverage.OnMount runs AFTER Auth; if Auth halts, Coverage.OnMount never runs. Document explicitly. |
| Surface header pill leaking covered counts to unauthorized users | Information disclosure | Surface header is rendered ONLY inside the `live_session :threadline` block, which is gated by Auth's `:authorize_fn`. No render path bypasses Auth. |
| Runtime policy edits via the LV | Tampering | Read-only ceiling holds (CONTEXT.md / REQUIREMENTS.md "Out of Scope" — no runtime policy edits from any viewer). The dashboard renders config; never mutates. |
| Manual-refresh DoS | DoS | Manual refresh is rate-limited only by user click latency. The two `pg_*` queries are bounded sub-second; per-LV blast radius is bounded. Consider adding a simple `phx-throttle="500"` on the refresh anchor (Claude's discretion). |

## Code Examples

### Example 1: Verified pg_namespace lookup (D-33a)

```elixir
# Source: lib/threadline/continuity.ex:80-89 (existing precedent for parameterized pg_* lookup)
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

The Phase 66 `pg_namespace` lookup follows the same shape:

```elixir
defp schema_exists?(repo, schema) do
  %{rows: rows} =
    Ecto.Adapters.SQL.query!(
      repo,
      "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1",
      [schema]
    )

  rows != []
end
```

### Example 2: Existing telemetry attach (regression test pattern)

```elixir
# Source: test/threadline/health_test.exs:40-58 (existing pattern)
test "trigger_coverage/1 emits :health, :checked event" do
  :telemetry.attach(
    "test-health-checked",
    [:threadline, :health, :checked],
    fn _name, measurements, _meta, pid -> send(pid, {:telemetry, measurements}) end,
    self()
  )

  on_exit(fn -> :telemetry.detach("test-health-checked") end)

  Threadline.Health.trigger_coverage(repo: @repo)

  assert_receive {:telemetry, %{covered: covered, uncovered: uncovered}}
  assert is_integer(covered)
  assert is_integer(uncovered)
end
```

Phase 66 EXTENDS to:

```elixir
assert_receive {:telemetry, %{covered: covered, uncovered: uncovered, expected_uncovered: expected}}
assert is_integer(covered)
assert is_integer(uncovered)
assert is_integer(expected)
```

(plus a new test for the error-event sibling.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded `'public'` literal in coverage SQL | Parameterized `:schema` opt with `pg_namespace` join | Phase 66 (D-33c) | Non-`public` schema adopters get correct results; cross-schema trigger leak fixed. |
| Two-tuple `{:covered \| :uncovered, name}` return | Three-tuple `{:covered \| :uncovered \| :expected_uncovered, name}` | Phase 66 (D-32) | Adopters' `schema_migrations` no longer surfaces as drift on day one; configurable for `oban_*` etc. |
| Per-LV `handle_info` boilerplate (hypothetical) | `attach_hook(:handle_info, ...)` in shared on_mount | Phoenix.LiveView 0.18+; Phase 66 first applies in this codebase | Zero per-LV boilerplate for cross-LV polling. |
| `live_dashboard`-style central PageLive | Per-LV `Process.send_after` driven by `live_session` `on_mount` hook | Phase 66 (D-30) | No central process; no PubSub dep; `phoenix_pubsub` stays `optional: true`. |
| Inline `'public'` validation at lib edge | Two-layer regex + `pg_namespace` parameterized lookup at LV/Mix edge | Phase 66 (D-33a) | Defense-in-depth; lib API stays thin; both surfaces share validation contract. |

**Deprecated/outdated:** none from this phase. Existing `:health, :checked` event remains the canonical hook; metadata grows additively.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Phoenix.LiveView.attach_hook/4` is the correct primitive for shared `:handle_info` interception across all LVs in a `live_session` block | Pattern 1, "Don't Hand-Roll" | If `attach_hook` doesn't propagate via `live_session` `on_mount` callbacks, fall back to per-LV `handle_info` clauses (still works, more boilerplate). VERIFIED via Phoenix.LiveView docs. |
| A2 | `Threadline.Continuity.assert_capture_ready!/2`'s `if {:covered, table_name} in coverage do` membership test continues to work with the additive third tuple | "Backward compatibility ceiling" | If Erlang `in` semantics change for tuple lists (they won't), the test would silently fail. Existing test in `test/threadline/continuity_test.exs` would catch any regression. VERIFIED via reading source. |
| A3 | Setting `Application.get_env(:threadline, :coverage_poll_ms, ...)` low (e.g. `100`) at test setup is sufficient to drive deterministic polling in LV integration tests | "Pitfall 13" | If `Application.put_env`-based test seam doesn't propagate to a fresh LV process, the test must use `send/2` directly. ASSUMED based on standard Elixir test idioms; needs verification in Wave 1. |
| A4 | `:slow` tag added to LV integration tests is NOT in the existing `mix test --exclude :slow` configuration | "Honest default tests" / "Validation Architecture" | If the existing `:slow` exclude blocks LV tests from running by default, CI is dishonest. CHECK during Wave 0 by reading `test/test_helper.exs` and `mix.exs`. ASSUMED based on CLAUDE.md "honest default tests" principle. |

**If this table is empty:** All claims in this research were verified or cited. (Not the case — A3 and A4 need Wave 0 confirmation.)

## Open Questions (RESOLVED)

1. **Should `Threadline.Health.Policy.validate!/1` be invoked at boot time inside `Threadline.Health.trigger_coverage/1`, or as a documented adopter responsibility in `application.ex`?**
   - What we know: precedent (`Threadline.Capture.RedactionPolicy.validate!/1`) is invoked at codegen time (`mix threadline.gen.triggers`), not at app boot.
   - What's unclear: a runtime policy that's only validated lazily delays config errors to first-poll; explicit boot-time invocation is more surgical.
   - RESOLVED — Recommendation: validate LAZILY inside `compute_expected_uncovered/0` (so the LV poll-error UX surfaces it as a `:threadline_coverage_error`), AND document the recommended boot-time call in `guides/operator-surface.md`. Two layers; the first is the safety net, the second is the polish.

2. **Should the surface header link `<a href={…}>` use `phx-throttle` to dampen rapid re-clicks during transient failure?**
   - What we know: D-30b says manual refresh lives only on CoverageLive; the surface header is just a navigation anchor.
   - What's unclear: a confused operator might rapid-click the header pill if the dashboard is slow.
   - RESOLVED — Recommendation: the header is a plain anchor (D-31d); the destination LV (CoverageLive) handles its own throttle on the manual-refresh button. No additional throttle needed on the header.

## Sources

### Primary (HIGH confidence)

- [VERIFIED via local code reading]
  - `lib/threadline/health.ex:1-72` — current `trigger_coverage/1` implementation; SQL queries; `@audit_tables` exclusion
  - `lib/threadline/telemetry.ex:1-67` — current `emit_health_checked/2` shape; existing event tree
  - `lib/threadline/operator_surface/auth.ex:1-64` — `on_mount/4` precedent; file-scope `Phoenix.LiveView` gating
  - `lib/threadline/operator_surface/router.ex:1-115` — current `live_session :threadline` block; macro mount precedent
  - `lib/threadline/operator_surface/style.ex:1-256` — `.threadline-ui` CSS namespace; existing `.timeline-toolbar` rule
  - `lib/threadline/operator_surface/live/timeline_live.ex:1-280` — Phase 64/65 LV shape; existing `trigger_coverage/1` datalist call
  - `lib/threadline/operator_surface/live/transaction_live.ex:1-120` — render shape; `<div class="threadline-ui">` wrapper
  - `lib/threadline/operator_surface/live/actor_live.ex:1-80` — render shape parity
  - `lib/threadline/capture/redaction_policy.ex:1-78` — `validate!/1` precedent
  - `lib/threadline/verify/coverage_policy.ex:1-51` — current `violations/2` clauses
  - `lib/threadline/continuity.ex:50-89` — `{:covered, name}` membership test backward-compat consumer; `public_table_exists?/2` parameterized-lookup precedent
  - `lib/mix/tasks/threadline.verify_coverage.ex:1-153` — sibling Mix task; boot sequence; `print_report/3` table-formatting precedent
  - `lib/mix/tasks/threadline.export.ex:1-120` — `OptionParser.parse/2` precedent; flag-mapping shape
  - `lib/threadline/operator_surface/exports/filter_params.ex:1-173` — Phase 65 atom-safety precedent
  - `lib/threadline/operator_surface/exports/filename.ex:1-46` — `Calendar.strftime/2` precedent; pure-stdlib helper shape
  - `lib/mix.exs:48-73` — optional vs hard dep envelope; `verify.compile_no_optional` alias
  - `test/threadline/health_test.exs:1-59` — existing telemetry attach + match? test patterns
  - `test/threadline/operator_surface/timeline_browse_doc_contract_test.exs:1-90` — pure source-reading doc-contract test precedent
  - `test/threadline/operator_surface/live/timeline_live_test.exs:1-90` — nested test-Endpoint shape precedent
  - `test/support/data_case.ex:1-30` — async: false convention; FK-order delete_all cleanup
  - `.planning/phases/64-raw-timeline-browse-and-filter-form/64-RESEARCH.md` (lines 1-60) — datetime-local normalization shape; `validate_timeline_filters!/1` shared literal
  - `.planning/phases/65-exports-ui-parity/65-RESEARCH.md` (lines 1-200) — atom-safety pitfall (Pitfall 11); `Mix.Task.rerun/2` gotcha (Pitfall 8); chunked-stream literal pinning pattern

### Secondary (MEDIUM confidence)

- [CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#attach_hook/4] — `attach_hook(name, stage, fun)` API for cross-LV `:handle_info` interception
- [CITED: hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#on_mount/1] — `on_mount` hook semantics in `live_session`
- [CITED: hexdocs.pm/elixir/Process.html#send_after/3] — `Process.send_after/3` + `Process.cancel_timer/1` semantics
- [CITED: hexdocs.pm/mix/Mix.Task.html#rerun/2] — Mix task re-enable + run pattern
- [CITED: postgresql.org/docs/current/catalog-pg-namespace.html] — `pg_namespace.nspname` is the canonical schema-name column for `pg_class.relnamespace` joins
- [CITED: postgresql.org/docs/current/catalog-pg-trigger.html] — `pg_trigger.tgrelid` joins to `pg_class.oid`; namespace filter requires `pg_namespace` join

### Tertiary (LOW confidence)

- [ASSUMED] — Phoenix LiveDashboard's `PageLive` uses `Process.send_after(self(), :refresh, n)` with a configurable interval (CONTEXT.md "Idiomatic peer projects" reference; not directly verified in this session)
- [ASSUMED] — `phx.gen.auth`'s `UserAuth` module shape is the exact precedent for shared on_mount assigns (CONTEXT.md reference; not directly verified)

## Metadata

**Confidence breakdown:**
- Existing-code reuse / extension: **HIGH** — every load-bearing module read; backward-compat consumers verified by grep
- Standard stack: **HIGH** — every dep version verified against `mix.exs`; no new deps
- Architecture (D-30 polling shape): **HIGH** — `attach_hook` is the documented LiveView primitive for this exact case; CONTEXT.md is exhaustive
- Architecture (third bucket return shape): **HIGH** — additive change verified against all four pattern-match callsites
- Failure modes / pitfalls: **HIGH** — 14 named pitfalls grounded in either CONTEXT.md decisions or carry-forward from Phase 64/65 patterns
- Validation architecture: **HIGH** — every COV-NN requirement mapped to a concrete test command + Wave 0 gap

**Research date:** 2026-05-07
**Valid until:** 2026-06-07 (30 days; codebase is stable, dependencies are pinned, no fast-moving external libraries in this phase)

## RESEARCH COMPLETE
