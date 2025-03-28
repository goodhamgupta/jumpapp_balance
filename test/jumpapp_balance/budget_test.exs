defmodule JumpappBalance.BudgetTest do
  use JumpappBalance.DataCase

  alias JumpappBalance.Budget
  alias JumpappBalance.Category
  alias JumpappBalance.Income

  describe "categories" do
    @valid_attrs %{"name" => "Groceries", "balance" => "100.00"}
    @update_attrs %{"name" => "Food", "balance" => "150.00"}
    @invalid_attrs %{"name" => nil, "balance" => nil}

    def category_fixture(attrs \\ %{}) do
      # Make sure there's income available
      {:ok, _income} = Budget.update_income("1000.00")
      
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Budget.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Enum.map(Budget.list_categories(), &(&1.id)) == [category.id]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Budget.get_category!(category.id).id == category.id
    end

    test "create_category/1 with valid data creates a category" do
      # Ensure there's income available
      {:ok, _income} = Budget.update_income("1000.00")
      
      assert {:ok, %Category{} = category} = Budget.create_category(@valid_attrs)
      assert category.name == "Groceries"
      assert Decimal.equal?(category.balance, Decimal.new("100.00"))
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Budget.create_category(@invalid_attrs)
    end

    test "create_category/1 subtracts from income" do
      # Set initial income
      {:ok, _income} = Budget.update_income("1000.00")
      initial_income = Budget.get_income()
      
      # Create category with balance
      {:ok, _category} = Budget.create_category(@valid_attrs)
      
      # Check that income was reduced
      updated_income = Budget.get_income()
      assert Decimal.compare(updated_income.amount, initial_income.amount) == :lt
      assert Decimal.equal?(
        updated_income.amount, 
        Decimal.sub(initial_income.amount, Decimal.new("100.00"))
      )
    end

    test "create_category/1 with insufficient income returns error" do
      # Set initial income to less than category balance
      {:ok, _income} = Budget.update_income("50.00")
      
      # Try to create category with balance higher than income
      result = Budget.create_category(@valid_attrs)
      
      assert result == {:error, :insufficient_income}
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, %Category{} = category} = Budget.update_category(category, @update_attrs)
      assert category.name == "Food"
      assert Decimal.equal?(category.balance, Decimal.new("150.00"))
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Budget.change_category(category)
    end
  end

  describe "income" do
    test "get_income/0 returns current income or creates default" do
      # Get income (should create default)
      income = Budget.get_income()
      assert %Income{} = income
      assert Decimal.equal?(income.amount, Decimal.new("500.00"))
      
      # Update income
      {:ok, _} = Budget.update_income("750.00")
      
      # Get updated income
      updated_income = Budget.get_income()
      assert Decimal.equal?(updated_income.amount, Decimal.new("750.00"))
    end

    test "update_income/1 updates the income" do
      amount = "800.00"
      assert {:ok, %Income{} = income} = Budget.update_income(amount)
      assert Decimal.equal?(income.amount, Decimal.new(amount))
    end
  end

  describe "budget adjustments" do
    setup do
      # Setup initial income and a category
      {:ok, _income} = Budget.update_income("1000.00")
      {:ok, category} = Budget.create_category(%{"name" => "Test", "balance" => "200.00"})
      
      %{
        category: category,
        initial_income: Budget.get_income()
      }
    end
    
    test "adjust_category_budget/2 adds to category and subtracts from income", %{category: category, initial_income: initial_income} do
      adjustment_amount = "50.00"
      
      assert {:ok, updated_category} = Budget.adjust_category_budget(category, adjustment_amount)
      assert Decimal.equal?(
        updated_category.balance, 
        Decimal.add(category.balance, Decimal.new(adjustment_amount))
      )
      
      # Check income was reduced
      updated_income = Budget.get_income()
      assert Decimal.equal?(
        updated_income.amount,
        Decimal.sub(initial_income.amount, Decimal.new(adjustment_amount))
      )
    end
    
    test "adjust_category_budget/2 with insufficient income returns error", %{category: category} do
      # Try to adjust with more than available income
      result = Budget.adjust_category_budget(category, "1000.00")
      
      assert result == {:error, :insufficient_income}
    end
    
    test "spend_from_category/2 reduces category balance", %{category: category} do
      spend_amount = "50.00"
      initial_balance = category.balance
      
      assert {:ok, updated_category} = Budget.spend_from_category(category, spend_amount)
      assert Decimal.equal?(
        updated_category.balance, 
        Decimal.sub(initial_balance, Decimal.new(spend_amount))
      )
      
      # Spending should not affect income
      income_after = Budget.get_income()
      assert Decimal.equal?(income_after.amount, Decimal.new("800.00")) # 1000 - 200 from setup
    end
    
    test "spend_from_category/2 with insufficient funds returns error", %{category: category} do
      # Try to spend more than category balance
      result = Budget.spend_from_category(category, "300.00")
      
      assert result == {:error, :insufficient_funds}
    end
  end
end