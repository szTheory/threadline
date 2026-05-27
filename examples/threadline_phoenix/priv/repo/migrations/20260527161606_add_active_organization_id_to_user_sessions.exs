defmodule ThreadlinePhoenix.Repo.Migrations.AddActiveOrganizationIdToUserSessions do
  use Ecto.Migration

  def change do
    alter table(:user_sessions) do
      add :active_organization_id, :binary_id
    end
  end
end
