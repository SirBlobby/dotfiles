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
| `install/steps/config.sh` | the `BLOB_PATH` symlink, everything under `~/.config`, and the login shell profile |
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
   built once with `makepkg`. A failed batch refreshes the databases and retries,
   then falls back to one package at a time, so a single name that no longer
   resolves cannot cost you the other hundred and the config, service and login
   steps below. See [packages.md](packages.md).
4. **Config** is copied into `~/.config`: `hypr/`, the themed app configs,
   `blob/shell.json`, the uwsm environment, `fontconfig/fonts.conf`, and the
   icon font, and the font cache is refreshed. The shell draws every icon as a
   Nerd Font glyph in the `monospace` family, and on a fresh Arch install
   fontconfig resolves that to a font with no such glyphs, so the bar and its
   panels come up full of blanks. `fonts.conf` binds `monospace` to
   `JetBrainsMono Nerd Font`; `blob font set` rewrites the same file, and the
   installer then reports it as a local change and keeps your choice.
   `~/.bashrc` gets one line sourcing `session/bashrc`, which is what starts
   the starship prompt and puts `blob` on `PATH` in an interactive shell. The
   line is added once, a `.bak` is kept, and a `~/.bashrc` that already has it
   is left alone.
   `session/profile.sh` also goes to `/etc/profile.d/blob.sh`, which sources
   `session/env-bootstrap` and is what puts `blob` on `PATH` in a login shell.
   Without it `BLOB_PATH` and `$BLOB_PATH/bin` are only set by
   `~/.config/uwsm/env.d/10-blob`, which uwsm reads when the graphical session
   starts, so `blob` is not found from a TTY. A shell that was already open when
   the installer ran keeps its old `PATH`; open a new one, or
   `source ~/.local/share/blob/session/env-bootstrap`.
