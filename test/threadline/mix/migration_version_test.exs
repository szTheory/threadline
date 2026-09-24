defmodule Threadline.Mix.MigrationVersionTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Mix.MigrationVersion

  @now ~N[2026-09-24 15:18:12]

  setup do
    dir =
      Path.join(
        System.tmp_dir!(),
        "threadline-migration-version-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)

    %{dir: dir}
  end

  defp touch(dir, relative) do
    file = Path.join(dir, relative)
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, "# test fixture\n")
  end

  describe "next/3" do
    test "asking for no versions returns none", %{dir: dir} do
      touch(dir, "20260101000000_existing.exs")

      assert MigrationVersion.next(dir, 0, @now) == []
    end

    test "an empty directory starts at the current second", %{dir: dir} do
      assert MigrationVersion.next(dir, 3, @now) ==
               ["20260924151812", "20260924151813", "20260924151814"]
    end

    test "a future-dated migration pushes every version past it, carrying the date",
         %{dir: dir} do
      touch(dir, "20991231235959_host_thing.exs")

      assert MigrationVersion.next(dir, 3, @now) ==
               ["21000101000000", "21000101000001", "21000101000002"]
    end

    test "a maximum that is not a valid timestamp falls back to integer steps", %{dir: dir} do
      touch(dir, "99999999999999_bad.exs")

      assert MigrationVersion.next(dir, 3, @now) ==
               ["100000000000000", "100000000000001", "100000000000002"]
    end

    test "a small integer numbering scheme below now uses the current second", %{dir: dir} do
      touch(dir, "7_legacy.exs")

      assert ["20260924151812" | _] = MigrationVersion.next(dir, 3, @now)
    end

    test "migrations in subdirectories are counted, as Ecto counts them", %{dir: dir} do
      touch(dir, "sub/20991231235959_nested.exs")

      assert ["21000101000000" | _] = MigrationVersion.next(dir, 2, @now)
    end

    test "files without an integer prefix followed by an underscore are ignored",
         %{dir: dir} do
      touch(dir, "README.exs")
      touch(dir, "seeds.exs")
      touch(dir, "99999999999999.exs")

      assert MigrationVersion.next(dir, 1, @now) == ["20260924151812"]
    end

    test "a clock at the last second of the year carries into the next", %{dir: dir} do
      assert MigrationVersion.next(dir, 2, ~N[2026-12-31 23:59:59]) ==
               ["20261231235959", "20270101000000"]
    end
  end
end
