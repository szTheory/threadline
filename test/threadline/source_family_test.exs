defmodule Threadline.Test.SourceFamilyTest do
  use ExUnit.Case, async: true

  alias Threadline.Test.SourceFamily

  @root Path.expand("../..", __DIR__)

  setup do
    dir =
      Path.join(System.tmp_dir!(), "source_family_#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, dir: dir}
  end

  test "a file with no sibling directory reads as exactly itself" do
    path = "lib/threadline/query/filter_params.ex"

    assert SourceFamily.files!(path) == [Path.join(@root, path)]
    assert SourceFamily.read!(path) == File.read!(Path.join(@root, path))
  end

  test "the parent comes first, then every sibling .ex/.css file in sorted order", %{dir: dir} do
    write!(dir, "a.ex", "parent")
    write!(dir, "a/z.ex", "z")
    write!(dir, "a/b.css", "b")
    write!(dir, "a/c.ex", "c")
    write!(dir, "a/nested/d.ex", "d")
    write!(dir, "a/notes.md", "ignored")

    parent = Path.join(dir, "a.ex")

    assert SourceFamily.files!(parent) ==
             Enum.map(~w(a.ex a/b.css a/c.ex a/nested/d.ex a/z.ex), &Path.join(dir, &1))

    assert SourceFamily.read!(parent) == "parent\nb\nc\nd\nz"
  end

  test "a deleted parent still reads its extracted siblings", %{dir: dir} do
    write!(dir, "a/x.ex", "sibling")

    assert SourceFamily.files!(Path.join(dir, "a.ex")) == [Path.join(dir, "a/x.ex")]
    assert SourceFamily.read!(Path.join(dir, "a.ex")) == "sibling"
  end

  test "a path with neither a file nor siblings raises naming the path", %{dir: dir} do
    missing = Path.join(dir, "missing.ex")

    error = assert_raise ArgumentError, fn -> SourceFamily.read!(missing) end
    assert error.message =~ missing
  end

  test "this test never references the planning directory" do
    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end

  defp write!(dir, relative, contents) do
    path = Path.join(dir, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end
end
