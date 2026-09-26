defmodule Threadline.Test.NoticeGuard do
  @moduledoc """
  Fails the test suite when PostgreSQL truncates an identifier.

  PostgreSQL silently cuts any identifier longer than 63 bytes and only says
  so with a NOTICE (SQLSTATE `42622`, name_too_long). Truncation is how two
  tables' capture function names once resolved to the same object, so the
  suite treats every such NOTICE as a failure.

  A telemetry handler on `[:threadline, :test, :repo, :query]` records each
  `42622` message Postgrex returns. Messages are matched on the SQLSTATE code
  only, never on message text, which depends on `lc_messages`.

  Hits are keyed by the process that started the work: the root of
  `$callers` when present (so a migration run inside `Task.async` belongs to
  the test that ran it), otherwise `self()`.

  A test that raises a truncation on purpose must drain it with `take/0` and
  assert the exact hit it expected. `take/0` only removes the calling
  process's hits, so it cannot hide another test's truncation.

  At the end of the suite `verify!/1` prints any undrained hit, or notes that
  the handler was detached (telemetry detaches a handler that raises), and
  makes the VM exit non-zero.

  Coverage limits: only queries through `Threadline.Test.Repo` are observed.
  Raw Postgrex sessions (such as the advisory-lock connections in the async
  helpers), nested `mix` processes, and the example app's repo are not.
  """

  @table :threadline_notice_guard
  @handler_id "threadline-notice-guard"
  @event [:threadline, :test, :repo, :query]
  @code "42622"

  @doc "Creates the hit table and attaches the telemetry handler."
  def attach! do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:duplicate_bag, :public, :named_table, write_concurrency: true])
    end

    :ok = :telemetry.attach(@handler_id, @event, &__MODULE__.handle/4, nil)
  end

  @doc false
  def handle(_event, _measurements, metadata, _config) do
    case metadata do
      %{result: {:ok, %Postgrex.Result{messages: messages}}} when is_list(messages) ->
        for %{code: @code} = message <- messages do
          :ets.insert(@table, {owner(), message, Map.get(metadata, :query)})
        end

        :ok

      _ ->
        :ok
    end
  rescue
    _ -> :ok
  end

  defp owner, do: List.last(Process.get(:"$callers", [])) || self()

  @doc "Removes and returns the hits recorded for `owner` as `[{message, query}]`."
  def take(owner \\ self()) do
    @table
    |> :ets.take(owner)
    |> Enum.map(fn {_owner, message, query} -> {message, query} end)
  end

  @doc "True when the telemetry handler is still attached."
  def attached? do
    @event
    |> :telemetry.list_handlers()
    |> Enum.any?(&(&1.id == @handler_id))
  end

  @doc "`ExUnit.after_suite/1` callback: reports undrained hits and fails the run."
  def verify!(_suite_result) do
    hits = remaining_hits()
    attached = attached?()

    if hits != [] or not attached do
      IO.puts(:stderr, report(hits, attached))
      System.at_exit(fn _ -> exit({:shutdown, 1}) end)
    end

    :ok
  end

  defp remaining_hits do
    if :ets.whereis(@table) == :undefined, do: [], else: :ets.tab2list(@table)
  end

  defp report(hits, attached) do
    lines =
      Enum.map(hits, fn {owner, message, query} ->
        text = Map.get(message, :message, inspect(message))
        "  * #{Map.get(message, :code)} #{text}\n    from #{inspect(owner)}: #{snippet(query)}"
      end)

    detached =
      if attached,
        do: [],
        else: ["  * the truncation handler was detached, so later queries went unobserved"]

    Enum.join(
      [
        "",
        "identifier truncation (SQLSTATE 42622): PostgreSQL shortened an identifier " <>
          "longer than 63 bytes during the test suite."
      ] ++ lines ++ detached ++ [""],
      "\n"
    )
  end

  defp snippet(query) when is_binary(query) do
    if byte_size(query) > 200, do: binary_part(query, 0, 200) <> "...", else: query
  end

  defp snippet(query), do: inspect(query)
end
