defmodule ExSieve.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:addresses) do
      add :street, :string
      add :city, :string

      add :user_id, references(:users)

      timestamps()
    end
  end
end
