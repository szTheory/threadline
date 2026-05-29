import Config

config :hex_evaluator, ecto_repos: [HexEvaluator.Repo]

config :threadline, ecto_repos: [HexEvaluator.Repo]

config :hex_evaluator, HexEvaluator.Repo,
  database: "hex_evaluator_test",
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  port: String.to_integer(System.get_env("DB_PORT") || "5432")

import_config "#{config_env()}.exs"
