defmodule Threadline.RetryNetworkContractTest do
  @moduledoc """
  REL-03: CI's network dependency fetches survive a transient hex.pm or
  network blip, and no test is ever retried.

  Two halves. The behaviour half drives `bin/retry-network` through a fake
  `mix` on PATH (no network, no real Mix) and pins its backoff, its runtime
  allowlist and its deterministic stops. The workflow half parses every
  `.github/workflows/*.yml` step and pins where retries may and may not
  appear. Each workflow rule has a mutation control that turns it red.
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @script Path.join(@repo_root, "bin/retry-network")
  @ci ".github/workflows/ci.yml"

  # --- Behaviour: bin/retry-network through a fake mix ------------------------

  # Fake `mix`: appends its args to CALL_LOG and its stdin to STDIN_LOG. Call
  # number N (1-based) fails while N <= FAKE_FAIL_TIMES (default 0), printing
  # FAKE_MARKER (if set) and exiting FAKE_STATUS (default 1). Later calls
  # print `fake mix: ok` and exit 0.
  @fake_mix """
  #!/usr/bin/env bash
  set -u
  printf '%s\\n' "$*" >> "$CALL_LOG"
  cat >> "$STDIN_LOG"
  n=$(wc -l < "$CALL_LOG" | tr -d ' ')
  if [ "$n" -le "${FAKE_FAIL_TIMES:-0}" ]; then
    printf 'fake mix: transient failure %s\\n' "$n"
    if [ -n "${FAKE_MARKER:-}" ]; then
      printf '%s\\n' "$FAKE_MARKER"
    fi
    exit "${FAKE_STATUS:-1}"
  fi
  printf 'fake mix: ok\\n'
  exit 0
  """

  defp sandbox do
    root = Path.join(System.tmp_dir!(), "retry_network_#{System.unique_integer([:positive])}")
    bin = Path.join(root, "bin")
    tmp = Path.join(root, "tmp")
    File.mkdir_p!(bin)
    File.mkdir_p!(tmp)
    on_exit(fn -> File.rm_rf!(root) end)

    mix = Path.join(bin, "mix")
    File.write!(mix, @fake_mix)
    File.chmod!(mix, 0o755)

    call_log = Path.join(root, "call_log")
    stdin_log = Path.join(root, "stdin_log")
    File.write!(call_log, "")
    File.write!(stdin_log, "")

    %{bin: bin, tmp: tmp, call_log: call_log, stdin_log: stdin_log}
  end

  defp wrapper_env(sb, env) do
    base = [
      {"PATH", sb.bin <> ":" <> System.get_env("PATH", "")},
      {"CALL_LOG", sb.call_log},
      {"STDIN_LOG", sb.stdin_log},
      {"TMPDIR", sb.tmp},
      {"RETRY_NETWORK_BASE_DELAY", "0"}
    ]

    Enum.reduce(env, base, fn {k, v}, acc ->
      [{k, v} | Enum.reject(acc, fn {ek, _} -> ek == k end)]
    end)
  end

  defp run_wrapper(sb, args, env \\ []) do
    {out, status} =
      System.cmd(@script, args, env: wrapper_env(sb, env), stderr_to_stdout: true)

    result(sb, out, status)
  end

  defp result(sb, out, status) do
    %{
      out: out,
      status: status,
      calls: sb.call_log |> File.read!() |> String.split("\n", trim: true) |> length(),
      stdin: File.read!(sb.stdin_log),
      leftovers: File.ls!(sb.tmp)
    }
  end

  defp attempt_lines(out), do: Regex.scan(~r/^retry-network: attempt \d+\/\d+ failed/m, out)

  describe "bin/retry-network behaviour" do
    test "retries a transient failure and succeeds on the third attempt" do
      sb = sandbox()
      r = run_wrapper(sb, ["mix", "deps.get"], [{"FAKE_FAIL_TIMES", "2"}])

      assert r.status == 0, r.out
      assert r.calls == 3
      assert r.stdin == "n\nn\nn\n", "every attempt must read exactly `n` on stdin"
      assert length(attempt_lines(r.out)) == 2, r.out
      assert r.out =~ "fake mix: transient failure 1", "attempt output must be streamed"
      assert r.out =~ "fake mix: ok"
      assert r.leftovers == [], "temp files left behind: #{inspect(r.leftovers)}"
    end

    test "gives up after the default 3 attempts with the command's status" do
      sb = sandbox()

      r =
        run_wrapper(sb, ["mix", "deps.get"], [{"FAKE_FAIL_TIMES", "99"}, {"FAKE_STATUS", "3"}])

      assert r.status == 3, r.out
      assert r.calls == 3
      assert r.out =~ "retry-network: giving up after 3 attempt(s)"
      assert r.leftovers == []
    end

    test "--attempts bounds the attempt count" do
      sb = sandbox()

      r =
        run_wrapper(sb, ["--attempts", "2", "mix", "local.hex", "--force"], [
          {"FAKE_FAIL_TIMES", "99"}
        ])

      assert r.status == 1, r.out
      assert r.calls == 2
      assert r.leftovers == []
    end

    for marker <- [
          "** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag",
          "Unchecked dependencies for environment test:",
          "** (Mix) Dependency resolution failed"
        ] do
      test "a deterministic failure is not retried: #{marker}" do
        sb = sandbox()

        r =
          run_wrapper(sb, ["mix", "deps.get"], [
            {"FAKE_FAIL_TIMES", "99"},
            {"FAKE_MARKER", unquote(marker)}
          ])

        assert r.status == 1, r.out
        assert r.calls == 1, "a deterministic failure must stop after one attempt"
        assert r.leftovers == []
      end
    end

    for status <- [126, 127, 130, 143] do
      test "exit status #{status} is not retried" do
        sb = sandbox()

        r =
          run_wrapper(sb, ["mix", "deps.get"], [
            {"FAKE_FAIL_TIMES", "99"},
            {"FAKE_STATUS", "#{unquote(status)}"}
          ])

        assert r.status == unquote(status), r.out
        assert r.calls == 1
        assert r.leftovers == []
      end
    end

    for args <- [
          ["mix", "test"],
          ["mix", "verify.test"],
          ["mix"],
          ["bash", "-c", "true"],
          ["/usr/bin/env", "mix", "deps.get"],
          ["notmix", "deps.get"]
        ] do
      test "refuses #{Enum.join(args, " ")} without running it" do
        sb = sandbox()
        r = run_wrapper(sb, unquote(args))

        assert r.status == 2, r.out
        assert r.calls == 0
        assert r.out =~ "mix deps.get", "the refusal must name the allowlist"
        assert r.out =~ "mix local.hex"
      end
    end

    for {label, args, env} <- [
          {"--attempts 0", ["--attempts", "0", "mix", "deps.get"], []},
          {"--attempts 11", ["--attempts", "11", "mix", "deps.get"], []},
          {"--attempts x", ["--attempts", "x", "mix", "deps.get"], []},
          {"--attempts with no value", ["--attempts"], []},
          {"an unknown flag", ["--retries", "2", "mix", "deps.get"], []},
          {"RETRY_NETWORK_BASE_DELAY=abc", ["mix", "deps.get"],
           [{"RETRY_NETWORK_BASE_DELAY", "abc"}]}
        ] do
      test "usage error: #{label} exits 2 with no attempt" do
        sb = sandbox()
        r = run_wrapper(sb, unquote(args), unquote(env))

        assert r.status == 2, r.out
        assert r.calls == 0
      end
    end

    test "SIGTERM during the backoff exits 143 at once, starts no attempt, leaves no temp file" do
      sb = sandbox()

      # The harness backgrounds the wrapper (a non-interactive shell ignores
      # SIGINT for background jobs, so SIGTERM is the signal exercised), waits
      # boundedly for the first call, then terminates it mid-backoff.
      harness = ~S"""
      "$0" mix deps.get &
      pid=$!
      i=0
      while [ ! -s "$CALL_LOG" ] && [ "$i" -lt 200 ]; do sleep 0.05; i=$((i + 1)); done
      sleep 0.5
      kill -TERM "$pid"
      wait "$pid"
      echo "wrapper-status=$?"
      """

      env = wrapper_env(sb, [{"FAKE_FAIL_TIMES", "99"}, {"RETRY_NETWORK_BASE_DELAY", "30"}])
      started = System.monotonic_time(:millisecond)
      {out, 0} = System.cmd("bash", ["-c", harness, @script], env: env, stderr_to_stdout: true)
      elapsed = System.monotonic_time(:millisecond) - started
      r = result(sb, out, 0)

      assert out =~ "wrapper-status=143", out
      assert r.calls == 1
      assert r.leftovers == []
      assert elapsed < 15_000, "the wrapper slept through SIGTERM (#{elapsed}ms)"
    end
  end

  describe "bin/retry-network source" do
    test "is executable and feeds `n` with a here-string, never a pipe" do
      assert File.stat!(@script).mode |> Bitwise.band(0o111) != 0
      code = @script |> File.read!() |> strip_comment_lines()

      assert code =~ "<<<'n'"
      refute code =~ "printf 'n"
    end
  end

  # --- Workflow rules ---------------------------------------------------------

  @job_id_pattern "[A-Za-z_][A-Za-z0-9_-]*"

  # The test commands a retry would hide a flake in (REL-03 Out of Scope).
  @test_commands [
    "mix test",
    "verify.test",
    "ci.all",
    "verify.hex_evaluator",
    "verify.example_browser",
    "playwright"
  ]

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

  # A step's `run:` script: the scalar, or the lines of a `run: |` block (every
  # following line indented past the key). Shell comment lines are dropped.
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

  defp workflow_steps(workflows) do
    for {path, yaml} <- Enum.sort(workflows),
        {job_id, block} <- workflow_jobs(yaml),
        step <- job_steps(block) do
      %{
        path: path,
        job: job_id,
        text: step,
        label: yaml_value(step, "name") || step |> String.trim() |> String.split("\n") |> hd(),
        run: run_text(step),
        wd: yaml_value(step, "working-directory") || "."
      }
    end
  end

  defp error(step, rule, message),
    do: "rule=#{rule} #{step.path} job=#{step.job} step=#{inspect(step.label)}: #{message}"

  # Every `bin/retry-network` occurrence in a run script: {path, rest of line}.
  defp wrapper_calls(nil), do: []

  defp wrapper_calls(run) do
    for [_, path, rest] <- Regex.scan(~r/(\S*bin\/retry-network)\b[ \t]*([^\n]*)/, run),
        do: {path, rest}
  end

  # rule=retry-allowlist: the wrapper only ever runs a network fetch.
  defp allowlist_errors(steps) do
    for step <- steps,
        {_path, rest} <- wrapper_calls(step.run),
        not Regex.match?(
          ~r/^(?:--attempts(?:=|\s+)\d+\s+)?(?:--\s+)?mix\s+(?:deps\.get|local\.hex)\b/,
          rest
        ) do
      error(
        step,
        "retry-allowlist",
        "bin/retry-network may only run `mix deps.get` or " <>
          "`mix local.hex`, got #{inspect(rest)}"
      )
    end
  end

  # rule=retry-no-test: a run script that retries anything runs no test.
  defp no_test_errors(steps) do
    for step <- steps,
        step.run != nil,
        String.contains?(step.run, "retry-network"),
        command <- @test_commands,
        String.contains?(step.run, command) do
      error(
        step,
        "retry-no-test",
        "a retried step must never run `#{command}`: a retry " <>
          "hides a flaky test (REL-03)"
      )
    end
  end

  # rule=retry-no-action: no third-party retry action (new supply-chain surface,
  # and it could wrap any step, tests included).
  defp no_action_errors(steps) do
    for step <- steps,
        [_, uses] <- [Regex.run(~r/^\s*(?:-\s+)?uses:\s*(\S+)/m, strip_comment_lines(step.text))],
        Regex.match?(~r/retry/i, uses) do
      error(
        step,
        "retry-no-action",
        "retry actions are forbidden (#{uses}); use bin/retry-network"
      )
    end
  end

  # rule=retry-path: the wrapper path, resolved from the step's
  # working-directory, is the repo-root bin/retry-network.
  defp path_errors(steps) do
    root = "/retry-network-fake-root"
    want = Path.join(root, "bin/retry-network")

    for step <- steps,
        {path, _rest} <- wrapper_calls(step.run),
        Path.expand(path, Path.expand(step.wd, root)) != want do
      error(
        step,
        "retry-path",
        "#{path} from working-directory #{step.wd} does not resolve " <>
          "to the repo-root bin/retry-network"
      )
    end
  end

  # A run-script line that invokes `mix deps.get` at a command position.
  defp deps_get_line?(line),
    do: Regex.match?(~r/(?:^|[;&|(]|\bthen|\bdo|\bif)\s*mix deps\.get\b/, String.trim(line))

  # rule=retry-unwrapped: every `mix deps.get` goes through a retry.
  # A valid inline bounded retry (below) is a retried fetch too.
  defp unwrapped_errors(steps) do
    for step <- steps,
        step.run != nil,
        inline_retry_shape(step.run) != [],
        line <- String.split(step.run, "\n"),
        deps_get_line?(line),
        not String.contains?(line, "retry-network") do
      error(
        step,
        "retry-unwrapped",
        "`mix deps.get` must run through bin/retry-network " <>
          "(REL-03): #{String.trim(line)}"
      )
    end
  end

  # The inline bounded retry: a `for attempt in 1 2 3` loop around one fetch,
  # for a step that must not depend on a repo file (publish-hex checks out a
  # computed ref that a recovery run can point at a tag predating
  # bin/retry-network). The Hex pin (244-05/244-06) shares this shape, so this
  # is the one recogniser. nil when the script is not an inline retry, else
  # its shape problems ([] = valid).
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

  # rule=retry-inline-shape: every inline bounded retry is bounded, backs off,
  # fails when exhausted and fetches nothing but one allowlisted command.
  defp inline_shape_errors(steps) do
    for step <- steps,
        problems = inline_retry_shape(step.run),
        problems not in [nil, []],
        problem <- problems do
      error(step, "retry-inline-shape", problem)
    end
  end

  # Scripts this phase introduces. A recovery tag cut before the phase lacks
  # them; pre-phase scripts (bin/verify-release-shape) exist on every tag.
  @phase_scripts ["bin/retry-network", "bin/date-release-changelog"]

  # A workspace-root actions/checkout (no `path:`) whose `ref:` is computed.
  defp expression_root_checkout?(step) do
    text = strip_comment_lines(step.text)

    Regex.match?(~r/^\s*(?:-\s+)?uses:\s*actions\/checkout@/m, text) and
      yaml_value(text, "path") == nil and
      String.contains?(yaml_value(text, "ref") || "", "${{")
  end

  defp ref_switching_jobs(steps) do
    for step <- steps,
        expression_root_checkout?(step),
        into: MapSet.new(),
        do: {step.path, step.job}
  end

  # rule=retry-ref-independent: a job that checks out a computed ref (a
  # workflow_dispatch recovery can point it at a pre-phase tag) references no
  # phase-introduced script, or a recovery publish exits 127.
  defp ref_independent_errors(steps) do
    switching = ref_switching_jobs(steps)

    for step <- steps,
        MapSet.member?(switching, {step.path, step.job}),
        script <- @phase_scripts,
        String.contains?(strip_comment_lines(step.text), script) do
      error(
        step,
        "retry-ref-independent",
        "#{script} may be absent from the computed ref this job checks out (a pre-phase " <>
          "recovery tag); use the inline bounded retry instead"
      )
    end
  end

  defp workflow_errors(workflows, rule_fun), do: workflows |> workflow_steps() |> rule_fun.()

  defp rule_fired?(errors, rule), do: Enum.any?(errors, &String.contains?(&1, "rule=#{rule}"))

  # Replaces `from` with `to` inside one job of a workflow, asserting `from`
  # occurs exactly once in that job.
  defp mutate_job(yaml, job_id, from, to) do
    {^job_id, block} = Enum.find(workflow_jobs(yaml), fn {id, _} -> id == job_id end)
    assert length(String.split(block, from)) == 2, "control anchor not unique in #{job_id}"
    mutated = String.replace(yaml, block, String.replace(block, from, to))
    refute mutated == yaml, "the control did not change the input"
    mutated
  end

  describe "workflow retry rules on the live tree" do
    for rule <- [
          "retry-allowlist",
          "retry-no-test",
          "retry-no-action",
          "retry-path",
          "retry-unwrapped",
          "retry-ref-independent",
          "retry-inline-shape"
        ] do
      test "rule=#{rule} holds" do
        errors = workflow_errors(all_workflows(), &rule_errors(unquote(rule), &1))
        assert errors == [], Enum.join(errors, "\n")
      end
    end

    test "the live tree wraps at least one fetch (the rules are not vacuous)" do
      wrapped =
        for step <- workflow_steps(all_workflows()), wrapper_calls(step.run) != [], do: step

      refute wrapped == []
    end

    # 15 `run: mix deps.get` steps at b01ffa87: ci.yml 11, release.yml 2,
    # browser-full.yml 1, flake-detection.yml 1. publish-hex is the inline one.
    test "exactly 15 workflow fetches retry: 14 through the wrapper, 1 inline (not vacuous)" do
      steps = workflow_steps(all_workflows())

      wrapper_form =
        for step <- steps,
            {_path, rest} <- wrapper_calls(step.run),
            rest =~ ~r/^(?:--attempts(?:=|\s+)\d+\s+)?(?:--\s+)?mix deps\.get\b/,
            do: {step.path, step.job}

      inline_form =
        for step <- steps,
            inline_retry_shape(step.run) == [],
            step.run =~ "mix deps.get",
            do: {step.path, step.job}

      assert length(wrapper_form) == 14, inspect(wrapper_form)
      assert inline_form == [{".github/workflows/release.yml", "publish-hex"}]
    end

    test "positive control: publish-hex is ref-switching and keeps its pre-phase script" do
      steps = workflow_steps(all_workflows())
      job = {".github/workflows/release.yml", "publish-hex"}

      assert MapSet.member?(ref_switching_jobs(steps), job),
             "publish-hex must be scanned as a computed-ref job, or the rule is vacuous"

      assert Enum.any?(
               steps,
               &({&1.path, &1.job} == job and &1.text =~ "bin/verify-release-shape")
             ),
             "the pre-phase bin/verify-release-shape step must be present in the scanned job"

      assert ref_independent_errors(steps) == []
    end
  end

  defp rule_errors("retry-allowlist", steps), do: allowlist_errors(steps)
  defp rule_errors("retry-no-test", steps), do: no_test_errors(steps)
  defp rule_errors("retry-no-action", steps), do: no_action_errors(steps)
  defp rule_errors("retry-path", steps), do: path_errors(steps)
  defp rule_errors("retry-unwrapped", steps), do: unwrapped_errors(steps)
  defp rule_errors("retry-ref-independent", steps), do: ref_independent_errors(steps)
  defp rule_errors("retry-inline-shape", steps), do: inline_shape_errors(steps)

  describe "mutation controls (REL-03 workflow rules)" do
    setup do
      %{live: all_workflows()}
    end

    test "wrapping `mix test` fires rule=retry-no-test and rule=retry-allowlist", %{live: live} do
      mutated =
        Map.update!(
          live,
          @ci,
          &mutate_job(
            &1,
            "verify-format",
            "run: mix verify.format\n",
            "run: bin/retry-network mix test\n"
          )
        )

      errors = workflow_errors(mutated, &no_test_errors/1)
      assert rule_fired?(errors, "retry-no-test"), inspect(errors)
      assert rule_fired?(workflow_errors(mutated, &allowlist_errors/1), "retry-allowlist")
    end

    test "wrapping `mix compile` fires rule=retry-allowlist", %{live: live} do
      mutated =
        Map.update!(
          live,
          @ci,
          &mutate_job(
            &1,
            "verify-pgbouncer-topology",
            "run: mix compile --warnings-as-errors\n",
            "run: bin/retry-network mix compile --warnings-as-errors\n"
          )
        )

      errors = workflow_errors(mutated, &allowlist_errors/1)
      assert rule_fired?(errors, "retry-allowlist"), inspect(errors)
    end

    test "adding a retry action fires rule=retry-no-action", %{live: live} do
      mutated =
        Map.update!(
          live,
          @ci,
          &mutate_job(
            &1,
            "verify-format",
            "      - name: Check formatting\n",
            "      - name: Retry the format check\n        uses: nick-fields/retry@v3\n\n" <>
              "      - name: Check formatting\n"
          )
        )

      errors = workflow_errors(mutated, &no_action_errors/1)
      assert rule_fired?(errors, "retry-no-action"), inspect(errors)
    end

    test "a repo-relative wrapper path under working-directory fires rule=retry-path", %{
      live: live
    } do
      mutated =
        Map.update!(live, @ci, fn yaml ->
          Regex.replace(
            ~r/(working-directory: examples\/threadline_phoenix\n\s+run: )(?:\.\.\/\.\.\/bin\/retry-network )?mix deps\.get\n/,
            yaml,
            "\\1bin/retry-network mix deps.get\n",
            global: false
          )
        end)

      refute mutated == live, "the control did not change the input"
      errors = workflow_errors(mutated, &path_errors/1)
      assert rule_fired?(errors, "retry-path"), inspect(errors)
    end

    test "unwrapping a deps.get fires rule=retry-unwrapped", %{live: live} do
      job_errors = fn workflows ->
        workflows
        |> workflow_errors(&unwrapped_errors/1)
        |> Enum.filter(&String.contains?(&1, "job=verify-format "))
      end

      assert job_errors.(live) == [], "verify-format must be wrapped on the live tree"

      mutated =
        Map.update!(
          live,
          @ci,
          &mutate_job(
            &1,
            "verify-format",
            "run: bin/retry-network mix deps.get\n",
            "run: mix deps.get\n"
          )
        )

      assert rule_fired?(job_errors.(mutated), "retry-unwrapped")
    end
  end

  @release ".github/workflows/release.yml"

  # Replaces the named step of one job with `new_step`.
  defp replace_step(yaml, job_id, step_name, new_step) do
    {^job_id, block} = Enum.find(workflow_jobs(yaml), fn {id, _} -> id == job_id end)
    [step] = block |> job_steps() |> Enum.filter(&(yaml_value(&1, "name") == step_name))
    mutate_job(yaml, job_id, step, new_step)
  end

  describe "mutation controls (REL-03 ref independence and the inline retry)" do
    setup do
      %{live: all_workflows()}
    end

    test "unwrapping publish-hex's fetch fires rule=retry-unwrapped", %{live: live} do
      mutated =
        Map.update!(
          live,
          @release,
          &replace_step(
            &1,
            "publish-hex",
            "Install dependencies",
            "      - name: Install dependencies\n        run: mix deps.get\n\n"
          )
        )

      errors = workflow_errors(mutated, &unwrapped_errors/1)

      assert Enum.any?(errors, &(&1 =~ "rule=retry-unwrapped" and &1 =~ "job=publish-hex ")),
             inspect(errors)
    end

    test "unwrapping an example-dir fetch fires rule=retry-unwrapped", %{live: live} do
      mutated =
        Map.update!(live, @ci, fn yaml ->
          Regex.replace(
            ~r/(working-directory: examples\/threadline_phoenix\n\s+run: )\.\.\/\.\.\/bin\/retry-network mix deps\.get\n/,
            yaml,
            "\\1mix deps.get\n",
            global: false
          )
        end)

      refute mutated == live, "the control did not change the input"
      errors = workflow_errors(mutated, &unwrapped_errors/1)

      assert Enum.any?(
               errors,
               &(&1 =~ "rule=retry-unwrapped" and &1 =~ "Install example dependencies")
             ),
             inspect(errors)
    end

    test "the wrapper in publish-hex fires rule=retry-ref-independent", %{live: live} do
      mutated =
        Map.update!(
          live,
          @release,
          &replace_step(
            &1,
            "publish-hex",
            "Install dependencies",
            "      - name: Install dependencies\n        run: bin/retry-network mix deps.get\n\n"
          )
        )

      errors = workflow_errors(mutated, &ref_independent_errors/1)
      assert rule_fired?(errors, "retry-ref-independent"), inspect(errors)
    end

    test "bin/date-release-changelog in publish-hex fires rule=retry-ref-independent", %{
      live: live
    } do
      mutated =
        Map.update!(
          live,
          @release,
          &mutate_job(
            &1,
            "publish-hex",
            "      - name: Install dependencies\n",
            "      - name: Date the changelog\n        run: bin/date-release-changelog\n\n" <>
              "      - name: Install dependencies\n"
          )
        )

      errors = workflow_errors(mutated, &ref_independent_errors/1)
      assert rule_fired?(errors, "retry-ref-independent"), inspect(errors)
    end
  end

  @inline_step """
        - name: Install dependencies
          run: |
            for attempt in 1 2 3; do
              if mix deps.get <<<'n'; then
                exit 0
              fi
              if [ "$attempt" -lt 3 ]; then
                sleep $((attempt * 10))
              fi
            done
            echo "Install dependencies: giving up after 3 attempts" >&2
            exit 1
  """

  describe "rule=retry-inline-shape fixtures" do
    defp inline_fixture(step) do
      %{
        ".github/workflows/fixture.yml" =>
          "on: push\njobs:\n  fixture:\n    runs-on: ubuntu-24.04\n    steps:\n" <> step
      }
    end

    test "the valid inline form passes every rule and counts as retried" do
      fixture = inline_fixture(@inline_step)

      assert workflow_errors(fixture, &inline_shape_errors/1) == []
      assert workflow_errors(fixture, &unwrapped_errors/1) == []
      assert workflow_errors(fixture, &no_test_errors/1) == []
    end

    for {label, from, to} <- [
          {"a bound above 10 attempts", "for attempt in 1 2 3;",
           "for attempt in 1 2 3 4 5 6 7 8 9 10 11;"},
          {"no sleep", "          sleep $((attempt * 10))\n", ""},
          {"no final exit 1", "          exit 1\n", ""},
          {"a test in the loop", "            exit 0\n",
           "            mix test\n            exit 0\n"}
        ] do
      test "#{label} fires rule=retry-inline-shape (and the fetch counts as unwrapped)" do
        from = unquote(from)
        assert length(String.split(@inline_step, from)) == 2, "control anchor not unique"
        mutated = inline_fixture(String.replace(@inline_step, from, unquote(to)))

        assert rule_fired?(workflow_errors(mutated, &inline_shape_errors/1), "retry-inline-shape")
        assert rule_fired?(workflow_errors(mutated, &unwrapped_errors/1), "retry-unwrapped")
      end
    end
  end

  describe "rule fixtures" do
    defp fixture(steps) do
      %{
        ".github/workflows/fixture.yml" =>
          "on: push\njobs:\n  fixture:\n    runs-on: ubuntu-24.04\n    steps:\n" <> steps
      }
    end

    test "rule=retry-unwrapped fires on a bare deps.get and not on a wrapped one" do
      bare = fixture("      - name: Install dependencies\n        run: mix deps.get\n")

      wrapped =
        fixture(
          "      - name: Install dependencies\n        run: bin/retry-network mix deps.get\n"
        )

      chained =
        fixture("      - name: Install\n        run: |\n          cd x && mix deps.get\n")

      assert rule_fired?(workflow_errors(bare, &unwrapped_errors/1), "retry-unwrapped")
      assert rule_fired?(workflow_errors(chained, &unwrapped_errors/1), "retry-unwrapped")
      assert workflow_errors(wrapped, &unwrapped_errors/1) == []
    end

    test "rule=retry-path accepts ../../ under an example working-directory" do
      ok =
        fixture(
          "      - name: Install example dependencies\n" <>
            "        working-directory: examples/threadline_phoenix\n" <>
            "        run: ../../bin/retry-network mix deps.get\n"
        )

      assert workflow_errors(ok, &path_errors/1) == []
    end

    test "comment lines are not steps' commands" do
      commented =
        fixture(
          "      - name: Install dependencies\n" <>
            "        # was: bin/retry-network mix test\n" <>
            "        # uses: nick-fields/retry@v3\n" <>
            "        run: bin/retry-network mix deps.get\n"
        )

      steps = workflow_steps(commented)
      assert no_test_errors(steps) == []
      assert no_action_errors(steps) == []
      assert allowlist_errors(steps) == []
    end
  end

  # --- Nested fetches: mix.exs aliases and bin/ scripts -----------------------
  #
  # A step-level retry cannot reach a fetch nested inside a mix alias or a
  # gate script without also retrying what follows it (the hex-evaluator
  # resolve shares its CI step with `mix test`), so the wrapper goes on the
  # command itself. mix.exs reaches it through `"$RETRY_NETWORK"`, an absolute
  # path that `retry_network_env/1` puts in the child shell's environment at
  # run time (so a `cd` inside the alias cannot break it, and a space or quote
  # in the checkout path never reaches shell text, CR-01); a bin/ script
  # through its own directory.

  @mix_exs "mix.exs"
  # As written inside mix.exs's double-quoted command strings.
  @mix_wrapper ~S|\"$RETRY_NETWORK\"|

  # Fetches left unwrapped on purpose, path => reason.
  @unwrapped_fetch_allowlist %{
    "bin/verify-clean-checkout" =>
      "runs inside its own clean-clone proof invoked from an ExUnit contract test, not a " <>
        "CI fetch step; REL-03 scope is CI fetch steps and the hex-evaluator resolve",
    "bin/verify-planning-independent" =>
      "runs inside its own clean-clone proof invoked from an ExUnit contract test, not a " <>
        "CI fetch step; REL-03 scope is CI fetch steps and the hex-evaluator resolve"
  }

  defp nested_sources do
    bins =
      @repo_root |> Path.join("bin/*") |> Path.wildcard() |> Enum.filter(&File.regular?/1)

    Map.new(
      [Path.join(@repo_root, @mix_exs) | bins],
      &{Path.relative_to(&1, @repo_root), File.read!(&1)}
    )
  end

  # Source text with message prose removed: comment lines, backtick spans
  # (`mix deps.get` in a fail message) and single-quoted printf formats.
  defp nested_code(text) do
    text
    |> strip_comment_lines()
    |> String.replace(~r/\\?`[^`\n]*?\\?`/, "")
    |> String.replace(~r/\bprintf[ \t]+(?:--[ \t]+)?'[^'\n]*'/, "printf")
  end

  # The wrapper reference a fetch in `path` must sit behind.
  defp wrapper_prefix(@mix_exs), do: ~r/\\?"\$RETRY_NETWORK\\?"[ \t]+$/
  defp wrapper_prefix(_bin), do: ~r/retry-network"?[ \t]+$/

  # The rest of the line is captured in a lookahead, so a second reference on
  # the same line (a wrapped test tail) is still scanned.
  defp wrapper_reference(@mix_exs), do: ~r/\\?"\$RETRY_NETWORK\\?"[ \t]+(?=([^\n]*))/
  defp wrapper_reference(_bin), do: ~r/retry-network"?[ \t]+(?=([^\n]*))/

  # Every `mix deps.get` / `"$MIX_BIN" deps.get` invocation: {path, line, wrapped?}.
  defp nested_fetches(files) do
    for {path, text} <- Enum.sort(files),
        line <- text |> nested_code() |> String.split("\n"),
        [{start, _len}] <-
          Regex.scan(~r/(?<![\w.\/-])(?:mix|"\$MIX_BIN")[ \t]+deps\.get\b/, line, return: :index) do
      prefix = binary_part(line, 0, start)
      {path, String.trim(line), Regex.match?(wrapper_prefix(path), prefix)}
    end
  end

  defp nested_fetch_errors(files) do
    fetches = nested_fetches(files)

    unwrapped =
      for {path, line, false} <- fetches,
          not Map.has_key?(@unwrapped_fetch_allowlist, path) do
        "rule=nested-unwrapped #{path}: `deps.get` must run through bin/retry-network " <>
          "(REL-03), or be allowlisted with a reason: #{line}"
      end

    stale =
      for {path, _reason} <- @unwrapped_fetch_allowlist,
          not Enum.any?(fetches, &match?({^path, _, false}, &1)) do
        "rule=nested-stale-allowlist #{path} has no unwrapped `deps.get` left; " <>
          "drop it from @unwrapped_fetch_allowlist"
      end

    allowlist =
      for {path, text} <- Enum.sort(files),
          [_, rest] <- Regex.scan(wrapper_reference(path), nested_code(text)),
          not Regex.match?(
            ~r/^(?:--attempts(?:=|\s+)\d+\s+)?(?:--\s+)?(?:mix|"\$MIX_BIN")\s+(?:deps\.get|local\.hex)\b/,
            rest
          ) do
        "rule=retry-allowlist #{path}: bin/retry-network may only run `mix deps.get` or " <>
          "`mix local.hex`, got #{inspect(rest)}"
      end

    unwrapped ++ stale ++ allowlist
  end

  defp mutate_source(files, path, from, to) do
    text = Map.fetch!(files, path)
    assert length(String.split(text, from)) == 2, "control anchor not unique in #{path}"
    Map.put(files, path, String.replace(text, from, to))
  end

  describe "nested fetch rules (REL-03 mix aliases and bin scripts)" do
    setup do
      %{live: nested_sources()}
    end

    test "rule=nested-unwrapped and rule=nested-stale-allowlist hold over mix.exs and bin/", %{
      live: live
    } do
      errors = nested_fetch_errors(live)
      assert errors == [], Enum.join(errors, "\n")
    end

    test "the detector finds exactly the known invocations and no prose (not vacuous)", %{
      live: live
    } do
      found =
        live
        |> nested_fetches()
        |> Enum.map(fn {path, _line, wrapped?} -> {path, wrapped?} end)
        |> Enum.frequencies()

      assert found == %{
               {@mix_exs, true} => 5,
               {"bin/deps-health-report", true} => 1,
               {"bin/verify-bump-rehearsal", true} => 1,
               {"bin/verify-deps-audit", true} => 1,
               {"bin/verify-clean-checkout", false} => 1,
               {"bin/verify-planning-independent", false} => 1
             }
    end

    test "mix.exs wraps exactly its 5 alias fetches (not vacuous)", %{live: live} do
      fetches = nested_fetches(Map.take(live, [@mix_exs]))
      assert length(fetches) == 5, inspect(fetches, pretty: true)
      assert Enum.all?(fetches, &elem(&1, 2)), inspect(fetches, pretty: true)
    end

    test "the hex-evaluator resolve retries and its compile, ecto and test tail do not", %{
      live: live
    } do
      [chain] =
        live
        |> Map.fetch!(@mix_exs)
        |> String.split("\n")
        |> Enum.filter(&(&1 =~ "-r HexEvaluator.Repo"))

      assert String.trim(chain) ==
               ~S|"\"$RETRY_NETWORK\" mix deps.get && mix compile --warnings-as-errors && | <>
                 ~S|mix ecto.create --quiet -r HexEvaluator.Repo && mix ecto.migrate --quiet && mix test"|

      [_, tail] = String.split(chain, "mix compile", parts: 2)
      refute tail =~ "retry"
    end

    test "prose is not an invocation" do
      prose = %{
        "bin/fixture" => ~S"""
        # run `mix deps.get` first
        fail "deps" "\`mix deps.get\` failed"
        printf -- '- note: mix deps.get --check-locked failed\n'
        printf 'usage: x [--] mix deps.get|local.hex\n'
        FAILURES+=("FAIL $d: deps.get --check-locked exited 1")
        """
      }

      assert nested_fetches(prose) == []

      calls = %{
        "bin/fixture" => ~S"""
        out="$(cd "$d" && "$MIX_BIN" deps.get --check-locked 2>&1)"
        (cd x && mix deps.get)
        """
      }

      assert [{_, _, false}, {_, _, false}] = nested_fetches(calls)
    end
  end

  describe "mutation controls (REL-03 nested fetches)" do
    setup do
      %{live: nested_sources()}
    end

    test "unwrapping the hex-evaluator resolve fires rule=nested-unwrapped", %{live: live} do
      mutated =
        mutate_source(
          live,
          @mix_exs,
          "#{@mix_wrapper} mix deps.get && mix compile --warnings-as-errors && " <>
            "mix ecto.create --quiet -r HexEvaluator.Repo",
          "mix deps.get && mix compile --warnings-as-errors && " <>
            "mix ecto.create --quiet -r HexEvaluator.Repo"
        )

      errors = nested_fetch_errors(Map.take(mutated, [@mix_exs]))
      assert rule_fired?(errors, "nested-unwrapped"), inspect(errors)
    end

    test "wrapping the hex-evaluator `mix test` tail fires rule=retry-allowlist", %{live: live} do
      mutated =
        mutate_source(
          live,
          @mix_exs,
          "mix ecto.migrate --quiet && mix test\"",
          "mix ecto.migrate --quiet && #{@mix_wrapper} mix test\""
        )

      errors = nested_fetch_errors(Map.take(mutated, [@mix_exs]))
      assert rule_fired?(errors, "retry-allowlist"), inspect(errors)
    end

    test "a relative wrapper path in mix.exs fires rule=nested-unwrapped", %{live: live} do
      mutated =
        mutate_source(
          live,
          @mix_exs,
          "cd bench && #{@mix_wrapper} mix deps.get && mix compile",
          "cd bench && bin/retry-network mix deps.get && mix compile"
        )

      errors = nested_fetch_errors(Map.take(mutated, [@mix_exs]))
      assert rule_fired?(errors, "nested-unwrapped"), inspect(errors)
    end

    test "an unwrapped deps.get added to a bin script fires rule=nested-unwrapped", %{
      live: live
    } do
      path = "bin/verify-deps-audit"
      mutated = Map.update!(live, path, &(&1 <> "\n(cd \"$d\" && mix deps.get)\n"))

      errors = nested_fetch_errors(mutated)

      assert Enum.any?(errors, &(&1 =~ "rule=nested-unwrapped #{path}:")),
             Enum.join(errors, "\n")
    end

    test "renaming an allowlisted script fires rule=nested-stale-allowlist", %{live: live} do
      {text, rest} = Map.pop!(live, "bin/verify-clean-checkout")
      mutated = Map.put(rest, "bin/verify-clean-checkout-renamed", text)

      errors = nested_fetch_errors(mutated)
      assert rule_fired?(errors, "nested-stale-allowlist"), inspect(errors)
    end

    test "removing an allowlisted script's fetch fires rule=nested-stale-allowlist", %{
      live: live
    } do
      mutated =
        mutate_source(
          live,
          "bin/verify-planning-independent",
          "\nmix deps.get --check-locked\n",
          "\ntrue\n"
        )

      errors = nested_fetch_errors(mutated)
      assert rule_fired?(errors, "nested-stale-allowlist"), inspect(errors)
    end
  end

  # --- CR-01: mix.exs loads from any checkout path ------------------------------
  #
  # mix.exs ships in the Hex package and Mix evaluates `project/0` (and so
  # `aliases/0`) for every adopter that depends on Threadline. Nothing there may
  # compute or validate a path that a directory name can break: the wrapper path
  # is resolved only inside the fetching task functions, at run time.

  @eager_guard_anchor "aliases: aliases(),"
  @eager_guard ~S|aliases: (if String.match?(__DIR__, ~r/\s/), do: Mix.raise("eager load guard"), else: aliases()),|

  # Copies mix.exs alone into a fresh `name`d dir and runs `mix help compile`
  # there. The MIX_* path variables are unset so the child cannot fall back to
  # this checkout. Not `Mix.Project.in_project/4`: the copy defines
  # `Threadline.MixProject`, which this suite has already loaded.
  defp load_mix_exs(name, source) do
    parent =
      Path.join(System.tmp_dir!(), "threadline_cr01_#{System.unique_integer([:positive])}")

    dir = Path.join(parent, name)
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(parent) end)
    File.write!(Path.join(dir, "mix.exs"), source)

    env = for var <- ~w(MIX_EXS MIX_BUILD_PATH MIX_DEPS_PATH MIX_LOCKFILE), do: {var, nil}
    System.cmd("mix", ["help", "compile"], cd: dir, stderr_to_stdout: true, env: env)
  end

  defp live_mix_exs, do: File.read!(Path.join(@repo_root, @mix_exs))

  defp eager_guard_mix_exs do
    text = live_mix_exs()
    assert length(String.split(text, @eager_guard_anchor)) == 2, "eager-guard anchor not unique"
    String.replace(text, @eager_guard_anchor, @eager_guard)
  end

  describe "mix.exs loads from any checkout path (CR-01)" do
    test "a directory name with a space loads" do
      {out, status} = load_mix_exs("threadline checkout", live_mix_exs())
      assert status == 0, out
    end

    test "a directory name with a single quote loads" do
      {out, status} = load_mix_exs("threadline's checkout", live_mix_exs())
      assert status == 0, out
    end

    test "control: a plain directory name loads" do
      {out, status} = load_mix_exs("threadline_checkout", live_mix_exs())
      assert status == 0, out
    end

    test "mutation control: an eager load-time path guard is caught (not vacuous)" do
      mutant = eager_guard_mix_exs()

      {out, status} = load_mix_exs("threadline checkout", mutant)
      assert status != 0, out
      assert out =~ "eager load guard", out

      {out, status} = load_mix_exs("threadline_checkout", mutant)
      assert status == 0, out
    end
  end
end
