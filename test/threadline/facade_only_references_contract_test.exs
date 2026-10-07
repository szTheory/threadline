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

  # Bare module mention: a heading or prose sentence that just names the
  # hidden module with no following `.function(...)` call, no backtick
  # `Module.fun/N` reference, and no `alias` keyword — e.g.
  # `## Timeline and Threadline.Query`. Excludes a following `.word` (a
  # dotted call/reference, handled by @backtick_regex / @call_regex), a
  # following `.{` (a struct-group alias such as
  # `alias Threadline.Investigation.{IncidentBundle, ...}`), and a following
  # `(` (a call with no dot, defensive).
  @bare_module_mention_regex ~r/\bThreadline\.(?:Query|Investigation)\b(?!\.\w|\.\{|\s*\()/

  # Exact-match allowlist. "timeline_query_x" or "timeline_query2" must NOT
  # match "timeline_query" — this is membership, never a prefix check.
  @allowed_functions ["timeline_query"]

  # D-18: internal names that must never appear in adopter-facing docs — the
  # Telemetry emitters, the raw export query builder, and the deleted paged
  # structs. No per-file exemption; every scope file is checked.
  @hidden_name_regex ~r/Threadline\.Telemetry\.emit_\w+|\bexport_changes_query\b|\bTimelinePage\b|\bActorHistoryPage\b/

  # D-18: retired facade names (all arities), with or without the
  # `Threadline.` prefix, backticked or bare. `\bhistory/3` must not match
  # `actor_history/3`-style names, because `_` is a word character and `\b`
  # requires a non-word boundary immediately before the match.
  @retired_name_regex ~r/Threadline\.history\(|\bhistory\/3\b|\brow_history\/4\b|\brow_history_page\/\d+\b|\bactor_window_page\/\d+\b|\bcorrelation_bundle_page\/\d+\b/

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
      Regex.scan(@bare_alias_regex, line)
      |> Enum.map(fn [full | _] -> {label, line_no, full} end)
    end)
  end

  # Given a label and its content, returns {label, line_number, matched_text}
  # for every bare module mention of the hidden modules (dotted calls,
  # backtick references, struct-group aliases, and `alias` statements
  # excluded — those are handled by the other three detectors).
  defp bare_module_mentions(label, content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      Regex.scan(@bare_module_mention_regex, line)
      |> Enum.map(fn [full | _] -> {label, line_no, full} end)
    end)
  end

  defp format_offenders(offenders) do
    offenders
    |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)
    |> Enum.map_join("\n", fn {label, line_no, full} -> "#{label}:#{line_no} #{full}" end)
  end

  # Given a label and its content, returns {label, line_number, matched_text}
  # for every hidden-internal-name reference (emit_*, export_changes_query,
  # TimelinePage, ActorHistoryPage).
  defp hidden_name_offenders(label, content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      Regex.scan(@hidden_name_regex, line)
      |> Enum.map(fn [full | _] -> {label, line_no, full} end)
    end)
  end

  # Given a label and its content, returns {label, line_number, matched_text}
  # for every retired-facade-name reference (history/3, row_history/4,
  # row_history_page, actor_window_page, correlation_bundle_page).
  defp retired_name_offenders(label, content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      Regex.scan(@retired_name_regex, line)
      |> Enum.map(fn [full | _] -> {label, line_no, full} end)
    end)
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

  describe "self-test (bare module mention fixture, non-vacuous)" do
    test "flags a bare heading mention but not a dotted call, backtick ref, or struct-group alias" do
      fixture = """
      ## Timeline and Threadline.Query

      See `Threadline.Investigation.row_history/4` for the full history.
      changes = Threadline.Query.timeline(recent)
      alias Threadline.Investigation.{IncidentBundle, IncidentChange, LinkedChange}
      alias Threadline.Query
      """

      found = bare_module_mentions("fixture", fixture)
      matched_texts = Enum.map(found, fn {_label, _line, full} -> full end)

      assert "Threadline.Query" in matched_texts

      # The bare `alias Threadline.Query` line has no following dot/paren
      # either, so it also matches this detector — that's fine, it's a
      # second independent signal on the same line already caught by
      # @bare_alias_regex via bare_aliases/2, not a false positive.
      assert length(found) == 2

      refute Enum.any?(matched_texts, &(&1 == "Threadline.Investigation.row_history"))
      refute Enum.any?(matched_texts, &String.contains?(&1, "Investigation.{"))
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

    test "has zero bare module mentions of the hidden modules (extend the scanner otherwise)" do
      found =
        scope_files()
        |> Enum.flat_map(fn path ->
          bare_module_mentions(relative(path), File.read!(path))
        end)
        |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)

      assert found == [], """
      Found a bare mention of a hidden module (Threadline.Query or \
      Threadline.Investigation) with no following call/backtick/alias form \
      (e.g. a heading or prose sentence naming the module directly) — rewrite \
      to name the Threadline facade function instead:

      #{format_offenders(found)}
      """
    end

    test "the bare-module-mention guard does not flag a struct-group alias fixture" do
      fixture =
        "alias Threadline.Investigation.{IncidentBundle, IncidentChange, LinkedChange}\n"

      assert bare_module_mentions("fixture", fixture) == []
    end
  end

  describe "self-test (hidden/retired name fixture, non-vacuous)" do
    test "the fixture yields exactly the seven hidden/retired offenders" do
      fixture = """
      Threadline.Telemetry.emit_export_completed(...)
      Query.export_changes_query(f)
      %Threadline.Query.TimelinePage{}
      ActorHistoryPage
      Threadline.history(MyApp.User, 1, repo: R)
      `Threadline.row_history/4`
      `row_history_page/4`
      """

      hidden = hidden_name_offenders("fixture", fixture)
      retired = retired_name_offenders("fixture", fixture)

      assert length(hidden) == 4, "expected 4 hidden-name offenders, got: #{inspect(hidden)}"
      assert length(retired) == 3, "expected 3 retired-name offenders, got: #{inspect(retired)}"

      hidden_texts = Enum.map(hidden, fn {_label, _line, full} -> full end)
      retired_texts = Enum.map(retired, fn {_label, _line, full} -> full end)

      assert Enum.any?(hidden_texts, &(&1 == "Threadline.Telemetry.emit_export_completed"))
      assert Enum.any?(hidden_texts, &(&1 == "export_changes_query"))
      assert Enum.any?(hidden_texts, &(&1 == "TimelinePage"))
      assert Enum.any?(hidden_texts, &(&1 == "ActorHistoryPage"))

      assert Enum.any?(retired_texts, &(&1 == "Threadline.history("))
      assert Enum.any?(retired_texts, &(&1 == "row_history/4"))
      assert Enum.any?(retired_texts, &(&1 == "row_history_page/4"))
    end

    test "near-miss names yield no hidden/retired offenders" do
      fixture = """
      Threadline.Telemetry.transaction_committed(t)
      actor_history/2
      row_history/3
      Threadline.Page
      """

      assert hidden_name_offenders("fixture", fixture) == []
      assert retired_name_offenders("fixture", fixture) == []
    end
  end

  describe "the real scope (hidden/retired names, D-18)" do
    test "reports zero hidden internal-name offenders" do
      found =
        scope_files()
        |> Enum.flat_map(fn path -> hidden_name_offenders(relative(path), File.read!(path)) end)
        |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)

      assert found == [], """
      Found a hidden internal name (Threadline.Telemetry.emit_*, \
      export_changes_query, TimelinePage, or ActorHistoryPage) in adopter-facing \
      scope:

      #{format_offenders(found)}
      """
    end

    test "reports zero retired-facade-name offenders, and the scan covers both upgrade guides" do
      scanned = scope_files() |> Enum.map(&relative/1)

      assert "guides/upgrading-to-0.11.md" in scanned,
             "expected guides/upgrading-to-0.11.md in the scanned file list"

      assert "guides/upgrade-path.md" in scanned,
             "expected guides/upgrade-path.md in the scanned file list"

      found =
        scope_files()
        |> Enum.flat_map(fn path -> retired_name_offenders(relative(path), File.read!(path)) end)
        |> Enum.sort_by(fn {label, line_no, _full} -> {label, line_no} end)

      assert found == [], """
      Found a retired facade name (Threadline.history/3, row_history/4, \
      row_history_page, actor_window_page, or correlation_bundle_page) in \
      adopter-facing scope — rewrite to the current replacement name:

      #{format_offenders(found)}
      """
    end
  end
end
