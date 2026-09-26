defmodule ThreadlineRowHistoryIndex do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute(
      Threadline.Capture.RowHistoryIndexSQL.create_concurrently_sql(storage_schema: "threadline")
    )
  end

  def down do
    execute(
      Threadline.Capture.RowHistoryIndexSQL.drop_concurrently_sql(storage_schema: "threadline")
    )
  end
end
