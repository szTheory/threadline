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

  test "context_overrides_fn: fills missing request metadata only when baseline values are nil" do
    conn =
      conn(:get, "/")
      |> assign(:request_id, nil)
      |> then(&%{&1 | remote_ip: {127, 0, 0, 1}})
      |> call(
        context_overrides_fn: fn _conn ->
          %{
            request_id: "override-req",
            correlation_id: "override-corr"
          }
        end
      )

    assert %AuditContext{
             actor_ref: nil,
             request_id: "override-req",
             correlation_id: "override-corr",
             remote_ip: "127.0.0.1"
           } = conn.assigns[:audit_context]
  end

  test "context_overrides_fn: explicit request and correlation values remain authoritative" do
    {:ok, ref} = ActorRef.new(:user, "u-1")

    conn =
      conn(:get, "/")
      |> put_req_header("x-request-id", "req-abc")
      |> put_req_header("x-correlation-id", "corr-xyz")
      |> call(
        actor_fn: fn _conn -> ref end,
        context_overrides_fn: fn _conn ->
          %{
            request_id: "override-req",
            correlation_id: "override-corr"
          }
        end
      )

    assert %AuditContext{
             actor_ref: ^ref,
             request_id: "req-abc",
             correlation_id: "corr-xyz",
             remote_ip: "127.0.0.1"
           } = conn.assigns[:audit_context]
  end

  test "context_overrides_fn: nil values do not clobber derived values" do
    conn =
      conn(:get, "/")
      |> assign(:request_id, "req-abc")
      |> put_req_header("x-correlation-id", "corr-xyz")
      |> call(
        context_overrides_fn: fn _conn ->
          %{request_id: nil, correlation_id: nil}
        end
      )

    assert %AuditContext{
             request_id: "req-abc",
             correlation_id: "corr-xyz"
           } = conn.assigns[:audit_context]
  end

  test "context_overrides_fn: unknown keys raise" do
    assert_raise ArgumentError, ~r/unknown audit context override keys/, fn ->
      conn(:get, "/")
      |> call(context_overrides_fn: fn _conn -> %{tenant_id: "org-1"} end)
    end
  end

  test "context_overrides_fn: actor_ref and remote_ip overrides raise" do
    assert_raise ArgumentError, ~r/unknown audit context override keys/, fn ->
      conn(:get, "/")
      |> call(context_overrides_fn: fn _conn -> %{actor_ref: %{}, remote_ip: "10.0.0.10"} end)
    end
  end

  test "context_overrides_fn: non-map results raise" do
    assert_raise ArgumentError, ~r/context_overrides_fn must return a map/, fn ->
      conn(:get, "/")
      |> call(context_overrides_fn: fn _conn -> :not_a_map end)
    end
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
