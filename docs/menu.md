# Menu tree

`menu/menu.jsonc` is the single source for both menus: the apps menu on
`Super + Space` and the root menu on `Super + Alt + Space`. There is no default
tree merged underneath it and no user extension file layered on top, so a row
sits where the file puts it. That is why the `before:` hint machinery the old
menu fork carried is gone.

## Trimmed from upstream

Upstream ships 338 rows. This tree has 178. What came out:

| Section | Dropped | Why |
| --- | --- | --- |
| `install.*` | 84 of 90 | the software catalogue: browsers, gaming, dev languages, AI tools, services. Kept: Package, AUR, TUI, and the Style subtree (theme, background, font) |
| `remove.*` | 56 of 59 | same catalogue in reverse. Kept: Package, TUI, Theme |
| `setup.default.agent.*` | 14 | AI agent defaults |
| `update.channel.*` | 5 | release channels for a package that will not exist |
| `learn.*` | 4 | Omarchy's manual and Discord, plus tmux and herdr keybindings |
| `trigger.transcode` | 1 | transcode dropped |
| `style.unlock` | 1 | plymouth theme switcher; `blob-boot-splash` covers splash images |
| `update.config.tmux` | 1 | tmux dropped |
| `setup.reset` | 1 | factory reset restores Omarchy defaults, which is wrong here |

Docs rows now open in the browser (`blob-launch-browser`) rather than as web apps,
which also keeps them working whichever way the web app question lands.

## Commands the menu still needs

The tree references 95 commands. All of them are now in `bin/`. What follows is
kept as the record of what Phase 6 had to fill:

- **audio**: `blob-audio-restart`
- **bar**: `blob-bar`
- **bluetooth**: `blob-bluetooth-restart`
- **branding**: `blob-branding-about`, `blob-branding-screensaver`
- **capture**: `blob-capture-qr`, `blob-capture-record`, `blob-capture-record-webcam`, `blob-capture-screenshot`, `blob-capture-text`
- **drive**: `blob-drive-password`
- **hibernation**: `blob-hibernation-available`
- **hw**: `blob-hw-dell-xps-haptic-touchpad`, `blob-hw-fingerprint`, `blob-hw-hybrid-gpu`, `blob-hw-laptop`, `blob-hw-touchpad`, `blob-hw-touchscreen`, `blob-hw-webcam`
- **hypr**: `blob-hypr-window-gaps-toggle`, `blob-hypr-window-single-square-aspect-toggle`, `blob-hypr-workspace-layout-toggle`
- **install**: `blob-install-font`
- **launch**: `blob-launch-about`, `blob-launch-config-editor`, `blob-launch-screensaver`
- **menu**: `blob-menu-emoji`, `blob-menu-keybindings`, `blob-menu-plugin`, `blob-menu-share`, `blob-menu-timezone`
- **network**: `blob-network-dns`, `blob-network-restart`, `blob-network-status`
- **pkg**: `blob-pkg-aur-install`, `blob-pkg-install`, `blob-pkg-remove`
- **plugin**: `blob-plugin-add`
- **refresh**: `blob-refresh-hyprland`, `blob-refresh-hyprsunset`, `blob-refresh-plymouth`, `blob-refresh-shell`
- **reminder**: `blob-reminder`
- **restart**: `blob-restart-hyprsunset`, `blob-restart-trackpad`, `blob-restart-xcompose`
- **setup**: `blob-setup-direct-boot`, `blob-setup-security-fido2`, `blob-setup-security-fingerprint`, `blob-setup-security-sshd`, `blob-setup-security-sudoless-docker`
- **sudo**: `blob-sudo-docker`, `blob-sudo-passwordless`
- **system**: `blob-system-lock`, `blob-system-logout`, `blob-system-reboot`, `blob-system-shutdown`
- **theme**: `blob-theme-update`
- **toggle**: `blob-toggle-bar`, `blob-toggle-crash-capture`, `blob-toggle-enabled`, `blob-toggle-glass`, `blob-toggle-hybrid-gpu`, `blob-toggle-idle`, `blob-toggle-nightlight`, `blob-toggle-screensaver`, `blob-toggle-silencing`, `blob-toggle-touchpad`, `blob-toggle-touchscreen`
- **update**: `blob-update`, `blob-update-firmware`, `blob-update-time`

Every one of these is reachable from a menu row, so a missing command shows up
as a row that does nothing rather than a broken menu.

## Reversed from the plan

`02-keep-drop.md` put `omarchy-setup-*` in the drop list as one-time setup to run
by hand. The menu disagrees: Setup > Security has rows for fingerprint, fido2,
sshd and sudoless docker, and Setup > Direct Boot has one too. Those scripts are
small, self-contained and genuinely useful, so they are vendored and the rows
stay.

`blob-capture-record-webcam` also stays a separate command rather than folding
into `blob-capture-record --webcam` as planned, because the menu row calls it
directly and upstream ships it as its own script.

## Status

Every row in this tree resolves to a command in `bin/`. The only unbacked
`blob-*` names left anywhere in the repo are `blob-launch-webapp` and
`blob-launch-or-focus-webapp`, both referenced from the `webapp` helper in
`hypr/default/helpers.lua` and reachable only from a binding that uses
`{ webapp = ... }`. No such binding ships. They stay as the hook for whichever
way the web app question lands.
