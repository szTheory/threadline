defmodule Threadline.DepFloorGuardTest do
  @moduledoc """
  D-16 shared-`mix.lock` false-promise guard.

  The CI min lane (Elixir 1.15) resolves the *committed* `mix.lock`, so it proves
  "1.15 compiles + tests green with current deps" — with zero margin. The next
  `mix deps.update` pulling a dependency that floors above 1.15 would silently
  break the declared 1.15 support and turn the min lane red mid-CI for a reason
  unrelated to Threadline.

  This guard fails LOUDLY at the lock instead: it inspects every fetched
  `deps/*/mix.exs` `elixir:` requirement and asserts each still admits 1.15.0.
  A locked dependency flooring above 1.15 (e.g. `~> 1.16`) fails here, naming the
  offending dep, rather than surfacing as an opaque matrix failure.

  Not folded into the async static-parse phase06 contract test: this one reads
  the fetched `deps/` tree (populated by `mix deps.get`, run in CI and by
  `mix ci.all`).
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @floor "1.15.0"

  describe "D-16: no locked dep floors above Elixir 1.15" do
    test "every deps/*/mix.exs elixir: requirement still admits #{@floor}" do
      mix_files = Path.wildcard(Path.join(@repo_root, "deps/*/mix.exs"))

      assert mix_files != [],
             "deps/ is empty — run `mix deps.get` before this guard (it inspects the fetched dep tree)"

      offenders =
        for path <- mix_files,
            {dep, req} <- [elixir_requirement(path)],
            req != nil,
            not Version.match?(@floor, req) do
          {dep, req}
        end

      assert offenders == [],
             "These locked deps floor above Elixir #{@floor} — the min-lane 1.15 support " <>
               "promise is now false. Fix the lock (pin a 1.15-compatible version) or drop " <>
               "the 1.15 floor claim:\n" <>
               (offenders
                |> Enum.map(fn {dep, req} -> "  - #{dep}: elixir #{inspect(req)}" end)
                |> Enum.join("\n"))
    end
  end

  # Returns {dep_name, requirement_string_or_nil}. Resolves both the literal
  # `elixir: "~> 1.x"` form and the module-attribute form
  # (`@elixir_requirement "~> 1.x"` ... `elixir: @elixir_requirement`).
  defp elixir_requirement(path) do
    dep = path |> Path.split() |> Enum.at(-2)
    content = File.read!(path)

    req =
      case Regex.run(~r/elixir:\s*("([^"]*)"|@([a-z_][a-z0-9_]*))/, content) do
        [_, _, literal] when is_binary(literal) and literal != "" ->
          literal

        [_, _, "", attr] ->
          resolve_attr(content, attr)

        _ ->
          nil
      end

    {dep, req}
  end

  defp resolve_attr(content, attr) do
    case Regex.run(~r/@#{Regex.escape(attr)}\s+"([^"]*)"/, content) do
      [_, value] -> value
      _ -> nil
    end
  end
end
