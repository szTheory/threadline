defmodule Threadline.Test.SourceFamily do
  @moduledoc false

  # Reads a source file together with the modules extracted from it.
  #
  # Splitting `foo.ex` usually moves code into `foo/*.ex`. Source-text pins that
  # used to read `foo.ex` alone can read the whole family instead, so a pin keeps
  # holding while its text moves between the parent and its siblings.
  #
  # The family is the parent file (when it still exists) followed by every
  # `*.ex` and `*.css` file under the sibling directory named after it,
  # recursively, in alphabetical path order. That order is not semantic, so this
  # reader suits presence and absence pins. An order-bearing resource, such as a
  # stylesheet whose segment order is the cascade, needs a reader driven by its
  # own explicit ordering instead.
  #
  # Relative paths resolve against the repository root, so callers work from any
  # working directory. Returned paths are absolute.

  @root Path.expand("../..", __DIR__)

  def files!(path) do
    parent = Path.expand(path, @root)

    siblings =
      parent
      |> Path.rootname()
      |> Path.join("**/*.{ex,css}")
      |> Path.wildcard()
      |> Enum.sort()

    case Enum.filter([parent], &File.regular?/1) ++ siblings do
      [] ->
        raise ArgumentError, "no source file or extracted siblings found for #{path} (#{parent})"

      files ->
        files
    end
  end

  def read!(path), do: path |> files!() |> Enum.map_join("\n", &File.read!/1)
end
