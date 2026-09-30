defmodule Threadline.ReleaseControlPlaneContractTest do
  use ExUnit.Case, async: true
  @root File.cwd!()

  # --- 216 CR-01: release.yml checkout credentials ----------------------------
  #
  # Default-deny (D-07): every `actions/checkout` step in release.yml must set
  # `persist-credentials: false`, unless its job is one of the two reasoned
  # exceptions below, each of which pushes with the persisted credential and
  # runs no mix. The check runs per checkout STEP, not per job (D-08) — the
  # sparse pin checkouts already set the flag, so a per-job count passes
  # vacuously for a job whose OTHER (target-ref) checkout omits it, and that is
  # how CR-01 escaped review.
  @persisted_checkout_jobs %{
    "dispatch-bootstrap" =>
      "a bare `git push origin \"$tag\"` uses the persisted credential; the job runs no mix",
    "distribution-sync" =>
      "a bare `git push -u origin \"$BRANCH\"` uses the persisted credential; the job runs no mix"
  }

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

    # The per-job checkout-vs-flag count that used to live here was replaced by
    # the per-STEP checkout-credential-free rule (D-08, D-10) and its D-11 case
    # 3 mutation control, both below — a per-job count passes vacuously when a
    # DIFFERENT checkout in the same job already sets the flag.

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

  test "every release.yml checkout is credential-free unless its job is allowlisted (216 CR-01)" do
    yaml = release_workflow()
    assert persisted_checkout_errors(yaml) == []

    checked_count =
      yaml
      |> release_job_ids()
      |> Enum.reject(&Map.has_key?(@persisted_checkout_jobs, &1))
      |> Enum.flat_map(fn job_id ->
        yaml |> job_block!(job_id) |> job_steps() |> Enum.filter(&checkout_step?/1)
      end)
      |> length()

    assert checked_count >= 7,
           "expected at least 7 non-allowlisted checkout steps (today's 9 minus the 2 " <>
             "allowlisted jobs), found #{checked_count} — the parser may have stopped seeing steps"
  end

  test "mix_invocation?/1 matches mix at a shell command position, not inside prose" do
    for positive <- [
          "mix deps.get",
          "run: mix hex.build",
          "if mix hex.info x",
          "a && mix b",
          "x=$(mix y)",
          "FOO=1 mix compile",
          "timeout 300 mix hex.publish",
          "sudo mix compile",
          "nohup mix test &",
          "nice mix test",
          "xargs -I{} mix build",
          "x) mix compile ;;"
        ] do
      assert mix_invocation?(positive), "expected #{inspect(positive)} to fire"
    end

    for negative <- [
          "Merge after CI (\\`mix verify.test\\`) is green on this PR.",
          "mixed"
        ] do
      refute mix_invocation?(negative), "expected #{inspect(negative)} not to fire"
    end
  end

  describe "mutation controls (D-11)" do
    setup do
      %{live: release_workflow()}
    end

    for {label, from, to, rule} <- [
          {"strip the flag from the publish-hex target checkout",
           "ref: ${{ needs.release-ref.outputs.checkout_ref }}\n" <>
             "          persist-credentials: false\n\n      - name: Install dependencies\n",
           "ref: ${{ needs.release-ref.outputs.checkout_ref }}\n\n      - name: Install dependencies\n",
           "checkout-credential-free"},
          {"strip the flag from the smoke-published target checkout",
           "ref: ${{ needs.release-ref.outputs.checkout_ref }}\n" <>
             "          persist-credentials: false\n\n      - name: Ensure hex_evaluator_test database exists\n",
           "ref: ${{ needs.release-ref.outputs.checkout_ref }}\n\n      - name: Ensure hex_evaluator_test database exists\n",
           "checkout-credential-free"},
          {"strip the flag from the sync-release-pr-pins ref: checkout",
           "ref: release-please--branches--main\n          persist-credentials: false\n",
           "ref: release-please--branches--main\n", "checkout-credential-free"},
          {"add a mix invocation to distribution-sync",
           "          token: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}\n\n" <>
             "      - name: Wait for Hex registry before doc sync\n",
           "          token: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}\n\n" <>
             "      - run: mix deps.get\n\n      - name: Wait for Hex registry before doc sync\n",
           "allowlisted-job-runs-no-mix"},
          {"rename an allowlisted job", "\n  distribution-sync:\n",
           "\n  distribution-sync-renamed:\n", "stale-allowlist-entry"}
        ] do
      test "#{label} fires rule=#{rule}", %{live: live} do
        from = unquote(from)
        to = unquote(to)

        assert length(String.split(live, from)) == 2,
               "control anchor not found or not unique"

        mutated = String.replace(live, from, to, global: false)
        refute mutated == live, "the control did not change the input"

        assert rule_fired?(persisted_checkout_errors(mutated), unquote(rule))
      end
    end

    test "positive control: the allowlist genuinely does the exempting (renaming the job un-exempts its bare checkout)",
         %{live: live} do
      # dispatch-bootstrap's checkout has no persist-credentials flag and is
      # exempt only because "dispatch-bootstrap" is a @persisted_checkout_jobs
      # key. Renaming just the job header (its checkout step is untouched)
      # removes it from the allowlist map while leaving the bare checkout in
      # place, so checkout-credential-free must now fire on that same step —
      # proving the exclusion is keyed on job id, not vacuously always green.
      from = "\n  dispatch-bootstrap:\n"
      to = "\n  dispatch-bootstrap-control:\n"

      assert length(String.split(live, from)) == 2, "control anchor not found or not unique"

      mutated = String.replace(live, from, to, global: false)
      refute mutated == live, "the control did not change the input"

      assert rule_fired?(checkout_credential_errors(mutated), "checkout-credential-free")
    end
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

  # Job ids are the two-space keys after the top-level `jobs:` line. `on:` also
  # has two-space keys (`push:`, `workflow_dispatch:`), so job ids are scanned
  # only from the text after `\njobs:\n`.
  defp release_job_ids(yaml) do
    case String.split(yaml, "\njobs:\n", parts: 2) do
      [_, body] ->
        ~r/^  ([A-Za-z0-9_-]+):[ \t]*$/m
        |> Regex.scan(body)
        |> Enum.map(fn [_, id] -> id end)

      _ ->
        []
    end
  end

  # A checkout step is any step whose `uses:` names actions/checkout, list-item
  # dash included. `yaml_value(step, "uses")` (below) does not match this form:
  # its `^\s*` anchor stops at the leading `- `.
  defp checkout_step?(step) do
    Regex.match?(~r/^\s*(?:- )?uses:[ \t]*actions\/checkout@/m, step)
  end

  # Copied verbatim from test/threadline/ci_workflow_parity_contract_test.exs
  # (job_steps/1, ~:3153): step texts of a job block, split at every
  # 6-space-indented list item. The leading chunk (job header up to the first
  # step) is dropped.
  defp job_steps(block) do
    case Regex.split(~r/^(?=      - )/m, block) do
      [_header | steps] -> steps
      [] -> []
    end
  end

  # Copied verbatim from test/threadline/ci_workflow_parity_contract_test.exs
  # (yaml_value/2, ~:3691).
  defp yaml_value(step, key) do
    case Regex.run(~r/^\s*#{Regex.escape(key)}:[ \t]*(.*?)[ \t]*$/m, step) do
      [_, value] -> value
      nil -> nil
    end
  end

  # Per-step (D-08), not per-job: every actions/checkout step outside
  # @persisted_checkout_jobs must set persist-credentials: false. Returns
  # `{ok?, message}` pairs, rejecting the ok ones, in the style of
  # bootstrap_guard_errors/1 above.
  defp checkout_credential_errors(yaml) do
    present_ids = release_job_ids(yaml)

    for job_id <- present_ids,
        not Map.has_key?(@persisted_checkout_jobs, job_id),
        {step, n} <-
          yaml
          |> job_block!(job_id)
          |> job_steps()
          |> Enum.filter(&checkout_step?/1)
          |> Enum.with_index(1) do
      {yaml_value(step, "persist-credentials") == "false",
       "rule=checkout-credential-free job=#{job_id} checkout=#{n}: every actions/checkout " <>
         "outside @persisted_checkout_jobs must set persist-credentials: false (216 CR-01)"}
    end
    |> Enum.reject(fn {ok, _message} -> ok end)
  end

  # True when any error's message names the given rule.
  defp rule_fired?(errors, rule) do
    Enum.any?(errors, fn {_ok, message} -> String.contains?(message, "rule=#{rule}") end)
  end

  # No allowlisted job (one that keeps a persisted token) may invoke mix: a job
  # that keeps a persisted token compiles no dependency code today, and this
  # rule keeps it that way (D-09). A plain "contains `mix `" substring test
  # would misfire on distribution-sync's own PR body, which mentions
  # `mix verify.test` as prose inside an escaped-backtick string — it runs
  # nothing. mix_invocation?/1 below is narrower: it requires `mix` to sit at a
  # shell command position, not merely appear in the text.
  defp allowlisted_job_run_errors(yaml) do
    present_ids = release_job_ids(yaml)

    for {job_id, _reason} <- @persisted_checkout_jobs,
        job_id in present_ids,
        step <- yaml |> job_block!(job_id) |> job_steps(),
        script = run_scripts(step),
        script not in [nil, ""] do
      {not mix_invocation?(script),
       "rule=allowlisted-job-runs-no-mix job=#{job_id}: a job that keeps a persisted token " <>
         "must never run mix, or compile-time dependency code can read it (D-07)"}
    end
    |> Enum.reject(fn {ok, _message} -> ok end)
  end

  # Every @persisted_checkout_jobs key must name a job that still exists in
  # release.yml, or the allowlist silently widens to cover nothing (D-09).
  defp stale_allowlist_errors(yaml) do
    present_ids = release_job_ids(yaml)

    for {job_id, _reason} <- @persisted_checkout_jobs, job_id not in present_ids do
      {false,
       "rule=stale-allowlist-entry job=#{job_id}: @persisted_checkout_jobs names no such " <>
         "release.yml job"}
    end
  end

  # All three 216 CR-01 rules combined: checkout-credential-free,
  # allowlisted-job-runs-no-mix and stale-allowlist-entry. Each rule already
  # rejects its own ok entries, so concatenating them is equivalent to
  # filtering the union.
  defp persisted_checkout_errors(yaml) do
    checkout_credential_errors(yaml) ++
      allowlisted_job_run_errors(yaml) ++ stale_allowlist_errors(yaml)
  end

  # The single-line value of a step's `run:` key, or, for a block scalar
  # (`run: |` / `run: >`, chomping indicators included), every following line
  # indented deeper than the `run:` key itself. Returns nil when the step has
  # no `run:` key.
  defp run_scripts(step) do
    lines = String.split(step, "\n")

    lines
    |> Enum.with_index()
    |> Enum.find(fn {line, _index} -> Regex.match?(~r/^\s*(?:- )?run:/, line) end)
    |> case do
      nil ->
        nil

      {line, index} ->
        [key_prefix] = Regex.run(~r/^\s*(?:- )?run:/, line)
        indent = String.length(key_prefix) - String.length("run:")
        value = line |> String.replace(~r/^\s*(?:- )?run:[ \t]*/, "") |> String.trim_trailing()

        if value == "" or Regex.match?(~r/^[|>][-+0-9]*$/, value) do
          block_scalar_lines(lines, index, indent)
        else
          value
        end
    end
  end

  defp block_scalar_lines(lines, run_line_index, indent) do
    lines
    |> Enum.slice((run_line_index + 1)..-1//1)
    |> Enum.take_while(&block_scalar_member?(&1, indent))
    |> Enum.join("\n")
  end

  defp block_scalar_member?(line, indent) do
    String.trim(line) == "" or
      String.length(line) - String.length(String.trim_leading(line)) > indent
  end

  # Matches `mix` at a shell command position — never merely as a substring —
  # so that prose such as an escaped-backtick `` \`mix verify.test\` `` inside
  # a PR body, or the word `mixed`, does not misfire (D-09). Checked per line:
  # `mix` must be followed by whitespace or end of line, and the text
  # immediately before it (trimmed of trailing whitespace) must be one of:
  # empty (line start), a command separator (`;`, `&&`, `||`, `|`, `)` for a
  # `case` branch), a subshell/YAML-key opener (`$(`, `:`), an unescaped
  # backtick, a shell keyword or command wrapper (if/then/elif/else/do/while/
  # until/!/exec/time/env/sudo/nohup/nice), a `timeout <N>` prefix, an `xargs`
  # prefix, or one or more `NAME=value` assignment prefixes. (WR-02: broadened
  # from the original keyword-only list, which missed these common wrapper
  # idioms and would silently defeat the D-09 check.)
  defp mix_invocation?(nil), do: false

  defp mix_invocation?(script) do
    script
    |> String.split(~r/\r?\n/)
    |> Enum.any?(&line_has_mix_invocation?/1)
  end

  defp line_has_mix_invocation?(line) do
    ~r/mix(?=\s|$)/
    |> Regex.scan(line, return: :index)
    |> Enum.any?(fn [{start, _len}] ->
      prefix = String.slice(line, 0, start)
      mix_command_position?(prefix)
    end)
  end

  defp mix_command_position?(prefix) do
    trimmed = String.trim_trailing(prefix)

    cond do
      trimmed == "" ->
        true

      String.ends_with?(trimmed, [";", "&&", "||", "|", "$(", ":", ")"]) ->
        true

      unescaped_backtick?(prefix) ->
        true

      Regex.match?(
        ~r/(?:^|\s)(if|then|elif|else|do|while|until|!|exec|time|env|sudo|nohup|nice)$/,
        trimmed
      ) ->
        true

      Regex.match?(~r/(?:^|\s)timeout\s+\S+$/, trimmed) ->
        true

      Regex.match?(~r/(?:^|\s)xargs\b.*$/, trimmed) ->
        true

      Regex.match?(~r/^(?:[A-Za-z_][A-Za-z0-9_]*=\S*\s+)+$/, prefix) ->
        true

      true ->
        false
    end
  end

  defp unescaped_backtick?(prefix) do
    String.ends_with?(prefix, "`") and not String.ends_with?(prefix, "\\`")
  end
end
