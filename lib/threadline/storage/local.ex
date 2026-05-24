defmodule Threadline.Storage.Local do
  @moduledoc """
  Local filesystem implementation of `Threadline.Storage`.

  This adapter is suitable for single-node deployments where the filesystem
  is persistent and accessible by the web server.

  Files are stored in the application's `priv/threadline_exports` directory
  by default.
  """

  @behaviour Threadline.Storage

  @impl true
  def init(_opts), do: :ok

  @impl true
  def put(content, opts \\ []) do
    file_id = Keyword.get_lazy(opts, :file_id, fn -> Ecto.UUID.generate() <> ".csv" end)
    path = local_path(file_id)

    with :ok <- File.mkdir_p(Path.dirname(path)) do
      if is_binary(content) and File.regular?(content) do
        case File.cp(content, path) do
          :ok -> {:ok, file_id}
          {:error, reason} -> {:error, reason}
        end
      else
        case File.write(path, content) do
          :ok -> {:ok, file_id}
          {:error, reason} -> {:error, reason}
        end
      end
    end
  end

  @impl true
  def get(file_id) do
    File.read(local_path(file_id))
  end

  @impl true
  def path(file_id) do
    path = local_path(file_id)

    if File.exists?(path) do
      {:ok, Path.expand(path)}
    else
      {:error, :not_found}
    end
  end

  @impl true
  def download_url(_file_id, _opts \\ []) do
    {:error, :not_supported}
  end

  @impl true
  def delete(file_id) do
    case File.rm(local_path(file_id)) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      error -> error
    end
  end

  defp local_path(file_id) do
    priv_dir = :code.priv_dir(:threadline) || "priv"
    Path.join([to_string(priv_dir), "threadline_exports", file_id])
  end
end
