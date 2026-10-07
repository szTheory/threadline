defmodule Threadline.Test.RowHistory do
  @moduledoc false

  # Plan 232-05 (D-13): the unbounded, plain-%AuditChange{} read migrated
  # tests use instead of the retired Threadline.history/3. Reads through the
  # canonical Threadline.row_history/3, forcing limit: :infinity so a
  # migrated assertion is never silently capped at the 200-row default.

  @doc false
  def changes(schema_module, id, opts \\ []) when is_list(opts) do
    schema_module
    |> Threadline.row_history(id, Keyword.put_new(opts, :limit, :infinity))
    |> Enum.map(& &1.audit_change)
  end
end
