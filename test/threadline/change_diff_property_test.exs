defmodule Threadline.ChangeDiffPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Threadline.ChangeDiff
  alias Threadline.Test.ChangeFactGenerators
  alias Threadline.Test.PropertyRuns

  # PROP-02: the expected value comes only from the generated facts
  # (`fact.fields`, `fact.mode`, `fact.extra_after`), never from inspecting
  # the built `%AuditChange{}`'s `data_after` / `changed_from` maps by key
  # lookup and never from calling `ChangeDiff` itself. See `expected/3`.
  describe "oracle: ChangeDiff matches the fact-derived expectation" do
    property "across the whole op x before_values matrix" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)

        assert ChangeDiff.from_audit_change(ch, []) === expected(fact, ch, [])
      end
    end

    property "expand_insert_fields derives one set row per data_after key on INSERT" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)
        opts = [expand_insert_fields: true]

        assert ChangeDiff.from_audit_change(ch, opts) === expected(fact, ch, opts)
      end
    end
  end

  describe "structural properties" do
    property "field_changes is sorted by name" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)
        names = field_names(ch, [])

        assert names == Enum.sort(names)
      end
    end

    property "UPDATE field_changes names equal changed_fields" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)

        if normalize_op(fact.op) == "UPDATE" do
          names = field_names(ch, [])
          assert MapSet.new(names) == MapSet.new(fact.field_names)
        end
      end
    end

    property "before_values none omits before and prior_state on every field" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)

        if normalize_op(fact.op) == "UPDATE" and fact.mode == :none do
          map = ChangeDiff.from_audit_change(ch, [])

          for entry <- map["field_changes"] do
            refute Map.has_key?(entry, "before")
            refute Map.has_key?(entry, "prior_state")
          end
        end
      end
    end

    property "sparse before_values has exactly one of before/prior_state per field" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)

        if normalize_op(fact.op) == "UPDATE" and fact.mode in [:sparse_empty, :sparse_partial] do
          map = ChangeDiff.from_audit_change(ch, [])

          for entry <- map["field_changes"] do
            has_before = Map.has_key?(entry, "before")
            has_prior_state = Map.has_key?(entry, "prior_state")
            assert has_before != has_prior_state
          end
        end
      end
    end

    property "DELETE always gives an empty field_changes list" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)

        if normalize_op(fact.op) == "DELETE" do
          map = ChangeDiff.from_audit_change(ch, [])
          assert map["field_changes"] == []
          assert map["data_after"] == nil
        end
      end
    end
  end

  describe "metamorphic properties" do
    property "atom-keyed data_after/changed_from give identical field_changes to string-keyed" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        string_fact = %{fact | keys: :string}
        atom_fact = %{fact | keys: :atom}

        string_map =
          ChangeDiff.from_audit_change(ChangeFactGenerators.to_audit_change(string_fact), [])

        atom_map =
          ChangeDiff.from_audit_change(ChangeFactGenerators.to_audit_change(atom_fact), [])

        assert string_map["field_changes"] == atom_map["field_changes"]
      end
    end

    property "shuffling changed_fields order does not change field_changes" do
      check all(fact <- ChangeFactGenerators.fact_gen(), max_runs: PropertyRuns.pure(150)) do
        ch = ChangeFactGenerators.to_audit_change(fact)
        shuffled_ch = %{ch | changed_fields: Enum.shuffle(ch.changed_fields || [])}

        assert ChangeDiff.from_audit_change(ch, []) ==
                 ChangeDiff.from_audit_change(shuffled_ch, [])
      end
    end

    property "extra data_after columns outside changed_fields leave UPDATE field_changes identical" do
      check all(
              fact <- ChangeFactGenerators.fact_gen(),
              extra_name <- member_of(~w(zzz_extra_a zzz_extra_b zzz_extra_c)),
              extra_value <-
                one_of([integer(), string(:alphanumeric, max_length: 5), boolean(), constant(nil)]),
              max_runs: PropertyRuns.pure(150)
            ) do
        ch = ChangeFactGenerators.to_audit_change(fact)

        if normalize_op(fact.op) == "UPDATE" and not Enum.member?(fact.field_names, extra_name) do
          widened_data_after = Map.put(ch.data_after || %{}, extra_name, extra_value)
          widened_ch = %{ch | data_after: widened_data_after}

          assert ChangeDiff.from_audit_change(ch, [])["field_changes"] ==
                   ChangeDiff.from_audit_change(widened_ch, [])["field_changes"]
        end
      end
    end
  end

  defp field_names(ch, opts) do
    ch
    |> ChangeDiff.from_audit_change(opts)
    |> Map.fetch!("field_changes")
    |> Enum.map(& &1["name"])
  end

  defp normalize_op(op), do: String.upcase(op)

  # The oracle. Reads only `fact` (the generated facts) plus the pass-through
  # identifier/metadata fields off `ch` (id, transaction_id, table_*,
  # captured_at, data_after) — never a keyed lookup into `ch.data_after` or
  # `ch.changed_from`, and never `Threadline.ChangeDiff` itself.
  defp expected(fact, ch, opts) do
    op = normalize_op(fact.op)

    base = %{
      "schema_version" => 1,
      "before_values" => before_values_label(fact.mode),
      "op" => op,
      "id" => to_string(ch.id),
      "transaction_id" => to_string(ch.transaction_id),
      "table_schema" => ch.table_schema,
      "table_name" => ch.table_name,
      "table_pk" => ch.table_pk || %{},
      "captured_at" => DateTime.to_iso8601(ch.captured_at),
      "data_after" => ch.data_after
    }

    Map.put(base, "field_changes", expected_field_changes(op, fact, opts))
  end

  defp before_values_label(:none), do: "none"
  defp before_values_label(_sparse), do: "sparse"

  defp expected_field_changes("DELETE", _fact, _opts), do: []

  defp expected_field_changes("INSERT", fact, opts) do
    if Keyword.get(opts, :expand_insert_fields, false) do
      expected_insert_expand(fact)
    else
      []
    end
  end

  defp expected_field_changes("UPDATE", fact, _opts) do
    fact.fields
    |> Enum.map(&expected_update_entry(&1, fact.mode))
    |> Enum.sort_by(& &1["name"])
  end

  defp expected_update_entry(f, :none) do
    %{"name" => f.name, "after" => present_or_nil(f.after)}
  end

  defp expected_update_entry(f, _sparse) do
    base = %{"name" => f.name, "after" => present_or_nil(f.after)}

    case f.prior do
      {:present, v} -> Map.put(base, "before", v)
      :absent -> Map.put(base, "prior_state", "omitted")
    end
  end

  defp present_or_nil({:present, v}), do: v
  defp present_or_nil(:absent), do: nil

  defp expected_insert_expand(fact) do
    present_values =
      fact.fields
      |> Enum.filter(&match?({:present, _}, &1.after))
      |> Enum.map(fn f -> {f.name, present_or_nil(f.after)} end)

    extra_values = Enum.map(fact.extra_after, fn e -> {e.name, e.value} end)

    (present_values ++ extra_values)
    |> Enum.sort_by(fn {name, _value} -> name end)
    |> Enum.map(fn {name, value} -> %{"name" => name, "after" => value, "kind" => "set"} end)
  end
end
