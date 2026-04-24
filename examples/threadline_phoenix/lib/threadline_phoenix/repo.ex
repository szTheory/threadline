defmodule ThreadlinePhoenix.Repo do
  use Ecto.Repo,
    otp_app: :threadline_phoenix,
    adapter: Ecto.Adapters.Postgres
end
