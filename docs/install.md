# Install

`./install.sh` takes a machine with nothing but Arch on it to a running Blob
desktop. Every step is idempotent, reports what it did, and can be previewed
with `--check`.

## Layout

| Path | Role |
| --- | --- |
| `bootstrap.sh` | one-command install on a bare machine: installs git, clones, runs `install.sh` |
| `install.sh` | flags and the order the steps run in |
| `install/helpers/lib.sh` | reporting, sections, the warning summary, file copies, unit queries |
| `install/steps/preflight.sh` | the checks that stop a run early, and the sudo keepalive |
| `install/helpers/as-root.sh` | `as_root`, a no-op when already root |
| `install/steps/directories.sh` | the directories the shell and scripts expect |
| `install/steps/packages.sh` | repo and AUR packages, and the yay bootstrap |
| `install/steps/config.sh` | the `BLOB_PATH` symlink, everything under `~/.config`, and the login shell profile |
| `install/steps/shell.sh` | the executable bit on `bin/` scripts, and new bar widgets added to an existing `shell.json` |
| `install/steps/services.sh` | system services, systemd drop-ins, user units |
| `install/steps/boot.sh` | the Plymouth boot splash, GRUB, and other-OS detection |
| `install/steps/theme.sh` | the wallpaper link, the first theme, the first background |
| `install/steps/apps.sh` | default applications for images, video, PDFs, office files, text and archives, with the file types read from `default/mime/` |
| `install/steps/login.sh` | SDDM, the session entry, and the first launch |
| `install/steps/reload.sh` | reloading systemd, the user services, and a running session |

## Steps

0. **Preflight** stops before anything is written when the installer is run as
   root (it installs into `$HOME`, and `makepkg` refuses to build as root), when
   `pacman` is missing, when `sudo` does not accept the user, or when
   `archlinux.org` cannot be reached and packages are wanted. It warns when
   `systemd-networkd`, `iwd`, `dhcpcd` or `netctl` is enabled, because
   NetworkManager is enabled below and two network managers fight over the same
   interface after a reboot. `archinstall`'s "copy ISO network config" option
   leaves exactly that behind. Once sudo is accepted it is refreshed every
   minute in the background, so a long AUR build does not stop halfway for a
   password.
1. **Directories** are created first, because nothing below can write into a
   directory that is not there: `~/.config/blob`, `~/.config/systemd/user/app.slice.d`,
   `~/.local/state/blob`, `~/.local/share` and `~/.cache/blob`. A fresh Arch
   install has none of them.
2. **`BLOB_PATH`** is symlinked to the checkout at `~/.local/share/blob`. Nothing
   under `bin/`, `shell/`, `themes/` or `default/` is ever copied. `ln` does not
   create the parent of a link, so this step makes `~/.local/share` itself rather
   than assuming step 1 ran. Any script in `bin/` that lost its executable bit
   gets it back.
3. **Packages** come from `packages/blob.packages` and
   `packages/blob-aur.packages`. Repo packages go in with a full
   `pacman -Syu`, never a partial upgrade. A machine with no AUR helper gets
   `yay-bin` built once with `makepkg`. A failed batch upgrades the system on
   its own, then falls back to one package at a time, so a single name that no longer
   resolves cannot cost you the other hundred and the config, service and login
   steps below. See [packages.md](packages.md).
