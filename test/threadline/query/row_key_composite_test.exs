defmodule Threadline.Query.RowKeyCompositeTest do
  @moduledoc """
  Proves `Threadline.history/3`, `row_history_page/4`, and `as_of/4` return
  captured rows for a composite-key table, through every accepted id-argument
  shape (keyword list, atom-keyed map, string-keyed map), and that a
  composite lookup never returns a sibling key's rows.

  Every assertion decodes the stored jsonb and compares with `==`, never the
  jsonb containment operator: containing an empty object is true for every
  row, which would make an adjacency assertion pass vacuously.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction, TriggerSQL}
  alias Threadline.Test.MigrationHarness, as: Harness

  @line_items "rk_line_items"
  @dropped_pairs "rk_dropped_pairs"

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-row-key-composite-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    Repo.query!(TriggerSQL.install_function([]))
    drop_fixtures!()

    on_exit(fn ->
      Mix.shell(previous_shell)
      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!()
      File.rm_rf!(tmp)
    end)

    %{tmp: tmp}
  end

  defp drop_fixtures! do
    Repo.query!("DROP TABLE IF EXISTS #{@line_items} CASCADE")
    Repo.query!("DROP TABLE IF EXISTS #{@dropped_pairs} CASCADE")
  end

  defmodule RkLineItem do
    use Ecto.Schema

    @primary_key false
    schema "rk_line_items" do
      field(:tenant_id, :integer, primary_key: true)
      field(:id, :integer, primary_key: true)
      field(:qty, :integer)
    end
  end

  defmodule RkDroppedPair do
    use Ecto.Schema

    @primary_key false
    schema "rk_dropped_pairs" do
      field(:account_id, :integer, primary_key: true)
      field(:token, Ecto.UUID, primary_key: true)
      field(:note, :string)
    end
  end

  describe "a composite-key table, captured end to end (READ-02)" do
    setup %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE #{@line_items} (
        tenant_id bigint NOT NULL,
        id        bigint NOT NULL,
        qty       int,
        PRIMARY KEY (tenant_id, id)
      )
      """)

      file = Harness.generate!(tmp, ["--tables", @line_items])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO #{@line_items} (tenant_id, id, qty) VALUES (1, 5, 1)")
      Repo.query!("INSERT INTO #{@line_items} (tenant_id, id, qty) VALUES (2, 5, 1)")
      Repo.query!("INSERT INTO #{@line_items} (tenant_id, id, qty) VALUES (1, 6, 1)")
      Repo.query!("UPDATE #{@line_items} SET qty = 2 WHERE tenant_id = 1 AND id = 5")

      :ok
    end

    test "keyword list, atom-keyed map, and string-keyed map all return the (1,5) history" do
      by_keyword = Threadline.history(RkLineItem, [tenant_id: 1, id: 5], repo: Repo)
      by_atom_map = Threadline.history(RkLineItem, %{id: 5, tenant_id: 1}, repo: Repo)

      by_string_map =
        Threadline.history(RkLineItem, %{"tenant_id" => "1", "id" => "5"}, repo: Repo)

      for rows <- [by_keyword, by_atom_map, by_string_map] do
        assert length(rows) == 2

        assert Enum.map(rows, & &1.table_pk) == [
                 %{"tenant_id" => "1", "id" => "5"},
                 %{"tenant_id" => "1", "id" => "5"}
               ]
      end

      [newest, oldest] = by_keyword
      assert newest.op == "update"
      assert oldest.op == "insert"
    end

    test "(2,5) returns only its own insert, never the (1,5) rows" do
      rows = Threadline.history(RkLineItem, [tenant_id: 2, id: 5], repo: Repo)

      assert length(rows) == 1
      assert hd(rows).op == "insert"
      assert hd(rows).table_pk == %{"tenant_id" => "2", "id" => "5"}
    end

    test "row_history_page/4 and as_of/4 agree for (1,5)" do
      page =
        Threadline.row_history_page(RkLineItem, [tenant_id: 1, id: 5], [], repo: Repo)

      assert length(page.entries) == 2

      assert {:ok, %{"qty" => 2}} =
               Threadline.as_of(RkLineItem, [tenant_id: 1, id: 5], DateTime.utc_now(), repo: Repo)
    end

    test "adjacency: a hand-built change with a single-key table_pk is never returned by a composite lookup" do
      transaction =
        Repo.insert!(
          AuditTransaction.changeset(%AuditTransaction{}, %{
            txid: System.unique_integer([:positive]),
            occurred_at: DateTime.utc_now(:microsecond)
          }),
          repo_opts()
        )

      Repo.insert!(
        AuditChange.changeset(%AuditChange{}, %{
          transaction_id: transaction.id,
          table_schema: "public",
          table_name: @line_items,
          table_pk: %{"id" => "5"},
          op: "insert",
          captured_at: DateTime.utc_now(:microsecond),
          data_after: %{"id" => 5}
        }),
        repo_opts()
      )

      rows = Threadline.history(RkLineItem, [tenant_id: 1, id: 5], repo: Repo)
      assert Enum.all?(rows, &(&1.table_pk != %{"id" => "5"}))

      rows2 = Threadline.history(RkLineItem, [tenant_id: 2, id: 5], repo: Repo)
      assert Enum.all?(rows2, &(&1.table_pk != %{"id" => "5"}))
    end
  end

  describe "a dropped composite table (fallback type map)" do
    test "stays readable for history/3 and as_of/4 after DROP TABLE", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE #{@dropped_pairs} (
        account_id bigint NOT NULL,
        token      uuid NOT NULL,
        note       text,
        PRIMARY KEY (account_id, token)
      )
      """)

      file = Harness.generate!(tmp, ["--tables", @dropped_pairs])
      assert {:ok, _} = Harness.migrate_up(file)

      token = Ecto.UUID.generate()

      Repo.query!(
        "INSERT INTO #{@dropped_pairs} (account_id, token, note) VALUES (1, $1, 'a')",
        [Ecto.UUID.dump!(token)]
      )

      Repo.query!(
        "UPDATE #{@dropped_pairs} SET note = 'b' WHERE account_id = 1 AND token = $1",
        [Ecto.UUID.dump!(token)]
      )

      before_drop = Threadline.history(RkDroppedPair, [account_id: 1, token: token], repo: Repo)
      assert length(before_drop) == 2

      Repo.query!("DROP TABLE #{@dropped_pairs}")

      after_drop = Threadline.history(RkDroppedPair, [account_id: 1, token: token], repo: Repo)
      assert Enum.map(after_drop, & &1.id) == Enum.map(before_drop, & &1.id)

      assert {:ok, %{"note" => "b"}} =
               Threadline.as_of(RkDroppedPair, [account_id: 1, token: token], DateTime.utc_now(),
                 repo: Repo
               )
    end
  end
end
