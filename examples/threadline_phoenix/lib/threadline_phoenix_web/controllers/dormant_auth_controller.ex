defmodule ThreadlinePhoenixWeb.DormantAuthController do
  @moduledoc false
  use ThreadlinePhoenixWeb, :controller

  def not_available(conn, _params) do
    conn
    |> put_status(404)
    |> text("Not available in the reference walkthrough.")
  end
end
