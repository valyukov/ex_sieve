defmodule ExSieve.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string
      add :surname, :string
      add :cash, :integer

      timestamps()
    end
  end
end
