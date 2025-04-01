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
  
  # Maximum decimal precision to use
  @max_precision 2

  @doc """
  Returns the list of categories.
  """
  def list_categories do
    Repo.all(Category)
    |> Enum.map(fn category ->
      %{category | balance: normalize_decimal(category.balance)}
    end)
  end

  @doc """
  Gets a single category.
  """
  def get_category!(id) do
    category = Repo.get!(Category, id)
    %{category | balance: normalize_decimal(category.balance)}
  end

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
    
    # Normalize the initial balance
    normalized_balance = normalize_decimal(initial_balance)
    
    # Create a clean map with string keys for consistency
    normalized_attrs = %{
      "name" => attrs["name"] || attrs[:name],
      "balance" => normalized_balance
    }
    
    # Ensure balance is non-negative
    if Decimal.compare(normalized_balance, Decimal.new("0")) == :lt do
      {:error, :negative_balance_not_allowed}
    else
      # Get current income
      income = get_income()
      
      # Check if we have enough income
      if Decimal.compare(income.amount, normalized_balance) == :lt do
        {:error, :insufficient_income}
      else
        # Calculate new income amount
        new_income_amount = Decimal.sub(income.amount, normalized_balance)
        
        # Use a transaction to ensure both operations succeed or fail together
        Repo.transaction(fn ->
          # Create the category
          case %Category{}
               |> Category.changeset(normalized_attrs)
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
  end

  @doc """
  Updates a category.
  """
  def update_category(%Category{} = category, attrs) do
    # Extract values with support for both atom and string keys
    balance = attrs[:balance] || attrs["balance"]
    name = attrs[:name] || attrs["name"]
    
    # Build clean params map
    normalized_attrs = %{}
    
    # Add normalized balance if provided
    normalized_attrs = if balance do
      Map.put(normalized_attrs, "balance", normalize_decimal(balance))
    else
      normalized_attrs
    end
    
    # Add name if provided
    normalized_attrs = if name do
      Map.put(normalized_attrs, "name", name)
    else
      normalized_attrs
    end
    
    # If no attributes were found, use the original attrs
    normalized_attrs = if map_size(normalized_attrs) == 0, do: attrs, else: normalized_attrs
    
    category
    |> Category.changeset(normalized_attrs)
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
  Normalizes a decimal to the configured precision
  """
  def normalize_decimal(%Decimal{} = decimal) do
    decimal
    |> Decimal.round(@max_precision)
  end
  
  @doc """
  Safely compares two decimals for the spending functionality
  Returns true if a is greater than or equal to b, considering our precision
  """
  def safe_decimal_gte(%Decimal{} = a, %Decimal{} = b) do
    # Normalize both values first
    a_norm = normalize_decimal(a)
    b_norm = normalize_decimal(b)
    
    # Standard comparison
    case Decimal.compare(a_norm, b_norm) do
      :lt -> false  # a < b
      _ -> true     # a >= b
    end
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
      income -> 
        # Normalize the amount to proper precision
        %{income | amount: normalize_decimal(income.amount)}
    end
  end
  
  @doc """
  Updates the income amount.
  """
  def update_income(amount) when is_binary(amount) do
    update_income(Decimal.new(amount))
  end
  
  def update_income(%Decimal{} = amount) do
    # Normalize the amount and ensure it is non-negative
    normalized_amount = normalize_decimal(amount)
    
    if Decimal.compare(normalized_amount, Decimal.new("0")) == :lt do
      {:error, :negative_amount_not_allowed}
    else
      %Income{}
      |> Income.changeset(%{amount: normalized_amount})
      |> Repo.insert()
    end
  end
  
  @doc """
  Adjusts a category budget and updates income.
  When you add to a category budget, that amount is subtracted from income.
  """
  def adjust_category_budget(%Category{} = category, amount) when is_binary(amount) do
    adjust_category_budget(category, Decimal.new(amount))
  end
  
  def adjust_category_budget(%Category{} = category, %Decimal{} = amount) do
    # Normalize and ensure amount is non-negative
    normalized_amount = normalize_decimal(amount)
    
    if Decimal.compare(normalized_amount, Decimal.new("0")) == :lt do
      {:error, :negative_amount_not_allowed}
    else
      # Get current income
      income = get_income()
      
      # Validate that we have enough income to allocate
      if Decimal.compare(income.amount, normalized_amount) == :lt do
        {:error, :insufficient_income}
      else
        # Update the category balance - add the amount to the category
        new_balance = normalize_decimal(Decimal.add(category.balance, normalized_amount))
        
        # Subtract from income - the amount moved from income to category
        new_income_amount = normalize_decimal(Decimal.sub(income.amount, normalized_amount))
        
        # Update both in a transaction
        Repo.transaction(fn ->
          {:ok, updated_category} = update_category(category, %{balance: new_balance})
          {:ok, _income} = update_income(new_income_amount)
          updated_category
        end)
      end
    end
  end
  
  @doc """
  Spends from a category.
  """
  def spend_from_category(%Category{} = category, amount) when is_binary(amount) do
    spend_from_category(category, Decimal.new(amount))
  end
  
  def spend_from_category(%Category{} = category, %Decimal{} = amount) do
    # Normalize and ensure amount is non-negative
    normalized_amount = normalize_decimal(amount)
    
    if Decimal.compare(normalized_amount, Decimal.new("0")) == :lt do
      {:error, :negative_amount_not_allowed}
    else
      # Ensure we don't go below zero
      current_balance = normalize_decimal(category.balance || Decimal.new("0"))
      
      # Use our safe comparison that handles decimal precision correctly
      if not safe_decimal_gte(current_balance, normalized_amount) do
        {:error, :insufficient_funds}
      else
        # Calculate the new balance and update
        new_balance = normalize_decimal(Decimal.sub(current_balance, normalized_amount))
        
        # Use a transaction to ensure atomicity
        case update_category(category, %{balance: new_balance}) do
          {:ok, updated_category} -> {:ok, updated_category}
          {:error, changeset} -> {:error, changeset}
        end
      end
    end
  end
end
