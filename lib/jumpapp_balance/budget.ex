defmodule JumpappBalance.Budget do
  @moduledoc """
  The Budget context.
  """

  import Ecto.Query, warn: false
  alias JumpappBalance.Repo
  alias JumpappBalance.Category
  alias JumpappBalance.Income

  # Default income amount if none exists
  @default_income Decimal.new("500.00")

  @doc """
  Returns the list of categories.
  """
  def list_categories do
    Repo.all(Category)
  end

  @doc """
  Gets a single category.
  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Creates a category and subtracts the initial balance from income.
  """
  def create_category(attrs \\ %{}) do
    # Get the initial balance from the attributes
    balance_str = attrs["balance"] || attrs[:balance] || "0"
    initial_balance = 
      case balance_str do
        %Decimal{} -> balance_str
        _ -> Decimal.new(balance_str)
      end

    # Get current income
    income = get_income()
    
    # Check if we have enough income
    if Decimal.compare(income.amount, initial_balance) == :lt do
      {:error, :insufficient_income}
    else
      # Calculate new income amount
      new_income_amount = Decimal.sub(income.amount, initial_balance)
      
      # Use a transaction to ensure both operations succeed or fail together
      Repo.transaction(fn ->
        # Create the category
        case %Category{}
             |> Category.changeset(attrs)
             |> Repo.insert() do
          {:ok, category} ->
            # Update income
            case update_income(new_income_amount) do
              {:ok, _income} -> category
              {:error, reason} -> Repo.rollback(reason)
            end
          
          {:error, reason} -> Repo.rollback(reason)
        end
      end)
    end
  end

  @doc """
  Updates a category.
  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.
  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.
  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
  
  @doc """
  Gets the current income balance.
  Creates one with default value if none exists.
  """
  def get_income do
    case Repo.one(from i in Income, order_by: [desc: i.id], limit: 1) do
      nil -> 
        # Create initial income record if none exists
        {:ok, income} = %Income{amount: @default_income} |> Repo.insert()
        income
      income -> income
    end
  end
  
  @doc """
  Updates the income amount.
  """
  def update_income(amount) when is_binary(amount) do
    update_income(Decimal.new(amount))
  end
  
  def update_income(%Decimal{} = amount) do
    %Income{}
    |> Income.changeset(%{amount: amount})
    |> Repo.insert()
  end
  
  @doc """
  Adjusts a category budget and updates income.
  When you add to a category budget, that amount is subtracted from income.
  """
  def adjust_category_budget(%Category{} = category, amount) when is_binary(amount) do
    adjust_category_budget(category, Decimal.new(amount))
  end
  
  def adjust_category_budget(%Category{} = category, %Decimal{} = amount) do
    # Get current income
    income = get_income()
    
    # Validate that we have enough income to allocate
    if Decimal.compare(income.amount, amount) == :lt do
      {:error, :insufficient_income}
    else
      # Update the category balance - add the amount to the category
      new_balance = Decimal.add(category.balance, amount)
      
      # Subtract from income - the amount moved from income to category
      new_income_amount = Decimal.sub(income.amount, amount)
      
      # Update both in a transaction
      Repo.transaction(fn ->
        {:ok, updated_category} = update_category(category, %{balance: new_balance})
        {:ok, _income} = update_income(new_income_amount)
        updated_category
      end)
    end
  end
  
  @doc """
  Spends from a category.
  """
  def spend_from_category(%Category{} = category, amount) when is_binary(amount) do
    spend_from_category(category, Decimal.new(amount))
  end
  
  def spend_from_category(%Category{} = category, %Decimal{} = amount) do
    # Ensure we don't go below zero
    current_balance = category.balance || Decimal.new("0")
    
    if Decimal.compare(current_balance, amount) == :lt do
      {:error, :insufficient_funds}
    else
      new_balance = Decimal.sub(current_balance, amount)
      update_category(category, %{balance: new_balance})
    end
  end
end