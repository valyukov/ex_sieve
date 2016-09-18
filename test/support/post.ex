defmodule ExSieve.Post do
  use Ecto.Schema

  schema "posts" do
    has_many :comments, ExSieve.Comment
    belongs_to :user, ExSieve.User

    field :title
    field :body
    field :published, :boolean

    timestamps
  end
end
