ExUnit.start()

topology_pooler? = System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1"

# Topology tests need PgBouncer + bootstrap DDL; keep them out of default `mix test`.
# `:live_dialyzer` needs a restored `.dialyzer` PLT and runs only in the `verify-dialyzer`
# CI job via `mix verify.dialyzer_slice`.
exclude =
  if(topology_pooler?,
    do: [live_dialyzer: true],
    else: [pgbouncer_topology: true, live_dialyzer: true]
  )

ExUnit.configure(exclude: exclude)
# Contract tests read the default excludes from this key because Mix CLI filters (a
# `file:LINE` path, `--only`) re-configure ExUnit's exclude list after this helper runs.
Application.put_env(:threadline, :default_test_excludes, exclude)

repo = Threadline.Test.Repo
config = repo.config()

unless topology_pooler? do
  case Ecto.Adapters.Postgres.storage_up(config) do
    :ok ->
      :ok

    {:error, :already_up} ->
      :ok

    {:error, reason} ->
      db = config[:database]
      host = config[:hostname] || "localhost"

      raise """
      Threadline tests: could not ensure PostgreSQL database #{inspect(db)} exists.

      #{if is_binary(reason), do: reason, else: inspect(reason)}

      Hint: start PostgreSQL (e.g. `docker compose up -d` from the repo root) and ensure \
      DB_HOST (default #{inspect(host)}), username, and password match config/test.exs.
      """
  end
end

{:ok, _} = repo.start_link()

# Any identifier PostgreSQL truncates (NOTICE 42622) fails the suite. Attached
# before migrations so their DDL is observed too.
Threadline.Test.NoticeGuard.attach!()
ExUnit.after_suite(&Threadline.Test.NoticeGuard.verify!/1)

unless topology_pooler? do
  # The truncation guard only sees NOTICE messages PostgreSQL sends back. At
  # client_min_messages = warning or above it sends none, and the guard would
  # pass while seeing nothing.
  %{rows: [[client_min_messages]]} =
    Ecto.Adapters.SQL.query!(repo, "SHOW client_min_messages", [])

  if client_min_messages != "notice" do
    raise """
    Threadline tests: client_min_messages is #{inspect(client_min_messages)}, expected "notice".

    At warning or above PostgreSQL returns no NOTICE messages, so the identifier-truncation
    guard (SQLSTATE 42622) would see nothing and every truncation would pass silently.

    Fix: reset client_min_messages to notice for the test database or role
    (for example `ALTER DATABASE <test db> RESET client_min_messages`).
    """
  end

  Ecto.Migrator.run(repo, :up, all: true)

  # The :threadline application booted before this helper started the repo and
  # migrated. Its export cleanup task reconciles as soon as the repo is up, so on
  # a freshly created database (every CI partition database, threadline_test<N>)
  # it can query threadline_export_jobs before the migration above created it,
  # crash past the supervisor's restart limit, and take the export task
  # supervisor down with it. Restart the application so every child boots
  # against the migrated schema.
  :ok = Application.stop(:threadline)
  {:ok, _} = Application.ensure_all_started(:threadline)

  # Stale-database tripwire (Phase 198, D-03). A test database created before
  # priv/repo/migrations/20260607000000_threadline_storage_schema_default.exs still
  # carries the audit tables in `public`, and every capture test then fails with an
  # opaque `relation "audit_transactions" does not exist` — ~81 misleading failures
  # from ONE environmental cause. Fail once, loudly, naming the cause and the fix.
  #
  # Scoped to `table_schema = 'public'` on purpose: test/support/storage_schema_case.ex
  # `prepare_dual_storage!/1` legitimately creates an `audit` schema, and a
  # schema-agnostic table-name search would false-positive on it.
  #
  # This lives ONLY here, never in lib/ — a host application may legitimately own
  # its own `public.audit_*` tables.
  stale_public_audit_tables =
    Ecto.Adapters.SQL.query!(
      repo,
      """
      select table_name from information_schema.tables
      where table_schema = 'public'
        and table_name in ('audit_transactions', 'audit_changes', 'audit_actions')
      order by table_name
      """,
      []
    ).rows
    |> List.flatten()

  if stale_public_audit_tables != [] do
    raise """
    Threadline tests: this test database predates the storage-schema migration
    (priv/repo/migrations/20260607000000_threadline_storage_schema_default.exs).

    Audit tables are still in the `public` schema: #{inspect(stale_public_audit_tables)}

    Left alone this produces dozens of misleading `relation "audit_transactions" \
    does not exist` failures that look like product bugs but are one stale database.

    Fix: `mix test.reset` (drops the test database; the next run recreates and migrates it).
    """
  end
end
