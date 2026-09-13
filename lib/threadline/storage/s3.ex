defmodule Threadline.Storage.S3 do
  @moduledoc """
  Stores Threadline exports in S3-compatible object storage.

  Use this optional `Threadline.Storage` adapter when export files must be
  available across nodes. Add the optional `:ex_aws`, `:ex_aws_s3`, `:req`,
  and `:sweet_xml` dependencies to the host project, then configure the adapter
  and its required bucket:

      config :threadline, storage_adapter: Threadline.Storage.S3
      config :threadline, Threadline.Storage.S3, bucket: "my-audit-exports"

  Module-keyed options are merged with per-call options, with per-call values
  taking precedence. Supported runtime options are:

    * `:bucket` - required non-empty bucket name
    * `:expires_in` - presigned-download lifetime in seconds; defaults to `900`
    * `:presigned_url_opts` - options forwarded while creating the download URL
    * `:ex_aws_request_opts` - request overrides passed to `ExAws.request/2`;
      defaults to `[http_client: ExAws.Request.Req]`

  `put/2` uploads the binary content it receives; it does not interpret a binary
  as a local filename. `path/1` returns `{:error, :not_local}`, so export delivery
  uses a presigned URL. Missing dependencies or bucket configuration fail
  `init/1`; request and presigning failures are returned as descriptive errors.
  """

  @behaviour Threadline.Storage

  @impl true
  def init(opts) do
    with :ok <- ensure_dependencies_loaded(),
         {:ok, _bucket} <- fetch_bucket(opts) do
      :ok
    end
  end

  @impl true
  def put(content, opts \\ []) do
    opts = merged_opts(opts)

    with :ok <- init(opts),
         file_id <- Keyword.get_lazy(opts, :file_id, fn -> Ecto.UUID.generate() <> ".csv" end),
         {:ok, bucket} <- fetch_bucket(opts) do
      ex_aws_mod = Keyword.get(opts, :ex_aws_mod, ExAws)
      ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)
      request = ex_aws_s3_mod.put_object(bucket, file_id, content)

      case ex_aws_mod.request(request, ex_aws_request_opts(opts)) do
        {:ok, _response} -> {:ok, file_id}
        {:error, reason} -> {:error, normalize_storage_error("S3 upload failed", reason)}
      end
    end
  end

  @impl true
  def get(file_id, opts \\ []) do
    opts = merged_opts(opts)

    with :ok <- init(opts),
         {:ok, bucket} <- fetch_bucket(opts) do
      ex_aws_mod = Keyword.get(opts, :ex_aws_mod, ExAws)
      ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)
      request = ex_aws_s3_mod.get_object(bucket, file_id)

      case ex_aws_mod.request(request, ex_aws_request_opts(opts)) do
        {:ok, %{body: body}} -> {:ok, body}
        {:error, reason} -> {:error, normalize_storage_error("S3 download failed", reason)}
      end
    end
  end

  @impl true
  def path(_file_id) do
    {:error, :not_local}
  end

  @impl true
  def download_url(file_id, opts \\ []) do
    opts = merged_opts(opts)

    with :ok <- init(opts),
         {:ok, bucket} <- fetch_bucket(opts) do
      ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)
      config_mod = Keyword.get(opts, :config_mod, ExAws.Config)
      expires_in = Keyword.get(opts, :expires_in, 900)

      presigned_opts =
        opts
        |> Keyword.get(:presigned_url_opts, virtual_host: true)
        |> Keyword.put(:expires_in, expires_in)

      case ex_aws_s3_mod.presigned_url(config_mod, :get, bucket, file_id, presigned_opts) do
        {:ok, url} ->
          {:ok, url}

        {:error, reason} ->
          {:error, normalize_storage_error("S3 download URL generation failed", reason)}
      end
    end
  end

  @impl true
  def delete(file_id, opts \\ []) do
    opts = merged_opts(opts)

    with :ok <- init(opts),
         {:ok, bucket} <- fetch_bucket(opts) do
      ex_aws_mod = Keyword.get(opts, :ex_aws_mod, ExAws)
      ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)
      request = ex_aws_s3_mod.delete_object(bucket, file_id)

      case ex_aws_mod.request(request, ex_aws_request_opts(opts)) do
        {:ok, _response} -> :ok
        {:error, reason} -> {:error, normalize_storage_error("S3 delete failed", reason)}
      end
    end
  end

  defp merged_opts(opts) do
    Application.get_env(:threadline, __MODULE__, [])
    |> Keyword.merge(opts)
  end

  defp ensure_dependencies_loaded do
    if Code.ensure_loaded?(ExAws.S3) and Code.ensure_loaded?(ExAws.Request.Req) do
      :ok
    else
      {:error, "S3 adapter requires ExAws S3 and Req dependencies"}
    end
  end

  defp ex_aws_request_opts(opts) do
    Keyword.get(opts, :ex_aws_request_opts, http_client: ExAws.Request.Req)
  end

  defp fetch_bucket(opts) do
    case Keyword.get(opts, :bucket) do
      bucket when is_binary(bucket) and bucket != "" -> {:ok, bucket}
      _ -> {:error, "S3 adapter requires a non-empty :bucket configuration"}
    end
  end

  defp normalize_storage_error(prefix, %{message: message}) when is_binary(message) do
    "#{prefix}: #{message}"
  end

  defp normalize_storage_error(prefix, reason) when is_binary(reason) do
    "#{prefix}: #{reason}"
  end

  defp normalize_storage_error(prefix, reason) do
    "#{prefix}: #{inspect(reason)}"
  end
end
