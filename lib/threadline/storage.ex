defmodule Threadline.Storage do
  @moduledoc """
  Behaviour for storing and retrieving export files and other persistent artifacts.

  Threadline provides a `Threadline.Storage.Local` implementation out-of-the-box
  for single-node deployments. Adopters needing multi-node support should implement
  an S3-compatible backend conforming to this behaviour.
  """

  @type file_id :: String.t()
  @type path_or_content :: String.t() | binary()
  @type options :: keyword()

  @doc """
  Puts a file into storage.

  Returns `{:ok, file_id}` where `file_id` is a backend-specific identifier
  (such as an S3 key or a local filesystem path) that can be used with `get/1`
  and `download_url/2`.
  """
  @callback put(path_or_content(), options()) :: {:ok, file_id()} | {:error, term()}

  @doc """
  Retrieves a file's content from storage.
  """
  @callback get(file_id()) :: {:ok, binary()} | {:error, term()}

  @doc """
  Generates a presigned or localized URL for downloading the file.

  Options may include `:expires_in` (in seconds).
  """
  @callback download_url(file_id(), options()) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Deletes a file from storage.
  """
  @callback delete(file_id()) :: :ok | {:error, term()}
end
