defmodule Threadline.EvidenceTest do
  use Threadline.DataCase

  alias Threadline.Evidence
  alias Threadline.Governance.EvidenceRecord
  alias Threadline.Semantics.ActorRef

  @repo Threadline.Test.Repo

  setup do
    # `function_exported?/3` returns false for a not-yet-loaded module, so the
    # record_* export assertions below were seed-order flaky. Force the load.
    Code.ensure_loaded!(Evidence)
    Repo.delete_all(EvidenceRecord, repo_opts())
    :ok
  end

  defp actor!(type, id) do
    {:ok, actor_ref} = ActorRef.new(type, id)
    actor_ref
  end

  defp insert_evidence(attrs) do
    defaults = %{
      subject: "retention_run",
      subject_ref: %{"run_id" => Ecto.UUID.generate()},
      summary_status: "completed",
      recorded_at: DateTime.utc_now(:microsecond),
      provenance: %{"writer" => "threadline", "entrypoint" => "test"},
      detail: %{"deleted_count" => 2},
      schema_version: 1
    }

    %EvidenceRecord{}
    |> EvidenceRecord.changeset(Map.merge(defaults, Map.new(attrs)))
    |> Repo.insert!(repo_opts())
  end

  describe "record_* helpers" do
    test "exposes the supported write helper family without a broad generic writer" do
      assert function_exported?(Evidence, :record_redaction_policy, 3)
      assert function_exported?(Evidence, :record_trigger_coverage, 3)
      assert function_exported?(Evidence, :record_retention_run, 3)
      assert function_exported?(Evidence, :record_retention_policy, 3)
      assert function_exported?(Evidence, :record_export_delivery, 3)
      assert function_exported?(Evidence, :record_support_scope_posture, 3)

      refute function_exported?(Evidence, :record_evidence, 3)
      refute function_exported?(Evidence, :record_subject, 4)
    end

    test "requires explicit repo handling at the public boundary" do
      assert {:error, :missing_repo} =
               Evidence.record_retention_run(
                 %{run_id: "ret-run-1"},
                 %{summary_status: "completed", detail: %{"deleted_count" => 2}}
               )
    end

    test "persists normalized defaults and stable provenance" do
      actor_ref = actor!(:system, "threadline")

      assert {:ok, record} =
               Evidence.record_retention_run(
                 %{run_id: "ret-run-1", scope: %{table: :users}},
                 %{
                   actor_ref: actor_ref,
                   summary_status: "completed",
                   detail: %{deleted_count: 2}
                 },
                 repo: @repo
               )

      assert record.subject == "retention_run"
      assert record.subject_ref == %{"run_id" => "ret-run-1", "scope" => %{"table" => "users"}}
      assert record.summary_status == "completed"
      assert record.detail == %{"deleted_count" => 2}
      assert record.actor_ref == actor_ref
      assert %DateTime{} = record.recorded_at
      assert record.schema_version == 1

      assert record.provenance == %{
               "entrypoint" => "record_retention_run",
               "writer" => "threadline"
             }
    end

    test "rejects missing semantic fields even when defaults are available" do
      assert {:error, changeset} =
               Evidence.record_retention_run(%{run_id: "ret-run-2"}, %{detail: %{}}, repo: @repo)

      assert {"can't be blank", _opts} = changeset.errors[:summary_status]

      assert {:error, changeset} =
               Evidence.record_retention_run(
                 %{run_id: "ret-run-2"},
                 %{summary_status: "completed"},
                 repo: @repo
               )

      assert {"can't be blank", _opts} = changeset.errors[:detail]
    end
  end

  describe "history and latest helpers" do
    test "lists append-only history with explicit filters and stable list shapes" do
      older = DateTime.add(DateTime.utc_now(:microsecond), -60, :second)
      newer = DateTime.add(older, 30, :second)

      first =
        insert_evidence(
          subject_ref: %{"run_id" => "ret-run-1"},
          recorded_at: older,
          detail: %{"deleted_count" => 1}
        )

      second =
        insert_evidence(
          subject_ref: %{"run_id" => "ret-run-1"},
          recorded_at: newer,
          detail: %{"deleted_count" => 2}
        )

      _other = insert_evidence(subject: "retention_policy", subject_ref: %{"policy" => "default"})

      first_id = first.id
      second_id = second.id

      assert [%EvidenceRecord{id: ^second_id}, %EvidenceRecord{id: ^first_id}] =
               Evidence.list_history(subject: :retention_run, repo: @repo)

      assert [%EvidenceRecord{id: ^second_id}, %EvidenceRecord{id: ^first_id}] =
               Evidence.list_subject_ref_history(
                 "retention_run",
                 %{run_id: "ret-run-1"},
                 repo: @repo
               )

      assert [] =
               Evidence.list_subject_ref_history(
                 "retention_run",
                 %{run_id: "missing"},
                 repo: @repo
               )
    end

    test "rejects unknown history filter keys loudly" do
      assert_raise ArgumentError, ~r/unknown evidence history filter key :nope/, fn ->
        Evidence.list_history(repo: @repo, nope: true)
      end
    end

    test "returns explicit latest projections without hiding older history" do
      earliest = DateTime.add(DateTime.utc_now(:microsecond), -120, :second)
      middle = DateTime.add(earliest, 30, :second)
      latest = DateTime.add(middle, 30, :second)

      older =
        insert_evidence(
          subject_ref: %{"run_id" => "ret-run-1"},
          recorded_at: middle,
          detail: %{"deleted_count" => 1}
        )

      newest =
        insert_evidence(
          subject_ref: %{"run_id" => "ret-run-1"},
          recorded_at: latest,
          detail: %{"deleted_count" => 3}
        )

      second_ref =
        insert_evidence(
          subject_ref: %{"run_id" => "ret-run-2"},
          recorded_at: earliest,
          detail: %{"deleted_count" => 5}
        )

      newest_id = newest.id
      older_id = older.id
      second_ref_id = second_ref.id

      assert [%EvidenceRecord{} = first_latest, %EvidenceRecord{} = second_latest] =
               Evidence.list_latest_subject_refs("retention_run", repo: @repo)

      assert Enum.map([first_latest, second_latest], & &1.id) == [newest_id, second_ref_id]

      assert %EvidenceRecord{id: ^newest_id} =
               Evidence.get_latest_subject_ref("retention_run", %{run_id: "ret-run-1"},
                 repo: @repo
               )

      assert nil ==
               Evidence.get_latest_subject_ref("retention_run", %{run_id: "missing"}, repo: @repo)

      assert [%EvidenceRecord{id: ^newest_id}, %EvidenceRecord{id: ^older_id}] =
               Evidence.list_subject_ref_history(
                 "retention_run",
                 %{run_id: "ret-run-1"},
                 repo: @repo
               )
    end

    test "returns overview latest rows across all six supported subject families" do
      insert_evidence(subject: "redaction_policy", subject_ref: %{"policy" => "default"})
      insert_evidence(subject: "trigger_coverage", subject_ref: %{"table" => "users"})
      insert_evidence(subject: "retention_run", subject_ref: %{"run_id" => "ret-run-1"})
      insert_evidence(subject: "retention_policy", subject_ref: %{"policy" => "default"})
      insert_evidence(subject: "export_delivery", subject_ref: %{"export_id" => "exp-1"})
      insert_evidence(subject: "support_scope_posture", subject_ref: %{"scope" => "support"})

      assert overview = Evidence.list_overview([], repo: @repo)

      assert overview
             |> Enum.map(& &1.subject)
             |> Enum.sort() == [
               "export_delivery",
               "redaction_policy",
               "retention_policy",
               "retention_run",
               "support_scope_posture",
               "trigger_coverage"
             ]
    end

    test "applies overview limit across the combined subject inventory" do
      now = ~U[2026-05-26 12:00:00.000000Z]

      insert_evidence(
        subject: "retention_run",
        subject_ref: %{"run_id" => "ret-run-1"},
        recorded_at: DateTime.add(now, -10, :second)
      )

      newest =
        insert_evidence(
          subject: "export_delivery",
          subject_ref: %{"export_id" => "exp-1"},
          recorded_at: now
        )

      insert_evidence(
        subject: "support_scope_posture",
        subject_ref: %{"scope" => "support"},
        recorded_at: DateTime.add(now, -5, :second)
      )

      assert [%EvidenceRecord{id: id, subject: "export_delivery"}] =
               Evidence.list_overview([limit: 1], repo: @repo)

      assert id == newest.id
    end
  end
end
