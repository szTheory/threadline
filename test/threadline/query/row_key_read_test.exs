defmodule Threadline.Query.RowKeyReadTest do
  @moduledoc """
  Proves `Threadline.history/3` returns rows captured by a generated trigger
  on a default Ecto bigserial table (READ-01), for integer, string, and
  keyword-list id arguments, and that the old jsonb-containment-operator
  predicate (0.10.2's `history/3`, verified via `git show v0.10.2`) does not
  match the same rows under an integer id — proving this test would fail on
  the pre-211 query code.
  """

  use Threadline.DataCase

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, TriggerSQL}
  alias Threadline.Test.MigrationHarness, as: Harness

  @table "rk_bigserial_users"

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-row-key-read-#{System.unique_integer([:positive])}"
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
    Repo.query!("DROP TABLE IF EXISTS #{@table} CASCADE")
    Repo.query!("DROP TABLE IF EXISTS rk_dropped_users CASCADE")
  end

  defmodule RkBigserialUser do
    use Ecto.Schema

    schema "rk_bigserial_users" do
      field(:name, :string)
    end
  end

  defmodule RkDroppedUser do
    use Ecto.Schema

    schema "rk_dropped_users" do
      field(:name, :string)
    end
  end

  defmodule RkMoneyCustomType do
    use Ecto.Type

    def type, do: :money_custom
    def cast(value), do: {:ok, value}
    def load(value), do: {:ok, value}
    def dump(value), do: {:ok, value}
  end

  defmodule RkUnmappableUser do
    use Ecto.Schema

    @primary_key {:code, RkMoneyCustomType, autogenerate: false}
    schema "rk_unmappable_users" do
    end
  end

  describe "history/3 on a default Ecto bigserial table (READ-01)" do
    test "integer, string, and keyword-list ids all return the same captured rows", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE #{@table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      file = Harness.generate!(tmp, ["--tables", @table])
      assert {:ok, _} = Harness.migrate_up(file)

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name) VALUES ('a') RETURNING id")

      Repo.query!("UPDATE #{@table} SET name = 'b' WHERE id = $1", [id])

      by_integer = Threadline.history(RkBigserialUser, id, repo: Repo)
      by_string = Threadline.history(RkBigserialUser, to_string(id), repo: Repo)
      by_keyword = Threadline.history(RkBigserialUser, [id: id], repo: Repo)

      assert length(by_integer) == 2
      assert Enum.map(by_integer, & &1.id) == Enum.map(by_string, & &1.id)
      assert Enum.map(by_integer, & &1.id) == Enum.map(by_keyword, & &1.id)

      [newest, oldest] = by_integer
      assert newest.op == "update"
      assert oldest.op == "insert"
      assert DateTime.compare(newest.captured_at, oldest.captured_at) in [:eq, :gt]
    end

    test "the old jsonb-containment predicate (0.10.2) returns [] for the same rows", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE #{@table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      file = Harness.generate!(tmp, ["--tables", @table])
      assert {:ok, _} = Harness.migrate_up(file)

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name) VALUES ('a') RETURNING id")

      # Sanity: the fixed query does return rows for this id.
      assert Threadline.history(RkBigserialUser, id, repo: Repo) != []

      # Regression proof: 0.10.2's `history/3` predicate, verbatim
      # (`git show v0.10.2:lib/threadline/query.ex`), with an Elixir integer
      # id. `@>` compares a JSON number against the trigger's stored JSON
      # string and never matches — this is READ-01's root-cause bug.
      pk_map = %{"id" => id}

      old_predicate_results =
        AuditChange
        |> where([ac], ac.table_schema == ^"public")
        |> where([ac], ac.table_name == ^@table)
        |> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
        |> Repo.all(repo_opts())

      assert old_predicate_results == []
    end

    test "raises ArgumentError before any query runs when id is nil" do
      assert_raise ArgumentError, ~r/got nil/, fn ->
        Threadline.history(RkBigserialUser, nil, repo: Repo)
      end
    end
  end

  describe "row_history_query/3, row_history_page/4, and as_of/4 on the same table" do
    setup %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE #{@table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      file = Harness.generate!(tmp, ["--tables", @table])
      assert {:ok, _} = Harness.migrate_up(file)

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name) VALUES ('a') RETURNING id")

      Repo.query!("UPDATE #{@table} SET name = 'b' WHERE id = $1", [id])

      %{id: id}
    end

    test "row_history_query/3 returns an Ecto.Query that resolves both changes", %{id: id} do
      query = Threadline.Query.row_history_query(RkBigserialUser, id, repo: Repo)
      assert %Ecto.Query{} = query
      assert length(Repo.all(query, repo_opts())) == 2
    end

    test "row_history_page/4 pages one entry at a time, in stable order", %{id: id} do
      page1 =
        Threadline.row_history_page(RkBigserialUser, id, [], repo: Repo, page_size: 1)

      assert length(page1.entries) == 1
      assert page1.next_cursor

      page2 =
        Threadline.row_history_page(RkBigserialUser, id, [],
          repo: Repo,
          page_size: 1,
          cursor: page1.next_cursor
        )

      assert length(page2.entries) == 1

      all_ids = Enum.map(page1.entries ++ page2.entries, & &1.audit_change.id)
      assert Enum.uniq(all_ids) == all_ids
    end

    test "as_of/4 returns the latest snapshot, then :deleted_record after a delete", %{id: id} do
      assert {:ok, %{"name" => "b"}} =
               Threadline.as_of(RkBigserialUser, to_string(id), DateTime.utc_now(), repo: Repo)

      Repo.query!("DELETE FROM #{@table} WHERE id = $1", [id])

      assert {:error, :deleted_record} =
               Threadline.as_of(RkBigserialUser, id, DateTime.utc_now(), repo: Repo)
    end

    test "history/3 raises ArgumentError naming :id and the schema for an uncastable id" do
      assert_raise ArgumentError, ~r/:id/, fn ->
        Threadline.history(RkBigserialUser, "not-a-number", repo: Repo)
      end
    end
  end

  describe "history of a dropped host table (fallback type map)" do
    test "stays readable for history/3 and as_of/4 after DROP TABLE", %{tmp: tmp} do
      table = "rk_dropped_users"

      Repo.query!("""
      CREATE TABLE #{table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      file = Harness.generate!(tmp, ["--tables", table])
      assert {:ok, _} = Harness.migrate_up(file)

      %{rows: [[id]]} = Repo.query!("INSERT INTO #{table} (name) VALUES ('a') RETURNING id")
      Repo.query!("UPDATE #{table} SET name = 'b' WHERE id = $1", [id])

      before_drop = Threadline.history(RkDroppedUser, id, repo: Repo)
      assert length(before_drop) == 2

      Repo.query!("DROP TABLE #{table}")

      after_drop = Threadline.history(RkDroppedUser, id, repo: Repo)
      assert Enum.map(after_drop, & &1.id) == Enum.map(before_drop, & &1.id)

      assert {:ok, %{"name" => "b"}} =
               Threadline.as_of(RkDroppedUser, id, DateTime.utc_now(), repo: Repo)
    end
  end

  describe "an unmappable key type (no catalog entry, no fallback mapping)" do
    test "raises ArgumentError naming the field, its Ecto type, and the qualified table" do
      assert_raise ArgumentError,
                   ~r/:code.*RkMoneyCustomType.*public\.rk_unmappable_users/s,
                   fn ->
                     Threadline.history(RkUnmappableUser, "x", repo: Repo)
                   end
    end
  end
end
