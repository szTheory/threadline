defmodule Threadline.PageTest do
  use Threadline.DataCase, async: false

  alias Threadline.Capture.{AuditChange, AuditTransaction}

  @repo Threadline.Test.Repo

  defp insert_transaction(attrs \\ %{}) do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    @repo.insert!(
      AuditTransaction.changeset(Map.merge(defaults, attrs)),
      repo_opts()
    )
  end

  defp insert_change(transaction, attrs \\ %{}) do
    defaults = %{
      table_schema: "public",
      table_name: "users",
      table_pk: %{"id" => "page-1"},
      op: "insert",
      data_after: %{"name" => "Alice"},
      changed_fields: ["name"],
      captured_at: DateTime.utc_now(),
      transaction_id: transaction.id
    }

    @repo.insert!(
      AuditChange.changeset(Map.merge(defaults, Map.new(attrs))),
      repo_opts()
    )
  end

  # Inserts `count` rows for `table_name`, each `captured_at` one second apart
  # (newest last-inserted == oldest timestamp growing forward), so default
  # keyset order (captured_at desc, id desc) is deterministic across runs.
  defp insert_rows(table_name, count) do
    txn = insert_transaction()
    base = ~U[2026-07-01 12:00:00.000000Z]

    for i <- 1..count do
      insert_change(txn, %{
        table_name: table_name,
        table_pk: %{"id" => "row-#{i}"},
        captured_at: DateTime.add(base, i, :second)
      })
    end
  end

  defp unique_table(prefix), do: "#{prefix}_#{System.unique_integer([:positive])}"

  describe "Threadline.Page struct shape" do
    test "has exactly entries, cursor, has_more, all enforced" do
      page = %Threadline.Page{entries: [], cursor: nil, has_more: false}
      assert Map.from_struct(page) |> Map.keys() |> Enum.sort() == [:cursor, :entries, :has_more]

      assert_raise ArgumentError, fn ->
        struct!(Threadline.Page, entries: [])
      end
    end
  end

  describe "timeline_page/2 exact has_more walk" do
    test "5 rows, page_size 2: pages of 2,2,1 with has_more true,true,false and nil final cursor" do
      tname = unique_table("page5")
      insert_rows(tname, 5)
      filters = [repo: @repo, table: tname]

      first = Threadline.timeline_page(filters, page_size: 2)
      assert length(first.entries) == 2
      assert first.has_more == true
      assert first.cursor != nil

      second = Threadline.timeline_page(filters, page_size: 2, cursor: first.cursor)
      assert length(second.entries) == 2
      assert second.has_more == true
      assert second.cursor != nil

      third = Threadline.timeline_page(filters, page_size: 2, cursor: second.cursor)
      assert length(third.entries) == 1
      assert third.has_more == false
      assert third.cursor == nil
    end

    test "4 rows, page_size 2: exact boundary — second page has_more false and cursor nil" do
      tname = unique_table("page4")
      insert_rows(tname, 4)
      filters = [repo: @repo, table: tname]

      first = Threadline.timeline_page(filters, page_size: 2)
      assert length(first.entries) == 2
      assert first.has_more == true
      assert first.cursor != nil

      second = Threadline.timeline_page(filters, page_size: 2, cursor: first.cursor)
      assert length(second.entries) == 2
      assert second.has_more == false
      assert second.cursor == nil
    end

    test "0 rows: one page, entries [], cursor nil, has_more false" do
      tname = unique_table("page0")
      filters = [repo: @repo, table: tname]

      page = Threadline.timeline_page(filters, page_size: 2)
      assert page.entries == []
      assert page.cursor == nil
      assert page.has_more == false
    end

    test "three rows sharing one captured_at, page_size 1: ordered by id desc, each exactly once" do
      tname = unique_table("tie")
      txn = insert_transaction()
      tie_time = ~U[2026-07-01 12:00:00.000000Z]

      changes =
        for i <- 1..3 do
          insert_change(txn, %{
            table_name: tname,
            table_pk: %{"id" => "tie-#{i}"},
            captured_at: tie_time
          })
        end

      expected_ids =
        changes
        |> Enum.map(& &1.id)
        |> Enum.sort(:desc)

      filters = [repo: @repo, table: tname]

      {all_ids, _final} =
        Enum.reduce(1..3, {[], :start}, fn _i, {acc, cursor} ->
          page = Threadline.timeline_page(filters, page_size: 1, cursor: cursor)
          {acc ++ Enum.map(page.entries, & &1.id), page.cursor || :start}
        end)

      assert all_ids == expected_ids
      assert length(Enum.uniq(all_ids)) == 3
    end

    test "cursor omitted and cursor: :start return the same first page" do
      tname = unique_table("start")
      insert_rows(tname, 3)
      filters = [repo: @repo, table: tname]

      omitted = Threadline.timeline_page(filters, page_size: 2)
      explicit_start = Threadline.timeline_page(filters, page_size: 2, cursor: :start)

      assert omitted == explicit_start
    end

    test "cursor: nil raises ArgumentError mentioning :start" do
      assert_raise ArgumentError, ~r/:start/, fn ->
        Threadline.timeline_page([repo: @repo], cursor: nil)
      end
    end

    test "a cursor map with an uppercase UUID id is accepted; a non-UUID id raises" do
      tname = unique_table("uuid")
      insert_rows(tname, 2)
      filters = [repo: @repo, table: tname]

      first = Threadline.timeline_page(filters, page_size: 1)
      upcased_cursor = %{first.cursor | id: String.upcase(first.cursor.id)}

      assert %Threadline.Page{} = Threadline.timeline_page(filters, page_size: 1, cursor: upcased_cursor)

      assert_raise ArgumentError, ~r/UUID/, fn ->
        Threadline.timeline_page(filters,
          page_size: 1,
          cursor: %{captured_at: DateTime.utc_now(), id: "not-a-uuid"}
        )
      end
    end

    test "concatenating a full walk equals Threadline.timeline/2 for the same filters" do
      tname = unique_table("walk")
      insert_rows(tname, 7)
      filters = [repo: @repo, table: tname]

      eager_ids = Enum.map(Threadline.timeline(filters), & &1.id)

      {walked_ids, _} =
        Enum.reduce_while(0..20, {[], :start}, fn _i, {acc, cursor} ->
          page = Threadline.timeline_page(filters, page_size: 2, cursor: cursor)
          new_acc = acc ++ Enum.map(page.entries, & &1.id)

          if page.has_more do
            {:cont, {new_acc, page.cursor}}
          else
            {:halt, {new_acc, nil}}
          end
        end)

      assert walked_ids == eager_ids
    end
  end
end
