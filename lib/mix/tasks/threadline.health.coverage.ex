defmodule Mix.Tasks.Threadline.Health.Coverage do
  @shortdoc "Show trigger coverage for audited tables"

  @moduledoc """
  Shows trigger coverage as reported by `Threadline.Health.trigger_coverage/1`,
  with a three-section table (default) or JSON output (`--json`).

  Viewer by default (exits 0); `--strict` turns `:error`-severity findings into exit 1.
  Uncovered tables never fail `--strict`; use `mix threadline.verify_coverage` for the positive-list gate.

  ## Usage

      mix threadline.health.coverage
      mix threadline.health.coverage --json
      mix threadline.health.coverage --schema=NAME
      mix threadline.health.coverage --strict
      mix threadline.health.coverage --strict --json

  Default output: a three-section TABLE / STATUS / SOURCE table followed by
  a `Coverage: N covered, M uncovered, K expected uncovered` summary line.

  `--json` emits a JSON object with keys `covered`, `expected_uncovered`,
  `findings`, `schema`, `uncovered`. The `expected_uncovered` value is a list of
  `{"table": ..., "source": "baseline" | "config"}` objects so adopters can
  filter via `jq '.expected_uncovered[] | select(.source == "config")'`.
  `findings` is a list of `Threadline.Health.trigger_findings/1` plus
  `Threadline.Health.legacy_key_findings/1` results, each with keys `code`,
  `severity`, `schema`, `table`, `message`, `details` (`code` and `severity`
  as strings). This key is additive: every other key keeps its existing
  shape, and `--json` stdout stays exactly one pure JSON document — the
  `--strict` status line below never reaches it.

  Default output also gains a `FINDINGS` section after the existing table,
  with columns `SEVERITY`, `CODE`, `TABLE`, `MESSAGE`.

  `--strict` gates the `--schema` schema (default `"public"`); after the
  normal output it prints one status line to stderr via
  `Mix.shell().error/1` — `strict: FAILED — N error finding(s) ...` and
  `exit({:shutdown, 1})` when any in-scope `:error` finding is present, or
  `strict: passed (W warning(s) not gated)` otherwise. Uncovered tables and
  `:warning` findings are never gated.

  If the `:unresolved_legacy_keys` probe (from `legacy_key_findings/1`) times
  out — typically a missing row-history index — the task prints a one-line
  hint to stderr pointing at
  [Step 4](upgrading-to-0.11.md#step-4-add-the-row-history-index) and
  continues with the trigger findings only; a timeout never fails `--strict`.

  A malformed `config :threadline, :trigger_capture` stops the task with
  `Mix.raise/1` before any findings are checked.

  `--schema=NAME` validates NAME at the edge (regex + `pg_namespace` lookup)
  and raises with `Mix.raise/1` on bad input. NAME must match
  `~r/\\A[a-z_][a-z0-9_]{0,62}\\z/` (PostgreSQL identifier, conservative subset)
  AND exist in `pg_namespace`. Default `"public"`.

  An unknown or invalid switch (for example `--stict`, `--jsn`, or `--schema`
  with no value) raises `Mix.raise/1` naming the offending switch, before the
  repo starts.
  """

  use Mix.Task

  alias Threadline.Capture.TriggerCaptureConfig
  alias Threadline.Health.CoverageSchemas

  @impl Mix.Task
  def run(argv) do
    {opts, _, invalid} =
      OptionParser.parse(argv,
        strict: [json: :boolean, schema: :string, strict: :boolean, all_schemas: :boolean]
      )

    if invalid != [] do
      invalid_names = Enum.map_join(invalid, ", ", fn {name, _value} -> name end)

      Mix.raise(
        "threadline.health.coverage: unknown or invalid option(s): #{invalid_names}. " <>
          "Valid options: --json, --schema=NAME, --strict, --all-schemas."
      )
    end

    all_schemas? = Keyword.get(opts, :all_schemas, false)

    if Keyword.has_key?(opts, :schema) and all_schemas? do
      Mix.raise(
        "threadline.health.coverage: --schema and --all-schemas cannot be used together. " <>
          "Use --schema=NAME for one schema or --all-schemas for every schema."
      )
    end

    json? = Keyword.get(opts, :json, false)
    schema = Keyword.get(opts, :schema, "public")
    strict? = Keyword.get(opts, :strict, false)

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    _ = load_capture_config!()

    if all_schemas? do
      run_all_schemas(repo, json?, strict?)
    else
      validate_schema!(repo, schema)
      run_single_schema(repo, schema, json?, strict?)
    end
  end

  defp run_single_schema(repo, schema, json?, strict?) do
    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)

    findings =
      (Threadline.Health.trigger_findings(repo: repo, schema: schema) ++
         legacy_findings_or_hint(repo, schema: schema))
      |> Enum.sort_by(&{&1.schema, &1.table, Atom.to_string(&1.code), &1.message})

    if json? do
      render_json(schema, coverage, findings)
    else
      render_table(schema, coverage, findings)
    end

    # Viewer by default: report findings and return :ok. Use
    # mix threadline.verify_coverage when CI must fail on uncovered tables.
    # --strict turns any :error-severity finding into exit 1 here too, but
    # never gates on uncovered tables or warnings — that stays
    # verify_coverage's positive-list job.
    if strict? do
      apply_strict_gate(findings)
    else
      :ok
    end
  end

  defp run_all_schemas(repo, json?, strict?) do
    coverage_by_schema = Threadline.Health.coverage_by_schema(repo: repo)

    findings =
      (Threadline.Health.trigger_findings(repo: repo) ++ legacy_findings_or_hint(repo, []))
      |> Enum.sort_by(&{&1.schema, &1.table, Atom.to_string(&1.code), &1.message})

    if json? do
      render_json_all_schemas(coverage_by_schema, findings)
    else
      render_table_all_schemas(coverage_by_schema, findings)
    end

    if strict? do
      apply_strict_gate(findings)
    else
      :ok
    end
  end

  # Runs Threadline.Health.legacy_key_findings/1 and rescues only a
  # cancelled-probe timeout (Postgrex.Error with postgres code
  # :query_canceled, typically a missing row-history index): prints a hint
  # to stderr and continues with [] rather than failing the whole task. Any
  # other exception propagates unchanged. A timeout never fails --strict.
  @doc false
  def legacy_findings_or_hint(repo, opts) do
    Threadline.Health.legacy_key_findings([repo: repo] ++ opts)
  rescue
    e in Postgrex.Error ->
      if match?(%{postgres: %{code: :query_canceled}}, e) do
        Mix.shell().error(
          "threadline.health.coverage: the unresolved legacy key check timed out and was " <>
            "skipped; add the row-history index: " <>
            "guides/upgrading-to-0.11.md#step-4-add-the-row-history-index"
        )

        []
      else
        reraise e, __STACKTRACE__
      end
  end

  defp apply_strict_gate(findings) do
    {errors, warnings} = Enum.split_with(findings, &(&1.severity == :error))

    if errors != [] do
      Mix.shell().error(
        "strict: FAILED — #{length(errors)} error finding(s) " <>
          "(uncovered tables are not gated; use mix threadline.verify_coverage)"
      )

      exit({:shutdown, 1})
    else
      Mix.shell().error("strict: passed (#{length(warnings)} warning(s) not gated)")
      :ok
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

  # --all-schemas default (table) output: a leading SCHEMA column (kubectl
  # -A style), a per-schema rollup, a grand total across every reported
  # schema, then the unchanged FINDINGS section (print_finding_rows/1
  # already prints "schema.table"). A schema is reported under the same
  # rule as the JSON envelope: at least one coverage row or one finding.
  defp render_table_all_schemas(coverage_by_schema, findings) do
    findings_by_schema = Enum.group_by(findings, & &1.schema)

    reported_schemas =
      (Map.keys(coverage_by_schema) ++ Map.keys(findings_by_schema))
      |> Enum.uniq()
      |> Enum.filter(fn schema ->
        Map.get(coverage_by_schema, schema, []) != [] or
          Map.get(findings_by_schema, schema, []) != []
      end)
      |> Enum.sort()

    schema_rows =
      for schema <- reported_schemas,
          {table, status, source} <-
            Enum.sort_by(Map.get(coverage_by_schema, schema, []), &elem(&1, 1))
            |> Enum.map(&row_for/1) do
        {schema, table, status, source}
      end

    schema_w =
      max(6, reported_schemas |> Enum.map(&byte_size/1) |> Enum.max(fn -> 6 end))

    table_w =
      max(24, schema_rows |> Enum.map(&byte_size(elem(&1, 1))) |> Enum.max(fn -> 5 end))

    status_w = 12

    header =
      String.pad_trailing("SCHEMA", schema_w) <>
        "  " <>
        String.pad_trailing("TABLE", table_w) <>
        "  " <> String.pad_trailing("STATUS", status_w) <> "  SOURCE"

    rule = String.duplicate("-", String.length(header))

    Mix.shell().info(header)
    Mix.shell().info(rule)

    for {schema, table, status, source} <- schema_rows do
      Mix.shell().info(
        String.pad_trailing(schema, schema_w) <>
          "  " <>
          String.pad_trailing(table, table_w) <>
          "  " <> String.pad_trailing(status, status_w) <> "  " <> source
      )
    end

    Mix.shell().info("")
    render_rollup(reported_schemas, coverage_by_schema, findings_by_schema, schema_w)

    Mix.shell().info("")
    Mix.shell().info("FINDINGS")

    if findings == [] do
      Mix.shell().info("none")
    else
      print_finding_rows(findings)
    end
  end

  defp render_rollup(reported_schemas, coverage_by_schema, findings_by_schema, schema_w) do
    rollup_header =
      String.pad_trailing("SCHEMA", schema_w) <>
        "  COVERED  UNCOVERED  EXPECTED  FINDINGS"

    Mix.shell().info(rollup_header)
    Mix.shell().info(String.duplicate("-", String.length(rollup_header)))

    totals =
      for schema <- reported_schemas do
        coverage = Map.get(coverage_by_schema, schema, [])
        schema_findings = Map.get(findings_by_schema, schema, [])
        covered = Enum.count(coverage, &match?({:covered, _}, &1))
        uncovered = Enum.count(coverage, &match?({:uncovered, _}, &1))
        expected = Enum.count(coverage, &match?({:expected_uncovered, _}, &1))

        Mix.shell().info(
          String.pad_trailing(schema, schema_w) <>
            "  " <>
            String.pad_trailing(Integer.to_string(covered), 7) <>
            "  " <>
            String.pad_trailing(Integer.to_string(uncovered), 9) <>
            "  " <>
            String.pad_trailing(Integer.to_string(expected), 8) <>
            "  " <> Integer.to_string(length(schema_findings))
        )

        {covered, uncovered, expected}
      end

    {covered_total, uncovered_total, expected_total} =
      Enum.reduce(totals, {0, 0, 0}, fn {c, u, e}, {ca, ua, ea} -> {ca + c, ua + u, ea + e} end)

    Mix.shell().info("")

    Mix.shell().info(
      "Coverage: #{covered_total} covered, #{uncovered_total} uncovered, " <>
        "#{expected_total} expected uncovered across #{length(reported_schemas)} schemas"
    )
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
    IO.puts(Jason.encode!(schema_payload(schema, coverage, findings)))
  end

  # Pure: builds the exact single-schema JSON payload. Called by the default
  # --json path and, once per reported schema, by --all-schemas, so the two
  # outputs are structurally guaranteed to agree (the --all-schemas golden
  # test pins this).
  defp schema_payload(schema, coverage, findings) do
    covered = for {:covered, t} <- coverage, do: t
    uncovered = for {:uncovered, t} <- coverage, do: t

    expected_uncovered =
      for {:expected_uncovered, t} <- coverage do
        %{"table" => t, "source" => source_for(t)}
      end

    %{
      "schema" => schema,
      "covered" => Enum.sort(covered),
      "uncovered" => Enum.sort(uncovered),
      "expected_uncovered" => Enum.sort_by(expected_uncovered, & &1["table"]),
      "findings" => Enum.map(findings, &finding_json/1)
    }
  end

  # --all-schemas --json: one envelope keyed by schema (sorted, encoded with
  # Jason.OrderedObject so the key order survives JSON encoding even past 32
  # keys, where a plain map would fall back to hash order) plus a summary of
  # grand totals. A schema is reported when it has at least one coverage row
  # or at least one finding; a schema with only findings (no reportable
  # tables) still appears, with an empty coverage payload.
  defp render_json_all_schemas(coverage_by_schema, findings) do
    findings_by_schema = Enum.group_by(findings, & &1.schema)

    reported_schemas =
      (Map.keys(coverage_by_schema) ++ Map.keys(findings_by_schema))
      |> Enum.uniq()
      |> Enum.filter(fn schema ->
        Map.get(coverage_by_schema, schema, []) != [] or
          Map.get(findings_by_schema, schema, []) != []
      end)
      |> Enum.sort()

    entries =
      for schema <- reported_schemas do
        coverage = Map.get(coverage_by_schema, schema, [])
        schema_findings = Map.get(findings_by_schema, schema, [])
        {schema, schema_payload(schema, coverage, schema_findings), coverage, schema_findings}
      end

    payload = %{
      "schemas" => Jason.OrderedObject.new(Enum.map(entries, fn {s, p, _, _} -> {s, p} end)),
      "summary" => %{
        "schemas" => length(entries),
        "covered" => count_status(entries, :covered),
        "uncovered" => count_status(entries, :uncovered),
        "expected_uncovered" => count_status(entries, :expected_uncovered),
        "error_findings" => count_severity(entries, :error),
        "warning_findings" => count_severity(entries, :warning)
      }
    }

    IO.puts(Jason.encode!(payload))
  end

  defp count_status(entries, status) do
    Enum.reduce(entries, 0, fn {_s, _p, coverage, _f}, acc ->
      acc + Enum.count(coverage, &match?({^status, _}, &1))
    end)
  end

  defp count_severity(entries, severity) do
    Enum.reduce(entries, 0, fn {_s, _p, _c, schema_findings}, acc ->
      acc + Enum.count(schema_findings, &(&1.severity == severity))
    end)
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
