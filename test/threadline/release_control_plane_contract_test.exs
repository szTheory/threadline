defmodule Threadline.ReleaseControlPlaneContractTest do
  use ExUnit.Case, async: true
  @root File.cwd!()

  test "the sole publish command is inside the production environment job behind hard gates" do
    paths = Path.wildcard(Path.join(@root, ".github/workflows/*.{yml,yaml}"))
    publishers = Enum.filter(paths, &(File.read!(&1) =~ "mix hex.publish"))
    assert Enum.map(publishers, &Path.basename/1) == ["release.yml"]

    source = File.read!(hd(publishers))
    [_, publish] = String.split(source, "\n  publish-hex:\n", parts: 2)
    assert publish =~ ~r/^    environment:\s*production-hex$/m
    assert publish =~ "needs:"
    assert publish =~ "gate-ci-green"
    assert publish =~ "mix hex.publish"
    refute publish =~ "continue-on-error: true"
    refute publish =~ ~r/if:.*workflow_dispatch/

    assert length(Regex.scan(~r/^\s+mix hex\.publish/m, source)) == 2
  end

  test "Hex authentication remains one contiguous replaceable step" do
    source = File.read!(Path.join(@root, ".github/workflows/release.yml"))

    assert [_, tail] =
             String.split(source, "HEX AUTHENTICATION — TRUSTED-PUBLISHING SWAP POINT", parts: 2)

    [auth | _] = String.split(tail, "END HEX AUTHENTICATION SWAP POINT", parts: 2)
    assert auth =~ "HEX_API_KEY"
    refute auth =~ "mix hex.publish"
  end

  # --- Phase 202 / D-09, D-10: the post-publish smoke gate -------------------
  #
  # These four assertions keep the `smoke-published` wiring honest. Each names
  # the consequence of the wiring it guards, because the failure modes here are
  # silent by construction: a workflow edit that drops the job, its version
  # input, or its place ahead of the attestation leaves every other gate green.

  @smoke_job "smoke-published"

  test "the published-release smoke job exists and is fed the published version" do
    smoke = job_block!(release_workflow(), @smoke_job)

    assert smoke =~ ~r/^      THREADLINE_HEX_EVALUATOR_MODE:\s*published$/m,
           "#{@smoke_job} must run the hex evaluator in published mode. Without it the job " <>
             "rehearses against the local registry and reports green for a release nobody installed."

    assert smoke =~
             ~r/^      THREADLINE_PUBLISHED_VERSION:.*release-ref\.outputs\.release_version/m,
           "#{@smoke_job} must take its version from the release-ref job's release_version " <>
             "output. A broken or absent wiring validates the wrong version, which is the " <>
             "RELEASE-03 gap this job exists to close."

    assert smoke =~ "mix verify.hex_evaluator",
           "#{@smoke_job} must invoke the named mix entrypoint, not a hand-rolled test command, " <>
             "so the unconditional dependency re-resolution that alias performs is inherited."

    assert smoke =~ ~r/^    needs:.*release-ref.*publish-hex/m,
           "#{@smoke_job} must depend on release-ref and publish-hex — it can only install a " <>
             "tarball that has already been published."
  end

  test "the attestation job waits on the published-release smoke job" do
    sync = job_block!(release_workflow(), "distribution-sync")

    assert sync =~ ~r/^    needs:.*#{@smoke_job}/m,
           "distribution-sync must list #{@smoke_job} in needs:, or the distribution " <>
             "attestation row is written about an artifact that was never installed."

    assert sync =~ ~r/needs\.#{@smoke_job}\.result == 'success'/,
           "distribution-sync carries `always()`, so membership in needs: alone does not " <>
             "block it. Its `if:` must also require #{@smoke_job} to have succeeded, or the " <>
             "attestation row is written about an artifact whose install failed."
  end

  test "the published-release smoke job exists in release.yml and nowhere else" do
    carriers =
      Path.wildcard(Path.join(@root, ".github/workflows/*.{yml,yaml}"))
      |> Enum.filter(&(File.read!(&1) =~ @smoke_job))
      |> Enum.map(&Path.basename/1)
      |> Enum.sort()

    assert carriers == ["release.yml"],
           "#{@smoke_job} must appear only in release.yml, found in #{inspect(carriers)}. " <>
             "A post-publish job inside ci.yml would be a conditionally-skipped member of " <>
             "ci-required on every pull request, and GitHub scores a skip as a pass."
  end

  test "the required check launders nothing: allowed-skips and allowed-failures stay empty" do
    ci = File.read!(Path.join(@root, ".github/workflows/ci.yml"))

    [_, block] = String.split(ci, "\n  ci-required:\n", parts: 2)

    uncommented =
      block
      |> String.split("\n")
      |> Enum.reject(&(String.trim_leading(&1) |> String.starts_with?("#")))
      |> Enum.join("\n")

    refute uncommented =~ ~r/^\s*allowed-skips:/m,
           "ci-required's alls-green step gained an allowed-skips list. That list is the " <>
             "mechanism by which a skipped job is scored as a pass; its emptiness is the " <>
             "standing tell that nothing has been laundered into the required check."

    refute uncommented =~ ~r/^\s*allowed-failures:/m,
           "ci-required's alls-green step gained an allowed-failures list. A required check " <>
             "that tolerates a failure is not a required check."

    refute uncommented =~ @smoke_job,
           "#{@smoke_job} appears inside ci-required's job block. A post-publish job can " <>
             "never be a member of the per-PR required check."
  end

  defp release_workflow, do: File.read!(Path.join(@root, ".github/workflows/release.yml"))

  # Isolates one job's YAML block: everything from its two-space key up to the
  # next two-space key at the same level (or end of file for the last job).
  defp job_block!(yaml, id) do
    case String.split(yaml, "\n  #{id}:\n", parts: 2) do
      [_, tail] ->
        tail
        |> String.split(~r/\n  [A-Za-z0-9_-]+:\n/, parts: 2)
        |> hd()

      _ ->
        flunk("could not find a \"  #{id}:\" job in .github/workflows/release.yml")
    end
  end
end
