if Code.ensure_loaded?(Phoenix.Controller) do
  defmodule Threadline.OperatorSurface.Controllers.ThemeController do
    use Phoenix.Controller, formats: [:html]

    @invalid_local_redirect_chars ["\\", "/%09", "/\t"]

    def update(conn, %{"theme" => theme}) when theme in ["light", "dark", "system"] do
      conn
      |> put_session(:tl_theme, theme)
      |> put_resp_cookie("tl_theme", theme, path: "/")
      |> redirect(to: redirect_path(conn))
    end

    def update(conn, _params) do
      redirect(conn, to: redirect_path(conn))
    end

    defp redirect_path(conn) do
      base_path = operator_base_path(conn.request_path)

      conn
      |> get_req_header("referer")
      |> List.first()
      |> safe_operator_path(conn, base_path)
      |> Kernel.||(base_path)
    end

    defp safe_operator_path(nil, _conn, _base_path), do: nil

    defp safe_operator_path(referer, conn, base_path) do
      uri = URI.parse(referer)

      if same_origin_or_relative?(uri, conn) do
        operator_path(uri, base_path)
      end
    rescue
      _ -> nil
    end

    defp same_origin_or_relative?(%URI{scheme: nil, host: nil}, _conn), do: true

    defp same_origin_or_relative?(%URI{scheme: scheme, host: host, port: port}, conn)
         when scheme in ["http", "https"] do
      host == conn.host and normalize_port(scheme, port) == conn.port
    end

    defp same_origin_or_relative?(_uri, _conn), do: false

    defp operator_path(%URI{path: "/" <> _ = path, query: query}, base_path) do
      candidate = path_with_query(path, query)

      if operator_path?(path, base_path) and safe_local_redirect?(candidate) do
        candidate
      end
    end

    defp operator_path(_uri, _base_path), do: nil

    defp safe_local_redirect?("//" <> _), do: false

    defp safe_local_redirect?("/" <> _ = path) do
      not String.contains?(path, @invalid_local_redirect_chars)
    end

    defp safe_local_redirect?(_path), do: false

    defp operator_path?(path, "/"), do: String.starts_with?(path, "/")

    defp operator_path?(path, base_path),
      do: path == base_path or String.starts_with?(path, base_path <> "/")

    defp path_with_query(path, nil), do: path
    defp path_with_query(path, ""), do: path
    defp path_with_query(path, query), do: path <> "?" <> query

    defp operator_base_path(path) when is_binary(path) do
      suffix = "/theme"

      if String.ends_with?(path, suffix) do
        base_path = binary_part(path, 0, byte_size(path) - byte_size(suffix))
        if base_path == "", do: "/", else: base_path
      else
        "/"
      end
    end

    defp operator_base_path(_path), do: "/"

    defp normalize_port("http", nil), do: 80
    defp normalize_port("https", nil), do: 443
    defp normalize_port(_scheme, port), do: port
  end
end
