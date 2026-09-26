defmodule Threadline.UpgradeRollbackTest do
  @moduledoc """
  Proves, against the live PostgreSQL catalog, that rolling back a whole
  upgraded 0.10.x-to-0.11 fixture set leaves no orphan capture function and
  drops no trigger that is not Threadline's own.

  Existing tests (`legacy_function_upgrade_test.exs`,
  `legacy_trigger_regeneration_test.exs`) prove only the generated SQL text
  and single-migration up/down round trips; this module is the first to walk
  a whole `Ecto.Migrator.run(..., :down, all: true)` sweep and inspect
  `pg_proc`/`pg_trigger`/`pg_namespace` directly afterward (D-09).

  The hazard under test: releases up to 0.10.2 ended a trigger migration's
  `down` with a per-table function drop that cascades (`DROP FUNCTION ...
  CASCADE`, frozen in `LegacyTriggerSQL.v0_10_2_drop_function_for_table/2`).
  If a table's function was ever shared with another table (the phase-209
  issue), rolling that migration back as generated could cascade-drop the
  sibling table's live trigger too. `guides/upgrading-to-0.11.md`'s "Rolling
  back" section tells adopters to edit such a migration's `down` first: drop
  only its own triggers, then run the guide's rollback-cleanup SQL (a
  no-cascade sweep that only drops a per-table function no trigger still
  references) in place of the original cascading drop. This module builds
  its 0.10.x shared-pair fixture with exactly that edited `down`, because
  that is the down an adopter following the guide will actually run.

  Scope note: the suite's own install migration and its global
  `threadline_capture_changes()` function are not in the tmp migrations path
  built here, so the global function is covered by the baseline snapshot
  taken before any fixture exists, rather than rolled back by this test.
  """

  use Threadline.DataCase, async: false

  alias Mix.Tasks.Threadline.Gen.RowHistoryIndex
  alias Threadline.Capture.{Naming, RowHistoryIndexSQL, TriggerSQL}
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @guide_path "guides/upgrading-to-0.11.md"
  @rollback_marker_start "<!-- threadline:rollback-cleanup-sql:start -->"
  @rollback_marker_end "<!-- threadline:rollback-cleanup-sql:end -->"

  @acct_table "rb_accounts"
  @unaudited_table "rb_unaudited"
  @public_pair {"public", "billing_invoices"}
  @schema_pair {"billing", "invoices"}
  @shared_function "threadline_capture_changes_billing_invoices"
  @host_function "rb_host_touch"

  @fixture_tables [
    {"public", @acct_table},
    {"public", @unaudited_table},
    @public_pair,
    @schema_pair
  ]

  setup do
    storage = StorageSchema.get()
    previous_shell = Mix.shell()
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-upgrade-rollback-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)
    drop_fixtures!()

    # Taken before any fixture in this test exists, so a suffixed function
    # left behind by an earlier test run (there should be none, but this is
    # the live catalog, not a sandboxed transaction) is never mistaken for
    # one this rollback orphaned.
    baseline_functions = suffixed_functions(storage)

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_capture do
        {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
        :error -> Application.delete_env(:threadline, :trigger_capture)
      end

      Repo.query!(TriggerSQL.install_function([]))
      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!()

      # Rolling back the row-history index migration drops the suite-shared
      # index; every later test expects it present and valid.
      Repo.query!(RowHistoryIndexSQL.create_sql(storage_schema: storage))
      File.rm_rf!(tmp)
    end)

    %{tmp: tmp, storage: storage, baseline_functions: baseline_functions}
  end

  describe "rolling back a whole upgraded fixture" do
    test "leaves no orphan capture function and drops no foreign trigger", %{
      tmp: tmp,
      storage: storage,
      baseline_functions: baseline_functions
    } do
      # --- The frozen renderer documents the hazard, as text only ---
      unedited_down = LegacyTriggerSQL.v0_10_2_drop_function_for_table(@shared_function, storage)
      assert unedited_down =~ "CASCADE"
      assert unedited_down =~ @shared_function

      # --- Foreign (non-Threadline) trigger fixture, created first (D-09) ---

      Repo.query!("""
      CREATE TABLE #{@acct_table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      Repo.query!("""
      CREATE TABLE #{@unaudited_table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      Repo.query!("""
      CREATE OR REPLACE FUNCTION #{@host_function}()
      RETURNS TRIGGER
      LANGUAGE plpgsql
      AS $$
      BEGIN
        RETURN NEW;
      END;
      $$
      """)

      Repo.query!(
        "CREATE TRIGGER host_touch_rb_accounts AFTER UPDATE ON #{@acct_table} " <>
          "FOR EACH ROW EXECUTE FUNCTION #{@host_function}()"
      )

      Repo.query!(
        "CREATE TRIGGER host_touch_rb_unaudited AFTER UPDATE ON #{@unaudited_table} " <>
          "FOR EACH ROW EXECUTE FUNCTION #{@host_function}()"
      )

      accounts_foreign_before = foreign_trigger_snapshot(@acct_table, "host_touch_rb_accounts")

      unaudited_foreign_before =
        foreign_trigger_snapshot(@unaudited_table, "host_touch_rb_unaudited")

      assert accounts_foreign_before != nil
      assert unaudited_foreign_before != nil

      # --- The 0.10.x fixture: one default-mode table, one shared pair ---

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @acct_table,
          StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      accounts_fixture =
        write_fixture_migration!(
          tmp,
          "20240401000000_threadline_triggers_rb_accounts.exs",
          "Threadline.Test.Repo.Migrations.ThreadlineTriggersRbAccounts",
          [
            LegacyTriggerSQL.v0_10_2_create_trigger(
              "public",
              @acct_table,
              StorageSchema.function("threadline_capture_changes") <> "()"
            )
          ],
          ["DROP TRIGGER IF EXISTS threadline_audit_#{@acct_table} ON #{@acct_table}"]
        )

      assert {:ok, _log} = Harness.migrate_up(accounts_fixture)

      Repo.query!("CREATE SCHEMA IF NOT EXISTS billing")

      for {schema, table} <- [@public_pair, @schema_pair] do
        Repo.query!("""
        CREATE TABLE #{ref(schema, table)} (
          id     bigserial PRIMARY KEY,
          email  text,
          secret text
        )
        """)
      end

      shared_fixture_sql =
        LegacyTriggerSQL.v0_10_2_install_function_for_table(
          @shared_function,
          storage,
          mask: ["secret"]
        )

      assert shared_fixture_sql =~ StorageSchema.function(@shared_function) <> "()"
      Repo.query!(shared_fixture_sql)

      shared_function_ref = StorageSchema.function(@shared_function) <> "()"

      for {schema, table} <- [@public_pair, @schema_pair] do
        Repo.query!(LegacyTriggerSQL.v0_10_2_create_trigger(schema, table, shared_function_ref))
      end

      # The down an adopter following the guide actually runs: its own
      # trigger drops, then the guide's verbatim rollback-cleanup SQL in
      # place of the original cascading function drop.
      rollback_cleanup_sql =
        extract_marker(@guide_path, @rollback_marker_start, @rollback_marker_end)
        |> substitute(%{"<storage_schema>" => storage})

      billing_downs =
        for(
          {schema, table} <- [@public_pair, @schema_pair],
          do:
            ~s|DROP TRIGGER IF EXISTS "threadline_audit_billing_invoices" ON #{ref(schema, table)}|
        ) ++ [rollback_cleanup_sql]

      billing_fixture =
        write_fixture_migration!(
          tmp,
          "20240402000000_threadline_triggers_billing_invoices_invoices.exs",
          "Threadline.Test.Repo.Migrations.ThreadlineTriggersBillingInvoicesInvoices",
          for(
            {schema, table} <- [@public_pair, @schema_pair],
            do: LegacyTriggerSQL.v0_10_2_create_trigger(schema, table, shared_function_ref)
          ),
          billing_downs
        )

      assert {:ok, _log} = Harness.migrate_up(billing_fixture)

      # --- The upgrade, exactly as the guide documents ---

      default_file = Harness.generate!(tmp, ["--tables", @acct_table])
      assert {:ok, _log} = Harness.migrate_up(default_file)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{
          "billing_invoices" => [mask: ["secret"]],
          "billing.invoices" => [mask: ["secret"]]
        }
      )

      shared_file = Harness.generate!(tmp, ["--tables", "billing_invoices,billing.invoices"])
      assert {:ok, _log} = Harness.migrate_up(shared_file)

      index_migration =
        File.cd!(tmp, fn ->
          RowHistoryIndex.run([])

          [tmp, "priv", "repo", "migrations", "*_threadline_row_history_index.exs"]
          |> Path.join()
          |> Path.wildcard()
        end)
        |> List.first()

      assert {:ok, _log} = Harness.migrate_up(index_migration)

      # --- Roll everything in the tmp path back ---

      migrations_path = Path.join([tmp, "priv", "repo", "migrations"])
      previous_compiler_opts = Code.compiler_options()
      Code.compiler_options(ignore_module_conflict: true)

      try do
        Ecto.Migrator.run(Repo, migrations_path, :down, all: true, log: false)
      after
        Code.compiler_options(previous_compiler_opts)
      end

      # --- Assertions against the live catalog ---

      post_functions = suffixed_functions(storage)
      assert post_functions -- baseline_functions == []

      for name <- post_functions -- baseline_functions do
        assert function_has_trigger?(storage, name)
      end

      for {schema, table} <- [@public_pair, @schema_pair, {"public", @acct_table}] do
        assert Harness.threadline_triggers(schema, table) == []
      end

      accounts_foreign_after = foreign_trigger_snapshot(@acct_table, "host_touch_rb_accounts")

      unaudited_foreign_after =
        foreign_trigger_snapshot(@unaudited_table, "host_touch_rb_unaudited")

      assert accounts_foreign_after == accounts_foreign_before
      assert unaudited_foreign_after == unaudited_foreign_before
    end
  end

  # ---------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------

  defp extract_marker(path, marker_start, marker_end) do
    content = File.read!(path)
    [_before, rest] = String.split(content, marker_start, parts: 2)
    [block, _after] = String.split(rest, marker_end, parts: 2)

    block
    |> String.split("\n")
    |> Enum.reject(&(String.trim(&1) in ["```sql", "```", ""]))
    |> Enum.join("\n")
  end

  defp substitute(sql, replacements) do
    Enum.reduce(replacements, sql, fn {placeholder, value}, acc ->
      String.replace(acc, placeholder, value)
    end)
  end

  defp suffixed_functions(storage) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = $1
          AND p.proname LIKE 'threadline\\_capture\\_changes\\_%' ESCAPE '\\'
        ORDER BY p.proname
        """,
        [storage]
      )

    Enum.map(rows, fn [name] -> name end)
  end

  defp function_has_trigger?(storage, function_name) do
    %{rows: [[count]]} =
      Repo.query!(
        """
        SELECT count(*)
        FROM pg_trigger t
        JOIN pg_proc p ON p.oid = t.tgfoid
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = $1 AND p.proname = $2 AND NOT t.tgisinternal
        """,
        [storage, function_name]
      )

    count > 0
  end

  defp foreign_trigger_snapshot(table, trigger_name) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT t.tgname, t.tgfoid, t.tgenabled
        FROM pg_trigger t
        WHERE t.tgrelid = $1::text::regclass AND t.tgname = $2
        """,
        [table, trigger_name]
      )

    case rows do
      [[name, foid, enabled]] -> {name, foid, enabled}
      [] -> nil
    end
  end

  defp write_fixture_migration!(tmp, basename, module, creates, drops) do
    migrations = Path.join([tmp, "priv", "repo", "migrations"])
    File.mkdir_p!(migrations)
    file = Path.join(migrations, basename)
    File.write!(file, LegacyTriggerSQL.migration_source(module, creates, drops))
    file
  end

  defp drop_fixtures! do
    for {schema, table} <- @fixture_tables do
      Repo.query!("""
      DO $$ BEGIN
        IF to_regclass('#{ref(schema, table)}') IS NOT NULL THEN
          EXECUTE 'DROP TRIGGER IF EXISTS host_touch_#{table} ON #{ref(schema, table)}';
          EXECUTE 'DROP TRIGGER IF EXISTS #{StorageSchema.quote_ident(Naming.trigger_name(%{schema: schema, table: table}))} ON #{ref(schema, table)}';
        END IF;
      END $$
      """)
    end

    Repo.query!("DROP FUNCTION IF EXISTS #{@host_function}() CASCADE")

    for {schema, table} <- @fixture_tables do
      functions = [
        Naming.function_name(%{schema: schema, table: table}),
        Naming.legacy_function_name(%{schema: schema, table: table})
      ]

      for name <- Enum.uniq(functions) do
        Repo.query!("DROP FUNCTION IF EXISTS " <> StorageSchema.function(name) <> "()")
      end
    end

    Repo.query!("DROP FUNCTION IF EXISTS " <> StorageSchema.function(@shared_function) <> "()")

    for {schema, table} <- @fixture_tables do
      Repo.query!("DROP TABLE IF EXISTS #{ref(schema, table)}")
    end

    Repo.query!("DROP SCHEMA IF EXISTS billing")
  end

  defp ref(schema, table),
    do: StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)
end
