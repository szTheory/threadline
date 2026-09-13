defmodule Threadline.OptionalDepsContractTest do
  @moduledoc """
  GREEN-07 resurrection guard (Phase 198, Plan 09).

  `mix.exs` declares `phoenix`, `phoenix_live_view`, `phoenix_html`, and
  `phoenix_pubsub` as `optional: true` so capture-only adopters can compile
  Threadline without Phoenix on the classpath. `mix verify.compile_no_optional`
  (`ci.yml`'s "Compile without optional deps" job) proves that promise by
  compiling with those deps absent from the build path.

  Every `lib/` module that references one of those optional modules at
  compile time (`use`/`import`/`require`) must open with a file-scope
  `if Code.ensure_loaded?(Phoenix.X) do ... end` guard — the idiom already
  used by every module under `lib/threadline/operator_surface/`. Two modules
  (`ui.ex`, `controllers/theme_controller.ex`) shipped without one and broke
  `verify.compile_no_optional` in CI rather than in the diff that introduced
  the defect.

  This test derives the roster of files needing a guard from the filesystem
  (not a hand-maintained allowlist — same failure mode `ui_form_policy_contract_test.exs`
  fixed for form declarations) so the next unguarded module fails `mix test`
  in its own diff instead of surfacing only in the "Compile without optional
  deps" CI lane.
  """

  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @lib_dir Path.join(@repo_root, "lib")

  # A compile-time load of one of the four optional-dep-bearing Phoenix
  # namespaces: `use`, `import`, or `require` naming the module directly.
  # A bare `alias` does not trigger a compile-time load of the aliased
  # module and is deliberately excluded — see components/icon.ex, which
  # aliases Phoenix.LiveView.JS inside an already-guarded block.
  @directive_regex ~r/^\s*(use|import|require)\s+Phoenix\.(Component|LiveView|Controller|HTML|PubSub)\b/m

  defp lib_files, do: Path.wildcard(Path.join(@lib_dir, "**/*.ex"))

  # Strip full-line comments before matching so a moduledoc/comment mention
  # of a Phoenix module (e.g. coverage/snapshot.ex's explanatory prose)
  # cannot flip the classification. Only whole-line `#` comments are
  # stripped, matching how the offending directives are always written on
  # their own line in this codebase.
  defp strip_comment_lines(content) do
    content
    |> String.split("\n")
    |> Enum.reject(fn line -> line |> String.trim() |> String.starts_with?("#") end)
    |> Enum.join("\n")
  end

  defp references_optional_phoenix?(path) do
    path
    |> File.read!()
    |> strip_comment_lines()
    |> then(&Regex.match?(@directive_regex, &1))
  end

  defp needs_guard_roster do
    lib_files()
    |> Enum.filter(&references_optional_phoenix?/1)
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()
  end

  defp first_non_blank_line(path) do
    path
    |> File.stream!()
    |> Enum.find(fn line -> String.trim(line) != "" end)
    |> case do
      nil -> ""
      line -> String.trim(line)
    end
  end

  defp guarded?(relative_path) do
    @repo_root
    |> Path.join(relative_path)
    |> first_non_blank_line()
    |> String.starts_with?("if Code.ensure_loaded?(")
  end

  test "the derived roster of optional-Phoenix-referencing lib files is non-empty" do
    roster = needs_guard_roster()

    assert roster != [],
           "no lib/**/*.ex files matched the optional-Phoenix compile-time directive " <>
             "regex under #{@lib_dir} — the Path.wildcard glob or the classifier regex " <>
             "is broken, and every per-file assertion below would pass vacuously"
  end

  test "every file in the roster has a file-scope Code.ensure_loaded? guard on its first line" do
    roster = needs_guard_roster()
    unguarded = Enum.reject(roster, &guarded?/1)

    assert unguarded == [],
           "unguarded optional-Phoenix reference(s) — add the guard shown for each path:\n" <>
             Enum.map_join(unguarded, "\n", fn path ->
               "  #{path} — wrap the module body in " <>
                 "`if Code.ensure_loaded?(Phoenix.X) do ... end` as the file's first line " <>
                 "(see lib/threadline/operator_surface/components/logo.ex or " <>
                 "controllers/export_controller.ex for the exact idiom)"
             end)
  end

  test "coverage/snapshot.ex (moduledoc-only Phoenix mention) is absent from the roster" do
    snapshot_path = "lib/threadline/operator_surface/coverage/snapshot.ex"
    roster = needs_guard_roster()

    assert File.exists?(Path.join(@repo_root, snapshot_path)),
           "fixture path moved — update this test's non-vacuity target"

    refute snapshot_path in roster,
           "coverage/snapshot.ex only *mentions* Phoenix.LiveView inside its moduledoc " <>
             "explaining why it deliberately has no guard (D-36); it must not be classified " <>
             "as needing one. If this assertion fails, the classifier is over-matching on " <>
             "prose instead of compile-time directives."
  end
end
