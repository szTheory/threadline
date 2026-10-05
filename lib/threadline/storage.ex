defmodule Threadline.Storage do
  @moduledoc """
  Stores and retrieves export files and other persistent artifacts.

  `init/1` validates adapter configuration, `put/2` and `get/1` write and read
  content, `path/1` exposes a local file when available, `download_url/2`
  supports remote delivery, and `delete/1` removes a stored object.

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

  @typedoc "An opaque identifier returned by a storage adapter for a stored file."
  @type file_id :: String.t()

  @typedoc "Binary content passed to or returned from a storage adapter."
  @type content :: binary()

  @typedoc "Adapter-defined keyword options that Threadline passes through without interpreting their keys."
  @type options :: keyword()

  @typedoc "Any Elixir value returned by an adapter as an error reason; Threadline treats it as opaque."
  @type error_reason ::
          atom()
          | number()
          | bitstring()
          | pid()
          | port()
          | reference()
          | function()
          | tuple()
          | maybe_improper_list(error_reason(), error_reason())
          | %{optional(error_reason()) => error_reason()}

  @doc """
  Initializes the adapter from its module-keyed configuration, returning `:ok`
  when ready or `{:error, reason}` when initialization fails.

  Threadline calls this during application startup. Return `{:error, reason}`
  for invalid configuration or unavailable dependencies.
  """
  @callback init(options()) :: :ok | {:error, error_reason()}

  @doc """
  Stores binary content, returning `{:ok, file_id}` when stored or
  `{:error, reason}` when storage fails.

  Returns `{:ok, file_id}` where `file_id` is a backend-specific identifier
  (such as an S3 key or a local filesystem path) that can be used with `get/1`
  and `download_url/2`.
  """
  @callback put(content(), options()) :: {:ok, file_id()} | {:error, error_reason()}

  @doc """
  Retrieves a file's content, returning `{:ok, content}` when found or
  `{:error, reason}` when retrieval fails.
  """
  @callback get(file_id()) :: {:ok, content()} | {:error, error_reason()}

  @doc """
  Returns `{:ok, path}` when the adapter can expose a local file, or
  `{:error, reason}` when it cannot; `:not_local` means no local path is
  available.

  This callback is optional. Adapters without a locally readable file should
  omit it or return `{:error, :not_local}`.
  """
  @callback path(file_id()) :: {:ok, String.t()} | {:error, error_reason()}
  @optional_callbacks path: 1

  @doc """
  Generates a download URL, returning `{:ok, url}` when available or
  `{:error, reason}` when URL generation fails.

  Threadline may pass `:expires_in` in seconds. Remote adapters commonly return
  a short-lived presigned URL; adapters that cannot generate a URL return an
  adapter-specific error.
  """
  @callback download_url(file_id(), options()) :: {:ok, String.t()} | {:error, error_reason()}

  @doc """
  Deletes a file from storage, returning `:ok` when deleted or
  `{:error, reason}` when deletion fails.
  """
  @callback delete(file_id()) :: :ok | {:error, error_reason()}
end
