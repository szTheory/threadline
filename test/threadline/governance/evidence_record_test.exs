defmodule Threadline.Governance.EvidenceRecordTest do
  use Threadline.DataCase

  alias Threadline.Governance.EvidenceRecord
  alias Threadline.Semantics.ActorRef

  setup do
    Repo.delete_all(EvidenceRecord)
    :ok
  end

  test "changeset accepts a valid Threadline-owned evidence payload" do
    {:ok, actor_ref} = ActorRef.new(:system, "threadline")

    changeset =
      EvidenceRecord.changeset(%EvidenceRecord{}, %{
        subject: "retention_run",
        subject_ref: %{"run_id" => Ecto.UUID.generate()},
        summary_status: "completed",
        recorded_at: DateTime.utc_now(:microsecond),
        actor_ref: actor_ref,
        provenance: %{"source" => "retention.purge"},
        detail: %{"deleted_count" => 2},
        schema_version: 1
      })

    assert changeset.valid?
  end

  test "changeset rejects missing required fields" do
    changeset = EvidenceRecord.changeset(%EvidenceRecord{}, %{})

    refute changeset.valid?

    Enum.each(
      [
        :subject,
        :subject_ref,
        :summary_status,
        :recorded_at,
        :provenance,
        :detail,
        :schema_version
      ],
      fn field ->
        assert {"can't be blank", _opts} = changeset.errors[field]
      end
    )
  end

  test "two inserts for the same logical subject are accepted" do
    shared_subject_ref = %{"policy" => "default-redaction"}
    now = DateTime.utc_now(:microsecond)

    for summary_status <- ["baseline", "rechecked"] do
      %EvidenceRecord{}
      |> EvidenceRecord.changeset(%{
        subject: "redaction_policy",
        subject_ref: shared_subject_ref,
        summary_status: summary_status,
        recorded_at: now,
        provenance: %{"phase" => 95},
        detail: %{"status" => summary_status},
        schema_version: 1
      })
      |> Repo.insert!()
    end

    assert Repo.aggregate(EvidenceRecord, :count) == 2
  end
end
