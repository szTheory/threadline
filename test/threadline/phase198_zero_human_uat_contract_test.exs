defmodule Threadline.Phase198ZeroHumanUatContractTest do
  use ExUnit.Case, async: true

  @root File.cwd!()
  @summaries Path.join(
               @root,
               ".planning/phases/198-green-bringup/198-*-SUMMARY.md"
             )

  test "every Phase 198 coverage entry is classified as automated and passing" do
    summaries = @summaries |> Path.wildcard() |> Enum.sort()
    assert summaries != [], "no Phase 198 summaries were discovered"

    {command, prefix} = classifier_command!()

    results =
      Enum.map(summaries, fn summary ->
        args = prefix ++ ["uat", "classify-coverage", "--summary", summary, "--raw"]
        {output, status} = System.cmd(command, args, stderr_to_stdout: true)

        assert status == 0,
               "canonical coverage classifier failed for #{summary}:\n#{output}"

        {summary, Jason.decode!(output)}
      end)

    total = Enum.sum(for {_file, result} <- results, do: result["total"])
    assert total > 0, "Phase 198 coverage discovery was vacuous"

    failures =
      Enum.flat_map(results, fn {file, result} ->
        mode_errors =
          if result["mode"] == "coverage",
            do: [],
            else: ["#{file}: legacy/non-coverage mode #{inspect(result["mode"])}"]

        validation_errors =
          for error <- result["errors"] || [] do
            "#{file}: #{error["id"] || "unknown"} #{error["code"]}: #{error["message"]}"
          end

        present_errors =
          for entry <- result["present"] || [] do
            "#{file}: #{entry["id"] || "unknown"} remains present (#{entry["reason"]})"
          end

        count_errors =
          if length(result["auto_passed"] || []) == result["total"],
            do: [],
            else: ["#{file}: not every coverage entry auto-passed"]

        mode_errors ++ validation_errors ++ present_errors ++ count_errors
      end)

    assert failures == [], "zero-human UAT contract failed:\n" <> Enum.join(failures, "\n")
  end

  defp classifier_command! do
    case System.find_executable("gsd-tools") do
      nil ->
        runtime =
          Path.join([
            System.user_home!(),
            ".codex",
            "gsd-core",
            "bin",
            "gsd-tools.cjs"
          ])

        unless File.regular?(runtime) do
          raise "canonical gsd-tools classifier not found on PATH or at #{runtime}"
        end

        {System.find_executable("node") || raise("node executable not found"), [runtime]}

      executable ->
        {executable, []}
    end
  end
end
