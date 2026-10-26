defmodule Threadline.UiCriticRetirementDocContractTest do
  @moduledoc """
  Pins the CONTRIBUTING.md "Retired: UI critic loop" pointer. The LLM UI critic
  and its runbook were removed from the tree; the only thing left is a short
  pointer to the annotated restore tag. This contract keeps the pointer
  present, keeps the retired runbook and its commands from creeping back, and
  keeps any critic runbook out of the published adopter guides.

  Keep criterion: it locks a removed artifact (the critic runbook and its
  commands) against reintroduction.
  """
  use ExUnit.Case, async: true
  @moduletag :repo_contract

  @contributing File.read!("CONTRIBUTING.md")
  @retired_heading "## Retired: UI critic loop"
  @restore_tag "archive/ui-critic-loop"

  test "CONTRIBUTING.md carries one retired pointer that names the restore tag" do
    occurrences = @contributing |> String.split(@retired_heading) |> length() |> Kernel.-(1)

    assert occurrences == 1,
           "CONTRIBUTING.md must contain the #{inspect(@retired_heading)} heading exactly once, " <>
             "found #{occurrences}"

    section = retired_section(@contributing)

    assert String.contains?(section, "`#{@restore_tag}`"),
           "the retired pointer must name the annotated restore tag #{@restore_tag}"

    assert String.contains?(section, "git cat-file -p #{@restore_tag}"),
           "the retired pointer must say how to print the restore recipe"
  end

  test "the retired runbook headings are gone" do
    for heading <- ["## Local-only critic", "## Forward-only gate — run one iteration"] do
      refute String.contains?(@contributing, heading),
             "CONTRIBUTING.md still carries the retired runbook heading #{inspect(heading)}"
    end
  end

  test "no retired critic command survives in CONTRIBUTING.md" do
    for command <- ["npm run critic:", "mix verify.ui_critique"] do
      refute String.contains?(@contributing, command),
             "CONTRIBUTING.md still documents the retired critic command #{inspect(command)}"
    end
  end

  test "no published adopter guide leaks a critic runbook" do
    guides = Path.wildcard("guides/**/*.md")

    if guides == [] do
      flunk("guides/**/*.md matched no file; the leak guard would pass vacuously")
    end

    for guide <- guides do
      body = File.read!(guide)

      for needle <- ["critic:gate", "verify.ui_critique"] do
        refute String.contains?(body, needle),
               "#{guide} leaks the retired critic (#{inspect(needle)}) into published adopter docs"
      end
    end
  end

  defp retired_section(contributing) do
    [_before, rest] = String.split(contributing, @retired_heading, parts: 2)

    case Regex.split(~r/^## /m, rest, parts: 2) do
      [section, _next] -> section
      [section] -> section
    end
  end
end
