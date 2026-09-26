defmodule Threadline.Capture.NoticeGuardTest do
  use ExUnit.Case, async: true

  alias Threadline.Test.NoticeGuard
  alias Threadline.Test.Repo

  @too_long "SELECT 1 AS " <> String.duplicate("c", 64)
  @at_limit "SELECT 1 AS " <> String.duplicate("c", 63)

  test "a 64-byte identifier is recorded once for the calling process" do
    Repo.query!(@too_long)

    assert [{%{code: "42622"}, query}] = NoticeGuard.take()
    assert query == @too_long
    assert NoticeGuard.take() == []
  end

  test "a 63-byte identifier records nothing" do
    Repo.query!(@at_limit)

    assert NoticeGuard.take() == []
  end

  test "a hit from a Task.async child is attributed to the test process" do
    Task.async(fn -> Repo.query!(@too_long) end) |> Task.await()

    assert [{%{code: "42622"}, @too_long}] = NoticeGuard.take()
  end

  test "take/0 never removes another process's hits" do
    parent = self()

    pid =
      spawn(fn ->
        Repo.query!(@too_long)
        send(parent, :recorded)

        receive do
          :take -> send(parent, {:taken, NoticeGuard.take()})
        end
      end)

    assert_receive :recorded, 5_000
    assert NoticeGuard.take() == []

    send(pid, :take)
    assert_receive {:taken, [{%{code: "42622"}, @too_long}]}, 5_000
  end

  test "the handler is attached for the whole suite" do
    assert NoticeGuard.attached?()
  end
end
