defmodule Threadline.Plug do
  @moduledoc """
  Plug that extracts `AuditContext` from a `Plug.Conn` and stores it in
  `conn.assigns[:audit_context]`.

  ## Usage

      # In a Phoenix router pipeline or endpoint:
      plug Threadline.Plug

      # With actor extraction:
      plug Threadline.Plug, actor_fn: &MyApp.Auth.to_actor_ref/1

      # With additive request-context overrides:
      plug Threadline.Plug,
        actor_fn: &MyApp.Auth.to_actor_ref/1,
        context_overrides_fn: &MyApp.Auth.audit_context_overrides/1

  ## Options

  - `:actor_fn` — a function `(Plug.Conn.t() -> ActorRef.t() | nil)` that
    extracts the current actor from the conn. Called during `call/2`. If omitted,
    `audit_context.actor_ref` will be nil.
  - `:context_overrides_fn` — a function `(Plug.Conn.t() -> map())` that returns
    additive `:request_id` and `:correlation_id` values only. `Threadline.Plug`
    derives those values from headers and conn state first; this callback can only
    fill missing values and cannot replace actor identity or `remote_ip`. Unknown
    keys and non-map returns raise `ArgumentError`.

  ## What is extracted

  - `actor_ref` — result of `:actor_fn` (or nil)
  - `request_id` — from `x-request-id` header, then `conn.assigns[:request_id]`,
    then nil
  - `correlation_id` — from `x-correlation-id` header, or nil
  - `remote_ip` — from `conn.remote_ip`, formatted as a dotted-decimal string

  When `:context_overrides_fn` is configured, its return value is merged after
  baseline extraction. Explicit header or conn-derived `request_id` and
  `correlation_id` values always win; override values only fill missing fields.
  Hosts that need proxy-aware IP handling should normalize `conn.remote_ip`
  upstream before `Threadline.Plug` runs.

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

  @allowed_override_keys [:request_id, :correlation_id]

  @impl Plug
  def init(opts) do
    %{
      actor_fn: Keyword.get(opts, :actor_fn),
      context_overrides_fn: Keyword.get(opts, :context_overrides_fn)
    }
  end

  @impl Plug
  def call(conn, %{actor_fn: actor_fn, context_overrides_fn: context_overrides_fn}) do
    context =
      %AuditContext{
        actor_ref: extract_actor(conn, actor_fn),
        request_id: extract_request_id(conn),
        correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
        remote_ip: format_ip(conn.remote_ip)
      }
      |> apply_context_overrides(conn, context_overrides_fn)

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

  defp apply_context_overrides(context, _conn, nil), do: context

  defp apply_context_overrides(context, conn, fun) when is_function(fun, 1) do
    overrides = fun.(conn)
    validate_context_overrides!(overrides)

    Enum.reduce(overrides, context, fn
      {_key, nil}, acc ->
        acc

      {key, value}, acc ->
        maybe_put_override(acc, key, value)
    end)
  end

  defp maybe_put_override(context, key, value) do
    if Map.get(context, key) == nil do
      Map.put(context, key, value)
    else
      context
    end
  end

  defp validate_context_overrides!(overrides) when is_map(overrides) do
    case Map.keys(overrides) -- @allowed_override_keys do
      [] ->
        :ok

      unknown_keys ->
        raise ArgumentError,
              "unknown audit context override keys: #{inspect(unknown_keys)}; expected a subset of #{inspect(@allowed_override_keys)}"
    end
  end

  defp validate_context_overrides!(other) do
    raise ArgumentError,
          "context_overrides_fn must return a map, got: #{inspect(other)}"
  end
end
