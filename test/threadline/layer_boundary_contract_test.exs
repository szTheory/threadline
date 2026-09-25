defmodule Threadline.LayerBoundaryContractTest do
  @moduledoc """
  GATE-03 layer boundary, asserted mechanically rather than promised in prose.

  Threadline is layered: capture, semantics, and query/export sit underneath the
  operator surface, and the operator surface depends on them, never the other
  way round. A module outside the surface that names an operator-surface module
  inverts that layering: the lower layer can no longer ship, compile, or be
  reasoned about without the UI on top of it.

  The check is a case-sensitive substring scan for `OperatorSurface` over every
  `lib/**/*.ex` file outside the surface tree. Every operator-surface module
  lives under the `Threadline.OperatorSurface` namespace, so any alias, call, or
  fully qualified reference to one contains that substring. Case sensitivity
  keeps prose like "operator surface" in docs and comments from tripping it.

  One non-surface file is allowlisted: the maintainer-only critic Mix task,
  which sits outside the four layers and is excluded from the Hex package. The
  allowlist is existence-checked, so a stale entry fails instead of silently
  widening the gate.
  """

  use ExUnit.Case, async: true

  @lib_glob "lib/**/*.ex"
  @surface_root "lib/threadline/operator_surface.ex"
  @surface_dir "lib/threadline/operator_surface/"
  @allowlist ["lib/mix/tasks/critic.synth.ex"]
  @needle "OperatorSurface"

  defp scanned_files do
    @lib_glob
    |> Path.wildcard()
    |> Enum.reject(fn path ->
      path == @surface_root or String.starts_with?(path, @surface_dir) or path in @allowlist
    end)
    |> Enum.sort()
  end

  test "scan set is non-empty" do
    assert scanned_files() != [],
           "no files matched #{@lib_glob} outside the operator surface. The glob or the " <>
             "exclusions are broken; an empty scan set would let this guard pass " <>
             "vacuously while every layer inversion went unnoticed."

    # This contract must not depend on local planning files.
    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end

  test "allowlisted paths and the surface root exist" do
    for path <- [@surface_root | @allowlist] do
      assert File.regular?(path),
             "#{path} does not exist. Remove or correct the stale entry; an exclusion " <>
               "for a missing file silently widens the layer-boundary gate."
    end
  end

  test "no lib module outside the operator surface references it" do
    offenders =
      for path <- scanned_files(),
          String.contains?(File.read!(path), @needle),
          do: Path.relative_to_cwd(path)

    assert offenders == [],
           "these lib files outside the operator surface reference #{@needle}, which " <>
             "inverts the layering: #{inspect(offenders)}. Move the module into its own " <>
             "layer or route through an injected function; do not widen the allowlist " <>
             "without review."
  end
end
