defmodule Threadline.Phase06NyquistCIContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  describe "CI-01 (Plan 06-01 Task 1): workflow contract" do
    test "ci.yml exposes stable job keys and main-only triggers" do
      yaml = read_rel!([".github", "workflows", "ci.yml"])

      assert Regex.match?(~r/^  verify-format:/m, yaml)
      assert Regex.match?(~r/^  verify-credo:/m, yaml)
      assert Regex.match?(~r/^  verify-test:/m, yaml)

      assert Regex.match?(
               ~r/^  push:\n(?:.*\n)*?    branches: \[main\]/m,
               yaml
             )

      assert Regex.match?(
               ~r/^  pull_request:\n(?:.*\n)*?    branches: \[main\]/m,
               yaml
             )
    end
  end

  describe "CI-02 (Plan 06-01 Task 2): local parity alias" do
    test "mix.exs ci.all matches verify-test ordering (compile strict before tests)" do
      mix = read_rel!(["mix.exs"])

      assert String.contains?(mix, ~s("ci.all": [))

      for step <- [
            "verify.format",
            "verify.credo",
            "compile --warnings-as-errors",
            "verify.test",
            "verify.threadline",
            "verify.doc_contract"
          ] do
        assert String.contains?(mix, step),
               "expected ci.all to include #{inspect(step)}"
      end

      {pos_test, _} = :binary.match(mix, "\"verify.test\"")
      {pos_tl, _} = :binary.match(mix, "\"verify.threadline\"")
      {pos_dc, _} = :binary.match(mix, "\"verify.doc_contract\"")

      assert pos_test < pos_tl and pos_tl < pos_dc,
             "ci.all must list verify.test before verify.threadline before verify.doc_contract"
    end
  end

  describe "CI-03 (Plan 06-02 Task 1): README discovery (D-05)" do
    test "HexDocs badge line is immediately followed by **CI:** paragraph" do
      lines = read_rel!(["README.md"]) |> String.split("\n")

      idx =
        lines
        |> Enum.find_index(fn line -> String.starts_with?(String.trim(line), "[![HexDocs") end)

      assert is_integer(idx), "expected a HexDocs badge line in README.md"

      rest = Enum.drop(lines, idx + 1)
      assert rest != []

      first_after = rest |> hd() |> String.trim()

      assert String.starts_with?(first_after, "**CI:**"),
             "D-05: line after HexDocs badge must start with **CI:**, got: #{inspect(Enum.take(rest, 3))}"
    end

    test "README still carries CI paragraph marker and Actions hub URL" do
      readme = read_rel!(["README.md"])
      assert String.contains?(readme, "**CI:** Runs on")
      assert String.contains?(readme, "github.com/szTheory/threadline/actions")
    end
  end

  describe "CI-03 (Plan 06-02 Task 2): CONTRIBUTING discovery" do
    test "CONTRIBUTING documents job keys and Actions URL" do
      doc = read_rel!(["CONTRIBUTING.md"])

      assert String.contains?(doc, "verify-format")
      assert String.contains?(doc, "verify-credo")
      assert String.contains?(doc, "verify-test")
      assert String.contains?(doc, "https://github.com/szTheory/threadline/actions")
    end
  end

  describe "CI-02 (Plan 06-02 Task 3): maintainer verification doc literals" do
    test "06-VERIFICATION.md includes workflow, jobs, and gh audit commands" do
      # Live phase dirs may be cleared between milestones; archived v1.1 copy is canonical.
      path = [".planning", "milestones", "v1.1-phases", "06-ci-on-github", "06-VERIFICATION.md"]
      doc = read_rel!(path)

      assert String.contains?(doc, "ci.yml")
      assert String.contains?(doc, "verify-format")
      assert String.contains?(doc, "verify-credo")
      assert String.contains?(doc, "verify-test")

      assert String.contains?(
               doc,
               "gh run list --repo szTheory/threadline --workflow=ci.yml --branch=main --limit=5"
             )

      assert String.contains?(
               doc,
               "gh run view RUN_ID --repo szTheory/threadline --json conclusion,headSha,url"
             )
    end
  end
end
