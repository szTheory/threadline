# Load the sibling controller test file so its Endpoint/Router/Layouts modules
# are compiled and available when this file runs in isolation
# (`mix test test/threadline/operator_surface/exports_mix_parity_test.exs`).
# When the full suite runs, the sibling file is loaded normally and
# `Code.require_file/1` is a no-op for already-loaded files.
Code.require_file("controllers/export_controller_test.exs", __DIR__)

if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.ExportsMixParityTest do
    @moduledoc """
    EXPO-05 byte-equality parity test (D-28).

    Both the Mix task `mix threadline.export` and the operator-surface export
    controller end up calling `Threadline.Export.{to_csv_iodata, to_json_document}/2`
    with identical opts derived from identical filters. This test proves the
    controller is a thin Plug wrapper, not a divergent reimplementation.

    Notes:

    * `async: false` — Threadline does NOT use SQL Sandbox; cleanup is FK-order
      `Repo.delete_all` in setup (mirrors `test/support/data_case.ex`).
    * `Mix.Task.reenable("threadline.export")` in setup — `Mix.Task.run/2`
      no-ops on second call within the same OS process; reenabling lets each
      test case re-invoke the Mix task (RESEARCH Pitfall 7 / Footgun F-4).
    * Reuses the `@endpoint` from `Threadline.OperatorSurface.ExportControllerTest`
      via `start_supervised/1` (idempotent — returns `{:error, {:already_started, _}}`
      quietly when called from this second test module).
    * Mix task accepts `--from "2020-01-01T00:00:00Z"` (full ISO-Z); controller
      accepts `?from=2020-01-01T00:00` (datetime-local, 16 chars). Convert via
      `String.slice(0..15)` so both paths see identical `DateTime` after parsing
      (RESEARCH §P-11 lines 1103-1106).
    """
    use ExUnit.Case, async: false

    import Phoenix.ConnTest
    import ExUnit.CaptureIO

    alias Threadline.Capture.{AuditChange, AuditTransaction}

    @endpoint Threadline.OperatorSurface.ExportControllerTest.Endpoint
    @repo Threadline.Test.Repo

    setup_all do
      # Endpoint may already be started by ExportControllerTest's setup_all if
      # the two modules run in the same suite. start_supervised/1 returns
      # {:error, {:already_started, _}} quietly, which we ignore.
      _ = start_supervised(@endpoint)
      :ok
    end

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

    test "CSV: Mix task and controller produce byte-identical output",
         %{conn: conn, tmp_dir: tmp_dir} do
      seed_changes!(50, table: "posts")

      from = "2020-01-01T00:00:00Z"
      to = "2099-01-01T00:00:00Z"
      tmp_path = Path.join(tmp_dir, "parity-csv-#{:rand.uniform(1_000_000)}.csv")

      # Mix task — write to disk
      capture_io(fn ->
        Mix.Tasks.Threadline.Export.run([
          "--format",
          "csv",
          "--output",
          tmp_path,
          "--from",
          from,
          "--to",
          to,
          "--table",
          "posts"
        ])
      end)

      mix_bytes = File.read!(tmp_path)

      # Controller — same filter values, but datetime-local format
      from_local = String.slice(from, 0..15)
      to_local = String.slice(to, 0..15)

      controller_conn =
        get(conn, "/audit/exports/changes.csv?from=#{from_local}&to=#{to_local}&table=posts")

      controller_bytes = response(controller_conn, 200)

      assert mix_bytes == controller_bytes,
             "Mix task and controller produced different bytes for the same CSV filters. " <>
               "Mix bytes: #{byte_size(mix_bytes)} bytes; controller bytes: #{byte_size(controller_bytes)} bytes."
    end

    test "JSON wrapped: Mix task and controller produce byte-identical output (modulo `generated_at`)",
         %{conn: conn, tmp_dir: tmp_dir} do
      seed_changes!(20, table: "posts")

      from = "2020-01-01T00:00:00Z"
      to = "2099-01-01T00:00:00Z"
      tmp_path = Path.join(tmp_dir, "parity-json-#{:rand.uniform(1_000_000)}.json")

      capture_io(fn ->
        Mix.Tasks.Threadline.Export.run([
          "--format",
          "json",
          # Default --json-format is wrapped; pass explicitly for clarity.
          "--json-format",
          "wrapped",
          "--output",
          tmp_path,
          "--from",
          from,
          "--to",
          to,
          "--table",
          "posts"
        ])
      end)

      mix_bytes = File.read!(tmp_path)

      from_local = String.slice(from, 0..15)
      to_local = String.slice(to, 0..15)

      controller_conn =
        get(conn, "/audit/exports/changes.json?from=#{from_local}&to=#{to_local}&table=posts")

      controller_bytes = response(controller_conn, 200)

      # Wrapped JSON includes a `generated_at` ISO-8601 microsecond-precision
      # timestamp captured at format time (lib/threadline/export.ex:434 —
      # `DateTime.utc_now() |> DateTime.truncate(:microsecond) |> DateTime.to_iso8601()`).
      # Mix and controller call it at different microseconds, so raw byte equality
      # is unattainable by design (the timestamp is intentional audit-trail
      # provenance metadata). Strip the timestamp for the parity assertion;
      # everything else — `format_version`, `changes` array, per-row encoding,
      # truncation metadata — must still be byte-identical.
      mix_normalized = strip_generated_at(mix_bytes)
      controller_normalized = strip_generated_at(controller_bytes)

      assert mix_normalized == controller_normalized,
             "Mix task and controller produced structurally different wrapped-JSON " <>
               "(after stripping `generated_at` timestamp). " <>
               "Mix bytes: #{byte_size(mix_bytes)} bytes; controller bytes: #{byte_size(controller_bytes)} bytes."

      # Belt + braces — both outputs must each contain a `generated_at` field
      # so a future regression that drops the field gets caught here.
      assert mix_bytes =~ ~r/"generated_at":/
      assert controller_bytes =~ ~r/"generated_at":/
    end

    test "NDJSON: Mix task and controller produce byte-identical output",
         %{conn: conn, tmp_dir: tmp_dir} do
      seed_changes!(20, table: "posts")

      from = "2020-01-01T00:00:00Z"
      to = "2099-01-01T00:00:00Z"
      tmp_path = Path.join(tmp_dir, "parity-ndjson-#{:rand.uniform(1_000_000)}.ndjson")

      capture_io(fn ->
        Mix.Tasks.Threadline.Export.run([
          "--format",
          "json",
          "--json-format",
          "ndjson",
          "--output",
          tmp_path,
          "--from",
          from,
          "--to",
          to,
          "--table",
          "posts"
        ])
      end)

      mix_bytes = File.read!(tmp_path)

      from_local = String.slice(from, 0..15)
      to_local = String.slice(to, 0..15)

      controller_conn =
        get(conn, "/audit/exports/changes.ndjson?from=#{from_local}&to=#{to_local}&table=posts")

      controller_bytes = response(controller_conn, 200)

      assert mix_bytes == controller_bytes,
             "Mix task and controller produced different bytes for the same NDJSON filters. " <>
               "Mix bytes: #{byte_size(mix_bytes)} bytes; controller bytes: #{byte_size(controller_bytes)} bytes."
    end

    # ---- Helpers ----

    # Strip the `"generated_at": "<ISO-8601 microsecond timestamp>"` key from a
    # wrapped-JSON body. The two surfaces capture the timestamp at different
    # microseconds, so byte-equality requires this normalization.
    defp strip_generated_at(json_binary) when is_binary(json_binary) do
      Regex.replace(~r/"generated_at":\s*"[^"]+"\s*,?\s*/, json_binary, "")
    end

    # Single-row insert; small N is fine for parity tests.
    defp seed_changes!(n, opts) when n > 0 do
      table = Keyword.fetch!(opts, :table)

      txn =
        @repo.insert!(
          AuditTransaction.changeset(%{
            txid: :rand.uniform(1_000_000_000),
            occurred_at: DateTime.utc_now()
          })
        )

      now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

      for i <- 1..n do
        @repo.insert!(
          AuditChange.changeset(%{
            transaction_id: txn.id,
            table_schema: "public",
            table_name: table,
            table_pk: %{"id" => "#{i}"},
            op: "insert",
            data_after: %{"i" => i},
            captured_at: now
          })
        )
      end
    end
  end
end
