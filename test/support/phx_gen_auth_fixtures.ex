defmodule Threadline.PhxGenAuthFixtures do
  @moduledoc false

  import Plug.Conn
  import Plug.Test

  def build_phx_scope_conn(opts \\ []) do
    scope = Keyword.get(opts, :scope)
    headers = Keyword.get(opts, :headers, [])
    current_user = Keyword.get(opts, :current_user)

    conn =
      Enum.reduce(headers, conn(:get, "/"), fn {key, value}, acc ->
        put_req_header(acc, key, value)
      end)

    conn =
      if Keyword.has_key?(opts, :scope) do
        assign(conn, :current_scope, scope)
      else
        conn
      end

    if current_user do
      assign(conn, :current_user, current_user)
    else
      conn
    end
  end

  def logged_in_scope, do: %{user: %{id: "u-42"}}
  def logged_out_scope, do: nil
  def admin_user, do: %{role: "admin"}
  def non_admin_user, do: %{role: "member"}
end
