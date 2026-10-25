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
  defp unwrapped_errors(steps) do
    for step <- steps,
        step.run != nil,
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
    for rule <- ["retry-allowlist", "retry-no-test", "retry-no-action", "retry-path"] do
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
  end

  defp rule_errors("retry-allowlist", steps), do: allowlist_errors(steps)
  defp rule_errors("retry-no-test", steps), do: no_test_errors(steps)
  defp rule_errors("retry-no-action", steps), do: no_action_errors(steps)
  defp rule_errors("retry-path", steps), do: path_errors(steps)

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
            "verify-credo",
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
end
