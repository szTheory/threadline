defmodule Threadline.FacadeOnlyReferencesContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  # D-12/SC2: guides, READMEs and the example app must call the Threadline
  # facade, never the hidden Threadline.Query / Threadline.Investigation
  # modules directly — except the one documented Ecto-composition escape
  # hatch, Threadline.Query.timeline_query/1 (named, not linked, per D-01 in
  # the 231 moduledoc). This is a separate contract from
  # public_surface_contract_test.exs's module-visibility ownership tags.

  @repo_root File.cwd!()

  # Scope: read-only, in-tree docs and example-app source an adopter would
  # copy from. Excluded on purpose (231-CONTEXT.md D-12): CHANGELOG.md
  # (historical), examples/threadline_phoenix/test/** (internal verification),
  # e2e/ artifacts, and .planning/.
  @scope_globs [
    "guides/*.md",
    "README.md",
    "examples/threadline_phoenix/README.md",
    "examples/threadline_phoenix/lib/**/*.{ex,heex}",
    "examples/threadline_phoenix/priv/scripts/*.exs"
  ]

  # Locked patterns (231-CONTEXT.md D-12 / 231-03-PLAN.md interfaces).
  # Backtick form: a markdown inline-code reference with an arity, e.g.
  # `Threadline.Investigation.row_history/4`.
  @backtick_regex ~r/`Threadline\.(?:Query|Investigation)\.([a-z_]\w*)[!?]?\/\d+`/
  # Call form: an actual function call, e.g. Threadline.Query.timeline(recent).
  @call_regex ~r/Threadline\.(?:Query|Investigation)\.([a-z_]\w*)[!?]?\s*\(/
  # Bare alias of the hidden module itself — NOT a struct-group alias such as
  # `alias Threadline.Investigation.{IncidentBundle, ...}`, which is followed
  # by a dot and must never trip this guard.
  @bare_alias_regex ~r/alias\s+Threadline\.(?:Query|Investigation)\b(?!\.)/

  # Exact-match allowlist. "timeline_query_x" or "timeline_query2" must NOT
  # match "timeline_query" — this is membership, never a prefix check.
  @allowed_functions ["timeline_query"]

  defp scope_files do
    @scope_globs
    |> Enum.flat_map(fn glob -> Path.wildcard(Path.join(@repo_root, glob)) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp relative(path), do: Path.relative_to(path, @repo_root)

  defp scan_line(regex, line) do
    Regex.scan(regex, line)
    |> Enum.map(fn [full, name | _] -> {name, full} end)
  end

  # Given a label (a file path) and its content, returns
  # {label, line_number, matched_text} for every hidden-module reference that
  # is not the exact, allowlisted escape hatch.
  defp offenders(label, content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      (scan_line(@backtick_regex, line) ++ scan_line(@call_regex, line))
      |> Enum.reject(fn {name, _full} -> name in @allowed_functions end)
      |> Enum.map(fn {_name, full} -> {label, line_no, full} end)
    end)
  end

  # Given a label and its content, returns {label, line_number, matched_text}
  # for every bare alias of the hidden modules (struct-group aliases excluded).
  defp bare_aliases(label, content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      case Regex.scan(@bare_alias_regex, line) do
        [] -> []
        matches -> Enum.map(matches, fn [full | _] -> {label, line_no, full} end)
      end
    end)
  end

  defp format_offenders(offenders) do
    offenders
    |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)
    |> Enum.map(fn {label, line_no, full} -> "#{label}:#{line_no} #{full}" end)
    |> Enum.join("\n")
  end

  describe "self-test (fixture, non-vacuous)" do
    test "the fixture yields exactly the hidden reference, the hidden call, and the near-miss as offenders" do
      fixture = """
      See `Threadline.Investigation.row_history/4` for the full history.
      changes = Threadline.Query.timeline(recent)
      Use `Threadline.Query.timeline_query/1` for custom queries.
      `Threadline.Query.timeline_query_x/1` is not the escape hatch.
      """

      found = offenders("fixture", fixture)

      assert length(found) == 3

      matched_texts = Enum.map(found, fn {_label, _line, full} -> full end)

      assert Enum.any?(matched_texts, &(&1 == "`Threadline.Investigation.row_history/4`"))
      assert Enum.any?(matched_texts, &(&1 == "Threadline.Query.timeline("))
      assert Enum.any?(matched_texts, &(&1 == "`Threadline.Query.timeline_query_x/1`"))

      refute Enum.any?(matched_texts, &(&1 == "`Threadline.Query.timeline_query/1`"))
    end

    test "offenders are sorted by {path, line} regardless of input order" do
      fixture_a =
        "`Threadline.Query.timeline_b/2`\nchanges = Threadline.Investigation.row_history(1)\n"

      fixture_b = "`Threadline.Query.timeline_a/2`\n"

      found =
        (offenders("b.md", fixture_b) ++ offenders("a.md", fixture_a))
        |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)

      assert found == [
               {"a.md", 1, "`Threadline.Query.timeline_b/2`"},
               {"a.md", 2, "Threadline.Investigation.row_history("},
               {"b.md", 1, "`Threadline.Query.timeline_a/2`"}
             ]
    end
  end

  describe "scope globs are non-empty (never vacuous)" do
    for glob <- @scope_globs do
      test "#{glob} resolves to at least one file" do
        matches = Path.wildcard(Path.join(@repo_root, unquote(glob)))
        assert matches != [], "scope glob #{unquote(glob)} matched zero files"
      end
    end
  end

  describe "the real scope" do
    test "reports zero facade-only offenders" do
      found =
        scope_files()
        |> Enum.flat_map(fn path ->
          offenders(relative(path), File.read!(path))
        end)
        |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)

      assert found == [], """
      Found hidden-module reference(s) outside the documented escape hatch \
      (Threadline.Query.timeline_query/1). Rewrite to a Threadline facade call:

      #{format_offenders(found)}
      """
    end

    test "has zero bare aliases of the hidden modules (extend the scanner otherwise)" do
      found =
        scope_files()
        |> Enum.flat_map(fn path ->
          bare_aliases(relative(path), File.read!(path))
        end)
        |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)

      assert found == [], """
      Found a bare alias of a hidden module (Threadline.Query or \
      Threadline.Investigation) outside a struct-group alias — extend the \
      scanner to cover this call shape, since an aliased call site would \
      otherwise pass unnoticed:

      #{format_offenders(found)}
      """
    end

    test "the alias guard does not flag a struct-group alias fixture" do
      fixture =
        "alias Threadline.Investigation.{IncidentBundle, IncidentChange, LinkedChange}\n"

      assert bare_aliases("fixture", fixture) == []
    end

    test "the alias guard flags a bare alias fixture" do
      fixture = "alias Threadline.Query\n"

      assert [{"fixture", 1, "alias Threadline.Query"}] = bare_aliases("fixture", fixture)
    end
  end
end
