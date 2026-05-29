defmodule ThreadlinePhoenix.Repo.Migrations.CreateHelpDeskTables do
  use Ecto.Migration

  def change do
    create table(:organizations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string, null: false
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:organizations, [:slug])

    create table(:org_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, :string, null: false
      add :role, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:org_memberships, [:organization_id, :user_id])

    create table(:agents, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :user_id, :string, null: false
      add :display_name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:agents, [:organization_id, :user_id])

    create table(:tickets, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :organization_id, references(:organizations, type: :binary_id, on_delete: :delete_all),
        null: false

      add :number, :integer, null: false
      add :status, :string, null: false, default: "open"
      add :assignee_id, references(:agents, type: :binary_id, on_delete: :nilify_all)
      add :closed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:tickets, [:organization_id, :number])

    create table(:ticket_replies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ticket_id, references(:tickets, type: :binary_id, on_delete: :delete_all), null: false
      add :body, :text, null: false
      add :internal_note_body, :text

      timestamps(type: :utc_datetime)
    end
  end
end
