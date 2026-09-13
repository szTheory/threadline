defmodule Threadline.OperatorSurface.SessionPlugTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  alias Threadline.OperatorSurface.SessionPlug
  alias Threadline.Semantics.ActorRef

  # A mock router just to initialize session for testing Plug.Conn
  defmodule TestRouter do
    use Plug.Router

    plug(Plug.Session,
      store: :cookie,
      key: "_test_key",
      signing_salt: "test_salt",
      encryption_salt: "test_salt"
    )

    plug(:match)
    plug(:dispatch)

    get "/" do
      send_resp(conn, 200, "ok")
    end
  end

  setup do
    conn =
      conn(:get, "/")
      |> Plug.Session.call(
        Plug.Session.init(
          store: :cookie,
          key: "_test_key",
          signing_salt: "test_salt"
        )
      )
      |> Plug.Conn.fetch_session()

    %{conn: conn}
  end

  test "puts serialized actor ref into session when actor_fn returns ActorRef", %{conn: conn} do
    actor_ref = %ActorRef{type: :user, id: "123"}
    actor_fn = fn _conn -> actor_ref end

    opts = SessionPlug.init(actor_fn: actor_fn)
    conn = SessionPlug.call(conn, opts)

    assert get_session(conn, "threadline_actor_ref") == "{\"id\":\"123\",\"type\":\"user\"}"
    assert conn.assigns.threadline_actor_ref == actor_ref
  end

  test "clears stale session ownership when actor_fn returns nil", %{conn: conn} do
    actor_a = %ActorRef{type: :user, id: "actor-a"}
    conn = SessionPlug.call(conn, SessionPlug.init(actor_fn: fn _ -> actor_a end))
    assert get_session(conn, "threadline_actor_ref")

    actor_fn = fn _conn -> nil end

    opts = SessionPlug.init(actor_fn: actor_fn)
    conn = SessionPlug.call(conn, opts)

    assert get_session(conn, "threadline_actor_ref") == nil
    refute Map.has_key?(conn.assigns, :threadline_actor_ref)
  end

  test "clears stale session ownership when actor_fn raises", %{conn: conn} do
    actor_a = %ActorRef{type: :user, id: "actor-a"}
    conn = SessionPlug.call(conn, SessionPlug.init(actor_fn: fn _ -> actor_a end))
    assert get_session(conn, "threadline_actor_ref")

    actor_fn = fn _conn -> raise "identity lookup failed" end

    opts = SessionPlug.init(actor_fn: actor_fn)
    conn = SessionPlug.call(conn, opts)

    assert get_session(conn, "threadline_actor_ref") == nil
    refute Map.has_key?(conn.assigns, :threadline_actor_ref)
  end

  test "clears session when actor_fn does not return an ActorRef", %{conn: conn} do
    actor_fn = fn _conn -> %{id: "123", type: "user"} end

    opts = SessionPlug.init(actor_fn: actor_fn)
    conn = SessionPlug.call(conn, opts)

    assert get_session(conn, "threadline_actor_ref") == nil
  end
end
