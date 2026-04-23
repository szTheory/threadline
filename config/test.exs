import Config

config :threadline, Threadline.Test.Repo,
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  username: "postgres",
  password: "postgres",
  database: "threadline_test",
  pool_size: 2

config :threadline, ecto_repos: [Threadline.Test.Repo]

config :logger, level: :warning
