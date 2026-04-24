import Config

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
