# services/

IO layer - reads/writes data, calls APIs/SDKs.

## Rules (per A.md)
- Contains NO product decisions
- Only called by Logic, never UI directly

## Files

- **firebase_service.dart** - Firestore operations for users and contracts

## Current State

**firebase_service.dart:**
- `userExists(name)` - check if user exists by name
- `getUserId(name)` - get userId by name
- `getUserName(userId)` - get name by userId
- `createUser(name)` - create new user
- `createContract(creatorId, partnerId, duration, tasks, pairKey)` - create contract with pairKey as doc ID, uses transaction to prevent duplicates, returns null if exists
- `getUserContracts(userId)` - real-time stream of contracts (listens to actual contract documents, updates when any user modifies)
- `getUsers(excludeUserId)` - stream all users except specified
- `setTaskCompletions(contractId, date, userId, indices)` - set completed task indices
- `updateContractProgress(contractId, {daysCompleted, completed})` - update contract progress
- `getContract(contractId)` - one-time fetch of contract data

**Data structures:**
- `users` collection: `{name: String}`
- `contracts` collection: `{creatorId, partnerId, duration, tasks: List<String>, createdAt, daysCompleted, completed, taskCompletions}`
- `contracts` doc ID: `pairKey` (sorted user IDs joined with `_`) - ensures one contract per user-pair
- `taskCompletions`: nested map `{date: {userId: [taskIndices]}}`
- `users/{id}/contracts` subcollection: `{contractId}` references
