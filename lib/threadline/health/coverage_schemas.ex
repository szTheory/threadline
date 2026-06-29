defmodule Threadline.Health.CoverageSchemas do
  @moduledoc """
  Boundary helpers for user-facing trigger-coverage schema selection.

  `Threadline.Health.trigger_coverage/1` deliberately trusts programmatic callers.
  LiveView and Mix-task surfaces use this module before passing user-provided schema
  names into catalog queries.
  """

  @schema_regex ~r/\A[a-z_][a-z0-9_]{0,62}\z/

  @doc """
  Validates a PostgreSQL schema name for user-facing coverage surfaces.

  Names must be conservative lowercase identifiers and must exist in `pg_namespace`.
  """
  @spec validate!(module(), String.t()) :: String.t()
  def validate!(repo, schema) when is_binary(schema) do
    case validate(repo, schema) do
      {:ok, schema} -> schema
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc false
  @spec validate(module(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def validate(repo, schema) when is_binary(schema) do
    if schema =~ @schema_regex do
      sql = "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1"

      case Ecto.Adapters.SQL.query!(repo, sql, [schema]) do
        %{rows: []} -> {:error, "Schema #{schema} was not found."}
        %{rows: _} -> {:ok, schema}
      end
    else
      {:error, "Schema #{schema} was not found."}
    end
  end

  @doc """
  Lists non-system schemas that contain ordinary tables.
  """
  @spec available(module()) :: [String.t()]
  def available(repo) do
    sql = """
    SELECT DISTINCT schemaname
    FROM pg_tables
    WHERE schemaname <> 'information_schema'
      AND schemaname NOT LIKE 'pg\\_%' ESCAPE '\\'
    ORDER BY schemaname
    """

    %{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [])
    List.flatten(rows)
  end
end
