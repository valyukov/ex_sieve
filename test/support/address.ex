defmodule ExSieve.Address do
  use Ecto.Schema
  use ExSieve.Schema, max_depth: 3

  schema "addresses" do
    belongs_to :user, ExSieve.User

    field :street
    field :city

    timestamps()
  end
end
