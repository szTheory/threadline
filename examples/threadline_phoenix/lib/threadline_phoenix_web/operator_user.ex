defmodule ThreadlinePhoenixWeb.OperatorUser do
  @moduledoc """
  Maps Sigra `current_scope` to help-desk-aware `current_user` for `/audit`.

  Recomputes `current_user` on every request (no full map in session).
  When impersonating, `is_admin` and desk `role` come from the impersonator only.
  """

  import Plug.Conn

  alias ThreadlinePhoenix.HelpDesk

  @doc """
  Builds the operator `current_user` map from scope and connection, or `nil`.
  """
  @spec build_operator_user(map() | nil, Plug.Conn.t()) :: map() | nil
  def build_operator_user(%{user: %{id: user_id} = user} = scope, conn) do
    user_id_str = to_string(user_id)
    org_id = organization_id(conn, user_id_str)

    {role_user_id, is_admin_user} =
      case Map.get(scope, :impersonating_from) do
        %{id: _} = impersonator ->
          {to_string(impersonator.id), impersonator}

        _ ->
          {user_id_str, user}
      end

    role =
      case org_id do
        nil -> nil
        oid -> HelpDesk.get_membership_role(role_user_id, oid)
      end

    %{
      id: user_id,
      organization_id: org_id,
      role: role,
      is_admin: is_admin?(is_admin_user)
    }
  end

  def build_operator_user(_scope, _conn), do: nil

  @doc false
  def assign_from_scope(conn, _opts) do
    scope = conn.assigns[:current_scope]

    case build_operator_user(scope, conn) do
      nil -> conn
      user -> assign(conn, :current_user, user)
    end
  end

  defp organization_id(conn, user_id_str) do
    case conn.private[:sigra_session] do
      %{active_organization_id: org_id} when not is_nil(org_id) ->
        to_string(org_id)

      _ ->
        HelpDesk.get_organization_id_for_user(user_id_str)
    end
  end

  defp is_admin?(user) do
    config = Application.get_env(:threadline_phoenix, __MODULE__, [])
    emails = Keyword.get(config, :admin_emails, [])
    user_ids = Keyword.get(config, :admin_user_ids, [])

    user_id = to_string(user.id)
    email = Map.get(user, :email)

    user_id in Enum.map(user_ids, &to_string/1) or email in emails
  end
end
