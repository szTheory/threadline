import Config

config :threadline, Threadline.Test.Repo,
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  username: "postgres",
  password: "postgres",
  database: "threadline_test",
  pool_size: 2

config :threadline, ecto_repos: [Threadline.Test.Repo]

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
  delete_empty_transactions: true

config :logger, level: :warning
