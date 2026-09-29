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

  # --- Phase 205 / RELEASE-02: the release PR pin-sync job -------------------
  #
  # release-please bumps @version but cannot rewrite the documented `~> x.y.0`
  # install pins; `mix release.pins` owns them. Without this job the release PR
  # is born red. A merge that silently drops it leaves every other gate green,
  # which is exactly how v1.41 audit finding F1 hid, so the wiring is pinned here.

  test "the release PR pin-sync job exists, is scoped, and gates the CI bootstrap" do
    sync = job_block!(release_workflow(), "sync-release-pr-pins")
    bootstrap = job_block!(release_workflow(), "bootstrap-release-pr-ci")

    assert sync =~ ~r/^    needs: release-please$/m,
           "sync-release-pr-pins must need release-please. It can only rewrite pins on a " <>
             "release PR that release-please has already opened or updated (RELEASE-02)."

    assert sync =~ "run: mix release.pins\n",
           "sync-release-pr-pins must run `mix release.pins`. Without it release-please " <>
             "cannot own the install pins and the release PR is born red (RELEASE-02)."

    assert sync =~ "mix release.pins --check",
           "sync-release-pr-pins must confirm the pin writer is idempotent with " <>
             "`mix release.pins --check`, or a half-written pin set is pushed as green."

    assert sync =~ ~r/^\s+persist-credentials: false$/m,
           "sync-release-pr-pins must check out with persist-credentials: false. The job " <>
             "compiles every dependency, and a persisted token is readable by their " <>
             "compile-time code (202-REVIEW WR-01)."

    checkout_count = fn job -> length(Regex.scan(~r/uses: actions\/checkout@/, job)) end
    credential_free = fn job -> length(Regex.scan(~r/^\s+persist-credentials: false$/m, job)) end

    assert checkout_count.(sync) == credential_free.(sync),
           "every checkout in sync-release-pr-pins must set persist-credentials: false. The " <>
             "job compiles every dependency, and one credential-bearing checkout is enough " <>
             "for their compile-time code to read the token."

    mutated =
      String.replace(
        sync,
        "ref: release-please--branches--main\n          persist-credentials: false\n",
        "ref: release-please--branches--main\n"
      )

    refute mutated == sync, "the credential-free checkout control did not change the input"

    refute checkout_count.(mutated) == credential_free.(mutated),
           "dropping the flag from the release-branch checkout must make the counts diverge"

    assert sync =~ ~r/^    concurrency:\n      group: sync-release-pr-pins$/m,
           "sync-release-pr-pins must carry its own concurrency group, or two pushes to " <>
             "main race to push onto the release branch and the loser fails (202-REVIEW WR-02)."

    assert length(Regex.scan(~r/^\s+PUSH_TOKEN:/m, sync)) == 1,
           "sync-release-pr-pins must bind PUSH_TOKEN exactly once, in the push step's env, " <>
             "so the token is supplied to the push step alone (202-REVIEW WR-01)."

    assert bootstrap =~ ~r/^    needs: \[release-please, sync-release-pr-pins\]$/m,
           "bootstrap-release-pr-ci must need sync-release-pr-pins, so the dispatched CI " <>
             "run tests the release PR's final head with its pins synced (RELEASE-02)."

    assert bootstrap =~ ~r/^    if: always\(\)/m,
           "bootstrap-release-pr-ci's `if:` must start with always(). Without it a failed " <>
             "pin sync silently suppresses the CI bootstrap and the release PR gets no CI " <>
             "at all (202-REVIEW WR-03)."

    assert bootstrap_guard_errors(bootstrap) == []
  end

  # --- Phase 218 / ECON-03: one CI run per release PR head --------------------
  #
  # With RELEASE_PLEASE_TOKEN configured, release-please's own push already fires
  # the release PR's CI, so the bootstrap dispatch runs only when the PAT is
  # absent. The decision must read configuration only, never prior runs.

  test "the bootstrap guard contract is not vacuous" do
    live = job_block!(release_workflow(), "bootstrap-release-pr-ci")
    assert bootstrap_guard_errors(live) == []

    dropped = String.replace(live, "        if: env.RELEASE_PAT_CONFIGURED != 'true'\n", "")
    refute dropped == live, "the step-guard-dropped control did not change the input"

    refute bootstrap_guard_errors(dropped) == [],
           "dropping the dispatch step's `if:` must turn the bootstrap guard contract red"

    flipped =
      String.replace(live, "RELEASE_PAT_CONFIGURED != 'true'", "RELEASE_PAT_CONFIGURED == 'true'")

    refute flipped == live, "the comparison-flipped control did not change the input"

    refute bootstrap_guard_errors(flipped) == [],
           "flipping the guard comparison must turn the bootstrap guard contract red"

    raw_secret =
      String.replace(
        live,
        "${{ secrets.RELEASE_PLEASE_TOKEN != '' }}",
        "${{ secrets.RELEASE_PLEASE_TOKEN }}"
      )

    refute raw_secret == live, "the env-from-the-raw-secret control did not change the input"

    refute bootstrap_guard_errors(raw_secret) == [],
           "exporting the raw secret must turn the bootstrap guard contract red"

    run_query =
      String.replace(
        live,
        "      - name: Dispatch CI on release PR branch\n",
        "      - name: List prior CI runs\n" <>
          "        run: gh run list --workflow ci.yml --branch release-please--branches--main\n\n" <>
          "      - name: Dispatch CI on release PR branch\n"
      )

    refute run_query == live, "the run-query-added control did not change the input"

    refute bootstrap_guard_errors(run_query) == [],
           "adding a workflow-run query must turn the bootstrap guard contract red"
  end

  # Returns the failed ECON-03 bootstrap-guard properties as `{false, message}`
  # pairs; an empty list means the guard holds.
  defp bootstrap_guard_errors(block) do
    [
      {block =~ ~r/^    permissions:\n      actions: write$/m,
       "bootstrap-release-pr-ci must keep `actions: write`, or the no-PAT dispatch " <>
         "fails and the release PR gets no CI at all (ECON-03)."},
      {block =~
         ~r/^      RELEASE_PAT_CONFIGURED: \$\{\{ secrets\.RELEASE_PLEASE_TOKEN != '' \}\}$/m,
       "bootstrap-release-pr-ci must export only the boolean `RELEASE_PLEASE_TOKEN != ''` " <>
         "as RELEASE_PAT_CONFIGURED. Exporting the secret itself leaks the PAT into the " <>
         "job environment (ECON-03, T-218-01)."},
      {block =~ ~r/^        if: env\.RELEASE_PAT_CONFIGURED != 'true'$/m,
       "the dispatch step must run only when no PAT is configured. With the PAT, " <>
         "release-please's push already fires the release PR's CI and a dispatch " <>
         "doubles it; without the guard every release cycle runs CI twice (ECON-03)."},
      {not (block =~ ~r/gh run list|gh run view|actions\/runs/),
       "bootstrap-release-pr-ci must never list or query workflow runs: a run query makes " <>
         "the bootstrap decision depend on timing, which ECON-03 forbids."}
    ]
    |> Enum.reject(fn {ok, _message} -> ok end)
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
