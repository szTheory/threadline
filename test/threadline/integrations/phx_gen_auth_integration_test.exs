defmodule PhxGenAuthScope do
  @moduledoc false
  defstruct [:user]
end

defmodule Threadline.Integrations.PhxGenAuthReference.AuditActor do
  @moduledoc false

  alias Threadline.Semantics.ActorRef

  def actor_ref_from_conn(conn) do
    case conn.assigns[:current_scope] do
      %{user: %{id: id}} when not is_nil(id) ->
        {:ok, ref} = ActorRef.new(:user, to_string(id))
        ref

      _ ->
        nil
    end
  end

  def audit_context_overrides_from_conn(_conn), do: %{}
end

defmodule Threadline.Integrations.PhxGenAuthReference.Audit do
  @moduledoc false

  def authorize_operator(%{assigns: assigns}) do
    user =
      case assigns[:current_scope] do
        %{user: user} when not is_nil(user) -> user
        _ -> assigns[:current_user]
      end

    case user do
      %{is_admin: true} -> :ok
      _ -> {:error, :unauthorized}
    end
  end
end

defmodule Threadline.Integrations.PhxGenAuthIntegrationTest do
  @moduledoc """
  Root CI proof for the `phx-gen-auth-reference` lane.

  Copy `Threadline.Integrations.PhxGenAuthReference.AuditActor` into your host as
  `MyApp.AuditActor`. Reference semantics items 4–6 are proven in
  `test/threadline/plug_test.exs`.
  """

  use ExUnit.Case, async: true

  alias Threadline.Integrations.PhxGenAuthReference.{Audit, AuditActor}
  alias Threadline.OperatorSurface.ExportAuthPlug
  alias Threadline.PhxGenAuthFixtures
  alias Threadline.Semantics.{ActorRef, AuditContext}

  describe "guide AuditActor actor_fn" do
    test "returns nil when current_scope key is absent" do
      assert AuditActor.actor_ref_from_conn(PhxGenAuthFixtures.build_phx_scope_conn()) == nil
    end

    test "returns nil when current_scope is nil" do
      conn = PhxGenAuthFixtures.build_phx_scope_conn(scope: nil)
      assert AuditActor.actor_ref_from_conn(conn) == nil
    end

    test "returns nil when current_scope.user is nil" do
      conn = PhxGenAuthFixtures.build_phx_scope_conn(scope: %{user: nil})
      assert AuditActor.actor_ref_from_conn(conn) == nil
    end

    test "returns a user actor for a logged-in scope map" do
      conn = PhxGenAuthFixtures.build_phx_scope_conn(scope: PhxGenAuthFixtures.logged_in_scope())
      assert %ActorRef{type: :user, id: "u-42"} = AuditActor.actor_ref_from_conn(conn)
    end

    test "returns a user actor when scope is a struct with the same keys" do
      scope = struct(PhxGenAuthScope, %{user: %{id: "u-42"}})
      conn = PhxGenAuthFixtures.build_phx_scope_conn(scope: scope)
      assert %ActorRef{type: :user, id: "u-42"} = AuditActor.actor_ref_from_conn(conn)
    end

    test "audit_context_overrides_from_conn returns an empty map" do
      conn = PhxGenAuthFixtures.build_phx_scope_conn(scope: PhxGenAuthFixtures.logged_in_scope())
      assert AuditActor.audit_context_overrides_from_conn(conn) == %{}
    end
  end

  describe "guide authorize_fn admin gate" do
    test "allows admin via current_scope.user with is_admin true" do
      conn =
        PhxGenAuthFixtures.build_phx_scope_conn(
          scope: %{user: PhxGenAuthFixtures.admin_scope_user()}
        )

      conn_out =
        ExportAuthPlug.call(conn, ExportAuthPlug.init(authorize_fn: &Audit.authorize_operator/1))

      refute conn_out.halted
    end

    test "denies non-admin via current_scope.user with 403" do
      conn =
        PhxGenAuthFixtures.build_phx_scope_conn(
          scope: %{user: PhxGenAuthFixtures.member_scope_user()}
        )

      conn_out =
        ExportAuthPlug.call(conn, ExportAuthPlug.init(authorize_fn: &Audit.authorize_operator/1))

      assert conn_out.halted
      assert conn_out.status == 403
      assert conn_out.resp_body == "forbidden"
    end

    test "allows admin via current_user fallback when scope user absent" do
      conn =
        PhxGenAuthFixtures.build_phx_scope_conn(
          scope: nil,
          current_user: %{is_admin: true, id: "legacy-admin"}
        )

      conn_out =
        ExportAuthPlug.call(conn, ExportAuthPlug.init(authorize_fn: &Audit.authorize_operator/1))

      refute conn_out.halted
    end
  end

  describe "Threadline.Plug composition" do
    test "guide callbacks compose with Threadline.Plug once" do
      conn =
        PhxGenAuthFixtures.build_phx_scope_conn(
          scope: PhxGenAuthFixtures.logged_in_scope(),
          headers: [{"x-request-id", "req-phx-1"}]
        )
        |> Threadline.Plug.call(
          Threadline.Plug.init(
            actor_fn: &AuditActor.actor_ref_from_conn/1,
            context_overrides_fn: &AuditActor.audit_context_overrides_from_conn/1
          )
        )

      assert %AuditContext{
               actor_ref: %ActorRef{type: :user, id: "u-42"},
               request_id: "req-phx-1"
             } = conn.assigns.audit_context
    end
  end
end
