defmodule Threadline.Mix.TriggerMigrationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Capture.{Naming, TriggerSQL}
  alias Threadline.Mix.{MigrationVersion, TriggerMigration}
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL

  @hex_evaluator_fixture "priv/ci/hex_evaluator/priv/repo/migrations/20260424080642_threadline_triggers_posts.exs"

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "threadline-trigger-migration-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    %{dir: dir}
  end

  defp write(dir, relative, contents) do
    file = Path.join(dir, relative)
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, contents)
    file
  end

  defp public(table), do: %{schema: "public", table: table}

  # A migration as the current generator writes it.
  defp generated(table) do
    create = TriggerSQL.create_trigger(table, :default, storage_schema: "threadline")
    LegacyTriggerSQL.migration_source("Gen", [create], [TriggerSQL.drop_trigger(table)])
  end

  defp taken(names, modules) do
    %{names: MapSet.new(names), modules: MapSet.new(modules)}
  end

  describe "resolve_name/2" do
    test "a free base keeps today's name and module" do
      assert TriggerMigration.resolve_name(["posts"], taken([], [])) ==
               {"threadline_triggers_posts", "ThreadlineTriggersPosts"}
    end

    test "a taken name moves to the next ordinal" do
      assert TriggerMigration.resolve_name(["posts"], taken(["threadline_triggers_posts"], [])) ==
               {"threadline_triggers_posts_2", "ThreadlineTriggersPosts2"}
    end

    test "a taken module alone moves to the next ordinal" do
      assert TriggerMigration.resolve_name(["posts"], taken([], ["ThreadlineTriggersPosts"])) ==
               {"threadline_triggers_posts_2", "ThreadlineTriggersPosts2"}
    end

    test "the base and the second ordinal taken gives the third" do
      existing =
        taken(
          ["threadline_triggers_posts"],
          ["ThreadlineTriggersPosts", "ThreadlineTriggersPosts2"]
        )

      assert TriggerMigration.resolve_name(["posts"], existing) ==
               {"threadline_triggers_posts_3", "ThreadlineTriggersPosts3"}
    end

    test "several tables whose joined name is taken" do
      assert TriggerMigration.resolve_name(["a", "b"], taken(["threadline_triggers_a_b"], [])) ==
               {"threadline_triggers_a_b_2", "ThreadlineTriggersAB2"}
    end

    test "a capitalised table keeps today's module" do
      assert TriggerMigration.resolve_name(["AuditLog"], taken([], [])) ==
               {"threadline_triggers_AuditLog", "ThreadlineTriggersAuditLog"}
    end

    test "Users after users moves on because the modules clash", %{dir: dir} do
      write(
        dir,
        "20260101000000_threadline_triggers_users.exs",
        "defmodule ThreadlineTriggersUsers do\nend\n"
      )

      assert TriggerMigration.resolve_name(["Users"], TriggerMigration.scan(dir)) ==
               {"threadline_triggers_Users_2", "ThreadlineTriggersUsers2"}
    end

    test "parsed pairs name the migration like the table strings" do
      pairs = Enum.map(["posts", "billing.invoices"], &StorageSchema.parse_table_identifier/1)

      assert TriggerMigration.resolve_name(pairs, taken([], [])) ==
               {"threadline_triggers_posts_billing_invoices",
                "ThreadlineTriggersPostsBillingInvoices"}
    end

    test "50 tables get a name of at most 63 bytes, and a numbered one keeps its hash" do
      tables = for n <- 1..50, do: "table_number_#{n}"

      {name, module} = TriggerMigration.resolve_name(tables, taken([], []))
      assert byte_size(name) <= 63
      assert [_, hash] = Regex.run(~r/_([0-9a-f]{12})\z/, name)

      {name2, module2} = TriggerMigration.resolve_name(tables, taken([name], []))
      assert byte_size(name2) <= 63
      assert String.ends_with?(name2, "_" <> hash <> "_2")
      assert module2 != module
    end
  end

  describe "scan/1" do
    test "reads migrations in subdirectories", %{dir: dir} do
      write(dir, "20260101000000_top.exs", "defmodule Top do\nend\n")
      write(dir, "nested/20260101000001_nested.exs", "defmodule Nested do\nend\n")

      scan = TriggerMigration.scan(dir)

      assert MapSet.equal?(scan.names, MapSet.new(["top", "nested"]))
      assert MapSet.equal?(scan.modules, MapSet.new(["Top", "Nested"]))
      assert length(scan.sources) == 2
    end

    test "ignores files that are not migrations", %{dir: dir} do
      write(dir, "seeds.exs", "defmodule Seeds do\nend\n")
      write(dir, "20260101000000_real.exs", "defmodule Real do\nend\n")

      scan = TriggerMigration.scan(dir)

      assert MapSet.equal?(scan.names, MapSet.new(["real"]))
      assert MapSet.equal?(scan.modules, MapSet.new(["Real"]))
    end

    test "captures a full module alias", %{dir: dir} do
      write(
        dir,
        "20260101000000_add_things.exs",
        "defmodule MyApp.Repo.Migrations.AddThings do\n  use Ecto.Migration\nend\n"
      )

      scan = TriggerMigration.scan(dir)

      assert MapSet.member?(scan.modules, "MyApp.Repo.Migrations.AddThings")
    end

    test "reads a host file as text without running or compiling it", %{dir: dir} do
      sentinel = Path.join(dir, "ran.txt")

      write(dir, "20260101000000_evil.exs", """
      File.write!(#{inspect(sentinel)}, "ran")
      raise "must not run"

      defmodule Evil.Migration do
        def up(( do
      """)

      scan = TriggerMigration.scan(dir)

      assert MapSet.member?(scan.names, "evil")
      assert MapSet.member?(scan.modules, "Evil.Migration")
      refute File.exists?(sentinel)
    end
  end

  describe "rerun?/2" do
    test "no sources means no earlier trigger migration" do
      refute TriggerMigration.rerun?(public("posts"), [])
    end

    test "the unqualified form written up to release 0.9.0, from the hex_evaluator fixture" do
      source = File.read!(@hex_evaluator_fixture)

      assert TriggerMigration.rerun?(public("posts"), [source])
      refute TriggerMigration.rerun?(public("comments"), [source])
    end

    test "the quoted CREATE TRIGGER form of releases 0.10.0 and 0.10.1" do
      create = LegacyTriggerSQL.v0_10_0_create_trigger("public", "posts")
      source = LegacyTriggerSQL.migration_source("Old", [create], [])

      assert TriggerMigration.rerun?(public("posts"), [source])
    end

    test "the quoted CREATE OR REPLACE TRIGGER form of release 0.10.2" do
      create = LegacyTriggerSQL.v0_10_2_create_trigger("billing", "invoices")
      source = LegacyTriggerSQL.migration_source("Old", [create], [])

      assert TriggerMigration.rerun?(%{schema: "billing", table: "invoices"}, [source])
      refute TriggerMigration.rerun?(public("invoices"), [source])
      refute TriggerMigration.rerun?(public("billing_invoices"), [source])
    end

    test "the form the generator writes today" do
      assert TriggerMigration.rerun?(public("posts"), [generated("posts")])
    end

    test "two tables sharing a 46-byte prefix are not reruns of each other" do
      prefix = String.duplicate("p", 46)
      a = prefix <> "_alpha"
      b = prefix <> "_beta"
      assert Naming.trigger_name(a) == Naming.trigger_name(b)

      sources = [generated(a)]

      assert TriggerMigration.rerun?(public(a), sources)
      refute TriggerMigration.rerun?(public(b), sources)
    end

    test "public.a_b and a.b are told apart" do
      assert TriggerMigration.rerun?(public("a_b"), [generated("a_b")])
      refute TriggerMigration.rerun?(%{schema: "a", table: "b"}, [generated("a_b")])

      assert TriggerMigration.rerun?(%{schema: "a", table: "b"}, [generated("a.b")])
      refute TriggerMigration.rerun?(public("a_b"), [generated("a.b")])
    end

    test "an unquoted ON table is case-folded to lower case" do
      create = LegacyTriggerSQL.v0_9_create_trigger("Posts")
      source = LegacyTriggerSQL.migration_source("Old", [create], [])

      assert TriggerMigration.rerun?(public("posts"), [source])
      refute TriggerMigration.rerun?(public("Posts"), [source])
    end

    test "a quoted ON table keeps its exact case" do
      create = LegacyTriggerSQL.v0_10_2_create_trigger("public", "Users")
      source = LegacyTriggerSQL.migration_source("Old", [create], [])

      assert TriggerMigration.rerun?(public("Users"), [source])
      refute TriggerMigration.rerun?(public("users"), [source])
    end

    test "an unqualified ON matches the table in any schema" do
      source =
        LegacyTriggerSQL.migration_source(
          "Old",
          [LegacyTriggerSQL.v0_9_create_trigger("posts")],
          []
        )

      assert TriggerMigration.rerun?(%{schema: "blog", table: "posts"}, [source])
    end

    test "a DROP TRIGGER statement alone is ignored" do
      drop = "DROP TRIGGER IF EXISTS threadline_audit_posts ON posts"
      source = LegacyTriggerSQL.migration_source("Old", [], [drop])

      refute TriggerMigration.rerun?(public("posts"), [source])
    end

    test "a trigger without the threadline_audit_ prefix is ignored" do
      create =
        String.replace(
          LegacyTriggerSQL.v0_9_create_trigger("posts"),
          "threadline_audit_",
          "my_audit_"
        )

      source = LegacyTriggerSQL.migration_source("Old", [create], [])

      refute TriggerMigration.rerun?(public("posts"), [source])
    end

    test "a CREATE TRIGGER in a down body counts" do
      create = LegacyTriggerSQL.v0_10_2_create_trigger("public", "posts")
      source = LegacyTriggerSQL.migration_source("Old", [], [create])

      assert TriggerMigration.rerun?(public("posts"), [source])
    end

    test "a DO block that only drops a function is not a match" do
      block = """
      DO $$
      BEGIN
        EXECUTE 'DROP FUNCTION IF EXISTS "public"."threadline_capture_changes_posts"()';
      END $$;
      """

      source = LegacyTriggerSQL.migration_source("Old", [block], [])

      refute TriggerMigration.rerun?(public("posts"), [source])
    end

    test "parse_triggers/1 reads the name, schema and table of each statement" do
      source =
        LegacyTriggerSQL.migration_source(
          "Old",
          [
            LegacyTriggerSQL.v0_9_create_trigger("Posts"),
            LegacyTriggerSQL.v0_10_2_create_trigger("billing", "Invoices")
          ],
          []
        )

      assert TriggerMigration.parse_triggers([source]) == [
               %{trigger: "threadline_audit_posts", schema: nil, table: "posts"},
               %{
                 trigger: "threadline_audit_billing_Invoices",
                 schema: "billing",
                 table: "Invoices"
               }
             ]
    end

    test "parse_triggers/1 reads the DO-block trigger statement for public, schema and mixed-case tables" do
      source =
        LegacyTriggerSQL.migration_source(
          "New",
          [
            TriggerSQL.create_trigger("posts"),
            TriggerSQL.create_trigger("billing.invoices"),
            TriggerSQL.create_trigger("public.Users")
          ],
          []
        )

      assert TriggerMigration.parse_triggers([source]) == [
               %{trigger: "threadline_audit_posts", schema: "public", table: "posts"},
               %{
                 trigger: "threadline_audit_billing_invoices",
                 schema: "billing",
                 table: "invoices"
               },
               %{trigger: "threadline_audit_Users", schema: "public", table: "Users"}
             ]
    end
  end

  describe "MigrationVersion.existing/1" do
    test "returns version, name and path for each migration", %{dir: dir} do
      top = write(dir, "20260101000000_top.exs", "# fixture\n")
      nested = write(dir, "nested/20260101000001_nested_name.exs", "# fixture\n")
      write(dir, "notes.exs", "# not a migration\n")

      assert Enum.sort(MigrationVersion.existing(dir)) == [
               {20_260_101_000_000, "top", top},
               {20_260_101_000_001, "nested_name", nested}
             ]
    end
  end
end
