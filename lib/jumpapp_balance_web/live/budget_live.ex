defmodule JumpappBalanceWeb.BudgetLive do
  use JumpappBalanceWeb, :live_view

  alias JumpappBalance.Budget
  alias JumpappBalance.Category

  def mount(_params, _session, socket) do
    categories = Budget.list_categories()
    income = Budget.get_income()
    changeset = Budget.change_category(%Category{})

    socket =
      socket
      |> assign(:categories, categories)
      |> assign(:income, income)
      |> assign(:changeset, changeset)
      |> assign(:show_adjust_modal, false)
      |> assign(:show_spend_modal, false)
      |> assign(:show_income_modal, false)
      |> assign(:selected_category, nil)

    {:ok, socket}
  end

  # Create a new category
  def handle_event("create-category", %{"category" => category_params}, socket) do
    case Budget.create_category(category_params) do
      {:ok, _category} ->
        socket =
          socket
          |> put_flash(:info, "Category created successfully.")
          |> assign(:categories, Budget.list_categories())
          |> assign(:income, Budget.get_income()) # Update income display
          |> assign(:changeset, Budget.change_category(%Category{}))

        {:noreply, socket}
      
      {:error, :insufficient_income} ->
        socket =
          socket
          |> put_flash(:error, "Insufficient income to create category with this balance.")
          |> assign(:changeset, Budget.change_category(%Category{}))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
        
      {:error, _reason} ->
        socket =
          socket
          |> put_flash(:error, "Could not create category.")
          |> assign(:changeset, Budget.change_category(%Category{}))

        {:noreply, socket}
    end
  end

  # Open the adjust budget modal
  def handle_event("open-adjust-modal", %{"id" => id}, socket) do
    category = Budget.get_category!(id)
    
    {:noreply, 
     socket
     |> assign(:show_adjust_modal, true)
     |> assign(:selected_category, category)}
  end

  # Open the spend modal
  def handle_event("open-spend-modal", %{"id" => id}, socket) do
    category = Budget.get_category!(id)
    
    {:noreply, 
     socket
     |> assign(:show_spend_modal, true)
     |> assign(:selected_category, category)}
  end

  # Open the income modal
  def handle_event("open-income-modal", _params, socket) do
    {:noreply, assign(socket, :show_income_modal, true)}
  end

  # Close any modal
  def handle_event("close-modal", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_adjust_modal, false)
     |> assign(:show_spend_modal, false)
     |> assign(:show_income_modal, false)}
  end

  # Adjust budget for a category
  def handle_event("adjust-budget", %{"category" => category_params}, socket) do
    category = socket.assigns.selected_category
    amount = Decimal.new(category_params["amount"] || "0")
    
    case Budget.adjust_category_budget(category, amount) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Budget adjusted successfully.")
          |> assign(:show_adjust_modal, false)
          |> assign(:categories, Budget.list_categories())
          |> assign(:income, Budget.get_income())

        {:noreply, socket}
        
      {:error, :insufficient_income} ->
        socket =
          socket
          |> put_flash(:error, "Insufficient income available.")
          |> assign(:show_adjust_modal, false)

        {:noreply, socket}

      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Could not adjust budget.")
          |> assign(:show_adjust_modal, false)

        {:noreply, socket}
    end
  end

  # Spend from a category
  def handle_event("spend", %{"category" => category_params}, socket) do
    category = socket.assigns.selected_category
    amount = Decimal.new(category_params["amount"] || "0")
    
    case Budget.spend_from_category(category, amount) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Expense recorded successfully.")
          |> assign(:show_spend_modal, false)
          |> assign(:categories, Budget.list_categories())

        {:noreply, socket}

      {:error, :insufficient_funds} ->
        socket =
          socket
          |> put_flash(:error, "Insufficient funds in this category.")
          |> assign(:show_spend_modal, false)

        {:noreply, socket}

      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Could not record expense.")
          |> assign(:show_spend_modal, false)

        {:noreply, socket}
    end
  end

  # Update income
  def handle_event("adjust-income", %{"income" => income_params}, socket) do
    amount = Decimal.new(income_params["amount"] || "0")
    
    case Budget.update_income(amount) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Income updated successfully.")
          |> assign(:show_income_modal, false)
          |> assign(:income, Budget.get_income())

        {:noreply, socket}

      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "Could not update income.")
          |> assign(:show_income_modal, false)

        {:noreply, socket}
    end
  end
end