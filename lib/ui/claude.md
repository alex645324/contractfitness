# ui/

User interface layer containing Flutter widgets.

## Files

- **app.dart** - Main app widget (`MyApp`), `HomePage`, `SetupDialog`, and `ContractCard` widgets

## Patterns

- StatelessWidget for simple display (`MyApp`, `ContractCard`)
- StatefulWidget for interactive components (`HomePage`, `SetupDialog`)
- Dialog pattern for user setup flow
- GridView for displaying contract cards

## Styling

- Custom font: SF Pro Display
- Primary color scheme: Grey tones (0xFFC8C8C8 background, 0xFF3E3E3E text)
- Card shadows with blur radius 18
