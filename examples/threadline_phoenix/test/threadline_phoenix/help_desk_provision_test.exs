defmodule ThreadlinePhoenix.HelpDeskProvisionTest do
  use ThreadlinePhoenix.DataCase, async: true

  alias ThreadlinePhoenix.HelpDesk
  alias ThreadlinePhoenix.HelpDesk.{OrgMembership, Organization}
  alias ThreadlinePhoenix.Repo

  test "provision_default_workspace_for_user/2 creates org, membership, and agent" do
    user_id = Ecto.UUID.generate()

    assert {:ok, %Organization{} = org} = HelpDesk.provision_default_workspace_for_user(user_id)

    membership =
      Repo.get_by!(OrgMembership, organization_id: org.id, user_id: user_id)

    assert membership.role == "agent"

    assert Repo.get_by(ThreadlinePhoenix.HelpDesk.Agent,
             organization_id: org.id,
             user_id: user_id
           )
  end

  test "provision_default_workspace_for_user/2 is idempotent for the same user_id" do
    user_id = Ecto.UUID.generate()

    assert {:ok, org1} = HelpDesk.provision_default_workspace_for_user(user_id)
    assert {:ok, org2} = HelpDesk.provision_default_workspace_for_user(user_id)

    assert org1.id == org2.id
    assert 1 == Repo.aggregate(from(m in OrgMembership, where: m.user_id == ^user_id), :count)
  end
end
