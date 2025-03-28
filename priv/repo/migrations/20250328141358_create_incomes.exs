defmodule JumpappBalance.Repo.Migrations.CreateIncomes do
  use Ecto.Migration

  def change do
    create table(:incomes) do
      add :amount, :decimal

      timestamps(type: :utc_datetime)
    end
  end
end
