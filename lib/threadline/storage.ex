defmodule Threadline.Storage do
  @moduledoc """
  Stores and retrieves export files and other persistent artifacts.

  Threadline uses `Threadline.Storage.Local` by default. Select another built-in
  or custom adapter in your host application's configuration:

      config :threadline, storage_adapter: MyApp.AuditStorage

  A custom adapter implements this behaviour. Threadline passes the keyword list
  stored under the adapter module to `c:init/1` during application startup when a
  repository is configured:

      config :threadline, MyApp.AuditStorage, region: "us-east-1"

  Return `:ok` from `c:init/1` only when the adapter is ready. Returning
  `{:error, reason}` or raising prevents Threadline's supervision tree from
  starting, so missing dependencies and invalid configuration fail early.

  `c:put/2` accepts binary content as the portable cross-adapter contract and
  returns an opaque file identifier used by the remaining callbacks. The built-in
  Local adapter also accepts the path of an existing regular file as a
  Local-specific convenience; custom and remote adapters do not need to support
  that shortcut.

  `c:path/1` is optional. Implement it only when the web process can serve a
  stored file from its local filesystem. When it is absent, or returns
  `{:error, :not_local}`, export delivery uses `c:download_url/2` instead.

  See `Threadline.Storage.Local` for single-node storage and
  `Threadline.Storage.S3` for optional S3-compatible object storage.
  """

  @type file_id :: String.t()
  @type content :: binary()
  @type options :: keyword()

  @doc """
  Initializes the adapter from its module-keyed configuration.

  Threadline calls this during application startup. Return `{:error, reason}`
  for invalid configuration or unavailable dependencies.
  """
  @callback init(keyword()) :: :ok | {:error, term()}

  @doc """
  Stores binary content.

  Returns `{:ok, file_id}` where `file_id` is a backend-specific identifier
  (such as an S3 key or a local filesystem path) that can be used with `get/1`
  and `download_url/2`.
  """
  @callback put(content(), options()) :: {:ok, file_id()} | {:error, term()}

  @doc """
  Retrieves a file's content from storage.
  """
  @callback get(file_id()) :: {:ok, binary()} | {:error, term()}

  @doc """
  Returns a direct local path to the stored file when supported by the adapter.

  This callback is optional. Adapters without a locally readable file should
  omit it or return `{:error, :not_local}`.
  """
  @callback path(file_id()) :: {:ok, String.t()} | {:error, term()}
  @optional_callbacks path: 1

  @doc """
  Generates a URL for downloading the file.

  Threadline may pass `:expires_in` in seconds. Remote adapters commonly return
  a short-lived presigned URL; adapters that cannot generate a URL return an
  adapter-specific error.
  """
  @callback download_url(file_id(), options()) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Deletes a file from storage.
  """
  @callback delete(file_id()) :: :ok | {:error, term()}
end
