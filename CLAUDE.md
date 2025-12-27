# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
flutter pub get          # Install/refresh dependencies
flutter analyze          # Run static analysis (flutter_lints)
flutter test             # Run all tests
flutter test --coverage  # Run tests with coverage
flutter run -d <device>  # Run on simulator/device
flutter build apk        # Build Android release
flutter build ios        # Build iOS release
```

## Architecture

Three-layer architecture in `lib/`:

- **ui/** - Flutter widgets (`app.dart` contains `MyApp`, `HomePage`, `SetupDialog`, `ContractCard`)
- **logic/** - Business logic with sealed result types (`SetupResult`, `ContractResult`) for type-safe error handling
- **services/** - Firebase/Firestore operations (`firebase_service.dart`)

**Data Flow:** UI → Logic (validation/transformation) → Services (Firestore) → Logic (result types) → UI

**Entry Point:** `main.dart` initializes Firebase, locks portrait orientation, runs `MyApp`

## Firestore Collections

- `users` - Documents with `name`, `createdAt`, `contractIds`
- `contracts` - Documents with `userIds`, `duration`, `createdAt`

## Conventions

- Dart style with 2-space indentation, `flutter_lints` rules
- File names: `snake_case.dart`, Classes: `PascalCase`, Private: `_prefix`
- Prefer `const` constructors/widgets
- Test files: `*_test.dart` in `test/`
- Custom font: SF Pro Display (weights 100-900)
- Color scheme: Grey tones (background `0xFFC8C8C8`, text `0xFF3E3E3E`)

## Firebase

- Config auto-generated in `lib/firebase_options.dart` - don't edit manually
- Never commit service keys; verify Firestore rules in staging before production
