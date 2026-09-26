# Run only by explicit path, from
# test/threadline/capture/notice_guard_canary_test.exs. It lives outside test/,
# so the default suite never runs it and it is not held to test-file naming.
#
# With THREADLINE_TRUNCATION_GUARD_CANARY=1 it raises one identifier-truncation
# notice and deliberately leaves it undrained, so the truncation guard must make
# `mix test` exit non-zero. Without the flag it does nothing and passes.
defmodule Threadline.NoticeGuardCanary do
  use ExUnit.Case, async: false

  alias Threadline.Test.Repo

  test "leaves an identifier-truncation notice undrained when the canary flag is set" do
    if System.get_env("THREADLINE_TRUNCATION_GUARD_CANARY") == "1" do
      Repo.query!("SELECT 1 AS " <> String.duplicate("c", 64))
    end
  end
end
