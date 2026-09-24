# Ported widgets

The GTK widgets that used to run as a separate AGS process are now plugins
inside the shell. A panel opens over IPC into a process that is already running
rather than starting a second toolkit, and `ags` is no longer installed or
autostarted.

## Where each one went

| Was | Is | Note |
| --- | --- | --- |
| `QuickSettings.tsx` (523 lines) | `shell/plugins/panels/quick-settings/` | split across 9 files, none over 250 lines |
| `SysMonitor.tsx` (142) | `shell/plugins/panels/sysmon/` | CPU, memory, disk, temperature |
| `Notifications.tsx` (160) | `shell/plugins/notification-center/` | reads the notification service's own history files |
| `WallPicker.tsx` (106) | the existing image picker | `blob-wallpaper-set --menu` now calls `blob-menu-images`, so wallpapers get the image grid instead of a text list |
| `ThemePicker.tsx` (178) | the menu and `blob-theme-switcher` | the shell already had a theme switcher; a second picker was duplicate surface |
| `ClaudeUsage.tsx` (372) | dropped | it existed to read agent usage records, and the agents feature is gone |
| `Media.tsx` (104) | dropped | `SHOW_DESKTOP_MEDIA` was already false, and the quick settings media row covers it |
| `WidgetCard.tsx` (22) | `Ui/Card.qml`, `Ui/CardHeader.qml`, `Ui/StatRow.qml` | shared, so no plugin repeats the card |
| `style.css` (759) | `Commons/Style.qml` tokens | see below |

## The look

`ags/style.css` was the visual identity worth keeping: square corners, a 2px
border, and an `alpha(background, 0.6)` fill. Those are now named tokens on
`Style` - `cardBorderWidth`, `cardRadius`, `cardFillAlpha`, `cardBorderAlpha`,
`panelFillAlpha` - so every ported panel reads the same numbers instead of
repeating literals.

The CSS was written against pywal's `@color0`, `@color4` and `@color5` aliases.
`blob-theme-color` resolves `color4` to blue and `color5` to magenta, so
`Commons/Color.qml` now exposes `blue` and `magenta` with that same cascade,
falling back to `accent` for themes that define neither. `color0` is
`background`, which Color already had.

## Opening them

| Panel | Opened by |
| --- | --- |
| Quick settings | left-click the bar clock, or `Super + Ctrl + Q` |
| Notification centre | left-click the bar bell; right-click silences notifications, and the bell is crossed out while they are |
| System monitor | `Super + Ctrl + M` |

Both new bar click actions are already in `shell.json`. The system monitor had no
bar entry point in the AGS setup either, so the keybinding is how it is reached.

## Quick settings

The control centre is centred on the screen, with the weather card to its left.
Its tiles fill the card width in three columns, and every tile and card button
draws a JetBrainsMono Nerd Font glyph over a light foreground fill with a thin
border, so they read against the panel in any theme. An active tile takes the
accent colour. The Wallpaper tile opens `blob.displays`, the Theme tile opens
`blob theme menu`.

## Deliberately not ported

The tiles still poll shell commands the way the GTK widgets did - `pamixer` for
volume, `brightnessctl` for brightness, `playerctl` for media - rather than
binding to the shell's own audio, brightness and media services. Polling only
runs while a panel is open, so the cost is bounded, but wiring these to the
services is the obvious next refinement and would remove the last per-tick
process spawns.

## Display layout

`blob.display-layout` arranges monitors. Opened with `Super + Shift + Ctrl + D`
or the Blob menu's Display layout row.

A scaled picture of the desktop, one draggable rectangle per monitor. Dropping
one applies the new position immediately. Edges snap to a neighbour's edge
within 60 logical pixels, so monitors end up touching exactly. Per-monitor
controls: mode, scale, enable or disable, and mirror. The panel
shrinks to fit the screen, and when a monitor reports more modes than fit, the
controls scroll while the canvas and the apply buttons stay in view.

**Scale options are filtered, not free.** Hyprland steps fractional scaling in
1/120 and rejects a scale that does not land on a whole number of physical
pixels on both axes. `DisplayModel.scaleIsValid` applies that rule, so only
usable scales are offered. On a 1920x1080 panel that means 1.0 and 1.2 are
adjacent with nothing between them, which is the constraint `hypr/monitors.lua`
documents by hand.

**Nothing is written to `monitors.lua`.** Every change goes through
`hyprctl keyword monitor` and lasts until the config reloads or the session
ends. "Reset to monitors.lua" runs `hyprctl reload` and makes the checked-in
config authoritative again. To keep a layout, edit `monitors.lua` yourself -
`blob display arrange list` prints the current layout in the exact keyword form,
ready to copy.

Rotation and primary-monitor selection are not implemented. `DisplayModel` reads
`transform` and round-trips it, so a rotated monitor is drawn and preserved
correctly, but nothing in the widget sets it.

## Wallpapers

`blob.displays` picks wallpapers. Opened with `Super + Alt + W`, the quick
settings Wallpaper tile, or the Blob menu's Wallpaper row.

A thumbnail grid of `~/wallpapers` that fits as many columns of at least 120px
as the panel allows and stretches them to its full width, with a row of chips
selecting the target:
"All monitors" sets the global wallpaper through `blob-bg-set`, and a specific
output assigns just that monitor through `blob-bg-monitor`, which symlinks the
image under `~/.local/state/blob/backgrounds/<output>`. An output with its own
wallpaper is marked with an asterisk.

`blob.background` already drew one window per screen but pointed them all at the
same image. It now resolves per screen: a monitor with an assignment shows it,
and a monitor without one shows the global wallpaper. The crossfade machinery
stays on the global path only, so an assigned monitor swaps without the reveal
animation rather than risking that code.

| Command | Does |
| --- | --- |
| `blob bg set <image>` | set the global wallpaper |
| `blob bg monitor <output> <image>` | assign a wallpaper to one monitor |
| `blob bg monitor <output> --clear` | fall back to the global wallpaper |
| `blob bg monitor --list` | show assignments |
| `blob display arrange list` | print the layout as monitor keywords |
| `blob display arrange apply <kw>` | apply a keyword now |
| `blob display arrange reset` | reload, restoring monitors.lua |

Both widgets share `Ui/Chip.qml`, `Ui/Card.qml` and `Ui/CardIconButton.qml`
rather than carrying their own copies.
