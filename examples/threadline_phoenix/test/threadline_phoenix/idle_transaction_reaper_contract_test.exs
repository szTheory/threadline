defmodule ThreadlinePhoenix.IdleTransactionReaperContractTest do
  use ThreadlinePhoenix.DataCase, async: false

  @expected_ms 60_000

  test "the Repo declares the test-only idle transaction timeout" do
    parameters = Application.fetch_env!(:threadline_phoenix, ThreadlinePhoenix.Repo)[:parameters]

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
end
