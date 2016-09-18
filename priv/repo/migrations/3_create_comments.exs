defmodule ExSieve.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :string
      add :post_id, references(:posts)
      add :user_id, references(:users)

      timestamps
    end

  end
end