5. **The first theme** is applied. `~/wallpapers` is symlinked to the checkout's
   `wallpapers/`, `flats` is applied with `BLOB_THEME_HEADLESS=1` (no shell or
   session bus exists yet), and the background symlink is pointed at the first
   image in `~/wallpapers`. Without this the first login has no palette and no
   wallpaper, which draws as a black desktop. It then links the per-app theme
   files the pipeline renders but no app would otherwise find:
   `~/.config/btop/themes/current.theme` (btop's `color_theme = "current"`) and,
   only when `~/.config/nvim/lua/plugins` already exists, `theme.lua` there.
   Every step is skipped when a theme, a background, a wallpaper directory or a
   theme file of your own is already in place. A theme counts as in place only
   when the staged theme under `~/.local/state/blob/current/theme` is there too,
   so a recorded theme name left without its palette is applied again rather
   than skipped.
6. **User units** land in `~/.config/systemd/user` and are enabled, not started:
   they are all `WantedBy=graphical-session.target`, so they come up with the
   session. `blob-speaker-tuning.service` is left out, because
   `blob-audio-tuning` installs it only on machines with a tuning profile.
7. **systemd drop-ins** are written under `/etc`: the shutdown timeouts, the
   oomd pressure thresholds, the plocate prune paths, and the sleep hooks.
8. **System services** are enabled: NetworkManager, resolved, bluetooth, cups,
   avahi, docker, power-profiles-daemon, and oomd.
   `NetworkManager-wait-online.service` is masked so a slow DHCP lease cannot
   hold up the login screen, and `plymouth-start.service` and
   `plymouth-quit-wait.service` are masked because Blob configures no boot
   splash: an unconfigured plymouth holds the console and leaves the machine
   with neither a greeter nor a TTY. See [packages.md](packages.md).
9. **The login screen** is SDDM. It has to be installed first: if
   `sddm.service` is not there, the installer says whether the package is
   missing or whether systemd has simply not re-read its units yet, and carries
   on without enabling anything. A unit counts as present when `systemctl cat`
   finds it or when its file is under `/etc/systemd/system`,
   `/run/systemd/system`, `/usr/local/lib/systemd/system` or
   `/usr/lib/systemd/system` - `systemctl` goes through the service manager, so
   it reports a perfectly good unit as missing inside a chroot or right after
   pacman wrote it.

   Three pieces have to be in place:

   | File | Why |
   | --- | --- |
   | `/usr/local/share/wayland-sessions/blob.desktop` | the session SDDM offers |
   | `/etc/sddm.conf.d/zz-blob.conf` | Wayland greeter, run on Hyprland, stock theme, remember the last session |
   | `/etc/sddm/hyprland-greeter.lua` | the greeter's own tiny Hyprland config |
   | `/usr/local/bin/blob-hw-gpu-accelerated` | the renderer check that config runs, where SDDM's user can read it |
   | `/etc/pam.d/blob-lock-password` | the PAM stack the lock screen authenticates against |

   The greeter config matters more than it looks: SDDM's stock Wayland greeter
   runs on `weston`, which Blob does not install, so a default SDDM would fail
   to draw anything. The installer checks that the `CompositorCommand` named in
   `zz-blob.conf` is actually installed and warns when it is not, because SDDM
   with a compositor command it cannot run starts, fails, and leaves the machine
   sitting at a text console with no explanation. That greeter config has to be Lua: Hyprland dropped the old
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
10. **Launch.** `sddm`, `hyprland`, `quickshell` and `uwsm` are checked one last
    time and any that are missing are named, because that is the whole difference
    between a desktop and a console. Then, when the installer was run from a
    console and nothing graphical is running, it starts `sddm.service` so the
    desktop appears without a reboot. `--no-launch` prints the command instead.
    `--autologin` writes `/etc/sddm.conf.d/zzz-blob-autologin.conf` for the
    current user.

## Flags

| Flag | Effect |
| --- | --- |
| `--check` | report every change, write nothing, exit 1 if anything differs |
| `--force` | overwrite files that differ from the repo copy |
| `--skip-packages` | directories, config and services only |
| `--autologin` | skip the SDDM prompt for this user |
| `--no-launch` | leave the login screen for the next reboot |

## The lock screen

The lock plugin watches `/etc/pam.d/blob-lock-password` and refuses to lock at
all when it is not there - `blob system lock` returns `missing-pam` and nothing
appears, which reads as a keybinding that does nothing. The installer writes it;
it is one line including `system-auth`, the same stack every other Wayland
locker on Arch authenticates against.

Fingerprint unlock is separate and opt-in: `blob setup-security-fingerprint`
writes `/etc/pam.d/blob-lock-fingerprint`, and the lock only offers fingerprint
when that file and a reader are both present.

## Choosing a renderer

Hyprland renders through Mesa, and on an adapter Mesa has no driver for it exits
with `failed to create dri2 screen` instead of drawing. The greeter is Hyprland
too, so that is a black screen at boot and a second one after login, which is
how a machine with no real GPU behind its display arrives.

`blob-hw-gpu-accelerated` decides which way to go. It reads the kernel driver of
each `/sys/class/drm/card*` from sysfs, not from `lspci`, which reads PCI config
space and resumes runtime-suspended GPUs. A card driven by `amdgpu`, `i915`,
`nouveau`, `nvidia`, `nvidia-drm`, `radeon` or `xe` is a real integrated or
dedicated GPU and hardware rendering is left alone. Everything else - `vmwgfx`,
`vboxvideo`, `qxl`, `bochs-drm`, `cirrus`, `simpledrm`, `vkms`, `virtio_gpu` -
is virtual or framebuffer-only, and two settings are applied:

| Setting | Effect |
| --- | --- |
| `LIBGL_ALWAYS_SOFTWARE=1` | Mesa uses llvmpipe, which renders on the CPU |
| `WLR_NO_HARDWARE_CURSORS=1`, `cursor:no_hardware_cursors` | the cursor is drawn by the compositor, since there is no plane to put it on |

llvmpipe is slow and it draws. A machine with a real GPU never touches it.

Two places read the detector, because they run as different users:

| Where | How |
| --- | --- |
| the session | `default/hypr/renderer.lua`, required from `envs.lua` beside `nvidia.lua`, through `$BLOB_PATH/bin` |
| the greeter | `default/sddm/hyprland-greeter.lua`, through `/usr/local/bin/blob-hw-gpu-accelerated` |

The greeter runs as SDDM's own user, with no `BLOB_PATH` and no read access to
your home directory, so `install.sh` copies the detector to `/usr/local/bin`.
A detector that is not there yet reads as no acceleration, which is the fallback
that always draws.

To add a driver to the accelerated list, edit `accelerated_drivers` in
`bin/blob-hw-gpu-accelerated` and rerun `./install.sh` so the greeter's copy
follows. `virtio_gpu` is deliberately not on it: QEMU only accelerates it when
the host enables virgl, and Mesa fails the same way when it does not.

To see the difference by hand, from a console:

```bash
Hyprland                          # fails with the dri2 error
LIBGL_ALWAYS_SOFTWARE=1 Hyprland  # starts
```

## Uninstall

`./uninstall.sh` removes the config, the user units, the `/etc` drop-ins, the
session entry, the wallpaper link and the symlink, restoring any `.bak` the
installer left. `--keep-session` keeps the session entry and the SDDM config,
`--keep-state` keeps `~/.local/state/blob`. `sddm.service` is left enabled either way, so the
machine still reaches a login screen.
