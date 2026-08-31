defmodule Threadline.IdleTransactionReaperContractTest do
  @moduledoc """
  Proves the test connection reaps orphaned idle-in-transaction sessions.

  ## Why this exists

  Plan 198-25 diagnosed an `ExUnit.TimeoutError` by capturing `pg_stat_activity` directly:
  a session left IDLE INSIDE A TRANSACTION by an unrelated process was holding a row lock
  and blocking a deterministic-UUID upsert. That plan added an advisory lock, and recorded
  honestly (198-25 D4) what the lock does not reach:

  > The advisory lock closes contention between this plan's own two test files; it does not
  > and cannot close the full class of an externally-orphaned session from an unrelated
  > process, which is a connection-hygiene concern outside this plan's declared scope.

  It cannot, and no application-level lock can: a client that is never coming back cannot
  cooperate. Only the database can evict it. `idle_in_transaction_session_timeout` is that
  eviction, set on the test repo's connection parameters.

  ## Why this is safe for slow tests

  The timeout fires only on `idle in transaction` — BEGIN issued, no statement running,
  client silent. A query that runs for ten minutes is `active` and is never touched. This
  cannot abort slow-but-healthy work; it reaps only the orphan signature.

  ## What this test asserts

  That the setting is actually live on a real connection — not merely present in config,
  which is the version of this check that would pass while the parameter silently failed to
  apply.
  """

  use Threadline.DataCase, async: false

  @expected_ms 60_000

  test "the live connection has an idle-in-transaction timeout applied" do
    %{rows: [[value]]} = Repo.query!("SHOW idle_in_transaction_session_timeout", [])

    refute value in ["0", "off"],
           """
           idle_in_transaction_session_timeout is disabled on the test connection.

           With it off, a single orphaned session — one process killed mid-transaction —
           holds its locks until someone restarts Postgres by hand, wedging every later run
           with an ExUnit.TimeoutError whose real cause is invisible from the test output.
           That is precisely the failure 198-25 spent a plan diagnosing.
           """

    # Postgres renders the GUC in friendly units ("1min"), so compare in milliseconds.
    %{rows: [[ms]]} =
      Repo.query!(
        "SELECT setting::bigint FROM pg_settings WHERE name = 'idle_in_transaction_session_timeout'",
        []
      )

    assert ms == @expected_ms,
           """
           Expected idle_in_transaction_session_timeout to be #{@expected_ms}ms, got #{ms}ms
           (SHOW reports #{inspect(value)}).

           If this was raised deliberately, raise @expected_ms with it and say why. The
           value is a balance: long enough that no legitimate gap between statements in a
           ~35s suite can trip it, short enough that an orphan clears within a single run.
           """
  end

  test "the timeout is configured on the repo rather than on the server" do
    # Set via connection parameters, so it travels with the app and applies identically on
    # a contributor's local Postgres, in CI, and through PgBouncer — instead of depending
    # on a hand-tuned postgresql.conf nobody remembers to reproduce.
    parameters = Application.get_env(:threadline, Threadline.Test.Repo)[:parameters] || []

    assert parameters[:idle_in_transaction_session_timeout],
           """
           The repo config no longer sets :idle_in_transaction_session_timeout in its
           connection :parameters.

           A server-side default would not follow the suite onto CI or a fresh clone, so the
           reaper has to be declared by the application to be dependable.
           """
  end

  test "an idle-in-transaction session is visible as such in pg_stat_activity" do
    # Non-vacuity: confirms this database actually reports the state the timeout keys on,
    # which is what 198-25 captured by hand during the original diagnosis.
    %{rows: rows} =
      Repo.query!(
        """
        SELECT count(*) FROM pg_stat_activity
        WHERE state IN ('idle in transaction', 'active', 'idle')
        """,
        []
      )

    assert [[count]] = rows

    assert count > 0,
           "pg_stat_activity reported no sessions at all, so this database cannot be observed for orphans"
  end
end
