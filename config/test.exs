import Config

config :threadline, Threadline.TestRepo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "threadline_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :logger, level: :warning
