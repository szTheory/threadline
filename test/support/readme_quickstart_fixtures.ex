defmodule Threadline.ReadmeDocContractAuth do
  @moduledoc false

  alias Threadline.Semantics.ActorRef

  def to_actor_ref(_conn) do
    {:ok, ref} = ActorRef.new(:anonymous)
    ref
  end
end

defmodule Threadline.ReadmeDocContractRouter do
  @moduledoc false
  use Plug.Router

  plug(Threadline.Plug, actor_fn: &Threadline.ReadmeDocContractAuth.to_actor_ref/1)
  plug(:match)
  plug(:dispatch)

  match(_, do: send_resp(conn, 404, "not found"))
end

defmodule Threadline.ReadmeQuickstartFixtures do
  @moduledoc """
  Compile-checked mirrors of README Quick Start paths (TOOL-03).

  Uses `Threadline.Semantics.ActorRef.new/2` where the README shows
  `anonymous/0` and `user/1` sugar — equivalent constructor shapes for CI.
  """

  alias Threadline.Semantics.ActorRef

  def actor_ref_map_examples do
    {:ok, anon} = ActorRef.new(:anonymous)
    {:ok, user} = ActorRef.new(:user, "user:1")
    %{anonymous: ActorRef.to_map(anon), user: ActorRef.to_map(user)}
  end

  def jason_encode_actor_example do
    actor_ref_map_examples().anonymous |> Jason.encode!()
  end

  def record_action_call(repo) do
    {:ok, actor} = ActorRef.new(:anonymous)
    Threadline.record_action(:readme_doc_contract_touch, repo: repo, actor: actor)
  end

  def trigger_coverage_call do
    Threadline.Health.trigger_coverage(repo: Threadline.Test.Repo)
  end
end
