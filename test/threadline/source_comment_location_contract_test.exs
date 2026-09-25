defmodule Threadline.SourceCommentLocationContractTest do
  @moduledoc """
  Guards against source comments that cite a `file:line` location.

  A comment such as "see auth.ex:21-27" is correct only on the day it is
  written. The moment either file is edited, the cited lines drift and the
  comment points readers at unrelated code while still looking authoritative.
  Symbol references (a module, or a `Module.function/arity`) survive edits and
  are the durable form, so comments in `lib/` must use those instead.

  Only comment text is scanned, via `Code.string_to_quoted_with_comments/1`, so
  string literals and documentation that legitimately mention a path are not
  affected. A detector-sanity test keeps the matcher honest, and a non-empty
  scan guard keeps the whole check from passing vacuously.
  """

  use ExUnit.Case, async: true

  @lib_glob "lib/**/*.ex"

  @location_citation ~r/[A-Za-z0-9_.\/-]+\.exs?:\d+(?:-\d+)?/

  defp lib_files, do: @lib_glob |> Path.wildcard() |> Enum.sort()

  defp location_citation?(text) when is_binary(text), do: Regex.match?(@location_citation, text)

  defp comments(path) do
    {:ok, _ast, comments} =
      path
      |> File.read!()
      |> Code.string_to_quoted_with_comments(file: path)

    comments
  end

  test "the lib scan set is non-empty" do
    assert lib_files() != [],
           "no files matched #{@lib_glob}: the glob is broken, and a broken glob would " <>
             "let the location-citation scan pass vacuously"
  end

  test "lib comments cite no file:line locations" do
    offenders =
      for path <- lib_files(),
          %{line: line, text: text} <- comments(path),
          location_citation?(text) do
        {path, line, text}
      end
      |> Enum.sort_by(fn {path, line, _text} -> {path, line} end)

    assert offenders == [],
           "these lib comments cite a file:line location, which goes stale as soon as " <>
             "either file changes. Refer to the symbol instead (for example " <>
             "`Module.function/arity`):\n" <>
             Enum.map_join(offenders, "\n", fn {path, line, text} ->
               "  #{path}:#{line}  #{text}"
             end)
  end

  test "detector sanity: flags location citations and ignores symbol references" do
    assert location_citation?("see auth.ex:21-27")
    assert location_citation?("foo.exs:9")
    assert location_citation?("# lifted from lib/threadline/query.ex:120")

    refute location_citation?("see `TimelineLive.safe_validate/1`")
    refute location_citation?("Phase 204 (STRUCT-07)")
    refute location_citation?("see `Threadline.OperatorSurface.Auth`")

    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end
end
