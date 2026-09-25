defmodule Threadline.NoWarnUndefinedContractTest do
  @moduledoc """
  GATE-04: the Capture/Semantics compiler suppression stays deleted.

  `Threadline.Capture.AuditTransaction` once carried a compiler directive that
  silenced undefined-module warnings for `Threadline.Semantics.AuditAction`. It
  suppressed nothing — a forced compile with warnings as errors is clean without
  it — so it only served to hide a future real problem between the capture and
  semantics layers.

  Deleting it is not enough on its own: the same suppression could quietly come
  back somewhere else, most easily as a project-wide compiler option. This
  contract therefore scans both places it could live — every source file under
  `lib/` and the project's `elixirc_options` — so the suppression can be
  removed but never relocated.
  """

  use ExUnit.Case, async: true

  @lib_glob "lib/**/*.ex"

  # Assembled at runtime so this file never carries the literal directive name.
  # It is outside the lib glob, but grep-based audits of the repo should not
  # report the guard itself as an offender.
  defp needle, do: "no_warn_" <> "undefined"

  defp needle_atom, do: String.to_existing_atom(needle())

  test "no lib source file carries the suppression (GATE-04)" do
    files = Path.wildcard(@lib_glob)

    assert files != [],
           "no files matched #{@lib_glob} — the glob is broken. An empty scan set " <>
             "would let this guard pass vacuously."

    offenders =
      for path <- files,
          String.contains?(File.read!(path), needle()),
          do: Path.relative_to_cwd(path)

    assert offenders == [],
           "these lib files carry a #{needle()} compiler suppression: " <>
             "#{inspect(offenders)}. GATE-04 requires it deleted, not relocated. " <>
             "Fix the underlying compile dependency instead of silencing the warning."

    # This contract must not depend on local planning files.
    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end

  test "the mix project does not relocate the suppression into elixirc_options (GATE-04)" do
    project_options = Threadline.MixProject.project()[:elixirc_options] || []
    config_options = Mix.Project.config()[:elixirc_options] || []

    for {source, options} <- [project: project_options, config: config_options] do
      assert Keyword.get(options, needle_atom()) == nil,
             "#{source} elixirc_options carries #{needle()}: #{inspect(options)}. " <>
               "GATE-04 forbids moving the suppression into compiler options."
    end
  end
end
