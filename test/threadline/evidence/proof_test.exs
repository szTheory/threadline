defmodule Threadline.Evidence.ProofTest do
  use Threadline.DataCase

  alias Threadline.Evidence.Proof
  alias Threadline.Governance.EvidenceRecord

  @repo Threadline.Test.Repo

  setup do
    Repo.delete_all(EvidenceRecord)
    :ok
  end

  defp insert_evidence(attrs) do
    defaults = %{
      subject: "retention_run",
      subject_ref: %{"run_id" => Ecto.UUID.generate()},
      summary_status: "proven",
      recorded_at: ~U[2026-05-26 12:00:00.000000Z],
      provenance: %{"writer" => "threadline", "entrypoint" => "test"},
      detail: %{"deleted_count" => 2},
      schema_version: 1
    }

    %EvidenceRecord{}
    |> EvidenceRecord.changeset(Map.merge(defaults, Map.new(attrs)))
    |> Repo.insert!()
  end

  test "builds wrapped proof json with the stable top-level contract for proven facts" do
    insert_evidence(
      subject: "retention_run",
      subject_ref: %{"run_id" => "ret-run-1"},
      summary_status: "proven"
    )

    assert {:ok, data} =
             Proof.to_json_iodata([], repo: @repo, generated_at: ~U[2026-05-27 00:00:00.000000Z])

    document = Jason.decode!(IO.iodata_to_binary(data))

    assert document["format_version"] == 1
    assert document["generated_at"] == "2026-05-27T00:00:00.000000Z"
    assert document["proof_type"] == "threadline_evidence"
    assert Map.has_key?(document, "subject")
    assert document["mode"] == "latest"
    assert Map.has_key?(document, "filters")
    assert Map.has_key?(document, "summary")
    assert Map.has_key?(document, "claim_assessment")
    assert Map.has_key?(document, "records")
    assert document["claim_assessment"]["status"] == "proven"
    assert document["claim_assessment"]["kind"] == "direct_fact"
  end

  test "default overview covers all six supported subject families" do
    insert_evidence(subject: "redaction_policy", subject_ref: %{"policy" => "default"})
    insert_evidence(subject: "trigger_coverage", subject_ref: %{"table" => "users"})
    insert_evidence(subject: "retention_run", subject_ref: %{"run_id" => "ret-run-1"})
    insert_evidence(subject: "retention_policy", subject_ref: %{"policy" => "default"})
    insert_evidence(subject: "export_delivery", subject_ref: %{"export_id" => "exp-1"})
    insert_evidence(subject: "support_scope_posture", subject_ref: %{"scope" => "support"})

    document = Proof.proof_document([], repo: @repo, generated_at: ~U[2026-05-27 00:00:00.000000Z])

    assert document["subject"] == "overview"

    assert document["records"]
           |> Enum.map(& &1["subject"])
           |> Enum.sort() == [
             "export_delivery",
             "redaction_policy",
             "retention_policy",
             "retention_run",
             "support_scope_posture",
             "trigger_coverage"
           ]
  end

  test "classifies posture subjects as inferred_posture when evidence is a posture snapshot" do
    insert_evidence(
      subject: "support_scope_posture",
      subject_ref: %{"scope" => "support"},
      summary_status: "configured",
      detail: %{
        "support_lane" => "read_only",
        "host_authorization" => "host_owned"
      }
    )

    document =
      Proof.proof_document(
        [subject: "support_scope_posture"],
        repo: @repo,
        generated_at: ~U[2026-05-27 00:00:00.000000Z]
      )

    assert document["claim_assessment"]["status"] == "inferred_posture"
    assert document["claim_assessment"]["kind"] == "posture_snapshot"
  end

  test "keeps explicit unsupported claims as valid proof payloads" do
    insert_evidence(
      subject: "support_scope_posture",
      subject_ref: %{"scope" => "support"},
      summary_status: "unsupported",
      detail: %{
        "claim_assessment" => %{
          "status" => "unsupported",
          "reason" => "host_owned_authorization"
        }
      }
    )

    document =
      Proof.proof_document(
        [subject: "support_scope_posture"],
        repo: @repo,
        generated_at: ~U[2026-05-27 00:00:00.000000Z]
      )

    assert document["claim_assessment"]["status"] == "unsupported"
    assert document["claim_assessment"]["reason"] == "host_owned_authorization"
  end

  test "classifies directly supported negative facts as proven" do
    insert_evidence(
      subject: "trigger_coverage",
      subject_ref: %{"table" => "users"},
      summary_status: "uncovered",
      detail: %{
        "coverage_status" => "uncovered",
        "table" => "users"
      }
    )

    document =
      Proof.proof_document(
        [subject: "trigger_coverage"],
        repo: @repo,
        generated_at: ~U[2026-05-27 00:00:00.000000Z]
      )

    assert document["claim_assessment"]["status"] == "proven"
    assert document["claim_assessment"]["kind"] == "direct_fact"
    assert document["records"] |> hd() |> Map.fetch!("summary_status") == "uncovered"
  end
end
