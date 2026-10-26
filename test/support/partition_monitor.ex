defmodule Threadline.Test.PartitionMonitor do
  @moduledoc """
  CI-only ExUnit formatter for the partitioned test runner.

  `bin/ci-test-partitions` is the only caller that attaches it. Every
  partition's `mix test` gets
  `--formatter ExUnit.CLIFormatter --formatter Threadline.Test.PartitionMonitor`,
  so the normal CLI output is unchanged. Plain `mix test`, the `mix.exs`
  aliases and `test/test_helper.exs` never attach it.

  It records per-file timings: with `THREADLINE_PARTITION_TIMINGS_FILE` set,
  at `:suite_finished` it writes a `threadline.partition-timings/1` TSV that
  `bin/ci-test-partitions --ingest-weights` turns into
  `test/partition_weights.txt`. The header is

      # threadline.partition-timings/1 partition=<i> lane=<lane> boot_ms=<ms> wall_ms=<ms>

  where `lane` is `THREADLINE_CI_LANE` (`local` when unset or empty),
  `boot_ms` is the VM wall time at the first `:module_started` and `wall_ms`
  the VM wall time at `:suite_finished`. Then one row per test file:
  `<relative file>\\t<wall_ms>\\t<test_ms>`, where `wall_ms` sums each of the
  file's modules from `:module_started` to `:module_finished` and `test_ms`
  sums the file's `ExUnit.Test` times.

  It handles only `:module_started`, `:test_started`, `:test_finished`,
  `:module_finished`, `:suite_finished` and `:sigquit`, and ignores every
  other event (including the deprecated `:case_started`/`:case_finished` and
  `:max_failures_reached`). It uses only struct fields present on Elixir
  1.15.
  """

  use GenServer

  @format "threadline.partition-timings/1"

  @impl GenServer
  def init(_opts) do
    {:ok, %{boot_ms: nil, modules: %{}, tests: %{}, files: %{}}}
  end

  @impl GenServer
  def handle_cast({:module_started, %ExUnit.TestModule{name: name, file: file}}, state) do
    now = vm_wall_ms()
    module = %{file: file, started_ms: now, tests_started: 0}

    {:noreply,
     %{state | boot_ms: state.boot_ms || now, modules: Map.put(state.modules, name, module)}}
  end

  def handle_cast({:test_started, %ExUnit.Test{module: module, name: name, tags: tags}}, state) do
    test = %{module: module, name: name, file: tags[:file], line: tags[:line]}

    modules =
      case state.modules do
        %{^module => entry} ->
          Map.put(state.modules, module, %{entry | tests_started: entry.tests_started + 1})

        modules ->
          modules
      end

    {:noreply, %{state | modules: modules, tests: Map.put(state.tests, {module, name}, test)}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{module: module, name: name} = test}, state) do
    file = test.tags[:file] || get_in(state.modules, [module, :file])
    files = add_time(state.files, file, :test_us, test.time)
    {:noreply, %{state | tests: Map.delete(state.tests, {module, name}), files: files}}
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{name: name}}, state) do
    case Map.pop(state.modules, name) do
      {nil, _modules} ->
        {:noreply, state}

      {entry, modules} ->
        wall = vm_wall_ms() - entry.started_ms

        {:noreply,
         %{state | modules: modules, files: add_time(state.files, entry.file, :wall_ms, wall)}}
    end
  end

  def handle_cast({:suite_finished, _times_us}, state) do
    write_timings(state, vm_wall_ms())
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  # --- Timings TSV ---------------------------------------------------------------

  defp add_time(files, nil, _key, _amount), do: files

  defp add_time(files, file, key, amount) do
    Map.update(
      files,
      file,
      Map.put(%{wall_ms: 0, test_us: 0}, key, amount),
      &Map.update!(&1, key, fn sum -> sum + amount end)
    )
  end

  defp write_timings(state, wall_ms) do
    case System.get_env("THREADLINE_PARTITION_TIMINGS_FILE") do
      path when path in [nil, ""] ->
        :ok

      path ->
        header = [
          "# ",
          @format,
          " partition=",
          env_or("MIX_TEST_PARTITION", "none"),
          " lane=",
          env_or("THREADLINE_CI_LANE", "local"),
          " boot_ms=",
          Integer.to_string(state.boot_ms || wall_ms),
          " wall_ms=",
          Integer.to_string(wall_ms),
          "\n"
        ]

        rows =
          state.files
          |> Enum.map(fn {file, times} -> {Path.relative_to_cwd(file), times} end)
          |> Enum.sort()
          |> Enum.map(fn {file, times} ->
            [
              file,
              "\t",
              Integer.to_string(times.wall_ms),
              "\t",
              Integer.to_string(div(times.test_us, 1000)),
              "\n"
            ]
          end)

        File.mkdir_p!(Path.dirname(path))
        File.write!(path, [header | rows])
    end
  end

  defp env_or(name, default) do
    case System.get_env(name) do
      value when value in [nil, ""] -> default
      value -> value
    end
  end

  # VM-relative wall time: milliseconds since this VM started.
  defp vm_wall_ms do
    {total_ms, _since_last_call} = :erlang.statistics(:wall_clock)
    total_ms
  end
end
