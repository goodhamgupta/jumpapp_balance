defmodule JumpappBalance.Income do
  use Ecto.Schema
  import Ecto.Changeset

  schema "incomes" do
    field :amount, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(income, attrs) do
    income
    |> cast(attrs, [:amount])
    |> validate_required([:amount])
  end
end
