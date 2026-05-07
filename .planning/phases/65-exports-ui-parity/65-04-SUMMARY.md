---
phase: 65-exports-ui-parity
plan: 04
subsystem: testing
tags: [elixir, exunit, doc-contract, phoenix-conntest, integration-test, mix-task-parity, byte-equality]

# Dependency graph
requires:
  - phase: 65-01
    provides: "Threadline.OperatorSurface.Exports.{Filename, FilterParams} pure-stdlib helpers + Threadline.Export.count_matching/2 :cap opt"
  - phase: 65-02
    provides: "ExportController + ExportAuthPlug + router macro sibling /exports scope; three additive Threadline.Export public helpers (format_changes_iodata/3, csv_header/1, stream_export_rows/2)"
  - phase: 65-03
    provides: "TimelineLive renders Download CSV/JSON/NDJSON anchors + count status line + truncation banner; FilterParams delegation (seven private parser helpers REMOVED)"
provides:
  - "test/threadline/operator_surface/exports_doc_contract_test.exs — pure source-reading test (async: true) pinning all EXPO-05 literals across router.ex, timeline_live.ex, export_controller.ex, export_auth_plug.ex, filename.ex, filter_params.ex"
  - "test/threadline/operator_surface/controllers/export_controller_test.exs — Phoenix.ConnTest integration test (async: false) with nested test-Endpoint, six cases covering all three iodata happy-paths + chunked path at 5,001 rows + 422 invalid-filter + empty-window header-only CSV"
  - "test/threadline/operator_surface/exports_mix_parity_test.exs — D-28 byte-equality test (async: false) comparing Mix-task and controller output across all three formats with Mix.Task.reenable in setup"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure source-reading doc-contract test (File.read! + String.contains? + Regex.scan; no AST walking — Footgun F-11)"
    - "Phoenix.ConnTest integration test with nested test-Endpoint mirroring timeline_live_test.exs:1-60 shape; outermost wrapper gates on Phoenix.Controller; FK-order Repo.delete_all cleanup in setup (Threadline does NOT use SQL Sandbox)"
    - "Mix-task vs controller byte-equality parity: Mix.Task.reenable in setup so each test case can re-invoke; String.slice(0..15) converts Mix's full ISO-Z to controller's datetime-local format"
    - "Code.require_file/1 from a sibling test file so a parity test that depends on another test module's Endpoint can run in isolation"
    - "JSON-wrapped byte-equality with generated_at timestamp normalization via Regex.replace (timestamp is intentional audit-trail provenance metadata; structural equality is the parity contract, not raw bytes)"
    - "@tag :slow on the chunked test only; NOT in mix test exclude list (OSS DNA 'honest default tests')"

key-files:
  created:
    - test/threadline/operator_surface/exports_doc_contract_test.exs
    - test/threadline/operator_surface/controllers/export_controller_test.exs
    - test/threadline/operator_surface/exports_mix_parity_test.exs
  modified: []

key-decisions:
  - "Doc-contract test download-anchor regex switched from [^}]+ to non-greedy .+? — the plan-supplied regex did not match because Elixir interpolation `#{@base_path}` inside the href brace-block contains `}` characters."
  - "Controller integration test required `import Plug.Conn, only: [get_resp_header: 2]` — Phoenix.ConnTest does not re-export get_resp_header/2; without the import, content-type/Content-Disposition/Cache-Control assertions fail at compile time."
  - "Parity test calls Code.require_file('controllers/export_controller_test.exs', __DIR__) so its references to ExportControllerTest.Endpoint resolve when the file is run in isolation — `mix test test/threadline/operator_surface/exports_mix_parity_test.exs` would otherwise fail because the sibling file is not auto-loaded."
  - "Wrapped-JSON parity uses structural equality (strip `generated_at` ISO timestamp before comparison) — the timestamp is captured at format time via DateTime.utc_now() (lib/threadline/export.ex:434) and intentionally differs by microseconds between Mix-task and controller calls. CSV and NDJSON parity remain raw byte equality because those formats have no timestamp."

patterns-established:
  - "Doc-contract regex must use .+? rather than [^}]+ when matching across Elixir interpolation: brace-block contents include literal `}` from `#{...}` interpolation closers."
  - "Test files that reference modules defined in a sibling test file should call Code.require_file/1 at file top so the test runs identically in isolation and as part of the full suite."
  - "Parity tests against timestamped output normalize the timestamp before comparison; the timestamp's existence is asserted separately so a regression that drops it is caught."

requirements-completed: [EXPO-05]

# Metrics
duration: ~6 min
completed: 2026-05-07
---

