defmodule JumpappBalanceWeb.BudgetController do
  use JumpappBalanceWeb, :controller

  alias JumpappBalance.Budget
  alias JumpappBalance.Category

  def index(conn, _params) do
    categories = Budget.list_categories()
    changeset = Budget.change_category(%Category{})
    income = Budget.get_income()
    
    render(conn, :index, 
      categories: categories, 
      changeset: changeset,
      income: income
    )
  end

  def create(conn, %{"category" => category_params}) do
    case Budget.create_category(category_params) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Category created successfully.")
        |> redirect(to: ~p"/budget")

      {:error, %Ecto.Changeset{} = changeset} ->
        categories = Budget.list_categories()
        income = Budget.get_income()
        render(conn, :index, categories: categories, changeset: changeset, income: income)
    end
  end

  def adjust_budget(conn, params) do
    id = params["id"] || params["category_id"]
    category_params = params["category"]
    
    category = Budget.get_category!(id)
    amount = Decimal.new(category_params["amount"] || "0")
    
    case Budget.adjust_category_budget(category, amount) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Budget adjusted successfully.")
        |> redirect(to: ~p"/budget")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not adjust budget.")
        |> redirect(to: ~p"/budget")
    end
  end

  def spend(conn, params) do
    id = params["id"] || params["category_id"]
    category_params = params["category"]
    category = Budget.get_category!(id)
    amount = Decimal.new(category_params["amount"] || "0")
    
    case Budget.spend_from_category(category, amount) do
      {:ok, _category} ->
        conn
        |> put_flash(:info, "Expense recorded successfully.")
        |> redirect(to: ~p"/budget")

      {:error, :insufficient_funds} ->
        conn
        |> put_flash(:error, "Insufficient funds in this category.")
        |> redirect(to: ~p"/budget")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Could not record expense.")
        |> redirect(to: ~p"/budget")
    end
  end
  
  def adjust_income(conn, %{"income" => income_params}) do
    amount = Decimal.new(income_params["amount"] || "0")
    
    case Budget.update_income(amount) do
      {:ok, _income} ->
        conn
        |> put_flash(:info, "Income updated successfully.")
        |> redirect(to: ~p"/budget")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not update income.")
        |> redirect(to: ~p"/budget")
    end
  end
end