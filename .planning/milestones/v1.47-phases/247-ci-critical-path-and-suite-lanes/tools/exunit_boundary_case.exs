defmodule CanaryEventFormatter do
  use GenServer

  def init(_opts), do: {:ok, :ok}

  def handle_cast({:module_started, _module}, state) do
    CanaryEvents.record("module_started")
    {:noreply, state}
  end

  def handle_cast({:suite_finished, _times}, state) do
    CanaryEvents.record("suite_finished")
    {:noreply, state}
  end

  def handle_cast(_event, state), do: {:noreply, state}
end

defmodule CanaryEvents do
  def synthetic_trace_target, do: :ok

  def record(name) do
    now = System.monotonic_time(:millisecond)
    IO.puts("THREADLINE_EVENT|#{name}|#{now}")
    now
  end

  def monotonic_ns({monotonic_ns, _strict_order}), do: monotonic_ns

  def record_at(name, monotonic_ns) do
    timestamp_ms = System.convert_time_unit(monotonic_ns, :nanosecond, :millisecond)
    IO.puts("THREADLINE_EVENT|#{name}|#{timestamp_ms}")
  end

  def flush_trace_events(collector, timeout_ms \\ 5_000) do
    delivery_ref = :erlang.trace_delivered(:all)

    receive do
      {:trace_delivered, :all, ^delivery_ref} ->
        flush_ref = make_ref()
        send(collector, {:flush, self(), flush_ref})

        receive do
          {:collector_flushed, ^flush_ref, events} -> {:ok, events}
        after
          timeout_ms -> {:error, :collector_flush_timeout}
        end
    after
      timeout_ms -> {:error, :trace_delivery_timeout}
    end
  end

  def trace_collector(events \\ [], delay_ms \\ 0) do
    receive do
      {:trace_ts, _pid, :call, {ExUnit.Server, :add_async_module, [_module]}, timestamp} ->
        if delay_ms > 0, do: Process.sleep(delay_ms)
        event = {"registration_async", monotonic_ns(timestamp)}
        trace_collector([event | events], delay_ms)

      {:trace_ts, _pid, :call, {ExUnit.Server, :add_sync_module, [_module]}, timestamp} ->
        if delay_ms > 0, do: Process.sleep(delay_ms)
        event = {"registration_sync", monotonic_ns(timestamp)}
        trace_collector([event | events], delay_ms)

      {:trace_ts, _pid, :call, {CanaryEvents, :synthetic_trace_target, []}, timestamp} ->
        if delay_ms > 0, do: Process.sleep(delay_ms)
        event = {"registration_async", monotonic_ns(timestamp)}
        trace_collector([event | events], delay_ms)

      {:flush, from, ref} ->
        send(from, {:collector_flushed, ref, Enum.reverse(events)})
        trace_collector(events, delay_ms)

      {:stop, from, ref} ->
        send(from, {:collector_stopped, ref})

      _other ->
        trace_collector(events, delay_ms)
    end
  end
end

