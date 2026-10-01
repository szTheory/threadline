defmodule Threadline.Test.ChangeFactGenerators do
  @moduledoc """
  Generates the ground truth first, then builds an `%AuditChange{}` from it.

  `fact_gen/0` draws a plain map of facts — op, before_values mode, key
  shape, and a per-field `%{name, after, prior}` list — before any
  `Threadline.ChangeDiff` struct exists. `to_audit_change/1` is the only
  function that turns those facts into a real `%AuditChange{}`; nothing in
  this module calls `Threadline.ChangeDiff` or inspects its output. A
  property's oracle reads the facts directly (see
  `Threadline.ChangeDiffPropertyTest.expected/3`), never the struct's
  `data_after` / `changed_from` by key lookup, so the comparison against
  the module under test's real output is never tautological.

  ## Biases

  - `{:present, nil}` (a captured JSON null) is about a third of all drawn
    priors; `:absent` is about a third; a present non-nil value is about a
    third. This exercises the "none" mode's unseen nulls and the
    "sparse"/"omitted" boundary that misreports a captured null as omitted.
  - A field named in `changed_fields` is absent from `data_after` about 30%
    of the time (capture can name a column without it surviving the
    snapshot, e.g. it was later excluded).
  - `op` is drawn in both lowercase (`"insert"`/`"update"`/`"delete"`, how
    capture persists it per the DB's `lower(TG_OP)` constraint) and
    uppercase canonical form.
  - `keys` picks one map-key shape, `:string` or `:atom`, applied
    consistently to every key in `data_after` and `changed_from` for that
    fact — never mixed, since `ChangeDiff`'s precedence for a map holding
    both an atom and a string form of the same key is unspecified.
  - `changed_from` is `nil` (mode `:none`), `%{}` (mode `:sparse_empty`,
    every prior forced `:absent` even though the fact still carries a
    `mode`), or a partial map of only the present priors (mode
    `:sparse_partial`).
  - Field-name selection is via a fixed-length boolean mask over a 12-name
    pool, so the draw is size-independent: every op x before_values matrix
    cell is reachable in a bounded number of runs regardless of how many
    fields happen to be selected on any one run.
  """

  use ExUnitProperties

  alias Threadline.Capture.AuditChange

  @pool ~w(name email status age active role note code level flag kind tag)
  @ops ~w(insert update delete INSERT UPDATE DELETE)
  @modes [:none, :sparse_empty, :sparse_partial]
  @key_shapes [:string, :atom]

  @doc """
  The 3 x 3 list of `{normalized_op, mode}` cells this generator's biases
  are meant to cover, for the generator-coverage test (plan 05).
  """
  def op_cells do
    for op <- ~w(INSERT UPDATE DELETE), mode <- @modes, do: {op, mode}
  end

  @doc "Generates one fact map (see moduledoc)."
  def fact_gen do
    gen all(
          op <- member_of(@ops),
          mode <- member_of(@modes),
          keys <- member_of(@key_shapes),
          field_mask <- mask_gen(length(@pool)),
          field_names = names_from_mask(@pool, field_mask),
          remaining_pool = @pool -- field_names,
          extra_mask <- mask_gen(length(remaining_pool)),
          extra_names = names_from_mask(remaining_pool, extra_mask),
          fields <- fixed_list(Enum.map(field_names, &field_entry_gen(&1, mode))),
          extra_after <- fixed_list(Enum.map(extra_names, &extra_entry_gen/1)),
          id_bytes <- binary(length: 16),
          tx_bytes <- binary(length: 16),
          table_schema <- ident_gen(),
          table_name <- ident_gen(),
          pk_value <- json_scalar_gen(),
          captured_at_usec <- integer(1_600_000_000_000_000..1_900_000_000_000_000)
        ) do
      %{
        op: op,
        mode: mode,
        keys: keys,
        fields: fields,
        field_names: field_names,
        extra_after: extra_after,
        id: Ecto.UUID.load!(id_bytes),
        transaction_id: Ecto.UUID.load!(tx_bytes),
        table_schema: table_schema,
        table_name: table_name,
        table_pk: %{"id" => pk_value},
        captured_at: DateTime.from_unix!(captured_at_usec, :microsecond)
      }
    end
  end

  @doc """
  Builds a real `%Threadline.Capture.AuditChange{}` from a fact drawn by
  `fact_gen/0`. The only logic here is "render these facts as a struct" —
  no lookups, no `ChangeDiff`-shaped projection.
  """
  def to_audit_change(fact) do
    %AuditChange{
      id: fact.id,
      transaction_id: fact.transaction_id,
      table_schema: fact.table_schema,
      table_name: fact.table_name,
      table_pk: fact.table_pk,
      op: fact.op,
      data_after: build_data_after(fact),
      changed_fields: fact.field_names,
      changed_from: build_changed_from(fact),
      captured_at: fact.captured_at
    }
  end

  defp build_data_after(fact) do
    if delete?(fact.op) do
      nil
    else
      present_entries =
        fact.fields
        |> Enum.filter(&match?({:present, _}, &1.after))
        |> Enum.map(fn f -> {f.name, present_value(f.after)} end)

      extra_entries = Enum.map(fact.extra_after, fn e -> {e.name, e.value} end)

      (present_entries ++ extra_entries)
      |> Enum.map(fn {name, value} -> {render_key(name, fact.keys), value} end)
      |> Map.new()
    end
  end

  defp build_changed_from(%{mode: :none}), do: nil
  defp build_changed_from(%{mode: :sparse_empty}), do: %{}

  defp build_changed_from(%{mode: :sparse_partial} = fact) do
    fact.fields
    |> Enum.filter(&match?({:present, _}, &1.prior))
    |> Enum.map(fn f -> {render_key(f.name, fact.keys), present_value(f.prior)} end)
    |> Map.new()
  end

  defp present_value({:present, v}), do: v

  defp render_key(name, :string), do: name
  defp render_key(name, :atom), do: String.to_atom(name)

  defp delete?(op), do: String.downcase(op) == "delete"

  defp field_entry_gen(name, mode) do
    gen all(after_fact <- after_gen(), prior_fact <- prior_gen_for_mode(mode)) do
      %{name: name, after: after_fact, prior: prior_fact}
    end
  end

  defp extra_entry_gen(name) do
    map(json_scalar_gen(), &%{name: name, value: &1})
  end

  defp after_gen do
    frequency([
      {3, constant(:absent)},
      {7, map(json_scalar_gen(), &{:present, &1})}
    ])
  end

  defp prior_gen_for_mode(:sparse_empty), do: constant(:absent)
  defp prior_gen_for_mode(_mode), do: prior_gen()

  defp prior_gen do
    frequency([
      {1, constant(:absent)},
      {1, constant({:present, nil})},
      {1, map(json_scalar_non_nil_gen(), &{:present, &1})}
    ])
  end

  defp json_scalar_gen do
    one_of([
      constant(nil),
      boolean(),
      integer(),
      float(),
      string(:alphanumeric, max_length: 8)
    ])
  end

  defp json_scalar_non_nil_gen do
    one_of([
      boolean(),
      integer(),
      float(),
      string(:alphanumeric, max_length: 8)
    ])
  end

  defp mask_gen(len), do: list_of(boolean(), length: len)

  defp names_from_mask(pool, mask) do
    pool
    |> Enum.zip(mask)
    |> Enum.filter(fn {_name, selected} -> selected end)
    |> Enum.map(&elem(&1, 0))
  end

  defp ident_gen, do: string(?a..?z, min_length: 3, max_length: 10)
end
