defmodule Threadline.IgnoreAdvisoriesContractTest do
  @moduledoc """
  SUP-03 contract: make every Hex advisory suppression accountable.

  Hex's `hex: [ignore_advisories: [...]]` (see `mix help hex.audit`) is a bare
  list of advisory ID strings with no metadata — accepting one is a decision
  with no built-in accountability trail. This repo's convention: a Mix
  project that ignores an advisory defines a public `hex_audit_ignores/0` on
  its MixProject module, returning a list of maps with keys `:id`, `:reason`,
  `:reachability`, and `:review_by` (a `%Date{}`). The project's
  `hex: [ignore_advisories: [...]]` must be *exactly* those ids — every
  ignore has a matching justification, and every justification maps back to
  a live ignore (no stale metadata left behind once an advisory is fixed).

  `ignore_retirements` is refused outright: this convention's metadata does
  not cover retirements, so suppressing them would silently widen what "SUP-03
  accountability" means. Extending the convention to cover them is a
  deliberate future edit, not something that falls out of a bare ignore list.

  Why resolved config, not a source regex on mix.exs: `Mix.Project.config()`
  sees exactly the ids Hex itself uses when it runs `hex.audit` — however
  they were constructed (literal list, comprehension, module attribute) — so
  a project cannot spell its ignore list in a way that dodges this check.
  `Mix.Project.in_project/4` loads bench's and the example app's mix.exs on
  Mix's own project stack (and pops it afterwards), the same way Mix itself
  loads a path dependency — never Code's `eval_file` or `require_file`
  (assembled so this text never contains either as one literal call), either
  of which would load the module a second time outside Mix's own bookkeeping
  and print a module-redefinition warning.
  """

  use ExUnit.Case, async: false

  setup_all do
    {:ok, facts: project_facts()}
  end

  test "every advisory ignore in all three Mix projects is justified and unexpired", %{
    facts: facts
  } do
    today = Date.utc_today()

    for %{module: mod, ignore_ids: ignore_ids, ignore_retirements: retirements, entries: entries} <-
          facts do
      result = violations(ignore_ids, retirements, entries, today)

      assert result == [],
             "#{inspect(mod)} has unjustified, expired, or stale hex advisory ignores:\n" <>
               Enum.join(result, "\n") <>
               "\n\nConvention: define hex_audit_ignores/0 on the MixProject module, returning a " <>
               "list of %{id:, reason:, reachability:, review_by:} maps (review_by a %Date{} " <>
               "after today). hex: [ignore_advisories: [...]] must list exactly those ids. " <>
               "ignore_retirements is refused."
    end
  end

  test "the live check inspected exactly the three Mix projects", %{facts: facts} do
    modules = Enum.map(facts, & &1.module)

    assert modules == [Threadline.MixProject, Bench.MixProject, ThreadlinePhoenix.MixProject]
  end

  test "the empty state passes" do
    assert violations([], [], [], ~D[2026-09-26]) == []
  end

  # --- Every SUP-03 rule, proven on synthetic inputs with an injected date -
  #
  # Fixed ~D[2026-09-26] is used as "today" throughout this section; the
  # live test above is the only one that asks the system clock what day it is.

  @today ~D[2026-09-26]

  @valid_entry %{
    id: "GHSA-aaaa-bbbb-cccc",
    reason: "r",
    reachability: "not reachable: test-only",
    review_by: ~D[2026-09-27]
  }

  test "a valid, unexpired, matched entry produces no violations" do
    assert violations([@valid_entry.id], [], [@valid_entry], @today) == []
  end

  test "review_by equal to today is expired" do
    entry = %{@valid_entry | review_by: @today}

    assert [violation] = violations([entry.id], [], [entry], @today)
    assert violation =~ "expired"
  end

  test "review_by before today is expired" do
    entry = %{@valid_entry | review_by: ~D[2026-09-25]}

    assert [violation] = violations([entry.id], [], [entry], @today)
    assert violation =~ "expired"
  end

  test "a missing, empty, or whitespace-only reason is a violation" do
    for entry <- [
          Map.delete(@valid_entry, :reason),
          Map.put(@valid_entry, :reason, ""),
          Map.put(@valid_entry, :reason, "   ")
        ] do
      assert [violation] = violations([@valid_entry.id], [], [entry], @today)
      assert violation =~ "reason"
    end
  end

  test "a missing, empty, or whitespace-only reachability is a violation" do
    for entry <- [
          Map.delete(@valid_entry, :reachability),
          Map.put(@valid_entry, :reachability, ""),
          Map.put(@valid_entry, :reachability, "   ")
        ] do
      assert [violation] = violations([@valid_entry.id], [], [entry], @today)
      assert violation =~ "reachability"
    end
  end

  test "a missing or non-Date review_by is a violation" do
    for entry <- [
          Map.delete(@valid_entry, :review_by),
          Map.put(@valid_entry, :review_by, "2026-12-01")
        ] do
      assert [violation] = violations([@valid_entry.id], [], [entry], @today)
      assert violation =~ "review_by"
    end
  end

  test "an ignore id with no matching entry has no justification" do
    assert [violation] = violations([@valid_entry.id], [], [], @today)
    assert violation =~ "no justification"
  end

  test "an entry whose id is not in ignore_advisories is stale" do
    assert [violation] = violations([], [], [@valid_entry], @today)
    assert violation =~ "stale"
  end

  test "the same id twice in ignore_advisories is a duplicate" do
    assert [violation] =
             violations([@valid_entry.id, @valid_entry.id], [], [@valid_entry], @today)

    assert violation =~ "duplicate"
  end

  test "the same id twice in entries is a duplicate" do
    result = violations([@valid_entry.id], [], [@valid_entry, @valid_entry], @today)
    assert Enum.any?(result, &(&1 =~ "duplicate"))
  end

  test "a non-empty ignore_retirements is refused" do
    result_atom_list = violations([], [:decimal], [], @today)
    assert Enum.any?(result_atom_list, &(&1 =~ "ignore_retirements"))

    result_keyword_list = violations([], [[phoenix: "1.0.0"]], [], @today)
    assert Enum.any?(result_keyword_list, &(&1 =~ "ignore_retirements"))
  end

  test "an input with three different violations sorts deterministically and repeats identically" do
    ignore_ids = ["id-1"]
    entries = [Map.put(@valid_entry, :id, "id-2")]
    retirements = [:decimal]

    result1 = violations(ignore_ids, retirements, entries, @today)
    result2 = violations(ignore_ids, retirements, entries, @today)

    assert length(result1) == 3
    assert result1 == Enum.sort(result1)
    assert result1 == result2
  end

  # --- project_facts/0 --------------------------------------------------
  #
  # Called exactly once per run, from setup_all. Mix.Project.in_project/4
  # mutates Mix's global project stack (loading bench's and the example
  # app's mix.exs, then popping it) — loading either a second time would
  # redefine its MixProject module and print a warning, hence this suite
  # runs with case-level concurrency disabled and a single setup_all call
  # rather than one per test.

  defp project_facts do
    [
      root_fact(),
      bench_fact(),
      threadline_phoenix_fact()
    ]
  end

  defp root_fact do
    build_fact(Mix.Project.get!(), Mix.Project.config())
  end

  defp bench_fact do
    full_path = Path.join(File.cwd!(), "bench")

    Mix.Project.in_project(:bench, full_path, fn mod ->
      build_fact(mod, Mix.Project.config())
    end)
  end

  defp threadline_phoenix_fact do
    full_path = Path.join(File.cwd!(), "examples/threadline_phoenix")

    Mix.Project.in_project(:threadline_phoenix, full_path, fn mod ->
      build_fact(mod, Mix.Project.config())
    end)
  end

  defp build_fact(mod, config) do
    hex_config = config[:hex] || []

    entries =
      if function_exported?(mod, :hex_audit_ignores, 0) do
        mod.hex_audit_ignores()
      else
        []
      end

    %{
      module: mod,
      ignore_ids: hex_config[:ignore_advisories] || [],
      ignore_retirements: hex_config[:ignore_retirements] || [],
      entries: entries
    }
  end

  # --- violations/4 (pure validator) -------------------------------------
  #
  # Every rule SUP-03 names, proven above on synthetic inputs before being
  # implemented here: duplicate ignore ids, duplicate entry ids, an ignore
  # with no matching entry (no justification), an entry with no matching
  # ignore (stale), blank reason/reachability, an expired or missing/invalid
  # review_by, and a refused ignore_retirements. The result is sorted and
  # deduplicated so repeated calls on the same input are byte-identical.

  defp violations(ignore_ids, ignore_retirements, entries, today) do
    ignore_ids = List.wrap(ignore_ids)
    entries = List.wrap(entries)
    ignore_retirements = List.wrap(ignore_retirements)

    entries_by_id = Enum.group_by(entries, & &1[:id])

    duplicate_ignore_ids =
      ignore_ids
      |> Enum.frequencies()
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(fn {id, _count} ->
        "duplicate ignore id #{inspect(id)}: listed more than once in ignore_advisories — remove the repeat"
      end)

    duplicate_entry_ids =
      entries_by_id
      |> Enum.filter(fn {_id, list} -> length(list) > 1 end)
      |> Enum.map(fn {id, _list} ->
        "duplicate entry id #{inspect(id)}: hex_audit_ignores/0 defines this id more than once — " <>
          "remove the repeat"
      end)

    missing_justification =
      ignore_ids
      |> Enum.uniq()
      |> Enum.reject(&Map.has_key?(entries_by_id, &1))
      |> Enum.map(fn id ->
        "#{inspect(id)}: no justification — ignore_advisories lists this id but hex_audit_ignores/0 " <>
          "has no matching entry; add one or remove the ignore"
      end)

    stale_entries =
      entries
      |> Enum.map(& &1[:id])
      |> Enum.reject(&(&1 in ignore_ids))
      |> Enum.uniq()
      |> Enum.map(fn id ->
        "#{inspect(id)}: stale justification — hex_audit_ignores/0 has an entry for this id but " <>
          "ignore_advisories does not list it; remove the entry"
      end)

    entry_rule_violations = Enum.flat_map(entries, &entry_violations(&1, today))

    retirement_violations =
      if ignore_retirements == [] do
        []
      else
        [
          "ignore_retirements is not permitted: found #{inspect(ignore_retirements)} — this " <>
            "convention does not cover retirements; remove it, or deliberately extend the " <>
            "convention to cover it"
        ]
      end

    [
      duplicate_ignore_ids,
      duplicate_entry_ids,
      missing_justification,
      stale_entries,
      entry_rule_violations,
      retirement_violations
    ]
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp entry_violations(entry, today) do
    id = Map.get(entry, :id)

    []
    |> maybe_violation(
      blank?(Map.get(entry, :reason)),
      "#{inspect(id)}: reason is missing or blank — add a non-blank reason field"
    )
    |> maybe_violation(
      blank?(Map.get(entry, :reachability)),
      "#{inspect(id)}: reachability is missing or blank — add a non-blank reachability field"
    )
    |> maybe_violation(
      not review_by_ok?(Map.get(entry, :review_by), today),
      review_by_message(id, Map.get(entry, :review_by), today)
    )
  end

  defp maybe_violation(list, false, _message), do: list
  defp maybe_violation(list, true, message), do: [message | list]

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(_value), do: true

  defp review_by_ok?(%Date{} = review_by, today), do: Date.compare(review_by, today) == :gt
  defp review_by_ok?(_review_by, _today), do: false

  defp review_by_message(id, %Date{} = review_by, today) do
    "#{inspect(id)}: review_by #{review_by} is expired (on or before #{today}) — extend it after " <>
      "re-review, or remove the ignore"
  end

  defp review_by_message(id, _review_by, _today) do
    "#{inspect(id)}: review_by is missing or not a Date — add review_by as a %Date{} after today"
  end
end
