defmodule ThreadlinePhoenix.Demo.RetentionTailEnvContractTest do
  use ExUnit.Case, async: true

  test "retention seeding restores both present and absent configuration states" do
    source = File.read!("lib/threadline_phoenix/demo/seed/retention_tail.ex")

    assert source =~ "Application.fetch_env(:threadline, :retention)"
    assert source =~ "{:ok, value} -> Application.put_env(:threadline, :retention, value)"
    assert source =~ ":error -> Application.delete_env(:threadline, :retention)"

    refute source =~ "prior_retention_env || []",
           "coercing an absent setting to [] changes Application.fetch_env/2 semantics"
  end
end
