# priv/scripts/incident_replay.exs
require Logger

alias ThreadlinePhoenix.Repo
alias ThreadlinePhoenix.Post

defmodule IncidentReplay do
  def run do
    # Ensure the app and its Repo are started
    Application.ensure_all_started(:threadline_phoenix)
    
    if Repo.config()[:pool] == Ecto.Adapters.SQL.Sandbox do
      Ecto.Adapters.SQL.Sandbox.checkout(Repo)
      Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    end

    {opts, _args, _invalid} =
      OptionParser.parse(System.argv(),
        strict: [incident: :string, execute: :boolean]
      )

    incident = Keyword.get(opts, :incident)
    execute? = Keyword.get(opts, :execute, false)

    validate_environment!()

    unless incident do
      IO.puts(format_json(:error, "Missing --incident flag"))
      System.halt(1)
    end

    if not execute? do
      IO.puts(format_json(:info, "Dry run enabled. Pass --execute to perform mutations.", incident: incident))
      System.halt(0)
    end

    case incident do
      "who-changed-row" ->
        scenario_who_changed_row()
      "service-account-today" ->
        scenario_service_account()
      "oban-job-mutation" ->
        scenario_oban_job()
      _ ->
        IO.puts(format_json(:error, "Unknown incident slug: #{incident}"))
        System.halt(1)
    end
  end

  defp validate_environment! do
    if System.get_env("THREADLINE_REPLAY_DISPOSABLE_DB") != "1" do
      IO.puts(format_json(:error, "THREADLINE_REPLAY_DISPOSABLE_DB must be set to 1"))
      System.halt(1)
    end

    db_name = Repo.config()[:database]
    unless String.contains?(db_name, ["test", "disposable", "dev"]) do
      IO.puts(format_json(:error, "Database name must indicate it is disposable (test/dev/disposable). Current: #{db_name}"))
      System.halt(1)
    end
  end

  defp set_context_guc(repo, context_map) do
    # context_map usually should be an ActorRef map. For this script we will use the type "user" or "system"
    # or just encode whatever map was provided. We must shape it like an ActorRef for the database trigger to parse it correctly, e.g. %{"type" => "user", "id" => ...}
    actor_map =
      cond do
        Map.has_key?(context_map, "actor_id") ->
          %{"type" => "user", "id" => context_map["actor_id"]}
        true ->
          %{"type" => "system", "id" => "unknown"}
      end
    
    json = Jason.encode!(actor_map)
    Ecto.Adapters.SQL.query!(repo, "SELECT set_config('threadline.actor_ref', $1::text, false)", [json])
  end

  defp scenario_who_changed_row do
    post = case Repo.all(Post) |> List.first() do
      nil ->
        %Post{}
        |> Ecto.Changeset.change(%{title: "Seed Post", slug: "seed-#{System.unique_integer()}"})
        |> Repo.insert!()
      existing_post -> existing_post
    end

    set_context_guc(Repo, %{"actor_id" => "user-123", "reason" => "scenario_who_changed_row"})
    
    {:ok, updated_post} =
      post
      |> Ecto.Changeset.change(%{title: "Updated Title for Incident"})
      |> Repo.update()
      
    # Read back audit log
    changes = Threadline.Query.history(Post, to_string(updated_post.id), repo: Repo)

    IO.puts(format_json(:success, "Scenario completed", incident: "who-changed-row", changes_count: length(changes)))
  end

  defp scenario_service_account do
    service_account_id = "service-acct-#{System.unique_integer([:positive])}"
    set_context_guc(Repo, %{"actor_id" => service_account_id})
    
    %Post{}
    |> Ecto.Changeset.change(%{title: "Batch Post", slug: "batch-#{System.unique_integer([:positive])}"})
    |> Repo.insert!()
    
    # Count the transactions directly for this disposable replay scenario.
    changes = Ecto.Adapters.SQL.query!(Repo, "SELECT * FROM audit_transactions WHERE actor_ref->>'id' = $1", [service_account_id])
    
    IO.puts(format_json(:success, "Scenario completed", incident: "service-account-today", changes_count: changes.num_rows))
  end

  defp scenario_oban_job do
    job_id = "job-#{System.unique_integer([:positive])}"
    set_context_guc(Repo, %{"oban_job_id" => job_id, "actor_id" => "oban-worker"})
    
    %Post{}
    |> Ecto.Changeset.change(%{title: "Oban Post", slug: "oban-#{System.unique_integer([:positive])}"})
    |> Repo.insert!()
    
    changes = Ecto.Adapters.SQL.query!(Repo, "SELECT * FROM audit_transactions WHERE actor_ref->>'id' = 'oban-worker'")
    
    IO.puts(format_json(:success, "Scenario completed", incident: "oban-job-mutation", changes_count: changes.num_rows))
  end

  defp format_json(status, message, extra \\ []) do
    map = Map.merge(%{status: status, message: message}, Map.new(extra))
    Jason.encode!(map)
  end
end

IncidentReplay.run()
