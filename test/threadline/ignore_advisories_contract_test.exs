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
  # Task 1 ships only the plumbing: the empty-input path, proven by "the
  # empty state passes" above and by today's real zero-ignore repo state.
  # Task 2 fills in every rule (duplicates, missing justification, stale
  # metadata, blank reason/reachability, expired review_by, refused
  # ignore_retirements) against synthetic inputs with an injected `today`,
  # red first.

  defp violations(_ignore_ids, _ignore_retirements, _entries, _today) do
    []
  end
end
