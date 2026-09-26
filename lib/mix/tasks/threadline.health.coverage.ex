defmodule Mix.Tasks.Threadline.Health.Coverage do
  @shortdoc "Show trigger coverage for audited tables"

  @moduledoc """
  Shows trigger coverage as reported by `Threadline.Health.trigger_coverage/1`,
  with a three-section table (default) or JSON output (`--json`).

  Unlike `mix threadline.verify_coverage`, this task is a viewer — it ALWAYS
  exits 0, even when uncovered tables exist. Use `mix threadline.verify_coverage`
  for the positive-list CI gate.

  ## Usage

      mix threadline.health.coverage
      mix threadline.health.coverage --json
      mix threadline.health.coverage --schema=NAME

  Default output: a three-section TABLE / STATUS / SOURCE table followed by
  a `Coverage: N covered, M uncovered, K expected uncovered` summary line.

  `--json` emits a JSON object with keys `covered`, `expected_uncovered`,
  `findings`, `schema`, `uncovered`. The `expected_uncovered` value is a list of
  `{"table": ..., "source": "baseline" | "config"}` objects so adopters can
  filter via `jq '.expected_uncovered[] | select(.source == "config")'`.
  `findings` is a list of `Threadline.Health.trigger_findings/1` results, each
  with keys `code`, `severity`, `schema`, `table`, `message`, `details`
  (`code` and `severity` as strings). This key is additive: every other key
  keeps its existing shape.

  Default output also gains a `FINDINGS` section after the existing table,
  with columns `SEVERITY`, `CODE`, `TABLE`, `MESSAGE`. This task always exits
  0 regardless of what findings are present — it is a viewer, not a gate.

  A malformed `config :threadline, :trigger_capture` stops the task with
  `Mix.raise/1` before any findings are checked.

  `--schema=NAME` validates NAME at the edge (regex + `pg_namespace` lookup)
  and raises with `Mix.raise/1` on bad input. NAME must match
  `~r/\\A[a-z_][a-z0-9_]{0,62}\\z/` (PostgreSQL identifier, conservative subset)
  AND exist in `pg_namespace`. Default `"public"`.
  """

  use Mix.Task

  alias Threadline.Capture.TriggerCaptureConfig
  alias Threadline.Health.CoverageSchemas

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [json: :boolean, schema: :string])
    json? = Keyword.get(opts, :json, false)
    schema = Keyword.get(opts, :schema, "public")

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    validate_schema!(repo, schema)
    _ = load_capture_config!()

    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
    findings = Threadline.Health.trigger_findings(repo: repo, schema: schema)

    if json? do
      render_json(schema, coverage, findings)
    else
      render_table(schema, coverage, findings)
    end

    # Viewer semantics: report findings and return :ok. Use
    # mix threadline.verify_coverage when CI must fail on uncovered tables.
    :ok
  end

  # A malformed :trigger_capture config makes TriggerCaptureConfig.load/0
  # raise ArgumentError; surfaced here the same way mix threadline.gen.triggers
  # surfaces it, so this task stops with a readable Mix error instead of a
  # stack trace or a finding.
  defp load_capture_config! do
    TriggerCaptureConfig.load()
  rescue
    e in ArgumentError ->
      Mix.raise("config :threadline, :trigger_capture " <> Exception.message(e))
  end

  defp resolve_repo! do
    case Application.get_env(:threadline, :ecto_repos, []) do
      [] ->
        Mix.raise(
          "Threadline: set :ecto_repos in config — no Ecto repository is configured to run threadline.health.coverage."
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

  defp validate_schema!(repo, schema) do
    case CoverageSchemas.validate(repo, schema) do
      {:ok, _schema} ->
        :ok

      {:error, _message} ->
        if schema =~ ~r/\A[a-z_][a-z0-9_]{0,62}\z/ do
          Mix.raise("threadline.health.coverage: schema #{inspect(schema)} not found.")
        else
          Mix.raise(
            "threadline.health.coverage: schema #{inspect(schema)} is not a valid PostgreSQL identifier. " <>
              "Expected lowercase letters, digits, and underscores starting with a letter or underscore (max 63 chars)."
          )
        end
    end
  end

  defp render_table(_schema, coverage, findings) do
    rows = Enum.map(coverage, &row_for/1)
    rows = Enum.sort_by(rows, fn {table, _status, _source} -> table end)

    # Column widths: TABLE 24 chars min, STATUS 12 chars, SOURCE remainder.
    table_w = max(24, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 5 end))
    status_w = 12

    header =
      String.pad_trailing("TABLE", table_w) <>
        "  " <> String.pad_trailing("STATUS", status_w) <> "  SOURCE"

    rule = String.duplicate("-", String.length(header))

    Mix.shell().info(header)
    Mix.shell().info(rule)

    for {table, status, source} <- rows do
      Mix.shell().info(
        String.pad_trailing(table, table_w) <>
          "  " <> String.pad_trailing(status, status_w) <> "  " <> source
      )
    end

    Mix.shell().info("")
    Mix.shell().info(summary_line(coverage))

    Mix.shell().info("")
    Mix.shell().info("FINDINGS")

    if findings == [] do
      Mix.shell().info("none")
    else
      print_finding_rows(findings)
    end
  end

  defp print_finding_rows(findings) do
    rows =
      Enum.map(findings, fn f ->
        {String.upcase(Atom.to_string(f.severity)), Atom.to_string(f.code),
         "#{f.schema}.#{f.table}", f.message}
      end)

    severity_w = max(8, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 8 end))
    code_w = max(4, rows |> Enum.map(&byte_size(elem(&1, 1))) |> Enum.max(fn -> 4 end))
    table_w = max(5, rows |> Enum.map(&byte_size(elem(&1, 2))) |> Enum.max(fn -> 5 end))

    header =
      String.pad_trailing("SEVERITY", severity_w) <>
        "  " <>
        String.pad_trailing("CODE", code_w) <>
        "  " <> String.pad_trailing("TABLE", table_w) <> "  MESSAGE"

    rule = String.duplicate("-", String.length(header))

    Mix.shell().info(header)
    Mix.shell().info(rule)

    for {severity, code, table, message} <- rows do
      Mix.shell().info(
        String.pad_trailing(severity, severity_w) <>
          "  " <>
          String.pad_trailing(code, code_w) <>
          "  " <> String.pad_trailing(table, table_w) <> "  " <> message
      )
    end
  end

  defp render_json(schema, coverage, findings) do
    covered = for {:covered, t} <- coverage, do: t
    uncovered = for {:uncovered, t} <- coverage, do: t

    expected_uncovered =
      for {:expected_uncovered, t} <- coverage do
        %{"table" => t, "source" => source_for(t)}
      end

    payload = %{
      "schema" => schema,
      "covered" => Enum.sort(covered),
      "uncovered" => Enum.sort(uncovered),
      "expected_uncovered" => Enum.sort_by(expected_uncovered, & &1["table"]),
      "findings" => Enum.map(findings, &finding_json/1)
    }

    IO.puts(Jason.encode!(payload))
  end

  defp finding_json(f) do
    %{
      "code" => Atom.to_string(f.code),
      "severity" => Atom.to_string(f.severity),
      "schema" => f.schema,
      "table" => f.table,
      "message" => f.message,
      "details" => f.details
    }
  end

  defp row_for({:covered, table}), do: {table, "covered", ""}
  defp row_for({:uncovered, table}), do: {table, "uncovered", ""}
  defp row_for({:expected_uncovered, table}), do: {table, "expected", source_for(table)}

  @baseline ~w(schema_migrations)

  defp source_for(table) do
    if table in @baseline, do: "baseline", else: "config"
  end

  defp summary_line(coverage) do
    covered = Enum.count(coverage, &match?({:covered, _}, &1))
    uncovered = Enum.count(coverage, &match?({:uncovered, _}, &1))
    expected = Enum.count(coverage, &match?({:expected_uncovered, _}, &1))
    "Coverage: #{covered} covered, #{uncovered} uncovered, #{expected} expected uncovered"
  end
end
