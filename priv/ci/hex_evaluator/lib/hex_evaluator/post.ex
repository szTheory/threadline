defmodule HexEvaluator.Post do
  use Ecto.Schema

  schema "posts" do
    field :title, :string
    field :slug, :string

    timestamps(type: :utc_datetime)
  end
end
