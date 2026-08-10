# kitty

Config for the [kitty](https://sw.kovidgoyal.net/kitty/) terminal.
`install.sh` does not deploy this — it shells out to `pacman`,
`sha256sum`, `hyprctl`, and `omarchy-theme-set`, so it only runs where
Omarchy does. Apply these by hand (or symlink them, below).

Two files, mirroring how kitty is set up on the Omarchy side:

- `kitty.conf` — fonts, window, tabs, cursor, and platform options.
  Ends up as one `include current-theme.conf` plus real settings; kitty's
  own 125KB commented reference config is deliberately not checked in.
- `current-theme.conf` — the active palette, currently **flats**.

## Theming

Under Omarchy, `omarchy-theme-set` regenerates the terminal palette from
`themes/<name>/colors.toml` whenever the theme changes. Nothing does that
here, so `current-theme.conf` is a hand translation of that same toml
into kitty's config syntax — meaning it does **not** track edits to
`themes/flats/colors.toml`.

To switch themes, retranslate the 22 keys from another
`themes/<name>/colors.toml`. The mapping is direct (`background` →
`background`, `color0` → `color0`, …), with the kitty-only extras
(borders, tab bar, marks, `cursor_text_color`, `url_color`) derived from
`accent` and `background`.

## Fonts

`kitty.conf` expects **JetBrainsMono Nerd Font**:

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

## Install

```bash
# Symlink (config tracks the repo — recommended)
ln -sf "$PWD/kitty/kitty.conf" ~/.config/kitty/kitty.conf
ln -sf "$PWD/kitty/current-theme.conf" ~/.config/kitty/current-theme.conf

# Or copy, if you'd rather edit the live files independently
cp kitty/*.conf ~/.config/kitty/
```

Reload a running kitty with `ctrl+cmd+,`. New windows pick up changes on
their own.
