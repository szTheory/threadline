defmodule HexEvaluator.Repo do
  use Ecto.Repo,
    otp_app: :hex_evaluator,
    adapter: Ecto.Adapters.Postgres
end
