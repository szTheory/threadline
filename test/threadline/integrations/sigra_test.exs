defmodule Threadline.Integrations.SigraTest do
  use ExUnit.Case, async: true

  import Plug.Conn
  import Plug.Test

  alias Threadline.Integrations.Sigra, as: SigraAdapter
  alias Threadline.Semantics.{ActorRef, AuditContext}

  describe "soft dependency doubles" do
    test "Sigra.Session shim exposes only the required fields" do
      assert %Sigra.Session{
               id: nil,
               user_id: nil,
               active_organization_id: nil,
               impersonator_user_id: nil,
               impersonator_session_id: nil
             } = %Sigra.Session{}
    end

    test "Sigra.Scope shim exposes only the required fields" do
      assert %Sigra.Scope{
               user: nil,
               active_organization: nil,
               membership: nil,
               impersonating_from: nil
             } = %Sigra.Scope{}
    end

    test "Sigra.APIToken shim preserves locked field order" do
      assert %Sigra.APIToken{user_id: nil, id: nil} = %Sigra.APIToken{}
      assert Map.from_struct(%Sigra.APIToken{}) == %{user_id: nil, id: nil}
    end
  end

  describe "actor_ref_from_conn/1" do
    test "returns nil when current_scope key is absent" do
      assert SigraAdapter.actor_ref_from_conn(conn(:get, "/")) == nil
    end

    test "returns nil when current_scope is nil" do
      assert conn(:get, "/") |> assign(:current_scope, nil) |> SigraAdapter.actor_ref_from_conn() ==
               nil
    end

    test "returns nil when current_scope.user is nil" do
      assert conn(:get, "/")
             |> assign(:current_scope, %{user: nil})
             |> SigraAdapter.actor_ref_from_conn() == nil
    end

    test "returns a user actor for a user scope" do
      conn = build_sigra_conn(scope: %{user: %{id: "u-42"}})

      assert %ActorRef{type: :user, id: "u-42"} = SigraAdapter.actor_ref_from_conn(conn)
    end

    test "returns an admin actor for an impersonation scope" do
      conn =
        build_sigra_conn(
          scope: %{impersonating_from: %{id: "admin-7"}, user: %{id: "imp-user-1"}}
        )

      assert %ActorRef{type: :admin, id: "admin-7"} = SigraAdapter.actor_ref_from_conn(conn)
    end

    test "returns a service_account actor for an api token scope" do
      conn = build_sigra_conn(scope: %{auth_method: :api_token, id: "u-99"})

      assert %ActorRef{type: :service_account, id: "u-99"} =
               SigraAdapter.actor_ref_from_conn(conn)
    end

    test "returns a service_account actor for a jwt token scope" do
      conn = build_sigra_conn(scope: %{auth_method: :jwt, id: "u-100"})

      assert %ActorRef{type: :service_account, id: "u-100"} =
               SigraAdapter.actor_ref_from_conn(conn)
    end
  end

  describe "audit_context_overrides_from_conn/1" do
    test "returns empty overrides for baseline anonymous shapes" do
      assert %{} = SigraAdapter.audit_context_overrides_from_conn(conn(:get, "/"))

      assert %{} =
               conn(:get, "/")
               |> assign(:current_scope, nil)
               |> SigraAdapter.audit_context_overrides_from_conn()

      assert %{} =
               conn(:get, "/")
               |> assign(:current_scope, %{user: nil})
               |> SigraAdapter.audit_context_overrides_from_conn()
    end

    test "returns a plain session correlation_id" do
      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "u-42"}
        )

      assert %{correlation_id: "sigra-session:s-1"} =
               SigraAdapter.audit_context_overrides_from_conn(conn)
    end

    test "returns an impersonation correlation_id with the impersonated user" do
      conn =
        build_sigra_conn(
          scope: %{impersonating_from: %{id: "admin-7"}, user: %{id: "imp-user-1"}},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "admin-7"}
        )

      assert %{correlation_id: "sigra-imp:s-1:user:imp-user-1"} =
               SigraAdapter.audit_context_overrides_from_conn(conn)
    end

    test "returns a token correlation_id" do
      conn =
        build_sigra_conn(scope: %{auth_method: :api_token, id: "u-99", token_id: "tok-1"})

      assert %{correlation_id: "sigra-token:tok-1"} =
               SigraAdapter.audit_context_overrides_from_conn(conn)
    end

    test "returns empty overrides when x-correlation-id header is already present" do
      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "u-42"},
          headers: [{"x-correlation-id", "explicit-cid"}]
        )

      assert %{} = SigraAdapter.audit_context_overrides_from_conn(conn)
    end

    test "appends organization suffix from scope active_organization_id" do
      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}, active_organization_id: "99"},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "u-42"}
        )

      assert %{correlation_id: "sigra-session:s-1:org:99"} =
               SigraAdapter.audit_context_overrides_from_conn(conn)
    end

    test "appends organization suffix from active_organization map fallback" do
      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}, active_organization: %{id: "77"}},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "u-42"}
        )

      assert %{correlation_id: "sigra-session:s-1:org:77"} =
               SigraAdapter.audit_context_overrides_from_conn(conn)
    end

    test "appends organization suffix from session fallback" do
      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}},
          sigra_session: %Sigra.Session{
            id: "s-1",
            user_id: "u-42",
            active_organization_id: "42"
          }
        )

      assert %{correlation_id: "sigra-session:s-1:org:42"} =
               SigraAdapter.audit_context_overrides_from_conn(conn)
    end
  end

  describe "actor_fn/0" do
    test "returns a callback suitable for Threadline.Plug" do
      {:ok, expected_ref} = ActorRef.new(:user, "u-42")

      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}},
          headers: [{"x-request-id", "req-1"}, {"x-correlation-id", "corr-1"}]
        )
        |> Threadline.Plug.call(Threadline.Plug.init(actor_fn: SigraAdapter.actor_fn()))

      assert %AuditContext{
               actor_ref: ^expected_ref,
               request_id: "req-1",
               correlation_id: "corr-1"
             } =
               conn.assigns.audit_context
    end
  end

  describe "Threadline.Plug integration" do
    test "direct Sigra callbacks compose with Threadline.Plug" do
      {:ok, expected_ref} = ActorRef.new(:user, "u-42")

      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}},
          sigra_session: %Sigra.Session{
            id: "s-1",
            user_id: "u-42",
            active_organization_id: "org-9"
          },
          headers: [{"x-request-id", "req-1"}]
        )
        |> Threadline.Plug.call(
          Threadline.Plug.init(
            actor_fn: &SigraAdapter.actor_ref_from_conn/1,
            context_overrides_fn: &SigraAdapter.audit_context_overrides_from_conn/1
          )
        )

      assert %AuditContext{
               actor_ref: ^expected_ref,
               request_id: "req-1",
               correlation_id: "sigra-session:s-1:org:org-9"
             } = conn.assigns.audit_context
    end

    test "explicit x-correlation-id header still wins when using Threadline.Plug" do
      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "u-42"},
          headers: [{"x-request-id", "req-1"}, {"x-correlation-id", "explicit-cid"}]
        )
        |> Threadline.Plug.call(
          Threadline.Plug.init(
            actor_fn: SigraAdapter.actor_fn(),
            context_overrides_fn: &SigraAdapter.audit_context_overrides_from_conn/1
          )
        )

      assert %AuditContext{correlation_id: "explicit-cid"} = conn.assigns.audit_context
    end

    test "actor identity still comes from actor_fn only when using context overrides" do
      {:ok, expected_ref} = ActorRef.new(:admin, "admin-7")

      conn =
        build_sigra_conn(
          scope: %{impersonating_from: %{id: "admin-7"}, user: %{id: "imp-user-1"}},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "admin-7"}
        )
        |> Threadline.Plug.call(
          Threadline.Plug.init(
            actor_fn: SigraAdapter.actor_fn(),
            context_overrides_fn: &SigraAdapter.audit_context_overrides_from_conn/1
          )
        )

      assert %AuditContext{
               actor_ref: ^expected_ref,
               correlation_id: "sigra-imp:s-1:user:imp-user-1"
             } = conn.assigns.audit_context
    end

    test "existing request values stay authoritative even if an override callback misbehaves" do
      misbehaving_callback = fn _conn ->
        %{request_id: "override-req", correlation_id: "override-corr"}
      end

      conn =
        build_sigra_conn(
          scope: %{user: %{id: "u-42"}},
          sigra_session: %Sigra.Session{id: "s-1", user_id: "u-42"},
          headers: [{"x-request-id", "req-1"}, {"x-correlation-id", "explicit-cid"}]
        )
        |> Threadline.Plug.call(
          Threadline.Plug.init(
            actor_fn: SigraAdapter.actor_fn(),
            context_overrides_fn: misbehaving_callback
          )
        )

      assert %AuditContext{
               request_id: "req-1",
               correlation_id: "explicit-cid"
             } = conn.assigns.audit_context
    end
  end

  defp build_sigra_conn(opts) do
    scope = Keyword.get(opts, :scope)
    headers = Keyword.get(opts, :headers, [])
    sigra_session = Keyword.get(opts, :sigra_session)

    conn =
      Enum.reduce(headers, conn(:get, "/"), fn {key, value}, acc ->
        put_req_header(acc, key, value)
      end)

    conn =
      if Keyword.has_key?(opts, :scope) do
        assign(conn, :current_scope, scope)
      else
        conn
      end

    if sigra_session do
      %{conn | private: Map.put(conn.private, :sigra_session, sigra_session)}
    else
      conn
    end
  end
end
