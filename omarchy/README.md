# Omarchy config

Omarchy 4 replaced waybar with the Quickshell bar built into `omarchy-shell`.
`shell.json` is the whole bar config; it hot-reloads on save, and
`install.sh` deploys it to `~/.config/omarchy/shell.json`.

## Bar layout

Ported from the old `waybar/config.jsonc`, section for section:

| Old waybar module | shell.json widget |
| --- | --- |
| `custom/omarchy` | `omarchy.menu` |
| `hyprland/workspaces` | `omarchy.workspaces` |
| `clock` | `blob.clock` (custom module) |
| `custom/update` | `omarchy.system-update` |
| `custom/voxtype` | `omarchy.indicators` -> `Dictation` |
| `custom/screenrecording-indicator` | `omarchy.indicators` -> `ScreenRecording` |
| `custom/idle-indicator` | `omarchy.indicators` -> `StayAwake` |
| `custom/notification-silencing-indicator` | `omarchy.indicators` -> `Dnd` |
| `group/tray-expander` | `omarchy.tray` |
| `bluetooth` | `omarchy.bluetooth` |
| `network` | `omarchy.network` |
| `pulseaudio` | `omarchy.audio` |
| `battery` | `omarchy.power` |
| `cpu` | `blob.cpu` (custom module) |
| `custom/notification` | `blob.notifications` (custom module) |
| (new in Omarchy 4) | `omarchy.agents` - AI agent usage |

Drop the `items` list from `omarchy.indicators` to show all six indicators
(adds `NightLight` and `Reminder`).

## Custom modules

The bar accepts arbitrary ids with `type: "command"`, which is how the two
AGS entry points survive the move off waybar:

- `blob.cpu` - left opens btop, middle opens alacritty, right toggles the AGS
  system monitor
- `blob.notifications` - left toggles the AGS notification center, right
  toggles notification silencing
- `blob.clock` - left toggles AGS quick settings, middle opens the shell's own
  calendar panel, right opens the timezone selector. `omarchy.clock` hardcodes
  its click actions, so matching the old waybar behavior needs a command module
  and `centerAnchor` pointed at it.

A command module with no `exec` key is a static icon; add `exec` and
`interval` for one that refreshes its own text.

## Editing

Dragging widgets in the bar rewrites `~/.config/omarchy/shell.json` directly.
That makes the live file diverge from this one, so after rearranging by hand,
copy it back:

```bash
cp ~/.config/omarchy/shell.json omarchy/shell.json
```

Run `./install.sh --check` to see whether the two have drifted.

## Not portable from waybar

- Bar height: fixed by the shell's style (26px horizontal, 28px vertical).
- Per-widget click actions on first-party widgets: `omarchy.network` and
  `omarchy.bluetooth` own their popups, so the old right-click-into-AGS
  bindings only exist on the custom modules above.
