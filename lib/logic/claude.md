# logic/

Core decisions layer - validates, applies rules, orchestrates.

## Rules (per A.md)
- Contains NO UI or vendor code
- Shared state lives here
- Returns Success(data) or Failure(code, message)

## Files

- **setup_logic.dart** - Auth, contract creation, user/contract queries

## Current State

**setup_logic.dart:**
- `currentUserId`, `currentUserName`, `currentContractId` - shared state
- `authenticate(name, isSignUp)` - sign up or log in
- `createContract(duration, partnerName, tasks)` - generates pairKey (sorted IDs joined with `_`), returns `duplicate` error if contract exists
- `userExists(name)` - check if user exists (for partner search)
- `getUserName(userId)` - resolve userId to name
- `getUserContracts()` - stream user's contracts
- `getUsers()` - stream all users (excluding current)
- `getTodayDate()` - returns YYYY-MM-DD string
- `getCompletedTasks(contractId)` - get today's completed task indices for current user
- `toggleTask(contractId, taskIndex)` - toggle task completion for today
- `evaluatePendingDays(contract)` - evaluate all days since lastEvaluatedDate, increment daysCompleted if both users completed all tasks
