defmodule Threadline.Query.AsOfPropertyTest do
  @moduledoc """
  PROP-06: `Threadline.Query.as_of/4` at every point in a row's history
  equals an independent, in-order replay of the real mutations that
  produced that history (ROADMAP SC2).

  Runs against a dedicated fixture table, `asof_prop_rows`, with the
  global capture function installed from `lib/` in `setup_all` (so a
  mutant to `lib/threadline/capture/trigger_sql.ex` takes effect every
  run, per D-14). The oracle is this test's own string-keyed model of the
  row, folded from the generated steps as they are applied as real
  parameterised SQL — never from `data_after`, `history_query/3`, or
  `as_of_query/4` (that would be the rejected Pitfall 3 tautology: flipping
  the SQL under test would flip the oracle too).

  `@max_runs PropertyRuns.db(20)` (D-05): measured at ~0.2s unscaled and
  well under budget at `THREADLINE_PROPERTY_SCALE=5` (~1s), so no need to
  drop below `db(20)`. Default `max_shrinking_steps`; no `max_run_time`.
  Worst case shrink cost stays bounded by ~100 x one iteration's measured
  ms (D-05) — each iteration is a handful of DB round trips plus up to 8
  steps' readbacks and probes, so shrinking stays cheap.

  Numeric and timestamptz columns are never generated (`RowHistoryGenerators`):
  `numeric` round-trips lossy through Jason, and `timestamptz` renders in
  the session timezone — either would fail this property on capture
  fidelity, not on `as_of` (CONTEXT.md D-14, Deferred).

  A second property, the `:limit` prefix contract (QRY-01/QRY-02, D-04),
  reuses this file's `asof_prop_rows` table, `AsOfPropRow` schema, and
  `history_gen/0`: for every generated row history, it applies the same
  batches as real SQL (ignoring the `as_of` probes), reads the unbounded
  `Threadline.Query.RowReads.audit_changes/3` result once as `full` (passing
  `limit: :infinity` explicitly, D-13 -- this is the plain-`AuditChange`
  baseline the deprecated `Query.history/3` used to provide), then asserts
  `RowReads.audit_changes(..., limit: n) == Enum.take(full, n)` for every `n`
  from 1 through `length(full) + 2`. No new generator or table is registered.
  """

  use Threadline.DataCase, async: false
  use ExUnitProperties

  import Threadline.Test.DbProperty
  import Threadline.Test.RowHistoryGenerators

  alias Threadline.Capture.TriggerSQL
  alias Threadline.Query
  alias Threadline.Query.RowReads
  alias Threadline.StorageSchema
  alias Threadline.Test.PropertyRuns

  @t "asof_prop_rows"
  @max_runs PropertyRuns.db(20)
  @cast_fields [:id, :name, :note, :n, :flag, :doc]

  defmodule AsOfPropRow do
    @moduledoc false
    use Ecto.Schema

    @primary_key {:id, :id, autogenerate: false}
    schema "asof_prop_rows" do
      field(:name, :string)
      field(:note, :string)
      field(:n, :integer)
      field(:flag, :boolean)
      field(:doc, :map)
    end
  end

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@t} (
      id   bigint PRIMARY KEY,
      name text NOT NULL,
      note text NULL,
      n    bigint,
      flag boolean,
      doc  jsonb
    )
    """)

    # Reinstalled from lib/ every run (not just once) so a capture_clock
    # or other global-function mutant takes effect (D-14, D-16).
    Repo.query!(TriggerSQL.install_function([]))
    Repo.query!(TriggerSQL.create_trigger(@t))

    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@t))
      Repo.query!("DROP TABLE IF EXISTS #{@t}")
    end)

    :ok
  end

  property "as_of at every point in a row's history equals an in-order replay of the real mutations that produced it" do
    check all(batches <- history_gen(), max_runs: @max_runs) do
      with_iteration(
        fn n -> delete_iteration!(@t, [Integer.to_string(n)]) end,
        fn n -> run_history_and_probe(n, batches) end
      )
    end
  end

  property "RowReads.audit_changes(limit: n) equals Enum.take(audit_changes(), n) for every n in 1..length+2" do
    check all(batches <- history_gen(), max_runs: @max_runs) do
      with_iteration(
        fn n -> delete_iteration!(@t, [Integer.to_string(n)]) end,
        fn n -> run_history_limit_prefix(n, batches) end
      )
    end
  end

  # ── Second property: apply the same batches, then prove the :limit prefix ──

  defp run_history_limit_prefix(pk, batches) do
    _final_model =
      Enum.reduce(batches, nil, fn steps, model -> apply_batch_only(pk, steps, model) end)

    full = RowReads.audit_changes(AsOfPropRow, pk, repo: Repo, limit: :infinity)

    for n <- 1..(length(full) + 2) do
      assert RowReads.audit_changes(AsOfPropRow, pk, repo: Repo, limit: n) == Enum.take(full, n)
    end
  end

  defp apply_batch_only(pk, steps, model0) do
    {:ok, model} =
      Repo.transaction(fn ->
        Enum.reduce(steps, model0, fn step, model1 -> apply_step_only(pk, step, model1) end)
      end)

    model
  end

  defp apply_step_only(pk, {:write, full_row, _subset}, nil) do
    model = Map.put(full_row, "id", pk)
    insert_row!(pk, full_row)
    model
  end

  defp apply_step_only(pk, {:write, full_row, subset}, model) when is_map(model) do
    changed = Map.take(full_row, Enum.map(subset, &Atom.to_string/1))
    new_model = Map.merge(model, changed)
    update_row!(pk, new_model)
    new_model
  end

  defp apply_step_only(_pk, :delete, nil), do: nil

  defp apply_step_only(pk, :delete, model) when is_map(model) do
    delete_row!(pk)
    nil
  end

  # ── Apply the generated history as real SQL, folding the model ─────────

  defp run_history_and_probe(pk, batches) do
    audit_changes = StorageSchema.table("audit_changes")

    {_final_model, probes} =
      Enum.reduce(batches, {nil, []}, fn steps, acc ->
        run_batch(pk, steps, acc, audit_changes)
      end)

    assert_strictly_increasing!(probes)
    probe_as_of!(pk, probes)
  end

  defp run_batch(pk, steps, {model0, probes0}, audit_changes) do
    {:ok, result} =
      Repo.transaction(fn -> apply_steps(pk, steps, model0, probes0, audit_changes) end)

    result
  end

  defp apply_steps(pk, steps, model0, probes0, audit_changes) do
    Enum.reduce(steps, {model0, probes0}, fn step, {model1, probes1} ->
      apply_step(pk, step, model1, probes1, audit_changes)
    end)
  end

  defp apply_step(pk, {:write, full_row, _subset}, nil, probes, audit_changes) do
    model = Map.put(full_row, "id", pk)
    insert_row!(pk, full_row)
    {new_probes} = observe!(pk, "insert", model, probes, audit_changes)
    {model, new_probes}
  end

  defp apply_step(pk, {:write, full_row, subset}, model, probes, audit_changes)
       when is_map(model) do
    changed =
      full_row
      |> Map.take(Enum.map(subset, &Atom.to_string/1))

    new_model = Map.merge(model, changed)
    update_row!(pk, new_model)
    {new_probes} = observe!(pk, "update", new_model, probes, audit_changes)
    {new_model, new_probes}
  end

  defp apply_step(_pk, :delete, nil, probes, _audit_changes), do: {nil, probes}

  defp apply_step(pk, :delete, model, probes, audit_changes) when is_map(model) do
    delete_row!(pk)
    {new_probes} = observe!(pk, "delete", model, probes, audit_changes)
    {nil, new_probes}
  end

  defp insert_row!(pk, full_row) do
    Repo.query!(
      "INSERT INTO #{@t} (id, name, note, n, flag, doc) VALUES ($1, $2, $3, $4, $5, $6::jsonb)",
      [
        pk,
        full_row["name"],
        full_row["note"],
        full_row["n"],
        full_row["flag"],
        doc_param(full_row["doc"])
      ]
    )
  end

  defp update_row!(pk, model) do
    Repo.query!(
      "UPDATE #{@t} SET name = $2, note = $3, n = $4, flag = $5, doc = $6::jsonb WHERE id = $1",
      [pk, model["name"], model["note"], model["n"], model["flag"], doc_param(model["doc"])]
    )
  end

  defp delete_row!(pk) do
    Repo.query!("DELETE FROM #{@t} WHERE id = $1", [pk])
  end

  # Postgrex encodes an Elixir term bound to a jsonb parameter directly via
  # Jason; pre-encoding it here would double-encode it into a jsonb string
  # scalar instead of the intended nested object.
  defp doc_param(doc), do: doc

  # Links a step's captured_at to the step by observation: reads the new
  # `audit_changes` row(s) for this table/pk that were not already seen,
  # asserts exactly one, that its op matches the applied statement, and
  # (for insert/update) that its data_after equals the model.
  defp observe!(pk, expected_op, model_or_deleted, probes, audit_changes) do
    pk_str = Integer.to_string(pk)
    seen_ids = Enum.map(probes, fn {_ts, _expected, id} -> id end)

    %{rows: rows} =
      Repo.query!(
        "SELECT id::text, op, captured_at, data_after FROM #{audit_changes} " <>
          "WHERE table_name = $1 AND table_pk->>'id' = $2 AND NOT (id::text = ANY($3::text[]))",
        ["asof_prop_rows", pk_str, seen_ids]
      )

    assert length(rows) == 1,
           "step #{inspect(expected_op)} on pk #{pk_str}: expected exactly one new " <>
             "audit_changes row, got #{length(rows)}"

    [[id, op, captured_at, data_after]] = rows

    assert op == expected_op,
           "step #{inspect(expected_op)} on pk #{pk_str}: captured op #{inspect(op)} does " <>
             "not match the applied statement"

    if expected_op != "delete" do
      assert data_after == model_or_deleted,
             "step #{inspect(expected_op)} on pk #{pk_str}: capture differs from the model; " <>
               "this is a capture fidelity failure, not an as_of failure"
    end

    expected =
      if expected_op == "delete" do
        {:error, :deleted_record}
      else
        {:ok, model_or_deleted}
      end

    {probes ++ [{captured_at, expected, id}]}
  end

  defp assert_strictly_increasing!(probes) do
    probes
    |> Enum.map(fn {ts, _expected, _id} -> ts end)
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.each(fn [a, b] ->
      assert DateTime.compare(a, b) == :lt,
             "tie or clock step: captured_at did not strictly increase; as_of ordering is " <>
               "then decided by the uuid tiebreak, which is not causal"
    end)
  end

  # ── Deterministic probes: exact bound, one microsecond before it, and
  #    one hour after the last step ─────────────────────────────────────

  defp probe_as_of!(pk, []) do
    assert {:error, :before_audit_horizon} =
             Query.as_of(AsOfPropRow, pk, DateTime.utc_now(), repo: Repo)
  end

  defp probe_as_of!(pk, probes) do
    expectations = Enum.map(probes, fn {ts, expected, _id} -> {ts, expected} end)

    expectations
    |> Enum.with_index()
    |> Enum.each(fn {{ts, expected}, index} ->
      predecessor =
        if index == 0,
          do: {:error, :before_audit_horizon},
          else: elem(Enum.at(expectations, index - 1), 1)

      assert_as_of!(pk, ts, expected, "step #{index}, exact bound")

      assert_as_of!(
        pk,
        DateTime.add(ts, -1, :microsecond),
        predecessor,
        "step #{index}, one microsecond before"
      )
    end)

    {last_ts, last_expected} = List.last(expectations)

    assert_as_of!(
      pk,
      DateTime.add(last_ts, 3600, :second),
      last_expected,
      "one hour after the last step"
    )
  end

  defp assert_as_of!(pk, ts, expected, label) do
    assert Query.as_of(AsOfPropRow, pk, ts, repo: Repo) == expected,
           "as_of mismatch at #{label}"

    case expected do
      {:ok, model} ->
        assert {:ok, struct} = Query.as_of(AsOfPropRow, pk, ts, repo: Repo, cast: true)

        assert Map.take(struct, @cast_fields) == atomize(model),
               "cast: true mismatch at #{label}"

      _ ->
        :ok
    end
  end

  defp atomize(model) do
    for {k, v} <- model, into: %{}, do: {String.to_atom(k), v}
  end
end
