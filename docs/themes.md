# Themes

A theme is a directory under `themes/` holding at minimum a `colors.toml`.
`blob-theme-set <name>` stages it, renders every template against it, and
retints the running desktop.

## What a theme can ship

| File | Used by |
| --- | --- |
| `colors.toml` | required; the palette everything else derives from |
| `backgrounds/` | the background switcher |
| `shell.lock.toml` | lock screen surface tokens |
| `neovim.lua` | the editor colorscheme |
| `icons.theme` | GTK icon theme name |
| `preview.png`, `unlock.png`, `preview-unlock.png` | theme and lock previews |

## colors.toml

Named keys are preferred: `background`, `foreground`, `accent`, `muted`,
`selection`, the eight base colors, and their `bright_` variants. The pywal
`color0`..`color15` form also works and is resolved through the same cascade:
`color0` is the background, `color4` is blue, `color5` is magenta.

That cascade lives in `blob-theme-color`, and `Commons/Color.qml` mirrors it so
the shell and the CLI never disagree about what a slot means.

## Templates

`default/themed/*.tpl` are rendered per theme into
`~/.local/state/blob/current/theme/`. Nine ship: foot, kitty, btop, chromium,
hyprland, the screenshare picker, neovim, `shell.toml`, and zen.

An app picks its colors up in one of two ways. Most include the generated file
directly, so nothing has to run:

```
include ~/.local/state/blob/current/theme/kitty.conf
```

Zen does the same through a CSS import in `userChrome.css`. The rest are pushed
by a short applier listed in `post_theme_commands` inside `blob-theme-set`:
`blob-theme-foot`, `blob-theme-browser`, `blob-restart-terminal`,
`blob-restart-btop`, `blob-hypr-restart`.

Adding a template for another app means dropping a `.tpl` in `default/themed/`
and, if it cannot include a file, adding an applier to that list.

## The three ways to set a theme

| Command | Does |
| --- | --- |
| `blob theme menu` | pick from the bundled and local sets |
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
Omarchy branding, and `~/wallpapers` holds 103 of your own. A theme with no
background of its own leaves the current wallpaper alone.
