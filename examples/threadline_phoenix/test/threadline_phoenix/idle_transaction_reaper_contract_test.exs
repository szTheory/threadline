defmodule ThreadlinePhoenix.IdleTransactionReaperContractTest do
  use ThreadlinePhoenix.DataCase, async: false

  # The reaper clears sessions abandoned idle inside a transaction so their locks
  # cannot wedge a later deterministic demo reset. Its value is not arbitrary: it
  # must be strictly below the deadline of the test it is protecting, or it fires
  # at the same instant the waiter gives up and can never help. An equal 60_000
  # is what made DemoContractTest's reset-then-seed test flake (1 failure in 9
  # isolated runs) with an ExUnit.TimeoutError while parked server-side in
  # Demo.Seed.Exports.run/1 -> insert_all.
  @expected_ms 20_000

  # ExUnit's default per-test timeout; test_helper.exs does not override it.
  @exunit_timeout_ms 60_000

  defp repo_config, do: Application.fetch_env!(:threadline_phoenix, ThreadlinePhoenix.Repo)

  test "the Repo declares the test-only idle transaction timeout" do
    parameters = repo_config()[:parameters]

    assert parameters[:idle_in_transaction_session_timeout] == Integer.to_string(@expected_ms)
  end

  test "a live Repo session applies the idle transaction timeout" do
    %{rows: [[value]]} = Repo.query!("SHOW idle_in_transaction_session_timeout", [])

    %{rows: [[milliseconds]]} =
      Repo.query!(
        "SELECT setting::bigint FROM pg_settings WHERE name = 'idle_in_transaction_session_timeout'",
        []
      )

    assert milliseconds == @expected_ms,
           "expected #{@expected_ms}ms, got #{milliseconds}ms (SHOW reports #{inspect(value)})"
  end

  test "the reaper deadline stays strictly below the deadlines it protects" do
    config = repo_config()

    reaper_ms =
      config[:parameters][:idle_in_transaction_session_timeout] |> String.to_integer()

    assert reaper_ms < config[:ownership_timeout],
           "idle_in_transaction_session_timeout (#{reaper_ms}ms) must be strictly below " <>
             "ownership_timeout (#{config[:ownership_timeout]}ms) — at an equal or greater " <>
             "deadline the reaper cannot unwedge a blocked query before its owner times out"

    assert reaper_ms < config[:timeout],
           "idle_in_transaction_session_timeout (#{reaper_ms}ms) must be strictly below " <>
             "the Repo query timeout (#{config[:timeout]}ms)"

    assert reaper_ms < @exunit_timeout_ms,
           "idle_in_transaction_session_timeout (#{reaper_ms}ms) must be strictly below " <>
             "the ExUnit per-test timeout (#{@exunit_timeout_ms}ms)"
  end
end
