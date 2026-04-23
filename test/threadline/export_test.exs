defmodule Threadline.ExportTest do
  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Export
  alias Threadline.Semantics.ActorRef

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
  end

  describe "stream_changes/2" do
    test "pages through all rows in timeline order" do
      tname = table_name("stream")
      txn = insert_transaction()

      for i <- 1..4 do
        insert_change(txn, %{
          table_name: tname,
          table_pk: %{"id" => "s-#{i}"},
          captured_at: DateTime.add(~U[2026-06-01 00:00:00.000000Z], i, :second)
        })
      end

      filters = [repo: @repo, table: tname]
      streamed = Export.stream_changes(filters, repo: @repo, page_size: 2) |> Enum.to_list()
      assert length(streamed) == 4

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
