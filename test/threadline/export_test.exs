defmodule Threadline.ExportTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Export
  alias Threadline.Semantics.{ActorRef, AuditAction}

  @repo Threadline.Test.Repo

  defp insert_transaction(attrs \\ %{}) do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}
    @repo.insert!(AuditTransaction.changeset(Map.merge(defaults, attrs)))
  end

  defp insert_change(transaction, attrs) do
    defaults = %{
      table_schema: "public",
      table_name: "users",
      table_pk: %{"id" => "user-1"},
      op: "insert",
      data_after: %{"name" => "Alice"},
      changed_fields: ["name"],
      captured_at: DateTime.utc_now(),
      transaction_id: transaction.id
    }

    @repo.insert!(AuditChange.changeset(Map.merge(defaults, attrs)))
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  defp table_name(suffix), do: "export_test_#{suffix}_#{:erlang.unique_integer([:positive])}"

  defp stream_fixture(table_name) do
    tie_time = ~U[2026-06-01 00:00:00.000000Z]
    newer_time = DateTime.add(tie_time, 60, :second)
    older_time = DateTime.add(tie_time, -60, :second)
    txn = insert_transaction(%{occurred_at: newer_time})

    insert_change(txn, %{
      table_name: table_name,
      table_pk: %{"id" => "s-1"},
      captured_at: newer_time
    })

    insert_change(txn, %{
      table_name: table_name,
      table_pk: %{"id" => "s-2"},
      captured_at: tie_time
    })

    insert_change(txn, %{
      table_name: table_name,
      table_pk: %{"id" => "s-3"},
      captured_at: tie_time
    })

    insert_change(txn, %{
      table_name: table_name,
      table_pk: %{"id" => "s-4"},
      captured_at: tie_time
    })

    insert_change(txn, %{
      table_name: table_name,
      table_pk: %{"id" => "s-5"},
      captured_at: older_time
    })
  end

  describe "to_csv_iodata/2" do
    test "happy path: CSV columns and JSON transaction cell parse" do
      tname = table_name("csv")
      txn = insert_transaction(%{source: "web"})
      insert_change(txn, %{table_name: tname, op: "insert", data_after: %{"x" => 1}})
      insert_change(txn, %{table_name: tname, op: "update", data_after: %{"x" => 2}})

      assert {:ok, %{data: iodata, truncated: false, returned_count: 2}} =
               Export.to_csv_iodata([repo: @repo, table: tname], [])

      csv = IO.iodata_to_binary(iodata)
      lines = String.split(String.trim_trailing(csv, "\n"), "\n")
      assert length(lines) == 3
      [header | rows] = lines
      assert header =~ "transaction_json"

      for row <- rows do
        parsed = NimbleCSV.RFC4180.parse_string(row <> "\n", skip_headers: false)
        [cells] = parsed
        assert length(cells) == 11
        tx_json = List.last(cells)
        map = Jason.decode!(tx_json)
        assert map["source"] == "web"
        assert map["id"]
        assert map["occurred_at"]
        assert is_map(map["actor_ref"]) or map["actor_ref"] == nil
      end
    end

    test "empty: header only and returned_count 0" do
      tname = table_name("empty")

      assert {:ok, %{data: iodata, truncated: false, returned_count: 0}} =
               Export.to_csv_iodata([repo: @repo, table: tname], [])

      csv = IO.iodata_to_binary(iodata)
      lines = String.split(String.trim_trailing(csv, "\n"), "\n")
      assert length(lines) == 1
      assert hd(lines) =~ "id"
    end

    test "truncation when more than max_rows" do
      tname = table_name("trunc")
      txn = insert_transaction()

      for i <- 1..5 do
        insert_change(txn, %{
          table_name: tname,
          table_pk: %{"id" => "r-#{i}"},
          captured_at: DateTime.add(~U[2026-01-01 00:00:00.000000Z], i, :second)
        })
      end

      assert {:ok, %{truncated: true, returned_count: 3, max_rows: 3}} =
               Export.to_csv_iodata([repo: @repo, table: tname], max_rows: 3)
    end

    test "CSV escapes comma, newline, and UTF-8 in JSON payload" do
      tname = table_name("esc")
      txn = insert_transaction()

      insert_change(txn, %{
        table_name: tname,
        data_after: %{"note" => "comma,here", "body" => "line1\nline2", "label" => "日本語"}
      })

      assert {:ok, %{data: iodata}} = Export.to_csv_iodata([repo: @repo, table: tname], [])
      csv = IO.iodata_to_binary(iodata)
      assert String.contains?(csv, "日本語")
      assert is_list(NimbleCSV.RFC4180.parse_string(csv, skip_headers: true))
    end

    test "strict filters: unknown key raises ArgumentError" do
      assert_raise ArgumentError, fn ->
        Export.to_csv_iodata([repo: @repo, oops: true], [])
      end
    end
  end

  describe "to_json_document/2" do
    test "happy path JSON wrapped document" do
      tname = table_name("json")
      actor = actor!(:user, "u-json")
      txn = insert_transaction(%{actor_ref: ActorRef.to_map(actor), source: "oban"})
      insert_change(txn, %{table_name: tname})

      assert {:ok, %{data: data, truncated: false}} =
               Export.to_json_document([repo: @repo, table: tname], [])

      doc = Jason.decode!(IO.iodata_to_binary(data))
      assert doc["format_version"] == 1
      assert is_binary(doc["generated_at"])
      assert length(doc["changes"]) == 1
      ch = hd(doc["changes"])
      assert ch["table_name"] == tname
      tx = ch["transaction"]
      assert tx["id"]
      assert tx["occurred_at"]
      assert tx["actor_ref"]["type"] == "user"
      assert tx["source"] == "oban"
    end

    test "NDJSON: one object per line" do
      tname = table_name("ndj")
      txn = insert_transaction()
      insert_change(txn, %{table_name: tname})
      insert_change(txn, %{table_name: tname, table_pk: %{"id" => "2"}})

      assert {:ok, %{data: data}} =
               Export.to_json_document([repo: @repo, table: tname], json_format: :ndjson)

      bin = IO.iodata_to_binary(data)

      bin
      |> String.split("\n", trim: true)
      |> Enum.each(fn line ->
        m = Jason.decode!(line)
        assert m["id"]
        assert m["transaction"]["id"]
      end)
    end

    test "empty JSON changes" do
      tname = table_name("je")

      assert {:ok, %{returned_count: 0, data: data}} =
               Export.to_json_document([repo: @repo, table: tname], [])

      assert Jason.decode!(IO.iodata_to_binary(data))["changes"] == []
    end
  end

  describe "LOOP-01: correlation timeline ↔ export" do
    defp insert_action(attrs) do
      actor = actor!(:user, "export-loop-user")

      defaults = %{
        name: "test.loop01",
        actor_ref: ActorRef.to_map(actor),
        status: :ok,
        correlation_id: "loop01-cid"
      }

      @repo.insert!(AuditAction.changeset(%AuditAction{}, Map.merge(defaults, attrs)))
    end

    test "JSON export change ids match timeline with :correlation_id filter" do
      tname = table_name("loop01parity")
      action = insert_action(%{correlation_id: "loop01-cid"})
      txn = insert_transaction(%{action_id: action.id})
      insert_change(txn, %{table_name: tname})
      insert_change(txn, %{table_name: tname, table_pk: %{"id" => "p2"}})

      filters = [repo: @repo, table: tname, correlation_id: "loop01-cid"]
      opts = [repo: @repo]

      timeline_ids =
        filters
        |> Threadline.timeline(opts)
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert {:ok, %{data: json}} = Export.to_json_document(filters, opts)
      doc = json |> IO.iodata_to_binary() |> Jason.decode!()

      export_ids =
        doc
        |> Map.get("changes")
        |> Enum.map(& &1["id"])
        |> Enum.sort()

      assert timeline_ids == export_ids
      [ch | _] = doc["changes"]
      assert ch["action"]["id"] == to_string(action.id)
      assert ch["action"]["correlation_id"] == "loop01-cid"
    end

    test "extended CSV includes correlation_id and action_id columns" do
      tname = table_name("loop01csv")
      action = insert_action(%{correlation_id: "loop01-cid"})
      txn = insert_transaction(%{action_id: action.id})
      insert_change(txn, %{table_name: tname})

      filters = [repo: @repo, table: tname, correlation_id: "loop01-cid"]

      assert {:ok, %{data: iodata}} =
               Export.to_csv_iodata(filters, include_action_metadata: true)

      csv = IO.iodata_to_binary(iodata)
      [header | _] = String.split(String.trim_trailing(csv, "\n"), "\n")
      assert header =~ "correlation_id"
      assert header =~ "action_id"

      [cells] = NimbleCSV.RFC4180.parse_string(csv, skip_headers: true)
      assert length(cells) == 13
      assert Enum.at(cells, -2) == "loop01-cid"
      assert List.last(cells) == to_string(action.id)
    end
  end

  describe "filter parity with timeline/2" do
    test "same multiset of change ids for table filter" do
      tname = table_name("parity")
      txn = insert_transaction()
      insert_change(txn, %{table_name: tname})
      insert_change(txn, %{table_name: tname, table_pk: %{"id" => "p2"}})

      filters = [repo: @repo, table: tname]
      opts = [repo: @repo]

      timeline_ids =
        filters
        |> Threadline.timeline(opts)
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert {:ok, %{data: json}} = Export.to_json_document(filters, opts)

      export_ids =
        json
        |> IO.iodata_to_binary()
        |> Jason.decode!()
        |> Map.get("changes")
        |> Enum.map(& &1["id"])
        |> Enum.sort()

      assert timeline_ids == export_ids
    end
  end

  describe "count_matching/2" do
    test "returns count without loading rows" do
      tname = table_name("cnt")
      txn = insert_transaction()
      insert_change(txn, %{table_name: tname})
      insert_change(txn, %{table_name: tname})

      assert {:ok, %{count: 2}} = Export.count_matching([repo: @repo, table: tname], [])
    end

    test "with :cap clamps at the cap value when more rows match" do
      tname = table_name("capclamp")
      txn = insert_transaction()
      for i <- 1..100, do: insert_change(txn, %{table_name: tname, table_pk: %{"id" => "r-#{i}"}})

      assert {:ok, %{count: 50}} =
               Export.count_matching([repo: @repo, table: tname], cap: 50)
    end

    test "with :cap returns the true count when fewer rows match" do
      tname = table_name("capslack")
      txn = insert_transaction()
      for i <- 1..10, do: insert_change(txn, %{table_name: tname, table_pk: %{"id" => "r-#{i}"}})

      assert {:ok, %{count: 10}} =
               Export.count_matching([repo: @repo, table: tname], cap: 50)
    end

    test "without :cap returns the true count (default behavior unchanged)" do
      tname = table_name("capnone")
      txn = insert_transaction()
      for i <- 1..100, do: insert_change(txn, %{table_name: tname, table_pk: %{"id" => "r-#{i}"}})

      assert {:ok, %{count: 100}} =
               Export.count_matching([repo: @repo, table: tname], [])
    end
  end

  describe "format_changes_iodata/3 + csv_header/1 (chunked-path helpers)" do
    test ":csv batch + csv_header concat byte-equal to to_csv_iodata/2 for the same rows" do
      tname = table_name("fmtcsv")
      txn = insert_transaction(%{source: "web"})
      insert_change(txn, %{table_name: tname, op: "insert", data_after: %{"x" => 1}})
      insert_change(txn, %{table_name: tname, op: "update", data_after: %{"x" => 2}})

      filters = [repo: @repo, table: tname]

      {:ok, %{data: full_iodata}} = Export.to_csv_iodata(filters, [])
      full_csv = IO.iodata_to_binary(full_iodata)

      rows = filters |> Export.stream_export_rows(repo: @repo) |> Enum.to_list()

      header_iodata = Export.csv_header([])
      data_iodata = Export.format_changes_iodata(rows, :csv, [])
      reconstructed = IO.iodata_to_binary([header_iodata, data_iodata])

      assert reconstructed == full_csv
    end

    test ":csv batch with include_action_metadata: true matches the extended CSV shape" do
      tname = table_name("fmtcsvmeta")
      txn = insert_transaction()
      insert_change(txn, %{table_name: tname})

      filters = [repo: @repo, table: tname]

      {:ok, %{data: full_iodata}} =
        Export.to_csv_iodata(filters, include_action_metadata: true)

      full_csv = IO.iodata_to_binary(full_iodata)

      rows = filters |> Export.stream_export_rows(repo: @repo) |> Enum.to_list()

      header_iodata = Export.csv_header(include_action_metadata: true)
      data_iodata = Export.format_changes_iodata(rows, :csv, include_action_metadata: true)
      reconstructed = IO.iodata_to_binary([header_iodata, data_iodata])

      assert reconstructed == full_csv
    end

    test "csv_header/1 returns the same header line as to_csv_iodata/2's first row" do
      tname = table_name("fmthdr")
      txn = insert_transaction()
      insert_change(txn, %{table_name: tname})

      filters = [repo: @repo, table: tname]

      {:ok, %{data: full_iodata}} = Export.to_csv_iodata(filters, [])
      full_csv = IO.iodata_to_binary(full_iodata)
      [first_line | _] = String.split(full_csv, "\r\n", parts: 2)

      header_str = Export.csv_header([]) |> IO.iodata_to_binary()
      assert header_str == first_line <> "\r\n"
    end

    test ":ndjson batch byte-equal to to_json_document/2 ndjson output" do
      tname = table_name("fmtndj")
      txn = insert_transaction()
      insert_change(txn, %{table_name: tname})
      insert_change(txn, %{table_name: tname, table_pk: %{"id" => "2"}})

      filters = [repo: @repo, table: tname]

      {:ok, %{data: full_data}} =
        Export.to_json_document(filters, json_format: :ndjson)

      full_ndjson = IO.iodata_to_binary(full_data)

      rows = filters |> Export.stream_export_rows(repo: @repo) |> Enum.to_list()
      batched = Export.format_changes_iodata(rows, :ndjson, []) |> IO.iodata_to_binary()

      assert batched == full_ndjson
    end

    test ":json_wrapped batch produces per-row JSON objects (no envelope)" do
      tname = table_name("fmtjson")
      txn = insert_transaction()
      insert_change(txn, %{table_name: tname})

      filters = [repo: @repo, table: tname]
      rows = filters |> Export.stream_export_rows(repo: @repo) |> Enum.to_list()

      iodata = Export.format_changes_iodata(rows, :json_wrapped, [])
      # Each element of the resulting iodata list is one Jason.encode!-ed binary.
      assert is_list(iodata)
      assert length(iodata) == length(rows)

      first = iodata |> List.first() |> IO.iodata_to_binary()
      decoded = Jason.decode!(first)
      assert decoded["table_name"] == tname
      assert is_map(decoded["transaction"])
    end

    test "format_changes_iodata/3 raises FunctionClauseError for unknown format" do
      assert_raise FunctionClauseError, fn ->
        Export.format_changes_iodata([], :xml, [])
      end
    end
  end

  describe "stream_export_rows/2" do
    test "yields the join-projected map shape (with tx_*/aa_* fields)" do
      tname = table_name("strex")
      txn = insert_transaction(%{source: "web"})
      insert_change(txn, %{table_name: tname})

      filters = [repo: @repo, table: tname]
      [row | _] = filters |> Export.stream_export_rows(repo: @repo) |> Enum.to_list()

      assert is_map(row)
      assert Map.has_key?(row, :tx_occurred_at)
      assert Map.has_key?(row, :tx_source)
      assert Map.has_key?(row, :tx_actor_ref)
      assert Map.has_key?(row, :aa_id)
      assert Map.has_key?(row, :aa_correlation_id)
      assert row.table_name == tname
      assert row.tx_source == "web"
    end

    test "pages by keyset across page_size boundaries" do
      tname = table_name("strexpage")
      txn = insert_transaction()

      for i <- 1..7 do
        insert_change(txn, %{
          table_name: tname,
          table_pk: %{"id" => "r-#{i}"},
          captured_at: DateTime.add(~U[2026-01-01 00:00:00.000000Z], i, :second)
        })
      end

      filters = [repo: @repo, table: tname]
      streamed = filters |> Export.stream_export_rows(repo: @repo, page_size: 3) |> Enum.to_list()

      assert length(streamed) == 7
      # Same ordering as export_changes_query (desc captured_at, desc id).
      streamed_pks = Enum.map(streamed, & &1.table_pk["id"])
      assert streamed_pks == ["r-7", "r-6", "r-5", "r-4", "r-3", "r-2", "r-1"]
    end
  end

  describe "stream_changes/2" do
    test "pages through all rows in timeline order" do
      tname = table_name("stream")
      stream_fixture(tname)

      filters = [repo: @repo, table: tname]
      streamed = Export.stream_changes(filters, repo: @repo, page_size: 2) |> Enum.to_list()
      assert length(streamed) == 5

      timeline_ids = Enum.map(Threadline.timeline(filters, repo: @repo), & &1.id)
      stream_ids = Enum.map(streamed, & &1.id)
      assert timeline_ids == stream_ids
    end
  end

  describe "DX-03: missing :repo and invalid filters" do
    test "to_csv_iodata raises ArgumentError when :repo missing" do
      assert_raise ArgumentError, ~r/missing :repo/, fn ->
        Export.to_csv_iodata([table: "users"], [])
      end
    end

    test "to_csv_iodata raises for unknown filter key" do
      assert_raise ArgumentError, ~r/unknown timeline filter/, fn ->
        Export.to_csv_iodata([repo: @repo, bad: 1], [])
      end
    end
  end
end
