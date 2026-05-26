defmodule Mix.Tasks.Threadline.Evidence.ShowTest do
  use Threadline.DataCase

  import ExUnit.CaptureIO

  alias Threadline.Governance.EvidenceRecord

  setup do
    Repo.delete_all(EvidenceRecord)
    Mix.Task.reenable("threadline.evidence.show")
    :ok
  end

  defp insert_evidence(attrs) do
    defaults = %{
      subject: "retention_run",
      subject_ref: %{"run_id" => Ecto.UUID.generate()},
      summary_status: "completed",
      recorded_at: ~U[2026-05-26 12:00:00.000000Z],
      provenance: %{"writer" => "threadline", "entrypoint" => "test"},
      detail: %{"deleted_count" => 2},
      schema_version: 1
    }

    %EvidenceRecord{}
    |> EvidenceRecord.changeset(Map.merge(defaults, Map.new(attrs)))
    |> Repo.insert!()
  end

  test "threadline.evidence.show prints overview-first human output by default" do
    insert_evidence(
      subject: "redaction_policy",
      subject_ref: %{"policy" => "default"},
      summary_status: "proven"
    )

    output =
      capture_io(fn ->
        assert :ok = Mix.Tasks.Threadline.Evidence.Show.run([])
      end)

    assert output =~ "Evidence proof overview"
    assert output =~ "redaction_policy"
    assert output =~ "latest"
  end

  test "threadline.evidence.show emits wrapped json with --json" do
    insert_evidence(
      subject: "trigger_coverage",
      subject_ref: %{"schema" => "public", "table" => "users"},
      summary_status: "proven"
    )

    output =
      capture_io(fn ->
        assert :ok = Mix.Tasks.Threadline.Evidence.Show.run(["--json"])
      end)

    document = Jason.decode!(output)

    assert document["format_version"] == 1
    assert document["proof_type"] == "threadline_evidence"
    assert document["mode"] == "latest"
    assert is_list(document["records"])
  end

  test "threadline.evidence.show parses bounded filters for subject history" do
    older = ~U[2026-05-25 12:00:00.000000Z]
    newer = ~U[2026-05-26 12:00:00.000000Z]

    insert_evidence(
      subject_ref: %{"run_id" => "ret-run-1"},
      recorded_at: older,
      summary_status: "proven"
    )

    insert_evidence(
      subject_ref: %{"run_id" => "ret-run-1"},
      recorded_at: newer,
      summary_status: "proven"
    )

    output =
      capture_io(fn ->
        assert :ok =
                 Mix.Tasks.Threadline.Evidence.Show.run([
                   "--subject",
                   "retention_run",
                   "--subject-ref-json",
                   ~s({"run_id":"ret-run-1"}),
                   "--history",
                   "--from",
                   "2026-05-25T00:00:00Z",
                   "--to",
                   "2026-05-26T23:59:59Z",
                   "--limit",
                   "1",
                   "--json"
                 ])
      end)

    document = Jason.decode!(output)

    assert document["subject"] == "retention_run"
    assert document["mode"] == "history"
    assert document["filters"]["limit"] == 1
    assert length(document["records"]) == 1
  end

  test "threadline.evidence.show returns successful output for unsupported proof states" do
    insert_evidence(
      subject: "support_scope_posture",
      subject_ref: %{"scope" => "support"},
      summary_status: "unsupported",
      detail: %{"reason" => "host authorization remains host-owned"}
    )

    output =
      capture_io(fn ->
        assert :ok =
                 Mix.Tasks.Threadline.Evidence.Show.run([
                   "--subject",
                   "support_scope_posture",
                   "--json"
                 ])
      end)

    document = Jason.decode!(output)

    assert document["claim_assessment"]["status"] == "unsupported"
    assert document["records"] != []
  end
end
