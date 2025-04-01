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
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end
end
