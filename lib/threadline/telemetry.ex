defmodule Threadline.Telemetry do
  @moduledoc """
  Telemetry integration helpers for Threadline.

  Threadline emits the following `:telemetry` events. No event carries row
  values, actor identifiers, correlation ids, or free-text reasons — with one
  narrow exception: `[:threadline, :retention, :purge, :exception]`'s
  `reason`/`stacktrace` metadata, forwarded verbatim from a raised exception
  for incident diagnosis (see the [Telemetry guide](guides/telemetry.md)'s
  "Keep row data out of your handlers" section before logging it anywhere
  durable). See the guide for an `attach_many` example per family, a
  `telemetry_metrics` example, handler-safety and cardinality warnings, and a
  recipe for observing Threadline's own repo queries through your host's
  `[:my_app, :repo, :query]` event.

  | Event | Measurements | Metadata | When emitted |
  |---|---|---|---|
  | `[:threadline, :transaction, :committed]` | `table_count` | — | an AuditTransaction is committed |
  | `[:threadline, :action, :recorded]` | `status` | — | Threadline.record_action/2 completes, whether it succeeds or fails |
  | `[:threadline, :health, :checked]` | `covered`, `expected_uncovered`, `uncovered` | — | Threadline.Health.trigger_coverage/1 returns |
  | `[:threadline, :health, :checked, :error]` | — | `exception` | a polled coverage check raises |
  | `[:threadline, :health, :findings_checked]` | `errors`, `warnings` | — | Threadline.Health.trigger_findings/1 returns |
  | `[:threadline, :operator_surface, :authorize]` | `result` | `path`, `scope_keys` | an operator-surface mount or request is authorized, denied, or errors |
  | `[:threadline, :operator_surface, :export_authorize]` | `count`, `result` | — | an export-specific authorization check raises |
  | `[:threadline, :operator_surface, :actor_ref_mismatch]` | `count` | — | the session actor and the scope-derived actor disagree |
  | `[:threadline, :export, :completed]` | `duration`, `row_count` | `format`, `truncated` | an export (eager CSV/JSON, the async orchestrator job, or the chunked operator-surface download) finishes successfully |
  | `[:threadline, :export, :failed]` | `duration`, `row_count` | `format`, `error_kind`, `exception` | an export (eager CSV/JSON, the async orchestrator job, or the chunked operator-surface download) fails |
  | `[:threadline, :retention, :purge, :start]` | `monotonic_time`, `system_time` | `dry_run`, `telemetry_span_context` | after purge/1's input checks pass, when the purge work begins |
  | `[:threadline, :retention, :purge, :stop]` | `batches_run`, `deleted_changes`, `deleted_transactions`, `duration`, `monotonic_time` | `dry_run`, `telemetry_span_context` | when the run or preview returns |
  | `[:threadline, :retention, :purge, :exception]` | `duration`, `monotonic_time` | `dry_run`, `kind`, `reason`, `stacktrace`, `telemetry_span_context` | when the database raises mid-run |
  | `[:threadline, :retention, :batch_purged]` | `deleted_changes`, `deleted_transactions`, `duration` | — | after a purge_loop step's change delete_all and full orphan drain both return, once per step including the terminating empty one |

  `[:threadline, :transaction, :committed]` is automatically emitted (with
  `table_count: 0`) when `Threadline.record_action/2` succeeds. For accurate
  per-transaction counts, call `Threadline.Telemetry.transaction_committed/2`
  explicitly after a known DB transaction commit.

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
      metadata: [:exception],
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
    },
    %{
      name: [:threadline, :export, :completed],
      measurements: [:duration, :row_count],
      metadata: [:format, :truncated],
      when:
        "an export (eager CSV/JSON, the async orchestrator job, or the chunked operator-surface download) finishes successfully"
    },
    %{
      name: [:threadline, :export, :failed],
      measurements: [:duration, :row_count],
      metadata: [:format, :error_kind, :exception],
      when:
        "an export (eager CSV/JSON, the async orchestrator job, or the chunked operator-surface download) fails"
    },
    %{
      name: [:threadline, :retention, :purge, :start],
      measurements: [:monotonic_time, :system_time],
      metadata: [:dry_run, :telemetry_span_context],
      when: "after purge/1's input checks pass, when the purge work begins"
    },
    %{
      name: [:threadline, :retention, :purge, :stop],
      measurements: [
        :batches_run,
        :deleted_changes,
        :deleted_transactions,
        :duration,
        :monotonic_time
      ],
      metadata: [:dry_run, :telemetry_span_context],
      when: "when the run or preview returns"
    },
    %{
      name: [:threadline, :retention, :purge, :exception],
      measurements: [:duration, :monotonic_time],
      metadata: [:dry_run, :kind, :reason, :stacktrace, :telemetry_span_context],
      exempt_metadata: [:kind, :reason, :stacktrace],
      when: "when the database raises mid-run"
    },
    %{
      name: [:threadline, :retention, :batch_purged],
      measurements: [:deleted_changes, :deleted_transactions, :duration],
      metadata: [],
      when:
        "after a purge_loop step's change delete_all and full orphan drain both return, once per step including the terminating empty one"
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

  Takes the raised exception struct itself, not a message. Metadata is
  `%{exception: module}` — the exception's struct module only. The message is
  intentionally not forwarded: exception messages can echo database values.
  """
  def emit_health_checked_error(exception) when is_exception(exception) do
    :telemetry.execute(
      [:threadline, :health, :checked, :error],
      %{},
      %{exception: exception.__struct__}
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

  @doc """
  Emits the `[:threadline, :operator_surface, :export_authorize]` event with
  `%{result: :error, count: 1}` measurements and no metadata, for an
  export-specific authorization callback that raised.
  """
  def emit_export_authorize_error do
    :telemetry.execute(
      [:threadline, :operator_surface, :export_authorize],
      %{result: :error, count: 1},
      %{}
    )
  end

  @doc """
  Emits the `[:threadline, :operator_surface, :actor_ref_mismatch]` event with
  `%{count: 1}` measurements and no metadata, as a pure incidence counter when
  the session actor and the scope-derived actor disagree.
  """
  def emit_actor_ref_mismatch do
    :telemetry.execute(
      [:threadline, :operator_surface, :actor_ref_mismatch],
      %{count: 1},
      %{}
    )
  end

  @doc """
  Emits the `[:threadline, :export, :completed]` event for one logical export
  that finished successfully.

  `format` is the user-facing export format (`:csv`, `:json`, or `:ndjson` —
  the async orchestrator job is always `:csv`). `row_count` is the number of
  rows returned or streamed. `truncated` is whether the export hit its row
  cap. `started_at` is a `System.monotonic_time/0` value captured by the
  caller before the export began; this helper computes `duration` from it.
  """
  def emit_export_completed(format, row_count, truncated, started_at)
      when format in [:csv, :json, :ndjson] and is_integer(row_count) and row_count >= 0 and
             is_boolean(truncated) and is_integer(started_at) do
    duration = System.monotonic_time() - started_at

    :telemetry.execute(
      [:threadline, :export, :completed],
      %{duration: duration, row_count: row_count},
      %{format: format, truncated: truncated}
    )
  end

  @doc """
  Emits the `[:threadline, :export, :failed]` event for one logical export
  that failed.

  `row_count` is the number of rows written or streamed before the failure
  (`0` for the eager functions, since they fail before returning anything).
  `error_kind` is one of `:exception`, `:client_closed`, `:storage_error`, or
  `:transaction_failed`. `exception` is the raised exception struct, or
  `nil` when the failure was not a raise — only the struct's module is
  forwarded, never its message, which can echo audited database values.
  `started_at` is the same `System.monotonic_time/0` value passed to
  `emit_export_completed/4`.
  """
  def emit_export_failed(format, row_count, error_kind, exception, started_at)
      when format in [:csv, :json, :ndjson] and is_integer(row_count) and row_count >= 0 and
             error_kind in [:exception, :client_closed, :storage_error, :transaction_failed] and
             (is_nil(exception) or is_exception(exception)) and is_integer(started_at) do
    duration = System.monotonic_time() - started_at
    exception_module = if exception, do: exception.__struct__, else: nil

    :telemetry.execute(
      [:threadline, :export, :failed],
      %{duration: duration, row_count: row_count},
      %{format: format, error_kind: error_kind, exception: exception_module}
    )
  end

  # Wraps a retention purge run (or dry-run preview) in a
  # `[:threadline, :retention, :purge]` span.
  #
  # Call this only after `Threadline.Retention.purge/1`'s input checks have
  # passed (`:repo` fetch, policy resolution, the disabled check, and cutoff
  # resolution) — a disabled or misconfigured call must emit nothing. `fun`
  # returns the purge result map (either `dry_run_result/4`'s preview or
  # `run_with_tracking/7`'s real result); start and stop metadata are both
  # `%{dry_run: dry_run?}` (`:telemetry` does not merge start metadata into
  # stop, so it is passed again), and the deleted-row counts are lifted into
  # stop measurements next to the automatic `duration`/`monotonic_time`. On a
  # raise mid-run, `:telemetry.span/3` emits `[:threadline, :retention, :purge,
  # :exception]` with `kind`/`reason`/`stacktrace` metadata and re-raises; the
  # return contract of `fun` is otherwise unchanged.
  @doc false
  def purge_span(dry_run?, fun) when is_boolean(dry_run?) and is_function(fun, 0) do
    :telemetry.span([:threadline, :retention, :purge], %{dry_run: dry_run?}, fn ->
      result = fun.()

      {result, Map.take(result, [:deleted_changes, :deleted_transactions, :batches_run]),
       %{dry_run: dry_run?}}
    end)
  end

  # Emits the `[:threadline, :retention, :batch_purged]` event for one
  # `purge_loop/7` step, after that step's change `delete_all` and full orphan
  # drain have both returned. `started_at` is a `System.monotonic_time/0`
  # value captured at the top of the step; this helper computes `duration`
  # from it. Fires for every step, including the terminating empty one, so
  # the event count equals the run's `batches_run`.
  @doc false
  def emit_batch_purged(deleted_changes, deleted_transactions, started_at)
      when is_integer(deleted_changes) and deleted_changes >= 0 and
             is_integer(deleted_transactions) and deleted_transactions >= 0 and
             is_integer(started_at) do
    duration = System.monotonic_time() - started_at

    :telemetry.execute(
      [:threadline, :retention, :batch_purged],
      %{
        deleted_changes: deleted_changes,
        deleted_transactions: deleted_transactions,
        duration: duration
      },
      %{}
    )
  end
end
