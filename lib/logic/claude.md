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
- `getUserContracts()` - stream user's contracts (real-time updates)
- `getUsers()` - stream all users (excluding current)
- `getTodayDate()` - returns YYYY-MM-DD string
- `toggleTask(contractId, taskIndex)` - toggle task, immediately updates daysCompleted if both users complete/uncomplete all tasks
