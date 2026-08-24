# Changelog

All notable changes to Runway are documented here.

## [1.0.0] - 2026-08-24

### Added

- Fullscreen Omarchy overlay for checking-account cash forecasting.
- Super + R hotkey (Hyprland bind) to summon and dismiss.
- Accounts (assets / liabilities), Plan (incomes / transfers / expenses), and Forecast step chart.
- Bar widget with staircase icon; left-click opens, right-click explains the hotkey.
- IPC: `omarchy-shell runway toggle|open|close|status` and `omarchy-shell shell toggle runway.forecast`.
- Sample household seeded on first launch; data at `~/.config/omarchy/runway.json`.

### Notes

- Follows the Fluid Clouds plugin layout (manifest, service-style QML, bar widget, assets, hypr bind, install script).
- Overlay surface matches first-party Omarchy overlays (emoji, clipboard): `WlrLayer.Overlay`, exclusive keyboard, Escape to dismiss.
