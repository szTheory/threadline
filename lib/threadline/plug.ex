defmodule Threadline.Plug do
  @moduledoc """
  Plug that extracts `AuditContext` from a `Plug.Conn` and stores it in
  `conn.assigns[:audit_context]`.

  ## Usage

      # In a Phoenix router pipeline or endpoint:
      plug Threadline.Plug

      # With actor extraction (recommended):
      plug Threadline.Plug, actor_fn: &MyApp.Auth.to_actor_ref/1

  ## Options

  - `:actor_fn` — a function `(Plug.Conn.t() -> ActorRef.t() | nil)` that
    extracts the current actor from the conn. Called during `call/2`. If omitted,
    `audit_context.actor_ref` will be nil.

  ## What is extracted

  - `actor_ref` — result of `:actor_fn` (or nil)
  - `request_id` — from `x-request-id` header, then `conn.assigns[:request_id]`,
    then nil
  - `correlation_id` — from `x-correlation-id` header, or nil
  - `remote_ip` — from `conn.remote_ip`, formatted as a dotted-decimal string

  ## PgBouncer note

  This Plug does not call `SET` / `SET LOCAL` on the database connection. Request
  metadata lives on `conn.assigns` only. This design is safe for PgBouncer
  transaction-mode pooling.

  ## PostgreSQL bridge (CTX-03)

  To populate `audit_transactions.actor_ref` from capture triggers, the host
  must set a **transaction-local** GUC inside the same `Ecto.Repo.transaction/1`
  as audited writes, **before** the first row change in that transaction:

      json = Threadline.Semantics.ActorRef.to_map(actor_ref) |> Jason.encode!()

      Repo.transaction(fn ->
        Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
        # ... audited writes here ...
      end)

  The trigger reads `threadline.actor_ref` via `current_setting` only; it never
  calls `set_config` itself (see `gate-01-01.md`). See
  `test/threadline/capture/trigger_context_test.exs` for the contract example.
  """

  @behaviour Plug

  import Plug.Conn, only: [get_req_header: 2, assign: 3]

  alias Threadline.Semantics.AuditContext

  @impl Plug
  def init(opts) do
    %{
      actor_fn: Keyword.get(opts, :actor_fn)
    }
  end

  @impl Plug
  def call(conn, %{actor_fn: actor_fn}) do
    context = %AuditContext{
      actor_ref: extract_actor(conn, actor_fn),
      request_id: extract_request_id(conn),
      correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
      remote_ip: format_ip(conn.remote_ip)
    }

    assign(conn, :audit_context, context)
  end

  defp extract_actor(_conn, nil), do: nil
  defp extract_actor(conn, fun) when is_function(fun, 1), do: fun.(conn)

  defp extract_request_id(conn) do
    case get_req_header(conn, "x-request-id") do
      [id | _] -> id
      [] -> conn.assigns[:request_id]
    end
  end

  defp format_ip(nil), do: nil

  defp format_ip(ip) when is_tuple(ip) do
    ip |> :inet.ntoa() |> to_string()
  end

  defp format_ip(ip) when is_binary(ip), do: ip
end
