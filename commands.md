# Custom Commands

The installer automatically exposes scripts from [`scripts/`](scripts/) as global commands.

| Command | Description |
| --- | --- |
| `blob_wallpaper [path]` | Sets your background using Omarchy's background system. If used with an image from `~/wallpapers/` or a valid path, it leverages Pywal to generate a full system color palette and dynamically updates the `blob-dynamic` theme, AGS widgets, and Waybar. With no argument, it opens the AGS wallpaper picker. |
| `blob_theme <share-link-or-id>` | Pulls a color palette shared from the wall-styles site and applies it as the `blob-dynamic` theme (e.g. `blob_theme "https://wall-styles.vercel.app/?id=ab12cd34ef"`). |
| `blob_glass [on\|off\|toggle]` | A quick toggle to enable or disable window transparency on the fly. |
| `blob_boot [path]` | Safely updates your Plymouth boot splash image (defaults to `branding/boot_flash.png`) and rebuilds the `initramfs` (GRUB compatible via `mkinitcpio`). |
| `blob_wifi` | A streamlined script to connect to the GMU Eduroam Wi-Fi network using `iwd` and `systemd-resolved` (replaces NetworkManager). |
| `blob_key <set\|show\|clear\|list> [NAME] [VALUE]` | Stores secrets/env values for widgets and services, e.g. `blob_key set SOME_TOKEN value`. |
