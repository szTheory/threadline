defmodule Threadline.Health.CoverageSchemas do
  @moduledoc false

  alias Ecto.Adapters.SQL

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

      case SQL.query!(repo, sql, [schema]) do
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

    %{rows: rows} = SQL.query!(repo, sql, [])
    List.flatten(rows)
  end

  @doc """
  Lists every `{schema, table}` pair for `mix threadline.health.coverage
  --all-schemas`'s batched enumeration (HLTH-02).

  Same non-system-schema predicate as `available/1`, plus one additional
  exclusion: schemas that are themselves a member of a PostgreSQL extension,
  detected only via `pg_depend`. The `pg_extension` catalog's own schema
  column names the extension's OWNING schema, not a schema it was later
  attached to with `ALTER EXTENSION ... ADD SCHEMA`; filtering on that
  column instead would incorrectly drop `public` whenever any extension's
  owning schema is `public` (for example `citext`).
  """
  @spec all_tables(module()) :: [{String.t(), String.t()}]
  def all_tables(repo) do
    sql = """
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname <> 'information_schema'
      AND schemaname NOT LIKE 'pg\\_%' ESCAPE '\\'
      AND NOT EXISTS (
        SELECT 1
        FROM pg_depend d
        JOIN pg_namespace ns ON ns.oid = d.objid
        WHERE d.classid = 'pg_namespace'::regclass
          AND d.deptype = 'e'
          AND ns.nspname = pg_tables.schemaname
      )
    ORDER BY schemaname, tablename
    """

    %{rows: rows} = SQL.query!(repo, sql, [])
    Enum.map(rows, fn [schema, table] -> {schema, table} end)
  end
end
