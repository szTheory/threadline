defmodule Threadline.Repo.Migrations.AddAuditChangesChangedFrom do
  use Ecto.Migration

  def up do
    execute("ALTER TABLE audit_changes ADD COLUMN IF NOT EXISTS changed_from jsonb")
  end

  def down do
    execute("ALTER TABLE audit_changes DROP COLUMN IF EXISTS changed_from")
  end
end
