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

- `xdg-terminal-exec` is load-bearing. Every TUI launcher's `Exec=` line calls
  it, so if its AUR build ever fails, TUI shortcuts stop opening.
- `aether` is in the AUR at a version newer than the one the repository shipped.

`quickshell` never came from the Omarchy repository - it is in official `extra`.

## Installing packages

`install.sh` installs what is missing before it writes any config:

```
packages/blob.packages       121 packages from core, extra, multilib
packages/blob-aur.packages    11 packages with no official equivalent
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

## No boot splash

`plymouth` is deliberately not on either list. Blob configures no splash: there
is no mkinitcpio hook, no kernel command line, and `default/plymouth/` ships no
theme assets, so `blob-plymouth-set` has nothing to publish either. An installed
but unconfigured plymouth is not harmless - it takes the console at boot and
never hands it back, and `getty@tty1` waits on `plymouth-quit-wait.service`, so
the machine reaches neither the greeter nor a TTY.

`install.sh` masks `plymouth-start.service` and `plymouth-quit-wait.service` for
that reason, which un-breaks a machine that already has the package. To go
further:

```
sudo pacman -Rns plymouth
```

## Updating

```
blob update
```

Refreshes the keyring, runs `pacman -Syu`, runs `yay -Sua` when the AUR is
reachable, prunes orphans, and sends a notification. `blob update-available`
prints the pending count that the bar's update indicator reads.

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
