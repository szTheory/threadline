defmodule Threadline.Test.LeakOracle do
  @moduledoc """
  PROP-04 (D-10): the shared negative/positive/structural oracle shared by
  `redaction_leak_property_test.exs`.

  `refute_canaries!/3` and `assert_markers!/3` operate on a `surfaces` list —
  `[{name, bytes}]` — built by the caller from whatever this iteration's
  surfaces are (raw stored rows, `ChangeDiff` output, CSV/JSON/NDJSON export
  output). This shape is deliberately open-ended (D-11): phase 228 appends
  `"telemetry:<event>"` surfaces to the same list; this module attaches no
  telemetry handler.

  `stored_surfaces/2` reads `audit_changes` and `audit_transactions` raw via
  `row_to_json`, bypassing the Ecto schema, so a column added later is
  covered automatically without touching this module.

  `assert_structure!/3` encodes the D-10.3 structural rules: the excluded key
  is absent from `data_after`/`changed_from`/`changed_fields`; masked keys
  equal the placeholder exactly, even when the plaintext was NULL or `""`;
  `table_pk` equals `%{"id" => id}`. The masked column's *name* appearing in
  `changed_fields` is accepted, not a leak: change detection compares raw
  `NEW`/`OLD` values before redaction (`trigger_sql.ex` ~L597), so
  `changed_fields` legitimately shows that a masked value changed.
  """

  alias Threadline.StorageSchema
  alias Threadline.Test.Repo

  @placeholder "[REDACTED]"

  @doc """
  Raw `audit_changes` and `audit_transactions` rows for one `table_name` +
  `id`, read via `row_to_json`, storage-qualified. Returned as two
  `{name, bytes}` surfaces.
  """
  def stored_surfaces(table_name, id) do
    audit_changes = StorageSchema.table("audit_changes")
    audit_transactions = StorageSchema.table("audit_transactions")

    %{rows: change_rows} =
      Repo.query!(
        "SELECT row_to_json(c)::text FROM #{audit_changes} c " <>
          "WHERE c.table_name = $1 AND c.table_pk->>'id' = $2 ORDER BY c.captured_at, c.id",
        [table_name, id]
      )

    change_jsons = Enum.map(change_rows, fn [json] -> json end)

    txn_ids =
      case Repo.query!(
             "SELECT DISTINCT transaction_id::text FROM #{audit_changes} " <>
               "WHERE table_name = $1 AND table_pk->>'id' = $2",
             [table_name, id]
           ) do
        %{rows: rows} -> Enum.map(rows, fn [tid] -> tid end)
      end

    txn_jsons =
      case txn_ids do
        [] ->
          []

        _ ->
          %{rows: rows} =
            Repo.query!(
              "SELECT row_to_json(t)::text FROM #{audit_transactions} t WHERE t.id::text = ANY($1::text[])",
              [txn_ids]
            )

          Enum.map(rows, fn [json] -> json end)
      end

    [
      {"stored:audit_changes", Enum.join(change_jsons, "\n")},
      {"stored:audit_transactions", Enum.join(txn_jsons, "\n")}
    ]
  end

  @doc """
  Decoded `audit_changes` rows for one `table_name` + `id`, via Ecto, used by
  `assert_structure!/3` and to build diff/export surfaces.
  """
  def stored_changes(table_name, id, repo_opts) do
    import Ecto.Query

    Threadline.Capture.AuditChange
    |> where([c], c.table_name == ^table_name)
    |> where([c], fragment("?->>'id' = ?", c.table_pk, ^id))
    |> order_by([c], asc: c.captured_at, asc: c.id)
    |> Repo.all(repo_opts)
  end

  @doc """
  Fails when any `canary` appears as a substring of any surface's bytes.

  `canaries` is a list of bare canary strings (see
  `RedactionLeakGenerators.canaries/1`); every surface is scanned for every
  canary, not just the one(s) planted at the step that produced it, because a
  leak at an earlier step could resurface on a later surface. On a hit,
  `flunk/1` names the surface, the canary, the op plan, and an 80-byte window
  around the match.
  """
  def refute_canaries!(surfaces, canaries, context \\ %{}) do
    for {name, bytes} <- surfaces, canary <- canaries, canary != nil do
      case find_window(bytes, canary) do
        nil ->
          :ok

        window ->
          ExUnit.Assertions.flunk("""
          LeakOracle: redaction leak detected.

          surface: #{name}
          canary:  #{inspect(canary)}
          window:  #{inspect(window)}
          op plan: #{inspect(Map.get(context, :plan))}
          """)
      end
    end

    :ok
  end

  @doc """
  Fails when any `marker` is absent from any surface's bytes. This is the
  positive control (D-10.4): a missing trigger produces zero stored rows (so
  `refute_canaries!/3` passes vacuously); the marker must reach every data
  surface, or the check proves nothing.
  """
  def assert_markers!(surfaces, markers, context \\ %{}) do
    for {name, bytes} <- surfaces, marker <- markers, marker != nil do
      unless String.contains?(bytes, marker) do
        ExUnit.Assertions.flunk("""
        LeakOracle: expected positive-control marker missing.

        surface: #{name}
        marker:  #{inspect(marker)}
        op plan: #{inspect(Map.get(context, :plan))}
        """)
      end
    end

    :ok
  end

  @doc """
  Structural rules (D-10.3) over decoded `AuditChange` structs for one row:

    * `secret_excluded` is absent from `data_after`, `changed_from`, and
      `changed_fields`;
    * `secret_masked` / `profile_masked`, wherever present in `data_after` or
      `changed_from`, equal the placeholder exactly (including when the
      plaintext was `nil` or `""` — a mask hides NULL-ness);
    * `table_pk == %{"id" => id}`.
  """
  def assert_structure!(changes, id, context \\ %{}) do
    for change <- changes do
      assert_no_excluded!(change, context)
      assert_masked!(change, context)

      unless change.table_pk == %{"id" => id} do
        ExUnit.Assertions.flunk("""
        LeakOracle: table_pk mismatch.

        expected: #{inspect(%{"id" => id})}
        actual:   #{inspect(change.table_pk)}
        op plan:  #{inspect(Map.get(context, :plan))}
        """)
      end
    end

    :ok
  end

  defp assert_no_excluded!(change, context) do
    data_after = change.data_after || %{}
    changed_from = change.changed_from || %{}
    changed_fields = change.changed_fields || []

    if Map.has_key?(data_after, "secret_excluded") or
         Map.has_key?(changed_from, "secret_excluded") or
         "secret_excluded" in changed_fields do
      ExUnit.Assertions.flunk("""
      LeakOracle: excluded column leaked structurally.

      change:  #{inspect(change)}
      op plan: #{inspect(Map.get(context, :plan))}
      """)
    end
  end

  defp assert_masked!(change, context) do
    data_after = change.data_after || %{}
    changed_from = change.changed_from || %{}

    for key <- ["secret_masked", "profile_masked"] do
      if Map.has_key?(data_after, key) and Map.get(data_after, key) != @placeholder do
        flunk_mask(key, "data_after", Map.get(data_after, key), context)
      end

      if Map.has_key?(changed_from, key) and Map.get(changed_from, key) != @placeholder do
        flunk_mask(key, "changed_from", Map.get(changed_from, key), context)
      end
    end
  end

  defp flunk_mask(key, location, value, context) do
    ExUnit.Assertions.flunk("""
    LeakOracle: masked column did not equal the placeholder exactly.

    column:  #{key}
    in:      #{location}
    value:   #{inspect(value)}
    op plan: #{inspect(Map.get(context, :plan))}
    """)
  end

  defp find_window(bytes, needle) when is_binary(bytes) and is_binary(needle) do
    case :binary.match(bytes, needle) do
      {pos, len} ->
        start = max(0, pos - 40)
        stop = min(byte_size(bytes), pos + len + 40)
        binary_part(bytes, start, stop - start)

      :nomatch ->
        nil
    end
  end

  defp find_window(_bytes, _needle), do: nil
end
