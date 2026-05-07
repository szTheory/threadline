defmodule Threadline.OperatorSurface.ExportsDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @router_path "lib/threadline/operator_surface/router.ex"
  @lv_path "lib/threadline/operator_surface/live/timeline_live.ex"
  @controller_path "lib/threadline/operator_surface/controllers/export_controller.ex"
  @plug_path "lib/threadline/operator_surface/export_auth_plug.ex"
  @filename_path "lib/threadline/operator_surface/exports/filename.ex"
  @filter_params_path "lib/threadline/operator_surface/exports/filter_params.ex"
  @query_path "lib/threadline/query.ex"

  # ---- EXPO-05: button-label literals (D-22 + D-26) ----

  describe "button labels (D-22, D-26)" do
    test "TimelineLive renders the three download button labels verbatim" do
      src = File.read!(@lv_path)
      assert String.contains?(src, "Download CSV")
      assert String.contains?(src, "Download JSON")
      assert String.contains?(src, "Download NDJSON")
    end

    test "TimelineLive download anchors include the HTML `download` attribute (PR #2611 / Pitfall 9)" do
      src = File.read!(@lv_path)
      # Each of the three anchors must have `download` as a bare HTML attribute
      # on a <.link href={...}> tag. The href value uses Elixir string
      # interpolation (`#{@base_path}` etc.), so `}` characters appear inside
      # the brace-block; match the entire anchor-line up to a bare `download`
      # token rather than walking through the brace-block.
      download_anchors = Regex.scan(~r/<\.link href=\{.+?\}\s+download[\s>]/, src)

      assert length(download_anchors) >= 3,
             "expected at least 3 anchors with `download` attribute in #{@lv_path}, got #{length(download_anchors)}"
    end
  end

  # ---- EXPO-05: route literals (per D-19, D-26) ----

  describe "route literals (D-19, D-26)" do
    test "router macro emits /exports/changes.{csv,json,ndjson} GET routes" do
      src = File.read!(@router_path)
      assert String.contains?(src, ~s|"/changes.csv"|)
      assert String.contains?(src, ~s|"/changes.json"|)
      assert String.contains?(src, ~s|"/changes.ndjson"|)
    end

    test "router macro references ExportController with three action atoms" do
      src = File.read!(@router_path)
      assert String.contains?(src, "ExportController, :csv")
      assert String.contains?(src, "ExportController, :json")
      assert String.contains?(src, "ExportController, :ndjson")
    end

    test "router macro guards the sibling export scope on Phoenix.Controller" do
      src = File.read!(@router_path)
      assert String.contains?(src, "Code.ensure_loaded?(Phoenix.Controller)")
    end

    test "router macro plug-mounts ExportAuthPlug inside the export scope (NOT a host pipeline — Footgun F-7)" do
      src = File.read!(@router_path)
      assert src =~ ~r/plug\(?\s*Threadline\.OperatorSurface\.ExportAuthPlug/
    end

    test "router macro uses LiveDashboard hygiene `alias: false, as: false`" do
      src = File.read!(@router_path)
      assert String.contains?(src, "alias: false, as: false")
    end
  end

  # ---- EXPO-05: content-type literals (D-26) ----

  describe "content-type literals (D-26)" do
    test "controller emits exact content-type literals" do
      src = File.read!(@controller_path)
      assert String.contains?(src, ~s|"text/csv; charset=utf-8"|)
      assert String.contains?(src, ~s|"application/json; charset=utf-8"|)
      assert String.contains?(src, ~s|"application/x-ndjson; charset=utf-8"|)
    end

    test "controller emits RFC 5987 dual-emit Content-Disposition" do
      src = File.read!(@controller_path)

      assert src =~ ~r/filename\*=UTF-8''/,
             "expected RFC 5987 filename*=UTF-8'' interpolation in controller source"
    end

    test "controller emits Cache-Control: no-store (audit-data hygiene)" do
      src = File.read!(@controller_path)
      assert String.contains?(src, "no-store")
    end
  end

  # ---- EXPO-05: filename helper canonical pattern (D-25, D-26) ----

  describe "filename helper canonical pattern (D-25, D-26)" do
    test "Filename.for/2 produces the canonical UTC-minute pattern for each format" do
      dt = ~U[2026-05-06 12:00:00.000Z]

      assert Threadline.OperatorSurface.Exports.Filename.for("csv", dt) ==
               "threadline-changes-2026-05-06T12-00Z.csv"

      assert Threadline.OperatorSurface.Exports.Filename.for("json", dt) ==
               "threadline-changes-2026-05-06T12-00Z.json"

      assert Threadline.OperatorSurface.Exports.Filename.for("ndjson", dt) ==
               "threadline-changes-2026-05-06T12-00Z.ndjson"
    end
  end

  # ---- EXPO-05: filter-key parity (load-bearing, D-26) ----

  describe "filter-key parity (D-26)" do
    test "controller filter-param parsing covers the same allowlist as Threadline.Query (parity guarantee)" do
      query_src = File.read!(@query_path)

      [_, allowlist_block] =
        Regex.run(~r/@allowed_timeline_filter_keys\s+~w\(([^)]+)\)a/, query_src) ||
          flunk("could not find @allowed_timeline_filter_keys in #{@query_path}")

      lib_keys =
        allowlist_block
        |> String.split()
        |> MapSet.new()
        |> MapSet.delete("repo")

      filter_params_src = File.read!(@filter_params_path)

      # actor_ref collapses from actor_kind + actor_id; assert both raw URL keys
      # are referenced where the lib key is "actor_ref".
      for key <- MapSet.to_list(lib_keys) do
        assert (key == "actor_ref" and
                  String.contains?(filter_params_src, "actor_kind") and
                  String.contains?(filter_params_src, "actor_id")) or
                 String.contains?(filter_params_src, key),
               "FilterParams source does not reference lib filter key #{inspect(key)}"
      end
    end

    test "BOTH TimelineLive AND ExportController delegate to the shared FilterParams module (Pitfall 3 / Footgun F-6)" do
      lv_src = File.read!(@lv_path)
      controller_src = File.read!(@controller_path)

      assert String.contains?(lv_src, "Threadline.OperatorSurface.Exports.FilterParams") or
               String.contains?(lv_src, "alias Threadline.OperatorSurface.Exports.FilterParams"),
             "TimelineLive must reference FilterParams (no inline parser)"

      assert String.contains?(controller_src, "FilterParams.parse") or
               String.contains?(controller_src, "FilterParams"),
             "ExportController must reference FilterParams (no inline parser)"
    end
  end

  # ---- EXPO-05: file-scope optional-deps gates (D-21, D-29) ----

  describe "file-scope optional-deps gates (D-21, D-29)" do
    test "controller is wrapped in file-scope Code.ensure_loaded?(Phoenix.Controller) gate" do
      src = File.read!(@controller_path)
      first_line = src |> String.split("\n") |> hd()

      assert first_line == "if Code.ensure_loaded?(Phoenix.Controller) do",
             "expected line 1 of #{@controller_path} to be the Phoenix.Controller file-scope gate, got: #{inspect(first_line)}"
    end

    test "auth plug is wrapped in file-scope Code.ensure_loaded?(Phoenix.Controller) gate" do
      src = File.read!(@plug_path)
      first_line = src |> String.split("\n") |> hd()

      assert first_line == "if Code.ensure_loaded?(Phoenix.Controller) do",
             "expected line 1 of #{@plug_path} to be the Phoenix.Controller file-scope gate, got: #{inspect(first_line)}"
    end

    test "Filename helper file is NOT gated on optional deps (pure stdlib — D-21)" do
      src = File.read!(@filename_path)
      refute String.contains?(src, "Code.ensure_loaded?")
    end

    test "FilterParams helper file is NOT gated on optional deps (pure stdlib — D-21)" do
      src = File.read!(@filter_params_path)
      refute String.contains?(src, "Code.ensure_loaded?")
    end

    test "router file retains its existing file-scope gate on Phoenix.LiveView (UNCHANGED)" do
      src = File.read!(@router_path)
      first_line = src |> String.split("\n") |> hd()
      assert first_line == "if Code.ensure_loaded?(Phoenix.LiveView) do"
    end
  end

  # ---- EXPO-05: chunked-stream pattern literals (Pitfalls 1, 2, 4 — Footguns F-1, F-2, F-3) ----

  describe "chunked-stream pattern literals" do
    test "controller caps the chunked path at 10,000 rows via Stream.take(10_000) (Pitfall 4 / F-3)" do
      src = File.read!(@controller_path)

      assert String.contains?(src, "Stream.take(10_000)") or
               src =~ ~r/Stream\.take\(@max_rows\)/,
             "expected Stream.take(10_000) (or Stream.take(@max_rows)) in #{@controller_path}"
    end

    test "controller uses Enum.reduce_while/3 for chunked dispatch (Pitfall 1 / F-1)" do
      src = File.read!(@controller_path)
      assert String.contains?(src, "Enum.reduce_while")
    end

    test "controller calls Plug.Conn.chunk/2 inside the reduce_while body" do
      src = File.read!(@controller_path)
      assert src =~ ~r/Plug\.Conn\.chunk|chunk\(conn,/
    end

    test "controller destructures count_matching/2 return shape (Pitfall 5 / F-5)" do
      src = File.read!(@controller_path)

      assert src =~ ~r/\{:ok,\s*%\{count:\s*count\}\}/,
             "controller must destructure {:ok, %{count: count}} from Export.count_matching/2 — never bare integer"
    end

    test "controller passes cap: 10_001 to count_matching (Plan 01's :cap opt)" do
      src = File.read!(@controller_path)
      assert src =~ ~r/cap:\s*10_001|cap:\s*@max_rows\s*\+\s*1/
    end
  end

  # ---- EXPO-05: count-line + truncation banner literals (D-17, D-18) ----

  describe "count-line and truncation banner literals (D-17, D-18)" do
    test "TimelineLive renders the count status line wrapper class" do
      src = File.read!(@lv_path)
      assert String.contains?(src, "match-count-status")
    end

    test "TimelineLive renders the band-1 informational banner literal at >5,000" do
      src = File.read!(@lv_path)
      assert String.contains?(src, "Large export — will stream in chunks.")
      assert String.contains?(src, "truncation-banner informational")
    end

    test "TimelineLive renders the band-2 warning banner literal at >=10,001" do
      src = File.read!(@lv_path)
      assert String.contains?(src, "Truncated to first 10,000 rows.")
      assert String.contains?(src, "truncation-banner warning")
    end

    test "TimelineLive uses cap: 10_001 in count_matching (matches controller cap; allows '10,000+' approximation)" do
      src = File.read!(@lv_path)
      assert String.contains?(src, "cap: 10_001")
    end
  end

  # ---- EXPO-05: atom-safety refutations (Pitfall 11) ----

  describe "atom-safety refutations (Pitfall 11)" do
    test "FilterParams source uses String.to_existing_atom (NOT String.to_atom)" do
      src = File.read!(@filter_params_path)
      assert String.contains?(src, "String.to_existing_atom")

      refute src =~ ~r/String\.to_atom\b/,
             "FilterParams must NEVER call String.to_atom — atom-table leak vector (Pitfall 11)"
    end

    test "ExportController source does NOT call String.to_atom (atom-leak vector closed)" do
      src = File.read!(@controller_path)
      refute src =~ ~r/String\.to_atom\b/
    end

    test "ExportAuthPlug source does NOT call String.to_atom (atom-leak vector closed)" do
      src = File.read!(@plug_path)
      refute src =~ ~r/String\.to_atom\b/
    end
  end

  # ---- Phase 64 carry-forward refutations (Footgun F-12) ----

  describe "Phase 64 carry-forward refutations" do
    test "TimelineLive form does NOT reintroduce phx-change (Phase 64 D-04 + Footgun F-12 stays green)" do
      src = File.read!(@lv_path)
      refute String.contains?(src, "phx-change=")
    end
  end

  # ---- EXPO-05: telemetry event reuse (D-20) ----

  describe "telemetry event reuse (D-20)" do
    test "ExportAuthPlug emits the SAME [:threadline, :operator_surface, :authorize] event the LV emits (single auth telemetry stream)" do
      src = File.read!(@plug_path)
      assert String.contains?(src, "[:threadline, :operator_surface, :authorize]")
    end

    test "ExportAuthPlug uses the synthetic %{assigns: conn.assigns} mirror to call :authorize_fn (D-20 — v1.17 contract preserved verbatim)" do
      src = File.read!(@plug_path)
      assert String.contains?(src, "%{assigns: conn.assigns}")
    end
  end
end
