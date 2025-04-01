defmodule JumpappBalance.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :balance, :decimal

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :balance])
    |> validate_required([:name, :balance])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
  end
end
