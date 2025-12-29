# ui/

Presentation layer - renders and collects input.

## Rules (per A.md)
- Calls Logic, never Services directly
- Contains NO business rules or IO
- Local UI state stays local

## Files

- **app.dart** - `MyApp` entry point
- **home_page.dart** - `HomePage` main screen with stacked contracts and bottom bar handle
- **bottom_sheet.dart** - `BottomSheetContent` modal (Duration, Partner selection)

## Current State

Stacked contract widgets implemented. Multiple contracts display as a deck with collapsed cards (showing only DAY. and percentage) stacked above the expanded card (full content with dot board, tasks, PARTNER). Tap to expand/collapse. Last contract (bottom) expanded by default. List reversed so newest contracts appear first.
