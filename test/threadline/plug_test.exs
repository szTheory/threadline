defmodule Threadline.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias Threadline.Plug, as: ThreadlinePlug
  alias Threadline.Semantics.{ActorRef, AuditContext}

  defp call(conn, opts \\ []) do
    ThreadlinePlug.call(conn, ThreadlinePlug.init(opts))
  end

  test "assigns an AuditContext to conn" do
    conn = conn(:get, "/") |> call()
    assert %AuditContext{} = conn.assigns[:audit_context]
  end

  test "extracts request_id from x-request-id header" do
    conn =
      conn(:get, "/")
      |> put_req_header("x-request-id", "req-abc")
      |> call()

    assert conn.assigns[:audit_context].request_id == "req-abc"
  end

  test "extracts correlation_id from x-correlation-id header" do
    conn =
      conn(:get, "/")
      |> put_req_header("x-correlation-id", "corr-xyz")
      |> call()

    assert conn.assigns[:audit_context].correlation_id == "corr-xyz"
  end

  test "actor_ref is nil when no actor_fn configured" do
    conn = conn(:get, "/") |> call()
    assert conn.assigns[:audit_context].actor_ref == nil
  end

  test "actor_fn: option sets actor_ref from the function result" do
    {:ok, ref} = ActorRef.new(:user, "u-1")

    conn =
      conn(:get, "/")
      |> call(actor_fn: fn _conn -> ref end)

    assert conn.assigns[:audit_context].actor_ref == ref
  end

  test "actor_fn: nil return leaves actor_ref nil" do
    conn =
      conn(:get, "/")
      |> call(actor_fn: fn _conn -> nil end)

    assert conn.assigns[:audit_context].actor_ref == nil
  end

  test "remote_ip from Erlang tuple is formatted as dotted-decimal string" do
    conn = %{conn(:get, "/") | remote_ip: {127, 0, 0, 1}} |> call()
    assert conn.assigns[:audit_context].remote_ip == "127.0.0.1"
  end

  test "nil remote_ip is handled gracefully" do
    conn = %{conn(:get, "/") | remote_ip: nil} |> call()
    assert conn.assigns[:audit_context].remote_ip == nil
  end

  test "CTX-01: AuditContext is stored in conn.assigns[:audit_context]" do
    conn = conn(:get, "/") |> call()
    assert Map.has_key?(conn.assigns, :audit_context)
  end
end
