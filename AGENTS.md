# Repository Guidelines

## Project Structure & Modules
- `lib/main.dart` boots the app, locks portrait, and initializes Firebase via `lib/firebase_options.dart`.
- UI lives in `lib/ui` (`app.dart` holds the `MaterialApp` and main screens); business rules sit in `lib/logic`; Firestore accessors are in `lib/services`.
- Custom typography is in `lib/fonts`; platform folders (`android`, `ios`, `macos`, `windows`, `linux`, `web`) use Flutter defaults.
- Tests reside under `test/` (seed file: `test/widget_test.dart`). Add new tests beside features using `*_test.dart`.

## Build, Test, and Development Commands
- `flutter pub get` – install/refresh dependencies after pulling changes.
- `flutter analyze` – run static analysis (uses `analysis_options.yaml` with `flutter_lints`).
- `flutter test` – run all unit/widget tests; add `--coverage` when validating coverage locally.
- `flutter run -d <device>` – launch the app on a simulator/emulator or connected device.
- `flutter build apk` / `flutter build ios` – produce release artifacts for Android/iOS (ensure platform prerequisites are installed).

## Coding Style & Naming Conventions
- Follow Dart style with 2-space indentation and `flutter_lints`; prefer `const` constructors/widgets when possible.
- File names use `snake_case.dart`; classes/widgets use `PascalCase`; private members prefix with `_`.
- Keep UI composition in `lib/ui`, shared data shaping in `lib/logic`, and network/Firebase calls in `lib/services`.
- Avoid `print`; surface issues through error handling or logging utilities when added.

## Testing Guidelines
- Use `flutter_test` for widget/unit coverage; mirror production file names with `*_test.dart`.
- Favor small, deterministic tests; mock Firestore calls via fakes/mocks when behavior depends on remote data.
- Include at least a happy-path and one failure-path per new logic function; for widgets, assert visible text, layout, and interaction results.

## Commit & Pull Request Guidelines
- Write concise commit messages in imperative mood (e.g., “Add contract grid layout”); group related changes per commit when feasible.
- Before opening a PR: run `flutter analyze` and `flutter test`, and note any intentional exceptions.
- PRs should describe scope, testing performed, and any follow-up TODOs; attach screenshots/GIFs for UI changes and reference issue IDs when applicable.

## Security & Configuration Tips
- Firebase config is generated into `lib/firebase_options.dart`; avoid committing service keys or altering auto-generated sections manually.
- Verify Firestore rules locally/in staging before shipping; never hardcode secrets in source—use platform-specific secure storage or env tooling when introduced.
