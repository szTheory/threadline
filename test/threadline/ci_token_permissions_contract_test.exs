defmodule Threadline.CITokenPermissionsContractTest do
  @moduledoc """
  Least-privilege `GITHUB_TOKEN` contract across every Actions workflow.

  `main`'s required check `CI required` is pinned to the GitHub Actions app
  (`.github/rulesets/main.json`). Any workflow's `GITHUB_TOKEN` is that app, so
  a token that can write `statuses` or `checks` could post a `CI required`
  status or check run without ci.yml's gate ever running. This contract keeps
  every workflow's token too narrow to do that, and keeps every other write
  grant on the one job that calls the write API.

  ## Representation

  A job's *effective grants* are its own `permissions:` block when it has one
  (a job block replaces the workflow block wholesale, it does not merge), or
  the workflow-level block otherwise. They are normalised to a map of
  case-folded scope to case-folded level, with `none` entries dropped, so an
  absent scope and `scope: none` are the same thing. The string forms become a
  wildcard scope: `read-all` is `%{"*" => "read"}` and `write-all` is
  `%{"*" => "write"}`, which no allowlist entry can ever match.

  The allowlists share one shape, `%{workflow => %{job => %{scope => reason}}}`:

    * `@job_write_grants` lists the scopes each job holds at `write`;
    * `@job_read_grants` lists the scopes each of those same jobs holds at
      `read`.

  For a job named in either allowlist, the effective grants must equal the
  full map built from both entries, read scopes included: an extra scope, a
  missing scope, or a scope at the other level all fail. For every other job
  the effective grants may hold no `write` scope at all. An allowlist entry for
  a workflow or job that no longer exists fails as stale, so the lists cannot
  outlive the code they describe.

  ## Not covered here

  That exactly one job in any workflow may be *named* `CI required` (and that
  no job name is an expression that could evaluate to it) is Phase 221's
  `rule=gate-name-unique` / `rule=gate-name-expression` in
  `test/threadline/ci_workflow_parity_contract_test.exs`. It is deliberately
  not duplicated here.
  """

  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  @job_write_grants %{
    ".github/workflows/release.yml" => %{
      "release-please" => %{
        "contents" => "pushes the release branch and tag",
        "pull-requests" => "opens and updates the release PR",
        "issues" => "labels the release PR"
      },
      "dispatch-bootstrap" => %{"contents" => "pushes a missing release tag"},
      "sync-release-pr-pins" => %{"contents" => "pushes the pin commit to the release branch"},
      "bootstrap-release-pr-ci" => %{"actions" => "dispatches ci.yml on the release PR branch"},
      "distribution-sync" => %{
        "contents" => "pushes the distribution sync branch",
        "pull-requests" => "opens the distribution sync PR"
      }
    },
    ".github/workflows/browser-full.yml" => %{
      "verify-example-browser-full" => %{"issues" => "upserts the browser failure issue"}
    },
    ".github/workflows/flake-detection.yml" => %{
      "verify-flake" => %{"issues" => "upserts the flake issue"}
    },
    ".github/workflows/deps-health.yml" => %{
      "deps-health" => %{"issues" => "upserts the ci-deps issue"}
    }
  }

  @job_read_grants %{
    ".github/workflows/release.yml" => %{
      "bootstrap-release-pr-ci" => %{"contents" => "restated alongside the actions write"}
    },
    ".github/workflows/browser-full.yml" => %{
      "verify-example-browser-full" => %{
        "actions" => "reads the run's own jobs",
        "contents" => "checks out the repository"
      }
    },
    ".github/workflows/flake-detection.yml" => %{
      "verify-flake" => %{
        "actions" => "reads the run's own jobs",
        "contents" => "checks out the repository"
      }
    },
    ".github/workflows/deps-health.yml" => %{
      "deps-health" => %{"contents" => "checks out the repository"}
    }
  }

  # `statuses: write` or `checks: write` is how a workflow could post the
  # required `CI required` context without ci.yml's gate. Empty by design.
  @status_scope_grants %{}

  # A job-level `uses:` (reusable workflow call) or `secrets: inherit` hands
  # the token or every secret to code this contract cannot see. Empty by design.
  @reusable_call_grants %{}

  @status_scopes ~w(statuses checks)

  defp read_rel!(path), do: @repo_root |> Path.join(path) |> File.read!()

  defp workflow_texts do
    paths =
      @repo_root
      |> Path.join(".github/workflows/*.{yml,yaml}")
      |> Path.wildcard()
      |> Enum.sort()

    refute paths == [],
           "found no workflow files to scan — a broken glob would launder a false pass here"

    Map.new(paths, fn path -> {Path.relative_to(path, @repo_root), File.read!(path)} end)
  end

  # --- YAML helpers (private copies of ci_workflow_parity_contract_test's) ---

  defp parse_yaml(text) do
    {:ok, YamlElixir.read_from_string!(text, merge_anchors: true)}
  rescue
    error -> {:error, Exception.message(error)}
  catch
    kind, reason -> {:error, inspect({kind, reason})}
  end

  defp yaml_key_string(key) when is_binary(key), do: key
  defp yaml_key_string(key) when is_atom(key) or is_number(key), do: to_string(key)
  defp yaml_key_string(key), do: inspect(key)

  # Case-folded and trimmed: GitHub keys are case-sensitive, so this only
  # over-reports.
  defp yaml_key(key), do: key |> yaml_key_string() |> String.trim() |> String.downcase()

  defp yaml_field(%{} = map, key) do
    Enum.find_value(map, fn {k, v} -> if yaml_key(k) == key, do: {:ok, v} end) || :error
  end

  defp yaml_field(_data, _key), do: :error

  defp yaml_get(data, key) do
    case yaml_field(data, key) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  defp parsed_jobs(doc) do
    case yaml_get(doc, "jobs") do
      %{} = jobs -> jobs |> Enum.map(fn {k, v} -> {yaml_key_string(k), v} end) |> Enum.sort()
      _ -> []
    end
  end

  # --- Grant normalisation ---------------------------------------------------

  defp level(value), do: value |> yaml_key_string() |> String.trim() |> String.downcase()

  defp grants(%{} = block) do
    for {scope, value} <- block, level(value) != "none", into: %{} do
      {yaml_key(scope), level(value)}
    end
  end

  defp grants(value) when is_binary(value) do
    case level(value) do
      "read-all" -> %{"*" => "read"}
      "write-all" -> %{"*" => "write"}
      other -> %{"*" => other}
    end
  end

  defp grants(_value), do: %{}

  defp effective_block(doc, job) do
    case yaml_field(job, "permissions") do
      {:ok, block} -> block
      :error -> yaml_get(doc, "permissions")
    end
  end

  defp writes(grants), do: for({scope, "write"} <- grants, into: MapSet.new(), do: scope)

  defp expected_grants(path, job_id) do
    w =
      for {scope, _} <- allow_entry(@job_write_grants, path, job_id),
          into: %{},
          do: {scope, "write"}

    r =
      for {scope, _} <- allow_entry(@job_read_grants, path, job_id),
          into: %{},
          do: {scope, "read"}

    Map.merge(r, w)
  end

  defp allow_entry(allowlist, path, job_id),
    do: allowlist |> Map.get(path, %{}) |> Map.get(job_id, %{})

  defp allowlisted?(path, job_id),
    do:
      allow_entry(@job_write_grants, path, job_id) != %{} or
        allow_entry(@job_read_grants, path, job_id) != %{}

  # --- The contract ------------------------------------------------------------

  defp token_errors(texts) do
    parsed = for {path, text} <- Enum.sort(texts), do: {path, text, parse_yaml(text)}

    parse_errors =
      for {path, _text, {:error, message}} <- parsed do
        "#{path} rule=yaml-parse: the workflow does not parse, so its token permissions " <>
          "cannot be checked (#{message})"
      end

    docs = for {path, text, {:ok, doc}} <- parsed, do: {path, text, doc}

    parse_errors ++
      Enum.flat_map(docs, &workflow_errors/1) ++ stale_errors(docs, parse_errors)
  end

  defp workflow_errors({path, text, doc}) do
    top_level_errors(path, doc) ++
      Enum.flat_map(parsed_jobs(doc), &job_errors(path, doc, &1)) ++
      pull_request_target_errors(path, text)
  end

  defp top_level_errors(path, doc) do
    case yaml_field(doc, "permissions") do
      {:ok, %{} = block} ->
        read_only_errors(path, block) ++ status_errors(path, "(workflow)", grants(block))

      {:ok, value} ->
        declared_error(path, "is #{inspect(value)}") ++
          write_all_errors(path, "(workflow)", value)

      :error ->
        declared_error(path, "is missing")
    end
  end

  defp read_only_errors(path, block) do
    for {scope, value} <- block, level(value) not in ["read", "none"] do
      "#{path} rule=workflow-level-read-only: top-level `#{yaml_key_string(scope)}: " <>
        "#{level(value)}` — the workflow block must be read or none; move writes to the job"
    end
  end

  defp declared_error(path, what) do
    [
      "#{path} rule=permissions-declared: the top-level `permissions` #{what}; it must be " <>
        "a map (`{}` is fine), never absent, `read-all` or `write-all`"
    ]
  end

  defp write_all_errors(path, where, value) do
    if is_binary(value) and level(value) == "write-all",
      do: ["#{path} #{where} rule=write-all-banned: `permissions: write-all` is banned"],
      else: []
  end

  defp status_errors(path, job_id, grants) do
    allowed = allow_entry(@status_scope_grants, path, job_id)

    for {scope, "write"} <- grants,
        scope in @status_scopes or scope == "*",
        not Map.has_key?(allowed, scope) do
      "#{path} job=#{job_id} rule=status-scopes-banned: `#{scope}: write` could post the " <>
        "required `CI required` status or check"
    end
  end

  defp job_errors(path, doc, {job_id, job}) do
    own = yaml_get(job, "permissions")
    effective = grants(effective_block(doc, job))
    where = "job=#{job_id}"

    write_all_errors(path, where, own) ++
      status_errors(path, job_id, grants(own)) ++
      allowlist_errors(path, job_id, effective) ++
      restate_errors(path, job_id, own) ++ reusable_errors(path, job_id, job)
  end

  defp allowlist_errors(path, job_id, effective) do
    expected = expected_grants(path, job_id)

    cond do
      allowlisted?(path, job_id) and effective != expected ->
        [
          "#{path} job=#{job_id} rule=job-write-allowlisted: effective grants " <>
            "#{inspect(effective)} must equal the allowlisted #{inspect(expected)}"
        ]

      not allowlisted?(path, job_id) and MapSet.size(writes(effective)) > 0 ->
        [
          "#{path} job=#{job_id} rule=job-write-allowlisted: write grants " <>
            "#{inspect(MapSet.to_list(writes(effective)))} are not in @job_write_grants"
        ]

      true ->
        []
    end
  end

  defp restate_errors(path, job_id, %{} = own) do
    if MapSet.size(writes(grants(own))) > 0 and yaml_field(own, "contents") == :error,
      do: [
        "#{path} job=#{job_id} rule=job-block-restates-contents: a job block that grants a " <>
          "write replaces the workflow block, so it must state `contents` explicitly"
      ],
      else: []
  end

  defp restate_errors(_path, _job_id, _own), do: []

  defp reusable_errors(path, job_id, job) do
    allowed = Map.has_key?(Map.get(@reusable_call_grants, path, %{}), job_id)
    secrets = yaml_get(job, "secrets")

    uses =
      if yaml_field(job, "uses") != :error and not allowed,
        do: ["#{path} job=#{job_id} rule=reusable-call-allowlisted: job-level `uses:` call"],
        else: []

    inherit =
      if is_binary(secrets) and level(secrets) == "inherit" and not allowed,
        do: ["#{path} job=#{job_id} rule=reusable-call-allowlisted: `secrets: inherit`"],
        else: []

    uses ++ inherit
  end

  # The YAML key `on` can parse as boolean `true`, so the trigger is scanned in
  # the raw text with comments stripped. Stripping a ` # …` tail can only hide
  # text, never invent it.
  defp pull_request_target_errors(path, text) do
    stripped =
      text
      |> String.split("\n")
      |> Enum.map_join("\n", &Regex.replace(~r/(^|\s)#.*$/, &1, ""))

    if Regex.match?(~r/pull_request_target/i, stripped),
      do: [
        "#{path} rule=no-pull-request-target: `pull_request_target` runs fork code with a " <>
          "privileged token"
      ],
      else: []
  end

  # An allowlist entry must name a workflow and job that exist. Skipped when a
  # workflow failed to parse, which already fails closed above.
  defp stale_errors(_docs, [_ | _]), do: []

  defp stale_errors(docs, []) do
    present = for {path, _text, doc} <- docs, {job_id, _} <- parsed_jobs(doc), do: {path, job_id}

    for {name, allowlist} <- [
          {"@job_write_grants", @job_write_grants},
          {"@job_read_grants", @job_read_grants},
          {"@status_scope_grants", @status_scope_grants},
          {"@reusable_call_grants", @reusable_call_grants}
        ],
        {path, jobs} <- allowlist,
        {job_id, _} <- jobs,
        {path, job_id} not in present do
      "#{path} job=#{job_id} rule=job-write-allowlisted: stale #{name} entry, no such job"
    end
  end

  # --- Tests -----------------------------------------------------------------

  defp rule_fired?(errors, rule), do: Enum.any?(errors, &String.contains?(&1, "rule=#{rule}"))

  defp mutate!(texts, path, from, to) do
    original = Map.fetch!(texts, path)

    assert String.contains?(original, from),
           "control anchor not found in #{path}: #{inspect(from)}"

    Map.put(texts, path, String.replace(original, from, to, global: false))
  end

  test "every workflow's GITHUB_TOKEN is least-privilege" do
    assert token_errors(workflow_texts()) == []
  end

  test "release.yml's workflow block is read-only and writes live on the jobs" do
    {:ok, doc} = parse_yaml(read_rel!(".github/workflows/release.yml"))
    assert grants(yaml_get(doc, "permissions")) == %{"contents" => "read"}
  end

  describe "mutation controls" do
    setup do
      %{texts: workflow_texts()}
    end

    @release ".github/workflows/release.yml"
    @ci ".github/workflows/ci.yml"
    @deps ".github/workflows/deps-health.yml"
    @release_top "permissions:\n  contents: read\n\n# No workflow-level"
    @ci_top "permissions:\n  contents: read\n"
    @deps_job "    permissions:\n      contents: read\n      issues: write\n"
    @gate_job "    permissions:\n      actions: read\n      contents: read\n    steps:"

    for {label, path, from, to, rule} <- [
          {"missing top-level block", @release, @release_top, "# No workflow-level",
           "permissions-declared"},
          {"top-level read-all", @ci, @ci_top, "permissions: read-all\n", "permissions-declared"},
          {"top-level write-all", @ci, @ci_top, "permissions: write-all\n", "write-all-banned"},
          {"top-level write", @ci, @ci_top, "permissions:\n  contents: write\n",
           "workflow-level-read-only"},
          {"job write-all", @deps, @deps_job, "    permissions: write-all\n", "write-all-banned"},
          {"extra job grant", @deps, @deps_job, @deps_job <> "      pull-requests: write\n",
           "job-write-allowlisted"},
          {"allowlisted read dropped", @deps, @deps_job,
           "    permissions:\n      contents: none\n      issues: write\n",
           "job-write-allowlisted"},
          {"unlisted job gains a write", @release, @gate_job,
           "    permissions:\n      actions: write\n      contents: read\n    steps:",
           "job-write-allowlisted"},
          {"stale allowlist entry", @deps, "  deps-health:\n", "  deps-health-renamed:\n",
           "job-write-allowlisted"},
          {"write block without contents", @deps, @deps_job,
           "    permissions:\n      issues: write\n", "job-block-restates-contents"},
          {"statuses write", @deps, @deps_job, @deps_job <> "      statuses: write\n",
           "status-scopes-banned"},
          {"checks write case-folded", @deps, @deps_job, @deps_job <> "      Checks: WRITE\n",
           "status-scopes-banned"},
          {"pull_request_target trigger", @ci, "on:\n", "on:\n  pull_request_target:\n",
           "no-pull-request-target"},
          {"reusable workflow call", @deps, @deps_job,
           @deps_job <> "    uses: ./.github/workflows/ci.yml\n", "reusable-call-allowlisted"},
          {"secrets inherit", @deps, @deps_job, @deps_job <> "    secrets: inherit\n",
           "reusable-call-allowlisted"},
          {"unparseable workflow", @deps, @deps_job, @deps_job <> "  steps: [unclosed\n",
           "yaml-parse"}
        ] do
      test "#{label} fires rule=#{rule}", %{texts: texts} do
        mutated = mutate!(texts, unquote(path), unquote(from), unquote(to))
        refute mutated == texts, "the control did not change the input"
        errors = token_errors(mutated)

        assert rule_fired?(errors, unquote(rule)),
               "expected rule=#{unquote(rule)} to fire, got #{inspect(errors)}"
      end
    end

    test "an extra read scope on an allowlisted job fails equality", %{texts: texts} do
      mutated = mutate!(texts, @deps, @deps_job, @deps_job <> "      packages: read\n")
      refute mutated == texts
      assert rule_fired?(token_errors(mutated), "job-write-allowlisted")
    end

    test "a job block replacing the workflow block is what counts", %{texts: texts} do
      # dropping deps-health's job block leaves it inheriting `contents: read`,
      # which no longer carries its allowlisted `issues: write`
      mutated = mutate!(texts, @deps, @deps_job, "")
      refute mutated == texts
      assert rule_fired?(token_errors(mutated), "job-write-allowlisted")
    end

    test "a commented-out pull_request_target passes (positive control)", %{texts: texts} do
      mutated = mutate!(texts, @ci, "on:\n", "on:\n  # pull_request_target: never\n")
      refute mutated == texts
      assert token_errors(mutated) == []
    end

    test "`{}` is an accepted top-level block (positive control)", %{texts: texts} do
      mutated = mutate!(texts, @ci, @ci_top, "permissions: {}\n")
      refute mutated == texts
      assert token_errors(mutated) == []
    end
  end
end
