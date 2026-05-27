defmodule ThreadlinePhoenix.Demo.Seed.RetentionTail do
  @moduledoc false

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Evidence
  alias Threadline.Health
  alias Threadline.Retention
  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.Repo

  @org_y_backdate_days 90

  @doc false
  @spec run(map()) :: map()
  def run(ctx) do
    org_y_id = Manifest.org_id(:offboarded_co)
    backdate_org_y_audit!(org_y_id)
    enable_retention!()

    purge_result =
      case Retention.purge(repo: Repo) do
        {:error, :disabled} ->
          raise "demo retention purge requires :threadline retention enabled"

        result when is_map(result) ->
          result
      end

    record_evidence!(org_y_id, purge_result)
    assert_org_y_audit_empty!(org_y_id)

    ctx
  end

  @doc false
  @spec org_y_audit_change_count(binary()) :: non_neg_integer()
  def org_y_audit_change_count(org_id) when is_binary(org_id) do
    Repo.aggregate(org_y_audit_changes_query(org_id), :count)
  end

  defp backdate_org_y_audit!(org_id) do
    backdated_at = DateTime.add(Manifest.epoch(), -@org_y_backdate_days, :day)

    Repo.query!(
      """
      UPDATE audit_transactions at
      SET occurred_at = $1
      WHERE at.meta->>'organization_id' = $2
      """,
      [backdated_at, org_id]
    )

    Repo.query!(
      """
      UPDATE audit_changes ac
      SET captured_at = $1
      FROM audit_transactions at
      WHERE ac.transaction_id = at.id
        AND at.meta->>'organization_id' = $2
      """,
      [backdated_at, org_id]
    )
  end

  defp enable_retention! do
    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 30,
      delete_empty_transactions: true
    )
  end

  defp record_evidence!(org_y_id, %{deleted_changes: deleted_changes} = purge_result) do
    run_id = Manifest.evidence_run_id(:offboarded_retention)

    retention_run_ref = %{
      "run_id" => run_id,
      "org_slug" => Manifest.org_slug(:offboarded_co),
      "organization_id" => org_y_id
    }

    {:ok, _} =
      Evidence.record_retention_run(
        retention_run_ref,
        %{
          summary_status: "completed",
          detail: %{
            "deleted_changes" => deleted_changes,
            "deleted_transactions" => purge_result.deleted_transactions,
            "narrative" => "org Y offboard"
          }
        },
        repo: Repo
      )

    {:ok, _} =
      Evidence.record_retention_policy(
        Manifest.evidence_subject_ref(:retention_policy),
        %{
          summary_status: "active",
          detail: %{
            "enabled" => true,
            "keep_days" => 30,
            "scope" => "global_age"
          }
        },
        repo: Repo
      )

    coverage = Health.trigger_coverage(repo: Repo)

    {:ok, _} =
      Evidence.record_trigger_coverage(
        Manifest.evidence_subject_ref(:trigger_coverage),
        %{
          summary_status: "snapshot",
          detail: trigger_coverage_detail(coverage)
        },
        repo: Repo
      )

    :ok
  end

  defp trigger_coverage_detail(coverage) when is_list(coverage) do
    covered = Enum.count(coverage, &match?({:covered, _}, &1))
    uncovered = Enum.count(coverage, &match?({:uncovered, _}, &1))
    expected = Enum.count(coverage, &match?({:expected_uncovered, _}, &1))

    %{
      "covered_count" => covered,
      "uncovered_count" => uncovered,
      "expected_uncovered_count" => expected
    }
  end

  defp assert_org_y_audit_empty!(org_id) do
    count = org_y_audit_change_count(org_id)

    if count != 0 do
      raise "expected org Y audit footprint to be purged, found #{count} audit_changes"
    end
  end

  defp org_y_audit_changes_query(org_id) do
    from(ac in AuditChange,
      join: at in AuditTransaction,
      on: ac.transaction_id == at.id,
      where: fragment("?->>'organization_id' = ?", at.meta, ^org_id)
    )
  end
end
