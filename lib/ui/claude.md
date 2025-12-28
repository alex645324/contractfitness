# ui/

Presentation layer - renders and collects input.

## Rules (per A.md)
- Calls Logic, never Services directly
- Contains NO business rules or IO
- Local UI state stays local

## Files

- **app.dart** - `MyApp` entry point
- **home_page.dart** - `HomePage` main screen with bottom bar handle
- **bottom_sheet.dart** - `BottomSheetContent` modal (Duration, Partner selection)

## Current State

Bottom sheet UI implemented. Top widgets pending.
