defmodule Threadline.Query.RowKeyLegacyTest do
  @moduledoc """
  Proves READ-03: one `Threadline.history/3` call returns both a row captured
  by the frozen 0.10.2 trigger SQL and a row captured after the trigger is
  regenerated, for the same record — because both eras store the same
  `->>`-text shape for an `id` key (D-07, no separate legacy branch needed).

  Also proves that `{}` and `{"id": null}` rows, hand-inserted directly, are
  never returned by any lookup, and that `history/3` results stay stable
  under equal `captured_at` (ordering edge).
  """

  use Threadline.DataCase, async: false

  alias Threadline.Capture.{AuditChange, AuditTransaction, TriggerSQL}
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @table "rk_legacy_items"
  @legacy_function "rk_legacy_capture_v0_10_2"

  setup do
    storage = StorageSchema.get()
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-row-key-legacy-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    drop_fixtures!(storage)

    Repo.query!(TriggerSQL.install_function([]))

    Repo.query!(
      LegacyTriggerSQL.v0_10_2_install_function(
        ~s|"#{storage}"."#{@legacy_function}"|,
        storage
      )
    )

    on_exit(fn ->
      Mix.shell(previous_shell)
      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!(storage)
      File.rm_rf!(tmp)
    end)

    %{tmp: tmp, storage: storage}
  end

  defp drop_fixtures!(storage) do
    Repo.query!("DROP TABLE IF EXISTS #{@table} CASCADE")
    Repo.query!(~s|DROP FUNCTION IF EXISTS "#{storage}"."#{@legacy_function}"() CASCADE|)
  end

  defmodule RkLegacyItem do
    use Ecto.Schema

    schema "rk_legacy_items" do
      field(:name, :string)
    end
  end

  describe "regenerating a table with a frozen 0.10.2 trigger" do
    test "one history/3 call returns both eras' changes, byte-identical table_pk", %{
      tmp: tmp,
      storage: storage
    } do
      Repo.query!("""
      CREATE TABLE #{@table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @table,
          ~s|"#{storage}"."#{@legacy_function}"()|
        )
      )

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name) VALUES ('a') RETURNING id")

      write_fixture_migration!(
        tmp,
        "20230101000000_threadline_triggers_rk_legacy_items.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersRkLegacyItems",
        [LegacyTriggerSQL.v0_10_2_create_trigger("public", @table)],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{@table} ON #{@table}"]
      )

      file = Harness.generate!(tmp, ["--tables", @table])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("UPDATE #{@table} SET name = 'b' WHERE id = $1", [id])

      rows = Threadline.history(RkLegacyItem, id, repo: Repo)

      assert length(rows) == 2
      assert Enum.map(rows, & &1.op) == ["update", "insert"]

      for row <- rows do
        assert row.table_pk == %{"id" => Integer.to_string(id)}
      end
    end
  end

  describe "hand-inserted unresolved-key rows" do
    test "{} and {\"id\": null} are never returned by any lookup" do
      Repo.query!("""
      CREATE TABLE #{@table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name) VALUES ('a') RETURNING id")

      transaction = insert_transaction!()

      insert_change!(transaction, %{table_pk: %{}})
      insert_change!(transaction, %{table_pk: %{"id" => nil}})

      rows = Threadline.history(RkLegacyItem, id, repo: Repo)
      assert rows == []
    end
  end

  describe "history/3 ordering under equal captured_at" do
    test "two changes sharing captured_at come back stably, id DESC" do
      Repo.query!("""
      CREATE TABLE #{@table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name) VALUES ('a') RETURNING id")

      transaction = insert_transaction!()
      shared_captured_at = DateTime.utc_now(:microsecond)

      change_a =
        insert_change!(transaction, %{
          table_pk: %{"id" => Integer.to_string(id)},
          captured_at: shared_captured_at,
          op: "update",
          data_after: %{"id" => id, "name" => "x"}
        })

      change_b =
        insert_change!(transaction, %{
          table_pk: %{"id" => Integer.to_string(id)},
          captured_at: shared_captured_at,
          op: "update",
          data_after: %{"id" => id, "name" => "y"}
        })

      expected_ids =
        [change_a, change_b]
        |> Enum.map(& &1.id)
        |> Enum.sort(:desc)

      for _ <- 1..3 do
        rows = Threadline.history(RkLegacyItem, id, repo: Repo)
        assert Enum.map(rows, & &1.id) == expected_ids
      end
    end
  end

  defp insert_transaction! do
    Repo.insert!(
      AuditTransaction.changeset(%AuditTransaction{}, %{
        txid: System.unique_integer([:positive]),
        occurred_at: DateTime.utc_now(:microsecond)
      }),
      repo_opts()
    )
  end

  defp insert_change!(transaction, attrs) do
    defaults = %{
      transaction_id: transaction.id,
      table_schema: "public",
      table_name: @table,
      op: "insert",
      captured_at: DateTime.utc_now(:microsecond),
      data_after: %{}
    }

    Repo.insert!(
      AuditChange.changeset(%AuditChange{}, Map.merge(defaults, attrs)),
      repo_opts()
    )
  end

  defp write_fixture_migration!(tmp, basename, module, creates, drops) do
    migrations = Path.join([tmp, "priv", "repo", "migrations"])
    File.mkdir_p!(migrations)

    File.write!(
      Path.join(migrations, basename),
      LegacyTriggerSQL.migration_source(module, creates, drops)
    )
  end
end
