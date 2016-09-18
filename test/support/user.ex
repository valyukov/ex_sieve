defmodule ExSieve.User do
  use Ecto.Schema

  schema "users" do
    has_many :comments, ExSieve.Comment
    has_many :posts, ExSieve.Post

    field :name

    timestamps
  end
end
