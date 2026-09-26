defmodule Threadline.Capture.LegacyFunctionUpgradeTest do
  @moduledoc """
  Upgrades an install that earlier releases left with two tables on one
  capture function, by generating trigger migrations with
  `mix threadline.gen.triggers` and applying them through `Ecto.Migrator`.

  Releases up to 0.10.2 named a table's capture function from its schema and
  table joined by "_", so public.billing_invoices and billing.invoices shared
  threadline_capture_changes_billing_invoices, and whichever table was
  generated last set the redaction rules for both. Current releases give
  billing.invoices its own hashed function, while public.billing_invoices keeps
  the old name.

  Regenerating a table must never leave another table on rules that are not
  its own: either the migration fails and applies nothing, or every table ends
  up capturing with its own rules and a WARNING names any table still on the
  old shared function.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction, Naming, TriggerSQL}
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @public_pair {"public", "billing_invoices"}
  @schema_pair {"billing", "invoices"}

  # The name both tables' 0.10.x triggers called.
  @shared_function "threadline_capture_changes_billing_invoices"

  @fix_command "mix threadline.gen.triggers --tables billing_invoices,billing.invoices"

  # Both names share their first 36 bytes, so releases before 0.10 cut both
  # capture function names to the same 63 bytes.
  @long_a "customer_subscription_billing_archive_2024"
  @long_b "customer_subscription_billing_archive_2025"
  @long_shared binary_part("threadline_capture_changes_" <> @long_a, 0, 63)

  @billing_pairs [@public_pair, @schema_pair]
  @tables @billing_pairs ++ [{"public", @long_a}, {"public", @long_b}]

  setup do
    previous_shell = Mix.shell()
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-legacy-upgrade-#{System.unique_integer([:positive])}"
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

  describe "an install where two tables share one capture function" do
    setup %{tmp: tmp} do
      install_shared_function_fixture!(tmp)

      put_capture(%{
        "billing_invoices" => [mask: ["email"]],
        "billing.invoices" => [mask: ["secret"], exclude: ["notes"]]
      })

      :ok
    end

    test "regenerating only the table that keeps the shared name fails and applies nothing",
         %{tmp: tmp} do
      before = Harness.function_definition(@shared_function)
      storage = StorageSchema.get()

      file = Harness.generate!(tmp, ["--tables", "billing_invoices"])

      error = assert_raise Postgrex.Error, fn -> Harness.migrate_up(file) end

      assert error.postgres.message =~ "billing.invoices"
      assert error.postgres.message =~ "may now apply another table's redaction rules"
      assert error.postgres.hint =~ @fix_command
      assert error.postgres.hint =~ "regenerate billing.invoices first"

      assert Harness.function_definition(@shared_function) == before
      assert Harness.trigger_function("public", "billing_invoices") == {storage, @shared_function}
      assert Harness.trigger_function("billing", "invoices") == {storage, @shared_function}
      refute migrated?(file)

      # billing.invoices still captures with the rules it had before.
      row = insert_and_capture!(@schema_pair)
      assert row["secret"] == "[REDACTED]"
      assert row["email"] == "e-invoices"
      refute Map.has_key?(row, "notes")
    end

    test "regenerating only the moved table succeeds and names the table left behind",
         %{tmp: tmp} do
      storage = StorageSchema.get()
      hashed = "threadline_capture_changes_billing_invoices_9bba11019407"
      assert Naming.function_name("billing.invoices") == hashed

      file = Harness.generate!(tmp, ["--tables", "billing.invoices"])
      assert {:ok, log} = Harness.migrate_up(file)

      assert Harness.trigger_function("billing", "invoices") == {storage, hashed}
      assert Harness.function_users(hashed) == ["billing.invoices"]

      row = insert_and_capture!(@schema_pair)
      assert row["secret"] == "[REDACTED]"
      assert row["email"] == "e-invoices"
      refute Map.has_key?(row, "notes")

      assert Harness.function_exists?(@shared_function)
      assert Harness.function_users(@shared_function) == ["public.billing_invoices"]
      assert log =~ "threadline: kept"
      assert log =~ "public.billing_invoices"

      # billing.invoices already had a trigger migration, so rolling this one
      # back drops nothing.
      [_up, down] = file |> File.read!() |> String.split("def down do")
      refute down =~ "execute"
      refute down =~ "DROP"

      assert {:ok, _log} = Harness.migrate_down(file)

      assert Harness.threadline_triggers("public", "billing_invoices") ==
               [{"threadline_audit_billing_invoices", "O"}]

      assert Harness.threadline_triggers("billing", "invoices") ==
               [{"threadline_audit_billing_invoices", "O"}]
    end

    test "after the refusal, regenerating both tables together gives each its own rules",
         %{tmp: tmp} do
      storage = StorageSchema.get()
      hashed = Naming.function_name("billing.invoices")

      refused = Harness.generate!(tmp, ["--tables", "billing_invoices"])
      assert_raise Postgrex.Error, fn -> Harness.migrate_up(refused) end

      file = Harness.generate!(tmp, ["--tables", "billing_invoices,billing.invoices"])
      assert {:ok, log} = Harness.migrate_up(file)
      refute log =~ "threadline: kept"

      assert Harness.trigger_function("public", "billing_invoices") == {storage, @shared_function}
      assert Harness.trigger_function("billing", "invoices") == {storage, hashed}
      assert length(Harness.function_users(@shared_function)) == 1
      assert length(Harness.function_users(hashed)) == 1

      # The old name stays with public.billing_invoices, rewritten with its
      # rules only.
      definition = Harness.function_definition(@shared_function)
      assert definition =~ "jsonb_build_object('email'"
      refute definition =~ "'secret'"
      refute definition =~ "'notes'"

      public_row = insert_and_capture!(@public_pair)
      assert public_row["email"] == "[REDACTED]"
      assert public_row["secret"] == "s-billing_invoices"
      assert Map.has_key?(public_row, "notes")
      assert public_row["notes"] == "n-billing_invoices"

      schema_row = insert_and_capture!(@schema_pair)
      assert schema_row["secret"] == "[REDACTED]"
      assert schema_row["email"] == "e-invoices"
      refute Map.has_key?(schema_row, "notes")

      assert [{_, "O"}] = Harness.threadline_triggers("public", "billing_invoices")
      assert [{_, "O"}] = Harness.threadline_triggers("billing", "invoices")
    end
  end

  describe "an install where two long table names share one cut capture function" do
    setup %{tmp: tmp} do
      install_long_shared_function_fixture!(tmp)

      put_capture(%{
        @long_a => [mask: ["secret"]],
        @long_b => [mask: ["email"], exclude: ["notes"]]
      })

      :ok
    end

    test "either table can be regenerated alone, and the old function goes with the last",
         %{tmp: tmp} do
      storage = StorageSchema.get()
      fn_a = Naming.function_name(@long_a)
      fn_b = Naming.function_name(@long_b)
      assert fn_a =~ ~r/_[0-9a-f]{12}\z/
      assert fn_b =~ ~r/_[0-9a-f]{12}\z/

      file_a = Harness.generate!(tmp, ["--tables", @long_a])
      assert {:ok, log_a} = Harness.migrate_up(file_a)

      assert Harness.trigger_function("public", @long_a) == {storage, fn_a}
      assert Harness.function_users(@long_shared) == ["public." <> @long_b]
      assert log_a =~ "threadline: kept"
      assert log_a =~ "public." <> @long_b

      row_a = insert_and_capture!({"public", @long_a})
      assert row_a["secret"] == "[REDACTED]"
      assert row_a["email"] == "e-" <> @long_a
      assert row_a["notes"] == "n-" <> @long_a

      file_b = Harness.generate!(tmp, ["--tables", @long_b])
      assert {:ok, log_b} = Harness.migrate_up(file_b)
      refute log_b =~ "threadline: kept"

      assert Harness.trigger_function("public", @long_b) == {storage, fn_b}
      refute Harness.function_exists?(@long_shared)

      row_b = insert_and_capture!({"public", @long_b})
      assert row_b["email"] == "[REDACTED]"
      assert row_b["secret"] == "s-" <> @long_b
      refute Map.has_key?(row_b, "notes")
    end
  end

  describe "a project installed on the current release" do
    test "adding billing.invoices after public.billing_invoices warns but keeps each table's rules",
         %{tmp: tmp} do
      put_capture(%{
        "billing_invoices" => [mask: ["email"], exclude: ["notes"]],
        "billing.invoices" => [mask: ["secret"]]
      })

      first = Harness.generate!(tmp, ["--tables", "billing_invoices"])
      assert {:ok, first_log} = Harness.migrate_up(first)
      refute first_log =~ "threadline: kept"

      second = Harness.generate!(tmp, ["--tables", "billing.invoices"])
      assert {:ok, second_log} = Harness.migrate_up(second)

      # public.billing_invoices legitimately owns the name billing.invoices
      # used before, so the old name is kept and the WARNING names it.
      assert second_log =~ "threadline: kept"
      assert second_log =~ "public.billing_invoices"
      assert Harness.function_users(@shared_function) == ["public.billing_invoices"]

      public_row = insert_and_capture!(@public_pair)
      assert public_row["email"] == "[REDACTED]"
      assert public_row["secret"] == "s-billing_invoices"
      refute Map.has_key?(public_row, "notes")

      schema_row = insert_and_capture!(@schema_pair)
      assert schema_row["secret"] == "[REDACTED]"
      assert schema_row["email"] == "e-invoices"
      assert schema_row["notes"] == "n-invoices"
    end
  end

  # The state a 0.10.x install is left in after generating public.billing_invoices
  # and then billing.invoices: one function carrying billing.invoices's rules,
  # called by both tables' triggers, and one trigger migration listing both.
  defp install_shared_function_fixture!(tmp) do
    fixture_sql =
      TriggerSQL.install_function_for_table("billing_invoices",
        mask: ["secret"],
        exclude: ["notes"]
      )

    assert fixture_sql =~ StorageSchema.function(@shared_function) <> "()"
    Repo.query!(fixture_sql)

    function_ref = StorageSchema.function(@shared_function) <> "()"

    creates =
      for {schema, table} <- @billing_pairs,
          do: LegacyTriggerSQL.v0_10_2_create_trigger(schema, table, function_ref)

    Enum.each(creates, &Repo.query!/1)

    drops =
      for {schema, table} <- @billing_pairs,
          do:
            ~s|DROP TRIGGER IF EXISTS "threadline_audit_billing_invoices" ON #{ref(schema, table)}|

    write_fixture_migration!(
      tmp,
      "20250101000000_threadline_triggers_billing_invoices_invoices.exs",
      "Threadline.Test.Repo.Migrations.ThreadlineTriggersBillingInvoicesInvoices",
      creates,
      drops
    )
  end

  # The state a pre-0.10 install is left in after generating @long_a and then
  # @long_b with per-table rules: PostgreSQL cut both function names to the
  # same 63 bytes, so one function carries @long_b's rules and both unqualified
  # triggers call it. The fixture creates the function under the name
  # PostgreSQL stored, so it truncates nothing.
  defp install_long_shared_function_fixture!(tmp) do
    assert byte_size(@long_shared) == 63
    assert binary_part(@long_a, 0, 36) == binary_part(@long_b, 0, 36)

    body =
      @long_b
      |> TriggerSQL.install_function_for_table(mask: ["email"], exclude: ["notes"])
      |> String.replace(Naming.function_name(@long_b), @long_shared)

    assert body =~ StorageSchema.function(@long_shared) <> "()"
    Repo.query!(body)

    for table <- [@long_a, @long_b] do
      Repo.query!(
        LegacyTriggerSQL.v0_9_create_trigger(
          table,
          StorageSchema.function(@long_shared) <> "()"
        )
      )
    end

    # The migration text as that release wrote it, with the uncut name.
    creates =
      for table <- [@long_a, @long_b],
          do: LegacyTriggerSQL.v0_9_create_trigger(table, "threadline_capture_changes_#{table}()")

    drops =
      for table <- [@long_a, @long_b],
          do: "DROP TRIGGER IF EXISTS threadline_audit_#{table} ON #{table}"

    write_fixture_migration!(
      tmp,
      "20240101000000_threadline_triggers_customer_subscription_billing_archive.exs",
      "Threadline.Test.Repo.Migrations.ThreadlineTriggersCustomerSubscriptionBillingArchive",
      creates,
      drops
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

  defp put_capture(tables),
    do: Application.put_env(:threadline, :trigger_capture, tables: tables)

  defp migrated?(file) do
    {version, "_" <> _} = file |> Path.basename() |> Integer.parse()

    %{rows: [[count]]} =
      Repo.query!("SELECT count(*) FROM schema_migrations WHERE version = $1", [version])

    count > 0
  end

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

    Repo.query!("DROP SCHEMA IF EXISTS billing")
  end

  defp trigger_name(schema, table),
    do: Naming.trigger_name(%{schema: schema, table: table})

  defp ref(schema, table),
    do: StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)
end