defmodule CanaryRunner do
  def main(["--compile-smoke"]) do
    compile_smoke()
  end

  def main(["--trace-self-test"]) do
    trace_self_test()
  end

  def main([case_path, mode, control]), do: run_case(case_path, mode, control)
  def main(_), do: System.halt(64)

  def compile_smoke do
    otp_version =
      :code.root_dir()
      |> to_string()
      |> Path.join("releases/#{:erlang.system_info(:otp_release)}/OTP_VERSION")
      |> File.read!()
      |> String.trim()

    IO.puts("THREADLINE_RUNTIME|#{System.version()}|#{otp_version}|#{:erlang.system_info(:system_architecture)}")
    IO.puts("THREADLINE_COMPILE_SMOKE|ok")
  end

  def trace_self_test do
    collector = spawn(fn -> CanaryEvents.trace_collector([], 25) end)
    :erlang.trace_pattern({CanaryEvents, :synthetic_trace_target, 0}, true, [])
    :erlang.trace(self(), true, [:call, :set_on_spawn, :strict_monotonic_timestamp, {:tracer, collector}])
    start_timestamp = System.monotonic_time(:nanosecond)
    child = spawn(fn -> CanaryEvents.synthetic_trace_target() end)
    monitor = Process.monitor(child)

    receive do
      {:DOWN, ^monitor, :process, ^child, :normal} -> :ok
      _ -> System.halt(74)
    after
      1_000 -> System.halt(74)
    end

    :erlang.trace(:all, false, [:call])
    :erlang.trace_pattern({CanaryEvents, :synthetic_trace_target, 0}, false, [])

    case flush_events(collector, 1_000) do
      {:ok, [{"registration_async", registration_ns}]} ->
        require_return_ns = System.monotonic_time(:nanosecond)

        if registration_ns < start_timestamp or registration_ns >= require_return_ns do
          System.halt(79)
        end

        stop_collector(collector, 1_000)
        IO.puts("trace plumbing self-test: PASS (captured occurrence timestamp precedes require_return)")

      _ -> System.halt(77)
    end
  end

  def run_case(case_path, _mode, control) do
    otp_version =
      :code.root_dir()
      |> to_string()
      |> Path.join("releases/#{:erlang.system_info(:otp_release)}/OTP_VERSION")
      |> File.read!()
      |> String.trim()

    runtime = %{
      elixir: System.version(),
      otp: otp_version,
      architecture: :erlang.system_info(:system_architecture) |> to_string()
    }

    unless runtime.elixir == "1.15.8" and runtime.otp == "26.2.5.21" and
             String.contains?(runtime.architecture, "aarch64") do
      IO.puts("THREADLINE_RUNTIME_INVALID|#{runtime.elixir}|#{runtime.otp}|#{runtime.architecture}")
      System.halt(72)
    end

    IO.puts("THREADLINE_RUNTIME|#{runtime.elixir}|#{runtime.otp}|#{runtime.architecture}")
    CanaryEvents.record("helper_start")
    Code.require_file("/probe/formatter.ex")
    if control == "pre_exunit", do: Process.sleep(2_000)

    collector = spawn(fn -> CanaryEvents.trace_collector() end)
    :erlang.trace_pattern({ExUnit.Server, :add_async_module, 1}, true, [])
    :erlang.trace_pattern({ExUnit.Server, :add_sync_module, 1}, true, [])
    # OTP strict_monotonic_timestamp supplies {monotonic_time(nanosecond), unique_integer} on :trace_ts messages.
    :erlang.trace(:all, true, [:call, :set_on_spawn, :strict_monotonic_timestamp, {:tracer, collector}])

    CanaryEvents.record("exunit_start")
    ExUnit.start(autorun: false, formatters: [Threadline.Test.PartitionMonitor, CanaryEventFormatter])
    task = ExUnit.async_run()
    CanaryEvents.record("require_start")
    Kernel.ParallelCompiler.require([case_path], [])
    flush_events!(collector)
    CanaryEvents.record("require_return")
    CanaryEvents.record("barrier_start")
    Process.sleep(2_000)
    CanaryEvents.record("barrier_release")
    ExUnit.await_run(task)

    :erlang.trace(:all, false, [:call])
    :erlang.trace_pattern({ExUnit.Server, :add_async_module, 1}, false, [])
    :erlang.trace_pattern({ExUnit.Server, :add_sync_module, 1}, false, [])
    flush_events!(collector)
    stop_collector(collector, 5_000)
  end

  def flush_events(collector, timeout_ms \\ 5_000), do: CanaryEvents.flush_trace_events(collector, timeout_ms)

  def flush_events!(collector) do
    case flush_events(collector) do
      {:ok, events} -> Enum.each(events, fn {name, timestamp_ns} -> CanaryEvents.record_at(name, timestamp_ns) end)
      {:error, reason} ->
        IO.puts("THREADLINE_TRACE_INVALID|#{reason}")
        System.halt(73)
    end
  end

  defp stop_collector(collector, timeout_ms) do
    stop_ref = make_ref()
    send(collector, {:stop, self(), stop_ref})
    receive do
      {:collector_stopped, ^stop_ref} -> :ok
    after
      timeout_ms ->
        IO.puts("THREADLINE_TRACE_INVALID|collector_stop_timeout")
        System.halt(76)
    end
  end
end

CanaryRunner.main(System.argv())
