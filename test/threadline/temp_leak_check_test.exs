defmodule Threadline.TempLeakCheckTest do
  @moduledoc """
  Offline behavior tests of `bin/verify-temp-leaks`, driven through a fake
  `mix` binary (the `MIX_BIN` seam), so the full matrix runs in the default
  `mix test` lane with no need to run the real suite underneath it.

  Each case sets the script's own `TMPDIR` to a subdirectory of this test's
  ExUnit `tmp_dir`, so the private directory `bin/verify-temp-leaks` creates
  via `mktemp -d` is both observable (for the leftover-cleanup assertion) and
  cleaned up automatically once the test process exits.
  """
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  @script Path.expand("../../bin/verify-temp-leaks", __DIR__)

  # Writes a fake `mix` that: (a) logs `$*` to CALL_LOG, (b) touches
  # `$TMPDIR/<leak_name>` when `:leak_name` is given (landing inside the
  # script's own private TMPDIR, since the script overrides TMPDIR for the
  # child process it spawns), and (c) exits `:exit_status` (default 0).
  defp fake_mix(root, opts) do
    path = Path.join(root, "mix")
    leak_name = Keyword.get(opts, :leak_name)
    exit_status = Keyword.get(opts, :exit_status, 0)
    log = Keyword.fetch!(opts, :log)

    leak_line =
      if leak_name do
        ~s(  printf '' > "$TMPDIR/#{leak_name}"\n)
      else
        ""
      end

    File.write!(path, """
    #!/usr/bin/env bash
    set -u
    printf '%s\\n' "$*" >> "#{log}"
    #{leak_line}exit #{exit_status}
    """)

    File.chmod!(path, 0o755)
    path
  end

  defp run(scratch_dir, args, opts) do
    log = Path.join(scratch_dir, "call_log")
    File.write!(log, "")
    mix = fake_mix(scratch_dir, Keyword.put(opts, :log, log))

    script_tmpdir = Path.join(scratch_dir, "script-tmpdir")
    File.mkdir_p!(script_tmpdir)

    {output, status} =
      System.cmd(@script, args,
        env: [{"MIX_BIN", mix}, {"TMPDIR", script_tmpdir}],
        stderr_to_stdout: true
      )

    %{
      output: output,
      status: status,
      log: File.read!(log),
      script_tmpdir: script_tmpdir
    }
  end

  # The private directory bin/verify-temp-leaks creates always matches
  # `threadline-temp-leak-check.*` under the TMPDIR it was given. After the
  # script exits (its EXIT trap always fires), nothing matching that glob
  # should remain — leak or no leak, pass or fail.
  defp assert_private_dir_gone!(result) do
    assert Path.wildcard(Path.join(result.script_tmpdir, "threadline-temp-leak-check.*")) == []
  end

  test "a fake mix that leaves an entry makes the script exit 1 and print LEAK", %{
    tmp_dir: tmp_dir
  } do
    result = run(tmp_dir, [], leak_name: "leaked-entry")

    assert result.status == 1
    assert result.output =~ "LEAK leaked-entry"
    assert_private_dir_gone!(result)
  end

  test "a fake mix that writes nothing and exits 0 makes the script exit 0 with the 0-entries line",
       %{tmp_dir: tmp_dir} do
    result = run(tmp_dir, [], [])

    assert result.status == 0
    assert result.output =~ "verify-temp-leaks: 0 entries left in the private TMPDIR"
    refute result.output =~ "LEAK "
    assert_private_dir_gone!(result)
  end

  test "a fake mix that exits 3 and writes nothing makes the script exit 3", %{tmp_dir: tmp_dir} do
    result = run(tmp_dir, [], exit_status: 3)

    assert result.status == 3
    refute result.output =~ "LEAK "
    assert_private_dir_gone!(result)
  end

  test "a fake mix that exits 3 and leaves an entry makes the script exit non-zero and still print LEAK",
       %{tmp_dir: tmp_dir} do
    result = run(tmp_dir, [], exit_status: 3, leak_name: "leftover-on-failure")

    assert result.status != 0
    assert result.output =~ "LEAK leftover-on-failure"
    assert_private_dir_gone!(result)
  end

  test "arguments pass through to mix test", %{tmp_dir: tmp_dir} do
    result = run(tmp_dir, ["test", "some/file_test.exs"], [])

    assert result.status == 0
    assert result.log =~ "test some/file_test.exs"
    assert_private_dir_gone!(result)
  end

  test "the private TMPDIR is gone after every case, clean or leaked", %{tmp_dir: tmp_dir} do
    clean = run(tmp_dir, [], [])
    leaked = run(tmp_dir, [], leak_name: "still-here")

    assert clean.status == 0
    assert leaked.status == 1
    assert_private_dir_gone!(clean)
    assert_private_dir_gone!(leaked)
  end
end
