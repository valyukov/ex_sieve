defmodule ExSieve.Repo.Migrations.CreateAuthor do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :cash, :integer

      timestamps()
    end
  end
end
