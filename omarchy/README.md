# Omarchy config

Omarchy 4 replaced waybar with the Quickshell bar built into `omarchy-shell`.
`shell.json` is the whole bar config; it hot-reloads on save, and
`install.sh` deploys it to `~/.config/omarchy/shell.json`.

## Bar layout

Ported from the old `waybar/config.jsonc`, section for section:

| Old waybar module | shell.json widget |
| --- | --- |
| `custom/omarchy` | `omarchy.menu` |
| `hyprland/workspaces` | `blob.workspaces` (cloned plugin) |
| `clock` | `blob.clock` (custom module) |
| `custom/update` | `omarchy.system-update` |
| `custom/voxtype` | dropped (voxtype is not installed) |
| `custom/screenrecording-indicator` | AGS quick settings -> Record tile |
| `custom/idle-indicator` | AGS quick settings -> Stay Awake tile |
| `custom/notification-silencing-indicator` | AGS quick settings -> Silence tile |
| `group/tray-expander` | `omarchy.tray` |
| `bluetooth` | `omarchy.bluetooth` |
| `network` | `omarchy.network` |
| `pulseaudio` | `omarchy.audio` |
| `battery` | `omarchy.power` |
| `cpu` | `blob.cpu` (custom module) |
| `custom/notification` | `blob.notifications` (custom module) |
| (new in Omarchy 4) | `omarchy.agents` - AI agent usage |
| (new in Omarchy 4) | `omarchy.monitor` - brightness and display controls |

The bar carries no `omarchy.indicators` widget: those four toggles live in the
AGS quick settings panel instead, so the bar keeps only the clock and the
update indicator in its center. Add `{ "id": "omarchy.indicators" }` back to
`center` to restore them (omit `items` for all six, which adds `NightLight`
and `Reminder`).

## Idle timings

`idle.screensaver` and `idle.lock` are both counted from the moment the session
goes idle, not from each other. The screensaver is what paints
`branding/screensaver.txt` across every monitor, so the two values need a real
gap between them or the lock screen covers the branding as soon as it appears.
Screensaver at 300 and lock at 900 leaves ten minutes of branding before the
session locks.

Neither timer runs while `~/.local/state/omarchy/indicators/stay-awake` exists.
That file is the Stay Awake toggle, it is runtime state rather than config so
it is not tracked here, and while it is set the idle service cancels every
cycle with `idle-cycle-cancel: stay-awake`. `omarchy-toggle-idle allow-idle`
clears it. The lock screen carries the branding on its own (see
`plugins/blob.lock/` below), so this only affects the screensaver.

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

## Cloned plugins

`blob.workspaces` and `blob.menu` were made with `omarchy plugin clone`, which
copies a built-in plugin, disables the original, and points the bar at the copy
- hence the `blob.` ids in `shell.json`. `blob.bar` and `blob.lock` were copied
by hand; see below for why.

`plugins/blob.workspaces/` clones `omarchy.workspaces`. The stock widget
hardcodes workspaces 1-5 as always visible and has no setting for it, so the
clone changes that list to 1-9 to match the old waybar `persistent-workspaces`.

`plugins/blob.menu/` clones `omarchy.menu` to widen it, to let a menu row
choose where it sits, and to put the Blob icon on the bar button. `cardWidth` in `Menu.qml` is hardcoded at
`Style.space(300)`; the clone raises it to 440, so the apps menu (Super + Space)
and the root menu (Super + Alt + Space) are both wider. The two oversized menus
(screen recording, font picker) keep their own 520 and are untouched.
`omarchy-menu` still targets `omarchy.menu` on the CLI - the manifest records
`clonedFrom`, and the shell routes those calls here.

`BarWidget.qml` swaps the stock `\ue900` glyph from the `omarchy` icon font for
`branding/blob_icon.svg`. Qt renders SVG through `qt6-svg`, but an `Image`
cannot be recolored, so the icon is used as an alpha mask over a rectangle
filled with the bar foreground. That keeps it following the theme and the bar's
own color animation the way a glyph did, and it means the black fill in the
source file never matters.

`mergeMenuSources` in `MenuModel.js` reads the default menu first and the user
extension second, so a row that only exists in `extensions/omarchy-menu.jsonc`
lands at the bottom of its menu with no way to move it. The clone adds a
`before:` key naming another row's id, and `applyBeforeHints` moves the row
ahead of it once both sources are merged - which is how `Blob` sits directly
under `Apps` instead of below `System`. A `before:` that names an unknown id is
ignored, and a row without one keeps its file order.

`plugins/blob.lock/` clones `omarchy.lock` to put `branding/screensaver.txt` on
the lock screen and to restyle the password field like the AGS widgets. Stock
`LockView.qml` draws a blurred wallpaper, the field, and a fingerprint hint -
there is no branding element and no config key for one, so a fork is the only
way in.

