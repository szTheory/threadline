defmodule ThreadlinePhoenix.Accounts.Scope do
  @moduledoc """
  Defines the scope for authenticated requests.

  The scope carries the current user and is assigned to
  `conn.assigns.current_scope` by the authentication pipeline.

  ## Usage

      scope = ThreadlinePhoenix.Accounts.Scope.for_user(user)
      scope.user #=> %ThreadlinePhoenix.Accounts.User{}

  ## Reserved fields

  `:impersonating_from` is reserved for v1.2 impersonation support and must
  not be removed. See `UPGRADE-v1.2.md` at the project root for the contract.

  """

  alias ThreadlinePhoenix.Accounts.User

  # Reserved for v1.2 impersonation. Do not remove — see UPGRADE-v1.2.md.
  defstruct user: nil,
            active_organization: nil,
            membership: nil,
            impersonating_from: nil

  @type t :: %__MODULE__{
          user: %User{} | nil,
          active_organization: nil,
          membership: nil,
          impersonating_from: %User{} | nil
        }

  @doc """
  Creates a scope for the given user.
  """
  def for_user(%User{} = user) do
    %__MODULE__{user: user}
  end

  def for_user(nil), do: nil

  @doc """
  Creates a scope struct from a user. Used by Sigra plugs.
  """
  def new(%User{} = user) do
    %__MODULE__{user: user}
  end

  def new(nil), do: nil

  @doc """
  Puts the given organization and membership on the scope.

  Called by `Sigra.Plug.PutActiveOrganization`:

    * `(scope, org, membership)` — after a membership check succeeds,
      sets the scope's active organization + membership.
    * `(scope, nil, nil)` — clears both fields. Used on the clear
      path and by `Sigra.Plug.LoadActiveOrganization`'s stale-pointer
      recovery branch.

  This is the single authoritative scope-level write path for
  active-organization transitions (Phase 14 D-15).
  """

  def put_active_organization(%__MODULE__{} = scope, nil, nil) do
    %{scope | active_organization: nil, membership: nil}
  end
end
