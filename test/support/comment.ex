defmodule ExSieve.Comment do
  use Ecto.Schema

  schema "comments" do
    belongs_to(:post, ExSieve.Post)
    belongs_to(:user, ExSieve.User)

    field(:body)

    timestamps()
  end
end
