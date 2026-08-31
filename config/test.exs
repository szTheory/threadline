import Config

pgbouncer_topology? = System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1"

repo_base = [
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  username: "postgres",
  password: "postgres",
  database: "threadline_test",
  pool_size: 2
]

# Orphaned-session reaper (Phase 199, closing 198-25 D4).
#
# Plan 198-25 diagnosed an ExUnit.TimeoutError caused by a session left IDLE INSIDE A
# TRANSACTION by an unrelated process, holding a row lock that blocked a
# deterministic-UUID upsert. That plan added an advisory lock, which closes contention
# between its own two test files but — as its own summary recorded — "does not and
# cannot close the full class of an externally-orphaned session from an unrelated
# process." Only the database can reap a client that is no longer coming back.
#
# Postgres kills a session that has held an open transaction while IDLE for this long.
# It does NOT interrupt work in progress: a query that runs for ten minutes is `active`,
# not `idle in transaction`, so this cannot abort a slow-but-healthy test. It fires only
# on the orphan signature — BEGIN issued, client gone.
#
# 60s is deliberately generous: the whole suite finishes in ~35s, so no legitimate gap
# between statements comes close, while an orphan still clears within a single run
# instead of wedging every subsequent one until someone restarts Postgres by hand.
#
# NOT sent through PgBouncer. Transaction-mode PgBouncer rejects any startup parameter
# outside its allowed set with `FATAL 08P01 (protocol_violation) unsupported startup
# parameter`, which fails every connection in the pool — observed on CI run 33355093630
# after this was first added unconditionally. That lane does not need it anyway: session
# lifetime there is PgBouncer's to manage, and its own timeouts cover the orphan case.
reaper_parameters = [idle_in_transaction_session_timeout: "60000"]

# Transaction-mode PgBouncer: avoid named prepared statements (Ecto + Postgrex).
repo_opts =
  if pgbouncer_topology? do
    Keyword.put(repo_base, :prepare, :unnamed)
  else
    Keyword.put(repo_base, :parameters, reaper_parameters)
  end

config :threadline, Threadline.Test.Repo, repo_opts

config :threadline, ecto_repos: [Threadline.Test.Repo]
config :threadline, storage_schema: "threadline"
config :threadline, :storage_adapter, Threadline.Storage.Local
config :threadline, :export_queue_adapter, Threadline.ExportQueue.TaskAdapter
config :threadline, Threadline.ExportQueue.Oban, oban_name: Oban, queue: :threadline_exports

if System.get_env("THREADLINE_VERIFY_COVERAGE_FAILURE_TEST") == "1" do
  config :threadline, :verify_coverage, expected_tables: ["threadline_verify_cov_uncovered"]
else
  config :threadline, :verify_coverage, expected_tables: ["threadline_ci_coverage_canary"]
end

# REDN-01 / REDN-02 — fixture for `mix threadline.gen.triggers` and capture tests.
config :threadline, :trigger_capture,
  tables: %{
    "test_redaction_users" => [
      exclude: ["password"],
      mask: ["email"],
      store_changed_from: true
    ]
  }

# RETN-01 / RETN-02 — explicit window for policy + purge tests (`Threadline.Retention.PolicyTest`,
# `Threadline.Retention.PurgeTest`). Destructive purge stays off unless a test enables it.
config :threadline, :retention,
  enabled: false,
  keep_days: 30,
  delete_empty_transactions: true,
  interval_ms: :timer.hours(24),
  sleep_ms: 0

config :threadline, :exports,
  cleanup_interval_ms: :timer.hours(24),
  stale_running_cutoff_hours: 24,
  retention_ttl_hours: 24 * 7

config :logger, level: :warning
