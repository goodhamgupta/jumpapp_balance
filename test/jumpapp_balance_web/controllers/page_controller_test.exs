defmodule JumpappBalanceWeb.PageControllerTest do
  use JumpappBalanceWeb.ConnCase

  # Our route "/" now routes to BudgetLive, not PageController
  # We'll keep this test for the traditional controller route
  test "GET /traditional", %{conn: conn} do
    conn = get(conn, ~p"/traditional")
    assert html_response(conn, 200) =~ "Envelope Budgeting"
  end
end