The fork is three small changes. `BrandingSource.qml` is new and holds both
file reads: the branding text, and the `color4` slot parsed out of the active
theme's `colors.toml`. `Color` resolves a palette down to `foreground`,
`background`, `accent`, `urgent`, and `muted` and never exposes `color4`, which
is the color AGS borders with. Stock `Color` reads that file once at startup
and takes theme switches over IPC, but
`~/.local/state/omarchy/current/theme` is a real directory rewritten in place
rather than a swapped symlink, so watching the file is enough here.
`Service.qml` gains only that component and two bindings on each of its two
`LockView` instances (the lock surface and the theme preview). `LockView.qml`
gains a `Text` above the field, and the field's own skin.

The styling follows `ags/style.css`: a 2px border and square corners in place
of the shell's 3px rounded outline, an `alpha(background, 0.6)` fill matching
`.qs-tile`, and the AGS border pair - `alpha(color4, 0.5)` while the field is
empty, going to a solid `accent` once there is something in it, and `urgent` on
a failed attempt. Only the geometry and the alphas are fixed; the colors come
from the active theme, so the field follows a theme change the way the AGS
widgets do. The `[lock]` tokens in a theme's `shell.toml` no longer reach the
border or the fill. `Text.Fit` scales the branding into whatever room is left
above the field, so a wider or taller `screensaver.txt` cannot run off the
screen, and a missing file leaves the lock unbranded rather than broken.

Unlike the other clones this one is load-bearing for security. The lock is a
`service` plugin, so it is enabled by its id appearing in `plugins[]` and the
original is switched off through `disabledPlugins[]` - both are needed, because
the two would otherwise register the same `lock` IPC target. There is no
fallback: a QML error means the service never loads and `omarchy-shell lock
lock` silently does nothing, which leaves the machine unlockable rather than
locked open. `journalctl --user -t omarchy-shell` names the fault as
`service plugin load failed for blob.lock`. To back out, drop `blob.lock` from
`plugins[]` and `omarchy.lock` from `disabledPlugins[]`; `cloneSourceRestores`
lists `blob.lock` so the shell restores the original by itself if the clone is
removed through `omarchy plugin remove`.

Re-copy `LockView.qml` and `Service.qml` from
`/usr/share/omarchy/shell/plugins/lock/` after an Omarchy update that touches
the lock, then re-apply the two blocks above. `BrandingSource.qml` is wholly
ours and carries over untouched.

`plugins/blob.bar/` replaces the whole bar so the clock cannot be dragged out
of the center. Omarchy 4 puts a drag-to-reorder handler on every bar module and
persists the drop into `bar.layout`; once `blob.clock` leaves the center list,
`centerAnchor` matches nothing and the center renders as a plain group. The bar
config has no setting for this, so the only lever is `canReorder` in `Bar.qml`.
The lock itself is two lines: an `anchored` property on `ModuleSlot`, and
`canReorder` gated on it, so only the module named by `centerAnchor` is pinned.
Every other widget still drags.

Three more lines are needed just to make the file loadable outside the packaged
slot. Stock `Bar.qml` declares `omarchyPath`, `barWidgetRegistry`, and
`barConfig` as `required`, which only works for the built-in bar because the
host instantiates it from an inline `Component` that sets them. A plugin bar is
loaded by URL and configured in the loader's `onLoaded`, so the required
properties are still unset at construction and the whole bar fails to build.
The copy declares them as ordinary properties defaulting to `""`/`null`, and
guards the one `barWidgetRegistry.widgets` read; `applyBarConfig` already falls
back to an empty layout, so nothing renders until the host injects the real
config a moment later.

When this happens the bar does not fall back to the stock one, it simply does
not appear: the host's `Loader.Error` branch calls a nonexistent `errorString`,
throws, and never sets `failedBarId`. If the bar ever vanishes after editing
this plugin, that is the first thing to check - `journalctl --user` will name
the offending property.

Do not run `omarchy plugin clone omarchy.bar` to refresh it. That command copies
the whole directory, including `widgets/`, whose manifests re-declare
`omarchy.workspaces`, `omarchy.tray`, and four more ids that already exist.
`Bar.qml` needs only `BarModel.js` - its widgets come from the host registry -
so the copy is just `manifest.json`, `Bar.qml`, and `BarModel.js`. A bar is
selected by `bar.id` in `shell.json` rather than by the enabled-plugin list, and
it has no disabled state: you leave one bar by naming another.

Re-copy after an Omarchy update if the upstream widget or bar gains something
worth picking up: `omarchy plugin clone omarchy.workspaces` then re-apply the
one-line `workspaceIds()` change, or copy `Bar.qml` and `BarModel.js` from
`/usr/share/omarchy/shell/plugins/bar/` and re-apply the two `canReorder` lines.

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
