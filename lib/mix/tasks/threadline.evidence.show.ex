defmodule Mix.Tasks.Threadline.Evidence.Show do
  @shortdoc "Show Threadline evidence proof output for overview, latest, or history"

  @moduledoc """
  Shows Threadline-owned evidence proof output through one canonical viewer task.

  This task is a viewer, not a gate. Successful proof reads always exit `0`,
  including outputs that classify claims as unsupported.

  ## Usage

      mix threadline.evidence.show
      mix threadline.evidence.show --json
      mix threadline.evidence.show --subject retention_run --history
      mix threadline.evidence.show --subject retention_run --subject-ref-json '{"run_id":"ret-run-1"}'

  ## Flags

    * `--json`
    * `--subject`
    * `--subject-ref-json`
    * `--latest`
    * `--history`
    * `--from`
    * `--to`
    * `--limit`
  """

  use Mix.Task

  alias Threadline.Evidence
  alias Threadline.Evidence.Subject

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [
          json: :boolean,
          subject: :string,
          subject_ref_json: :string,
          latest: :boolean,
          history: :boolean,
          from: :string,
          to: :string,
          limit: :integer
        ]
      )

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    document = proof_document(opts, repo)

    if Keyword.get(opts, :json, false) do
      render_json(document)
    else
      render_human(document)
    end

    :ok
  end

  defp proof_document(opts, repo) do
    subject = parse_subject(opts)
    subject_ref = parse_subject_ref(opts)
    mode = parse_mode(opts)
    filters = parse_filters(opts)
    records = fetch_records(subject, subject_ref, mode, filters, repo)

    %{
      "format_version" => 1,
      "generated_at" => iso8601(DateTime.utc_now(:microsecond)),
      "proof_type" => "threadline_evidence",
      "subject" => subject,
      "mode" => Atom.to_string(mode),
      "filters" => json_filters(subject_ref, filters),
      "summary" => %{
        "record_count" => length(records),
        "subject_count" => records |> Enum.map(& &1.subject) |> Enum.uniq() |> length()
      },
      "claim_assessment" => claim_assessment(records),
      "records" => Enum.map(records, &record_to_map/1)
    }
  end

  defp parse_subject(opts) do
    case Keyword.get(opts, :subject) do
      nil -> nil
      subject -> validate_subject!(subject)
    end
  end

  defp parse_subject_ref(opts) do
    case Keyword.get(opts, :subject_ref_json) do
      nil ->
        nil

      payload ->
        case Jason.decode(payload) do
          {:ok, value} when is_map(value) -> value
          {:ok, other} -> Mix.raise("threadline.evidence.show: --subject-ref-json must decode to a JSON object, got: #{inspect(other)}")
          {:error, error} -> Mix.raise("threadline.evidence.show: invalid JSON for --subject-ref-json: #{Exception.message(error)}")
        end
    end
  end

  defp parse_mode(opts) do
    latest? = Keyword.get(opts, :latest, false)
    history? = Keyword.get(opts, :history, false)

    cond do
      latest? and history? ->
        Mix.raise("threadline.evidence.show: choose at most one of --latest or --history")

      history? ->
        :history

      true ->
        :latest
    end
  end

  defp parse_filters(opts) do
    []
    |> maybe_put_datetime(:from, Keyword.get(opts, :from))
    |> maybe_put_datetime(:to, Keyword.get(opts, :to))
    |> maybe_put_limit(Keyword.get(opts, :limit))
  end

  defp maybe_put_datetime(filters, _key, nil), do: filters

  defp maybe_put_datetime(filters, key, value) do
    Keyword.put(filters, key, parse_datetime!(key, value))
  end

  defp maybe_put_limit(filters, nil), do: filters
  defp maybe_put_limit(filters, limit), do: Keyword.put(filters, :limit, limit)

  defp fetch_records(nil, nil, :latest, filters, repo) do
    Subject.supported_subjects()
    |> Enum.flat_map(fn subject ->
      Evidence.list_latest_subject_refs(subject, filters, repo: repo)
    end)
    |> Enum.sort_by(
      fn record -> {DateTime.to_unix(record.recorded_at, :microsecond), record.id} end,
      :desc
    )
  end

  defp fetch_records(subject, nil, :latest, filters, repo) do
    Evidence.list_latest_subject_refs(subject, filters, repo: repo)
  end

  defp fetch_records(subject, subject_ref, :latest, _filters, repo) do
    case Evidence.get_latest_subject_ref(subject, subject_ref, repo: repo) do
      nil -> []
      record -> [record]
    end
  end

  defp fetch_records(subject, subject_ref, :history, filters, repo) when not is_nil(subject_ref) do
    Evidence.list_subject_ref_history(subject, subject_ref, filters, repo: repo)
  end

  defp fetch_records(subject, _subject_ref, :history, filters, repo) when not is_nil(subject) do
    Evidence.list_history(Keyword.put(filters, :subject, subject), repo: repo)
  end

  defp fetch_records(nil, _subject_ref, :history, filters, repo) do
    Evidence.list_history(filters, repo: repo)
  end

  defp claim_assessment([]) do
    %{
      "status" => "unsupported",
      "reason" => "no_records"
    }
  end

  defp claim_assessment(records) do
    statuses =
      records
      |> Enum.map(& &1.summary_status)
      |> Enum.uniq()

    status =
      cond do
        "unsupported" in statuses -> "unsupported"
        "inferred_posture" in statuses -> "inferred_posture"
        true -> "proven"
      end

    %{
      "status" => status,
      "record_statuses" => statuses
    }
  end

  defp record_to_map(record) do
    %{
      "id" => record.id,
      "subject" => record.subject,
      "subject_ref" => record.subject_ref,
      "summary_status" => record.summary_status,
      "recorded_at" => iso8601(record.recorded_at),
      "actor_ref" => actor_ref_to_map(record.actor_ref),
      "provenance" => record.provenance,
      "detail" => record.detail,
      "schema_version" => record.schema_version,
      "inserted_at" => iso8601(record.inserted_at)
    }
  end

  defp actor_ref_to_map(nil), do: nil
  defp actor_ref_to_map(actor_ref), do: Threadline.Semantics.ActorRef.to_map(actor_ref)

  defp json_filters(subject_ref, filters) do
    filters
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), filter_value(value)} end)
    |> maybe_put_subject_ref(subject_ref)
  end

  defp maybe_put_subject_ref(filters, nil), do: filters
  defp maybe_put_subject_ref(filters, subject_ref), do: Map.put(filters, "subject_ref", subject_ref)

  defp filter_value(%DateTime{} = value), do: iso8601(value)
  defp filter_value(value), do: value

  defp render_json(document) do
    IO.puts(Jason.encode!(document))
  end

  defp render_human(document) do
    Mix.shell().info("Evidence proof overview")
    Mix.shell().info("Mode: #{document["mode"]}")
    Mix.shell().info("Claim assessment: #{document["claim_assessment"]["status"]}")
    Mix.shell().info("Records: #{document["summary"]["record_count"]}")

    Enum.each(document["records"], fn record ->
      Mix.shell().info(
        "* #{record["subject"]} #{inspect(record["subject_ref"])} #{record["summary_status"]} #{record["recorded_at"]}"
      )
    end)
  end

  defp parse_datetime!(flag, value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :microsecond)
      {:error, _reason} -> Mix.raise("threadline.evidence.show: invalid ISO-8601 for --#{flag}: #{inspect(value)}")
    end
  end

  defp validate_subject!(subject) do
    case Subject.validate(subject) do
      :ok -> subject
      {:error, {:unsupported_subject, value}} -> Mix.raise("threadline.evidence.show: unsupported subject #{inspect(value)}")
    end
  end

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)

  defp resolve_repo! do
    case Application.get_env(:threadline, :ecto_repos, []) do
      [] ->
        Mix.raise(
          "Threadline: set :ecto_repos in config — no Ecto repository is configured to run threadline.evidence.show."
        )

      [repo | _] ->
        repo
    end
  end

  defp ensure_repo_started!(repo) do
    case repo.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      {:error, reason} -> Mix.raise("Could not start #{inspect(repo)}: #{inspect(reason)}")
    end
  end
end
