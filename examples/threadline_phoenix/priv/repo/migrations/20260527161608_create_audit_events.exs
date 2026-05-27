defmodule ThreadlinePhoenix.Repo.Migrations.CreateAuditEvents do
  use Ecto.Migration

  def change do
    create table(:audit_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :occurred_at, :utc_datetime_usec, null: false
      add :action, :string, null: false, size: 255
      add :outcome, :string, null: false, size: 32
      add :actor_id, :binary_id, null: true
      add :actor_type, :string, null: false, size: 64, default: "user"
      add :target_id, :binary_id, null: true
      add :target_type, :string, null: true, size: 64
      add :ip_address, :string, null: true, size: 64
      add :user_agent, :string, null: true, size: 512
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:audit_events, [:actor_id, :inserted_at])
    create index(:audit_events, [:action, :inserted_at])
    create index(:audit_events, [:inserted_at])
  end
end
