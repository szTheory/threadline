defmodule Threadline.ChangeDiff do
  @moduledoc """
  Pure projection of a single captured row change into deterministic, JSON-friendly maps.

  ## Authority

  `from_audit_change/2` is a **pass-through** of persisted `audit_changes` columns only.
  It does not query the database, re-apply `Threadline.Capture.RedactionPolicy`, or invent
  values that capture did not store. Low-information rows (masked columns, sparse
  `changed_from`) are expected and honest.

  Relationship to **`Threadline.Export`**: the `:export_compat` format mirrors the
  **base** string-key map produced by export's internal `change_map/1` (`"op"`,
  `"data_after"`, `"changed_fields"`, `"changed_from"`, identifiers). Phase 31
  **omits** nested `"transaction"` and `"action"` objects; full export rows may still
  include those when preloaded. Use export for CSV/NDJSON documents; use this module
  when you need **`field_changes`** or the same triple without join metadata.

  ## `schema_version`

  The primary wire map includes `"schema_version" => 1`. Future additive fields may
  bump this integer; consumers should treat unknown keys as forward-compatible.

  ## INSERT / UPDATE / DELETE matrix

  | Op | `data_after` | `changed_fields` / `changed_from` | Default `field_changes` |
  | -- | ------------ | ----------------------------------- | ------------------------ |
  | INSERT | row snapshot | N/A for delta semantics | `[]` (row snapshot is authoritative via `"data_after"`) |
  | UPDATE | row after image | capture-driven delta | One entry per name in `changed_fields` (only), sorted by `"name"` |
  | DELETE | `nil` | N/A | `[]` — no synthetic per-column removals without a stored pre-image |

  ## `before_values` and per-field prior epistemics

  - **`"none"`** — `changed_from` is `nil`: integrator did not store before-values.
    UPDATE field entries **omit** `"before"` / `"prior"` keys entirely (only `"after"`).
  - **`"sparse"`** — `changed_from` is a map (including `%{}`): prior values may be
    incomplete. If a column in `changed_fields` has **no** key in `changed_from`, the
    field object includes **`"prior_state" => "omitted"`** instead of inventing a scalar.
    When the key exists, **`"before"`** reflects JSON truth (including JSON `null`).

  ## `except_columns` and masking

  UPDATE projection iterates **only** `changed_fields` (nil-safe), not
  `Map.keys(data_after)`, so columns present in `data_after` but excluded from capture's
  delta lists do not appear as false positives.

  Values in `data_after` / `changed_from` pass through unchanged—including stable
  placeholders such as `:mask` where capture stored them (same class of values as
  export JSON).

  ## Options

  - `:format` — set to `:export_compat` for the export-aligned flat map (see `from_audit_change/2` `@doc`).
  - `:expand_insert_fields` — default `false`; when `true` on INSERT, derives
    `"kind" => "set"` field rows from keys in `data_after` only (presentation-only; not
    per-field capture facts).
  """

  alias Threadline.Capture.AuditChange

  @schema_version 1

  @doc """
  Builds a deterministic map for `audit_change`.

  ## Primary format (default)

  String keys throughout, including `"schema_version"`, `"before_values"` (`"none"` or
  `"sparse"`), `"field_changes"` (lexicographically sorted by `"name"`), and core row
  identifiers compatible with integrator expectations (`"op"`, `"id"`, `"transaction_id"`,
  `"table_schema"`, `"table_name"`, `"table_pk"`, `"captured_at"` as ISO-8601 UTC,
  `"data_after"`).

  ## `:export_compat`

  When `opts` contains `format: :export_compat`, returns a **single flat** string-key map
  aligned with **`Threadline.Export`** `change_map/1` **base** fields: `"id"`,
  `"transaction_id"`, `"table_schema"`, `"table_name"`, `"op"`, `"captured_at"`,
  `"table_pk"`, `"data_after"`, `"changed_fields"`, `"changed_from"`. IDs are coerced
  with `to_string/1`; `table_pk` defaults to `%{}`, `changed_fields` to `[]`,
  `changed_from` to `%{}` when nil. Nested `"transaction"` and `"action"` are **not**
  included in Phase 31 unless a later phase adds optional preload parameters.
  """
  @spec from_audit_change(AuditChange.t(), keyword()) :: map()
  def from_audit_change(%AuditChange{} = ch, opts \\ []) do
    if Keyword.get(opts, :format) == :export_compat do
      export_compat_map(ch)
    else
      primary_map(ch, opts)
    end
  end

  defp export_compat_map(%AuditChange{} = ch) do
    %{
      "id" => ch.id |> to_string(),
      "transaction_id" => ch.transaction_id |> to_string(),
      "table_schema" => ch.table_schema,
      "table_name" => ch.table_name,
      "op" => ch.op,
      "captured_at" => datetime_iso(ch.captured_at),
      "table_pk" => ch.table_pk || %{},
      "data_after" => ch.data_after,
      "changed_fields" => ch.changed_fields || [],
      "changed_from" => ch.changed_from || %{}
    }
  end

  defp datetime_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp datetime_iso(nil), do: nil

  defp primary_map(%AuditChange{} = ch, opts) do
    op = ch.op

    unless op in ["INSERT", "UPDATE", "DELETE"] do
      raise ArgumentError, "unsupported op: #{inspect(op)}"
    end

    base = %{
      "schema_version" => @schema_version,
      "before_values" => before_values_signal(ch.changed_from),
      "op" => op,
      "id" => ch.id |> to_string(),
      "transaction_id" => ch.transaction_id |> to_string(),
      "table_schema" => ch.table_schema,
      "table_name" => ch.table_name,
      "table_pk" => ch.table_pk || %{},
      "captured_at" => datetime_iso(ch.captured_at),
      "data_after" => ch.data_after
    }

    case op do
      "INSERT" ->
        Map.put(base, "field_changes", insert_field_changes(ch, opts))

      "UPDATE" ->
        Map.put(base, "field_changes", update_field_changes(ch))

      "DELETE" ->
        Map.put(base, "field_changes", [])
    end
  end

  defp before_values_signal(nil), do: "none"
  defp before_values_signal(%{}), do: "sparse"

  defp insert_field_changes(%AuditChange{} = ch, opts) do
    if Keyword.get(opts, :expand_insert_fields, false) do
      da = ch.data_after || %{}

      da
      |> Map.keys()
      |> Enum.map(&normalize_map_key/1)
      |> Enum.uniq()
      |> Enum.sort(:asc)
      |> Enum.map(fn name ->
        %{
          "name" => name,
          "after" => map_get(da, name),
          "kind" => "set"
        }
      end)
    else
      []
    end
  end

  defp update_field_changes(%AuditChange{} = ch) do
    fields = ch.changed_fields || []
    da = ch.data_after || %{}
    cf = ch.changed_from
    before_values = before_values_signal(cf)

    fields
    |> Enum.map(&to_string/1)
    |> Enum.sort(:asc)
    |> Enum.map(fn name ->
      build_update_field(name, da, cf, before_values)
    end)
  end

  defp build_update_field(name, da, cf, before_values) do
    base = %{
      "name" => name,
      "after" => map_get(da, name)
    }

    cond do
      before_values == "none" ->
        base

      is_map(cf) ->
        if map_has_field?(cf, name) do
          Map.put(base, "before", map_get(cf, name))
        else
          Map.put(base, "prior_state", "omitted")
        end

      true ->
        base
    end
  end

  defp map_has_field?(m, name) when is_binary(name) and is_map(m) do
    Map.has_key?(m, name) or atom_key_has?(m, name)
  end

  defp atom_key_has?(m, name) when is_binary(name) do
    atom = String.to_existing_atom(name)
    Map.has_key?(m, atom)
  rescue
    ArgumentError -> false
  end

  defp map_get(m, key) when is_map(m) and is_binary(key) do
    case Map.fetch(m, key) do
      {:ok, v} ->
        v

      :error ->
        try do
          Map.get(m, String.to_existing_atom(key))
        rescue
          ArgumentError -> nil
        end
    end
  end

  defp normalize_map_key(k) when is_binary(k), do: k
  defp normalize_map_key(k) when is_atom(k), do: Atom.to_string(k)
end
