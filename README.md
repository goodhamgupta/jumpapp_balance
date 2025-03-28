# Envelope Budgeting App

A Phoenix LiveView application for managing personal finances through the envelope budgeting method.

## What is Envelope Budgeting?

Envelope budgeting is a personal finance approach where you divide your income into categories (or "envelopes") of spending. By allocating money to specific categories upfront, you can better track and control your spending habits.

## Features

- **LiveView Interface**: Real-time updates without page refreshes
- **Income Management**: Track available income and adjust as needed
- **Category Management**: Create budget categories with initial balances
- **Budget Adjustments**: Allocate income to specific categories
- **Expense Tracking**: Record spending from each category
- **Validation**: Prevent overspending with balance checks

## Technical Details

- **Framework**: Phoenix with LiveView
- **Database**: SQLite3 for simpler deployment
- **Frontend**: Tailwind CSS for styling
- **Persistence**: Ecto for database operations

## Usage Flow

1. **Initial Setup**: The app starts with a default income amount
2. **Create Categories**: Create budget categories with names and initial balances
3. **Adjust Income**: Update your available income as needed
4. **Manage Budget**: 
   - Allocate more funds to categories (subtracts from income)
   - Record expenses from categories (subtracts from category balance)
5. **Track Balances**: Monitor your remaining income and category balances

## Key Interactions

- **Creating a category**: Allocates money from your income to a new budget category
- **Adjusting a budget**: Moves money from income to an existing category
- **Recording an expense**: Reduces the balance of a category without affecting income

## Installation

### Prerequisites

- Elixir (version 1.14 or later)
- Phoenix Framework
- SQLite3

### Setup

1. Clone the repository:
   ```bash
   git clone [repository-url]
   cd jumpapp_balance
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

3. Setup the database:
   ```bash
   mix ecto.setup
   ```

4. Start the Phoenix server:
   ```bash
   mix phx.server
   ```

5. Visit [`localhost:4000`](http://localhost:4000) from your browser.

## Implementation Details

### Database Schema

- **Categories**: Store budget categories with name and balance
- **Income**: Track available income amount

### Key Components

- **Budget Context**: Handles business logic for categories and income
- **BudgetLive**: LiveView component for interactive UI
- **Transactions**: Ensures data integrity when updating related records

## Development

### Available Commands

- `mix setup` - Install and setup dependencies
- `mix ecto.migrate` - Run database migrations
- `mix phx.server` - Start Phoenix server
- `iex -S mix phx.server` - Start Phoenix server with interactive Elixir shell

## Notes

- The application uses a SQLite database for simplicity, making it portable and easy to set up
- LiveView provides a seamless user experience with real-time updates
- Transactions ensure that related operations (like updating both category and income) succeed or fail together