defmodule Threadline.Storage.Local do
  @moduledoc """
  Stores Threadline exports on the local filesystem.

  This is the default `Threadline.Storage` adapter. It is intended for a
  single-node deployment whose filesystem is persistent and readable by the
  web process. Select it explicitly when needed:

      config :threadline, storage_adapter: Threadline.Storage.Local

  Files are stored under `priv/threadline_exports`. `put/2` writes the supplied
  binary content and accepts an optional `:file_id`; otherwise it generates a
  CSV identifier. As an adapter-specific convenience, when the supplied binary
  names an existing regular file, Local copies that file instead of storing the
  path text. Other adapters are required to accept binary content only.

  `path/1` returns an expanded local path for export delivery. `download_url/2`
  returns `{:error, :not_supported}` because this adapter does not generate
  URLs. Filesystem failures are returned as `{:error, reason}` values from
  Elixir's `File` module, while deleting a missing file is successful.
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
    priv_dir =
      case :code.priv_dir(:threadline) do
        path when is_list(path) -> path
        {:error, :bad_name} -> "priv"
      end

    Path.join([to_string(priv_dir), "threadline_exports", file_id])
  end
end
