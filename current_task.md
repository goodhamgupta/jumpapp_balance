## Current Task: Create an envelope budgeting app

### Task 1: Show a list of categories with a balance on each one ✅ COMPLETE

#### Implementation:
- Created Category schema with name and balance fields
- Set up SQLite database with migrations
- Implemented interactive LiveView interface
- Display all categories with balances in a clean UI
- Added ability to create new categories
- Added modals for adjusting budgets and spending
- Integrated income management at the top of the page

### Task 2: Create a new category with a name ✅ COMPLETE
- Implemented category creation form with LiveView
- Category creation stores both name and initial balance
- Initial category balance is subtracted from available income
- Real-time feedback without page refreshes
- Validation to prevent creating categories with balances exceeding available income

### Task 3: Income Management at the top ✅ COMPLETE
- Added Income model to track available funds
- Implemented income adjustment functionality with LiveView modal
- Show current income at top of page
- Real-time updates when income changes

### Task 4: Ability to adjust budget or spend from categories ✅ COMPLETE
- Added LiveView modals for adjusting category budgets and spending
- Added functionality to record expenses from categories
- Implemented proper balance tracking
- When adjusting a budget, amount is subtracted from income
- Spending subtracts amount from the category
- Added validation for insufficient funds

### Implementation Details:
- Using Phoenix LiveView for real-time updates and interactive UI
- SQLite database for data persistence
- Transaction-based updates to ensure data integrity
- Tailwind CSS for responsive design

### Next Steps:
All required features have been implemented! The app now allows:
- Viewing categories with balances
- Creating new categories
- Adjusting income
- Adjusting category budgets (subtracting from income)
- Recording expenses from categories