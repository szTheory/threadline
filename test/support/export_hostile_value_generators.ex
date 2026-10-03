defmodule Threadline.Test.ExportHostileValueGenerators do
  @moduledoc """
  Delivers CSV/JSON-hostile scalars into both raw-string export columns
  (`table_schema`, `table_name`, `op`, the action correlation id) and
  JSON-encoded columns (`data_after`, `changed_from`), on top of
  `Threadline.Test.ChangeFactGenerators`' fact-first row shape.

  ## Biases

  - `hostile_string_gen/0` draws from a fixed list — a comma, a double
    quote, a CRLF pair, a lone LF, a lone CR, a value with a leading
    `=`/`+`/`-`/`@` (the CSV-formula-injection prefixes, D-17's deferred
    sibling concern), an astral codepoint, a combining-mark grapheme, the
    empty string, and the literal `"[REDACTED]"` placeholder — about half
    the time, and a plain printable string the rest.
  - `json_value_gen/0` draws JSON-domain values with string keys only:
    `nil`, booleans, integers (including values outside a 64-bit float's
    exact range), floats (including `1.0e300`, `5.0e-324`, `2.0`, and
    `-0.0`), hostile strings, short lists, and shallow nested maps, bounded
    to a depth of 2 so generation terminates.
  - `export_row_gen/0` starts from `ChangeFactGenerators.fact_gen/0`, then:
    overrides every `data_after`/`changed_from` leaf value (keeping the
    same keys) with a fresh `json_value_gen/0` draw; overrides
    `table_schema`, `table_name`, and `op` with a hostile string about 30%
    of the time each (so a bare CR reaches a raw-string column, not just a
    JSON-encoded one); and attaches a transaction actor (nil, or an
    `ActorRef` built from a generated type/id pair), a transaction source,
    and optional action metadata (`aa_id` / `aa_correlation_id`, the latter
    a hostile string when present).
  """

  use ExUnitProperties

  alias Threadline.Semantics.ActorRef
  alias Threadline.Test.ChangeFactGenerators

  @hostile_strings [
    ",",
    "\"",
    "\r\n",
    "\n",
    "\r",
    "=SUM(A1)",
    "+1",
    "-1",
    "@mention",
    "😀",
    "e" <> <<0x0301::utf8>>,
    "",
    "[REDACTED]"
  ]

  @actor_types ~w(user admin service_account job system anonymous)a

  @doc "A fixed list of CSV/JSON-hostile strings, mixed with plain printable strings."
  def hostile_string_gen do
    frequency([
      {5, member_of(@hostile_strings)},
      {5, string(:printable, max_length: 10)}
    ])
  end

  @doc "A hostile string guaranteed non-empty (for values that must not be blank)."
  def hostile_non_empty_string_gen do
    frequency([
      {5, member_of(@hostile_strings -- [""])},
      {5, string(:printable, min_length: 1, max_length: 10)}
    ])
  end

  @doc """
  A JSON-domain value with string keys only: scalars, short lists, and
  shallow nested maps (depth-limited so generation always terminates).
  """
  def json_value_gen, do: json_value_gen(2)

  defp json_value_gen(depth) do
    scalars = [
      constant(nil),
      boolean(),
      integer(),
      bignum_gen(),
      float_special_gen(),
      hostile_string_gen()
    ]

    if depth <= 0 do
      one_of(scalars)
    else
      one_of(
        scalars ++
          [
            list_of(json_value_gen(depth - 1), max_length: 3),
            json_map_gen(depth - 1)
          ]
      )
    end
  end

  defp json_map_gen(depth) do
    gen all(
          raw_keys <- list_of(map_key_gen(), max_length: 3),
          keys = Enum.uniq(raw_keys),
          values <- fixed_list(List.duplicate(json_value_gen(depth), length(keys)))
        ) do
      keys |> Enum.zip(values) |> Map.new()
    end
  end

  defp map_key_gen, do: string(?a..?z, min_length: 1, max_length: 6)

  defp bignum_gen, do: map(integer(1..999_999), &(&1 * 1_000_000_000_000_000))

  defp float_special_gen do
    frequency([
      {1, member_of([1.0e300, 5.0e-324, 2.0, -0.0])},
      {3, float()}
    ])
  end

  @doc """
  Builds `{fact, audit_change, row}` from a fact-first draw: `fact` is the
  `ChangeFactGenerators.fact_gen/0` draw (op/mode/keys shape intact for
  callers that need it); `audit_change` is the `%AuditChange{}` built from
  it with hostile overrides applied; `row` is the plain export-row map
  `Threadline.Export.format_changes_iodata/3` and friends consume (the
  `AuditChange` fields plus `tx_occurred_at`, `tx_actor_ref`, `tx_source`,
  `aa_id`, `aa_correlation_id`).
  """
  def export_row_gen do
    gen all(
          fact <- ChangeFactGenerators.fact_gen(),
          base_change = ChangeFactGenerators.to_audit_change(fact),
          table_schema <- maybe_hostile(fact.table_schema),
          table_name <- maybe_hostile(fact.table_name),
          op <- maybe_hostile(fact.op),
          data_after <- overridden_map_gen(base_change.data_after),
          changed_from <- overridden_map_gen(base_change.changed_from),
          tx_usec <- tx_occurred_at_usec_gen(),
          tx_source <- one_of([constant(nil), hostile_string_gen()]),
          tx_actor_ref <- actor_ref_gen(),
          has_action <- boolean(),
          aa_id_bytes <- binary(length: 16),
          aa_correlation_id <- one_of([constant(nil), hostile_string_gen()])
        ) do
      audit_change = %{
        base_change
        | table_schema: table_schema,
          table_name: table_name,
          op: op,
          data_after: data_after,
          changed_from: changed_from
      }

      row = %{
        id: audit_change.id,
        transaction_id: audit_change.transaction_id,
        table_schema: audit_change.table_schema,
        table_name: audit_change.table_name,
        op: audit_change.op,
        captured_at: audit_change.captured_at,
        table_pk: audit_change.table_pk,
        data_after: audit_change.data_after,
        changed_fields: audit_change.changed_fields,
        changed_from: audit_change.changed_from,
        tx_occurred_at: DateTime.from_unix!(tx_usec, :microsecond),
        tx_actor_ref: tx_actor_ref,
        tx_source: tx_source,
        aa_id: if(has_action, do: Ecto.UUID.load!(aa_id_bytes), else: nil),
        aa_correlation_id: if(has_action, do: aa_correlation_id, else: nil)
      }

      {fact, audit_change, row}
    end
  end

  defp maybe_hostile(plain_value) do
    frequency([
      {7, constant(plain_value)},
      {3, hostile_string_gen()}
    ])
  end

  # Keeps the original map's shape (nil stays nil; `%{}` stays `%{}`; a
  # partial map keeps its keys) but redraws every leaf value from
  # `json_value_gen/0`, so a bare CR or a nested map can land in a JSON
  # column without changing which columns are "none" vs "sparse" (D-19).
  defp overridden_map_gen(nil), do: constant(nil)

  defp overridden_map_gen(map) when is_map(map) do
    keys = Map.keys(map)

    gen all(values <- fixed_list(List.duplicate(json_value_gen(), length(keys)))) do
      keys |> Enum.zip(values) |> Map.new()
    end
  end

  defp tx_occurred_at_usec_gen do
    frequency([
      {7, integer(1_600_000_000_000_000..1_900_000_000_000_000)},
      {3, map(integer(1_600_000_000..1_900_000_000), &(&1 * 1_000_000))}
    ])
  end

  defp actor_ref_gen do
    one_of([constant(nil), built_actor_ref_gen()])
  end

  defp built_actor_ref_gen do
    gen all(
          type <- member_of(@actor_types),
          id <- actor_id_gen(type)
        ) do
      case ActorRef.new(type, id) do
        {:ok, ref} -> ref
        {:error, _reason} -> %ActorRef{type: :anonymous, id: nil}
      end
    end
  end

  defp actor_id_gen(:anonymous), do: constant(nil)
  defp actor_id_gen(_type), do: hostile_non_empty_string_gen()
end
