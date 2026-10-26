defmodule Threadline.Test.PartitionMonitor do
  @moduledoc """
  CI-only ExUnit formatter for the partitioned test runner.

  `bin/ci-test-partitions` is the only caller that attaches it. Every
  partition's `mix test` gets
  `--formatter ExUnit.CLIFormatter --formatter Threadline.Test.PartitionMonitor`,
  so the normal CLI output is unchanged. Plain `mix test`, the `mix.exs`
  aliases and `test/test_helper.exs` never attach it.

  ## Timings

  With `THREADLINE_PARTITION_TIMINGS_FILE` set, at `:suite_finished` it
  writes a `threadline.partition-timings/1` TSV that
  `bin/ci-test-partitions --ingest-weights` turns into
  `test/partition_weights.txt`. The header is

      # threadline.partition-timings/1 partition=<i> lane=<lane> boot_ms=<ms> wall_ms=<ms>

  where `lane` is `THREADLINE_CI_LANE` (`local` when unset or empty),
  `boot_ms` is the VM wall time at the first `:module_started` and `wall_ms`
  the VM wall time at `:suite_finished`. Then one row per test file:
  `<relative file>\\t<wall_ms>\\t<test_ms>`, where `wall_ms` sums each of the
  file's modules from `:module_started` to `:module_finished` and `test_ms`
  sums the file's `ExUnit.Test` times.

  ## Hang report

  With `THREADLINE_TEST_DEADLINE_MS` set to a positive integer, a watcher
  process holds the deadline. When the VM has run that many milliseconds
  (VM-relative, `:erlang.statistics(:wall_clock)`, so boot and file loading
  count), it prints a block that starts `HANG: in-flight:` and names each
  running test as `<file>:<line> <test name>`, each module still in
  `setup_all` as `<file> <Module> (setup_all)`, or
  `suite_finished seen; VM did not exit`. It then prints, for the in-flight
  test and module processes first and then any other process that is not
  idle (at most 200 in all), only `current_stacktrace`, `registered_name`,
  `status` and `message_queue_len` (never process dictionaries, messages or
  state), and halts the VM with status 1.

  The watcher is a plain `spawn`, NOT linked to this formatter: ExUnit stops
  every formatter with `GenServer.stop/3` right after `:suite_finished`, so a
  deadline held here would die exactly when a VM that will not exit needs it.
  The formatter sends the watcher a snapshot after every event it handles.

  `:sigquit` (ExUnit's own SIGQUIT abort) prints the same blocks without
  halting; the runner halts the VM itself.

  It handles only `:module_started`, `:test_started`, `:test_finished`,
  `:module_finished`, `:suite_finished` and `:sigquit`, and ignores every
  other event (including the deprecated `:case_started`/`:case_finished` and
  `:max_failures_reached`). It uses only struct fields present on Elixir
  1.15.
  """

  use GenServer

  @format "threadline.partition-timings/1"
  @poll_ms 250
  @process_cap 200

  @impl GenServer
  def init(_opts) do
    watcher =
      case deadline_ms() do
        nil ->
          nil

        deadline ->
          spawn(fn -> watch(deadline, %{tests: %{}, modules: %{}, suite_finished: false}) end)
      end

    {:ok, %{boot_ms: nil, modules: %{}, tests: %{}, files: %{}, watcher: watcher}}
  end

  @impl GenServer
  def handle_cast({:module_started, %ExUnit.TestModule{name: name, file: file}}, state) do
    now = vm_wall_ms()
    module = %{file: file, started_ms: now, tests_started: 0}

    notify(%{state | boot_ms: state.boot_ms || now, modules: Map.put(state.modules, name, module)})
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

    notify(%{state | modules: modules, tests: Map.put(state.tests, {module, name}, test)})
  end

  def handle_cast({:test_finished, %ExUnit.Test{module: module, name: name} = test}, state) do
    file = test.tags[:file] || get_in(state.modules, [module, :file])
    files = add_time(state.files, file, :test_us, test.time)
    notify(%{state | tests: Map.delete(state.tests, {module, name}), files: files})
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{name: name}}, state) do
    case Map.pop(state.modules, name) do
      {nil, _modules} ->
        {:noreply, state}

      {entry, modules} ->
        wall = vm_wall_ms() - entry.started_ms

        notify(%{
          state
          | modules: modules,
            files: add_time(state.files, entry.file, :wall_ms, wall)
        })
    end
  end

  def handle_cast({:suite_finished, _times_us}, state) do
    write_timings(state, vm_wall_ms())
    if state.watcher, do: send(state.watcher, :suite_finished)
    {:noreply, state}
  end

  def handle_cast({:sigquit, current}, state) do
    current = List.wrap(current)

    tests =
      for %ExUnit.Test{module: module, name: name, tags: tags} <- current,
          into: %{},
          do:
            {{module, name}, %{module: module, name: name, file: tags[:file], line: tags[:line]}}

    modules =
      for %ExUnit.TestModule{name: name, file: file} <- current,
          into: %{},
          do: {name, %{file: file, started_ms: 0, tests_started: 0}}

    print_report(%{tests: tests, modules: modules, suite_finished: false}, "sigquit")
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}

  defp notify(%{watcher: nil} = state), do: {:noreply, state}

  defp notify(state) do
    send(state.watcher, {:snapshot, state.tests, state.modules})
    {:noreply, state}
  end

  # --- Watcher (unlinked; outlives the formatter) ----------------------------------

  defp watch(deadline, snapshot) do
    now = vm_wall_ms()

    if now >= deadline do
      print_report(snapshot, "deadline #{deadline} ms")
      System.halt(1)
    else
      receive do
        {:snapshot, tests, modules} ->
          watch(deadline, %{snapshot | tests: tests, modules: modules})

        :suite_finished ->
          watch(deadline, %{snapshot | suite_finished: true})
      after
        min(@poll_ms, deadline - now) -> watch(deadline, snapshot)
      end
    end
  end

  defp print_report(snapshot, reason) do
    in_flight = in_flight_lines(snapshot)
    in_flight_modules = in_flight_modules(snapshot)

    IO.write(:user, [
      "\n----- HANG: in-flight: (#{reason}, VM wall #{vm_wall_ms()} ms) -----\n",
      Enum.map(in_flight, &["  ", &1, "\n"]),
      "----- HANG: processes -----\n",
      Enum.map(hang_processes(in_flight_modules), &format_process/1),
      "----- HANG: end -----\n"
    ])
  end

  defp in_flight_lines(snapshot) do
    test_lines =
      snapshot.tests
      |> Map.values()
      |> Enum.sort_by(&{&1.file || "", &1.line || 0, &1.name})
      |> Enum.map(&"#{relative(&1.file)}:#{&1.line} #{&1.name}")

    running_modules = MapSet.new(Map.values(snapshot.tests), & &1.module)

    module_lines =
      snapshot.modules
      |> Enum.reject(fn {name, _entry} -> MapSet.member?(running_modules, name) end)
      |> Enum.sort_by(fn {name, entry} -> {entry.file || "", inspect(name)} end)
      |> Enum.map(fn
        {name, %{tests_started: 0} = entry} ->
          "#{relative(entry.file)} #{inspect(name)} (setup_all)"

        {name, entry} ->
          "#{relative(entry.file)} #{inspect(name)} (module open, no test running)"
      end)

    suite_lines =
      if snapshot.suite_finished, do: ["suite_finished seen; VM did not exit"], else: []

    case test_lines ++ module_lines ++ suite_lines do
      [] -> ["nothing in flight (no test module running)"]
      lines -> lines
    end
  end

  defp in_flight_modules(snapshot) do
    snapshot.tests
    |> Map.values()
    |> Enum.map(& &1.module)
    |> Enum.concat(Map.keys(snapshot.modules))
    |> MapSet.new()
  end

  # In-flight test and module processes first (any process whose stack has a
  # frame from an in-flight test module or from ExUnit.Runner: test bodies,
  # setup_all processes and the module processes that wait on them), then any
  # other process that is not idle. Capped at @process_cap.
  defp hang_processes(in_flight_modules) do
    watched = MapSet.put(in_flight_modules, ExUnit.Runner)

    infos =
      Process.list()
      |> List.delete(self())
      |> Enum.flat_map(fn pid ->
        case Process.info(pid, [
               :current_stacktrace,
               :registered_name,
               :status,
               :message_queue_len
             ]) do
          nil -> []
          info -> [{pid, Map.new(info)}]
        end
      end)

    {in_flight, rest} =
      Enum.split_with(infos, fn {_pid, info} ->
        Enum.any?(info.current_stacktrace, fn {module, _fun, _arity, _location} ->
          MapSet.member?(watched, module)
        end)
      end)

    busy =
      Enum.filter(rest, fn {_pid, info} ->
        info.status != :waiting or info.message_queue_len > 0
      end)

    Enum.take(in_flight ++ busy, @process_cap)
  end

  defp format_process({pid, info}) do
    name =
      case info.registered_name do
        [] -> ""
        name -> " registered_name=#{inspect(name)}"
      end

    [
      "#{inspect(pid)}#{name} status=#{info.status} message_queue_len=#{info.message_queue_len}\n",
      Exception.format_stacktrace(info.current_stacktrace)
    ]
  end

  defp deadline_ms do
    with value when is_binary(value) <- System.get_env("THREADLINE_TEST_DEADLINE_MS"),
         {ms, ""} when ms > 0 <- Integer.parse(String.trim(value)) do
      ms
    else
      _ -> nil
    end
  end

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
          |> Enum.map(fn {file, times} -> {relative(file), times} end)
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

  defp relative(nil), do: "unknown"
  defp relative(file), do: Path.relative_to_cwd(file)

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
