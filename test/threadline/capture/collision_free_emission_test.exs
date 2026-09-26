defmodule Threadline.Capture.CollisionFreeEmissionTest do
  @moduledoc """
  Generates trigger migrations with `mix threadline.gen.triggers` and applies
  them through `Ecto.Migrator`, the way an adopter runs them. Every table must
  get its own capture function and apply only its own redaction rules, and
  rolling back one table's migration must leave every other table's capture in
  place.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction, Naming, TriggerSQL}
  alias Threadline.StorageSchema
  alias Threadline.Test.MigrationHarness, as: Harness

  # public.billing_invoices and billing.invoices once shared one capture
  # function name, threadline_capture_changes_billing_invoices.
  @public_pair {"public", "billing_invoices"}
  @schema_pair {"billing", "invoices"}

  # Both names share their first 36 bytes, the longest public table name that
  # keeps its legacy capture function name.
  @long_a "customer_subscription_billing_ledger_2024"
  @long_b "customer_subscription_billing_ledger_2025"

  # Both names share their first 46 bytes, so both are cut to the same
  # 63-byte trigger name.
  @prefix46 "customer_invoice_line_item_adjustment_history_"
  @shared_a @prefix46 <> "alpha"
  @shared_b @prefix46 <> "beta"

  @tables [
    @public_pair,
    @schema_pair,
    {"public", @long_a},
    {"public", @long_b},
    {"public", @shared_a},
    {"public", @shared_b}
  ]

  # PostgreSQL clones a row trigger on a partitioned table onto each
  # partition, calling the same function. The parent comes first, so dropping
  # its trigger and table also drops the partition's.
  @partitioned "audited_events"
  @partition "audited_events_default"
  @partition_tables [{"public", @partitioned}, {"public", @partition}]

  setup do
    previous_shell = Mix.shell()
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-collision-free-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)
    drop_all!()

    Repo.query!(TriggerSQL.install_function([]))
    Repo.query!("CREATE SCHEMA billing")

    for {schema, table} <- @tables do
      Repo.query!("""
      CREATE TABLE #{ref(schema, table)} (
        id     bigserial PRIMARY KEY,
        email  text,
        secret text,
        notes  text
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

  describe "a fresh install gives every table its own capture function" do
    test "a public table and a schema table with the same function suffix", %{tmp: tmp} do
      put_capture(%{
        "billing_invoices" => [mask: ["email"], exclude: ["notes"]],
        "billing.invoices" => [mask: ["secret"]]
      })

      file = Harness.generate!(tmp, ["--tables", "billing_invoices,billing.invoices"])
      assert {:ok, _log} = Harness.migrate_up(file)

      storage = StorageSchema.get()

      assert Harness.trigger_function("public", "billing_invoices") ==
               {storage, "threadline_capture_changes_billing_invoices"}

      assert Harness.trigger_function("billing", "invoices") ==
               {storage, "threadline_capture_changes_billing_invoices_9bba11019407"}

      public_row = insert_and_capture!(@public_pair)
      assert public_row["email"] == "[REDACTED]"
      assert public_row["secret"] == "s-billing_invoices"
      refute Map.has_key?(public_row, "notes")

      schema_row = insert_and_capture!(@schema_pair)
      assert schema_row["secret"] == "[REDACTED]"
      assert schema_row["email"] == "e-invoices"
      assert Map.has_key?(schema_row, "notes")
      assert schema_row["notes"] == "n-invoices"
    end

    test "two public tables that share their first 36 bytes", %{tmp: tmp} do
      put_capture(%{
        @long_a => [mask: ["secret"], exclude: ["notes"]],
        @long_b => [mask: ["notes"]]
      })

      file = Harness.generate!(tmp, ["--tables", "#{@long_a},#{@long_b}"])
      assert {:ok, _log} = Harness.migrate_up(file)

      {_, fn_a} = Harness.trigger_function("public", @long_a)
      {_, fn_b} = Harness.trigger_function("public", @long_b)

      assert fn_a != fn_b
      assert fn_a =~ ~r/_[0-9a-f]{12}\z/
      assert fn_b =~ ~r/_[0-9a-f]{12}\z/
      assert Harness.function_users(fn_a) == ["public." <> @long_a]
      assert Harness.function_users(fn_b) == ["public." <> @long_b]

      row_a = insert_and_capture!({"public", @long_a})
      assert row_a["secret"] == "[REDACTED]"
      refute Map.has_key?(row_a, "notes")

      row_b = insert_and_capture!({"public", @long_b})
      assert row_b["secret"] == "s-" <> @long_b
      assert Map.has_key?(row_b, "notes")
      assert row_b["notes"] == "[REDACTED]"
    end
  end

  describe "a partitioned table" do
    test "migrates up and down without counting its partitions as other tables",
         %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE #{ref("public", @partitioned)} (
        id     bigserial,
        email  text,
        secret text,
        notes  text,
        PRIMARY KEY (id)
      ) PARTITION BY LIST (id)
      """)

      Repo.query!(
        "CREATE TABLE #{ref("public", @partition)} PARTITION OF #{ref("public", @partitioned)} DEFAULT"
      )

      put_capture(%{@partitioned => [mask: ["secret"], exclude: ["notes"]]})

      file = Harness.generate!(tmp, ["--tables", @partitioned])
      assert {:ok, up_log} = Harness.migrate_up(file)
      refute up_log =~ "threadline: kept"

      fn_name = function_name("public", @partitioned)
      trigger = trigger_name("public", @partitioned)

      assert Harness.trigger_function("public", @partitioned) ==
               {StorageSchema.get(), fn_name}

      assert Harness.threadline_triggers("public", @partitioned) == [{trigger, "O"}]
      assert cloned_trigger_functions(@partition) == [fn_name]

      row = insert_and_capture!({"public", @partition})
      assert row["secret"] == "[REDACTED]"
      refute Map.has_key?(row, "notes")

      [change] =
        AuditChange
        |> where([c], c.table_schema == "public" and c.table_name == ^@partition)
        |> Repo.all(repo_opts())

      assert %{"id" => id_text} = change.table_pk
      assert is_binary(id_text)

      assert {:ok, down_log} = Harness.migrate_down(file)
      refute down_log =~ "threadline: kept"
      refute down_log =~ @partition

      assert Harness.threadline_triggers("public", @partitioned) == []
      assert cloned_trigger_functions(@partition) == []
      refute Harness.function_exists?(fn_name)
    end
  end

  describe "rolling back one table's migration leaves every other table's capture" do
    test "two tables with the same cut trigger name", %{tmp: tmp} do
      cut = "threadline_audit_" <> @prefix46
      assert byte_size(cut) == 63

      put_capture(%{
        @shared_a => [mask: ["secret"]],
        @shared_b => [mask: ["secret"]]
      })

      file_a = Harness.generate!(tmp, ["--tables", @shared_a])
      assert {:ok, _} = Harness.migrate_up(file_a)
      file_b = Harness.generate!(tmp, ["--tables", @shared_b])
      assert {:ok, _} = Harness.migrate_up(file_b)

      assert Harness.threadline_triggers("public", @shared_a) == [{cut, "O"}]
      assert Harness.threadline_triggers("public", @shared_b) == [{cut, "O"}]

      assert {:ok, log} = Harness.migrate_down(file_b)
      refute log =~ "threadline: kept"

      assert Harness.threadline_triggers("public", @shared_a) == [{cut, "O"}]
      assert Harness.function_exists?(function_name("public", @shared_a))

      assert Harness.function_users(function_name("public", @shared_a)) == [
               "public." <> @shared_a
             ]

      assert Harness.threadline_triggers("public", @shared_b) == []
      refute Harness.function_exists?(function_name("public", @shared_b))

      row = insert_and_capture!({"public", @shared_a})
      assert row["secret"] == "[REDACTED]"
    end

    test "a function another table's trigger still uses is kept, with a warning",
         %{tmp: tmp} do
      put_capture(%{@shared_b => [mask: ["secret"]]})

      file_b = Harness.generate!(tmp, ["--tables", @shared_b])
      assert {:ok, _} = Harness.migrate_up(file_b)

      fn_b = function_name("public", @shared_b)

      # A trigger on another table pointed at this function by hand.
      Repo.query!("""
      CREATE TRIGGER #{StorageSchema.quote_ident(trigger_name("public", "billing_invoices"))}
      AFTER INSERT OR UPDATE OR DELETE ON #{ref("public", "billing_invoices")}
      FOR EACH ROW EXECUTE FUNCTION #{StorageSchema.function(fn_b)}()
      """)

      assert {:ok, log} = Harness.migrate_down(file_b)

      assert log =~ "threadline: kept"
      assert log =~ "public.billing_invoices"
      assert Harness.function_exists?(fn_b)
      assert Harness.function_users(fn_b) == ["public.billing_invoices"]

      assert Harness.threadline_triggers("public", "billing_invoices") ==
               [{"threadline_audit_billing_invoices", "O"}]

      assert Harness.threadline_triggers("public", @shared_b) == []
    end
  end

  # The functions called by the triggers PostgreSQL cloned onto the partition.
  # PostgreSQL 14 marks clones internal, so the harness helpers skip them.
  defp cloned_trigger_functions(partition) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT p.proname
        FROM pg_trigger t
        JOIN pg_proc p ON p.oid = t.tgfoid
        WHERE t.tgrelid = $1::text::regclass AND t.tgparentid <> 0
        ORDER BY 1
        """,
        [ref("public", partition)]
      )

    Enum.map(rows, &hd/1)
  end

  defp put_capture(tables),
    do: Application.put_env(:threadline, :trigger_capture, tables: tables)

  # Inserts one row and returns the data_after captured for it.
  defp insert_and_capture!({schema, table}) do
    Repo.query!(
      "INSERT INTO #{ref(schema, table)} (email, secret, notes) VALUES ($1, $2, $3)",
      ["e-" <> table, "s-" <> table, "n-" <> table]
    )

    [change] =
      AuditChange
      |> where([c], c.table_schema == ^schema and c.table_name == ^table)
      |> Repo.all(repo_opts())

    assert change.op == "insert"
    change.data_after
  end

  # Drops triggers before functions, so no drop needs to cascade.
  defp drop_all! do
    tables = @partition_tables ++ @tables

    for {schema, table} <- tables do
      Repo.query!("""
      DO $$ BEGIN
        IF to_regclass('#{ref(schema, table)}') IS NOT NULL THEN
          EXECUTE 'DROP TRIGGER IF EXISTS #{StorageSchema.quote_ident(trigger_name(schema, table))} ON #{ref(schema, table)}';
        END IF;
      END $$
      """)
    end

    for {schema, table} <- tables do
      Repo.query!(
        "DROP FUNCTION IF EXISTS " <>
          StorageSchema.function(function_name(schema, table)) <> "()"
      )

      Repo.query!(
        "DROP FUNCTION IF EXISTS " <>
          StorageSchema.function(legacy_function_name(schema, table)) <> "()"
      )
    end

    for {schema, table} <- tables do
      Repo.query!("DROP TABLE IF EXISTS #{ref(schema, table)}")
    end

    Repo.query!("DROP SCHEMA IF EXISTS billing")
  end

  defp trigger_name(schema, table),
    do: Naming.trigger_name(%{schema: schema, table: table})

  defp function_name(schema, table),
    do: Naming.function_name(%{schema: schema, table: table})

  defp legacy_function_name(schema, table),
    do: Naming.legacy_function_name(%{schema: schema, table: table})

  defp ref(schema, table),
    do: StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)
end
