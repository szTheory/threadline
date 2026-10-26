defmodule Threadline.PartitionMonitorTest do
  # D-16(b): proves Threadline.Test.PartitionMonitor names an in-VM hang (a
  # hung test body or a hung setup_all) with file:line or module plus a stack,
  # and halts the VM. Each case builds a throwaway mix project in tmp_dir at
  # runtime (the hanging tests are never committed as *_test.exs files under
  # test/), compiles it, then runs `mix test` with the monitor attached and
  # THREADLINE_TEST_DEADLINE_MS=2000. Every subprocess is killed if it
  # outlives @run_timeout_ms, so a monitor that fails to halt cannot leave a
  # BEAM behind.
  use ExUnit.Case, async: false

  @moduletag :tmp_dir
  @moduletag timeout: 180_000

  @monitor_source Path.expand("../support/partition_monitor.ex", __DIR__)
  @deadline_ms "2000"
  @run_timeout_ms 60_000

  @hang_body_test """
  defmodule PmSandbox.HangBodyTest do
    use ExUnit.Case

    test "hangs in the body" do
      Process.sleep(:infinity)
      :ok
    end
  end
  """

  @hang_setup_all_test """
  defmodule PmSandbox.HangSetupAllTest do
    use ExUnit.Case

    setup_all do
      Process.sleep(:infinity)
      :ok
    end

    test "never runs" do
      :ok
    end
  end
  """

  @passing_test """
  defmodule PmSandbox.PassingTest do
    use ExUnit.Case

    test "passes" do
      assert 1 + 1 == 2
    end
  end
  """

  # A formatted stack frame, e.g. "    (elixir 1.15.8) lib/process.ex:294: Process.sleep/1".
  @sleep_frame ~r/^ +\([a-z_]+[^)]*\) [^\n]*:\d+: Process\.sleep\/1$/m

  test "a hung test body is named by file:line with its stack, and the VM halts", %{
    tmp_dir: dir
  } do
    sandbox!(dir, "test/hang_body_test.exs", @hang_body_test)

    {output, status} = run_sandbox(dir, "test/hang_body_test.exs", @deadline_ms)

    assert status != 0, output
    assert output =~ "HANG: in-flight:", output
    assert output =~ "test/hang_body_test.exs:4 test hangs in the body", output
    assert output =~ @sleep_frame, output
    assert output =~ "----- HANG: end -----", output
  end

  test "a hung setup_all is named by file and module with its stack, and the VM halts", %{
    tmp_dir: dir
  } do
    sandbox!(dir, "test/hang_setup_all_test.exs", @hang_setup_all_test)

    {output, status} = run_sandbox(dir, "test/hang_setup_all_test.exs", @deadline_ms)

    assert status != 0, output
    assert output =~ "HANG: in-flight:", output
    assert output =~ "test/hang_setup_all_test.exs PmSandbox.HangSetupAllTest (setup_all)", output
    assert output =~ @sleep_frame, output
    refute output =~ "never runs", output
  end

  test "without a deadline a passing suite exits 0 and prints no hang report", %{tmp_dir: dir} do
    sandbox!(dir, "test/passing_test.exs", @passing_test)

    {output, status} = run_sandbox(dir, "test/passing_test.exs", false)

    assert status == 0, output
    assert output =~ ~r/1 tests?, 0 failures/, output
    refute output =~ "HANG:", output
  end

  defp sandbox!(dir, test_file, test_source) do
    File.mkdir_p!(Path.join(dir, "lib"))
    File.mkdir_p!(Path.join(dir, "test"))

    File.write!(Path.join(dir, "mix.exs"), """
    defmodule PmSandbox.MixProject do
      use Mix.Project

      def project do
        [app: :pm_sandbox, version: "0.1.0", elixirc_paths: ["lib"], deps: []]
      end

      def application, do: [extra_applications: [:ex_unit]]
    end
    """)

    File.cp!(@monitor_source, Path.join(dir, "lib/partition_monitor.ex"))
    File.write!(Path.join(dir, "test/test_helper.exs"), "ExUnit.start()\n")
    File.write!(Path.join(dir, test_file), test_source)

    # Compile in its own VM so the deadline below measures only the test run.
    {output, status} = run(dir, ["compile"], false)
    assert status == 0, "sandbox compile failed:\n" <> output
  end

  defp run_sandbox(dir, test_file, deadline) do
    run(
      dir,
      [
        "test",
        test_file,
        "--formatter",
        "ExUnit.CLIFormatter",
        "--formatter",
        "Threadline.Test.PartitionMonitor"
      ],
      deadline
    )
  end

  # Runs `mix <args>` in the sandbox through a port so a run that outlives
  # @run_timeout_ms is killed (with its children) instead of leaking a BEAM.
  defp run(dir, args, deadline) do
    mix = System.find_executable("mix") || flunk("mix is not on PATH")

    env =
      [
        {"MIX_ENV", "test"},
        {"THREADLINE_TEST_DEADLINE_MS", deadline},
        {"MIX_EXS", false},
        {"MIX_BUILD_PATH", false},
        {"MIX_DEPS_PATH", false},
        {"MIX_LOCKFILE", false},
        {"MIX_TEST_PARTITION", false},
        {"THREADLINE_PARTITION_TIMINGS_FILE", false}
      ]
      |> Enum.map(fn
        {name, false} -> {String.to_charlist(name), false}
        {name, value} -> {String.to_charlist(name), String.to_charlist(value)}
      end)

    port =
      Port.open({:spawn_executable, mix}, [
        :binary,
        :exit_status,
        :stderr_to_stdout,
        :hide,
        args: args,
        cd: dir,
        env: env
      ])

    {:os_pid, os_pid} = Port.info(port, :os_pid)
    deadline_at = System.monotonic_time(:millisecond) + @run_timeout_ms
    collect(port, os_pid, deadline_at, [])
  end

  defp collect(port, os_pid, deadline_at, acc) do
    remaining = max(deadline_at - System.monotonic_time(:millisecond), 0)

    receive do
      {^port, {:data, data}} ->
        collect(port, os_pid, deadline_at, [acc, data])

      {^port, {:exit_status, status}} ->
        {IO.iodata_to_binary(acc), status}
    after
      remaining ->
        kill_tree(os_pid)
        output = IO.iodata_to_binary(acc)
        flunk("sandbox mix run did not exit within #{@run_timeout_ms} ms; killed it:\n" <> output)
    end
  end

  defp kill_tree(os_pid) do
    pid = Integer.to_string(os_pid)
    System.cmd("pkill", ["-KILL", "-P", pid], stderr_to_stdout: true)
    System.cmd("kill", ["-KILL", pid], stderr_to_stdout: true)
  end
end
