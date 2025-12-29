# lib/

Contract Fitness Flutter app - Fresh Start

## Architecture (per A.md)

Three layers only:
- **ui/** - Input & output (renders, collects input, calls Logic)
- **logic/** - Decisions & rules (validates, applies rules, orchestrates)
- **services/** - Side effects (reads/writes data, calls APIs)

## Entry Point

`main.dart` - Initializes Firebase, runs `MyApp`

## Current State

Auth flow (sign up/log in), contract creation, and stacked contract display with tap-to-expand/collapse behavior implemented.
