# logic/

Business logic layer handling data transformation and validation.

## Files

- **setup_logic.dart** - Setup flow logic and contract retrieval

## Classes

### Result Types (Sealed Classes)
- `SetupResult` - Base for setup outcomes
  - `SetupSuccess` - Contains userId and optional contractId
  - `SetupFailure` - Contains error message
- `ContractResult` - Base for contract query outcomes
  - `ContractSuccess` - Contains contract display data (id, title, partnerNames, daysPassed, duration)
  - `ContractNotFound` - No active contract found

## Functions

- `submitSetup()` - Validates input, creates user, optionally creates contract
- `getActiveContract()` - Retrieves and formats active contract for display
