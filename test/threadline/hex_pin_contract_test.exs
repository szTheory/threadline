defmodule Threadline.HexPinContractTest do
  @moduledoc """
  REL-04: CI and local run one chosen Hex version.

  The pin is toolchain determinism. Every setup-beam step turns its own Hex
  install off and the very next step pins one explicit version, retried, and
  `MIN_HEX` in bin/verify-deps-audit equals that pin, so a future Hex
  behaviour change lands as a reviewed bump. It is not what fixed the 1.1.0
  red run: Hex 2.5.1 and 2.6.0 both reject a `[]` build-manager lock from a
  cold deps/ and both accept it from a warm one. bin/verify-lock-hygiene is
  the check for that defect.

  `hex_pin_errors/3` is pure over a map of workflow path => text. Each rule
  emits a `rule=<tag>` message and has a mutation control that turns it red.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @deps_audit "bin/verify-deps-audit"
  @ci ".github/workflows/ci.yml"

  @release ".github/workflows/release.yml"
  @browser_full ".github/workflows/browser-full.yml"

  # The live assertion covers every job in every workflow. A narrower scope is a
  # list of {path, job} or {path, :all}.
  @live_scope :all

  # Pinned setup-beam steps the live scope must contain (ci.yml 11, release.yml
  # 3, browser-full, flake-detection, deps-health), so a parse that finds no
  # jobs cannot pass vacuously.
  @live_pin_count 17

  # release.yml's sparse-job pin script, verbatim, as a mutation anchor.
  @release_inline_pin "        run: |\n" <>
                        "          for attempt in 1 2 3; do\n" <>
                        "            if mix local.hex 2.6.0 --force <<<'n'; then\n" <>
                        "              exit 0\n" <>
                        "            fi\n" <>
                        "            if [ \"$attempt\" -lt 3 ]; then\n" <>
                        "              sleep $((attempt * 10))\n" <>
                        "            fi\n" <>
                        "          done\n" <>
                        "          echo \"Pin Hex: giving up after 3 attempts\" >&2\n" <>
                        "          exit 1\n"

  @job_id_pattern "[A-Za-z_][A-Za-z0-9_-]*"
  @version ~r/^[0-9]+\.[0-9]+\.[0-9]+$/

  # --- Parsing (copied bodies; tests do not share modules) --------------------

  defp all_workflows do
    paths = @repo_root |> Path.join(".github/workflows/*.{yml,yaml}") |> Path.wildcard()
    refute paths == [], "found no workflow files to scan"
    Map.new(paths, &{Path.relative_to(&1, @repo_root), File.read!(&1)})
  end

  # Copied from ci_workflow_parity_contract_test.exs (workflow_jobs/1).
  defp workflow_jobs(yaml) do
    case String.split(yaml, ~r/^jobs:\n/m, parts: 2) do
      [_, body] ->
        ~r/^  (#{@job_id_pattern}):[ \t]*\n[\s\S]*?(?=^  #{@job_id_pattern}:[ \t]*\n|\z)/m
        |> Regex.scan(body)
        |> Enum.map(fn [block, job_id] -> {job_id, block} end)

      _ ->
        []
    end
  end

  # Copied from ci_workflow_parity_contract_test.exs (job_steps/1).
  defp job_steps(block) do
    case Regex.split(~r/^(?=      - )/m, block) do
      [_header | steps] -> steps
      [] -> []
    end
  end

  # Copied from ci_workflow_parity_contract_test.exs (yaml_value/2).
  defp yaml_value(step, key) do
    case Regex.run(~r/^\s*(?:-\s+)?#{Regex.escape(key)}:[ \t]*(.*?)[ \t]*$/m, step) do
      [_, value] -> value
      nil -> nil
    end
  end

  # Copied from ci_workflow_parity_contract_test.exs (strip_comment_lines/1).
  defp strip_comment_lines(text) do
    text
    |> String.split("\n")
    |> Enum.reject(&String.match?(&1, ~r/^\s*#/))
    |> Enum.join("\n")
  end

  # Copied from ci_workflow_parity_contract_test.exs (trimmed_lines/1).
  defp trimmed_lines(text) do
    text |> strip_comment_lines() |> String.split("\n") |> Enum.map(&String.trim/1)
  end

  # Copied from retry_network_contract_test.exs (run_text/1).
  defp run_text(step) do
    lines = step |> strip_comment_lines() |> String.split("\n")

    case Enum.split_while(lines, &(not Regex.match?(~r/^\s*(?:-\s+)?run:/, &1))) do
      {_, []} ->
        nil

      {_, [run_line | rest]} ->
        [_, indent, value] = Regex.run(~r/^(\s*)(?:-\s+)?run:[ \t]*(.*?)[ \t]*$/, run_line)

        if value in ["|", "|-", "|+", ">", ">-"] do
          rest
          |> Enum.take_while(&(String.trim(&1) == "" or indent_width(&1) > byte_size(indent)))
          |> Enum.join("\n")
        else
          value
        end
    end
  end

  defp indent_width(line), do: byte_size(line) - byte_size(String.trim_leading(line))

  # Copied from retry_network_contract_test.exs (inline_retry_shape/1 and
  # inline_shape_problems/2): the one recogniser of the inline bounded retry.
  # nil when the script is not an inline retry, else its problems ([] = valid).
  defp inline_retry_shape(nil), do: nil

  defp inline_retry_shape(run) do
    case Regex.run(~r/\bfor\s+attempt\s+in\s+((?:\d+[ \t]+)*\d+)[ \t]*(?:;[ \t]*|\n\s*)do\b/, run) do
      nil -> nil
      [_, list] -> inline_shape_problems(run, list |> String.split() |> length())
    end
  end

  defp inline_shape_problems(run, count) do
    fetches =
      Regex.scan(~r/(?:^|[\s;&|(])mix\s+(?:deps\.get\b|local\.hex\b[^\n]*--force\b)/m, run)

    mix_calls = Regex.scan(~r/(?:^|[\s;&|(])mix\s+\S/m, run)
    done? = Regex.match?(~r/^\s*done\s*$/m, run)
    after_done = run |> String.split(~r/^\s*done\s*$/m) |> List.last()

    [
      {count in 2..10, "the loop must run 2..10 attempts, got #{count}"},
      {length(fetches) == 1,
       "the loop must run exactly one `mix deps.get` or `mix local.hex ... --force`"},
      {length(mix_calls) == 1, "an inline retry runs no other mix command (never a test)"},
      {Regex.match?(~r/\bsleep\s/, run), "the loop must sleep between attempts"},
      {done? and Regex.match?(~r/\bexit 1\b/, after_done),
       "`exit 1` must follow `done`, so exhausting the attempts fails the step"}
    ]
    |> Enum.reject(&elem(&1, 0))
    |> Enum.map(&elem(&1, 1))
  end

  # --- The contract ------------------------------------------------------------

  defp setup_beam?(step),
    do: String.contains?(strip_comment_lines(step), "uses: erlef/setup-beam@")

  # A workspace-root actions/checkout (no `path:` input): bin/ is on disk after it.
  defp root_checkout?(step) do
    text = strip_comment_lines(step)

    Regex.match?(~r/^\s*(?:-\s+)?uses:\s*actions\/checkout@/m, text) and
      yaml_value(text, "path") == nil
  end

  defp local_hex?(step) do
    run = run_text(step)
    is_binary(run) and Regex.match?(~r/(?:^|[\s;&|(])mix\s+local\.hex\b/m, run)
  end

  # {:wrapper | :inline, version} for a recognised retried pin, else nil. A bare
  # unretried `mix local.hex` is never a pin.
  defp pin(step) do
    run = run_text(step)

    cond do
      not is_binary(run) ->
        nil

      match = Regex.run(~r/\Abin\/retry-network mix local\.hex (\S+) --force\z/, String.trim(run)) ->
        {:wrapper, Enum.at(match, 1)}

      inline_retry_shape(run) == [] ->
        case Regex.run(~r/(?:^|[\s;&|(])mix\s+local\.hex\s+(\S+)\s+--force\b/m, run) do
          [_, version] -> {:inline, version}
          nil -> nil
        end

      true ->
        nil
    end
  end

  defp in_scope?(_path, _job, :all), do: true
  defp in_scope?(path, job, scope), do: {path, job} in scope or {path, :all} in scope

  defp scoped_jobs(workflows, scope) do
    for {path, yaml} <- Enum.sort(workflows),
        {job, block} <- workflow_jobs(yaml),
        in_scope?(path, job, scope) do
      {path, job, job_steps(block)}
    end
  end

  defp err(path, job, rule, message), do: "rule=#{rule} #{path} job=#{job}: #{message}"

  defp hex_pin_errors(workflows, min_hex, scope \\ :all) do
    jobs = scoped_jobs(workflows, scope)
    per_job = Enum.flat_map(jobs, &job_pin_errors/1)

    versions =
      for {_path, _job, steps} <- jobs, step <- steps, {_, v} <- [pin(step)], do: v

    uniform =
      case Enum.uniq(versions) do
        [] -> []
        [_] -> []
        many -> ["rule=pin-uniform every pin must name one Hex version, got #{inspect(many)}"]
      end

    floor =
      for v <- Enum.uniq(versions), v != min_hex do
        "rule=pin-floor pin #{v} must equal MIN_HEX #{min_hex} in #{@deps_audit}"
      end

    per_job ++ uniform ++ floor
  end

  defp job_pin_errors({path, job, steps}) do
    indexed = Enum.with_index(steps)
    beams = for {step, i} <- indexed, setup_beam?(step), do: i
    hex_steps = Enum.filter(steps, &local_hex?/1)

    install_off =
      for i <- beams, "install-hex: false" not in trimmed_lines(Enum.at(steps, i)) do
        err(path, job, "pin-install-hex-off", "setup-beam must declare `install-hex: false`")
      end

    after_beam = Enum.flat_map(beams, &after_beam_errors(path, job, steps, &1))

    unretried =
      for step <- hex_steps, pin(step) == nil do
        err(path, job, "pin-step", "`mix local.hex` must be retried: #{inspect(run_text(step))}")
      end

    single =
      if (beams != [] or hex_steps != []) and length(hex_steps) != 1,
        do: [err(path, job, "pin-single", "exactly one `mix local.hex` step per job")],
        else: []

    install_off ++ after_beam ++ unretried ++ single
  end

  # pin-step / pin-wrapped for the step right after the setup-beam at index i.
  defp after_beam_errors(path, job, steps, i) do
    next = Enum.at(steps, i + 1)
    rooted? = steps |> Enum.take(i) |> Enum.any?(&root_checkout?/1)

    case next && pin(next) do
      nil ->
        [
          err(
            path,
            job,
            "pin-step",
            "the step right after setup-beam must pin `mix local.hex V --force`, retried"
          )
        ]

      {form, version} ->
        version_errors(path, job, version) ++ wrapped_errors(path, job, rooted?, form)
    end
  end

  defp version_errors(path, job, version) do
    if Regex.match?(@version, version),
      do: [],
      else: [err(path, job, "pin-step", "pin version #{inspect(version)} is not X.Y.Z")]
  end

  # A root checkout before setup-beam puts bin/ on disk: use the wrapper.
  # Without one (a sparse `.toolchain-pin` checkout) bin/ is absent: inline.
  defp wrapped_errors(path, job, true, :inline),
    do: [err(path, job, "pin-wrapped", "bin/ is on disk here: use bin/retry-network")]

  defp wrapped_errors(path, job, false, :wrapper),
    do: [
      err(
        path,
        job,
        "pin-wrapped",
        "no root checkout precedes setup-beam, so bin/ is absent: use the inline retry"
      )
    ]

  defp wrapped_errors(_path, _job, _rooted?, _form), do: []

  # setup-beam steps in scope whose very next step is a recognised pin.
  defp pinned_beam_count(workflows, scope) do
    for {_path, _job, steps} <- scoped_jobs(workflows, scope),
        {step, i} <- Enum.with_index(steps),
        setup_beam?(step),
        next = Enum.at(steps, i + 1),
        next != nil and pin(next) != nil,
        reduce: 0 do
      acc -> acc + 1
    end
  end

  defp rule_fired?(errors, rule), do: Enum.any?(errors, &String.contains?(&1, "rule=#{rule}"))

  # Replaces `from` (which must occur exactly once in the job) inside one job of
  # one workflow, so a control stays unique when every job carries the pin.
  defp mutate_job(workflows, path, job, from, to) do
    yaml = Map.fetch!(workflows, path)
    block = job_block!(yaml, job)

    assert length(String.split(block, from)) == 2,
           "control anchor not found or not unique in #{path} job=#{job}"

    mutated = String.replace(yaml, block, String.replace(block, from, to), global: false)
    refute mutated == yaml, "the control did not change the input"
    Map.put(workflows, path, mutated)
  end

  defp job_block!(yaml, job) do
    case List.keyfind(workflow_jobs(yaml), job, 0) do
      {^job, block} -> block
      nil -> flunk("no job #{job} in the workflow")
    end
  end

  # Moves the job's pin step to just after its first cache step.
  defp move_pin_after_first_cache(workflows, path, job) do
    yaml = Map.fetch!(workflows, path)
    block = job_block!(yaml, job)
    [header | _] = Regex.split(~r/^(?=      - )/m, block)
    steps = job_steps(block)

    pin_at = Enum.find_index(steps, &(pin(&1) != nil))
    assert pin_at, "#{path} job=#{job} has no pin step to move"
    {pin_step, rest} = List.pop_at(steps, pin_at)

    cache_at = Enum.find_index(rest, &String.contains?(&1, "uses: actions/cache"))
    assert cache_at, "#{path} job=#{job} has no cache step"

    moved = header <> Enum.join(List.insert_at(rest, cache_at + 1, pin_step))
    Map.put(workflows, path, String.replace(yaml, block, moved, global: false))
  end

  defp min_hex! do
    text = File.read!(Path.join(@repo_root, @deps_audit))

    case Regex.run(~r/^MIN_HEX="([^"]+)"/m, text) do
      [_, v] -> v
      nil -> flunk("#{@deps_audit} has no literal MIN_HEX=\"X.Y.Z\" line")
    end
  end

  # --- Fixtures -----------------------------------------------------------------

  @wrapper_job """
    rooted:
      runs-on: ubuntu-24.04
      steps:
        - uses: actions/checkout@v5

        - uses: erlef/setup-beam@v1
          id: beam
          with:
            version-file: .tool-versions
            version-type: strict
            install-hex: false

        - name: Pin Hex (CI and local must agree)
          run: bin/retry-network mix local.hex 2.6.0 --force

        - name: Install dependencies
          run: bin/retry-network mix deps.get
  """

  # The inline job's pin script, verbatim, as a mutation anchor.
  @inline_run "        run: |\n" <>
                "          for attempt in 1 2 3; do\n" <>
                "            if mix local.hex 2.6.0 --force; then\n" <>
                "              exit 0\n" <>
                "            fi\n" <>
                "            if [ \"$attempt\" -lt 3 ]; then\n" <>
                "              sleep $((attempt * 10))\n" <>
                "            fi\n" <>
                "          done\n" <>
                "          echo \"Pin Hex: giving up after 3 attempts\" >&2\n" <>
                "          exit 1\n"

  @inline_job """
    sparse:
      runs-on: ubuntu-24.04
      steps:
        - name: Read the toolchain pin
          uses: actions/checkout@v5
          with:
            path: .toolchain-pin
            sparse-checkout: .tool-versions

        - uses: erlef/setup-beam@v1
          id: beam
          with:
            version-file: .toolchain-pin/.tool-versions
            version-type: strict
            install-hex: false

        - name: Pin Hex (CI and local must agree)
          run: |
            for attempt in 1 2 3; do
              if mix local.hex 2.6.0 --force; then
                exit 0
              fi
              if [ "$attempt" -lt 3 ]; then
                sleep $((attempt * 10))
              fi
            done
            echo "Pin Hex: giving up after 3 attempts" >&2
            exit 1

        - uses: actions/checkout@v5
          with:
            ref: ${{ github.sha }}
  """

  defp fixture(jobs_text), do: %{".github/workflows/fixture.yml" => fixture_text(jobs_text)}

  defp fixture_text(jobs_text), do: "on: push\njobs:\n" <> jobs_text

  defp two_jobs, do: @wrapper_job <> "\n" <> @inline_job

  describe "fixtures" do
    test "a wrapper-pinned job and an inline-pinned sparse job pass every rule" do
      assert hex_pin_errors(fixture(two_jobs()), "2.6.0") == []
    end

    test "the sparse .toolchain-pin job accepts the inline bounded retry" do
      assert hex_pin_errors(fixture(@inline_job), "2.6.0") == []
    end

    test "the inline pin with an 11-attempt bound is not a pin (rule=pin-step)" do
      from = "for attempt in 1 2 3;"
      assert length(String.split(@inline_job, from)) == 2, "control anchor not unique"

      mutated = String.replace(@inline_job, from, "for attempt in 1 2 3 4 5 6 7 8 9 10 11;")
      errors = hex_pin_errors(fixture(mutated), "2.6.0")
      assert rule_fired?(errors, "pin-step"), inspect(errors)
    end
  end

  describe "mutation controls (each turns its rule red)" do
    for {label, from, to, rule} <- [
          {"setup-beam keeps its own Hex install",
           "          version-file: .tool-versions\n          version-type: strict\n" <>
             "          install-hex: false\n",
           "          version-file: .tool-versions\n          version-type: strict\n",
           "pin-install-hex-off"},
          {"a non-pin step sits between setup-beam and the pin",
           "      - name: Pin Hex (CI and local must agree)\n        run: bin/",
           "      - name: Echo\n        run: echo hi\n\n" <>
             "      - name: Pin Hex (CI and local must agree)\n        run: bin/", "pin-step"},
          {"the pin runs bare, unretried", "run: bin/retry-network mix local.hex 2.6.0 --force",
           "run: mix local.hex 2.6.0 --force", "pin-step"},
          {"the pin version is not X.Y.Z", "mix local.hex 2.6.0 --force\n\n",
           "mix local.hex latest --force\n\n", "pin-step"},
          {"the rooted job uses the inline form",
           "        run: bin/retry-network mix local.hex 2.6.0 --force\n",
           "        run: |\n          for attempt in 1 2 3; do\n" <>
             "            if mix local.hex 2.6.0 --force; then\n              exit 0\n" <>
             "            fi\n            sleep 10\n          done\n          exit 1\n",
           "pin-wrapped"},
          {"the sparse job uses the wrapper form", @inline_run,
           "        run: bin/retry-network mix local.hex 2.6.0 --force\n", "pin-wrapped"},
          {"one job pins a different version", "mix local.hex 2.6.0 --force\n\n",
           "mix local.hex 2.5.4 --force\n\n", "pin-uniform"},
          {"a second local.hex step in one job",
           "      - name: Install dependencies\n        run: bin/retry-network mix deps.get\n",
           "      - name: Install dependencies\n        run: bin/retry-network mix deps.get\n\n" <>
             "      - name: Pin again\n        run: bin/retry-network mix local.hex 2.6.0 --force\n",
           "pin-single"}
        ] do
      test "#{label} fires rule=#{rule}" do
        live = fixture_text(two_jobs())
        from = unquote(from)

        assert length(String.split(live, from)) == 2, "control anchor not found or not unique"

        mutated = String.replace(live, from, unquote(to), global: false)
        refute mutated == live, "the control did not change the input"

        errors = hex_pin_errors(%{".github/workflows/fixture.yml" => mutated}, "2.6.0")
        assert rule_fired?(errors, unquote(rule)), inspect(errors)
      end
    end

    test "MIN_HEX 2.5.1 under 2.6.0 pins fires rule=pin-floor" do
      assert hex_pin_errors(fixture(two_jobs()), "2.6.0") == []
      errors = hex_pin_errors(fixture(two_jobs()), "2.5.1")
      assert rule_fired?(errors, "pin-floor"), inspect(errors)
    end
  end

  describe "live tree" do
    test "bin/verify-deps-audit carries a literal X.Y.Z MIN_HEX" do
      assert Regex.match?(@version, min_hex!())
    end

    test "the scoped jobs pin Hex, retried, right after setup-beam, at MIN_HEX" do
      workflows = all_workflows()
      assert hex_pin_errors(workflows, min_hex!(), @live_scope) == []

      assert pinned_beam_count(workflows, @live_scope) == @live_pin_count,
             "expected #{@live_pin_count} pinned setup-beam steps in the live scope"
    end

    for {label, path, job, from, to, rule} <- [
          {"dropping install-hex: false", @ci, "verify-deps-audit",
           "          install-hex: false\n", "", "pin-install-hex-off"},
          {"unretrying the pin", @ci, "verify-deps-audit",
           "run: bin/retry-network mix local.hex 2.6.0 --force",
           "run: mix local.hex 2.6.0 --force", "pin-step"},
          {"pinning below MIN_HEX", @ci, "verify-deps-audit",
           "run: bin/retry-network mix local.hex 2.6.0 --force",
           "run: bin/retry-network mix local.hex 2.5.1 --force", "pin-floor"},
          {"dropping install-hex: false from the matrix step", @ci, "verify-test",
           "          install-hex: false\n", "", "pin-install-hex-off"},
          {"a bare, unretried release pin", @release, "publish-hex", @release_inline_pin,
           "        run: mix local.hex 2.6.0 --force\n", "pin-step"},
          {"a release pin through the wrapper bin/ does not yet hold", @release,
           "smoke-published", @release_inline_pin,
           "        run: bin/retry-network mix local.hex 2.6.0 --force\n", "pin-wrapped"},
          {"a rooted browser-full pin in the inline form", @browser_full,
           "verify-example-browser-full",
           "        run: bin/retry-network mix local.hex 2.6.0 --force\n", @release_inline_pin,
           "pin-wrapped"}
        ] do
      test "#{label} (#{job}) fires rule=#{rule}" do
        workflows = all_workflows()

        mutated =
          mutate_job(workflows, unquote(path), unquote(job), unquote(from), unquote(to))

        errors = hex_pin_errors(mutated, min_hex!(), @live_scope)
        assert rule_fired?(errors, unquote(rule)), inspect(errors)
      end
    end

    test "moving the verify-format pin after its first cache step fires rule=pin-step" do
      workflows = all_workflows()
      assert hex_pin_errors(workflows, min_hex!(), @live_scope) == []

      mutated = move_pin_after_first_cache(workflows, @ci, "verify-format")
      refute mutated == workflows, "the control did not change the input"

      errors = hex_pin_errors(mutated, min_hex!(), @live_scope)
      assert rule_fired?(errors, "pin-step"), inspect(errors)
    end
  end
end
