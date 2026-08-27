defmodule Threadline.ZeroSkipsContractTest do
  @moduledoc """
  Phase 198 (D-05) anti-laundering cap, asserted mechanically rather than
  promised in prose.

  Retiring a red test baseline honestly means fixing each failure on its
  merits — as a real bug, a rewritten assertion, a setup-path fix, or a
  deletion with a recorded admission in `198-TRIAGE.md`. Tagging a failure out
  of the run produces the same green summary line while destroying the very
  coverage that summary is supposed to attest to. This guard makes that route
  fail loudly.

  Two invariants:

    1. No file under `test/` carries a test-level or suite-level skip tag.
    2. The ExUnit exclude configuration carries nothing beyond the single
       PgBouncer topology tag, which is a genuine environment gate (those tests
       require PgBouncer plus bootstrap DDL) rather than a retired failure.
  """

  use ExUnit.Case, async: true

  @test_glob "test/**/*_test.exs"

  @topology_tag :pgbouncer_topology

  # The needles below are assembled at runtime instead of written as literals
  # because THIS FILE is itself matched by the glob it scans. A literal skip tag
  # in this source would make the guard report itself as an offender, and the
  # natural "fix" for that would be to exempt this file from its own scan —
  # precisely the laundering the guard exists to prevent. Concatenation keeps
  # the gate self-consistent: it can never be satisfied by exempting itself.
  defp skip_needles do
    attr = "@"
    test_level = attr <> "tag"
    suite_level = attr <> "module" <> "tag"

    for prefix <- [test_level, suite_level],
        suffix <- [" :skip", " skip:"],
        do: prefix <> suffix
  end

  defp test_files, do: Path.wildcard(@test_glob)

  test "no test file carries a skip tag (D-05 zero-exclusions cap)" do
    files = test_files()

    assert files != [],
           "no files matched #{@test_glob} — the glob is broken. A broken glob would " <>
             "let this guard pass vacuously while every skip tag in the suite went " <>
             "unnoticed, which is worse than having no guard at all."

    offenders =
      for path <- files,
          source = File.read!(path),
          needle <- skip_needles(),
          String.contains?(source, needle),
          do: {Path.relative_to_cwd(path), needle}

    assert offenders == [],
           "these test files carry a skip tag, violating the Phase 198 zero-exclusions " <>
             "cap: #{inspect(offenders)}. Fix the test on its merits, or delete it and " <>
             "record the dropped coverage in " <>
             ".planning/phases/198-green-bringup/198-TRIAGE.md — do not tag it out of " <>
             "the run to manufacture a green summary."
  end

  test "the ExUnit exclude list carries nothing beyond the topology gate (D-05)" do
    exclude = ExUnit.configuration()[:exclude]

    # test/test_helper.exs drops the exclusion when the suite is deliberately run
    # against a PgBouncer topology, so both shapes are legitimate. What is never
    # legitimate is a third tag: that is how a retired failure gets excluded.
    expected =
      if System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1",
        do: [],
        else: [{@topology_tag, true}]

    assert exclude == expected,
           "unexpected ExUnit exclude configuration #{inspect(exclude)} (expected " <>
             "#{inspect(expected)}). The only sanctioned exclusion is #{inspect(@topology_tag)}, " <>
             "a real environment gate. Excluding a tag to retire a failing test is the " <>
             "laundering Phase 198 caps at zero."
  end
end
