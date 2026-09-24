defmodule Mix.Tasks.Threadline.GenTriggersTest do
  # async: false — the task writes relative to the working directory and reads
  # the global :storage_schema application env, and both are VM-wide.
  use ExUnit.Case, async: false

  alias Mix.Tasks.Threadline.Gen.Triggers

  @migrations "priv/repo/migrations"

  @legacy_fixture "priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs"

  setup do
    previous_shell = Mix.shell()
    previous_schema = Application.fetch_env(:threadline, :storage_schema)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-gen-triggers-#{System.unique_integer([:positive])}"
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

  defp run_triggers(tmp, args) do
    File.cd!(tmp, fn -> Triggers.run(args) end)
    drain_shell([])
  end

  defp drain_shell(acc) do
    receive do
      {:mix_shell, :info, [msg]} -> drain_shell([msg | acc])
    after
      0 -> acc |> Enum.reverse() |> Enum.join("\n")
    end
  end

  # Every trigger migration in the directory, in version order.
  defp trigger_files(tmp) do
    [tmp, @migrations, "**", "*_threadline_triggers_*.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.sort_by(&Path.basename/1)
  end

  # Ecto's own extraction: the integer before the first "_" is the version and
  # the rest of the file name is the migration name.
  defp ecto_name(file) do
    {_, "_" <> name} = file |> Path.basename() |> Path.rootname() |> Integer.parse()
    name
  end

  defp version(file) do
    {version, "_" <> _} = file |> Path.basename() |> Path.rootname() |> Integer.parse()
    Integer.to_string(version)
  end

  defp module_of(file) do
    {:defmodule, _, [{:__aliases__, _, parts}, _]} =
      file |> File.read!() |> Code.string_to_quoted!()

    Module.concat(parts)
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

  # Ecto also refuses a pending set in which two files share a name, and two
  # files defining the same module clash when both are loaded.
  defp assert_distinct_names_and_modules!(files) do
    names = Enum.map(files, &ecto_name/1)
    name_dupes = names -- Enum.uniq(names)

    assert name_dupes == [],
           "`mix ecto.migrate` would raise (Ecto.MigrationError) migrations can't be executed, " <>
             "migration name #{List.first(name_dupes)} is duplicated — got #{inspect(names)}"

    modules = Enum.map(files, &module_of/1)
    module_dupes = modules -- Enum.uniq(modules)

    assert module_dupes == [],
           "module #{inspect(List.first(module_dupes))} is defined twice — got #{inspect(modules)}"
  end

  describe "rerun naming" do
    test "first run keeps today's name and module", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])

      assert [file] = trigger_files(tmp)
      assert String.ends_with?(file, "_threadline_triggers_posts.exs")
      assert ecto_name(file) == "threadline_triggers_posts"
      assert module_of(file) == ThreadlineTriggersPosts
    end

    test "first run for several tables keeps today's module", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts,org_memberships"])

      assert [file] = trigger_files(tmp)
      assert ecto_name(file) == "threadline_triggers_posts_org_memberships"
      assert module_of(file) == ThreadlineTriggersPostsOrgMemberships
    end

    test "first run for a capitalised table keeps today's module", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "AuditLog"])

      assert [file] = trigger_files(tmp)
      assert ecto_name(file) == "threadline_triggers_AuditLog"
      assert module_of(file) == ThreadlineTriggersAuditLog
    end

    test "a rerun gets a distinct Ecto name", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])
      run_triggers(tmp, ["--tables", "posts"])

      files = trigger_files(tmp)
      assert_valid_increasing!(Enum.map(files, &version/1))
      assert_distinct_names_and_modules!(files)

      assert Enum.map(files, &ecto_name/1) == [
               "threadline_triggers_posts",
               "threadline_triggers_posts_2"
             ]

      run_triggers(tmp, ["--tables", "posts"])

      files = trigger_files(tmp)
      assert_valid_increasing!(Enum.map(files, &version/1))
      assert_distinct_names_and_modules!(files)

      assert Enum.map(files, &ecto_name/1) == [
               "threadline_triggers_posts",
               "threadline_triggers_posts_2",
               "threadline_triggers_posts_3"
             ]
    end

    test "a rerun gets a distinct module", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])
      run_triggers(tmp, ["--tables", "posts"])

      assert Enum.map(trigger_files(tmp), &module_of/1) == [
               ThreadlineTriggersPosts,
               ThreadlineTriggersPosts2
             ]
    end

    test "a legacy trigger migration already present", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      legacy = Path.join([tmp, @migrations, "20260424080642_threadline_triggers_posts.exs"])
      File.mkdir_p!(Path.dirname(legacy))
      File.cp!(@legacy_fixture, legacy)

      run_triggers(tmp, ["--tables", "posts"])

      files = trigger_files(tmp)
      assert [^legacy, new_file] = files
      assert ecto_name(new_file) == "threadline_triggers_posts_2"
      assert module_of(new_file) == ThreadlineTriggersPosts2
      assert_valid_increasing!(Enum.map(files, &version/1))
      assert_distinct_names_and_modules!(files)
    end

    test "lookalike table names never collide", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])
      run_triggers(tmp, ["--tables", "posts_2"])
      run_triggers(tmp, ["--tables", "posts"])

      files = trigger_files(tmp)
      assert_distinct_names_and_modules!(files)

      assert Enum.map(files, &ecto_name/1) == [
               "threadline_triggers_posts",
               "threadline_triggers_posts_2",
               "threadline_triggers_posts_3"
             ]

      assert Enum.map(files, &module_of/1) == [
               ThreadlineTriggersPosts,
               ThreadlineTriggersPosts2,
               ThreadlineTriggersPosts3
             ]

      second = Path.join(tmp, "second")
      File.mkdir_p!(second)
      run_triggers(second, ["--tables", "a_b"])
      run_triggers(second, ["--tables", "a,b"])

      files = trigger_files(second)
      assert_distinct_names_and_modules!(files)

      assert Enum.map(files, &ecto_name/1) == [
               "threadline_triggers_a_b",
               "threadline_triggers_a_b_2"
             ]

      assert Enum.map(files, &module_of/1) == [ThreadlineTriggersAB, ThreadlineTriggersAB2]
    end
  end
end
