defmodule Threadline.PersonaRoutingDocContractTest do
  @moduledoc """
  Locks the Phase 191 intent-verb routing (D-191-13..17): the four verb lanes
  (Evaluate/Adopt/Operate/Contribute) agree on both surfaces — README
  `## Start here` prose owns the words, ExDoc `groups_for_extras` owns the
  sidebar structure — and no standalone start-here/where-to-go-next guide exists.

  This is the subset/label contract. `release_artifact_contract_test.exs` owns
  the exact-equality assertion on the full `groups_for_extras` key order; the two
  must agree on the four verbs.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  # Verb lane -> canonical landing link (D-191-14). Frozen.
  @lanes [
    {"Evaluate", "guides/evaluating-threadline.md"},
    {"Adopt", "guides/getting-started-saas.md"},
    {"Operate", "guides/operator-surface.md"},
    {"Contribute", "CONTRIBUTING.md"}
  ]

  @lane_keys [:Evaluate, :Adopt, :Operate, :Contribute]

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  defp groups_for_extras do
    Threadline.MixProject.project()[:docs][:groups_for_extras]
  end

  defp start_here_slice do
    read_rel!(["README.md"])
    |> String.split("## Start here", parts: 2)
    |> Enum.at(1, "")
    |> String.split("## Evidence plane", parts: 2)
    |> hd()
  end

  test "ExDoc groups_for_extras contains the four verb routing lanes" do
    keys = Keyword.keys(groups_for_extras())

    for key <- @lane_keys do
      assert key in keys,
             "expected groups_for_extras to contain the #{inspect(key)} verb lane, got: #{inspect(keys)}"
    end
  end

  test "README Start here routes each verb lane to its canonical landing" do
    slice = start_here_slice()

    for {label, landing} <- @lanes do
      assert String.contains?(slice, label),
             "expected README `## Start here` to contain the #{inspect(label)} lane label"

      assert String.contains?(slice, landing),
             "expected the #{inspect(label)} lane to link its canonical landing #{inspect(landing)}"
    end
  end

  test "no standalone start-here / where-to-go-next guide exists (ADOPT-03)" do
    refute File.exists?(Path.join(@repo_root, "guides/where-to-go-next.md")),
           "ADOPT-03 forbids a new wayfinding guide — reader intent, not a new guide, is the fix"

    refute File.exists?(Path.join(@repo_root, "guides/start-here.md")),
           "ADOPT-03 forbids a new wayfinding guide — reader intent, not a new guide, is the fix"
  end
end
