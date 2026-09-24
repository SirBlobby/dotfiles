# Hooks

Hooks are optional scripts you write to run your own commands when something in
Blob happens. None ship active: `hooks/` holds only `.sample` templates, the
installer copies them to `~/.config/blob/hooks/`, and `blob-hook` skips any file
ending in `.sample`. Blob's own behaviour, such as recolouring apps on a theme
change, is built into its scripts and never depends on a hook.

To use one, copy the sample without the suffix and edit it:

```
cp ~/.config/blob/hooks/theme-set.sample ~/.config/blob/hooks/theme-set
```

`blob-hook <name>` runs `~/.config/blob/hooks/<name>` and then every file in
`~/.config/blob/hooks/<name>.d/`, so several scripts can share one event. A
failing hook prints a message and never stops the command that called it.

| Hook | Run by | Argument |
| --- | --- | --- |
| `theme-set` | `blob-theme-set`, after a theme is applied | theme name |
| `font-set` | `blob-font-set`, after the font changes | font name |
| `battery-low` | `blob-battery-low` | battery percentage |
| `post-update` | `blob-update`, after a successful update | none |
