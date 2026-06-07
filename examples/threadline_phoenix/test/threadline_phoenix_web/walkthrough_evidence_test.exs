defmodule ThreadlinePhoenixWeb.WalkthroughEvidenceTest do
  @moduledoc """
  ConnCase automation for maintainer WALKTHROUGH §5 evidence plane exercises.
  """
  use ThreadlinePhoenixWeb.ConnCase, async: false

  import Ecto.Query
  import ThreadlinePhoenixWeb.WalkthroughCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.HelpDesk.{Organization, Ticket}
  alias ThreadlinePhoenix.Repo

  setup do
    seed_demo_fiction!()
    :ok
  end

  describe "§5 evidence plane (WALK-04-01..03)" do
    test "WALK-04-01 retention_run evidence and empty offboarded-co timeline" do
      subject_ref = retention_run_subject_ref()
      run_id = subject_ref["run_id"]

      evidence_conn =
        admin_conn()
        |> get(
          ~p"/audit/evidence?#{%{subject: "retention_run", subject_ref_json: Jason.encode!(subject_ref)}}"
        )

      html = html_response(evidence_conn, 200)
      assert html =~ "retention_run"
      assert html =~ run_id
      assert html =~ "Proven"

      offboarded_timeline_conn =
        build_conn()
        |> login_demo(:support_offboarded)
        |> get(~p"/audit")
        |> follow_audit_redirect()

      timeline_html = html_response(offboarded_timeline_conn, 200)
      refute timeline_html =~ "Forbidden"
      refute timeline_html =~ "View Incident"
    end

    test "WALK-04-02 redaction_policy evidence and #4521 row history shows [REDACTED]" do
      policy_ref = Manifest.evidence_subject_ref(:redaction_policy)

      evidence_conn =
        admin_conn()
        |> get(
          ~p"/audit/evidence?#{%{subject: "redaction_policy", subject_ref_json: Jason.encode!(policy_ref)}}"
        )

      html = html_response(evidence_conn, 200)
      assert html =~ "redaction_policy"
      assert html =~ "walk-demo-redaction-policy"
      assert html =~ "Inferred"

      policy_conn = admin_conn() |> get(~p"/audit/policy/redaction")
      policy_html = html_response(policy_conn, 200)
      assert policy_html =~ "Policy redaction drift"

      {tx_id, reply_pk} = hero_4521_close_reply_ids!()

      history_conn =
        admin_conn()
        |> get(~p"/audit/transactions/#{tx_id}/history/ticket_replies/#{reply_pk}")

      history_html = html_response(history_conn, 200)
      assert history_html =~ "[REDACTED]"
      refute history_html =~ "WALKTHROUGH-INTERNAL-SECRET-4521"
    end

    test "WALK-04-03 trigger coverage dashboard and evidence snapshot" do
      snapshot_ref = Manifest.evidence_subject_ref(:trigger_coverage)

      coverage_conn = admin_conn() |> get(~p"/audit/coverage")
      coverage_html = html_response(coverage_conn, 200)
      refute coverage_html =~ "Coverage view unavailable"
      assert coverage_html =~ "tickets" or coverage_html =~ "ticket_replies"
      assert coverage_html =~ "covered"

      evidence_conn =
        admin_conn()
        |> get(
          ~p"/audit/evidence?#{%{subject: "trigger_coverage", subject_ref_json: Jason.encode!(snapshot_ref)}}"
        )

      evidence_html = html_response(evidence_conn, 200)
      assert evidence_html =~ "trigger_coverage"
      assert evidence_html =~ "walk-demo-trigger-coverage"
    end
  end

  defp hero_4521_close_reply_ids! do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
      acme = Repo.get_by!(Organization, slug: "acme")
      ticket = Repo.get_by!(Ticket, organization_id: acme.id, number: 4521)

      close_tx =
        Repo.one!(
          from(at in AuditTransaction,
            join: ac in assoc(at, :changes),
            where: ac.table_name == "tickets",
            where: ac.op == "update",
            where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(ticket.id)),
            where: fragment("?->>'status' = ?", ac.data_after, "closed"),
            order_by: [desc: at.occurred_at],
            limit: 1
          )
        )

      reply_change =
        Repo.one!(
          from(ac in AuditChange,
            where: ac.transaction_id == ^close_tx.id,
            where: ac.table_name == "ticket_replies",
            where: ac.op == "insert"
          )
        )

      {close_tx.id, reply_change.table_pk["id"]}
    end)
  end
end
