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
- `createContract(creatorId, partnerId, duration, tasks)` - create contract, link to both users
- `getUserContracts(userId)` - stream contracts for user
- `getUsers(excludeUserId)` - stream all users except specified

**Data structures:**
- `users` collection: `{name: String}`
- `contracts` collection: `{creatorId, partnerId, duration, tasks: List<String>, createdAt}`
- `users/{id}/contracts` subcollection: `{contractId}` references
