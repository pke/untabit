# Changelog

All notable changes to Untabit are documented here.

## [0.3.1] - 2026-08-17

### Fixed

- Ignore harmless races when a tab or window closes during an Untabit operation.
- Process rapid shortcut and toolbar invocations sequentially.
- Handle Chromium extension service-worker shutdown races without uncaught errors.

## [0.3.0] - 2026-08-13

### Added

- Pop the active tab into its own window with Alt+U (Control+U on macOS).
- Press the same shortcut again to merge the tab back into its original window.
- Preserve page state by moving tabs rather than reopening them.
- Fall back to the most recently focused compatible window if the origin is gone.
- Show guided help when the suggested shortcut cannot be registered.
- Support Chrome, Brave, Edge, and Firefox.
