defmodule ExSieve.User do
  use Ecto.Schema
  use ExSieve.Schema

  @ex_sieve_not_filterable_fields [:addresses, :surname]

  schema "users" do
    has_many :comments, ExSieve.Comment
    has_many :posts, ExSieve.Post
    has_many :addresses, ExSieve.Address

    field :name
    field :surname
    field :cash, Money.Ecto.Type

    timestamps()
  end
end
