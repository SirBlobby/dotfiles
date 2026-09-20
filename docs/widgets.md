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
| Notification centre | left-click the bar bell |
| System monitor | `Super + Ctrl + M` |

Both new bar click actions are already in `shell.json`. The system monitor had no
bar entry point in the AGS setup either, so the keybinding is how it is reached.

## Deliberately not ported

The tiles still poll shell commands the way the GTK widgets did - `pamixer` for
volume, `brightnessctl` for brightness, `playerctl` for media - rather than
binding to the shell's own audio, brightness and media services. Polling only
runs while a panel is open, so the cost is bounded, but wiring these to the
services is the obvious next refinement and would remove the last per-tick
process spawns.
