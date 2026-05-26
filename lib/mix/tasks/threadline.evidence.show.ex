defmodule Mix.Tasks.Threadline.Evidence.Show do
  @shortdoc "Show Threadline evidence proof output for overview, latest, or history"

  @moduledoc """
  Shows Threadline-owned evidence proof output through one canonical viewer task.

  This task is a viewer, not a gate. Successful proof reads always exit `0`,
  including outputs that classify claims as unsupported. If you need a failing
  policy check later, that belongs in a future gate task such as
  `mix threadline.evidence.verify`, not in this viewer.

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

  alias Threadline.Evidence.Proof
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
      Proof.render_json(document)
    else
      Proof.render_human(document)
    end

    :ok
  end

  defp proof_document(opts, repo) do
    [
      subject: parse_subject(opts),
      subject_ref: parse_subject_ref(opts),
      mode: parse_mode(opts)
    ] ++ parse_filters(opts)
    |> Proof.proof_document(repo: repo)
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
