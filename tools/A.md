# ARCHITECTURE.md — First Principles

This codebase is built from fundamentals, not patterns.

Software reduces to three unavoidable forces:
1. **UI** — input & output
2. **Logic** — decisions & rules
3. **Services** — side effects (IO)

Nothing else is allowed.

---

## PRIME DIRECTIVE

Write the **least amount of code** that:
- Works
- Is readable end-to-end
- Can be changed without fear

If a line does not reduce confusion or real pain, delete it.

---

## SIMPLICITY LAWS (NON-NEGOTIABLE)

1. Fewer files beat clever abstractions  
2. One folder = one purpose  
3. One file = one primary job  
4. One function = one responsibility  
5. No abstraction until duplication hurts  
6. Delete aggressively

---

## LAYERS & RULES

### UI (Presentation)
- Renders and collects input
- Calls Logic
- Contains **no** business rules or IO

### Logic (Core Decisions)
- Validates input
- Applies rules
- Orchestrates behavior
- Contains **no** UI or vendor code

### Services (IO)
- Reads/writes data
- Calls APIs / SDKs
- Contains **no** product decisions

---

## DEPENDENCY LAW

Never reverse this direction.

---

## FILE LAW

Default:
- **One file = one primary function**

Multiple functions allowed **only** when they are inseparable helpers for that function.

File names describe **behavior**, not implementation.

---

## FEATURE CREATION RULE

Start with the **verb** (what the user does), not data models or schema.

Each feature produces:
- A UI entry point
- A Logic action
- A Service effect

---

## STATE RULES

- Local UI state stays local
- Shared state lives in Logic
- All meaningful state changes go through Logic

---

## ERROR RULE

Logic returns:
- `Success(data)`
- `Failure(code, message)`

UI displays results.  
UI never interprets meaning.

---

## PERFORMANCE TRUTH

Performance comes from:
- Small data
- Few transformations
- Few IO calls

Never from premature abstraction.

---

## CHANGE PROTOCOL

For non-trivial changes:
1. Propose files
2. Confirm
3. Implement minimal version
4. Confirm
5. Harden
6. Confirm

---

If this file grows, the architecture has failed.

