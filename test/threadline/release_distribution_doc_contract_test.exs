defmodule Threadline.ReleaseDistributionDocContractTest do
  use ExUnit.Case, async: true

  @changelog "CHANGELOG.md"

  defp section_0_6_0 do
    changelog = File.read!(@changelog)
    [_before, rest] = String.split(changelog, "## [0.6.0]", parts: 2)
    section = hd(String.split(rest, "\n## [", parts: 2))
    section
  end

  test "CHANGELOG [0.6.0] upgrade section lists four canonical lane IDs in order" do
    section = section_0_6_0()

    assert String.contains?(section, "guides/upgrade-path.md")

    assert section =~
             ~r/`capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference`/

    refute section =~ ~r/`capture-only`, `phoenix-surface`, `sigra-reference`/
  end
end
