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
  end

  test "leaves session unchanged when actor_fn returns nil", %{conn: conn} do
    actor_fn = fn _conn -> nil end

    opts = SessionPlug.init(actor_fn: actor_fn)
    conn = SessionPlug.call(conn, opts)

    assert get_session(conn, "threadline_actor_ref") == nil
  end

  test "leaves session unchanged when actor_fn raises or returns error", %{conn: conn} do
    actor_fn = fn _conn -> {:error, :unauthenticated} end

    opts = SessionPlug.init(actor_fn: actor_fn)
    conn = SessionPlug.call(conn, opts)

    assert get_session(conn, "threadline_actor_ref") == nil
  end

  test "leaves session unchanged when actor_fn does not return an ActorRef", %{conn: conn} do
    actor_fn = fn _conn -> %{id: "123", type: "user"} end

    opts = SessionPlug.init(actor_fn: actor_fn)
    conn = SessionPlug.call(conn, opts)

    assert get_session(conn, "threadline_actor_ref") == nil
  end
end
