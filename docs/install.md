# Install

`./install.sh` takes a machine with nothing but Arch on it to a running Blob
desktop. Every step is idempotent, reports what it did, and can be previewed
with `--check`.

## Layout

| Path | Role |
| --- | --- |
| `install.sh` | flags and the order the steps run in |
| `install/helpers/lib.sh` | reporting, file copies, unit queries |
| `install/helpers/as-root.sh` | `as_root`, a no-op when already root |
| `install/steps/directories.sh` | the directories the shell and scripts expect |
| `install/steps/packages.sh` | repo and AUR packages, and the yay bootstrap |
| `install/steps/config.sh` | the `BLOB_PATH` symlink and everything under `~/.config` |
| `install/steps/services.sh` | system services, systemd drop-ins, user units |
| `install/steps/theme.sh` | the wallpaper link, the first theme, the first background |
| `install/steps/login.sh` | SDDM, the session entry, and the first launch |

## Steps

1. **Directories** are created first, because nothing below can write into a
   directory that is not there: `~/.config/blob`, `~/.config/systemd/user/app.slice.d`,
   `~/.local/state/blob`, `~/.local/share` and `~/.cache/blob`. A fresh Arch
   install has none of them.
2. **`BLOB_PATH`** is symlinked to the checkout at `~/.local/share/blob`. Nothing
   under `bin/`, `shell/`, `themes/` or `default/` is ever copied. `ln` does not
   create the parent of a link, so this step makes `~/.local/share` itself rather
   than assuming step 1 ran.
3. **Packages** come from `packages/blob.packages` and
   `packages/blob-aur.packages`. A machine with no AUR helper gets `yay-bin`
   built once with `makepkg`. See [packages.md](packages.md).
4. **Config** is copied into `~/.config`: `hypr/`, the themed app configs,
   `blob/shell.json`, the uwsm environment, and the icon font.
5. **The first theme** is applied. `~/wallpapers` is symlinked to the checkout's
   `wallpapers/`, `flats` is applied with `BLOB_THEME_HEADLESS=1` (no shell or
   session bus exists yet), and the background symlink is pointed at the first
   image in `~/wallpapers`. Without this the first login has no palette and no
   wallpaper, which draws as a black desktop. All three steps are skipped when a
   theme, a background or a wallpaper directory of your own is already there.
6. **User units** land in `~/.config/systemd/user` and are enabled, not started:
   they are all `WantedBy=graphical-session.target`, so they come up with the
   session. `blob-speaker-tuning.service` is left out, because
   `blob-audio-tuning` installs it only on machines with a tuning profile.
7. **systemd drop-ins** are written under `/etc`: the shutdown timeouts, the
   oomd pressure thresholds, the plocate prune paths, and the sleep hooks.
8. **System services** are enabled: NetworkManager, resolved, bluetooth, cups,
   avahi, docker, power-profiles-daemon, and oomd.
   `NetworkManager-wait-online.service` is masked so a slow DHCP lease cannot
   hold up the login screen.
9. **The login screen** is SDDM. Three pieces have to be in place:

   | File | Why |
   | --- | --- |
   | `/usr/local/share/wayland-sessions/blob.desktop` | the session SDDM offers |
   | `/etc/sddm.conf.d/zz-blob.conf` | Wayland greeter, run on Hyprland, stock theme, remember the last session |
   | `/etc/sddm/hyprland-greeter.lua` | the greeter's own tiny Hyprland config |

   The greeter config matters more than it looks: SDDM's stock Wayland greeter
   runs on `weston`, which Blob does not install, so a default SDDM would fail
   to draw anything. That greeter config has to be Lua: Hyprland dropped the old
   hyprlang format, and a config it cannot parse leaves the greeter with no
   compositor and the screen black. `sddm.service` is enabled and the default
   systemd target is set to `graphical.target`, which an Arch install without a
   display manager does not have.

   The `zz-` prefix is load-bearing. SDDM reads `/etc/sddm.conf.d` in
   alphabetical order and the last file wins, so a leftover `10-wayland.conf`,
   `10-theme.conf` or `autologin.conf` from another desktop would otherwise
   override Blob's. For the same reason `zz-blob.conf` blanks `Theme` and
   `Autologin`: a greeter pointed at an uninstalled theme, or an autologin
   pointed at a session entry that no longer exists, leaves SDDM on a black
   screen it never falls back from, and the only way in is a TTY.

   The Omarchy ISO wrote exactly such an autologin, owned by no package, so it
   outlives Omarchy. The installer reports it and overrides it; deleting it stops
   the warning:

   ```bash
   sudo rm /etc/sddm.conf.d/autologin.conf
   ```

   `--autologin` writes `zzz-blob-autologin.conf`, the only file that sorts after
   `zz-blob.conf`.
10. **Launch.** When the installer was run from a console and nothing graphical
    is running, it starts `sddm.service` so the desktop appears without a reboot.
    `--no-launch` prints the command instead. `--autologin` writes
    `/etc/sddm.conf.d/zzz-blob-autologin.conf` for the current user.

## Flags

| Flag | Effect |
| --- | --- |
| `--check` | report every change, write nothing, exit 1 if anything differs |
| `--force` | overwrite files that differ from the repo copy |
| `--skip-packages` | directories, config and services only |
| `--autologin` | skip the SDDM prompt for this user |
| `--no-launch` | leave the login screen for the next reboot |

## Uninstall

`./uninstall.sh` removes the config, the user units, the `/etc` drop-ins, the
session entry, the wallpaper link and the symlink, restoring any `.bak` the
installer left. `--keep-session` keeps the session entry and the SDDM config,
`--keep-state` keeps `~/.local/state/blob`. `sddm.service` is left enabled either way, so the
machine still reaches a login screen.
