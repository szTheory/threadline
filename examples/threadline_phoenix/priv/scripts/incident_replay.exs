defmodule ThreadlinePhoenix.IncidentReplay do
  @moduledoc false
  
  def run do
    # 1. Guard check
    if System.get_env("THREADLINE_REPLAY_DISPOSABLE_DB") != "1" do
      IO.puts(Enum.join(["Error: THREADLINE_REPLAY_DISPOSABLE_DB=1 is required."], ""))
      System.halt(1)
    end

    config = ThreadlinePhoenix.Repo.config()
    db_name = Keyword.fetch!(config, :database)

    if not String.ends_with?(db_name, "_test") and not String.ends_with?(db_name, "_dev") do
      IO.puts(Enum.join(["Error: Database name must end with _test or _dev. Current DB: ", db_name], ""))
      System.halt(1)
    end

    # 2. Argument Parsing
    {opts, _args, _invalid} = OptionParser.parse(System.argv(), strict: [incident: :string, execute: :boolean])

    incident = Keyword.get(opts, :incident)
    execute? = Keyword.get(opts, :execute, false)

    alias ThreadlinePhoenix.{Repo, Post}

    # Ensure seed data exists
    if Repo.aggregate(Post, :count) == 0 do
      %Post{} |> Post.changeset(%{title: "Synthetic note A", slug: "synthetic-note-a"}) |> Repo.insert!()
      %Post{} |> Post.changeset(%{title: "Synthetic note B", slug: "synthetic-note-b"}) |> Repo.insert!()
    end

    # Helper to run an incident scenario
    run_scenario = fn slug, run_fn ->
      if incident == nil or incident == slug do
        if execute? do
          run_fn.()
        else
          IO.puts(Jason.encode!(%{incident: slug, status: "dry-run"}))
        end
      end
    end

    # 3. Implement 3 scenarios

    run_scenario.("who-changed-this-row", fn ->
      post = Repo.get_by!(Post, slug: "synthetic-note-a")
      
      alias Threadline.Semantics.ActorRef
      
      actor_ref = ActorRef.user("hacker_99")
      json = ActorRef.to_map(actor_ref) |> Jason.encode!()
      
      Repo.transaction(fn ->
        Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
        post
        |> Post.changeset(%{title: "Hacked Title"})
        |> Repo.update!()
      end)
      Threadline.record_action(:hacked_post, repo: Repo, actor: actor_ref, correlation_id: "hacker-123")
      
      timeline = Threadline.Query.timeline(table: "posts", row_pk: to_string(post.id), repo: Repo) |> Repo.preload(:transaction)
      
      change = Enum.find(timeline, &(&1.op == "update" and &1.transaction.actor_ref.id == "hacker_99"))
      
      IO.puts(Jason.encode!(%{
        incident: "who-changed-this-row",
        status: "executed",
        found_actor: change.transaction.actor_ref.id,
        action: change.op
      }))
    end)

    run_scenario.("service-account-actions", fn ->
      alias Threadline.Semantics.ActorRef

      actor_ref = ActorRef.service_account("svc_worker_456")
      json = ActorRef.to_map(actor_ref) |> Jason.encode!()
      
      Repo.transaction(fn ->
        Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
        %Post{}
        |> Post.changeset(%{title: "Worker created note", slug: "worker-note-#{System.unique_integer([:positive])}"})
        |> Repo.insert!()
      end)
      Threadline.record_action(:worker_create, repo: Repo, actor: actor_ref, correlation_id: "worker-req-1")
      
      timeline = Threadline.Query.timeline(actor_ref: actor_ref, repo: Repo)
      
      IO.puts(Jason.encode!(%{
        incident: "service-account-actions",
        status: "executed",
        actor_actions: length(timeline)
      }))
    end)

    run_scenario.("single-transaction", fn ->
      alias Threadline.Semantics.ActorRef

      {:ok, actor_ref} = ActorRef.new(:job, "batch_process")
      json = ActorRef.to_map(actor_ref) |> Jason.encode!()

      Repo.transaction(fn ->
        Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
        Repo.insert!(Post.changeset(%Post{}, %{title: "Batch 1", slug: "batch-1-#{System.unique_integer([:positive])}"}))
        Repo.insert!(Post.changeset(%Post{}, %{title: "Batch 2", slug: "batch-2-#{System.unique_integer([:positive])}"}))
      end)
      Threadline.record_action(:batch_insert, repo: Repo, actor: actor_ref, correlation_id: "batch-req-1")
      
      txs = Repo.all(Threadline.Capture.AuditTransaction)
      if length(txs) > 0 do
        IO.puts(Enum.join(["All audit txs: ", inspect(txs)], ""))
      end
      
      [recent_change | _] = Threadline.Query.timeline(actor_ref: actor_ref, repo: Repo) |> Repo.preload(:transaction)
      tx_id = recent_change.transaction_id
      
      tx_timeline = Threadline.Query.audit_changes_for_transaction(tx_id, repo: Repo)
      
      IO.puts(Jason.encode!(%{
        incident: "single-transaction",
        status: "executed",
        tx_changes: length(tx_timeline)
      }))
    end)
  end
end

ThreadlinePhoenix.IncidentReplay.run()
