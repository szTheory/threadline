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

config :logger, level: :warning
