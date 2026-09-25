defmodule Threadline.Mix.TriggerMigrationTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Mix.{MigrationVersion, TriggerMigration}

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
    test "finds the trigger as the generator writes it" do
      source = ~S|    execute "CREATE OR REPLACE TRIGGER \"threadline_audit_posts\"\nAFTER INSERT|

      assert TriggerMigration.rerun?("posts", [source])
    end

    test "finds the trigger in a legacy migration" do
      source = ~S|    execute "CREATE TRIGGER threadline_audit_posts\nAFTER INSERT OR UPDATE|

      assert TriggerMigration.rerun?("posts", [source])
    end

    test "a longer table name with the same prefix is not a match" do
      source =
        ~S|    execute "CREATE OR REPLACE TRIGGER \"threadline_audit_posts_archive\"\nAFTER|

      refute TriggerMigration.rerun?("posts", [source])
    end

    test "no sources means no earlier trigger migration" do
      refute TriggerMigration.rerun?("posts", [])
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
