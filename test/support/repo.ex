defmodule Threadline.Test.Repo do
  use Ecto.Repo,
    otp_app: :threadline,
    adapter: Ecto.Adapters.Postgres
end
