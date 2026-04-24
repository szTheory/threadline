defmodule ThreadlinePhoenixWeb.Router do
  use ThreadlinePhoenixWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", ThreadlinePhoenixWeb do
    pipe_through(:api)
  end
end
