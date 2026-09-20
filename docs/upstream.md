# Upstream base

This desktop was forked from Omarchy and no longer tracks it. There is no
automatic sync. This file exists so a future cherry-pick has a diff base.

| Field | Value |
| --- | --- |
| Package | omarchy 4.0.4-1 |
| Version file | 4.0.0.alpha |
| Source | https://github.com/basecamp/omarchy |
| Path forked from | /usr/share/omarchy |
| Forked on | 2026-09-19 |

## What was taken

| Upstream path | Landed at |
| --- | --- |
| `shell/` | `shell/` |
| `default/hypr/` | `hypr/default/` |
| `default/themed/*.tpl` | `themed/` |
| `themes/` | `themes/` |
| `bin/` (selected) | `bin/` |
| `default/omarchy/omarchy-menu.jsonc` | `menu/menu.jsonc` |

Upstream carries 441 commands and 39,721 lines of QML/JS. This fork carries the
subset reachable from the shell, the menu, and the theme system.

## Renames applied

Every identifier was rewritten. `OMARCHY_PATH` to `BLOB_PATH`, `omarchy-*`
commands to `blob-*`, `omarchy.*` plugin ids to `blob.*`, `org.omarchy.*` app ids
to `org.blob.*`, and the three state paths from `omarchy` to `blob`. The full map
is `docs/renames.md`.

## To compare against upstream later

```
git clone https://github.com/basecamp/omarchy /tmp/omarchy
cd /tmp/omarchy && git log --oneline v4.0.4..HEAD -- shell/
```

Apply anything wanted by hand, through the rename map.
