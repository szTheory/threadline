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

  @allowed_extensions MapSet.new([".csv"])
  @invalid_file_id_chars ~r{[/\\\x00-\x1F\x7F]}

  @impl true
  def init(_opts), do: :ok

  @impl true
  def put(content, opts \\ []) do
    file_id = Keyword.get_lazy(opts, :file_id, fn -> Ecto.UUID.generate() <> ".csv" end)

    with {:ok, path} <- resolve_path(file_id),
         :ok <- File.mkdir_p(export_root()),
         :ok <- reject_symlink(export_root()),
         :ok <- reject_symlink(path) do
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
    with {:ok, path} <- resolve_path(file_id) do
      File.read(path)
    end
  end

  @impl true
  def path(file_id) do
    with {:ok, path} <- resolve_path(file_id) do
      if File.exists?(path) do
        {:ok, path}
      else
        {:error, :not_found}
      end
    end
  end

  @impl true
  def download_url(_file_id, _opts \\ []) do
    {:error, :not_supported}
  end

  @impl true
  def delete(file_id) do
    with {:ok, path} <- resolve_path(file_id) do
      case File.rm(path) do
        :ok -> :ok
        {:error, :enoent} -> :ok
        error -> error
      end
    end
  end

  defp resolve_path(file_id) when is_binary(file_id) do
    root = export_root()

    with :ok <- validate_file_id(file_id),
         candidate <- Path.expand(file_id, root),
         true <- Path.dirname(candidate) == root,
         :ok <- reject_symlink(root),
         :ok <- reject_symlink(candidate) do
      {:ok, candidate}
    else
      false -> {:error, :invalid_file_id}
      {:error, _reason} = error -> error
    end
  end

  defp resolve_path(_file_id), do: {:error, :invalid_file_id}

  defp validate_file_id(file_id) do
    cond do
      file_id in ["", ".", ".."] ->
        {:error, :invalid_file_id}

      Regex.match?(@invalid_file_id_chars, file_id) ->
        {:error, :invalid_file_id}

      Path.basename(file_id) != file_id ->
        {:error, :invalid_file_id}

      not MapSet.member?(@allowed_extensions, Path.extname(file_id)) ->
        {:error, :invalid_file_id}

      true ->
        :ok
    end
  end

  defp reject_symlink(path) do
    case File.lstat(path) do
      {:ok, %File.Stat{type: :symlink}} -> {:error, :unsafe_path}
      {:ok, _stat} -> :ok
      {:error, :enoent} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp export_root do
    priv_dir =
      case :code.priv_dir(:threadline) do
        path when is_list(path) -> path
        {:error, :bad_name} -> "priv"
      end

    Path.expand(Path.join(to_string(priv_dir), "threadline_exports"))
  end
end
