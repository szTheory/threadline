defmodule Threadline.Test.DbProperty do
  @moduledoc """
  Per-iteration isolation for DB-backed property tests (D-01, D-02).

  This module holds **plain functions only**. It never defines `__using__`
  or `setup` — doing so would grow a second test harness next to
  `Threadline.DataCase`, which D-02 forbids. Every caller does:

      use Threadline.DataCase, async: false
      use ExUnitProperties
      import Threadline.Test.DbProperty

  ## Why per-iteration cleanup, and no Sandbox

  DB-backed properties in this phase run real DDL/DML against a live,
  shared, non-sandboxed Postgres connection. Transaction-plus-rollback
  per iteration is rejected: PostgreSQL triggers fire on a *committed*
  transaction, and other connections (readback queries, a second `Repo`
  checkout) cannot see rows still inside an open transaction. A Sandbox
  checkout would hide capture entirely.

  Retention's dry-run/real-purge oracle and export's filterless query act
  on the **whole table**, with no row-key filter. A single `on_exit`
  cleanup, run once per test rather than once per iteration, would leave
  rows from a prior iteration (including a failed or shrinking one)
  visible to the next iteration's whole-table oracle and silently corrupt
  it. So every iteration:

    1. creates its own unique key *inside* the property body (never as a
       generated StreamData value — a generated key could be shrunk, or
       appear differently across reruns, breaking seed-replay comparison);
    2. does its real work;
    3. deletes only its own rows in `after`, in FK order: host row first
       (so the delete itself fires the trigger and is captured, which the
       next step then removes), then this iteration's `audit_changes`,
       then only the `audit_transactions` that are now empty.

  Cleanup never raises: a failing cleanup step is rescued and warned via
  `IO.warn/1`, so a cleanup bug can never mask the real assertion failure
  from the property body. No assertion message produced by this module
  (or expected to be produced by a caller) includes the iteration key —
  seed replay compares counterexample text, and a per-run key would make
  the same seed print different text on every run.

  Every raw SQL statement here reads the storage-qualified audit tables
  through `Threadline.StorageSchema.table/2`, never a bare table name.
  Local databases have carried a stale `public.threadline_capture_changes()`
  function that masks an unqualified read that then fails only on CI.
  """

  alias Threadline.StorageSchema
  alias Threadline.Test.Repo

  @host_table_pattern ~r/\A[a-z_][a-z0-9_]*\z/

  @doc """
  Returns a fresh, monotonically increasing integer for scoping one
  property iteration's rows. Always call this *inside* the property body,
  never bind it to a generated value.
  """
  def iteration_key, do: System.unique_integer([:positive, :monotonic])

  @doc """
  Runs `body.(n)` for a fresh iteration key `n`, then always runs
  `cleanup.(n)` in `after` — on a passing iteration, a failing assertion,
  and every shrink rerun. `cleanup` is rescued: any exception, throw, or
  exit it raises is caught and reported with `IO.warn/1` naming the
  iteration key and the cleanup failure, and the body's own result (value
  or exception) is always what propagates.

  Both `cleanup` and `body` are arity-1 functions receiving `n`.
  """
  def with_iteration(cleanup, body) when is_function(cleanup, 1) and is_function(body, 1) do
    n = iteration_key()

    try do
      body.(n)
    after
      safely(cleanup, n)
    end
  end

  defp safely(cleanup, n) do
    cleanup.(n)
  rescue
    exception ->
      IO.warn(
        "Threadline.Test.DbProperty cleanup failed for iteration #{n}: " <>
          Exception.format(:error, exception, __STACKTRACE__)
      )
  catch
    kind, reason ->
      IO.warn("Threadline.Test.DbProperty cleanup #{kind} for iteration #{n}: #{inspect(reason)}")
  end

  @doc """
  Deletes one iteration's rows from a fixture host table, in FK order:

    1. the host rows themselves, matched by `id::text = ANY($1)` (this
       fires the capture trigger, so the delete is itself captured — step
       3 removes that capture too);
    2. the `audit_changes` rows this iteration produced against
       `host_table`, matched by `table_pk->>'id' = ANY($1)`;
    3. only the `audit_transactions` that are now empty (no remaining
       `audit_changes` reference them).

  `pk_values` is a list of the text form of each id, so uuid and bigint
  primary keys share one code path. `host_table` is validated against
  `~r/\\A[a-z_][a-z0-9_]*\\z/` before interpolation and is expected to be an
  internal fixture name, never host input; `pk_values` are always passed
  as query parameters.
  """
  def delete_iteration!(host_table, pk_values) when is_list(pk_values) do
    unless Regex.match?(@host_table_pattern, host_table) do
      raise ArgumentError,
            "Threadline.Test.DbProperty.delete_iteration!/2 host_table must match " <>
              "#{@host_table_pattern.source}, got: #{inspect(host_table)}"
    end

    audit_changes = StorageSchema.table("audit_changes")
    audit_transactions = StorageSchema.table("audit_transactions")

    Repo.query!("DELETE FROM #{host_table} WHERE id::text = ANY($1::text[])", [pk_values])

    %{rows: txn_rows} =
      Repo.query!(
        "SELECT DISTINCT transaction_id::text FROM #{audit_changes} " <>
          "WHERE table_name = $1 AND table_pk->>'id' = ANY($2::text[])",
        [host_table, pk_values]
      )

    Repo.query!(
      "DELETE FROM #{audit_changes} WHERE table_name = $1 AND table_pk->>'id' = ANY($2::text[])",
      [host_table, pk_values]
    )

    txn_ids = Enum.map(txn_rows, fn [id] -> id end)

    Repo.query!(
      "DELETE FROM #{audit_transactions} t WHERE t.id::text = ANY($1::text[]) " <>
        "AND NOT EXISTS (SELECT 1 FROM #{audit_changes} c WHERE c.transaction_id = t.id)",
      [txn_ids]
    )

    :ok
  end

  @doc """
  Deletes the given storage-qualified `audit_transactions` ids. The `ON
  DELETE CASCADE` on `audit_changes.transaction_id` removes their changes.
  Used by the retention property, whose fixture rows are inserted directly
  into both audit tables rather than produced by a host-table trigger.
  """
  def delete_transactions!(ids) when is_list(ids) do
    audit_transactions = StorageSchema.table("audit_transactions")
    Repo.query!("DELETE FROM #{audit_transactions} WHERE id::text = ANY($1::text[])", [ids])
    :ok
  end

  @doc """
  Flunks with the exact message `"foreign rows present; global purge oracle
  unsound"` when either storage-qualified audit table holds any row. This
  is the PROP-07 precondition: retention's dry-run and real-purge oracles
  act on the whole table, so a leftover row from a prior iteration (or an
  unrelated test) would make the oracle wrong.
  """
  def assert_audit_tables_empty! do
    audit_changes = StorageSchema.table("audit_changes")
    audit_transactions = StorageSchema.table("audit_transactions")

    %{rows: [[changes_count]]} = Repo.query!("SELECT count(*) FROM #{audit_changes}")
    %{rows: [[transactions_count]]} = Repo.query!("SELECT count(*) FROM #{audit_transactions}")

    if changes_count > 0 or transactions_count > 0 do
      ExUnit.Assertions.flunk("foreign rows present; global purge oracle unsound")
    end

    :ok
  end

  @doc """
  Returns a deterministic uuid whose byte ordering is `rank`, then `n`:
  `Ecto.UUID.load!(<<rank::32, n::96>>)`. PostgreSQL compares uuids byte by
  byte, so two values built this way always order by `rank`. Used only by
  the D-17 tie example test, where the winning side of a `captured_at` tie
  must come from generated data rather than from insertion order.
  """
  def ordered_id(rank, n) when is_integer(rank) and is_integer(n) do
    Ecto.UUID.load!(<<rank::32, n::96>>)
  end
end
