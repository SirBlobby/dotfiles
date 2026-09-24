# Packages

## Leaving the Omarchy repository

Omarchy ships its own binary repository, added to `/etc/pacman.conf`:

```
[omarchy]
Server = https://pkgs.omarchy.org/stable/$arch
```

Thirty-one installed packages came from it. `blob-repo-migrate` moves off it.
Run it dry first; it changes nothing without `--apply`:

```
blob repo-migrate
blob repo-migrate --apply
```

It refuses to run if the stock `linux` package is not installed, because it
removes `linux-omarchy`.

## What happens to each package

### Removed (15)

Omarchy's own software, plus one hardware helper this machine has no use for:

`omarchy`, `omarchy-keyring`, `omarchy-settings`, `omarchy-nvim`, `omacalc`,
`omacut`, `omawrite`, `tensaku`, `tobi-try`, `cliamp`, `herdr`, `ttfx`,
`linux-omarchy`, `linux-omarchy-headers`, `asdcontrol`.

`linux-omarchy` was installed but not booted - the running kernel is stock
`core/linux`, so the machine is not relying on it. `asdcontrol` sets brightness
on Apple Studio Displays and is reachable only from
`blob-brightness-display-apple`.

### Replaced (2)

| From | To | Where |
| --- | --- | --- |
| `ttf-jetbrains-mono-nerd-basic` | `ttf-jetbrains-mono-nerd` | official `extra` |
| `hyprland-preview-share-picker` | `hyprland-preview-share-picker-git` | AUR |

The first is Omarchy's trimmed build of a font Arch ships in full.

### Kept, from the AUR (14)

`aether`, `limine-mkinitcpio-hook`, `limine-snapper-sync`, `localsend`,
`minecraft-launcher`, `mise-bin`, `spotify`, `ttf-ia-writer`, `tzupdate`,
`ufw-docker`, `visual-studio-code-bin`, `xdg-terminal-exec`, `yaru-icon-theme`,
`yay`.

All exist in the AUR under the same name. Once the repository is gone, pacman
treats them as foreign and `yay` picks them up, so `blob update` rebuilds them
from source. The first update after migrating therefore takes noticeably longer
than usual.

Two are worth knowing about:

- `xdg-terminal-exec` used to be load-bearing: every TUI launcher, the floating
  launcher behind most of the menu, and `$TERMINAL` called it by name, so a
  failed AUR build silently broke about half the menu. They all go through
  `blob-terminal-exec` now, which prefers it and falls back to `foot`, then
  `kitty`, both from the official repositories.
- `aether` is in the AUR at a version newer than the one the repository shipped.

`quickshell` never came from the Omarchy repository - it is in official `extra`.

## Installing packages

`install.sh` installs what is missing before it writes any config:

```
packages/blob.packages       147 packages from core, extra, multilib
packages/blob-aur.packages    13 packages with no official equivalent
```

Only missing packages are touched, through `pacman -S --needed` and
`yay -S --needed`. An entry is treated as already installed, and skipped, when a
package of that name is installed, when an installed package provides that name,
or when the name is a group whose members are all installed - so `base-devel` and
packages pulled in under a different name no longer come back on every run. AUR
packages are built one at a time, so a build that fails is reported at the end
instead of stopping the install.

Repo packages go in one `pacman` call. If that call fails the databases are
refreshed with `pacman -Sy` and it is tried again, because a stale database is
what turns an installed-and-present package into `target not found`. If it still
fails the packages are installed one at a time, so one unresolvable name does not
block the other hundred - which is how a missing `sddm` used to turn into a
machine with no login screen. `install.sh` ends by naming any of `sddm`,
`hyprland`, `quickshell` and `uwsm` that are still not installed.

`./install.sh --check` lists what it would install without installing anything,
and `--skip-packages` does the directories and config only.

### Validating the lists

```
blob-packages-check
```

`pacman -Si` and `yay -Si` both search *every* configured repository, so a
package that exists only in a third-party repo passes them and then fails on a
machine without that repo. `blob-packages-check` names the repositories
explicitly instead: official entries must be in core, extra or multilib, and AUR
entries must have an exact `aur/` match and must not be in an official repo.

Run it after editing either list. It caught `localsend` and `tzupdate` sitting in
the official list when they only exist in the Omarchy repository, and `awww`,
`lazydocker` and `woff2-font-awesome` sitting in the AUR list when they are in
official `extra`.

### Bootstrapping an AUR helper

A fresh Arch install has no AUR helper, and `yay` is not in the official
repositories. `install.sh` builds `yay-bin` from the AUR once with `makepkg`
before installing anything from the AUR list, which is why `base-devel` and
`git` are in the official list.

An entry may be written `wanted|already-fine`, which asks for the first name but
accepts either as satisfying the requirement. That is how
`hyprland-preview-share-picker-git` avoids conflicting with the non-git build
that the Omarchy repository still ships.

Three of the AUR entries are load-bearing for this fork and were not in
Omarchy's own package list, because they were installed by hand on this machine:

| Package | Needed by |
| --- | --- |
| `python-pywal16` | `blob-wallpaper-set`, palette extraction |
| `python-terminaltexteffects` | `blob-screensaver`, the effects it draws |
| `awww` | the wallpaper daemon `blob-wallpaper-set` and `blob-theme-menu` drive |
| `playerctl` | the quick settings media row |

