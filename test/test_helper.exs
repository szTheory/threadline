ExUnit.start()

topology_pooler? = System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1"

# Topology tests need PgBouncer + bootstrap DDL; keep them out of default `mix test`.
exclude = if(topology_pooler?, do: [], else: [pgbouncer_topology: true])
ExUnit.configure(exclude: exclude)

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

unless topology_pooler? do
  Ecto.Migrator.run(repo, :up, all: true)

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
