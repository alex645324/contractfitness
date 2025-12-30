# lib/

Contract Fitness Flutter app

## Architecture (per A.md)

Three layers only:
- **ui/** - Input & output (renders, collects input, calls Logic)
- **logic/** - Decisions & rules (validates, applies rules, orchestrates)
- **services/** - Side effects (reads/writes data, calls APIs)

## Entry Point

`main.dart` - Initializes Firebase, runs `MyApp`

## Current State

- Auth flow (sign up/log in)
- Contract creation with duration (60/90), 3 custom tasks, partner search
- Stacked contract display with tap-to-expand/collapse
- Dynamic contract rendering (duration, tasks, partner from saved data)
- Required field validation before contract creation
