defmodule Threadline.OperatorSurfaceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "README declares the operator surface mount macro" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "threadline_operator_surface")
  end

  test "README documents fail-closed posture and links guide" do
    readme = File.read!("README.md")
    assert String.contains?(readme, "fail-closed")
    assert String.contains?(readme, "guides/operator-surface.md")
  end

  test "operator surface guide declares route literals" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "/audit/transactions/:id")
    assert String.contains?(guide, "/audit/actors/:kind/:id")
    assert String.contains?(guide, "/audit/rows/:table/:pk")
  end

  test "operator surface guide details fail-closed security and auth options" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "fail-closed")
    assert String.contains?(guide, ":authorize_fn")
    assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true")
  end

  test "operator surface guide locks the canonical admin and support recipes" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "pipe_through [:browser, :admin_auth]")
    assert String.contains?(guide, "support-read-only variation")
    assert String.contains?(guide, "exports: false")
    assert String.contains?(guide, "organization_id")
    refute String.contains?(guide, "support_roles =")
    refute String.contains?(guide, "permissions_dsl")
  end

  test "operator surface guide links the canonical upgrade-path guide and stays scoped" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "guides/upgrade-path.md")
    assert String.contains?(guide, "guides/integration-contracts.md")
    assert String.contains?(guide, "{:threadline, \"~> 0.5\"}")
    refute String.contains?(guide, "{:threadline, \"~> 0.3.0\"}")
    refute String.contains?(guide, "{:phoenix, \"~> 1.7\"}")
    assert String.contains?(guide, "This guide stays focused on mount, auth, and screens.")
    refute String.contains?(guide, "## Supported compatibility matrix")
    refute String.contains?(guide, "## Surface-only deprecation and removal policy")
  end

  test "operator surface guide locks callback shape and export fallback wording" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(
             guide,
             "The `:authorize_fn` callback is invoked directly as a 1-arity function."
           )

    assert String.contains?(guide, "`%{assigns: assigns}`")
    assert String.contains?(guide, "it receives the socket-shaped value")

    assert String.contains?(
             guide,
             "they call it with a synthetic `%{assigns: conn.assigns}` mirror."
           )

    assert String.contains?(guide, "`{:ok, scope}` - Allowed.")
    assert String.contains?(guide, "host-owned and opaque")

    assert String.contains?(
             guide,
             "`live_session` and `on_mount` protect the LiveView pages only"
           )

    assert String.contains?(guide, "plain-text `403`")
    refute String.contains?(guide, "{:cont, socket}")
    refute String.contains?(guide, "{:ok, socket}")
    refute String.contains?(guide, "{:ok, conn}")
  end

  test "operator surface guide locks mounted parity table and rejects overclaiming" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "## Mounted workflow parity")
    assert String.contains?(guide, "mix threadline.incident <transaction_id>")
    assert String.contains?(guide, "mix threadline.export --dry-run --table posts")
    assert String.contains?(guide, "mix threadline.health.coverage")
    assert String.contains?(guide, "mix threadline.policy.show")
    assert String.contains?(guide, "Threadline.actor_history/2")
    assert String.contains?(guide, "Threadline.history/3")
    assert String.contains?(guide, "Threadline.as_of/4")
    refute String.contains?(guide, "every page is blocked for support")
    refute String.contains?(guide, "universal scope narrowing")
  end
end
