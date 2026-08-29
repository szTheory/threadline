defmodule Mix.Tasks.Threadline.Evidence.ShowTest do
  use Threadline.DataCase

  import ExUnit.CaptureIO

  alias Threadline.Governance.EvidenceRecord

  setup do
    Repo.delete_all(EvidenceRecord, repo_opts())
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
    |> Repo.insert!(repo_opts())
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

  test "threadline.evidence.show fails fast on unknown flags" do
    assert_raise Mix.Error, ~r/unknown option\(s\): --histroy/, fn ->
      Mix.Tasks.Threadline.Evidence.Show.run(["--histroy"])
    end
  end

  test "threadline.evidence.show requires --subject when --subject-ref-json is present" do
    assert_raise Mix.Error, ~r/--subject-ref-json requires --subject/, fn ->
      Mix.Tasks.Threadline.Evidence.Show.run([
        "--subject-ref-json",
        ~s({"run_id":"ret-run-1"})
      ])
    end
  end

  test "threadline.evidence.show returns successful output for unsupported proof states" do
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

    json_output =
      capture_io(fn ->
        assert :ok =
                 Mix.Tasks.Threadline.Evidence.Show.run([
                   "--subject",
                   "support_scope_posture",
                   "--json"
                 ])
      end)

    human_output =
      capture_io(fn ->
        assert :ok =
                 Mix.Tasks.Threadline.Evidence.Show.run([
                   "--subject",
                   "support_scope_posture"
                 ])
      end)

    document = Jason.decode!(json_output)

    assert document["claim_assessment"]["status"] == "unsupported"
    assert document["claim_assessment"]["reason"] == "host_owned_authorization"
    assert document["records"] != []
    assert human_output =~ "Evidence proof support_scope_posture"
    assert human_output =~ "Claim assessment: unsupported"
  end

  test "threadline.evidence.show docs keep viewer semantics separate from any future gate task" do
    assert {:docs_v1, _, :elixir, _, %{"en" => moduledoc}, _, _} =
             Code.fetch_docs(Mix.Tasks.Threadline.Evidence.Show)

    assert moduledoc =~ "This task is a viewer, not a gate."
    assert moduledoc =~ "future gate task"
  end
end
