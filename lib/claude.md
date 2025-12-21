# lib/

Main source code directory for the Contract Fitness Flutter app.

## Architecture

Three-layer architecture:
- **ui/** - Flutter widgets and UI components
- **logic/** - Business logic and data models
- **services/** - External service integrations (Firebase)
- **fonts/** - Custom font assets (SF Pro Display)

## Entry Point

`main.dart` initializes Firebase and runs `MyApp` from `ui/app.dart`.