# Phase 65 Plan 04: Exports UI Parity — EXPO-05 Test Trifecta Summary

**Three new test files locking the EXPO-03 + EXPO-04 surface from Plans 02 and 03 in place: (1) pure source-reading doc-contract test with 33 assertions across 11 describe blocks pinning button labels, route literals, content-type literals, filename helper output, file-scope optional-deps gates, chunked-stream pattern literals, count-line + banner literals, atom-safety refutations, Phase 64 phx-change carry-forward, and telemetry event reuse; (2) Phoenix.ConnTest integration test with six cases covering all three iodata happy-paths + the D-27 chunked path at 5,001 rows + 422 invalid-filter + empty-window header-only CSV; (3) Mix-task vs controller D-28 byte-equality parity test for CSV / JSON wrapped / NDJSON. ALL three deliverables address EXPO-05's load-bearing role: future edits to TimelineLive, the export controller, the router macro, the auth plug, the filename helper, OR Threadline.Export cannot drift the surface (button labels, route literals, content types, filename format, filter-key allowlist, file-scope gates) without flipping a test red.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-07T14:00:57Z
- **Completed:** 2026-05-07T14:06:48Z
- **Tasks:** 3
- **Files modified/created:** 3 (0 modified, 3 created)

## Accomplishments

- **`exports_doc_contract_test.exs` — 33 assertions across 11 describe blocks** — pure source-reading test (`use ExUnit.Case, async: true`; no DB, no LV bootup) that mirrors `timeline_browse_doc_contract_test.exs` shape. Module path constants for all six target source files (`@router_path`, `@lv_path`, `@controller_path`, `@plug_path`, `@filename_path`, `@filter_params_path`, `@query_path`). Pinning by describe block: (a) **button labels** — three `Download CSV/JSON/NDJSON` literals + non-greedy regex match for the three `<.link href={...} download` anchors (PR #2611 / Pitfall 9); (b) **route literals** — three `/changes.csv|json|ndjson` route literals + three `ExportController, :csv|:json|:ndjson` action atoms in router + `Code.ensure_loaded?(Phoenix.Controller)` guard + `plug ExportAuthPlug` mount + `alias: false, as: false` LiveDashboard hygiene; (c) **content-type literals** — three exact `text/csv; charset=utf-8` etc. + RFC 5987 `filename*=UTF-8''` dual-emit + `Cache-Control: no-store`; (d) **filename helper canonical pattern** — live execution of `Filename.for/2` against `~U[2026-05-06 12:00:00.000Z]` for CSV / JSON / NDJSON producing the canonical `threadline-changes-2026-05-06T12-00Z.{ext}`; (e) **filter-key parity** — `@allowed_timeline_filter_keys` regex extraction + cross-reference that controller-side parsing covers same keys (BROWSE-04 / D-26) + assertion BOTH `TimelineLive` AND `ExportController` reference shared `FilterParams` (Pitfall 3 / Footgun F-6); (f) **file-scope optional-deps gates** — controller + plug first-line gates on `Phoenix.Controller`; Filename + FilterParams refute `Code.ensure_loaded?` (pure stdlib — D-21); router file-scope gate on `Phoenix.LiveView` UNCHANGED; (g) **chunked-stream pattern literals** — `Stream.take(10_000)` (Pitfall 4 / F-3) + `Enum.reduce_while` (Pitfall 1 / F-1) + `Plug.Conn.chunk` reference + `{:ok, %{count: count}}` destructure (Pitfall 5 / F-5) + `cap: 10_001` opt (Plan 01); (h) **count-line and banner literals** — `match-count-status` wrapper class + band-1 informational `Large export — will stream in chunks.` em-dash literal + band-2 warning `Truncated to first 10,000 rows.` + `cap: 10_001` parity in TimelineLive; (i) **atom-safety refutations** — `String.to_atom\b` regex refute on FilterParams (with positive `String.to_existing_atom` assertion), ExportController, ExportAuthPlug (Pitfall 11); (j) **Phase 64 carry-forward** — `phx-change=` refute in TimelineLive (D-04 / F-12); (k) **telemetry event reuse** — `[:threadline, :operator_surface, :authorize]` event in plug + `%{assigns: conn.assigns}` synthetic-mirror dispatch (D-20). 33/33 assertions pass in 0.07s.

- **`controllers/export_controller_test.exs` — six integration cases** — Phoenix.ConnTest (`async: false` — Threadline does NOT use SQL Sandbox per `test/support/data_case.ex:6-10`) with nested test Layouts + Router + Endpoint mirroring `timeline_live_test.exs:1-60` shape. Outermost wrapper gates on `Phoenix.Controller`. Browser pipeline `:accepts ["html", "csv", "json"]` (extends Phase 64's `["html"]`) so `response_content_type/2` lookups succeed for `:csv` and `:json`. FK-order `Repo.delete_all` cleanup in `setup` (`AuditChange` first, `AuditTransaction` second, `Threadline.Semantics.AuditAction` last). Six cases:
  - **Case 1 — iodata CSV happy-path:** seeds 10 changes via single-row `seed_changes!/2`, GETs `/audit/exports/changes.csv?from=...&to=...&table=posts`, asserts `conn.status == 200`, `response_content_type =~ "text/csv"`, Content-Disposition matches `attachment; filename="threadline-changes-` + `filename*=UTF-8''`, Cache-Control `no-store`, no UTF-8 BOM, RFC 4180 line-count = 11 (1 header + 10 rows).
  - **Case 2 — iodata JSON wrapped:** seeds 5 changes, GETs `.json`, asserts content-type literal `application/json; charset=utf-8`, body parses via `Jason.decode/1`, decoded map has `changes` array of length 5.
  - **Case 3 — iodata NDJSON:** seeds 3 changes, GETs `.ndjson`, asserts content-type literal `application/x-ndjson; charset=utf-8`, body splits to 3 lines, each line parses via `Jason.decode/1`.
  - **Case 4 — chunked CSV path (D-27 — load-bearing):** `@tag :slow`, seeds 5,001 changes via `bulk_seed_changes!/2` (`Repo.insert_all/3` chunked at 1,000 rows per call to defend PG bind-parameter limit), GETs `.csv`, asserts `conn.status == 200`, content-type `text/csv`, **`conn.state == :chunked`** transport-state assertion (proves controller chose chunked branch), `body` line-count >= 5,001.
  - **Case 5 — 422 invalid filter:** GETs with `?from=not-a-date`, asserts `conn.status == 422`, content-type matches `text/plain`, body contains `"invalid"`.
  - **Case 6 — empty-window header-only CSV:** GETs with 1-day window + `does_not_exist` table, asserts `conn.status == 200`, body line-count == 1 (header only, RFC 4180 valid).

  6/6 cases pass in 0.7s including the chunked seeding.

- **`exports_mix_parity_test.exs` — three byte-equality cases (D-28)** — `async: false` test that exercises BOTH the Mix task AND the controller against the SAME seeded data with the SAME filters and asserts byte-identical output across all three formats. `Mix.Task.reenable("threadline.export")` in `setup` so each test case can re-invoke the Mix task (Pitfall 7 / Footgun F-4 — `Mix.Task.run/2` no-ops on second call within the same OS process). `Code.require_file("controllers/export_controller_test.exs", __DIR__)` at file top so the parity test can reference `Threadline.OperatorSurface.ExportControllerTest.Endpoint` whether the file runs alone or as part of the full suite. Reuses the Endpoint via idempotent `start_supervised/1` (returns `{:error, {:already_started, _}}` quietly when called from this second test module). Three cases (CSV / JSON wrapped / NDJSON): each seeds 20-50 rows via single-row inserts, runs `Mix.Tasks.Threadline.Export.run([...])` with full ISO-Z input format wrapped in `capture_io/1` to suppress banner chatter, GETs the controller with the SAME filter values converted to datetime-local format via `String.slice(0..15)`, asserts `mix_bytes == controller_bytes` for CSV / NDJSON or `strip_generated_at(mix_bytes) == strip_generated_at(controller_bytes)` for JSON wrapped (timestamp at `lib/threadline/export.ex:434` differs by microseconds between calls). The error message includes byte sizes so a regression hint shows what diverged. Belt + braces for JSON wrapped: assert each output independently contains `"generated_at":` so a future regression that drops the timestamp gets caught. 3/3 parity tests pass in 0.5s.

## Task Commits

1. **Task 1: `exports_doc_contract_test.exs` — pure source-reading literal pinning** — `50edc15` (test)
2. **Task 2: `controllers/export_controller_test.exs` — chunked-stream integration test (D-27)** — `750b40c` (test)
3. **Task 3: `exports_mix_parity_test.exs` — Mix-task vs controller byte-equality (D-28)** — `5fd91e9` (test)

## API Surface (final shapes)

This plan adds three test files; no production-code changes.

### `Threadline.OperatorSurface.ExportsDocContractTest`

```elixir
defmodule Threadline.OperatorSurface.ExportsDocContractTest do
  use ExUnit.Case, async: true

  @router_path "lib/threadline/operator_surface/router.ex"
  @lv_path "lib/threadline/operator_surface/live/timeline_live.ex"
  @controller_path "lib/threadline/operator_surface/controllers/export_controller.ex"
  @plug_path "lib/threadline/operator_surface/export_auth_plug.ex"
  @filename_path "lib/threadline/operator_surface/exports/filename.ex"
  @filter_params_path "lib/threadline/operator_surface/exports/filter_params.ex"
  @query_path "lib/threadline/query.ex"

  describe "button labels (D-22, D-26)"
  describe "route literals (D-19, D-26)"
  describe "content-type literals (D-26)"
  describe "filename helper canonical pattern (D-25, D-26)"
  describe "filter-key parity (D-26)"
  describe "file-scope optional-deps gates (D-21, D-29)"
  describe "chunked-stream pattern literals"
  describe "count-line and truncation banner literals (D-17, D-18)"
  describe "atom-safety refutations (Pitfall 11)"
  describe "Phase 64 carry-forward refutations"
  describe "telemetry event reuse (D-20)"
end
```

NO file-scope `Code.ensure_loaded?` wrapper — pure source-reading test, no Phoenix runtime needed. `use ExUnit.Case, async: true`.

### `Threadline.OperatorSurface.ExportControllerTest`

```elixir
if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportControllerTest.Layouts do
    use Phoenix.Component
    # root layout + 500.html
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.Router do
    use Phoenix.Router
    require Threadline.OperatorSurface.Router

    pipeline :browser do
      plug(:accepts, ["html", "csv", "json"])
      plug(:fetch_session)
    end

    scope "/" do
      pipe_through(:browser)
      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit")
    end
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest.Endpoint do
    use Phoenix.Endpoint, otp_app: :threadline
    # session, parsers, method override, head, router
  end

  defmodule Threadline.OperatorSurface.ExportControllerTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import Plug.Conn, only: [get_resp_header: 2]

    @endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint
    @repo Threadline.Test.Repo

    setup_all do
      Application.put_env(:threadline, @endpoint, [...])
      start_supervised!(@endpoint)
      :ok
    end

    setup do
      # FK-order cleanup mirrors data_case.ex
      @repo.delete_all(AuditChange)
      @repo.delete_all(AuditTransaction)
      if Code.ensure_loaded?(Threadline.Semantics.AuditAction), do: @repo.delete_all(...)
      {:ok, conn: build_conn()}
    end

    # Six tests — three iodata happy-paths + one chunked (@tag :slow) + 422 + empty-window
  end
end
```

### `Threadline.OperatorSurface.ExportsMixParityTest`

```elixir
Code.require_file("controllers/export_controller_test.exs", __DIR__)

if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportsMixParityTest do
    use ExUnit.Case, async: false
    import Phoenix.ConnTest
    import ExUnit.CaptureIO

    @endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint
    @repo Threadline.Test.Repo

    setup_all do
      _ = start_supervised(@endpoint)  # idempotent — already_started is OK
      :ok
    end

    setup do
      # FK-order cleanup
      @repo.delete_all(AuditChange)
      @repo.delete_all(AuditTransaction)
      if Code.ensure_loaded?(Threadline.Semantics.AuditAction), do: @repo.delete_all(...)
      Mix.Task.reenable("threadline.export")
      {:ok, conn: build_conn(), tmp_dir: System.tmp_dir!()}
    end

    test "CSV: Mix task and controller produce byte-identical output"
    test "JSON wrapped: Mix task and controller produce byte-identical output (modulo `generated_at`)"
    test "NDJSON: Mix task and controller produce byte-identical output"

    defp strip_generated_at(json_binary)  # Regex.replace removing "generated_at": "<ISO>" key
    defp seed_changes!(n, opts)
  end
end
```

## Verification

- `mix test test/threadline/operator_surface/exports_doc_contract_test.exs --max-failures 1` — **33/33 tests pass** in 0.07s.
- `mix test test/threadline/operator_surface/controllers/export_controller_test.exs --include slow --max-failures 1` — **6/6 tests pass** in 0.7s (including the 5,001-row chunked test).
- `mix test test/threadline/operator_surface/exports_mix_parity_test.exs --max-failures 1` — **9/9 tests pass** in 0.5s (3 parity cases + 6 cases inherited from the require_file'd Endpoint sibling).
- `mix test test/threadline/operator_surface/ --include slow --max-failures 5` — **122/122 tests pass** in 1.3s (all operator_surface tests across all phases).
- `mix verify.format` — **exits 0** (touched files formatted; pre-existing repo-wide drift in untouched files outside Phase 65 scope remains scheduled for Phase 68 ADOPT-07).
- `mix verify.compile_no_optional` — **exits 0** (the doc-contract test is pure stdlib; the integration test and parity test gate on `Phoenix.Controller` at file scope so capture-only adopters compile cleanly).
- `mix verify.test` — **413/413 tests pass** in 3.4s (1 excluded `pgbouncer_topology` tag, 1 pre-existing unused-default-arg warning in `verify_coverage_task_test.exs` — out of plan scope). Net 42 new tests since Plan 65-03's 371-test baseline (33 doc-contract + 6 controller integration + 3 parity).

Greppable invariants verified:

- `head -1 test/threadline/operator_surface/exports_doc_contract_test.exs` → `defmodule Threadline.OperatorSurface.ExportsDocContractTest do` (no file-scope gate).
- `grep -c "async: true" test/threadline/operator_surface/exports_doc_contract_test.exs` → **1**.
- `grep -c "Download CSV\|Download JSON\|Download NDJSON" test/threadline/operator_surface/exports_doc_contract_test.exs` → **3**.
- `grep -c "text/csv; charset=utf-8\|application/json; charset=utf-8\|application/x-ndjson; charset=utf-8" test/threadline/operator_surface/exports_doc_contract_test.exs` → **3**.
- `grep -c "threadline-changes-2026-05-06T12-00Z" test/threadline/operator_surface/exports_doc_contract_test.exs` → **3** (one per format).
- `grep -c "@allowed_timeline_filter_keys" test/threadline/operator_surface/exports_doc_contract_test.exs` → **2** (1 in regex literal, 1 in flunk message).
- `grep -c "Stream.take(10_000)" test/threadline/operator_surface/exports_doc_contract_test.exs` → **2** (1 String.contains?, 1 in error message).
- `grep -c "Enum.reduce_while" test/threadline/operator_surface/exports_doc_contract_test.exs` → **2** (assertion + comment).
- `grep -c "cap: 10_001" test/threadline/operator_surface/exports_doc_contract_test.exs` → **2** (controller assertion + LV assertion).
- `grep -c "if Code.ensure_loaded?(Phoenix.Controller) do" test/threadline/operator_surface/exports_doc_contract_test.exs` → **2** (controller first-line assertion + plug first-line assertion).
- `grep -E "refute.*Code.ensure_loaded" test/threadline/operator_surface/exports_doc_contract_test.exs` → **2** (Filename + FilterParams).
- `grep -c "String.to_atom" test/threadline/operator_surface/exports_doc_contract_test.exs` → **6** (three refutes + assertion text + atom-leak comment + Pitfall reference).
- `grep -c "phx-change" test/threadline/operator_surface/exports_doc_contract_test.exs` → **2** (refute + comment in describe name).
- `head -1 test/threadline/operator_surface/controllers/export_controller_test.exs` → `if Code.ensure_loaded?(Phoenix.Controller) do`.
- `grep -c "async: false" test/threadline/operator_surface/controllers/export_controller_test.exs` → **2** (use ExUnit.Case + comment).
- `grep -c "import Phoenix.ConnTest" test/threadline/operator_surface/controllers/export_controller_test.exs` → **1**.
- `grep -c "threadline_operator_surface(\"/audit\")" test/threadline/operator_surface/controllers/export_controller_test.exs` → **1**.
- `grep -c "Repo.insert_all\|@repo.insert_all" test/threadline/operator_surface/controllers/export_controller_test.exs` → **1** (in `bulk_seed_changes!/2`).
- `grep -c "delete_all(AuditChange)" test/threadline/operator_surface/controllers/export_controller_test.exs` → **1**.
- `grep -c "conn.state == :chunked" test/threadline/operator_surface/controllers/export_controller_test.exs` → **1** (D-27 chunked-path assertion).
- `grep -c "@tag :slow" test/threadline/operator_surface/controllers/export_controller_test.exs` → **1** (chunked test only).
- `grep -c '^    test "' test/threadline/operator_surface/controllers/export_controller_test.exs` → **6** (six test cases).
- `grep -c "5_001" test/threadline/operator_surface/controllers/export_controller_test.exs` → **3** (seed call + assertion + comment).
- `head -1 test/threadline/operator_surface/exports_mix_parity_test.exs` → `# Load the sibling controller test file ...` (Code.require_file preamble), then line 6 `if Code.ensure_loaded?(Phoenix.Controller) do`.
- `grep -c "async: false" test/threadline/operator_surface/exports_mix_parity_test.exs` → **2** (use + comment).
- `grep -c "Mix.Task.reenable" test/threadline/operator_surface/exports_mix_parity_test.exs` → **1** (in setup).
- `grep -c "Mix.Tasks.Threadline.Export.run" test/threadline/operator_surface/exports_mix_parity_test.exs` → **3** (one per format).
- `grep -c "File.read!(tmp_path)" test/threadline/operator_surface/exports_mix_parity_test.exs` → **3**.
- `grep -c 'test "CSV:' test/threadline/operator_surface/exports_mix_parity_test.exs` → **1**.
- `grep -c 'test "JSON wrapped' test/threadline/operator_surface/exports_mix_parity_test.exs` → **1**.
- `grep -c 'test "NDJSON' test/threadline/operator_surface/exports_mix_parity_test.exs` → **1**.
- `grep -c "String.slice(from, 0..15)\|String.slice(to, 0..15)" test/threadline/operator_surface/exports_mix_parity_test.exs` → **6** (one pair per format).
- `grep -c "ExportControllerTest.Endpoint" test/threadline/operator_surface/exports_mix_parity_test.exs` → **1** (the @endpoint module attribute).
- `grep -c "Code.require_file" test/threadline/operator_surface/exports_mix_parity_test.exs` → **1** (preamble).

## Decisions Made

- **Doc-contract download-anchor regex switched from `[^}]+` to non-greedy `.+?`** — the plan-supplied `~r/<\.link href=\{[^}]+\}\s+download[\s>]/` does not match because the LV's anchor href uses Elixir interpolation (`#{@base_path}/exports/changes.csv?#{@filter_query}`) and the inner `}` of `#{...}` triggers `[^}]+` to terminate too early. Switched to non-greedy `\{.+?\}` so the match walks across the brace-block boundary while still demanding `download` immediately after the closing `}`. The rest of the regex is preserved verbatim.
- **Controller integration test imports `Plug.Conn.get_resp_header/2` explicitly** — `Phoenix.ConnTest` provides assertion helpers like `response/2`, `response_content_type/2`, `redirected_to/2`, and `get_session/2` but does not re-export `get_resp_header/2`. The plan-supplied test stub uses `get_resp_header(conn, "...")` for the Content-Disposition / Cache-Control / content-type assertions, requiring an explicit `import Plug.Conn, only: [get_resp_header: 2]`. Without this, the test does not compile.
- **Parity test uses `Code.require_file/1` to load the sibling Endpoint** — when `mix test test/threadline/operator_surface/exports_mix_parity_test.exs` is run in isolation (the per-task verification command in the plan acceptance), the `Threadline.OperatorSurface.ExportControllerTest.Endpoint` module is not loaded because ExUnit's auto-load process only loads `test/test_helper.exs` and the explicitly-passed file. Adding `Code.require_file("controllers/export_controller_test.exs", __DIR__)` at file top compiles the sibling file's modules. When the full suite runs, `Code.require_file/1` is a no-op for already-loaded files. This pattern is preferable to either (a) duplicating the Endpoint definition in this file (would create two Endpoint modules with the same purpose), or (b) extracting the shared infrastructure to `test/support/` (would expand `mix verify.compile_no_optional` surface area).
- **Wrapped-JSON parity uses structural equality (strip `generated_at`)** — the wrapped-JSON envelope includes a `"generated_at": "<ISO-8601 microsecond timestamp>"` key (`lib/threadline/export.ex:434` — `DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.to_iso8601()`). The Mix task and the controller call this function at different microseconds, producing same-byte-size but byte-different output (the test diff: 8519 vs 8519 bytes, content differs in the timestamp). Strip the key from both outputs via `Regex.replace(~r/"generated_at":\s*"[^"]+"\s*,?\s*/, json, "")` before comparison. The key's existence is asserted separately on both outputs as a belt-and-braces guard against a future regression that drops the timestamp. CSV and NDJSON do not include this timestamp — they remain raw byte equality.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan-supplied download-anchor regex `[^}]+` does not match across Elixir interpolation in href**

- **Found during:** Task 1 verification (`mix test test/threadline/operator_surface/exports_doc_contract_test.exs`)
- **Issue:** The plan-supplied regex `~r/<\.link href=\{[^}]+\}\s+download[\s>]/` walks character-by-character through the brace-block looking for the closing `}`, but the LV's anchor href uses Elixir string interpolation: `<.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"}` — the inner `#{...}` interpolation ends with a `}` character, so `[^}]+` stops at the first `}` and the regex never matches the closing brace of the outer brace-block. Result: the plan-supplied test counted 0 anchors instead of 3, asserting `length(download_anchors) >= 3` failed.
- **Fix:** Switched to non-greedy `.+?`: `~r/<\.link href=\{.+?\}\s+download[\s>]/`. The non-greedy match still finds the FIRST `}` followed by `download`, which is the correct semantic (the anchor's brace-block closer immediately followed by the `download` HTML attribute). Three anchors match.
- **Files modified:** test/threadline/operator_surface/exports_doc_contract_test.exs (only)
- **Verification:** `mix test ...exports_doc_contract_test.exs --max-failures 3` — 33/33 tests pass; the regex matches all three anchors as intended.
- **Committed in:** 50edc15 (Task 1 commit; the regex fix is included in the initial file write — no separate fix commit needed)

**2. [Rule 3 - Blocking] Plan-supplied controller integration test missing `import Plug.Conn, only: [get_resp_header: 2]`**

- **Found during:** Task 2 first-pass compile (`mix test test/threadline/operator_surface/controllers/export_controller_test.exs`)
- **Issue:** The plan-supplied test stub uses `get_resp_header(conn, "content-disposition")`, `get_resp_header(conn, "cache-control")`, and `get_resp_header(conn, "content-type")` for the per-test header assertions. `Phoenix.ConnTest` (the only import in the plan-supplied skeleton) does not re-export `get_resp_header/2` — that function lives on `Plug.Conn`. Compile failure: `undefined function get_resp_header/2` at five call sites.
- **Fix:** Added `import Plug.Conn, only: [get_resp_header: 2]` directly under `import Phoenix.ConnTest`. Limited the import via `only:` to avoid pulling in the full Plug.Conn surface (which would mask any bug where the test inadvertently uses a Plug-level function that should have come from Phoenix).
- **Files modified:** test/threadline/operator_surface/controllers/export_controller_test.exs (only)
- **Verification:** `mix test ...export_controller_test.exs --include slow --max-failures 5` — 6/6 tests pass.
- **Committed in:** 750b40c (Task 2 commit; included in the initial file write after compile-error feedback)

**3. [Rule 1 - Bug] Plan-supplied parity test cannot run in isolation — references Endpoint defined in sibling test file**

- **Found during:** Task 3 first-pass run (`mix test test/threadline/operator_surface/exports_mix_parity_test.exs`)
- **Issue:** The plan-supplied test references `@endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint` and calls `start_supervised(@endpoint)` in `setup_all`. When `mix test` is invoked with only this file as an argument, ExUnit's auto-load process loads `test/test_helper.exs` and the explicitly-passed test file — but NOT the sibling `controllers/export_controller_test.exs` file that defines the Endpoint module. Result: `setup_all` raised `ArgumentError: The module Threadline.OperatorSurface.ExportControllerTest.Endpoint was given as a child to a supervisor but it does not exist`. The plan acceptance criterion `mix test test/threadline/operator_surface/exports_mix_parity_test.exs --max-failures 1 exits 0` could not be met.
- **Fix:** Added `Code.require_file("controllers/export_controller_test.exs", __DIR__)` at file top (line 1, before the `if Code.ensure_loaded?` wrapper). `Code.require_file/2` compiles the sibling file's modules unconditionally; when the full suite runs and the file is already loaded, `Code.require_file/1` is a no-op. Now the file runs identically in isolation and as part of the full suite. Alternative considered (and rejected): extracting the shared Endpoint to `test/support/` — would broaden `mix verify.compile_no_optional`'s surface area because `support/*.ex` files are auto-compiled regardless of test selector.
- **Files modified:** test/threadline/operator_surface/exports_mix_parity_test.exs (only — at the time the test was first written)
- **Verification:** `mix test ...exports_mix_parity_test.exs --max-failures 5` — 9/9 tests pass (3 parity cases + 6 inherited via require_file). Full suite still passes 413/413.
- **Committed in:** 5fd91e9 (Task 3 commit)

**4. [Rule 1 - Bug] Plan-supplied JSON-wrapped parity test asserts raw byte equality, but `generated_at` timestamp is captured at format time**

- **Found during:** Task 3 first-pass run (after fixing deviation #3)
- **Issue:** The plan-supplied test asserts `assert mix_bytes == controller_bytes` for all three formats. CSV and NDJSON pass — neither format includes a generation timestamp. JSON wrapped fails: `lib/threadline/export.ex:434` defines `defp generated_at_iso, do: DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.to_iso8601()`, called once per `to_json_document/2` invocation. Mix and controller call the function at different microseconds, producing same-byte-size (8519 vs 8519) but byte-different output — only the timestamp string differs. Raw byte equality is unattainable by design; the timestamp is intentional audit-trail provenance metadata that must survive future edits.
- **Fix:** Strip the `generated_at` key from both outputs before comparison: `defp strip_generated_at(json_binary), do: Regex.replace(~r/"generated_at":\s*"[^"]+"\s*,?\s*/, json_binary, "")`. The structural-equality assertion still proves the controller is a thin Plug wrapper over the same `to_json_document/2` call — `format_version`, `changes` array, per-row encoding, truncation metadata are all required to be byte-identical. Belt-and-braces: assert each output independently contains a `"generated_at":` field so a future regression that drops the field gets caught here.
- **Files modified:** test/threadline/operator_surface/exports_mix_parity_test.exs (only)
- **Verification:** `mix test ...exports_mix_parity_test.exs --max-failures 5` — 9/9 tests pass.
- **Committed in:** 5fd91e9 (Task 3 commit)

**5. [Rule 3 - Blocking] Format drift on Task 2 file after `mix verify.format` (long test description forces a multi-line wrap)**

- **Found during:** Final verification (`mix verify.format`)
- **Issue:** The first test case in `export_controller_test.exs` has a long test description (`"GET /audit/exports/changes.csv with small window returns 200 + CSV iodata"`) that, combined with the `%{conn: conn}` argument on the same line, exceeded the formatter's default 98-char line-length. `mix verify.format --check-formatted` flagged it.
- **Fix:** Ran `mix format` on the file, which reflowed the long line into a multi-line `%{conn: conn} do` form. The other five tests in the file already use the multi-line form (their descriptions span more than 98 chars), so this is a localized fix to one test case.
- **Files modified:** test/threadline/operator_surface/controllers/export_controller_test.exs (formatter-driven; one test description re-wrapped)
- **Verification:** `mix verify.format` exits 0; all 6 controller integration tests still pass.
- **Committed in:** 5fd91e9 (Task 3 commit; the format fix was bundled with the parity test commit because both edits the formatter touched landed at the same time)

---

**Total deviations:** 5 auto-fixed (3 Rule 1 bugs + 2 Rule 3 blocking issues; all in plan-supplied test stubs and all required to satisfy the per-task verification gate).
**Impact on plan:** No scope creep. All five fixes are local to the three test files this plan creates. Plan 04's intent (lock the EXPO-05 surface in place) is fully delivered; the fixes are about the test file mechanics, not the assertions.

## Issues Encountered

None beyond the five auto-fixed deviations above. No verification steps had to be retried beyond initial deviation discovery, no Mix-task regression appeared, no `mix verify.compile_no_optional` regression appeared.

## Threat Flags

None. All three new test files are read-only against existing source files (doc-contract test) or perform read-only audit-table operations (integration test + parity test). No new HTTP surface, no new auth surface, no new network calls beyond the existing controller routes Plan 02 already secured behind `ExportAuthPlug`. The integration test's nested test-Endpoint mounts the SAME `threadline_operator_surface/2` macro the production code uses, with identical authorization defaults — the test itself does not bypass auth.

## Self-Check: PASSED

All claimed files exist:

- `test/threadline/operator_surface/exports_doc_contract_test.exs` — created.
- `test/threadline/operator_surface/controllers/export_controller_test.exs` — created.
- `test/threadline/operator_surface/exports_mix_parity_test.exs` — created.

All claimed commits found in `git log`:

- `50edc15` — Task 1 (doc-contract test).
- `750b40c` — Task 2 (controller integration test).
- `5fd91e9` — Task 3 (Mix-vs-controller parity test + format-driven re-wrap of Task 2 file).

## Next-Phase Readiness

- **Phase 65 closure:** All three plans (65-02, 65-03, 65-04) plus the foundation plan (65-01) have shipped. EXPO-03, EXPO-04, EXPO-05 are all marked complete in REQUIREMENTS.md. The phase is ready for `/gsd-verify-work 65` (confirms `must_haves.truths` for all four plans hold) followed by `/gsd-complete-phase 65` (closes Phase 65; updates ROADMAP plan count + completion date).
- **Phase 66 (Coverage Dashboard):** First phase of Coverage subsystem. Will introduce `Threadline.Health.trigger_coverage/1` `:schema` opt + `mix threadline.health.coverage` parity Mix task + a coverage dashboard LV. The Phase 65 surface stays frozen; Phase 66 is a sibling LV under the same `threadline_operator_surface/2` macro.

---

*Phase: 65-exports-ui-parity*
*Completed: 2026-05-07*
