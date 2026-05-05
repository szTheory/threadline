defmodule Threadline.Integrations.Sigra do
  @moduledoc """
  Soft-dependency adapter for deriving Threadline audit context from Sigra state.

  The adapter reads Sigra-shaped request data when `Sigra.Session` is available
  and otherwise returns neutral defaults so Threadline itself does not require
  `:sigra` as a dependency.
  """

  alias Threadline.Semantics.ActorRef

  @type audit_overrides :: %{optional(:correlation_id) => String.t()}

  @doc """
  Returns an `ActorRef` derived from Sigra request state, or `nil` when the
  request does not carry a supported Sigra actor shape.
  """
  @spec actor_ref_from_conn(Plug.Conn.t()) :: ActorRef.t() | nil
  def actor_ref_from_conn(conn) do
    if sigra_available?() do
      conn
      |> current_scope()
      |> actor_ref_from_scope()
    else
      nil
    end
  end

  @doc """
  Returns additive audit context overrides derived from Sigra request state.
  """
  @spec audit_context_overrides_from_conn(Plug.Conn.t()) :: audit_overrides()
  def audit_context_overrides_from_conn(conn) do
    if header_correlation_id?(conn) do
      %{}
    else
      build_audit_overrides(conn)
    end
  end

  defp build_audit_overrides(conn) do
    if sigra_available?() do
      scope = current_scope(conn)
      sigra_session = sigra_session(conn)

      case build_correlation_id(scope, sigra_session) do
        nil -> %{}
        correlation_id -> %{correlation_id: correlation_id}
      end
    else
      %{}
    end
  end

  @doc """
  Returns the adapter callback in a form suitable for `Threadline.Plug`.
  """
  @spec actor_fn() :: (Plug.Conn.t() -> ActorRef.t() | nil)
  def actor_fn, do: &actor_ref_from_conn/1

  defp header_correlation_id?(conn) do
    conn
    |> Plug.Conn.get_req_header("x-correlation-id")
    |> Enum.any?()
  end

  defp sigra_available?, do: Code.ensure_loaded?(Sigra.Session)

  defp current_scope(conn), do: Map.get(conn.assigns, :current_scope)
  defp sigra_session(conn), do: Map.get(conn.private, :sigra_session)

  defp actor_ref_from_scope(scope) when is_map(scope) do
    cond do
      impersonating_from = Map.get(scope, :impersonating_from) ->
        actor_ref(:admin, nested_id(impersonating_from))

      user = Map.get(scope, :user) ->
        actor_ref(:user, nested_id(user))

      Map.get(scope, :auth_method) in [:api_token, :jwt] ->
        actor_ref(:service_account, scalar_id(scope))

      true ->
        nil
    end
  end

  defp actor_ref_from_scope(_scope), do: nil

  defp actor_ref(type, id) when is_binary(id) do
    case ActorRef.new(type, id) do
      {:ok, ref} -> ref
      {:error, _} -> nil
    end
  end

  defp actor_ref(_type, _id), do: nil

  defp build_correlation_id(scope, sigra_session) do
    base =
      cond do
        is_map(scope) and Map.get(scope, :impersonating_from) ->
          "sigra-imp:#{session_id(sigra_session)}:user:#{impersonated_user_id(scope)}"

        is_map(scope) and Map.get(scope, :user) ->
          "sigra-session:#{session_id(sigra_session)}"

        is_map(scope) and Map.get(scope, :auth_method) in [:api_token, :jwt] ->
          "sigra-token:#{token_id(scope)}"

        true ->
          nil
      end

    maybe_append_org(base, scope, sigra_session)
  end

  defp maybe_append_org(nil, _scope, _sigra_session), do: nil

  defp maybe_append_org(base, scope, sigra_session) do
    case organization_id(scope, sigra_session) do
      nil -> base
      org_id -> "#{base}:org:#{org_id}"
    end
  end

  defp organization_id(scope, sigra_session) do
    cond do
      is_map(scope) and is_binary(Map.get(scope, :active_organization_id)) and
          Map.get(scope, :active_organization_id) != "" ->
        Map.get(scope, :active_organization_id)

      is_map(scope) ->
        organization_id_from_active(Map.get(scope, :active_organization)) ||
          organization_id_from_membership(Map.get(scope, :membership)) ||
          session_org_id(sigra_session)

      true ->
        session_org_id(sigra_session)
    end
  end

  defp organization_id_from_active(active_organization) when is_map(active_organization) do
    scalar_id(active_organization)
  end

  defp organization_id_from_active(_), do: nil

  defp organization_id_from_membership(membership) when is_map(membership) do
    membership
    |> Map.get(:organization)
    |> organization_id_from_active()
  end

  defp organization_id_from_membership(_), do: nil

  defp session_org_id(sigra_session) when is_map(sigra_session) do
    case Map.get(sigra_session, :active_organization_id) do
      org_id when is_binary(org_id) and org_id != "" -> org_id
      _ -> nil
    end
  end

  defp session_org_id(_), do: nil

  defp session_id(sigra_session) when is_map(sigra_session), do: scalar_id(sigra_session)
  defp session_id(_), do: nil

  defp token_id(scope) when is_map(scope) do
    case Map.get(scope, :token_id) do
      token_id when is_binary(token_id) and token_id != "" -> token_id
      _ -> nil
    end
  end

  defp token_id(_), do: nil

  defp impersonated_user_id(scope) when is_map(scope) do
    scope
    |> Map.get(:user)
    |> nested_id()
  end

  defp impersonated_user_id(_), do: nil

  defp scalar_id(map) when is_map(map) do
    case Map.get(map, :id) do
      id when is_binary(id) and id != "" -> id
      _ -> nil
    end
  end

  defp scalar_id(_), do: nil

  defp nested_id(map) when is_map(map), do: scalar_id(map)
  defp nested_id(_), do: nil
end
