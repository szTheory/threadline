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
  import ThreadlinePhoenixWeb.WalkthroughCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.AuditAction
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.HelpDesk.{Agent, Organization, Ticket}
  alias ThreadlinePhoenix.Repo

  setup do
    seed_demo_fiction!()
    :ok
  end

  describe "§1 clean clone / landing (WALK-01-04)" do
    test "logged-out home exposes register and log in", %{conn: conn} do
      conn = get(conn, ~p"/")
      html = html_response(conn, 200)

      assert html =~ "RelayDesk"
      assert html =~ "What to click first"
      assert html =~ "walk-acme-4521-close"
      assert html =~ "operator surface is mounted"
      assert html =~ "Register"
      assert html =~ "Log in"
      refute html =~ "Signed in as"
      refute html =~ ~s|href="/audit"|
    end
  end

  describe "§2 onboarding (WALK-01-05..07)" do
    test "WALK-01-06 support user reaches org-scoped audit timeline" do
      conn =
        build_conn()
        |> login_demo(:support_acme)
        |> get(~p"/audit/timeline")
        |> follow_audit_redirect()

      html = html_response(conn, 200)
      refute html =~ "Forbidden"
      assert html =~ "correlation_id"
    end

    test "WALK-01-07 support ticket reply via dev route returns audit_transaction_id" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")

        agent =
          Repo.get_by!(Agent, organization_id: acme.id, user_id: Manifest.user_id(:support_acme))

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
            from(a in AuditAction,
              join: at in AuditTransaction,
              on: a.id == at.action_id,
              where: at.id == ^tx_id,
              where: a.name == "ticket_replied_and_closed"
            )
          )

        refute is_nil(action)

        admin_conn =
          build_conn()
          |> login_demo(:admin)
          |> get(~p"/audit/transactions/#{tx_id}")

        html = html_response(admin_conn, 200)
        assert html =~ "ticket_replies"
        assert html =~ "tickets"
      end)
    end

    test "WALK-02-02 admin reaches cross-org audit timeline" do
      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/timeline")
        |> follow_audit_redirect()

      html = html_response(conn, 200)
      refute html =~ "Forbidden"
      assert html =~ "correlation_id"
    end

    test "WALK-02-03 support cannot export from operator surface" do
      conn =
        build_conn()
        |> login_demo(:support_acme)
        |> get(~p"/audit/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00")

      assert response(conn, 403) == "forbidden"
    end

    test "admin export status shows seeded job states" do
      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/exports")

      html = html_response(conn, 200)
      assert html =~ "Ready to hand off"
      assert html =~ "Completed"
      assert html =~ "Failed"
      assert html =~ "Running"
      assert html =~ "Queued"
      assert html =~ "Download export"
      assert html =~ "Export expired"
    end
  end

  describe "§4 operator incidents (WALK-03-01..04)" do
    test "WALK-03-01 correlation filter surfaces hero #4521 close transaction" do
      correlation = Manifest.correlation_id(:acme_4521_close)

      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/timeline?correlation_id=#{correlation}")

      html = html_response(conn, 200)
      assert html =~ correlation
      assert html =~ "tickets"
    end

    test "WALK-03-02 admin actor history for agent2 persona" do
      agent2_id = "33123cc4-da21-5674-b030-e168cee90521"

      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/actors/user/#{agent2_id}")

      html = html_response(conn, 200)
      refute html =~ "Forbidden"
      assert html =~ "Actor"
      assert html =~ agent2_id
    end

    test "WALK-03-03 retention evidence row present for offboarded-co purge proof" do
      run_id = Manifest.evidence_run_id(:offboarded_retention)

      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/evidence")

      html = html_response(conn, 200)
      assert html =~ "retention_run"
      assert html =~ run_id
    end

    test "retention history shows seeded completed purge run" do
      conn =
        build_conn()
        |> login_demo(:admin)
        |> get(~p"/audit/policy/retention")

      html = html_response(conn, 200)
      assert html =~ "Retention window"
      assert html =~ "completed"
      refute html =~ "No retention runs yet"
    end

    test "WALK-03-04 deleter hard-delete on #4518 visible to admin" do
      Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
        acme = Repo.get_by!(Organization, slug: "acme")
        _ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4518)
        deleter_id = Manifest.user_id(:deleter)
        delete_at = DateTime.add(Manifest.last_tuesday(), 2, :hour)

        at =
          from(ac in AuditChange,
            join: at in assoc(ac, :transaction),
            where: ac.table_name == "ticket_replies",
            where: ac.op == "delete",
            where: fragment("?->>'organization_id' = ?", at.meta, ^to_string(acme.id)),
            where: at.occurred_at == ^delete_at,
            select: at
          )
          |> Repo.all()
          |> Enum.find(fn at ->
            match?(%Threadline.Semantics.ActorRef{type: :user, id: ^deleter_id}, at.actor_ref)
          end)

        refute is_nil(at)

        conn =
          build_conn()
          |> login_demo(:admin)
          |> get(~p"/audit/transactions/#{at.id}")

        html = html_response(conn, 200)
        assert html =~ "ticket_replies"
        assert html =~ "DELETE"
      end)
    end
  end
end