`playerctl` is in official `extra`, so it sits in the repo list.

## Desktop applications

The everyday apps come from the official repositories with everything else:

| Package | Opens |
| --- | --- |
| `loupe` | images (GNOME Image Viewer) |
| `imv` | images, keyboard-driven, for scripts and quick previews |
| `mpv` | video and audio |
| `evince` | documents: PDF, PostScript, DjVu, XPS and comic books |
| `guvcview` | webcam viewer and capture |
| `libreoffice-fresh` | documents, spreadsheets and presentations (Writer, Calc, Impress) |
| `kdenlive` | video editing |
| `gnome-text-editor` | plain text and Markdown |
| `file-roller` | archives (zip, 7z, rar, tar) |
| `gnome-calculator` | calculator |
| `baobab` | disk usage analyzer |
| `gnome-disk-utility` | drives and partitions |
| `gnome-system-monitor` | processes and resources |
| `pavucontrol` | audio mixer |
| `network-manager-applet` | network connections (`nm-connection-editor`) |

`hunspell-en_us` gives LibreOffice spell checking, and `ttf-liberation` gives it
metric-compatible replacements for Arial, Times New Roman and Courier New, so
Microsoft Office documents keep their layout. `7zip`, `unrar` and `zip` are the
archive backends `file-roller` needs.

In the terminal: `btop`, `htop` and `nvtop` for system and GPU monitoring,
`duf` for free disk space, and `ncdu` and `dua` for disk usage.

NetBird comes from the AUR as `netbird-bin` and `netbird-ui-bin`. The package
ships a templated `netbird@.service` whose socket lives at
`/var/run/netbird/<instance>.sock`, while the `netbird` CLI and the tray app
look for `/var/run/netbird.sock`. `install.sh` adds a drop-in that moves the
socket to the default path and enables `netbird@main.service`, so
`netbird up` and the tray app work with no extra flags. The service starts on
the next boot, or now with `sudo systemctl start netbird@main`.

`install.sh` makes them the default for their file types through `xdg-mime`,
which writes `~/.config/mimeapps.list`. A type that already has a default in
that file is left alone, so a choice you made yourself always wins, and an app
that is not installed is skipped.

## The boot splash

`install.sh` sets the splash to `branding/blob_boot.png`. To change it later:

```
blob boot                    # branding/blob_boot.png
blob boot ~/some/image.png   # or any other image
```

An installed but *unconfigured* plymouth is not harmless: it takes the console
at boot and never hands it back, and `getty@tty1` waits on
`plymouth-quit-wait.service`, so the machine reaches neither the greeter nor a
TTY. `install.sh` therefore masks `plymouth-start.service` and
`plymouth-quit-wait.service` until the splash is configured, and `blob boot`
unmasks them as part of configuring everything else - the theme in
`default/plymouth/`, the `plymouth` mkinitcpio hook, and the initramfs rebuild.

Every splash update then sets GRUB up to boot the machine and everything else
on it:

- With GRUB already installed, it makes sure `os-prober` is installed and
  `GRUB_DISABLE_OS_PROBER=false`, adds whichever of `quiet splash
  vt.global_cursor_default=0` is missing from `GRUB_CMDLINE_LINUX_DEFAULT`
  without touching the rest of the line, and regenerates the menu. os-prober
  finds other systems, Windows gets an explicit chainload entry when os-prober
  misses it on a shared ESP, and the run stops if the menu has no Arch entry.
- Without GRUB, it runs the same migration as `blob boot grub`: GRUB is
  installed, other systems are detected, and GRUB is armed for one test boot
  with Limine left as the standing default. Once that boot works,
  `blob boot cleanup` retires Limine.
- On a machine not booted in UEFI mode GRUB is left alone and the kernel
  parameters the bootloader still needs are printed instead.

`blob boot detect` reruns only the OS detection.

## Updating

```
blob update
```

Opens with the logo from `~/.config/blob/branding/screensaver.txt` (falling back
to `branding/screensaver.txt`), the same text the screensaver draws, so
`blob branding screensaver` changes both. It checks for updates first and lists every pending system and AUR package with
its old and new version, then asks once with `gum confirm` (`--no-confirm`
skips it). When nothing is pending it says so and stops. The update itself runs
as four numbered steps: refresh the keyring, `pacman -Syu`, `yay -Sua` when the
AUR is reachable, and prune orphans. It ends with a summary of what changed and
how long it took, an offer to reboot when a new kernel came in, and a
notification. A failed step is named on screen and in a critical notification. `blob update-available`
prints the pending count that the bar's update indicator reads. The indicator
rechecks every six hours and a few seconds after any pacman transaction, so it
clears as soon as an update, from `blob update` or by hand, finishes.

This replaces 27 upstream scripts of channel, migration, and version-pinning
machinery. There are no release channels: there is one repository set, which is
Arch plus the AUR.

## After migrating

```
pacman -Qtdq        # orphans the removals left behind
pacman -Qm          # everything now AUR-managed
```

`blob-repo-migrate` backs up `/etc/pacman.conf` to `pacman.conf.bak.<epoch>`
before editing, and prints the path.
