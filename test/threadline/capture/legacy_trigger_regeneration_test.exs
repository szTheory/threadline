defmodule Threadline.Capture.LegacyTriggerRegenerationTest do
  @moduledoc """
  Regenerates tables whose triggers were installed by earlier releases, with
  `mix threadline.gen.triggers`, and applies and rolls back the new migration
  through `Ecto.Migrator`.

  Each earlier release wrote its trigger statement differently:

    * 0.9.0 and earlier: `CREATE TRIGGER threadline_audit_<table> ... ON <table>`,
      nothing quoted or qualified;
    * 0.10.0 and 0.10.1: a quoted trigger name and `ON "schema"."table"`, with
      plain `CREATE TRIGGER`;
    * 0.10.2: the same as 0.10.0 with `CREATE OR REPLACE TRIGGER`.

  Regenerating must replace that trigger, never add a second one next to it,
  so each table ends up with exactly one Threadline trigger whose name is the
  one the earlier release gave it. Rolling the regeneration back keeps that
  trigger enabled.
  """

  use Threadline.DataCase, async: false

  alias Threadline.Capture.{AuditChange, AuditTransaction, Naming, TriggerSQL}
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @schema "regen_s"

  # One public table per historical form, plus a table outside public for the
  # two forms that could qualify it. Short names, so nothing is cut.
  @v0_9_table {"public", "regen_nine"}
  @v0_10_0_tables [{"public", "regen_ten"}, {@schema, "ten"}]
  @v0_10_2_tables [{"public", "regen_twelve"}, {@schema, "twelve"}]

  @tables [@v0_9_table] ++ @v0_10_0_tables ++ @v0_10_2_tables

  setup do
    previous_shell = Mix.shell()
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-legacy-regeneration-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)
    drop_all!()

    Repo.query!(TriggerSQL.install_function([]))
    Repo.query!("CREATE SCHEMA #{@schema}")

    for {schema, table} <- @tables do
      Repo.query!("""
      CREATE TABLE #{ref(schema, table)} (
        id     bigserial PRIMARY KEY,
        email  text,
        secret text
      )
      """)
    end

    Repo.delete_all(AuditChange, repo_opts())
    Repo.delete_all(AuditTransaction, repo_opts())

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_capture do
        {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
        :error -> Application.delete_env(:threadline, :trigger_capture)
      end

      Harness.cleanup!(Harness.migration_files(tmp))
      drop_all!()
      File.rm_rf!(tmp)
    end)

    %{tmp: tmp}
  end

  describe "regenerating a table with a 0.9.0 trigger" do
    test "keeps exactly one trigger with the same name, through up and down", %{tmp: tmp} do
      {"public", table} = @v0_9_table

      # The database gets the storage-qualified function, because an
      # unqualified call would resolve through search_path. The migration
      # text keeps the release's exact bytes.
      Repo.query!(LegacyTriggerSQL.v0_9_create_trigger(table, global_function_ref()))

      write_fixture_migration!(
        tmp,
        "20230101000000_threadline_triggers_regen_nine.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersRegenNine",
        [LegacyTriggerSQL.v0_9_create_trigger(table)],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{table} ON #{table}"]
      )

      expected = %{@v0_9_table => "threadline_audit_regen_nine"}
      assert_regenerates_in_place!(tmp, expected, [table])
    end
  end

  describe "regenerating tables with a 0.10.0 trigger" do
    test "keeps exactly one trigger per table with the same name, through up and down",
         %{tmp: tmp} do
      creates =
        for {schema, table} <- @v0_10_0_tables,
            do: LegacyTriggerSQL.v0_10_0_create_trigger(schema, table, global_function_ref())

      Enum.each(creates, &Repo.query!/1)

      write_fixture_migration!(
        tmp,
        "20240101000000_threadline_triggers_regen_ten_regen_s_ten.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersRegenTenRegenSTen",
        for(
          {schema, table} <- @v0_10_0_tables,
          do: LegacyTriggerSQL.v0_10_0_create_trigger(schema, table)
        ),
        []
      )

      expected = %{
        {"public", "regen_ten"} => "threadline_audit_regen_ten",
        {@schema, "ten"} => "threadline_audit_regen_s_ten"
      }

      assert_regenerates_in_place!(tmp, expected, ["regen_ten", "regen_s.ten"])
    end
  end

  describe "regenerating tables with a 0.10.2 trigger" do
    setup %{tmp: tmp} do
      creates =
        for {schema, table} <- @v0_10_2_tables,
            do: LegacyTriggerSQL.v0_10_2_create_trigger(schema, table, global_function_ref())

      Enum.each(creates, &Repo.query!/1)

      write_fixture_migration!(
        tmp,
        "20250101000000_threadline_triggers_regen_twelve_regen_s_twelve.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersRegenTwelveRegenSTwelve",
        for(
          {schema, table} <- @v0_10_2_tables,
          do: LegacyTriggerSQL.v0_10_2_create_trigger(schema, table)
        ),
        []
      )

      :ok
    end

    @v0_10_2_names %{
      {"public", "regen_twelve"} => "threadline_audit_regen_twelve",
      {"regen_s", "twelve"} => "threadline_audit_regen_s_twelve"
    }

    test "keeps exactly one trigger per table with the same name, through up and down",
         %{tmp: tmp} do
      assert_regenerates_in_place!(tmp, @v0_10_2_names, ["regen_twelve", "regen_s.twelve"])
    end

    test "in per-table mode, keeps one trigger per table and applies the mask", %{tmp: tmp} do
      Application.put_env(:threadline, :trigger_capture,
        tables: %{
          "regen_twelve" => [mask: ["secret"]],
          "regen_s.twelve" => [mask: ["secret"]]
        }
      )

      file = Harness.generate!(tmp, ["--tables", "regen_twelve,regen_s.twelve"])
      assert {:ok, _log} = Harness.migrate_up(file)

      for {{schema, table} = pair, name} <- @v0_10_2_names do
        assert Harness.threadline_triggers(schema, table) == [{name, "O"}]

        assert Harness.trigger_function(schema, table) ==
                 {StorageSchema.get(), Naming.function_name(%{schema: schema, table: table})}

        row = insert_and_capture!(pair)
        assert row["secret"] == "[REDACTED]"
        assert row["email"] == "e-" <> table
      end

      assert {:ok, _log} = Harness.migrate_down(file)

      for {{schema, table}, name} <- @v0_10_2_names do
        assert Harness.threadline_triggers(schema, table) == [{name, "O"}]
      end
    end
  end

  # Regenerates `tables` in default mode over the fixture triggers, then
  # checks every table in `expected` after up and again after down.
  defp assert_regenerates_in_place!(tmp, expected, tables) do
    file = Harness.generate!(tmp, ["--tables", Enum.join(tables, ",")])

    # Each table already had a trigger migration, so the rollback drops nothing.
    [_up, down] = file |> File.read!() |> String.split("def down do")
    refute down =~ "execute"

    assert {:ok, _log} = Harness.migrate_up(file)

    for {{schema, table}, name} <- expected do
      assert [{^name, "O"}] = Harness.threadline_triggers(schema, table)

      assert Harness.trigger_function(schema, table) ==
               {StorageSchema.get(), "threadline_capture_changes"}

      row = insert_and_capture!({schema, table})
      assert row["secret"] == "s-" <> table
    end

    assert {:ok, _log} = Harness.migrate_down(file)

    for {{schema, table}, name} <- expected do
      triggers = Harness.threadline_triggers(schema, table)
      assert length(triggers) == 1, "#{schema}.#{table} has #{inspect(triggers)}"
      assert [{^name, "O"}] = triggers
    end
  end

  defp global_function_ref, do: StorageSchema.function("threadline_capture_changes") <> "()"

  defp write_fixture_migration!(tmp, basename, module, creates, drops) do
    migrations = Path.join([tmp, "priv", "repo", "migrations"])
    File.mkdir_p!(migrations)

    File.write!(
      Path.join(migrations, basename),
      LegacyTriggerSQL.migration_source(module, creates, drops)
    )
  end

  # Inserts one row and returns the data_after captured for it.
  defp insert_and_capture!({schema, table}) do
    Repo.query!(
      "INSERT INTO #{ref(schema, table)} (email, secret) VALUES ($1, $2)",
      ["e-" <> table, "s-" <> table]
    )

    [change] =
      AuditChange
      |> where([c], c.table_schema == ^schema and c.table_name == ^table)
      |> Repo.all(repo_opts())

    assert change.op == "insert"
    change.data_after
  end

  # Drops triggers before functions, so no drop needs to cascade. Tables are
  # dropped by schema-qualified name, which also removes their triggers.
  defp drop_all! do
    for {schema, table} <- @tables do
      Repo.query!("""
      DO $$ BEGIN
        IF to_regclass('#{ref(schema, table)}') IS NOT NULL THEN
          EXECUTE 'DROP TRIGGER IF EXISTS #{StorageSchema.quote_ident(trigger_name(schema, table))} ON #{ref(schema, table)}';
        END IF;
      END $$
      """)
    end

    functions =
      Enum.flat_map(@tables, fn {schema, table} ->
        pair = %{schema: schema, table: table}
        [Naming.function_name(pair), Naming.legacy_function_name(pair)]
      end)

    for name <- Enum.uniq(functions) do
      Repo.query!("DROP FUNCTION IF EXISTS " <> StorageSchema.function(name) <> "()")
    end

    for {schema, table} <- @tables do
      Repo.query!("DROP TABLE IF EXISTS #{ref(schema, table)}")
    end

    Repo.query!("DROP SCHEMA IF EXISTS #{@schema}")
  end

  defp trigger_name(schema, table),
    do: Naming.trigger_name(%{schema: schema, table: table})

  defp ref(schema, table),
    do: StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)
end
