defmodule ThreadlineQueryIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute("""
    CREATE INDEX CONCURRENTLY IF NOT EXISTS audit_transactions_actor_ref_gin
      ON audit_transactions USING GIN (actor_ref)
    """)
  end

  def down do
    execute("DROP INDEX CONCURRENTLY IF EXISTS audit_transactions_actor_ref_gin")
  end
end
