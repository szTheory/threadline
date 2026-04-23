import Config

config :threadline, Threadline.Test.Repo,
  hostname: System.get_env("DB_HOST", "localhost"),
  username: "postgres",
  password: "postgres",
  database: "threadline_test",
  pool_size: 2

config :threadline, ecto_repos: [Threadline.Test.Repo]

config :logger, level: :warning
