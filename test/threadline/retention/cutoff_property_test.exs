defmodule Threadline.Retention.CutoffPropertyTest do
  @moduledoc """
  PROP-07: `Threadline.Retention.purge/1` selects exactly the rows strictly
  older than the cutoff, `dry_run: true` and the real purge agree, and
  every row at or after the cutoff survives byte-for-byte (ROADMAP SC3).

  Expected purge and survivor sets come only from generated facts
  (`DateTime.compare(captured_at, cutoff) == :lt`), never from `lib/`
  code (D-18) — no eligible-rows predicate is extracted or shared between
  the dry run and the real delete, so a one-site `<`/`<=` mutation on
  either side alone is still caught (226 D-01's shared-predicate trap).

  Each iteration inserts its own transactions/changes directly via
  `insert_all` (the retention fixture has no host table / trigger of its
  own), snapshots both storage-qualified tables with a whole-row `::text`
  cast (covers columns added later), runs a dry run then a real purge of
  the same fixture, and asserts every surviving row is byte-identical.

  `@max_runs PropertyRuns.db(20)` (D-05). Measured at ~111ms unscaled (20
  runs, ~5.5ms/iteration) and ~265ms at `THREADLINE_PROPERTY_SCALE=5` (60
  runs, ~4.4ms/iteration) — both well under the 2s/9s thresholds that
  would call for dropping below `db(20)`. Default `max_shrinking_steps`
  (no cap needed: worst-case shrink cost stays bounded by ~100 x one
  iteration's measured ms, far under the 100ms-per-iteration line that
  would call for capping at 50). No `max_run_time`.
  """

  use Threadline.DataCase, async: false
  use ExUnitProperties

  import Ecto.Query
  import Threadline.Test.DbProperty
  import Threadline.Test.RetentionCutoffGenerators

  alias Threadline.Governance.RetentionRun
  alias Threadline.Retention
  alias Threadline.StorageSchema
  alias Threadline.Test.PropertyRuns

  @max_runs PropertyRuns.db(20)

  setup do
    previous = Application.fetch_env(:threadline, :retention)

    on_exit(fn ->
      case previous do
        {:ok, value} -> Application.put_env(:threadline, :retention, value)
        :error -> Application.delete_env(:threadline, :retention)
      end
    end)

    :ok
  end

  property "purge selects exactly the rows strictly older than the cutoff, dry run and real purge agree, and survivors are byte-identical" do
    check all(fixture <- fixture_gen(), max_runs: @max_runs) do
      with_iteration(
        fn n -> cleanup_iteration(n, fixture) end,
        fn n -> run_fixture(n, fixture) end
      )
    end
  end

  # ── Iteration body ──────────────────────────────────────────────────

  defp run_fixture(n, fixture) do
    assert_audit_tables_empty!()

    Application.put_env(:threadline, :retention,
      enabled: true,
      keep_days: 1,
      delete_empty_transactions: fixture.delete_empty?
    )

    rows = build_rows(n, fixture)
    insert_rows!(rows)
    assert_round_trip!(rows)

    changes_snapshot = snapshot_table("audit_changes")
    txns_snapshot = snapshot_table("audit_transactions")

    expected_purged_ids = expected_purged_ids(fixture, rows)
    expected_survivor_ids = expected_survivor_ids(fixture, rows)
    expected_orphaned_ids = expected_orphaned_ids(fixture, rows)

    dry = Retention.purge(repo: Repo, cutoff: fixture.cutoff, dry_run: true)

    assert dry.deleted_changes == length(expected_purged_ids),
           "dry run deleted_changes mismatch: expected #{length(expected_purged_ids)}, " <>
             "got #{dry.deleted_changes} (strict < cutoff rule)"

    expected_dry_txns = if fixture.delete_empty?, do: length(expected_orphaned_ids), else: 0

    assert dry.deleted_transactions == expected_dry_txns,
           "dry run deleted_transactions mismatch: expected #{expected_dry_txns}, " <>
             "got #{dry.deleted_transactions} (delete_empty?=#{fixture.delete_empty?})"

    real =
      Retention.purge(
        repo: Repo,
        cutoff: fixture.cutoff,
        batch_size: fixture.batch_size,
        sleep_ms: 0
      )

    remaining_ids = Repo.all(from(c in AuditChange, select: c.id), repo_opts())
    assert_survivors_match!(fixture, rows, remaining_ids)

    remaining_txn_ids = Repo.all(from(t in AuditTransaction, select: t.id), repo_opts())
    assert_orphans_match!(fixture, rows, remaining_txn_ids)

    surviving_txn_ids =
      if fixture.delete_empty? do
        rows |> Enum.map(& &1.txn_id) |> Kernel.--(expected_orphaned_ids)
      else
        Enum.map(rows, & &1.txn_id)
      end

    assert_byte_identical!(changes_snapshot, expected_survivor_ids, "audit_changes")
    assert_byte_identical!(txns_snapshot, surviving_txn_ids, "audit_transactions")

    assert real.deleted_changes == length(expected_purged_ids),
           "real purge deleted_changes mismatch: expected #{length(expected_purged_ids)}, " <>
             "got #{real.deleted_changes}"

    expected_real_txns = if fixture.delete_empty?, do: length(expected_orphaned_ids), else: 0

    assert real.deleted_transactions == expected_real_txns,
           "real purge deleted_transactions mismatch: expected #{expected_real_txns}, " <>
             "got #{real.deleted_transactions} (delete_empty?=#{fixture.delete_empty?})"

    dry_counts = Map.take(dry, [:deleted_changes, :deleted_transactions])
    real_counts = Map.take(real, [:deleted_changes, :deleted_transactions])

    assert real_counts == dry_counts,
           "dry run and real purge disagree: dry=#{inspect(dry_counts)}, " <>
             "real=#{inspect(real_counts)}"

    if real.deleted_changes > 0 or real.deleted_transactions > 0 do
      assert real.batches_run >= 1
    end

    runs = Repo.all(RetentionRun, repo_opts())

    assert length(runs) == 1,
           "expected exactly one RetentionRun to be recorded, got #{length(runs)}"

    [run] = runs
    assert run.status == "completed"

    assert run.deleted_count == real.deleted_changes + real.deleted_transactions,
           "RetentionRun.deleted_count must equal deleted_changes + deleted_transactions"
  end

  defp cleanup_iteration(n, fixture) do
    delete_transactions!(txn_ids_for(n, fixture))
    Repo.delete_all(RetentionRun, repo_opts())
  end

  # ── Fixture construction, built only from generated facts (D-18) ───────

  defp txn_ids_for(n, fixture) do
    fixture.transactions
    |> Enum.with_index(1)
    |> Enum.map(fn {_offsets, t} -> Ecto.UUID.load!(<<n::64, t::32, 0xFFFFFFFF::32>>) end)
  end

  defp build_rows(n, fixture) do
    fixture.transactions
    |> Enum.with_index(1)
    |> Enum.map(fn {offsets, t} ->
      txn_id = Ecto.UUID.load!(<<n::64, t::32, 0xFFFFFFFF::32>>)
      txid = n * 100 + t

      changes =
        offsets
        |> Enum.with_index()
        |> Enum.map(fn {offset_us, c} ->
          change_id = Ecto.UUID.load!(<<n::64, t::32, c::32>>)
          captured_at = DateTime.add(fixture.cutoff, offset_us, :microsecond)

          %{
            id: change_id,
            transaction_id: txn_id,
            table_schema: "public",
            table_name: "retention_prop",
            table_pk: %{"id" => change_id},
            op: Enum.at(["insert", "update", "delete"], rem(c, 3)),
            data_after: %{"t" => t, "c" => c, "offset_us" => offset_us},
            changed_from: %{"t" => t, "c" => c, "offset_us" => offset_us},
            captured_at: captured_at
          }
        end)

      %{txn_id: txn_id, txid: txid, changes: changes}
    end)
  end

  defp insert_rows!(rows) do
    txn_attrs =
      Enum.map(rows, fn %{txn_id: id, txid: txid} ->
        %{id: id, txid: txid, occurred_at: DateTime.utc_now(:microsecond)}
      end)

    Repo.insert_all(AuditTransaction, txn_attrs, repo_opts())

    change_attrs = Enum.flat_map(rows, & &1.changes)

    if change_attrs != [] do
      Repo.insert_all(AuditChange, change_attrs, repo_opts())
    end

    :ok
  end

  defp assert_round_trip!(rows) do
    change_attrs = Enum.flat_map(rows, & &1.changes)
    ids = Enum.map(change_attrs, & &1.id)

    if ids != [] do
      actual =
        AuditChange
        |> where([c], c.id in ^ids)
        |> select([c], {c.id, c.captured_at})
        |> Repo.all(repo_opts())
        |> Map.new()

      for %{id: id, captured_at: expected} <- change_attrs do
        assert Map.fetch!(actual, id) == expected,
               "captured_at round-trip mismatch for id=#{id}: expected #{inspect(expected)}, " <>
                 "got #{inspect(Map.fetch!(actual, id))}"
      end
    end
  end

  # ── Expected sets, from generated facts only (D-18) ─────────────────

  defp survives?(change, fixture), do: DateTime.compare(change.captured_at, fixture.cutoff) != :lt

  defp expected_purged_ids(fixture, rows) do
    for %{changes: changes} <- rows,
        c <- changes,
        not survives?(c, fixture),
        do: c.id
  end

  defp expected_survivor_ids(fixture, rows) do
    for %{changes: changes} <- rows,
        c <- changes,
        survives?(c, fixture),
        do: c.id
  end

  defp expected_orphaned_ids(fixture, rows) do
    for %{txn_id: txn_id, changes: changes} <- rows,
        not Enum.any?(changes, &survives?(&1, fixture)),
        do: txn_id
  end

  # ── Snapshots: whole-row ::text, covers columns added later (D-18) ──

  defp snapshot_table("audit_changes"), do: snapshot(StorageSchema.table("audit_changes"))

  defp snapshot_table("audit_transactions"),
    do: snapshot(StorageSchema.table("audit_transactions"))

  defp snapshot(table) do
    %{rows: rows} = Repo.query!("SELECT id::text, t::text FROM #{table} t")
    Map.new(rows, fn [id, text] -> {id, text} end)
  end

  defp assert_byte_identical!(before_snapshot, surviving_ids, table_name) do
    after_snapshot = snapshot_table(table_name)

    mismatches =
      for id <- surviving_ids,
          Map.get(before_snapshot, id) != Map.get(after_snapshot, id) do
        "id=#{id} table=#{table_name} before=#{inspect(Map.get(before_snapshot, id))} " <>
          "after=#{inspect(Map.get(after_snapshot, id))}"
      end

    assert mismatches == [],
           "survivor content changed or disappeared (byte-identical snapshot):\n" <>
             Enum.join(mismatches, "\n")
  end

  # ── Boundary/adjacency assertions, naming the rule per failing row ──

  defp assert_survivors_match!(fixture, rows, remaining_ids) do
    remaining_set = MapSet.new(remaining_ids)

    mismatches =
      for %{txn_id: txn_id, changes: changes} <- rows,
          c <- changes,
          should_survive? = survives?(c, fixture),
          survived? = MapSet.member?(remaining_set, c.id),
          should_survive? != survived? do
        offset_us = DateTime.diff(c.captured_at, fixture.cutoff, :microsecond)

        rule =
          if should_survive?,
            do:
              "row at cutoff+#{offset_us}us was deleted, but captured_at == cutoff must survive (strict <)",
            else:
              "row at cutoff+#{offset_us}us survived, but captured_at < cutoff must be purged (strict <)"

        "txn=#{txn_id} id=#{c.id} offset_us=#{offset_us} " <>
          "captured_at=#{DateTime.to_iso8601(c.captured_at)} rule=\"#{rule}\""
      end

    assert mismatches == [],
           "retention purge boundary violated:\n" <> Enum.join(mismatches, "\n")
  end

  defp assert_orphans_match!(fixture, rows, remaining_txn_ids) do
    remaining_set = MapSet.new(remaining_txn_ids)

    mismatches =
      for %{txn_id: txn_id, changes: changes} <- rows,
          has_survivor? = Enum.any?(changes, &survives?(&1, fixture)),
          should_survive? = has_survivor? or not fixture.delete_empty?,
          survived? = MapSet.member?(remaining_set, txn_id),
          should_survive? != survived? do
        "txn=#{txn_id} has_survivor=#{has_survivor?} delete_empty?=#{fixture.delete_empty?} " <>
          "expected_keep=#{should_survive?} actual_kept=#{survived?} " <>
          "rule=\"transaction deleted while it still had a surviving change " <>
          "(cascade would destroy survivors)\""
      end

    assert mismatches == [],
           "retention transaction-orphan rule violated:\n" <> Enum.join(mismatches, "\n")
  end
end
