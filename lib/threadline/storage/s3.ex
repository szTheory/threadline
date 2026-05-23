defmodule Threadline.Storage.S3 do
  @moduledoc """
  S3 implementation of `Threadline.Storage`.

  This adapter stores files in an S3-compatible object storage service,
  making them accessible across a multi-node cluster via presigned URLs.
  Requires the optional `:ex_aws`, `:ex_aws_s3`, `:hackney`, and `:sweet_xml` dependencies.
  """

  @behaviour Threadline.Storage

  @impl true
  def init(_opts) do
    if Code.ensure_loaded?(ExAws.S3) do
      :ok
    else
      raise "S3 adapter requires ExAws dependencies. Please add :ex_aws, :ex_aws_s3, :hackney, and :sweet_xml to your mix.exs."
    end
  end

  @impl true
  def put(content, opts \\ []) do
    file_id = Keyword.get_lazy(opts, :file_id, fn -> Ecto.UUID.generate() <> ".csv" end)
    bucket = get_bucket(opts)
    
    ex_aws_mod = Keyword.get(opts, :ex_aws_mod, ExAws)
    ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)

    request = ex_aws_s3_mod.put_object(bucket, file_id, content)

    case ex_aws_mod.request(request) do
      {:ok, _response} -> {:ok, file_id}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def get(file_id, opts \\ []) do
    bucket = get_bucket(opts)

    ex_aws_mod = Keyword.get(opts, :ex_aws_mod, ExAws)
    ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)

    request = ex_aws_s3_mod.get_object(bucket, file_id)

    case ex_aws_mod.request(request) do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def path(_file_id) do
    {:error, :not_local}
  end

  @impl true
  def download_url(file_id, opts \\ []) do
    bucket = get_bucket(opts)
    ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)
    
    expires_in = Keyword.get(opts, :expires_in, 900) # 15 minutes default

    # ExAws.Config is a bit special. We'll just pass ExAws.Config as the config parameter
    # because ExAws.S3.presigned_url expects the config module or map.
    config_mod = Keyword.get(opts, :config_mod, ExAws.Config)
    
    presigned_opts = [virtual_host: true, expires_in: expires_in]
    # some configurations might need specific presigned_opts, but we'll stick to a default.
    case ex_aws_s3_mod.presigned_url(config_mod, :get, bucket, file_id, presigned_opts) do
      {:ok, url} -> {:ok, url}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def delete(file_id, opts \\ []) do
    bucket = get_bucket(opts)
    
    ex_aws_mod = Keyword.get(opts, :ex_aws_mod, ExAws)
    ex_aws_s3_mod = Keyword.get(opts, :ex_aws_s3_mod, ExAws.S3)

    request = ex_aws_s3_mod.delete_object(bucket, file_id)

    case ex_aws_mod.request(request) do
      {:ok, _response} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_bucket(opts) do
    Keyword.get_lazy(opts, :bucket, fn ->
      Application.get_env(:threadline, Threadline.Storage.S3, []) |> Keyword.get(:bucket)
    end)
  end
end