unless Code.ensure_loaded?(Sigra.Session) do
  defmodule Sigra.Session do
    @moduledoc false

    defstruct [
      :id,
      :user_id,
      :active_organization_id,
      :impersonator_user_id,
      :impersonator_session_id
    ]
  end

  defmodule Sigra.Scope do
    @moduledoc false

    defstruct [:user, :active_organization, :membership, :impersonating_from]
  end

  defmodule Sigra.APIToken do
    @moduledoc false

    defstruct [:user_id, :id]
  end
end
