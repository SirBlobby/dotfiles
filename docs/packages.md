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
packages/blob.packages       117 packages from core, extra, multilib
packages/blob-aur.packages    11 packages with no official equivalent
```

Only missing packages are touched, through `pacman -S --needed` and
`yay -S --needed`. `./install.sh --check` lists what it would install without
installing anything, and `--skip-packages` does the directories and config only.

An entry may be written `wanted|already-fine`, which asks for the first name but
accepts either as satisfying the requirement. That is how
`hyprland-preview-share-picker-git` avoids conflicting with the non-git build
that the Omarchy repository still ships.

Three of the AUR entries are load-bearing for this fork and were not in
Omarchy's own package list, because they were installed by hand on this machine:

| Package | Needed by |
| --- | --- |
| `python-pywal` | `blob-wallpaper-set`, palette extraction |
| `awww` | the wallpaper daemon `blob-wallpaper-set` and `blob-theme-menu` drive |
| `playerctl` | the quick settings media row |

`playerctl` is in official `extra`, so it sits in the repo list.

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
