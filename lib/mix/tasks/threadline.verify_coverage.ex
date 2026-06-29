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
  uncovered; exits **0** when all expected tables are covered.

  Table names in output are public-schema metadata only (same scope as `Health`).

  ## Schema scope

  By default, this task verifies the `"public"` schema. Pass `--schema=NAME`
  to verify a non-`public` schema (e.g. `mix threadline.verify_coverage --schema=tenant_42`).
  NAME is validated at the edge (regex + `pg_namespace` lookup); invalid input
  exits 1 via `Mix.raise/1`.
  """

  use Mix.Task

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

    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
    violations = CoveragePolicy.violations(coverage, expected)
    counts = CoveragePolicy.summary_counts(coverage, expected)

    print_report(expected, coverage, counts)

    if violations != [] do
      exit({:shutdown, 1})
    end
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
              Enum.map(list, fn
                name when is_binary(name) ->
                  name

                other ->
                  Mix.raise(
                    "Threadline: :expected_tables must contain only binary strings, got: #{inspect(other)}"
                  )
              end)

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
end
