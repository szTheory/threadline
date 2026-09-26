defmodule Threadline.Capture.RowHistoryIndexSQL do
  @moduledoc false

  # Owns the DDL for `audit_changes_row_history_idx`, the index that keeps
  # `history/3`, `row_history_query/3`, and `as_of/4` (see
  # `Threadline.Query.where_row/2`) off a sequential scan. The install
  # template (`Threadline.Capture.Migration`) and the existing-adopter
  # generator (`mix threadline.gen.row_history_index`) both call into this
  # one module, so the column list cannot drift between the two paths.

  alias Threadline.StorageSchema

  @index_name "audit_changes_row_history_idx"
  @columns "(table_schema, table_name, table_pk, captured_at DESC, id DESC)"

  @doc "Returns the index name, unqualified."
  @spec index_name() :: String.t()
  def index_name, do: @index_name

  @doc """
  Returns the blocking `CREATE INDEX IF NOT EXISTS` statement for the install
  template. Safe inside the install migration's transaction because the
  table is brand new and empty.

  `opts` accepts `:storage_schema` exactly as `StorageSchema.table/2` does.
  """
  @spec create_sql(keyword()) :: String.t()
  def create_sql(opts \\ []) do
    "CREATE INDEX IF NOT EXISTS #{@index_name} ON #{audit_changes(opts)} #{@columns}"
  end

  @doc """
  Returns the non-blocking `CREATE INDEX CONCURRENTLY IF NOT EXISTS`
  statement for existing adopters. The migration that executes this must
  carry `@disable_ddl_transaction true` and `@disable_migration_lock true`,
  because `CONCURRENTLY` cannot run inside a transaction block.
  """
  @spec create_concurrently_sql(keyword()) :: String.t()
  def create_concurrently_sql(opts \\ []) do
    "CREATE INDEX CONCURRENTLY IF NOT EXISTS #{@index_name} ON #{audit_changes(opts)} #{@columns}"
  end

  @doc """
  Returns the non-blocking `DROP INDEX CONCURRENTLY IF EXISTS` statement,
  schema-qualified since the storage schema may not be on `search_path`.
  """
  @spec drop_concurrently_sql(keyword()) :: String.t()
  def drop_concurrently_sql(opts \\ []) do
    qualified_index = StorageSchema.qualify(StorageSchema.get(opts), @index_name)
    "DROP INDEX CONCURRENTLY IF EXISTS #{qualified_index}"
  end

  defp audit_changes(opts), do: StorageSchema.table("audit_changes", opts)
end
