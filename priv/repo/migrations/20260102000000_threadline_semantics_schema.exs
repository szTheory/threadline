defmodule ThreadlineSemanticsMigration do
  use Ecto.Migration

  def up do
    execute("""
    CREATE TABLE IF NOT EXISTS audit_actions (
      id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
      name           text        NOT NULL,
      actor_ref      jsonb       NOT NULL,
      status         text        NOT NULL CHECK (status IN ('ok', 'error')),
      verb           text,
      category       text,
      reason         text,
      comment        text,
      correlation_id text,
      request_id     text,
      job_id         text,
      inserted_at    timestamptz NOT NULL DEFAULT now()
    )
    """)

    execute("""
    CREATE INDEX IF NOT EXISTS audit_actions_actor_ref_idx
      ON audit_actions USING GIN (actor_ref)
    """)

    execute("""
    CREATE INDEX IF NOT EXISTS audit_actions_inserted_at_idx
      ON audit_actions (inserted_at)
    """)

    execute("""
    CREATE INDEX IF NOT EXISTS audit_actions_name_idx
      ON audit_actions (name)
    """)

    execute("""
    ALTER TABLE audit_transactions
      ADD COLUMN IF NOT EXISTS actor_ref jsonb,
      ADD COLUMN IF NOT EXISTS action_id uuid REFERENCES audit_actions(id) ON DELETE SET NULL
    """)
  end

  def down do
    execute("ALTER TABLE audit_transactions DROP COLUMN IF EXISTS action_id")
    execute("ALTER TABLE audit_transactions DROP COLUMN IF EXISTS actor_ref")
    execute("DROP TABLE IF EXISTS audit_actions")
  end
end
