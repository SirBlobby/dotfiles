# Themes

Drop-in static color themes. Each subdirectory here becomes a theme
selectable from `blob_theme`, the theme picker widget, and the Omarchy
menu, once `install.sh` copies it into `~/.config/omarchy/themes/`.

## Adding a theme

Create a directory named after the theme (lowercase, hyphens instead
of spaces — e.g. `tokyo-night/`) containing a `colors.toml`:

```toml
accent = "#7aa2f7"
cursor = "#c0caf5"
foreground = "#c0caf5"
background = "#1a1b26"
selection_foreground = "#1a1b26"
selection_background = "#7aa2f7"

color0 = "#1a1b26"
color1 = "#f7768e"
color2 = "#9ece6a"
color3 = "#e0af68"
color4 = "#7aa2f7"
color5 = "#bb9af7"
color6 = "#7dcfff"
color7 = "#c0caf5"
color8 = "#414868"
color9 = "#f7768e"
color10 = "#9ece6a"
color11 = "#e0af68"
color12 = "#7aa2f7"
color13 = "#bb9af7"
color14 = "#7dcfff"
color15 = "#c0caf5"
```

All 22 keys are required — this is the same format Omarchy themes and
`blob_wallpaper`'s pywal-generated `blob-dynamic` theme already use, so
`omarchy-theme-set` and its app-config templates pick it up with no
extra work.

### Saving a dynamic palette you like

If a wallpaper's pywal-generated colors are worth keeping permanently,
dump the currently active theme's `colors.toml` straight into a new
theme folder instead of typing it out by hand:

```bash
mkdir -p themes/my-new-theme
blob_theme --print > themes/my-new-theme/colors.toml
```

Run `./install.sh` (add `--force` if the theme already exists on disk
and you're updating it) to deploy new/changed theme folders.

Any theme already installed under `~/.config/omarchy/themes/` or
bundled with Omarchy itself (`$OMARCHY_PATH/themes/`) shows up
automatically too — this directory is just for ones you want tracked
in dotfiles.

## kitty

`omarchy-theme-set` and its app-config templates only run under Omarchy,
so themes do not propagate to the standalone kitty config in
[`kitty/`](../kitty/README.md). It carries its own hand-translated copy
of one palette at `kitty/current-theme.conf` — currently **flats** —
which changing a theme's `colors.toml` here does not update.
