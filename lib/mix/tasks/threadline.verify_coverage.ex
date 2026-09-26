defmodule Mix.Tasks.Threadline.VerifyCoverage do
  @shortdoc "Checks configured audited tables have Threadline capture triggers (uses Health.trigger_coverage/1)"

  @moduledoc """
  Verifies that tables listed in application config have Threadline audit
  triggers installed, using the same catalog queries as `Threadline.Health.trigger_coverage/1`.

  ## Configuration

  Hosts must set a non-empty list of public table names (strings only):

      config :threadline, :verify_coverage,
        expected_tables: ["users", "posts"]

  ## Usage

      mix threadline.verify_coverage
      mix threadline.verify_coverage --schema=NAME

  Prints a `TABLE` / `STATUS` report to stdout, then a line containing `summary:`
  with counts. Exits with status **1** if any expected table is missing or
  uncovered, or if `Threadline.Health.trigger_findings/1` reports an `:error`
  finding for an expected table; exits **0** when all expected tables are
  covered and no expected table has an error finding.

  Table names in output are public-schema metadata only (same scope as `Health`).

  ## Findings gate

  After the coverage report, this task also checks
  `Threadline.Health.trigger_findings/1` and prints a `FINDINGS` section:

  - An `:error` finding for a table in `:expected_tables` fails the task
    (`exit({:shutdown, 1})`), the same as a missing or uncovered table.
  - An `:error` finding for a table **not** in `:expected_tables` is printed
    under a heading marking it as not gated, and never fails the
    task, so the positive-list contract stays intact.
  - `:warning` findings are always printed and never fail the task.

  A malformed `config :threadline, :trigger_capture` stops the task with
  `Mix.raise/1` before any findings are checked.

  ## Schema scope

  By default, this task verifies the `"public"` schema. Pass `--schema=NAME`
  to verify a non-`public` schema (e.g. `mix threadline.verify_coverage --schema=tenant_42`).
  NAME is validated at the edge (regex + `pg_namespace` lookup); invalid input
  exits 1 via `Mix.raise/1`.
  """

  use Mix.Task

  alias Threadline.Capture.TriggerCaptureConfig
  alias Threadline.Health.CoverageSchemas
  alias Threadline.Verify.CoveragePolicy

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [schema: :string])
    schema = Keyword.get(opts, :schema, "public")

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)
    validate_schema!(repo, schema)
    expected = resolve_expected_tables!()
    _ = load_capture_config!()

    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
    violations = CoveragePolicy.violations(coverage, expected)
    counts = CoveragePolicy.summary_counts(coverage, expected)

    findings = Threadline.Health.trigger_findings(repo: repo, schema: schema)
    partition = CoveragePolicy.partition_findings(findings, expected)

    print_report(expected, coverage, counts)
    print_findings(partition)

    if violations != [] or partition.gated != [] do
      exit({:shutdown, 1})
    end
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
          "Threadline: set :ecto_repos in config — no Ecto repository is configured to run verify_coverage."
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
          Mix.raise("threadline.verify_coverage: schema #{inspect(schema)} not found.")
        else
          Mix.raise(
            "threadline.verify_coverage: schema #{inspect(schema)} is not a valid PostgreSQL identifier. " <>
              "Expected lowercase letters, digits, and underscores starting with a letter or underscore (max 63 chars)."
          )
        end
    end
  end

  defp resolve_expected_tables! do
    kw = Application.get_env(:threadline, :verify_coverage)

    tables =
      case kw do
        nil ->
          Mix.raise(
            "Threadline: configure :verify_coverage with :expected_tables — expected_tables is required."
          )

        opts when is_list(opts) ->
          case Keyword.get(opts, :expected_tables) do
            nil ->
              Mix.raise(
                "Threadline: :verify_coverage must include :expected_tables — expected_tables is required."
              )

            [] ->
              Mix.raise(
                "Threadline: :expected_tables must be a non-empty list of table name strings."
              )

            list when is_list(list) ->
              Enum.map(list, &expected_table_name!/1)

            other ->
              Mix.raise(
                "Threadline: :expected_tables must be a list of strings, got: #{inspect(other)}"
              )
          end

        other ->
          Mix.raise("Threadline: :verify_coverage must be a keyword list, got: #{inspect(other)}")
      end

    tables
  end

  defp expected_table_name!(name) when is_binary(name), do: name

  defp expected_table_name!(other) do
    Mix.raise(
      "Threadline: :expected_tables must contain only binary strings, got: #{inspect(other)}"
    )
  end

  defp print_report(expected, coverage, counts) do
    by_table = Map.new(coverage, fn {st, name} -> {name, st} end)

    rows =
      expected
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.map(fn table ->
        status =
          case Map.fetch(by_table, table) do
            {:ok, :covered} -> "covered"
            {:ok, :uncovered} -> "uncovered"
            :error -> "missing"
          end

        {table, status}
      end)

    table_w = max(5, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 5 end))
    table_w = max(table_w, byte_size("TABLE"))

    header = String.pad_trailing("TABLE", table_w) <> "  STATUS"
    rule = String.duplicate("-", String.length(header))

    Mix.shell().info(header)
    Mix.shell().info(rule)

    for {t, st} <- rows do
      Mix.shell().info(String.pad_trailing(t, table_w) <> "  " <> st)
    end

    Mix.shell().info(
      "summary: #{counts.covered}/#{counts.expected} expected tables covered (#{counts.violated} violated)"
    )
  end

  defp print_findings(%{gated: gated, not_gated: not_gated, warnings: warnings}) do
    Mix.shell().info("")
    Mix.shell().info("FINDINGS")

    printed = gated ++ warnings

    if printed == [] do
      Mix.shell().info("none")
    else
      print_finding_rows(printed)
    end

    _ =
      if not_gated != [] do
        Mix.shell().info("")
        Mix.shell().info("NOT GATED (table not in :expected_tables)")
        print_finding_rows(not_gated)
      end

    Mix.shell().info("")

    if gated == [] and not_gated == [] and warnings == [] do
      Mix.shell().info("findings: none")
    else
      Mix.shell().info(
        "findings: #{length(gated)} gated error(s), #{length(not_gated)} not-gated error(s), " <>
          "#{length(warnings)} warning(s)"
      )
    end
  end

  defp print_finding_rows(findings) do
    rows =
      Enum.map(findings, fn f ->
        {String.upcase(Atom.to_string(f.severity)), Atom.to_string(f.code),
         "#{f.schema}.#{f.table}", f.message}
      end)

    severity_w = max(8, rows |> Enum.map(&byte_size(elem(&1, 0))) |> Enum.max(fn -> 8 end))
    code_w = rows |> Enum.map(&byte_size(elem(&1, 1))) |> Enum.max(fn -> 4 end)
    code_w = max(code_w, byte_size("CODE"))
    table_w = rows |> Enum.map(&byte_size(elem(&1, 2))) |> Enum.max(fn -> 5 end)
    table_w = max(table_w, byte_size("TABLE"))

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
end
