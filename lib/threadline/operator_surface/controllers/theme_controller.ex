defmodule Threadline.OperatorSurface.Controllers.ThemeController do
  use Phoenix.Controller, formats: [:html]

  def update(conn, %{"theme" => theme}) when theme in ["light", "dark", "system"] do
    conn
    |> put_session(:tl_theme, theme)
    |> put_resp_cookie("tl_theme", theme, path: "/")
    |> redirect(to: get_req_header(conn, "referer") |> List.first() || "/")
  end

  def update(conn, _params) do
    redirect(conn, to: get_req_header(conn, "referer") |> List.first() || "/")
  end
end
