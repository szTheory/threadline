defmodule Mix.Tasks.Threadline.GenRowHistoryIndexTest do
  # async: false — the task writes relative to the working directory and reads
  # the global :storage_schema application env, and both are VM-wide.
  use ExUnit.Case, async: false

  alias Ecto.Adapters.SQL
  alias Mix.Tasks.Threadline.Gen.RowHistoryIndex
  alias Threadline.Capture.RowHistoryIndexSQL
  alias Threadline.Test.Repo

  import Threadline.StorageSchemaCase

  @migrations "priv/repo/migrations"

  setup do
    previous_shell = Mix.shell()
    previous_schema = Application.fetch_env(:threadline, :storage_schema)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-gen-row-history-index-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_schema do
        {:ok, value} -> Application.put_env(:threadline, :storage_schema, value)
        :error -> Application.delete_env(:threadline, :storage_schema)
      end

      File.rm_rf!(tmp)
    end)

    %{tmp: tmp}
  end

  defp run(tmp, args) do
    File.cd!(tmp, fn -> RowHistoryIndex.run(args) end)
    drain_shell([])
  end

  defp drain_shell(acc) do
    receive do
      {:mix_shell, :info, [msg]} -> drain_shell([msg | acc])
    after
      0 -> acc |> Enum.reverse() |> Enum.join("\n")
    end
  end

  defp generated_files(tmp) do
    [tmp, @migrations, "**", "*_threadline_row_history_index.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.sort()
  end

  test "writes exactly one migration with the concurrent, non-blocking shape", %{tmp: tmp} do
    run(tmp, ["--migrations-path", @migrations])

    assert [file] = generated_files(tmp)
    content = File.read!(file)

    assert content =~ "@disable_ddl_transaction true"
    assert content =~ "@disable_migration_lock true"
    assert content =~ "CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_changes_row_history_idx"
    assert content =~ "DROP INDEX CONCURRENTLY IF EXISTS"
    assert content =~ "INVALID"
    assert {:ok, _quoted} = Code.string_to_quoted(content)
  end

  test "a second run writes nothing and names the existing file", %{tmp: tmp} do
    run(tmp, ["--migrations-path", @migrations])
    assert [file] = generated_files(tmp)

    output = run(tmp, ["--migrations-path", @migrations])

    assert generated_files(tmp) == [file]
    assert output =~ Path.basename(file)
  end

  test "an unknown flag raises Mix.Error", %{tmp: tmp} do
    assert_raise Mix.Error, fn ->
      File.cd!(tmp, fn -> RowHistoryIndex.run(["--bogus"]) end)
    end
  end

  test "the generated SQL matches RowHistoryIndexSQL for the configured storage schema", %{
    tmp: tmp
  } do
    run(tmp, ["--migrations-path", @migrations])
    assert [file] = generated_files(tmp)
    content = File.read!(file)

    expected_create = RowHistoryIndexSQL.create_concurrently_sql(storage_schema: "threadline")
    expected_drop = RowHistoryIndexSQL.drop_concurrently_sql(storage_schema: "threadline")

    assert content =~ inspect(expected_create)
    assert content =~ inspect(expected_drop)
  end

  test "up, down, up leaves exactly one valid index in a non-default storage schema", %{
    tmp: tmp
  } do
    prepare_storage_schema!("audit")

    file =
      with_storage_schema("audit", fn ->
        run(tmp, ["--migrations-path", @migrations])
        [file] = generated_files(tmp)
        file
      end)

    module = load_migration!(file)
    version = migration_version(file)

    # The "audit" schema was just built by copying "threadline"'s tables with
    # `LIKE ... INCLUDING ALL`, which already carries the row-history index —
    # so this first `up` proves migrating up when the index already exists
    # succeeds (IF NOT EXISTS treats it as a no-op).
    assert Ecto.Migrator.up(Repo, version, module) in [:ok, :already_up]
    assert index_valid?("audit") == true

    assert Ecto.Migrator.down(Repo, version, module) in [:ok, :already_down]
    assert index_valid?("audit") == nil

    assert Ecto.Migrator.up(Repo, version, module) in [:ok, :already_up]
    assert index_valid?("audit") == true

    Repo.query!("DELETE FROM schema_migrations WHERE version = $1", [version])
  end

  defp load_migration!(file) do
    case Regex.run(~r/defmodule\s+([A-Za-z0-9_.]+)\s+do/, File.read!(file)) do
      [_, name] ->
        module = Module.concat([name])
        Code.compiler_options(ignore_module_conflict: true)
        [{^module, _binary}] = Code.compile_file(file)
        module
    end
  end

  defp migration_version(file) do
    {version, "_" <> _} = file |> Path.basename() |> Path.rootname() |> Integer.parse()
    version
  end

  defp index_valid?(storage_schema) do
    %{rows: rows} =
      SQL.query!(
        Repo,
        """
        SELECT i.indisvalid
        FROM pg_index i
        JOIN pg_class c ON c.oid = i.indexrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = $1 AND c.relname = $2
        """,
        [storage_schema, RowHistoryIndexSQL.index_name()]
      )

    case rows do
      [] -> nil
      [[valid?]] -> valid?
    end
  end
end
