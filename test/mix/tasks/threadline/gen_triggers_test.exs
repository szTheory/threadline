defmodule Mix.Tasks.Threadline.GenTriggersTest do
  # async: false — the task writes relative to the working directory and reads
  # the global :storage_schema application env, and both are VM-wide.
  use ExUnit.Case, async: false

  alias Mix.Tasks.Threadline.Gen.Triggers
  alias Threadline.Capture.{Naming, TriggerSQL}
  alias Threadline.Test.LegacyTriggerSQL

  @migrations "priv/repo/migrations"

  @legacy_fixture "priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs"

  # Evaluated at compile time: the tests below File.cd! into tmp dirs, so the
  # guides are read from an absolute path.
  @repo_root File.cwd!()

  # The rerun wording shared by the drift guides, the task docs and the
  # generated rollback comment. The generated comment uses a subset, so the
  # guides cannot describe a rollback the generator does not.
  @rerun_doc_phrases [
    "replaces the trigger in place",
    "does not restore the earlier capture policy",
    "unredacted",
    "mix threadline.policy.show"
  ]
  @generated_down_phrases [
    "does not restore the earlier capture policy",
    "unredacted",
    "mix threadline.policy.show"
  ]

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

  # The SQL string of every `execute` call in the named function of a
  # generated migration, in source order. Parsed as data, never compiled.
  defp executes(file, fun_name) do
    ast = file |> File.read!() |> Code.string_to_quoted!()

    {_, [body]} =
      Macro.prewalk(ast, [], fn
        {:def, _, [{^fun_name, _, _}, [do: body]]} = node, acc -> {node, [body | acc]}
        node, acc -> {node, acc}
      end)

    {_, sqls} =
      Macro.prewalk(body, [], fn
        {:execute, _, [sql]} = node, acc when is_binary(sql) -> {node, [sql | acc]}
        node, acc -> {node, acc}
      end)

    Enum.reverse(sqls)
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

  describe "migrations directory" do
    @custom_repo Threadline.TestSupport.CustomPrivRepo

    setup do
      previous = Application.fetch_env(:threadline, :ecto_repos)
      Application.delete_env(:threadline, :storage_schema)

      on_exit(fn ->
        case previous do
          {:ok, value} -> Application.put_env(:threadline, :ecto_repos, value)
          :error -> Application.delete_env(:threadline, :ecto_repos)
        end
      end)

      :ok
    end

    defp files_in(tmp, dir) do
      [tmp, dir, "*_threadline_triggers_*.exs"] |> Path.join() |> Path.wildcard() |> Enum.sort()
    end

    test "a repo with a custom :priv gets the migration in its own directory", %{tmp: tmp} do
      Application.put_env(:threadline, :ecto_repos, [@custom_repo])

      run_triggers(tmp, ["--tables", "posts"])

      assert [file] = files_in(tmp, "priv/custom_repo/migrations")
      assert String.ends_with?(file, "_threadline_triggers_posts.exs")
      assert files_in(tmp, @migrations) == []
    end

    test "a rerun is detected in the custom :priv directory", %{tmp: tmp} do
      Application.put_env(:threadline, :ecto_repos, [@custom_repo])

      run_triggers(tmp, ["--tables", "posts"])
      output = run_triggers(tmp, ["--tables", "posts"])

      assert output =~ "already have a Threadline trigger migration"

      assert [_, second] = files_in(tmp, "priv/custom_repo/migrations")
      assert String.ends_with?(second, "_threadline_triggers_posts_2.exs")
      assert files_in(tmp, @migrations) == []
    end

    test "--migrations-path wins over --repo", %{tmp: tmp} do
      run_triggers(tmp, [
        "--tables",
        "posts",
        "--migrations-path",
        "db/triggers",
        "--repo",
        inspect(@custom_repo)
      ])

      assert [_] = files_in(tmp, "db/triggers")
      assert files_in(tmp, "priv/custom_repo/migrations") == []
      assert files_in(tmp, @migrations) == []
    end

    test "-r picks the repo's migrations directory", %{tmp: tmp} do
      run_triggers(tmp, ["--tables", "posts", "-r", inspect(@custom_repo)])

      assert [_] = files_in(tmp, "priv/custom_repo/migrations")
      assert files_in(tmp, @migrations) == []
    end

    test "an unloadable configured repo falls back to priv/repo/migrations with a warning",
         %{tmp: tmp} do
      Application.put_env(:threadline, :ecto_repos, [Does.Not.Exist])

      run_triggers(tmp, ["--tables", "posts"])

      assert [_] = trigger_files(tmp)
      assert_received {:mix_shell, :error, [warning]}
      assert warning =~ ~r/Does\.Not\.Exist/
      assert warning =~ "priv/repo/migrations"
    end

    test "--dry-run still rejects a repeated --repo", %{tmp: tmp} do
      assert_raise Mix.Error, ~r/may be given once/, fn ->
        run_triggers(tmp, ["--tables", "posts", "--dry-run", "--repo", "A", "--repo", "B"])
      end
    end

    test "--dry-run still rejects a --repo that cannot be loaded", %{tmp: tmp} do
      assert_raise Mix.Error, ~r/Does\.Not\.Exist/, fn ->
        run_triggers(tmp, ["--tables", "posts", "--dry-run", "--repo", "Does.Not.Exist"])
      end
    end

    test "--dry-run with a valid --repo writes nothing", %{tmp: tmp} do
      output = run_triggers(tmp, ["--tables", "posts", "--dry-run", "-r", inspect(@custom_repo)])

      assert output =~ "[dry-run] no migration file written"
      assert files_in(tmp, "priv/custom_repo/migrations") == []
    end

    test "--repo may be given once", %{tmp: tmp} do
      assert_raise Mix.Error, ~r/may be given once/, fn ->
        run_triggers(tmp, ["--tables", "posts", "--repo", "A", "--repo", "B"])
      end

      assert trigger_files(tmp) == []
    end
  end

  describe "--tables validation" do
    defp tables_error(tmp, value) do
      error =
        assert_raise Mix.Error, fn ->
          File.cd!(tmp, fn -> Triggers.run(["--tables", value]) end)
        end

      assert [tmp, "**", "*.exs"] |> Path.join() |> Path.wildcard() == []
      Exception.message(error)
    end

    test "an oversized table names the host table and its byte count", %{tmp: tmp} do
      table = String.duplicate("t", 70)
      message = tables_error(tmp, table)

      assert String.starts_with?(message, "--tables: ")
      assert message =~ "host table"
      assert message =~ table
      assert message =~ "70 bytes"
      refute message =~ "storage schema"
    end

    test "an invalid table segment names the original input", %{tmp: tmp} do
      message = tables_error(tmp, "billing.bad-name")

      assert message =~ "--tables: "
      assert message =~ ~s[(from "billing.bad-name")]
    end

    test "a three-part name is rejected", %{tmp: tmp} do
      assert tables_error(tmp, "a.b.c") =~ "table must be NAME or SCHEMA.NAME"
    end
  end

  describe "trigger names" do
    test "fitting trigger names are unchanged" do
      Application.delete_env(:threadline, :storage_schema)

      assert TriggerSQL.create_trigger("posts") =~ ~s|TRIGGER "threadline_audit_posts"|

      assert TriggerSQL.drop_trigger("billing.invoices") ==
               ~s|DROP TRIGGER IF EXISTS "threadline_audit_billing_invoices" ON "billing"."invoices"|
    end

    test "a default-mode table whose trigger name overflows generates with the cut name",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      table = String.duplicate("t", 50)
      cut = binary_part("threadline_audit_" <> table, 0, 63)

      run_triggers(tmp, ["--tables", table])

      assert [file] = trigger_files(tmp)
      assert byte_size(ecto_name(file)) <= 63
      assert [_function, create | _] = executes(file, :up)
      assert create =~ ~s|CREATE OR REPLACE TRIGGER "#{cut}"\n|
      assert executes(file, :down) == [~s|DROP TRIGGER IF EXISTS "#{cut}" ON "public"."#{table}"|]

      output = run_triggers(tmp, ["--tables", table])
      assert output =~ "already have a Threadline trigger migration"
      assert [_, rerun] = trigger_files(tmp)
      assert executes(rerun, :down) == []
    end
  end

  describe "rerun detection by table" do
    test "two public tables sharing a 46-byte prefix are not reruns of each other",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      prefix = String.duplicate("p", 46)
      a = prefix <> "_alpha"
      b = prefix <> "_beta"
      cut = "threadline_audit_" <> prefix
      assert byte_size(cut) == 63

      run_triggers(tmp, ["--tables", a])
      output = run_triggers(tmp, ["--tables", b])

      refute output =~ "already have a Threadline trigger migration"
      assert [_, b_file] = trigger_files(tmp)
      assert executes(b_file, :down) == [TriggerSQL.drop_trigger(b)]
      assert executes(b_file, :down) == [~s|DROP TRIGGER IF EXISTS "#{cut}" ON "public"."#{b}"|]
    end

    test "public.a_b and a.b are not reruns of each other", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      run_triggers(tmp, ["--tables", "a_b"])
      output = run_triggers(tmp, ["--tables", "a.b"])

      refute output =~ "already have a Threadline trigger migration"
      assert [_, ab_file] = trigger_files(tmp)
      assert executes(ab_file, :down) == [TriggerSQL.drop_trigger("a.b")]
    end

    test "a.b then public.a_b is not a rerun either", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      run_triggers(tmp, ["--tables", "a.b"])
      output = run_triggers(tmp, ["--tables", "a_b"])

      refute output =~ "already have a Threadline trigger migration"
      assert [_, a_b_file] = trigger_files(tmp)
      assert executes(a_b_file, :down) == [TriggerSQL.drop_trigger("a_b")]
    end

    test "the unqualified trigger of release 0.9.0 is a rerun of public.posts", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      legacy = Path.join([tmp, @migrations, "20260424080642_threadline_triggers_posts.exs"])
      File.mkdir_p!(Path.dirname(legacy))
      File.cp!(@legacy_fixture, legacy)

      output = run_triggers(tmp, ["--tables", "posts"])

      assert output =~ "These tables already have a Threadline trigger migration: posts."
      assert [^legacy, new_file] = trigger_files(tmp)
      assert executes(new_file, :down) == []
    end
  end

  describe "up body" do
    test "default-mode up retires the per-table function after the trigger, with no owner guard",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])

      [file] = trigger_files(tmp)
      sqls = executes(file, :up)

      assert sqls == [
               TriggerSQL.install_function(),
               TriggerSQL.create_trigger("posts"),
               TriggerSQL.drop_function_if_unused("threadline_capture_changes_posts")
             ]

      # No owner guard: only the trigger's own primary-key DO block raises
      # (table-does-not-exist), never the "another table's redaction rules"
      # owner-guard message.
      refute Enum.any?(sqls, &(&1 =~ "redaction rules"))

      assert List.last(sqls) =~
               ~S|to_regprocedure('"public"."threadline_capture_changes_posts"()')|
    end

    test "per-table up keeps its function and retires only unused names", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "test_redaction_users,posts"])

      [file] = trigger_files(tmp)
      sqls = executes(file, :up)

      # Mirrors the `test_redaction_users` entry in config/test.exs.
      per_table_opts = [
        store_changed_from: true,
        except_columns: [],
        exclude: ["password"],
        mask: ["email"]
      ]

      assert sqls == [
               TriggerSQL.install_function(),
               TriggerSQL.install_function_for_table("test_redaction_users", per_table_opts),
               TriggerSQL.create_trigger("test_redaction_users", :per_table,
                 redacted_columns: ["password", "email"]
               ),
               TriggerSQL.create_trigger("posts"),
               TriggerSQL.function_owner_guard("test_redaction_users"),
               TriggerSQL.drop_function_if_unused("threadline_capture_changes_posts")
             ]

      refute sqls
             |> Enum.filter(&(statement_kind(&1) == :retire))
             |> Enum.any?(
               &String.contains?(&1, "threadline_capture_changes_test_redaction_users\"()')")
             )
    end

    test "every retire block runs after every trigger", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts,comments,test_redaction_users"])

      [file] = trigger_files(tmp)
      sqls = executes(file, :up)
      kinds = Enum.map(sqls, &statement_kind/1)

      assert kinds == [
               :function,
               :function,
               :trigger,
               :trigger,
               :trigger,
               :guard,
               :retire,
               :retire
             ]

      assert Enum.drop(sqls, 6) == [
               TriggerSQL.drop_function_if_unused("threadline_capture_changes_posts"),
               TriggerSQL.drop_function_if_unused("threadline_capture_changes_comments")
             ]
    end

    test "a table that moves to a hashed function retires its legacy name", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      previous_capture = Application.fetch_env!(:threadline, :trigger_capture)
      on_exit(fn -> Application.put_env(:threadline, :trigger_capture, previous_capture) end)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"billing.invoices" => [mask: ["secret"]]}
      )

      run_triggers(tmp, ["--tables", "billing.invoices"])

      [file] = trigger_files(tmp)
      sqls = executes(file, :up)

      assert sqls == [
               TriggerSQL.install_function_for_table("billing.invoices",
                 store_changed_from: false,
                 except_columns: [],
                 exclude: [],
                 mask: ["secret"]
               ),
               TriggerSQL.create_trigger("billing.invoices", :per_table,
                 redacted_columns: ["secret"]
               ),
               TriggerSQL.function_owner_guard("billing.invoices"),
               TriggerSQL.drop_function_if_unused("threadline_capture_changes_billing_invoices")
             ]
    end

    test "no generated statement cascades, in up or down", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts,test_redaction_users"])
      run_triggers(tmp, ["--tables", "posts,test_redaction_users"])

      for file <- trigger_files(tmp), fun <- [:up, :down], sql <- executes(file, fun) do
        refute sql =~ ~r/cascade/i, "#{Path.basename(file)} #{fun} cascades: #{sql}"
      end
    end
  end

  describe "generated SQL invariants" do
    # At least 50 bytes, so trigger names are cut and function names hashed.
    @long_table "generated_sql_invariants_table_with_a_long_name_xyz"

    test "no statement cascades and every quoted identifier fits in 63 bytes", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      assert byte_size(@long_table) >= 50

      tables = ["posts", "billing.invoices", @long_table, "billing." <> @long_table]
      modes = [default: [], per_table: ["--store-changed-from"]]

      files =
        for {mode, flags} <- modes, table <- tables do
          dir = Path.join(tmp, "#{mode}-#{Naming.suffix(table)}")
          File.mkdir_p!(dir)

          # The second run is a rerun: its down keeps the trigger.
          run_triggers(dir, ["--tables", table | flags])
          run_triggers(dir, ["--tables", table | flags])
          trigger_files(dir)
        end
        |> List.flatten()

      assert length(files) == 16

      for file <- files, fun <- [:up, :down], sql <- executes(file, fun) do
        refute sql =~ ~r/CASCADE/i, "#{Path.basename(file)} #{fun} cascades: #{sql}"

        # Double quotes in generated SQL only ever delimit identifiers; string
        # literals, including the ones inside function bodies, use single
        # quotes.
        for [quoted] <- Regex.scan(~r/"(?:[^"]|"")*"/, sql) do
          identifier =
            quoted |> binary_part(1, byte_size(quoted) - 2) |> String.replace(~s(""), ~s("))

          assert byte_size(identifier) <= 63,
                 "#{Path.basename(file)} #{fun} quotes a #{byte_size(identifier)}-byte " <>
                   "identifier: #{identifier}"
        end
      end
    end
  end

  defp statement_kind(sql) do
    cond do
      sql =~ "CREATE OR REPLACE FUNCTION" -> :function
      sql =~ "CREATE OR REPLACE TRIGGER" -> :trigger
      sql =~ "RAISE EXCEPTION" -> :guard
      sql =~ "drop this capture function only if no trigger still uses it" -> :retire
    end
  end

  describe "shared capture function advisory" do
    test "names a table an earlier migration covers that shared the old function name",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      write_earlier_migration!(tmp, [
        LegacyTriggerSQL.v0_10_2_create_trigger("public", "billing_invoices")
      ])

      run_triggers(tmp, ["--tables", "billing.invoices"])

      assert [warning] = shell_errors()
      assert warning =~ "public.billing_invoices"
      assert warning =~ "billing.invoices"
      assert warning =~ "mix threadline.gen.triggers --tables billing.invoices,billing_invoices"

      assert [_earlier, generated] = migration_files(tmp)
      assert generated =~ "threadline_triggers_billing_invoices"
    end

    test "is silent when both tables are regenerated together", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      write_earlier_migration!(tmp, [
        LegacyTriggerSQL.v0_10_2_create_trigger("public", "billing_invoices"),
        LegacyTriggerSQL.v0_10_2_create_trigger("billing", "invoices")
      ])

      run_triggers(tmp, ["--tables", "billing_invoices,billing.invoices"])

      assert shell_errors() == []
    end

    test "reads an unqualified ON clause as a table in public", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      write_earlier_migration!(tmp, [LegacyTriggerSQL.v0_9_create_trigger("billing_invoices")])

      run_triggers(tmp, ["--tables", "billing.invoices"])

      assert [warning] = shell_errors()
      assert warning =~ "public.billing_invoices"
      assert warning =~ "mix threadline.gen.triggers --tables billing.invoices,billing_invoices"
    end

    test "is silent when earlier migrations cover only unrelated tables", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)

      write_earlier_migration!(tmp, [LegacyTriggerSQL.v0_10_2_create_trigger("public", "posts")])

      run_triggers(tmp, ["--tables", "billing.invoices"])

      assert shell_errors() == []
    end
  end

  defp write_earlier_migration!(tmp, creates) do
    dir = Path.join(tmp, @migrations)
    File.mkdir_p!(dir)

    File.write!(
      Path.join(dir, "20240101000000_threadline_triggers_earlier.exs"),
      LegacyTriggerSQL.migration_source(
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersEarlier",
        creates,
        []
      )
    )
  end

  defp migration_files(tmp) do
    [tmp, @migrations, "*.exs"] |> Path.join() |> Path.wildcard() |> Enum.sort()
  end

  # The comment lines of a generated migration's down, joined with single
  # spaces so a phrase wrapped across lines still matches.
  defp down_comment(file) do
    file
    |> File.read!()
    |> String.split("def down do")
    |> List.last()
    |> String.split("\n")
    |> Enum.filter(&(String.trim_leading(&1) |> String.starts_with?("#")))
    |> Enum.map_join(
      " ",
      &(&1 |> String.trim_leading() |> String.trim_leading("#") |> String.trim())
    )
  end

  # run_triggers/2 drains only :info messages, so errors stay in the mailbox.
  defp shell_errors(acc \\ []) do
    receive do
      {:mix_shell, :error, [msg]} -> shell_errors([msg | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  describe "down body" do
    test "a first-run table keeps today's rollback", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])

      [file] = trigger_files(tmp)
      assert executes(file, :down) == [TriggerSQL.drop_trigger("posts")]
      refute File.read!(file) =~ "does not restore the earlier capture policy"

      per_table = Path.join(tmp, "per_table")
      File.mkdir_p!(per_table)
      run_triggers(per_table, ["--tables", "test_redaction_users"])

      [file] = trigger_files(per_table)

      assert executes(file, :down) == [
               TriggerSQL.drop_trigger("test_redaction_users"),
               TriggerSQL.drop_function_if_unused(Naming.function_name("test_redaction_users"))
             ]

      refute File.read!(file) =~ "does not restore the earlier capture policy"
    end

    test "a rerun table's rollback leaves capture on", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])
      run_triggers(tmp, ["--tables", "posts"])

      [first, rerun] = trigger_files(tmp)

      assert executes(first, :down) == [TriggerSQL.drop_trigger("posts")]
      assert executes(rerun, :down) == []

      text = File.read!(rerun)

      for phrase <- [
            "does not restore the earlier capture policy",
            "Capture stays on",
            "continues unredacted",
            "mix threadline.policy.show"
          ] do
        assert text =~ phrase, "the rerun rollback comment does not say #{inspect(phrase)}"
      end
    end

    test "mixed table sets split the rollback per table", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts,users"])
      run_triggers(tmp, ["--tables", "posts,comments"])

      [_first, rerun] = trigger_files(tmp)

      assert executes(rerun, :down) == [TriggerSQL.drop_trigger("comments")]

      down_text = rerun |> File.read!() |> String.split("def down do") |> List.last()
      assert down_text =~ ~r/#[^\n]*\bposts\b/
      refute down_text =~ ~r/#[^\n]*\bcomments\b/
    end

    test "a rerun back to the default function names the function it retired",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts", "--store-changed-from"])
      run_triggers(tmp, ["--tables", "posts"])

      [first, rerun] = trigger_files(tmp)
      refute File.read!(first) =~ "does not recreate"

      comment = down_comment(rerun)
      assert comment =~ "retired threadline_capture_changes_posts for posts"
      assert comment =~ "does not recreate threadline_capture_changes_posts"
      assert comment =~ "the trigger of posts keeps using threadline_capture_changes."

      for phrase <- @generated_down_phrases do
        assert comment =~ phrase, "the rerun rollback comment lost #{inspect(phrase)}"
      end
    end

    test "a per-table rerun names the old name it retired and the function it keeps",
         %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      hashed = "threadline_capture_changes_billing_invoices_9bba11019407"
      assert Naming.function_name("billing.invoices") == hashed

      run_triggers(tmp, ["--tables", "billing.invoices", "--store-changed-from"])
      run_triggers(tmp, ["--tables", "billing.invoices", "--store-changed-from"])

      [first, rerun] = trigger_files(tmp)
      refute File.read!(first) =~ "does not recreate"

      comment = down_comment(rerun)

      assert comment =~
               "retired threadline_capture_changes_billing_invoices for billing.invoices"

      assert comment =~ "does not recreate threadline_capture_changes_billing_invoices"
      assert comment =~ "the trigger of billing.invoices keeps using #{hashed}."
    end

    test "a per-table rerun that retires nothing adds no retired line", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "test_redaction_users"])
      run_triggers(tmp, ["--tables", "test_redaction_users"])

      [_first, rerun] = trigger_files(tmp)
      comment = down_comment(rerun)
      assert comment =~ "does not restore the earlier capture policy"
      refute comment =~ "does not recreate"
    end

    test "the task names rerun tables", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      first_output = run_triggers(tmp, ["--tables", "posts"])
      refute first_output =~ "already have a Threadline trigger migration"

      output = run_triggers(tmp, ["--tables", "posts"])
      assert output =~ "already have a Threadline trigger migration"
      assert output =~ "posts"
    end
  end

  describe "rerun documentation" do
    test "guides and the task docs describe a rerun the way the generated migration does" do
      {:docs_v1, _, :elixir, _, %{"en" => moduledoc}, _, _} =
        Code.fetch_docs(Mix.Tasks.Threadline.Gen.Triggers)

      sources = [
        {"guides/production-checklist.md",
         File.read!(Path.join(@repo_root, "guides/production-checklist.md"))},
        {"guides/domain-reference.md",
         File.read!(Path.join(@repo_root, "guides/domain-reference.md"))},
        {"the mix threadline.gen.triggers moduledoc", moduledoc}
      ]

      missing =
        for {source, text} <- sources,
            phrase <- @rerun_doc_phrases,
            not String.contains?(String.replace(text, ~r/\s+/, " "), phrase),
            do: "#{source} lacks #{inspect(phrase)}"

      assert missing == [],
             "these docs no longer describe a rerun the way the generated migration " <>
               "does: " <> Enum.join(missing, "; ")
    end

    test "a generated rerun down comment uses the shared phrases", %{tmp: tmp} do
      assert @generated_down_phrases -- @rerun_doc_phrases == [],
             "the generated rollback comment uses wording the guides are not held to"

      Application.delete_env(:threadline, :storage_schema)
      run_triggers(tmp, ["--tables", "posts"])
      run_triggers(tmp, ["--tables", "posts"])

      [_first, rerun] = trigger_files(tmp)

      down_text =
        rerun
        |> File.read!()
        |> String.split("def down do")
        |> List.last()
        |> String.replace(~r/\s+/, " ")

      for phrase <- @generated_down_phrases do
        assert down_text =~ phrase,
               "the generated rerun rollback comment does not say #{inspect(phrase)}"
      end
    end
  end

  describe "long SQL" do
    test "a function longer than 4096 bytes is written whole", %{tmp: tmp} do
      Application.delete_env(:threadline, :storage_schema)
      previous_capture = Application.fetch_env!(:threadline, :trigger_capture)
      on_exit(fn -> Application.put_env(:threadline, :trigger_capture, previous_capture) end)

      mask = for i <- 1..40, do: "masked_column_#{i}"
      Application.put_env(:threadline, :trigger_capture, tables: %{"wide" => [mask: mask]})

      expected =
        TriggerSQL.install_function_for_table("wide",
          store_changed_from: false,
          except_columns: [],
          exclude: [],
          mask: mask
        )

      assert byte_size(expected) > 4096

      run_triggers(tmp, ["--tables", "wide"])

      [file] = trigger_files(tmp)
      source = File.read!(file)

      refute source =~ "<> ..."
      assert {:ok, _ast} = Code.string_to_quoted(source)
      assert [^expected | _] = executes(file, :up)
    end
  end

  describe "table spelling" do
    setup do
      Application.delete_env(:threadline, :storage_schema)
      previous_capture = Application.fetch_env!(:threadline, :trigger_capture)
      on_exit(fn -> Application.put_env(:threadline, :trigger_capture, previous_capture) end)
      :ok
    end

    defp masked_posts_function(table) do
      TriggerSQL.install_function_for_table(table,
        store_changed_from: false,
        except_columns: [],
        exclude: [],
        mask: ["secret"]
      )
    end

    test "--tables public.posts finds config keyed posts", %{tmp: tmp} do
      Application.put_env(:threadline, :trigger_capture, tables: %{"posts" => [mask: ["secret"]]})

      run_triggers(tmp, ["--tables", "public.posts"])

      [file] = trigger_files(tmp)

      assert [function, trigger | _] = executes(file, :up)
      assert function == masked_posts_function("public.posts")

      assert trigger ==
               TriggerSQL.create_trigger("public.posts", :per_table, redacted_columns: ["secret"])
    end

    test "--tables posts finds config keyed public.posts", %{tmp: tmp} do
      Application.put_env(:threadline, :trigger_capture,
        tables: %{"public.posts" => [mask: ["secret"]]}
      )

      run_triggers(tmp, ["--tables", "posts"])

      [file] = trigger_files(tmp)

      assert [function, trigger | _] = executes(file, :up)
      assert function == masked_posts_function("posts")

      assert trigger ==
               TriggerSQL.create_trigger("posts", :per_table, redacted_columns: ["secret"])
    end

    test "one table under two config keys stops the task", %{tmp: tmp} do
      Application.put_env(:threadline, :trigger_capture,
        tables: %{"posts" => [mask: ["secret"]], "public.posts" => [mask: ["email"]]}
      )

      error =
        assert_raise Mix.Error, fn -> run_triggers(tmp, ["--tables", "posts"]) end

      assert error.message =~ "more than one key"
      assert error.message =~ "posts, public.posts (all public.posts)"
      assert trigger_files(tmp) == []
    end

    test "--tables naming one table twice stops the task", %{tmp: tmp} do
      error =
        assert_raise Mix.Error, fn ->
          run_triggers(tmp, ["--tables", "posts,users,public.posts"])
        end

      assert error.message =~ "--tables lists the same table more than once"
      assert error.message =~ "posts, public.posts (all public.posts)"
      refute error.message =~ "users"
      assert trigger_files(tmp) == []
    end

    test "a malformed primary_key: stops the task with a config-prefixed Mix error", %{
      tmp: tmp
    } do
      Application.put_env(:threadline, :trigger_capture, tables: %{"t" => [primary_key: []]})

      error = assert_raise Mix.Error, fn -> run_triggers(tmp, ["--tables", "t"]) end

      assert String.starts_with?(error.message, "config :threadline, :trigger_capture")
      assert trigger_files(tmp) == []
    end

    test "there is no --primary-key CLI flag", %{tmp: tmp} do
      error =
        assert_raise Mix.Error, fn ->
          run_triggers(tmp, ["--tables", "posts", "--primary-key", "x"])
        end

      assert error.message =~ "Unknown options"
      assert trigger_files(tmp) == []
    end
  end
end
