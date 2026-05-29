defmodule ThreadlinePhoenixWeb.WalkthroughHappyPathTest do
  @moduledoc """
  ConnCase automation for maintainer WALKTHROUGH happy paths (§1–§4).

  Replaces manual browser verification called out in WALKTHROUGH.md where
  HTTP-level proof is sufficient. Doc-contract tests lock prose; this module
  locks behavior on seeded demo fiction.
  """
  use ThreadlinePhoenixWeb.ConnCase, async: false

  import Ecto.Query
  import ThreadlinePhoenix.HelpDeskFixtures

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.AuditAction
  alias ThreadlinePhoenix.Accounts
  alias ThreadlinePhoenix.Demo.{Manifest, Reset, Seed}
  alias ThreadlinePhoenix.HelpDesk.{Agent, Organization}
  alias ThreadlinePhoenix.Repo

  setup do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      assert :ok = Reset.run()
      assert :ok = Seed.run()
    end)

    :ok
  end

  describe "§1 clean clone / landing (WALK-01-04)" do
    test "logged-out home exposes register and log in", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ "Register"
      assert html =~ "Log in"
      refute html =~ "Signed in as"
    end
  end

  describe "§2 onboarding (WALK-01-05..07)" do
    test "WALK-01-06 support user reaches org-scoped audit timeline" do
      conn =
        build_conn()
        |> login_demo(:support_acme)
        |> get(~p"/audit")
        |> follow_audit_redirect()

      html = html_response(conn, 200)
      refute html =~ "Forbidden"
      assert html =~ "timeline" or html =~ "Audit" or html =~ "audit"
    end

    test "WALK-01-07 support ticket reply via dev route returns audit_transaction_id" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        agent = Repo.get_by!(Agent, organization_id: acme.id, user_id: Manifest.user_id(:support_acme))
        ticket = ticket_fixture(acme, agent)

        conn =
          build_conn()
          |> login_demo(:support_acme)
          |> recycle()
          |> get(~p"/")
          |> post(~p"/dev/help_desk/ticket_reply", %{
            "organization_id" => acme.id,
            "ticket_id" => ticket.id,
            "body" => "Walkthrough automation reply"
          })

        assert %{"audit_transaction_id" => tx_id} = json_response(conn, 200)
        assert Repo.get!(AuditTransaction, tx_id)
      end)
    end
  end

  describe "§3 daily use (WALK-02-01..03)" do
    test "WALK-02-01 closer ticket reply captured; admin views transaction semantics" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        agent = Repo.get_by!(Agent, organization_id: acme.id, user_id: Manifest.user_id(:closer))
        ticket = ticket_fixture(acme, agent)

        conn =
          build_conn()
          |> login_demo(:closer)
          |> recycle()
          |> get(~p"/")
          |> post(~p"/dev/help_desk/ticket_reply", %{
            "organization_id" => acme.id,
            "ticket_id" => ticket.id,
            "body" => "Closer walkthrough reply"
          })

        assert %{"audit_transaction_id" => tx_id} = json_response(conn, 200)

        action =
          Repo.one!(
            from a in AuditAction,
              join: at in AuditTransaction,
              on: a.id == at.action_id,
              where: at.id == ^tx_id,
              where: a.name == "ticket_replied_and_closed"
          )

        refute is_nil(action)

        admin_conn =
          build_conn()
          |> login_demo(:admin)
          |> get(~p"/audit/transactions/#{tx_id}")

        html = html_response(admin_conn, 200)
        assert html =~ "ticket_replies" or html =~ "tickets"
      end)
    end

    test "WALK-02-02 admin reaches cross-org audit timeline" do
      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit")
        |> follow_audit_redirect()

      html = html_response(conn, 200)
      refute html =~ "Forbidden"
      assert html =~ "timeline" or html =~ "Audit"
    end

    test "WALK-02-03 support cannot export from operator surface" do
      conn =
        build_conn()
        |> login_demo(:support_acme)
        |> get(~p"/audit/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00")

      assert response(conn, 403) == "forbidden"
    end
  end

  describe "§4 operator incidents (WALK-03-01..03)" do
    test "WALK-03-01 correlation filter surfaces hero #4521 close transaction" do
      correlation = Manifest.correlation_id(:acme_4521_close)

      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit?#{%{filter: %{correlation_id: correlation}}}")

      html = html_response(conn, 200)
      assert html =~ correlation or html =~ "4521" or html =~ "ticket"
    end

    test "WALK-03-02 admin actor history for agent2 persona" do
      agent2_id = "33123cc4-da21-5674-b030-e168cee90521"

      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/actors/user/#{agent2_id}")

      html = html_response(conn, 200)
      refute html =~ "Forbidden"
      assert html =~ "Actor" or html =~ "agent2" or html =~ "tickets"
    end

    test "WALK-03-03 retention evidence row present for offboarded-co purge proof" do
      run_id = Manifest.evidence_run_id(:offboarded_retention)

      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/evidence")

      html = html_response(conn, 200)
      assert html =~ "retention_run" or html =~ run_id or html =~ "offboarded"
    end
  end

  defp demo_user!(key) do
    email = Manifest.user_email(key)

    case Accounts.get_user_by_email(email) do
      nil -> flunk("missing seeded demo user #{email}")
      user -> user
    end
  end

  defp login_demo(conn, key) do
    login_via_sigra(conn, demo_user!(key))
  end

  defp follow_audit_redirect(conn) do
    case conn.status do
      302 -> get(conn, redirected_to(conn))
      _ -> conn
    end
  end
end
