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
      end
    end)
    |> Enum.sort_by(fn {kind, name} -> {name, violation_rank(kind)} end)
  end

  defp violation_rank(:missing), do: 0
  defp violation_rank(:uncovered), do: 1

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
