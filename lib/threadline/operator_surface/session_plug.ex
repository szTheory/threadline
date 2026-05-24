defmodule Threadline.OperatorSurface.SessionPlug do
  @moduledoc """
  A Plug that executes a configured `actor_fn` on the connection and stores the
  serialized `ActorRef` in the session under the `"threadline_actor_ref"` key.

  This allows LiveView mounts (which don't have access to connection headers or
  assigns) to read the authenticated actor directly from the session.
  """

  @behaviour Plug

  import Plug.Conn

  alias Threadline.Semantics.ActorRef

  @impl Plug
  def init(opts) do
    actor_fn = Keyword.get(opts, :actor_fn)

    unless is_function(actor_fn, 1) do
      raise ArgumentError, "SessionPlug requires an :actor_fn that takes 1 argument (the conn)"
    end

    %{actor_fn: actor_fn}
  end

  @impl Plug
  def call(conn, %{actor_fn: actor_fn}) do
    try do
      case actor_fn.(conn) do
        %ActorRef{} = actor_ref ->
          serialized = actor_ref |> ActorRef.to_map() |> Jason.encode!()
          put_session(conn, "threadline_actor_ref", serialized)

        _ ->
          conn
      end
    rescue
      _ -> conn
    end
  end
end
