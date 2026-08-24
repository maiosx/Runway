# Runway for Omarchy

![Runway preview](preview.png)

A fullscreen checking-account forecast that lives inside `omarchy-shell`. Super + R summons it over the desktop — accounts, a plan of incomes / transfers / expenses, and a green step-chart of cash from today to any date you pick.

Layout matches a native phone finance app: black field, white pills, orange zero-line. Data is stored in `~/.config/omarchy/runway.json` (a sample household is seeded on first launch). Escape dismisses the overlay.

The plugin adds a staircase icon to the bar. Left-click opens Runway; right-click shows a short reminder that Super + R is the hotkey.

## Install

```bash
omarchy plugin add https://github.com/maiosx/omarchy-runway.git --enable --yes
~/.config/omarchy/plugins/runway.forecast/scripts/install-bind
```

For a local checkout:

```bash
plugin_dir="$HOME/.config/omarchy/plugins/runway.forecast"
mkdir -p "$(dirname "$plugin_dir")"
ln -s "$PWD" "$plugin_dir"
omarchy-shell shell rescanPlugins
omarchy plugin enable runway.forecast
./scripts/install-bind
```

`install-bind` writes `~/.config/hypr/runway.conf` and sources it so **Super + R** runs:

```bash
omarchy-shell shell toggle runway.forecast
```

If Super + R is already taken (stock Hyprland resize submap), comment that bind out and keep Runway's. Quattro Lua equivalent:

```lua
o.bind("SUPER + R", "omarchy-shell shell toggle runway.forecast")
```

The plugin targets Omarchy Quattro and uses only Qt Quick and Quickshell components already present in Omarchy. It does not install packages or run background executables.

## Controls

```bash
omarchy-shell shell toggle runway.forecast
omarchy-shell runway toggle
omarchy-shell runway open
omarchy-shell runway close
omarchy-shell runway status
```

Inside the overlay:

- Bottom tabs — Accounts, Plan, Forecast
- Forecast date arrows step a month; tap the date to jump one year out
- Tap the big number to flip between balance and months of runway
- Tap the account label to switch Checking ↔ All Accounts
- Plan checkmarks enable/disable a cashflow without deleting it
- `+` adds an account, income, expense, or transfer
- Escape closes an editor, then the overlay

## Notes

- The overlay is a `WlrLayer.Overlay` surface with exclusive keyboard focus, the same kind as the emoji picker and clipboard manager.
- `keepLoaded: true` keeps the forecast in memory between summons.
- Disable or remove with:

```bash
omarchy plugin disable runway.forecast
omarchy plugin remove runway.forecast --yes
```
