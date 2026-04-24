defmodule ThreadlinePhoenixWeb.Router do
  use ThreadlinePhoenixWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
    plug(Threadline.Plug, actor_fn: &ThreadlinePhoenix.AuditActor.from_conn/1)
  end

  scope "/api", ThreadlinePhoenixWeb do
    pipe_through(:api)

    post "/posts", PostController, :create

    get "/audit_transactions/:id/changes", AuditTransactionController, :changes
  end
end
