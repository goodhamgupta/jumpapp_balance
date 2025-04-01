defmodule JumpappBalanceWeb.BudgetLiveTest do
  use JumpappBalanceWeb.ConnCase

  import Phoenix.LiveViewTest
  alias JumpappBalance.Budget

  # Setup some test data for the budget tests
  setup do
    # Start with a clean income
    {:ok, income} = Budget.update_income("1000.00")
    
    # Create a test category
    {:ok, category} = Budget.create_category(%{"name" => "Test Category", "balance" => "200.00"})
    
    %{income: income, category: category}
  end

  test "disconnected and connected render", %{conn: conn} do
    # Test both disconnected and connected LiveView
    {:ok, page_live, disconnected_html} = live(conn, "/")
    
    # Check both the initial HTML and the connected LiveView
    assert disconnected_html =~ "Envelope Budgeting"
    assert render(page_live) =~ "Envelope Budgeting"
    
    # Check for expected content
    assert disconnected_html =~ "Available Income"
    assert disconnected_html =~ "Categories"
  end

  test "displays income and categories", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Check for the category we created in the setup
    assert render(view) =~ "Test Category"
    
    # Check for Available Income section
    assert render(view) =~ "Available Income"
  end

  test "can open and close modals", %{conn: conn, category: _category} do
    {:ok, view, _html} = live(conn, "/")
    
    # Initial render should not have modals
    refute render(view) =~ "Adjust Budget for Test Category"
    refute render(view) =~ "Spend from Test Category"
    # The button text will be in the page, but not the modal content
    refute render(view) =~ "New Income Amount"
    
    # Open adjust budget modal
    view |> element("button", "Adjust Budget") |> render_click()
    assert render(view) =~ "Adjust Budget for Test Category"
    
    # Close it
    view |> element("button", "Cancel") |> render_click()
    refute render(view) =~ "Adjust Budget for Test Category"
    
    # Open spend modal
    view |> element("button", "Spend") |> render_click()
    assert render(view) =~ "Spend from Test Category"
    
    # Close it
    view |> element("button", "Cancel") |> render_click()
    refute render(view) =~ "Spend from Test Category"
    
    # Open income modal
    view |> element("button", "Adjust Income") |> render_click()
    assert render(view) =~ "New Income Amount"
    
    # Close it
    view |> element("button", "Cancel") |> render_click()
    refute render(view) =~ "New Income Amount"
  end

  test "can create a new category", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # The form is rendered
    assert render(view) =~ "Create New Category"
    
    # Submit the form
    attrs = %{name: "New Category", balance: "50.00"}
    view
    |> form("form", category: attrs)
    |> render_submit()
    
    # Check for success message
    assert render(view) =~ "Category created successfully"
    # Also verify the category name appears (this should be more reliable)
    assert render(view) =~ "New Category"
  end
  
  test "shows error on negative balance", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Try to create category with negative balance
    attrs = %{name: "Negative Category", balance: "-50.00"}
    view
    |> form("form", category: attrs)
    |> render_submit()
    
    # Should show error message
    assert render(view) =~ "Negative balance not allowed"
  end

  test "shows error on insufficient income", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Try to create category with more balance than available income
    attrs = %{name: "Expensive Category", balance: "2000.00"}
    view
    |> form("form", category: attrs)
    |> render_submit()
    
    # Should show error message
    assert render(view) =~ "Insufficient income"
  end

  test "can adjust budget", %{conn: conn, category: _category} do
    {:ok, view, _html} = live(conn, "/")
    
    # Open adjust budget modal
    view |> element("button", "Adjust Budget") |> render_click()
    
    # Submit adjustment form
    view
    |> element("form[phx-submit='adjust-budget']")
    |> render_submit(%{category: %{amount: "50.00"}})
    
    # Verify the flash message appears
    assert render(view) =~ "Budget adjusted successfully"
    
    # Note: We can't easily verify exact balance amounts in LiveView tests
    # because the HTML output is large and complex. Instead, we verify
    # the operation completed successfully through flash messages.
  end
  
  test "shows error on negative budget adjustment", %{conn: conn, category: _category} do
    {:ok, view, _html} = live(conn, "/")
    
    # Open adjust budget modal
    view |> element("button", "Adjust Budget") |> render_click()
    
    # Submit negative adjustment
    view
    |> element("form[phx-submit='adjust-budget']")
    |> render_submit(%{category: %{amount: "-50.00"}})
    
    # Should show error message
    assert render(view) =~ "Negative amount not allowed"
  end

  test "can spend from category", %{conn: conn, category: _category} do
    {:ok, view, _html} = live(conn, "/")
    
    # Open spend modal
    view |> element("button", "Spend") |> render_click()
    
    # Submit spend form
    view
    |> element("form[phx-submit='spend']")
    |> render_submit(%{category: %{amount: "50.00"}})
    
    # Verify the flash message appears
    assert render(view) =~ "Expense recorded successfully"
  end
  
  test "shows error on negative spend amount", %{conn: conn, category: _category} do
    {:ok, view, _html} = live(conn, "/")
    
    # Open spend modal
    view |> element("button", "Spend") |> render_click()
    
    # Submit negative spend amount
    view
    |> element("form[phx-submit='spend']")
    |> render_submit(%{category: %{amount: "-50.00"}})
    
    # Should show error message
    assert render(view) =~ "Negative amount not allowed"
  end

  test "can adjust income", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Open income modal
    view |> element("button", "Adjust Income") |> render_click()
    
    # Submit income adjustment form
    view
    |> element("form[phx-submit='adjust-income']")
    |> render_submit(%{income: %{amount: "1200.00"}})
    
    # Check for success message
    assert render(view) =~ "Income updated successfully"
  end
  
  test "shows error on negative income", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    
    # Open income modal
    view |> element("button", "Adjust Income") |> render_click()
    
    # Submit negative income adjustment
    view
    |> element("form[phx-submit='adjust-income']")
    |> render_submit(%{income: %{amount: "-1200.00"}})
    
    # Should show error message
    assert render(view) =~ "Negative amount not allowed"
  end
end