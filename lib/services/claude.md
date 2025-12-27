# services/

External service integrations layer.

## Files

- **firebase_service.dart** - Firestore database operations

## Functions

### Users
- `createUser(name)` - Creates user document, returns doc ID
- `getUsers()` - Returns all users with IDs
- `getUsersByIds(userIds)` - Batch fetch users by document IDs

### Contracts
- `createContract(userIds, duration)` - Creates contract and updates user documents with contract reference
- `getContractsByUserId(userId)` - Queries contracts containing the user

## Firestore Collections

- `users` - User documents with name, createdAt, contractIds
- `contracts` - Contract documents with userIds, duration, createdAt
