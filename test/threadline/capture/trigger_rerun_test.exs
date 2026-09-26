defmodule Threadline.Capture.TriggerRerunTest do
  @moduledoc """
  Applies the trigger DDL a rerun migration emits against the real database:
  installing the audit trigger again must replace it in place, and switching a
  table between the global and per-table capture functions must re-point the
  existing trigger.
  """

  use Threadline.DataCase

  alias Mix.Tasks.Threadline.Gen.Triggers
  alias Threadline.Capture.{AuditChange, AuditTransaction, Naming, TriggerSQL}
  alias Threadline.StorageSchema

  @table "test_trigger_rerun_target"

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@table} (
      id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name  text NOT NULL,
      value integer
    )
    """)

    Repo.query!(TriggerSQL.install_function([]))

    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@table))
      Repo.query!(TriggerSQL.drop_function_for_table(@table))
      Repo.query!("DROP TABLE IF EXISTS #{@table}")
    end)

    :ok
  end

  setup do
    Repo.query!(TriggerSQL.drop_trigger(@table))
    Repo.query!(TriggerSQL.drop_function_for_table(@table))
    Repo.query!("TRUNCATE #{@table} CASCADE")
    Repo.delete_all(AuditChange, repo_opts())
    Repo.delete_all(AuditTransaction, repo_opts())
    :ok
  end

  describe "rerunning trigger installation" do
    test "installing the trigger twice succeeds" do
      Repo.query!(TriggerSQL.create_trigger(@table))
      Repo.query!(TriggerSQL.create_trigger(@table))

      assert trigger_function() == {StorageSchema.get(), "threadline_capture_changes"}
    end

    test "a rerun re-points the trigger to the per-table function" do
      Repo.query!(TriggerSQL.create_trigger(@table))

      Repo.query!(
        TriggerSQL.install_function_for_table(@table,
          store_changed_from: true,
          except_columns: []
        )
      )

      Repo.query!(TriggerSQL.create_trigger(@table, :per_table))

      assert trigger_function() ==
               {StorageSchema.get(), "threadline_capture_changes_" <> @table}

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO #{@table} (name, value) VALUES ('a', 1) RETURNING id")

      Repo.delete_all(AuditChange, repo_opts())
      Repo.delete_all(AuditTransaction, repo_opts())

      Repo.query!("UPDATE #{@table} SET value = 2 WHERE id = $1", [id])

      [change] = Repo.all(AuditChange, repo_opts())
      assert change.op == "update"
      assert is_map(change.changed_from)
      assert Map.get(change.changed_from, "value") == 1
    end

    test "switching back to default mode removes the unused per-table function" do
      install_per_table_trigger!()

      Repo.query!(TriggerSQL.create_trigger(@table))
      result = Repo.query!(drop_if_unused())

      assert warnings(result) == []
      assert per_table_function_count() == 0
      assert trigger_function() == {StorageSchema.get(), "threadline_capture_changes"}
    end

    test "keeps the function and warns while a trigger still uses it" do
      install_per_table_trigger!()

      result = Repo.query!(drop_if_unused())

      assert [warning] = warnings(result)
      assert warning =~ "threadline: kept"
      assert warning =~ "public.#{@table}"
      assert warning =~ "regenerate triggers for those tables"
      assert per_table_function_count() == 1

      assert trigger_function() ==
               {StorageSchema.get(), "threadline_capture_changes_" <> @table}
    end

    test "names every table still using the function, sorted by schema then table" do
      install_per_table_trigger!()
      Repo.query!("CREATE SCHEMA IF NOT EXISTS rerun_sibling")
      Repo.query!("CREATE TABLE IF NOT EXISTS rerun_sibling.a_table (id bigserial PRIMARY KEY)")

      on_exit(fn -> Repo.query!("DROP SCHEMA IF EXISTS rerun_sibling CASCADE") end)

      Repo.query!("""
      CREATE TRIGGER threadline_audit_rerun_sibling_a_table
      AFTER INSERT OR UPDATE OR DELETE ON rerun_sibling.a_table
      FOR EACH ROW EXECUTE FUNCTION #{StorageSchema.function(Naming.function_name(@table))}()
      """)

      result = Repo.query!(drop_if_unused())

      assert [warning] = warnings(result)
      assert warning =~ "triggers on public.#{@table}, rerun_sibling.a_table still use it"
      assert per_table_function_count() == 1

      assert %{rows: [["O"], ["O"]]} =
               Repo.query!("""
               SELECT tgenabled::text FROM pg_trigger
               WHERE tgname LIKE 'threadline_audit_%'
                 AND tgrelid IN ('#{@table}'::regclass, 'rerun_sibling.a_table'::regclass)
               """)
    end

    test "the drop is harmless when no per-table function exists" do
      Repo.query!(TriggerSQL.create_trigger(@table))

      result = Repo.query!(drop_if_unused())

      assert warnings(result) == []
      assert trigger_function() == {StorageSchema.get(), "threadline_capture_changes"}
    end
  end

  # "threadline_capture_changes_" is 27 bytes, so a per-table function name for
  # any table suffix longer than 36 bytes exceeds PostgreSQL's 63-byte limit.
  # These two tables share their first 36 bytes, so their per-table function
  # names truncate to the same identifier, while their trigger names stay
  # distinct and within the limit.
  @long_default "customer_subscription_billing_events_2024"
  @long_per_table "customer_subscription_billing_events_2025"
  @shared_function binary_part("threadline_capture_changes_" <> @long_per_table, 0, 63)

  describe "long table names whose per-table function names truncate to the same identifier" do
    setup do
      previous_shell = Mix.shell()
      previous_capture = Application.fetch_env(:threadline, :trigger_capture)
      Mix.shell(Mix.Shell.Process)

      tmp =
        Path.join(
          System.tmp_dir!(),
          "threadline-trigger-long-names-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(tmp)

      for table <- [@long_default, @long_per_table] do
        Repo.query!("""
        CREATE TABLE IF NOT EXISTS #{table} (
          id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
          name  text NOT NULL,
          value integer
        )
        """)
      end

      on_exit(fn ->
        Mix.shell(previous_shell)

        case previous_capture do
          {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
          :error -> Application.delete_env(:threadline, :trigger_capture)
        end

        for table <- [@long_default, @long_per_table] do
          Repo.query!("DROP TABLE IF EXISTS #{table} CASCADE")
        end

        Repo.query!("DROP FUNCTION IF EXISTS #{shared_function_ref()}()")

        Repo.query!(
          "DROP FUNCTION IF EXISTS " <>
            StorageSchema.function(Naming.function_name(@long_per_table)) <> "()"
        )

        File.rm_rf!(tmp)
      end)

      %{tmp: tmp}
    end

    test "the two names really collide once PostgreSQL truncates them" do
      [default_fn, per_table_fn] =
        Enum.map([@long_default, @long_per_table], &("threadline_capture_changes_" <> &1))

      assert byte_size(@long_default) >= 40
      assert binary_part(@long_default, 0, 36) == binary_part(@long_per_table, 0, 36)
      assert byte_size(default_fn) > 63
      assert binary_part(default_fn, 0, 63) == binary_part(per_table_fn, 0, 63)
      assert byte_size("threadline_audit_" <> @long_default) <= 63
    end

    test "a default-mode table applies while the colliding per-table trigger is installed",
         %{tmp: tmp} do
      install_legacy_per_table_trigger!()

      tmp
      |> generate!(["--tables", @long_default])
      |> apply_up!()

      assert trigger_function(@long_default) ==
               {StorageSchema.get(), "threadline_capture_changes"}

      assert trigger_function(@long_per_table) == {StorageSchema.get(), @shared_function}

      Repo.query!("INSERT INTO #{@long_per_table} (name, value) VALUES ('b', 1)")
      assert_captured!(@long_default)
    end

    test "two default-mode tables on one cut function both leave it, and it is dropped",
         %{tmp: tmp} do
      install_legacy_per_table_trigger!()

      Repo.query!("""
      CREATE TRIGGER #{StorageSchema.quote_ident("threadline_audit_" <> @long_default)}
      AFTER INSERT OR UPDATE OR DELETE ON #{@long_default}
      FOR EACH ROW EXECUTE FUNCTION #{shared_function_ref()}()
      """)

      tmp
      |> generate!(["--tables", "#{@long_default},#{@long_per_table}"])
      |> apply_up!()

      for table <- [@long_default, @long_per_table] do
        assert trigger_function(table) == {StorageSchema.get(), "threadline_capture_changes"}
      end

      assert shared_function_count() == 0
    end

    test "a per-table table after a default-mode table in one run gets its own function",
         %{tmp: tmp} do
      Application.put_env(:threadline, :trigger_capture,
        tables: %{@long_per_table => [store_changed_from: true]}
      )

      tmp
      |> generate!(["--tables", "#{@long_default},#{@long_per_table}"])
      |> apply_up!()

      assert trigger_function(@long_default) ==
               {StorageSchema.get(), "threadline_capture_changes"}

      assert trigger_function(@long_per_table) ==
               {StorageSchema.get(), Naming.function_name(@long_per_table)}

      assert Naming.function_name(@long_per_table) =~ ~r/_[0-9a-f]{12}\z/
    end
  end

  # A per-table function installed before Threadline validated identifier
  # length (0.9.x and earlier): PostgreSQL truncated its name to 63 bytes. The
  # fixture creates it under the name PostgreSQL stored, so it truncates nothing.
  defp install_legacy_per_table_trigger! do
    Repo.query!("""
    CREATE FUNCTION #{shared_function_ref()}()
    RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$
    """)

    Repo.query!("""
    CREATE TRIGGER #{StorageSchema.quote_ident("threadline_audit_" <> @long_per_table)}
    AFTER INSERT OR UPDATE OR DELETE ON #{@long_per_table}
    FOR EACH ROW EXECUTE FUNCTION #{shared_function_ref()}()
    """)

    assert shared_function_count() == 1
  end

  defp shared_function_ref do
    StorageSchema.function(@shared_function)
  end

  defp shared_function_count do
    %{rows: [[count]]} =
      Repo.query!(
        """
        SELECT count(*)
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = $1 AND p.proname = $2
        """,
        [StorageSchema.get(), @shared_function]
      )

    count
  end

  defp assert_captured!(table) do
    Repo.query!("INSERT INTO #{table} (name, value) VALUES ('a', 1)")

    assert [%AuditChange{table_name: ^table, op: "insert"}] =
             Repo.all(AuditChange, repo_opts())
  end

  # Runs `mix threadline.gen.triggers` in `tmp` and returns the migration file
  # it wrote.
  defp generate!(tmp, args) do
    before = migration_files(tmp)
    File.cd!(tmp, fn -> Triggers.run(args) end)
    [file] = migration_files(tmp) -- before
    file
  end

  defp migration_files(tmp) do
    [tmp, "priv/repo/migrations", "*_threadline_triggers_*.exs"]
    |> Path.join()
    |> Path.wildcard()
  end

  # Applies the SQL of every `execute` in the migration's `up`, in source order.
  # Parsed as data, never compiled.
  defp apply_up!(file) do
    ast = file |> File.read!() |> Code.string_to_quoted!()

    {_, [body]} =
      Macro.prewalk(ast, [], fn
        {:def, _, [{:up, _, _}, [do: body]]} = node, acc -> {node, [body | acc]}
        node, acc -> {node, acc}
      end)

    {_, sqls} =
      Macro.prewalk(body, [], fn
        {:execute, _, [sql]} = node, acc when is_binary(sql) -> {node, [sql | acc]}
        node, acc -> {node, acc}
      end)

    sqls |> Enum.reverse() |> Enum.each(&Repo.query!/1)
  end

  defp drop_if_unused, do: TriggerSQL.drop_function_if_unused(Naming.function_name(@table))

  defp warnings(%Postgrex.Result{messages: messages}) do
    for %{severity: "WARNING", message: message} <- messages, do: message
  end

  defp install_per_table_trigger! do
    Repo.query!(
      TriggerSQL.install_function_for_table(@table,
        store_changed_from: true,
        except_columns: []
      )
    )

    Repo.query!(TriggerSQL.create_trigger(@table, :per_table))
  end

  defp per_table_function_count do
    %{rows: [[count]]} =
      Repo.query!(
        """
        SELECT count(*)
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = $1 AND p.proname = $2
        """,
        [StorageSchema.get(), "threadline_capture_changes_" <> @table]
      )

    count
  end

  # Identifies the trigger's function by catalog name and namespace rather than
  # its text rendering, which varies with search_path. The table name is sent as
  # text and cast, because Postgrex encodes a bare regclass parameter as an oid.
  defp trigger_function(table \\ @table) do
    %{rows: [[nsp, proname]]} =
      Repo.query!(
        """
        SELECT n.nspname, p.proname
        FROM pg_trigger t
        JOIN pg_proc p ON p.oid = t.tgfoid
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE t.tgrelid = $1::text::regclass AND t.tgname = $2 AND NOT t.tgisinternal
        """,
        [table, "threadline_audit_" <> table]
      )

    {nsp, proname}
  end
end
