defmodule ThreadlinePhoenix.Workers.PostTouchWorkerTest do
  use ThreadlinePhoenix.DataCase, async: false
  use Oban.Testing, repo: ThreadlinePhoenix.Repo

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias ThreadlinePhoenix.{Post, Repo}
  alias ThreadlinePhoenix.Workers.PostTouchWorker

  test "perform_job captures posts change and audit action with job context" do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(ThreadlinePhoenix.Repo, fn ->
      slug = "job-touch-#{System.unique_integer([:positive])}"

      post =
        %Post{}
        |> Post.changeset(%{title: "before", slug: slug})
        |> Repo.insert!()

      {:ok, ref} = ActorRef.new(:service_account, "threadline-phoenix-example-job")
      actor_ref_map = ActorRef.to_map(ref)

      job =
        build_job(PostTouchWorker, %{
          "actor_ref" => actor_ref_map,
          "correlation_id" => "phase-24-corr",
          "post_id" => post.id,
          "title" => "after"
        })

      assert :ok = perform_job(job)

      assert {_ac, %AuditTransaction{} = at} =
               Repo.one!(
                 from(ac in AuditChange,
                   join: at in assoc(ac, :transaction),
                   where: ac.table_name == "posts",
                   where: ac.op == "update",
                   where: fragment("?->>'slug' = ?", ac.data_after, ^slug),
                   order_by: [desc: ac.captured_at],
                   select: {ac, at}
                 )
               )

      assert %ActorRef{type: :service_account, id: "threadline-phoenix-example-job"} =
               at.actor_ref

      action =
        Repo.one(
          from(a in AuditAction,
            where: a.name == "post_title_refreshed_from_queue",
            where: a.job_id == ^to_string(job.id),
            where: a.correlation_id == "phase-24-corr"
          )
        )

      refute is_nil(action)

      Repo.query!(
        "TRUNCATE TABLE audit_changes, audit_transactions, audit_actions, posts RESTART IDENTITY CASCADE",
        []
      )
    end)
  end
end
