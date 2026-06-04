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
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :threadline_phoenix, ThreadlinePhoenixWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
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
config :threadline, :trigger_capture,
  tables: %{
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
  }

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
