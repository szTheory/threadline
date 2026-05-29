defmodule ThreadlinePhoenixWeb.WalkthroughCase do
  @moduledoc false

  import ExUnit.Assertions
  import Phoenix.ConnTest

  alias ThreadlinePhoenix.Accounts
  alias ThreadlinePhoenix.Demo.{Manifest, Reset, Seed}
  alias ThreadlinePhoenix.Repo

  @endpoint ThreadlinePhoenixWeb.Endpoint

  def seed_demo_fiction! do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      assert :ok = Reset.run()
      assert :ok = Seed.run()
    end)
  end

  def demo_user!(key) do
    email = Manifest.user_email(key)

    case Accounts.get_user_by_email(email) do
      nil -> flunk("missing seeded demo user #{email}")
      user -> user
    end
  end

  def login_demo(conn, key) do
    ThreadlinePhoenixWeb.ConnCase.login_via_sigra(conn, demo_user!(key))
  end

  def follow_audit_redirect(conn) do
    case conn.status do
      302 -> get(conn, redirected_to(conn))
      _ -> conn
    end
  end

  def admin_conn do
    build_conn()
    |> login_demo(:admin)
  end

  def retention_run_subject_ref do
    %{
      "run_id" => Manifest.evidence_run_id(:offboarded_retention),
      "org_slug" => Manifest.org_slug(:offboarded_co),
      "organization_id" => Manifest.org_id(:offboarded_co)
    }
  end
end
