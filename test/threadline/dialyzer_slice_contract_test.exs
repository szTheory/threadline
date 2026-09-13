defmodule Threadline.DialyzerSliceContractTest do
  use ExUnit.Case, async: false

  @script Path.expand("../../bin/verify-dialyzer-slice", __DIR__)
  @fixture Path.expand("../fixtures/dialyzer/critic-tooling.json", __DIR__)
  @raw_command "MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status"

  @tag :live_dialyzer
  test "committed critic-tooling slice has no live warnings" do
    {output, status} = System.cmd(@script, ["--fixture", @fixture], stderr_to_stdout: true)

    assert status == 0, output
    assert output =~ "verified slice critic-tooling: 3/40 sealed warnings"
    assert output =~ "0 live warnings"
  end

  test "synthetic raw output verifies a bounded fixed slice" do
    raw =
      ~S|{:warn_unknown, {~c"lib/threadline/query.ex", {53, 34}}, {:unknown_type, {Threadline.Capture.AuditChange, :t, 0}}}|
      |> Kernel.<>("\n")

    assert {output, 0} = run_fixture(with_post_hash(committed_fixture(), raw), raw)
    assert output =~ "3/40 sealed warnings"
    assert output =~ "3 authorized origins"
    assert output =~ "0 live warnings"
  end

  test "duplicate warning IDs are rejected" do
    fixture = committed_fixture()
    warning = warning!(fixture, "W05")

    assert {output, 1} = run_fixture(%{fixture | "warnings" => [warning, warning]}, "")
    assert output =~ "warning IDs must be unique"
  end

  test "a warning origin outside authorized_origins is rejected" do
    fixture = committed_fixture()

    warning =
      fixture
      |> warning!("W05")
      |> put_in(["origin", "path"], "lib/threadline/query.ex")

    assert {output, 1} = run_fixture(%{fixture | "warnings" => [warning]}, "")
    assert output =~ "origin is outside authorized_origins"
  end

  test "a surviving fixed warning is rejected" do
    fixture = committed_fixture()
    warning = warning!(fixture, "W05")
    raw = warning["raw_line"] <> "\n"

    assert {output, 1} = run_fixture(with_post_hash(fixture, raw), raw)
    assert output =~ "fixed warning W05 still survives"
  end

  test "an unrecorded live warning in an authorized origin is rejected" do
    fixture = committed_fixture()

    raw =
      ~S|{:warn_matching, {~c"lib/threadline/critic_trust/measure.ex", {101, 7}}, {:pattern_match, [~c"pattern _", ~c"term()"]}}|
      |> Kernel.<>("\n")

    assert {output, 1} = run_fixture(with_post_hash(fixture, raw), raw)
    assert output =~ "unrecorded live warning"
  end

  test "irreducible residue requires an exact tuple, rationale, and removal trigger" do
    fixture = committed_fixture()
    warning = warning!(fixture, "W05")

    complete =
      warning
      |> Map.put("disposition", "irreducible")
      |> Map.put("ignore_tuple", %{
        "file" => warning["origin"]["path"],
        "warning_description" => warning["raw_line"]
      })
      |> Map.put("rationale", "Upstream types cannot express the generator state return.")
      |> Map.put("removal_trigger", "Remove after the upstream type contract exposes the return.")

    for {key, expected} <- [
          {"ignore_tuple", "exact ignore_tuple"},
          {"rationale", "rationale must be a non-empty string"},
          {"removal_trigger", "removal_trigger must be a non-empty string"}
        ] do
      malformed = Map.delete(complete, key)
      mutated = %{fixture | "warnings" => [malformed]}

      assert {output, 1} = run_fixture(mutated, warning["raw_line"] <> "\n")
      assert output =~ expected
    end
  end

  test "fixture raw evidence must match its declared class and origin" do
    fixture = committed_fixture()

    warning =
      fixture
      |> warning!("W05")
      |> Map.put("class", "warn_matching")

    assert {output, 1} = run_fixture(%{fixture | "warnings" => [warning]}, "")
    assert output =~ "raw_line does not match"
  end

  test "the verifier has no planning-tree dependency" do
    source = File.read!(@script)
    assert committed_fixture()["post_analysis"]["command"] == @raw_command
    refute source =~ ".planning"
    refute source =~ ":json.decode"
    assert source =~ "apply(Jason, :decode"
    assert source =~ "mix"
    assert source =~ "dialyzer"
    assert source =~ "--format"
    assert source =~ "raw"
  end

  test "invalid JSON is rejected through the supported project decoder" do
    root = Path.dirname(Mix.Project.project_file())

    temp_root =
      Path.join([
        root,
        "_build",
        "dialyzer-slice-contract",
        Integer.to_string(System.unique_integer([:positive]))
      ])

    File.mkdir_p!(temp_root)
    fixture_path = Path.join(temp_root, "invalid.json")
    raw_path = Path.join(temp_root, "dialyzer.raw")
    File.write!(fixture_path, ~S|{"schema_version": 1, }|)
    File.write!(raw_path, "")
    on_exit(fn -> File.rm_rf!(temp_root) end)

    assert {output, 1} =
             System.cmd(
               @script,
               ["--fixture", fixture_path, "--raw-output", raw_path],
               stderr_to_stdout: true
             )

    assert output =~ "fixture is not valid JSON"
  end

  defp committed_fixture do
    @fixture
    |> File.read!()
    |> Jason.decode!()
  end

  defp warning!(fixture, id), do: Enum.find(fixture["warnings"], &(&1["id"] == id))

  defp run_fixture(fixture, raw) do
    root = Path.dirname(Mix.Project.project_file())

    temp_root =
      Path.join([
        root,
        "_build",
        "dialyzer-slice-contract",
        Integer.to_string(System.unique_integer([:positive]))
      ])

    File.mkdir_p!(temp_root)
    fixture_path = Path.join(temp_root, "slice.json")
    raw_path = Path.join(temp_root, "dialyzer.raw")
    File.write!(fixture_path, Jason.encode!(fixture))
    File.write!(raw_path, raw)
    on_exit(fn -> File.rm_rf!(temp_root) end)

    System.cmd(
      @script,
      ["--fixture", fixture_path, "--raw-output", raw_path],
      stderr_to_stdout: true
    )
  end

  defp with_post_hash(fixture, raw) do
    warning_lines =
      raw
      |> String.split("\n", trim: true)
      |> Enum.filter(&String.starts_with?(&1, "{:warn_"))
      |> Enum.sort()

    authorized = fixture["authorized_origins"]

    bounded_lines =
      Enum.filter(warning_lines, fn line ->
        Enum.any?(authorized, fn origin -> String.contains?(line, "~c\"" <> origin <> "\"") end)
      end)

    bounded = if bounded_lines == [], do: "", else: Enum.join(bounded_lines, "\n") <> "\n"
    hash = :crypto.hash(:sha256, bounded) |> Base.encode16(case: :lower)
    put_in(fixture, ["post_analysis", "authorized_output_sha256"], hash)
  end
end
