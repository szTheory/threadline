import Config

System.put_env(
  "CLOAK_KEY",
  Base.encode64(:crypto.hash(:sha256, "threadline_phoenix_test_cloak_v1"))
)

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :threadline_phoenix, ThreadlinePhoenix.Repo,
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  database: "threadline_phoenix_test#{System.get_env("MIX_TEST_PARTITION")}",
  # Reap clients abandoned while idle inside a transaction so their locks cannot
  # wedge later deterministic demo resets. Active queries are unaffected.
  #
  # This MUST stay strictly below `ownership_timeout` and the ExUnit per-test
  # timeout (both 60_000 below). At an equal deadline the reaper fires at the
  # same instant the waiting test gives up, so it can never unwedge the blocked
  # query in time — which is exactly the race that made
  # DemoContractTest "SEED-02 idempotency and SEED-04 reset recovery" flake with
  # an ExUnit.TimeoutError while parked server-side in
  # Demo.Seed.Exports.run/1 -> insert_all. 20s leaves ~3x headroom over the
  # slowest observed demo-seed test (~7s) and 40s of margin for the unblocked
  # waiter to finish. Enforced by IdleTransactionReaperContractTest.
  parameters: [idle_in_transaction_session_timeout: "20000"],
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  timeout: 60_000,
  ownership_timeout: 60_000

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :threadline_phoenix, ThreadlinePhoenixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  # The e2e runner chooses a free localhost port dynamically. Keep origin
  # checks disabled in test only so LiveView sockets connect on that port.
  check_origin: false,
  secret_key_base: "EjvmPWRdJYl2nuzaH1YTk0jrEqwiEFmBxkknVmdDY2eYjwJ16VMVmRYqleJVRC25",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Disable Oban plugins/queues in test so the Postgres notifier/peer does not
# contend with Ecto SQL Sandbox ownership on the Repo connection.
config :threadline_phoenix, Oban, testing: :manual, plugins: false, queues: false

# Demo drift: redaction policy masks `internal_note_body` + `body`, but the
# deployed trigger (priv/repo/migrations) only masks `internal_note_body` — the
# policy was updated and triggers haven't been regenerated. Lets the operator
# surface's redaction-drift screen demonstrate a real finding (the e2e runs in
# MIX_ENV=test). Capture is unaffected, so row-history [REDACTED] still holds.
# TWIN-01 shape fixtures (Phase 212): the `primary_key:` override for
# shape_join and the `mask:` entries for the two same-named shape_twin
# tables. These exist only in the ExUnit lane — priv/shape_fixtures/migrations
# is migrated up by test/test_helper.exs and rolled back in
# ExUnit.after_suite, never by `mix ecto.migrate` (see that migration's
# header comment). They are omitted entirely when THREADLINE_E2E=1 so the
# browser lane's redaction screen (e2e/run-e2e.sh) never sees them.
#
# Elixir's `Config` deep-merges keyword lists but replaces maps outright, and
# this file already sets a `:trigger_capture` `tables:` map above (well,
# below) for ticket_replies/posts — so folding the fixtures into config.exs
# instead would be silently dead here. `Map.merge/2` combines both without
# duplicating the ticket_replies/posts entries.
shape_fixture_tables =
  if System.get_env("THREADLINE_E2E") == "1" do
    %{}
  else
    %{
      "shape_join" => [primary_key: ["left_id", "right_id"]],
      "shape_twin" => [mask: ["note"]],
      "shapes.shape_twin" => [mask: ["note"]]
    }
  end

config :threadline, :trigger_capture,
  tables:
    Map.merge(
      %{
        "ticket_replies" => [
          mask: ["internal_note_body", "body"],
          store_changed_from: true
        ],
        # `posts` has a deployed trigger with no redaction; an empty configured mask
        # makes it a green "Deployed matches config" row on the redaction screen,
        # so the e2e (MIX_ENV=test) shows a match alongside the ticket_replies drift.
        "posts" => [
          mask: []
        ]
      },
      shape_fixture_tables
    )

# `audit_events` exists (migrations) but has no capture trigger, so listing it
# as expected makes the coverage screen demonstrate a real "Needs capture" row
# + a non-zero header badge (and matching trigger-coverage evidence) in the e2e.
config :threadline, :verify_coverage,
  expected_tables: [
    "posts",
    "organizations",
    "org_memberships",
    "agents",
    "tickets",
    "ticket_replies",
    "audit_events"
  ]

# Sigra authentication
# Speed up password hashing in tests
config :argon2_elixir, t_cost: 1, m_cost: 8

config :swoosh, :api_client, false

config :threadline_phoenix, ThreadlinePhoenixWeb.OperatorUser,
  admin_emails: ["admin@example.com"],
  admin_user_ids: []

config :threadline_phoenix, dev_routes: true

config :threadline_phoenix,
  demo_epoch: ~U[2026-05-27 12:00:00Z],
  demo_seed_password: "password123456"

config :threadline,
  retention: [enabled: false, keep_days: 30, delete_empty_transactions: true]
