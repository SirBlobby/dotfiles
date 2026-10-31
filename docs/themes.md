# Themes

A theme is a directory under `themes/` holding at minimum a `colors.toml`.
`blob-theme-set <name>` stages it, renders every template against it, and
retints the running desktop.

## What a theme can ship

| File | Used by |
| --- | --- |
| `colors.toml` | required; the palette everything else derives from |
| `backgrounds/` | the background switcher; a theme without one keeps the current wallpaper |
| `shell.lock.toml` | lock screen surface tokens |
| `neovim.lua` | the editor colorscheme |
| `icons.theme` | GTK icon theme name |
| `preview.png`, `unlock.png`, `preview-unlock.png` | theme and lock previews |

## colors.toml

Named keys are preferred: `background`, `foreground`, `accent`, `muted`,
`selection`, the eight base colors, and their `bright_` variants. The pywal
`color0`..`color15` form also works and is resolved through the same cascade:
`color0` is the background, `color4` is blue, `color5` is magenta.

That cascade lives in `blob-theme-color`, and `Commons/Colors.qml` mirrors it so
the shell and the CLI never disagree about what a slot means.

## Templates

Each rendered file is picked up differently: `foot.ini` and `kitty.conf` by an
`include` in the shipped terminal config, `hyprland.lua` through Hyprland's Lua
module path, `shell.toml` and `chromium.theme` read straight from the state
directory, and `btop.theme`, `neovim.lua`, `gtk.css`, `starship.toml` and
`fastfetch.jsonc` through symlinks the installer makes into those apps' own
config trees.

`default/themed/*.tpl` are rendered per theme into
`~/.local/state/blob/current/theme/`. Twelve ship: foot, kitty, btop, chromium,
hyprland, the screenshare picker, neovim, `shell.toml`, zen, `gtk.css`,
`starship.toml`, and `fastfetch.jsonc`.

An app picks its colors up in one of two ways. Most include the generated file
directly, so nothing has to run:

```
include ~/.local/state/blob/current/theme/kitty.conf
```

Zen does the same through a CSS import in `userChrome.css`. The rest are pushed
by a short applier listed in `post_theme_commands` inside `blob-theme-set`:
`blob-theme-foot`, `blob-theme-browser`, `blob-restart-terminal`,
`blob-restart-btop`, `blob-hypr-restart`, `blob-theme-gtk`.

## GTK apps

Nautilus and the other GTK apps read two things. The palette comes from
`gtk.css`, linked into both `~/.config/gtk-3.0/gtk.css` and
`~/.config/gtk-4.0/gtk.css`, which redefines the libadwaita named colors
(`window_bg_color`, `headerbar_bg_color`, `accent_bg_color` and the rest) so a
stock Adwaita app is drawn in the theme's own colors. The light or dark
preference comes from `blob-theme-gtk`, which reads the theme's `mode` and sets
`org.gnome.desktop.interface color-scheme` and `gtk-theme` through `gsettings`.

The preference applies to running apps immediately; the CSS is read at startup,
so an app that was already open keeps its old colors until it is restarted.

Adding a template for another app means dropping a `.tpl` in `default/themed/`
and, if it cannot include a file, adding an applier to that list.

## Tokens

A template may reference `{{ key }}` for any resolved palette key, plus three
derived forms: `{{ key_strip }}` without the leading `#`, `{{ key_rgb }}` as
`R,G,B`, and `{{ key_ansi }}` as `38;2;R;G;B`, which is what a terminal program
that takes a raw escape sequence rather than a hex color needs.

## About

`fastfetch.jsonc` is linked to `~/.config/fastfetch/config.jsonc`. It draws
`~/.config/blob/branding/about.txt` as the logo, with 2 columns of padding to
its left and 6 between it and the modules - the exact numbers
`blob-launch-about` measures the About window against, so replacing the logo
resizes the window to fit it. Title and keys take the theme's accent.

A config of your own at that path is a regular file rather than the symlink, and
`blob-launch-about` leaves the window sizing alone when it finds one.

## The prompt

`starship.toml` is linked to `~/.config/starship.toml`. It carries a
`[palettes.blob]` block built from the theme - `accent`, `foreground`, `muted`,
`success`, `warning`, `error` - and every style in the file names one of those
rather than a literal color, so the prompt moves with the theme. Starship reads
its config on each prompt, so a theme change shows up on the next command, in
shells that are already open.

`starship init bash` runs from `session/bashrc`, which `install.sh` sources from
`~/.bashrc` with a single line. That file returns immediately in a
non-interactive shell, so it cannot disturb `scp` or `rsync`, and it also
sources `session/env-bootstrap` so `blob` is on `PATH` in any interactive shell.

## The three ways to set a theme

| Command | Does |
| --- | --- |
| `blob theme menu` | pick from the bundled and local sets, each row previewing the theme's background, foreground, accent and six palette colours as swatches |
| `blob theme set <name>` | apply one by name |
| `blob wallpaper set <image>` | extract a palette from a wallpaper with pywal, fix flat palettes with `blob-theme-contrast`, and apply it as `blob-dynamic` |
| `blob theme share <link>` | fetch a shared palette and apply it as `blob-dynamic` |

Aether is also installed and does the same job with a GUI. To have its palettes
land where these do, add Blob as a custom app in Aether with a template writing
`colors.toml` into `~/.local/state/blob/current/theme/` and a post-apply hook
calling `blob-theme-refresh`.

## Bundled themes

Twenty-two came across from upstream, plus `flats` and `pitch-dark`. Their
`backgrounds/` directories are empty on purpose: the upstream images were
Omarchy branding, and `~/wallpapers` holds 112 of your own. A theme with no
background of its own leaves the current wallpaper alone.

Because of that, a machine with no wallpaper yet would get none from the theme
either. The installer covers the gap: it symlinks `~/wallpapers` to the
checkout, applies `flats`, and points the background symlink at the first image
it finds. See [install.md](install.md).
