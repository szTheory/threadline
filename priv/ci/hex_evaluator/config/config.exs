import Config

config :hex_evaluator, ecto_repos: [HexEvaluator.Repo]

config :threadline, ecto_repos: [HexEvaluator.Repo]

config :hex_evaluator, HexEvaluator.Repo,
  database: "hex_evaluator_test",
  username: "postgres",
  password: "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  port: String.to_integer(System.get_env("DB_PORT") || "5432")

# TWIN-01 shape fixture overrides (Phase 212, D-19): the shape_join table has
# no primary key at all, addressed only through this primary_key: override,
# and both shape_twin tables mask their `note` column. Do not add a dedicated
# schema key here — the evaluator's legacy-public proof (LegacyPublicSchemaTest)
# depends on this fixture configuring no schema for audit tables at all.
config :threadline, :trigger_capture,
  tables: %{
    "shape_join" => [primary_key: ["left_id", "right_id"]],
    "shape_twin" => [mask: ["note"]],
    "shapes.shape_twin" => [mask: ["note"]]
  }

import_config "#{config_env()}.exs"