4. **Config** is copied into `~/.config`: `hypr/`, the themed app configs,
   `blob/shell.json`, the uwsm environment, `fontconfig/fonts.conf`, and
   `pipewire/pipewire.conf.d/50-blob-noise-suppression.conf`. That last file
   adds a "Noise Suppressed Microphone" input, which runs the default
   microphone through RNNoise from `noise-suppression-for-voice`; PipeWire
   loads it at its next start, and apps use it when it is picked as their
   input. A
   leftover Omarchy icon font in `~/.local/share/fonts` is removed, and the
   font cache is refreshed. The shell draws every icon as a Nerd Font glyph in
   the `monospace` family, and on a fresh Arch install
   fontconfig resolves that to a font with no such glyphs, so the bar and its
   panels come up full of blanks. `fonts.conf` binds `monospace` to
   `JetBrainsMono Nerd Font`; `blob font set` rewrites the same file, and the
   installer then reports it as a local change and keeps your choice.
   A `shell.json` you already have is kept, but widgets listed in
   `bar_widgets` in `install/steps/shell.sh` are added to it when missing, each
   after the widget it names (or at the start of the right section), with a
   `.bak` of the previous file. That is how `blob.agents` reaches an existing
   bar.
   Launcher entries in `applications/desktop/` go to `~/.local/share/applications`
   and their icons in `applications/icons/` to `~/.local/share/icons/hicolor/32x32/apps`;
   that is how the Draw web app is installed.
   Default applications are set in `~/.config/mimeapps.list`: Loupe for
   images, `mpv` for video and audio, `evince` for PDFs and other documents, LibreOffice for
   documents, spreadsheets and presentations, GNOME Text Editor for text, and
   File Roller for archives. A file type that already has a
   default there is left alone. The file types for each group are listed in
   `default/mime/<group>.types`, and Setup > Defaults in the Blob menu changes
   the image viewer, video player and PDF viewer later. See
   [packages.md](packages.md#desktop-applications).
   `~/.bashrc` gets one line sourcing `session/bashrc`. The line is added once,
   a `.bak` is kept, and a `~/.bashrc` that already has it is left alone.
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
   `/etc/NetworkManager/conf.d/10-blob-wifi-powersave.conf` turns Wi-Fi power
   saving off, and NetworkManager is reloaded when it changes.
8. **System services** are enabled: NetworkManager, resolved, bluetooth, cups,
   avahi, docker, power-profiles-daemon, and oomd.
   `NetworkManager-wait-online.service` is masked so a slow DHCP lease cannot
   hold up the login screen, and `plymouth-start.service` and
   `plymouth-quit-wait.service` are masked because an unconfigured plymouth
   holds the console and leaves the machine with neither a greeter nor a TTY.
   The installer then applies `branding/blob_boot.png` as the boot splash
   through `blob boot`, which installs the theme, adds the mkinitcpio hook,
   unmasks the plymouth units, rebuilds the initramfs, and sets GRUB up with
   os-prober so other installed systems appear in the boot menu. It is skipped when
   the blob theme is already the default with the same image, and once it is
   in place the plymouth units are no longer masked on later runs. See
   [packages.md](packages.md#the-boot-splash).
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
   | `/etc/sddm.conf.d/zz-blob.conf` | Wayland greeter, run on Hyprland, Blob theme, remember the last session |
| `/usr/share/sddm/themes/blob/` | the Blob login screen, from `default/sddm/blob/` and `branding/blob_icon.svg` |
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
   override Blob's. For the same reason `zz-blob.conf` pins `Theme` to `blob`
   and blanks `Autologin`: a greeter pointed at an uninstalled theme, or an autologin
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
10. **Reload.** systemd re-reads its units and `systemd-oomd` is restarted so
    the new drop-ins apply. The user manager is reloaded and every Blob user
    service that is running is restarted. When a Hyprland session is running
    for this user, the current theme is rendered again with
    `blob-theme-refresh`, Hyprland reloads its config, and the Blob shell
    restarts, so an install over a live desktop takes effect without logging
    out. The shell restart is refused while the screen is locked. Nothing that
    was stopped is started, and `--check` only reports what would reload.
11. **Launch.** `sddm`, `hyprland`, `quickshell` and `uwsm` are checked one last
    time and any that are missing are named, because that is the whole difference
    between a desktop and a console. Then, when the installer was run from a
    console and nothing graphical is running, it offers a reboot, which brings
    up NetworkManager, the boot splash and any new kernel modules together.
    Declining starts `sddm.service` so the desktop appears without one.
    `--no-launch` prints the command instead. Every warning from the run is
    listed again just before this step.
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

## The interactive shell

`session/bashrc` is sourced from `~/.bashrc` and returns immediately in a
non-interactive shell, so it cannot disturb `scp` or `rsync`. It does four
things, the first three only when the tool is installed:

| Line | Effect |
| --- | --- |
| `session/env-bootstrap` | `BLOB_PATH` and `$BLOB_PATH/bin` on `PATH`, so `blob` resolves |
| `starship init bash` | the themed prompt, see [themes.md](themes.md#the-prompt) |
| `zoxide init bash --cmd cd` | `cd` learns the directories you actually use |
| `powerprofilesctl` function | runs it on `/usr/bin/python3`, since a mise Python ahead on `PATH` has no `gi` module |

`--cmd cd` replaces `cd` rather than adding a `z` command, so
`cd blomarchy` jumps to the last matching directory you have visited from
anywhere, while `cd ./relative/path`, `cd -` and `cd` with no argument keep
behaving exactly as the builtin does. `cdi` picks from the matches
interactively through `fzf`, and `zoxide query -ls` prints the database.

The database is built as you go: it learns a directory the first time you `cd`
there, so the jumping is only as good as the history behind it and a fresh
install knows nothing yet.

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
