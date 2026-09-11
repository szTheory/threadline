defmodule Threadline.CiAttestationContractTest do
  @moduledoc false

  use ExUnit.Case, async: true

  describe "the recorder itself" do
    test "bin/record-ci-attestation is present and executable" do
      script = Path.expand("../../bin/record-ci-attestation", __DIR__)

      assert File.exists?(script),
             "bin/record-ci-attestation is missing — attestations cannot be produced without it"

      %{mode: mode} = File.stat!(script)

      assert Bitwise.band(mode, 0o111) != 0,
             "bin/record-ci-attestation is not executable (mode #{Integer.to_string(mode, 8)})"
    end

    test "it refuses to attest a run that has not completed" do
      script = File.read!(Path.expand("../../bin/record-ci-attestation", __DIR__))

      assert String.contains?(script, ~s|[ "$STATUS" = "completed" ]|),
             """
             bin/record-ci-attestation must refuse to snapshot an in-flight run.

             Attesting a run mid-flight would freeze a partial job list as though it were the
             final result — a green-so-far run recorded as green.
             """
    end

    test "a render failure preserves an existing attestation and a valid render replaces it" do
      script = Path.expand("../../bin/record-ci-attestation", __DIR__)
      root = Path.join(System.tmp_dir!(), "ci_attestation_#{System.unique_integer([:positive])}")
      fake_bin = Path.join(root, "bin")
      out_dir = Path.join(root, "out")
      File.mkdir_p!(fake_bin)
      File.mkdir_p!(out_dir)

      fake_gh = Path.join(fake_bin, "gh")
      out_file = Path.join(out_dir, "ci-attestation-123.json")
      File.write!(out_file, "previous evidence\n")

      File.write!(
        fake_gh,
        "#!/usr/bin/env bash\nprintf '%s' '{\"databaseId\":123,\"status\":\"completed\",\"conclusion\":\"success\",\"jobs\":null}'\n"
      )

      File.chmod!(fake_gh, 0o755)

      env = [{"PATH", fake_bin <> ":" <> System.fetch_env!("PATH")}]

      {_output, status} =
        System.cmd("bash", [script, "123", "--out-dir", out_dir],
          env: env,
          stderr_to_stdout: true
        )

      assert status != 0
      assert File.read!(out_file) == "previous evidence\n"

      File.write!(
        fake_gh,
        "#!/usr/bin/env bash\nprintf '%s' '{\"databaseId\":123,\"displayTitle\":\"CI\",\"workflowName\":\"CI\",\"headSha\":\"abc\",\"headBranch\":\"main\",\"event\":\"push\",\"status\":\"completed\",\"conclusion\":\"success\",\"createdAt\":\"2026-01-01T00:00:00Z\",\"updatedAt\":\"2026-01-01T00:01:00Z\",\"url\":\"https://example.test/run/123\",\"attempt\":1,\"jobs\":[]}'\n"
      )

      File.chmod!(fake_gh, 0o755)

      {_output, status} =
        System.cmd("bash", [script, "123", "--out-dir", out_dir],
          env: env,
          stderr_to_stdout: true
        )

      assert status == 0
      assert Jason.decode!(File.read!(out_file))["run"]["id"] == 123
      assert Path.wildcard(Path.join(out_dir, ".ci-attestation-123.*")) == []

      File.rm_rf!(root)
    end
  end
end
