defmodule ThreadlinePhoenixWeb.RegistrationController do
  use ThreadlinePhoenixWeb, :controller

  alias ThreadlinePhoenix.Accounts
  alias ThreadlinePhoenix.HelpDesk
  alias ThreadlinePhoenixWeb.UserAuth

  def new(conn, _params) do
    changeset = Accounts.change_user_registration(%Accounts.User{}, %{})
    render(conn, :new, form: Phoenix.Component.to_form(changeset, as: "user"))
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        user_id = to_string(user.id)

        case HelpDesk.provision_default_workspace_for_user(user_id) do
          {:ok, _org} ->
            conn
            |> put_flash(:info, "Account created successfully!")
            |> UserAuth.log_in_user(user, user_params)

          {:error, reason} ->
            conn
            |> put_flash(:error, "Workspace setup failed: #{inspect(reason)}")
            |> redirect(to: ~p"/users/register")
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, form: Phoenix.Component.to_form(changeset, as: "user"))
    end
  end
end
