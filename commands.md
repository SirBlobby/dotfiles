# Custom Commands

The installer automatically exposes scripts from [`scripts/`](scripts/) as global commands.

| Command | Description |
| --- | --- |
| `blob_wallpaper [path]` | Sets your background using Omarchy's background system. If used with an image from `~/wallpapers/` or a valid path, it leverages Pywal to generate a full system color palette into the `blob-dynamic` theme and always updates the desktop background — but only switches your active color theme to it if you're already in dynamic mode (see `blob_theme --mode`), so it won't pull you out of a static theme. With no argument, it opens the AGS wallpaper picker; `--menu` opens the same list in the Omarchy menu (also reachable from Blob > Wallpaper). |
| `blob_theme [name\|--dynamic\|--mode\|--print\|share-link-or-id]` | Manages color themes. With no argument, opens the AGS theme picker; `--menu` opens the same list in the Omarchy menu (also reachable from Blob > Theme). `--dynamic` recolors from the current wallpaper without changing it; `--mode` prints `static` or `dynamic`; `--print` dumps the currently active theme's `colors.toml` to stdout, e.g. `blob_theme --print > themes/my-theme/colors.toml` to save a dynamically-generated palette you like. A `name` applies a local theme (see [`themes/`](themes/README.md)) or, if no local theme matches, falls back to pulling a shared palette from the wall-styles site by link or id (e.g. `blob_theme "https://wall-styles.vercel.app/?id=ab12cd34ef"`). |
| `blob_glass [on\|off\|toggle]` | A quick toggle to enable or disable window transparency on the fly. It writes a Hyprland flag into `~/.local/state/omarchy/toggles/hypr/`, which Omarchy loads after `hypr/looknfeel.lua`, so no config file is rewritten. |
| `blob_boot [path]` | Safely updates your Plymouth boot splash image (defaults to `branding/boot_flash.png`) and rebuilds the `initramfs` (GRUB compatible via `mkinitcpio`). |
| `blob_wifi` | A streamlined script to connect to the GMU Eduroam Wi-Fi network using `iwd` and `systemd-resolved` (replaces NetworkManager). |
| `blob_key <set\|show\|clear\|list> [NAME] [VALUE]` | Stores secrets/env values for widgets and services, e.g. `blob_key set SOME_TOKEN value`. |
