defmodule Threadline.OperatorSurface.SessionPlug do
  @moduledoc false

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

          conn
          |> assign(:threadline_actor_ref, actor_ref)
          |> put_session("threadline_actor_ref", serialized)

        _ ->
          conn
      end
    rescue
      _ -> conn
    end
  end
end
