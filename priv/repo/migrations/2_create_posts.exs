defmodule ExSieve.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :string
      add :published, :boolean
      add :user_id, references(:users)

      timestamps
    end

  end
end
