defmodule ThreadlinePhoenixWeb.Router do
  use ThreadlinePhoenixWeb, :router

  pipeline :api do
    # doc: start: router-pipeline-actor-fn
    plug(:accepts, ["json"])
    plug(ThreadlinePhoenixWeb.SigraContextPlug)
    plug(Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1)
    # doc: end: router-pipeline-actor-fn
  end

  scope "/api", ThreadlinePhoenixWeb do
    pipe_through(:api)

    post "/posts", PostController, :create

    get "/audit_transactions/:id/changes", AuditTransactionController, :changes
  end
end
