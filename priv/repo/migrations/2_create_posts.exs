defmodule ExSieve.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :string
      add :published, :boolean
      add :published_at, :naive_datetime
      add :user_id, references(:users)

      timestamps()
    end
  end
end
