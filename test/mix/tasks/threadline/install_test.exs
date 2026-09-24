defmodule Mix.Tasks.Threadline.InstallTest do
  # async: false — the task writes relative to the working directory and reads
  # the global :storage_schema application env, and both are VM-wide.
  use ExUnit.Case, async: false

  alias Mix.Tasks.Threadline.Gen.Triggers
  alias Mix.Tasks.Threadline.Install

  @suffixes [
    "_threadline_audit_schema.exs",
    "_threadline_semantics_schema.exs",
    "_threadline_governance_schema.exs"
  ]

  setup do
    previous_shell = Mix.shell()
    previous_schema = Application.fetch_env(:threadline, :storage_schema)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(System.tmp_dir!(), "threadline-install-#{System.unique_integer([:positive])}")

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

  defp run_install(tmp) do
    File.cd!(tmp, fn -> Install.run([]) end)
    drain_shell([])
  end

  defp drain_shell(acc) do
    receive do
      {:mix_shell, :info, [msg]} -> drain_shell([msg | acc])
    after
      0 -> acc |> Enum.reverse() |> Enum.join("\n")
    end
  end

  @migrations "priv/repo/migrations"

  # The version prefix of each family's migration, in the order given.
  defp prefixes(tmp, suffixes) do
    for suffix <- suffixes do
      [file] = Path.wildcard(Path.join([tmp, @migrations, "*" <> suffix]))
      file |> Path.basename() |> String.split("_", parts: 2) |> hd()
    end
  end

  defp seed(tmp, name) do
    file = Path.join([tmp, @migrations, name])
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, "# seeded by the test\n")
  end

  # Ecto reads the integer before the first "_" as the migration version and
  # refuses to run a set that contains the same version twice.
  defp assert_valid_increasing!(versions) do
    for v <- versions do
      assert v =~ ~r/^\d{14}$/, "version #{v} is not 14 digits"

      <<y::binary-4, mo::binary-2, d::binary-2, h::binary-2, mi::binary-2, s::binary-2>> = v

      assert {:ok, _} =
               NaiveDateTime.new(
                 String.to_integer(y),
                 String.to_integer(mo),
                 String.to_integer(d),
                 String.to_integer(h),
                 String.to_integer(mi),
                 String.to_integer(s)
               ),
             "version #{v} is not a valid timestamp"
    end

    dupes = versions -- Enum.uniq(versions)

    assert dupes == [],
           "`mix ecto.migrate` would raise (Ecto.MigrationError) migrations can't be executed, " <>
             "migration version #{List.first(dupes)} is duplicated — got #{inspect(versions)}"

    assert versions == Enum.sort(versions),
           "versions are not increasing in write order: #{inspect(versions)}"
  end

  defp generated(tmp) do
    tmp
    |> Path.join("**/*.exs")
    |> Path.wildcard()
    |> Enum.filter(fn file -> Enum.any?(@suffixes, &String.ends_with?(file, &1)) end)
  end

  test "an unconfigured new install is told to delete the migrations it just wrote before re-running",
       %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)

    output = run_install(tmp)
    files = generated(tmp)

    assert length(files) == 3

    for file <- files do
      relative = Path.relative_to(file, tmp)

      assert String.contains?(output, relative),
             "the storage-schema advice must name #{relative}, which this run generated into " <>
               "`public` — re-running without deleting it keeps the `public` migration while " <>
               "the config points at the dedicated schema"
    end

    assert output =~ "Delete the migration files this run just generated"
    assert output =~ ~s(config :threadline, storage_schema: "threadline")

    # The advice follows generation, so it can name what was actually written.
    {advice_at, _} = :binary.match(output, "No `:storage_schema` is configured")
    {created_at, _} = :binary.match(output, "creating")
    assert created_at < advice_at
  end

  test "following the advice produces migrations that target the dedicated schema", %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)
    run_install(tmp)

    Enum.each(generated(tmp), &File.rm!/1)

    Application.put_env(:threadline, :storage_schema, "threadline")
    output = run_install(tmp)
    files = generated(tmp)

    assert length(files) == 3
    refute output =~ "No `:storage_schema` is configured"

    audit = Enum.find(files, &String.ends_with?(&1, "_threadline_audit_schema.exs"))
    assert File.read!(audit) =~ ~s("threadline")
  end

  test "a re-run over an existing install skips every migration and gives no schema advice",
       %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)
    run_install(tmp)
    before = generated(tmp)

    output = run_install(tmp)

    assert generated(tmp) == before
    assert output =~ "already exists — skipping"
    refute output =~ "No `:storage_schema` is configured"
    refute output =~ "Run `mix ecto.migrate`"
  end

  test "a configured install gets no schema advice", %{tmp: tmp} do
    Application.put_env(:threadline, :storage_schema, "threadline")

    output = run_install(tmp)

    assert length(generated(tmp)) == 3
    refute output =~ "No `:storage_schema` is configured"
  end

  describe "migration versions" do
    test "a fresh install writes three distinct versions in family order", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      run_install(tmp)

      assert_valid_increasing!(prefixes(tmp, @suffixes))
    end

    test "every version is above a future-dated host migration, with the date carried",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      seed(tmp, "20991231235959_host_thing.exs")

      run_install(tmp)
      versions = prefixes(tmp, @suffixes)

      for v <- versions do
        assert String.to_integer(v) > 20_991_231_235_959,
               "version #{v} does not sort after the existing host migration 20991231235959"
      end

      assert hd(versions) == "21000101000000"
      assert_valid_increasing!(versions)
    end
  end

  test "a Threadline migration moved into a subdirectory is not written again", %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)
    seed(tmp, "archive/20991231235958_threadline_audit_schema.exs")

    output = run_install(tmp)

    assert Path.wildcard(Path.join([tmp, @migrations, "*_threadline_audit_schema.exs"])) == []
    assert output =~ "already exists — skipping"
    versions = prefixes(tmp, tl(@suffixes))
    assert hd(versions) == "20991231235959"
    assert_valid_increasing!(versions)
  end

  describe "storage-schema advice" do
    test "a partial re-run versions the missing migration last and is told to keep `public`",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      seed(tmp, "20991231235958_threadline_audit_schema.exs")
      seed(tmp, "20991231235959_threadline_semantics_schema.exs")

      output = run_install(tmp)
      [governance] = prefixes(tmp, ["_threadline_governance_schema.exs"])

      assert governance == "21000101000000"
      assert_valid_increasing!([governance])
      assert output =~ "already exists — skipping"
      refute output =~ "No `:storage_schema` is configured"
      assert output =~ "Keep `:storage_schema` unset"
    end

    test "fresh-install advice has no paragraph about existing installs", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      output = run_install(tmp)

      assert output =~ "Delete the migration files this run just generated"
      refute output =~ "Existing installs need no action"
    end
  end

  describe "install then gen.triggers" do
    defp triggers_prefix(tmp) do
      [file] = Path.wildcard(Path.join([tmp, @migrations, "*_threadline_triggers_*.exs"]))
      file |> Path.basename() |> String.split("_", parts: 2) |> hd()
    end

    test "the trigger migration is versioned after the three install migrations", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      run_install(tmp)
      File.cd!(tmp, fn -> Triggers.run(["--tables", "posts"]) end)
      drain_shell([])

      assert_valid_increasing!(prefixes(tmp, @suffixes) ++ [triggers_prefix(tmp)])
    end
  end
end
