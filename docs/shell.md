# The shell

`blob-shell` is one long-running Quickshell process hosting the bar, panels,
notifications, lock screen, OSD, and both menus. Everything runs inside it as a
plugin, so summoning a panel is an IPC call into a process that is already up.

## Layout

```
shell/
  shell.qml            entry point
  Commons/             Style, Color, Border, Util
  Ui/                  shared components
  services/            plugin registry, bar widget registry, app library
  plugins/
    bar/               the bar and its widgets
    menu/              both menus
    notifications/     daemon, popups, DND, history
    notification-center/
    lock/  polkit/  osd/  background/  clipboard/  emojis/
    image-picker/  reminders/
    panels/            audio bluetooth clock disk-speedtest monitor network
                       power quick-settings speedtest sysmon weather wifiqr
    services/          battery idle media nightlight
```

First-party plugins are discovered under `shell/plugins` at a depth of two or
three and are enabled without being listed anywhere. Third-party plugins live in
`~/.config/blob/plugins/<id>/` and are enabled through `shell.json`.

## Config

`shell.json` is the whole bar config. It hot-reloads on save, and dragging a bar
widget rewrites `~/.config/blob/shell.json` directly, so after rearranging by
hand copy it back:

```
cp ~/.config/blob/shell.json shell.json
```

`./install.sh --check` reports the drift.

Defaults live at `config/blob/shell.json`. A valid user file replaces them
entirely rather than merging.

## Bar layout

| Section | Widgets |
| --- | --- |
| left | `blob.menu`, `blob.workspaces` |
| center | `blob.clock` (anchored), `blob.system-update` |
| right | `blob.tray`, `blob.bluetooth`, `blob.network`, `blob.audio`, `blob.monitor`, `blob.power`, `blob.notifications` |

`blob.clock` and `blob.notifications` are `type: "command"` modules, which is how
they carry their own click actions: the clock opens quick settings on left click,
the shell's calendar on middle, and the timezone picker on right; the bell opens
the notification centre on left and toggles silencing on right. The bell runs
`blob-notification-bell` every 3 seconds and turns into a crossed-out bell while
notifications are silenced.

The centre module named by `centerAnchor` cannot be dragged out of the centre.
Every other widget still reorders.

## Differences from upstream

This shell was forked from Omarchy 4.0.4 and is not tracked against it. The
changes beyond renaming:

- `agents`, `tailscale`, `dropbox`, and `dev-gallery` plugins removed, about
  7,000 lines.
- The `Dictation` bar indicator removed with voice typing.
- Persistent workspaces 1-9 instead of 1-5.
- Menu cards 440 wide instead of 300, with the Blob icon on the bar button.
- The lock screen shows a large clock and the date over the blurred, dimmed
  wallpaper, then an avatar with the user's initial and name, and a rounded
  password field with a lock icon and, when enrolled, a fingerprint icon. The
  border goes to the blue slot while focused or typing and to urgent on a
  failed attempt, when the field shakes and the line under it shows the error
  and attempt count. `branding/screensaver.txt` sits faded at the bottom.
- `quick-settings`, `sysmon`, and `notification-center` are new, ported from the
  GTK widgets. See [widgets.md](widgets.md).

None of these are clones or overrides. They are edits to first-party source, so
there is no clone machinery and nothing to re-apply after an upstream release.
The fork base is recorded in [upstream.md](upstream.md).

## Debugging

```
journalctl --user -t blob-shell -f
blob-shell-restart
```

A QML error in a `service` plugin means that service never loads. For the lock
that leaves the machine unlockable rather than locked open, so test it with
`blob-shell lock lock` before trusting a change to it.
