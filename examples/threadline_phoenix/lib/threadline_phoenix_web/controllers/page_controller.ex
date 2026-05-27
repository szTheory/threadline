defmodule ThreadlinePhoenixWeb.PageController do
  use ThreadlinePhoenixWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
