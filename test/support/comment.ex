defmodule ExSieve.Comment do
  use Ecto.Schema
  use ExSieve.Schema

  @ex_sieve_not_filterable_fields [:inserted_at]

  schema "comments" do
    belongs_to :post, ExSieve.Post
    belongs_to :user, ExSieve.User

    field :body

    timestamps()
  end
end
