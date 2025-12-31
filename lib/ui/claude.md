# ui/

Presentation layer - renders and collects input.

## Rules (per A.md)
- Calls Logic, never Services directly
- Contains NO business rules or IO
- Local UI state stays local

## Files

- **app.dart** - `MyApp` entry point
- **home_page.dart** - `HomePage` main screen with stacked contracts and bottom bar handle
- **bottom_sheet.dart** - `BottomSheetContent` modal (Duration, Tasks, Partner, Account)

## Current State

**home_page.dart:**
- Stacked contract widgets with tap-to-expand/collapse
- Dynamic rendering: daysCompleted/duration, custom task names, partner name from contract data
- Clickable tasks with strikethrough toggle (persisted to Firebase per user per day)
- Partner name resolved async from partnerId
- Dot board with 30 dots per page, pagination based on daysCompleted
- Real-time updates via StreamBuilder (both users see changes immediately)

**bottom_sheet.dart:**
- Duration: select 60 or 90 (strikethrough selection)
- Tasks: 3 text inputs for custom task names
- Partner: FIND input + THIS FUCKER to confirm partner exists
- Account: SIGN UP / LOG IN + NAME input + CONFIRM
- Validation: all fields required, Confirm turns red on failure
- `_isCreating` lock prevents duplicate contract creation from multi-tap
