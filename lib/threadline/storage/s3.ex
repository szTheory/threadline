defmodule Threadline.Storage.S3 do
  @moduledoc """
  S3 implementation of `Threadline.Storage`.

  This adapter stores files in an S3-compatible object storage service,
  making them accessible across a multi-node cluster via presigned URLs.
  Requires the optional `:ex_aws`, `:ex_aws_s3`, `:hackney`, and `:sweet_xml` dependencies.
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

      case ex_aws_mod.request(request) do
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

      case ex_aws_mod.request(request) do
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

      case ex_aws_mod.request(request) do
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
    if Code.ensure_loaded?(ExAws.S3) do
      :ok
    else
      {:error, "S3 adapter requires ExAws dependencies"}
    end
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
