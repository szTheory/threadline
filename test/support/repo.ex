defmodule Threadline.Test.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :threadline,
    adapter: Ecto.Adapters.Postgres
end
