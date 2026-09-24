# Menu tree

`default/blob/blob-menu.jsonc` is the source for both menus: the apps menu on
`Super + Space` and the root menu on `Super + Alt + Space`. Rows keep the order
the file lists them in, which is why Install opens with Package and AUR ahead
of Development, Browser, Gaming and the rest. That is also why the `before:`
hint machinery the old menu fork carried is gone.

## Trimmed from upstream

Upstream ships 338 rows. This tree has 260. What came out:

| Section | Dropped | Why |
| --- | --- | --- |
| `install.*` | 35 of 91 | AI tools, editors, terminals, services, web apps, preinstalls. Browsers, gaming, dev languages and the Windows VM were restored on request |
| `remove.*` | 16 of 60 | the same set in reverse, plus security and dictation removal |
| `setup.default.agent.*` | 14 | AI agent defaults |
| `update.channel.*` | 5 | release channels for a package that will not exist |
| `learn.*` | 4 | Omarchy's manual and Discord, plus tmux and herdr keybindings |
| `trigger.transcode` | 1 | transcode dropped |
| `style.unlock` | 1 | plymouth theme switcher; `blob boot` covers splash images |
| `update.config.tmux` | 1 | tmux dropped |
| `setup.reset` | 1 | factory reset restores Omarchy defaults, which is wrong here |

Docs rows now open in the browser (`blob-launch-browser`) rather than as web apps,
which also keeps them working whichever way the web app question lands.

## Commands the menu still needs

Every command the tree references is in `bin/`. What follows is the record of
what Phase 6 had to fill:

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

## Restored install and remove subtrees

Browsers, gaming, dev languages and the Windows VM came back after the first
pass cut them, which took 82 rows and 38 commands with them.

| Subtree | Rows | Covers |
| --- | --- | --- |
| Browsers | 14 | Chrome, Edge, Brave, Brave Origin, Firefox, Zen, install and remove |
| Gaming | 20 | Steam, RetroArch, Minecraft, Lutris, Heroic, GeForce NOW, Xbox Cloud, Xbox controllers, Battle.net |
| Development | 44 | Ruby on Rails, JavaScript (Node/Bun/Deno), Go, PHP (+ Laravel, Symfony), Python, Elixir (+ Phoenix), Zig, Rust, Java, .NET, OCaml, Clojure, Scala |
| Windows VM | 2 | install and remove |

### This settled the web app question

Xbox Cloud Gaming and GeForce NOW are web apps, not packages. Restoring gaming
therefore pulled in `blob-webapp-install`, `blob-webapp-remove`,
`blob-launch-webapp` and `blob-launch-or-focus-webapp`, and those fall back to
`chromium.desktop` for any browser that is not Chrome, Brave, Edge, Opera,
Vivaldi or Helium. Zen is Firefox-based.

So chromium stays, as the web app runtime. The `webapp` helper in
`hypr/default/helpers.lua` is live again rather than a dangling hook, though no
binding ships that uses it. The `install.webapp` and `remove.webapp` menu rows
are still out; the machinery behind them now works, so adding them back is a
two-line change if you want to create web app launchers from the menu.

### Still out

AI tools, editors, terminals, services (1Password, Dropbox, Spotify, Signal,
Tailscale, NordVPN, ONCE, Bitwarden), preinstalls, dictation, and the security
removal rows. Say the word on any of them.
