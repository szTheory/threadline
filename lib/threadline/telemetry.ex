defmodule Threadline.Telemetry do
  @moduledoc """
  Telemetry integration helpers for Threadline.

  Threadline emits five telemetry events:

  - `[:threadline, :transaction, :committed]` — after an `AuditTransaction` is
    committed. Automatically emitted (with `table_count: 0`) when
    `Threadline.record_action/2` succeeds. For accurate per-transaction counts,
    call `Threadline.Telemetry.transaction_committed/2` explicitly after a known
    DB transaction commit.

  - `[:threadline, :action, :recorded]` — after `Threadline.record_action/2`
    completes (success or failure).

  - `[:threadline, :health, :checked]` — after
    `Threadline.Health.trigger_coverage/1` returns. Measurements:
    `%{covered: integer, uncovered: integer, expected_uncovered: integer}`.
    The `expected_uncovered` measurement is an additive —
    subscribers that destructure only `covered` and `uncovered` keep working).

  - `[:threadline, :health, :checked, :error]` — sibling event emitted when a
    polled coverage check raises. Metadata: `%{error: message}`.
    The dashboard keeps the last-good snapshot and reschedules the next poll;
    this event lets adopters alert on transient or sustained failure.

  - `[:threadline, :health, :findings_checked]` — after
    `Threadline.Health.trigger_findings/1` returns. Measurements:
    `%{errors: integer, warnings: integer}`, counted over the returned list.

  Every emission in this library goes through a `@doc false` helper function
  in this module; `:telemetry.execute/3` and `:telemetry.span/3` are called
  only here. Every event this module can emit, along with its measurement
  and metadata keys, is held in an internal registry exposed through
  `__events__/0` (`@doc false`) — not a public `events/0` — for use by this
  library's own test suite.

  ## Usage

  Attach handlers in your application's `start/2` callback:

      :telemetry.attach(
        "my-app-audit",
        [:threadline, :action, :recorded],
        &MyApp.Instrumentation.handle_event/4,
        nil
      )
  """

  @events [
    %{
      name: [:threadline, :transaction, :committed],
      measurements: [:table_count],
      metadata: [],
      when: "an AuditTransaction is committed"
    },
    %{
      name: [:threadline, :action, :recorded],
      measurements: [:status],
      metadata: [],
      when: "Threadline.record_action/2 completes, whether it succeeds or fails"
    },
    %{
      name: [:threadline, :health, :checked],
      measurements: [:covered, :expected_uncovered, :uncovered],
      metadata: [],
      when: "Threadline.Health.trigger_coverage/1 returns"
    },
    %{
      name: [:threadline, :health, :checked, :error],
      measurements: [],
      metadata: [:error],
      when: "a polled coverage check raises"
    },
    %{
      name: [:threadline, :health, :findings_checked],
      measurements: [:errors, :warnings],
      metadata: [],
      when: "Threadline.Health.trigger_findings/1 returns"
    },
    %{
      name: [:threadline, :operator_surface, :authorize],
      measurements: [:result],
      metadata: [:path, :scope_keys],
      when: "an operator-surface mount or request is authorized, denied, or errors"
    },
    %{
      name: [:threadline, :operator_surface, :export_authorize],
      measurements: [:count, :result],
      metadata: [],
      when: "an export-specific authorization check raises"
    },
    %{
      name: [:threadline, :operator_surface, :actor_ref_mismatch],
      measurements: [:count],
      metadata: [],
      when: "the session actor and the scope-derived actor disagree"
    }
  ]

  @doc false
  def __events__, do: @events

  @doc """
  Emits `[:threadline, :transaction, :committed]` with the given table count.

  Call this after a DB transaction that you know produced `AuditTransaction`
  records, when you need accurate `table_count` measurements.

  ## Example

      {:ok, txn} = MyApp.Repo.transaction(fn ->
        # ... your writes ...
      end)
      Threadline.Telemetry.transaction_committed(txn, table_count: 3)
  """
  def transaction_committed(_transaction, opts \\ []) do
    table_count = Keyword.get(opts, :table_count, 0)
    :telemetry.execute([:threadline, :transaction, :committed], %{table_count: table_count}, %{})
  end

  @doc false
  def emit_action_recorded(status) do
    :telemetry.execute([:threadline, :action, :recorded], %{status: status}, %{})
  end

  @doc false
  def emit_transaction_committed_proxy do
    :telemetry.execute([:threadline, :transaction, :committed], %{table_count: 0}, %{})
  end

  @doc """
  Emits the `[:threadline, :health, :checked]` event with covered / uncovered /
  expected_uncovered measurements.

  The `expected_uncovered` measurement key is (additive). External
  subscribers that destructure only `%{covered: c, uncovered: u}` continue to
  work unchanged.
  """
  def emit_health_checked(covered, uncovered, expected_uncovered) do
    :telemetry.execute(
      [:threadline, :health, :checked],
      %{covered: covered, uncovered: uncovered, expected_uncovered: expected_uncovered},
      %{}
    )
  end

  @doc """
  Emits the `[:threadline, :health, :checked, :error]` event when a polled
  coverage check fails. The dashboard keeps the last-good snapshot and ALWAYS
  reschedules the next poll; this event lets adopters alert on transient or
  sustained failure.
  """
  def emit_health_checked_error(error_message) when is_binary(error_message) do
    :telemetry.execute(
      [:threadline, :health, :checked, :error],
      %{},
      %{error: error_message}
    )
  end

  @doc """
  Emits the `[:threadline, :health, :findings_checked]` event with error and
  warning counts, measured over the list `Threadline.Health.trigger_findings/1`
  is about to return.
  """
  def emit_findings_checked(errors, warnings) do
    :telemetry.execute(
      [:threadline, :health, :findings_checked],
      %{errors: errors, warnings: warnings},
      %{}
    )
  end

  @doc """
  Emits the `[:threadline, :operator_surface, :authorize]` event.

  `result` is the authorization outcome atom (`:granted`, `:denied`, or
  `:error`). `conn_or_nil` is either a `%Plug.Conn{}`, from which the route
  path is read, or `nil` when the caller has no conn (a LiveView mount).
  `scope` is the host-returned scope map, or `nil`/anything else when there is
  none. Metadata is `%{path: binary, scope_keys: [atom]}` — `scope_keys` holds
  only the scope map's KEYS, sorted, never its values, so no identity data is
  forwarded.
  """
  def emit_operator_surface_authorize(result, conn_or_nil, scope) when is_atom(result) do
    path = authorize_path(conn_or_nil)
    scope_keys = if is_map(scope), do: scope |> Map.keys() |> Enum.sort(), else: []

    :telemetry.execute(
      [:threadline, :operator_surface, :authorize],
      %{result: result},
      %{path: path, scope_keys: scope_keys}
    )
  end

  defp authorize_path(%Plug.Conn{} = conn), do: conn.request_path || ""
  defp authorize_path(_conn_or_nil), do: ""
end
