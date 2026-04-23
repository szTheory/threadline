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

  Prints a `TABLE` / `STATUS` report to stdout, then a line containing `summary:`
  with counts. Exits with status **1** if any expected table is missing or
  uncovered; exits **0** when all expected tables are covered.

  Table names in output are public-schema metadata only (same scope as `Health`).
  """

  use Mix.Task

  alias Threadline.Verify.CoveragePolicy

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)
    expected = resolve_expected_tables!()

    coverage = Threadline.Health.trigger_coverage(repo: repo)
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
