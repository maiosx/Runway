# Changelog

All notable changes to Runway are documented here.

## [1.0.2] - 2026-08-24

### Fixed

- List row text was defaulting to black on black (Bound delegates could not see `root.fg`). Account names, balances, incomes, and expenses now use explicit white `#f5f5f7`.
- Renamed the plan `enabled` model role to `isOn` so it no longer clashes with `Item.enabled`.

## [1.0.1] - 2026-08-24

### Fixed

- First launch now starts at $0 Checking with an empty plan — no sample paycheck or Rose income.
- Added accounts now appear on the Assets / Liabilities list (list layout no longer collapses).
- Tab icons draw in QML so they show even if SVG assets fail to load.
- Save clones account arrays instead of relying on QVariantList.concat.

## [1.0.0] - 2026-08-24

### Added

- Fullscreen Omarchy overlay for checking-account cash forecasting.
- Super + R hotkey (Hyprland bind) to summon and dismiss.
- Accounts (assets / liabilities), Plan (incomes / transfers / expenses), and Forecast step chart.
- Bar widget with staircase icon; left-click opens, right-click explains the hotkey.
- IPC: `omarchy-shell runway toggle|open|close|status` and `omarchy-shell shell toggle runway.forecast`.
- Data at `~/.config/omarchy/runway-v2.json`.
