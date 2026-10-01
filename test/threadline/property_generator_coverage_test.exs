defmodule Threadline.PropertyGeneratorCoverageTest do
  @moduledoc """
  D-22: StreamData has no `classify`/`cover`, so this module samples each of
  this phase's generators deterministically and asserts floors, set well
  below the expected rate, that prove the generator's stated bias actually
  reaches the cases its moduledoc claims.

  `sample/2` deliberately does not pipe one `StreamData.seeded/2` generator
  into Elixir's enumerable-draining functions to pull many elements:
  `StreamData.seeded/2` ignores the per-element seed its caller feeds it (it
  hard-codes its own seed into the returned generator — see
  `deps/stream_data/lib/stream_data.ex`), so draining many elements from one
  seeded generator that way returns many copies of a single value, not many
  independent samples. A coverage floor over identical samples would be
  vacuous. Draining an unseeded generator is not an option either — it seeds
  from the wall clock, so a floor computed from it would be non-deterministic
  (flaky under a `--seed` replay). `sample/2` instead calls
  `StreamData.seeded/2` once per index with a *different* integer seed, each
  wrapped in its own single-element pull, giving `n` independent,
  deterministic draws; the `rem(i, 100) + 1` size ramp (`StreamData.resize/2`)
  also varies draw size across the sample, the same way `check all` varies it
  across runs.
  """

  use ExUnit.Case, async: true

  alias Threadline.Test.ChangeFactGenerators
  alias Threadline.Test.CursorGenerators
  alias Threadline.Test.ExportHostileValueGenerators
  alias Threadline.Test.RedactionLeakGenerators
  alias Threadline.Test.RedactionPolicyGenerators

  @sample_size 1000

  @doc "n independent, deterministic draws from `gen`, varying size across the draw."
  def sample(gen, n \\ @sample_size) do
    for i <- 1..n do
      gen
      |> StreamData.resize(rem(i, 100) + 1)
      |> StreamData.seeded(i)
      |> Enum.at(0)
    end
  end

  @doc """
  n independent, deterministic draws from a DB-backed generator, with a
  1..20 size ramp (`rem(i, 20) + 1`) matching `PropertyRuns.db/1`'s max_runs
  ceiling, rather than `sample/2`'s 1..100 ramp for pure properties (D-26).
  """
  def sample_db(gen, n \\ @sample_size) do
    for i <- 1..n do
      gen
      |> StreamData.resize(rem(i, 20) + 1)
      |> StreamData.seeded(i)
      |> Enum.at(0)
    end
  end

  # ---------------------------------------------------------------------
  # Cursor paging (CursorGenerators.paging_gen/0)
  # ---------------------------------------------------------------------

  defp ts_frequencies(entries), do: entries |> Enum.map(& &1.ts_usec) |> Enum.frequencies()

  defp has_duplicate_ts?(entries) do
    entries |> ts_frequencies() |> Map.values() |> Enum.any?(&(&1 >= 2))
  end

  defp max_tie_group_size(entries) do
    entries |> ts_frequencies() |> Map.values() |> Enum.max(fn -> 0 end)
  end

  defp has_adjacent_1us_gap?(entries) do
    entries
    |> Enum.map(& &1.ts_usec)
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [a, b] -> b - a == 1 end)
  end

  describe "CursorGenerators.paging_gen/0 (tie-heavy cursor bias)" do
    test "at least 25% of tie lists contain a duplicate timestamp" do
      samples = sample(CursorGenerators.paging_gen())
      dup_count = Enum.count(samples, fn {entries, _k} -> has_duplicate_ts?(entries) end)

      assert dup_count / length(samples) >= 0.25,
             "expected >=25% of samples to contain a duplicated ts_usec (tie-heavy bias), " <>
               "got #{dup_count}/#{length(samples)}"
    end

    test "some tie lists contain a timestamp shared by 3 or more entries" do
      samples = sample(CursorGenerators.paging_gen())

      assert Enum.any?(samples, fn {entries, _k} -> max_tie_group_size(entries) >= 3 end),
             "expected at least one sample with a 3+ way timestamp tie"
    end

    test "some tie lists have adjacent groups exactly 1 microsecond apart" do
      samples = sample(CursorGenerators.paging_gen())

      assert Enum.any?(samples, fn {entries, _k} -> has_adjacent_1us_gap?(entries) end),
             "expected at least one sample exercising the off-by-one-microsecond boundary"
    end

    test "page sizes include k == n and k > n at least once each" do
      samples = sample(CursorGenerators.paging_gen())

      assert Enum.any?(samples, fn {entries, k} ->
               n = length(entries)
               n > 0 and k == n
             end),
             "expected at least one sample where the page size equals the entry count"

      assert Enum.any?(samples, fn {entries, k} -> k > length(entries) end),
             "expected at least one sample where the page size exceeds the entry count"
    end
  end

  # ---------------------------------------------------------------------
  # ChangeDiff facts (ChangeFactGenerators.fact_gen/0)
  # ---------------------------------------------------------------------

  defp normalize_op(op), do: String.upcase(op)

  defp present_nil_prior?(fact) do
    Enum.any?(fact.fields, &match?(%{prior: {:present, nil}}, &1))
  end

  describe "ChangeFactGenerators.fact_gen/0 (op x before_values matrix bias)" do
    test "every op x before_values cell (ChangeFactGenerators.op_cells/0) has at least 1 sample" do
      samples = sample(ChangeFactGenerators.fact_gen())
      seen_cells = samples |> Enum.map(&{normalize_op(&1.op), &1.mode}) |> MapSet.new()
      missing_cells = Enum.reject(ChangeFactGenerators.op_cells(), &(&1 in seen_cells))

      assert missing_cells == [],
             "every op x before_values cell must be reached within " <>
               "#{@sample_size} samples; missing: #{inspect(missing_cells)}"
    end

    test "{:present, nil} priors (a captured JSON null) appear at least once" do
      samples = sample(ChangeFactGenerators.fact_gen())

      assert Enum.any?(samples, &present_nil_prior?/1),
             "expected at least one sample with a {:present, nil} prior " <>
               "(protects the null-vs-omitted boundary)"
    end
  end

  # ---------------------------------------------------------------------
  # Redaction policy (RedactionPolicyGenerators.policy_gen/0)
  # ---------------------------------------------------------------------

  describe "RedactionPolicyGenerators.policy_gen/0 (valid/invalid defect-tag bias)" do
    test "every defect tag (RedactionPolicyGenerators.defect_tags/0) has at least 1 sample" do
      samples = sample(RedactionPolicyGenerators.policy_gen())

      seen_tags =
        samples
        |> Enum.filter(&match?({:invalid, _tag, _col, _opts}, &1))
        |> Enum.map(fn {:invalid, tag, _col, _opts} -> tag end)
        |> MapSet.new()

      missing_tags = Enum.reject(RedactionPolicyGenerators.defect_tags(), &(&1 in seen_tags))

      assert missing_tags == [],
             "every tagged defect must be reached within #{@sample_size} samples; " <>
               "missing: #{inspect(missing_tags)}"
    end

    test "valid samples make up at least 30%" do
      samples = sample(RedactionPolicyGenerators.policy_gen())
      valid_count = Enum.count(samples, &match?({:valid, _opts}, &1))

      assert valid_count / length(samples) >= 0.30,
             "expected >=30% valid policies (policy_gen/0 is biased 7:3 toward valid), " <>
               "got #{valid_count}/#{length(samples)}"
    end
  end

  # ---------------------------------------------------------------------
  # Export hostile values (ExportHostileValueGenerators.export_row_gen/0)
  # ---------------------------------------------------------------------

  defp collect_json_leaves(nil), do: [nil]
  defp collect_json_leaves(map) when is_map(map), do: Enum.flat_map(map, &leaf_from_pair/1)

  defp collect_json_leaves(list) when is_list(list),
    do: Enum.flat_map(list, &collect_json_leaves/1)

  defp collect_json_leaves(value), do: [value]

  defp leaf_from_pair({_key, value}), do: collect_json_leaves(value)

  defp raw_string_columns(row) do
    [row.table_schema, row.table_name, row.op, row.tx_source, row.aa_correlation_id]
  end

  defp non_ascii?(value) when is_binary(value) do
    value |> String.to_charlist() |> Enum.any?(&(&1 > 127))
  end

  defp export_leaves(samples) do
    Enum.reduce(samples, {[], []}, fn {_fact, _audit_change, row}, {raw_acc, json_acc} ->
      json_leaves = collect_json_leaves(row.data_after) ++ collect_json_leaves(row.changed_from)
      {raw_acc ++ raw_string_columns(row), json_acc ++ json_leaves}
    end)
  end

  describe "ExportHostileValueGenerators.export_row_gen/0 (CSV/JSON-hostile value bias)" do
    test "samples include a quote, a comma, a lone CR, a lone LF, non-ASCII and nil" do
      samples = sample(ExportHostileValueGenerators.export_row_gen())
      {raw_values, json_leaves} = export_leaves(samples)
      all_values = raw_values ++ json_leaves
      all_strings = Enum.filter(all_values, &is_binary/1)

      assert Enum.any?(all_strings, &(&1 == "\"")),
             "expected a raw-string or JSON-encoded column with a bare double-quote value"

      assert Enum.any?(all_strings, &(&1 == ",")),
             "expected a raw-string or JSON-encoded column with a bare comma value"

      assert Enum.any?(all_strings, &(&1 == "\r")),
             "expected a raw-string or JSON-encoded column with a lone CR value"

      assert Enum.any?(all_strings, &(&1 == "\n")),
             "expected a raw-string or JSON-encoded column with a lone LF value"

      assert Enum.any?(all_strings, &non_ascii?/1),
             "expected a raw-string or JSON-encoded column with a non-ASCII value"

      assert Enum.any?(all_values, &is_nil/1),
             "expected a nil value (a none before_values column, or a JSON null leaf)"
    end
  end

  # ---------------------------------------------------------------------
  # Redaction leak op plans (RedactionLeakGenerators.op_plan_gen/0)
  # ---------------------------------------------------------------------

  defp redacted_written_values(plan) do
    insert_values =
      [:secret_excluded, :secret_masked, :profile_masked]
      |> Enum.map(&RedactionLeakGenerators.value(Map.fetch!(plan.insert, &1)))

    step_values =
      Enum.flat_map(plan.steps, fn
        %{kind: :touch_redacted, values: values} ->
          values |> Map.values() |> Enum.map(&RedactionLeakGenerators.value/1)

        _ ->
          []
      end)

    insert_values ++ step_values
  end

  defp both_redacted_slots_touched?(plan) do
    Enum.any?(plan.steps, fn
      %{kind: :touch_redacted, values: values} ->
        Map.has_key?(values, :secret_excluded) and Map.has_key?(values, :secret_masked)

      _ ->
        false
    end)
  end

  defp multibyte?(value) when is_binary(value) do
    value |> String.to_charlist() |> Enum.any?(&(&1 > 127))
  end

  defp multibyte?(_), do: false

  describe "RedactionLeakGenerators.op_plan_gen/0 (canary and hostile-shape bias)" do
    test "a touch_redacted step changing both secret_excluded and secret_masked appears in >= 40% of plans (D-26)" do
      samples = sample_db(RedactionLeakGenerators.op_plan_gen())
      count = Enum.count(samples, &both_redacted_slots_touched?/1)

      assert count / length(samples) >= 0.40,
             "expected >=40% of plans to have a touch_redacted step touching both " <>
               "secret_excluded and secret_masked (protects the dual-mask/exclude " <>
               "coverage floor), got #{count}/#{length(samples)}"
    end

    test "redacted values cover nil, empty string, exact placeholder, placeholder as substring, multibyte, and >1KB (D-26)" do
      samples = sample_db(RedactionLeakGenerators.op_plan_gen())
      values = Enum.flat_map(samples, &redacted_written_values/1)

      assert Enum.any?(values, &is_nil/1),
             "expected at least one nil redacted value (structural-check-only rung)"

      assert Enum.any?(values, &(&1 == "")),
             "expected at least one empty-string redacted value (structural-check-only rung)"

      assert Enum.any?(values, &(&1 == "[REDACTED]")),
             "expected at least one exact-placeholder redacted value (structural-check-only rung)"

      assert Enum.any?(values, fn v ->
               is_binary(v) and v != "[REDACTED]" and String.contains?(v, "[REDACTED]")
             end),
             "expected at least one redacted value containing the placeholder as a substring " <>
               "without being the exact placeholder (hostile-wrapper bias)"

      assert Enum.any?(values, &multibyte?/1),
             "expected at least one multibyte redacted value (hostile-wrapper bias)"

      assert Enum.any?(values, fn v -> is_binary(v) and byte_size(v) > 1024 end),
             "expected at least one redacted value over 1 KB (padding bias)"
    end
  end
end
