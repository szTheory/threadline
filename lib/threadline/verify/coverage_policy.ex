defmodule Threadline.Verify.CoveragePolicy do
  @moduledoc """
  Pure policy for comparing `Threadline.Health.trigger_coverage/1` output with
  host-configured expected audited table names.

  **Intersection semantics:** Only tables listed in `expected_tables` are
  evaluated. Each must appear in the coverage list as `{:covered, name}`.
  `{:uncovered, name}` for an expected name is a violation. If a name is not
  present in the coverage list at all (e.g. typo or table outside the catalog
  `Health` enumerates), that is reported as `{:missing, name}`.

  An empty `expected_tables` list yields no violations; the Mix task fails
  closed before invoking this module when the configured list is missing or empty.

  ## Findings

  `partition_findings/2` sorts `Threadline.Health.Finding` structs into three
  buckets so a CI gate can fail on the ones it is responsible for while still
  surfacing everything else: `:error` findings on an expected table gate the
  task, `:error` findings on a table the host never listed are informational
  only, and `:warning` findings never fail the task regardless of table.
  """

  @doc """
  Returns a sorted list of violations for tables the host expects to be covered.

  `coverage` is `[{:covered | :uncovered, String.t()}]` from
  `Threadline.Health.trigger_coverage/1`. `expected_tables` is a list of
  unique public table name strings.
  """
  def violations(coverage, expected_tables)
      when is_list(coverage) and is_list(expected_tables) do
    by_table = Map.new(coverage, fn {status, name} -> {name, status} end)

    expected_tables
    |> Enum.uniq()
    |> Enum.flat_map(fn table ->
      case Map.fetch(by_table, table) do
        :error -> [{:missing, table}]
        {:ok, :uncovered} -> [{:uncovered, table}]
        {:ok, :covered} -> []
        {:ok, :expected_uncovered} -> []
      end
    end)
    |> Enum.sort_by(fn {kind, name} -> {violation_rank(kind), name} end)
  end

  defp violation_rank(:missing), do: 0
  defp violation_rank(:uncovered), do: 1

  @doc """
  Partitions `Threadline.Health.Finding` structs into gated, not-gated and
  warning buckets, given the host's expected-table positive list.

  - `:gated` — `:error` findings whose `table` is in `expected_tables`. These
    are the findings a CI gate must fail on.
  - `:not_gated` — `:error` findings whose `table` is not in `expected_tables`.
    Printed for visibility; never fails the task.
  - `:warnings` — every `:warning` finding, regardless of table.

  Each bucket keeps the input list's order. Pure; does not read the database
  or call `Mix.raise`.
  """
  @spec partition_findings([Threadline.Health.Finding.t()], [String.t()]) :: %{
          gated: [Threadline.Health.Finding.t()],
          not_gated: [Threadline.Health.Finding.t()],
          warnings: [Threadline.Health.Finding.t()]
        }
  def partition_findings(findings, expected_tables)
      when is_list(findings) and is_list(expected_tables) do
    expected = MapSet.new(Enum.uniq(expected_tables))

    gated =
      Enum.filter(findings, fn f -> f.severity == :error and MapSet.member?(expected, f.table) end)

    not_gated =
      Enum.filter(findings, fn f ->
        f.severity == :error and not MapSet.member?(expected, f.table)
      end)

    warnings = Enum.filter(findings, fn f -> f.severity == :warning end)

    %{gated: gated, not_gated: not_gated, warnings: warnings}
  end

  @doc """
  Counts expected tables vs how many are fully covered (no violation row).
  """
  def summary_counts(coverage, expected_tables) do
    expected = expected_tables |> Enum.uniq()
    total = length(expected)
    violated = violations(coverage, expected) |> length()
    %{expected: total, covered: total - violated, violated: violated}
  end
end
