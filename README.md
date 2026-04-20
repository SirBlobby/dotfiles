<div align="center">
  <h1>Blob's Dotfiles</h1>
  <p>My personal system configurations for a custom Wayland desktop environment.</p>

  <img src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white" alt="Arch Linux" />
  <img src="https://img.shields.io/badge/Hyprland-00A86B?style=for-the-badge&logo=hyprland&logoColor=white" alt="Hyprland" />
  <img src="https://img.shields.io/badge/Waybar-FF6600?style=for-the-badge&logo=linux&logoColor=white" alt="Waybar" />
  <img src="https://img.shields.io/badge/AGS-231F20?style=for-the-badge&logo=gnome&logoColor=white" alt="AGS" />
</div>

## What's Inside?

My current setup is built around these core components:

- **[Hyprland](https://hyprland.org/):** A highly customizable dynamic tiling Wayland compositor.
- **[Waybar](https://github.com/Alexays/Waybar):** A customizable, modular status bar.
- **[AGS](https://github.com/Aylur/ags):** Aylur's Gtk Shell, used for creating custom, scriptable desktop widgets.

### Directory Structure

- **`hypr/`**: Hyprland configurations (keybindings, window rules, animations, layout settings, and autostart).
- **`waybar/`**: Status bar layout, CSS styling, and custom interactive modules.
- **`ags/`**: Custom desktop widgets built with TypeScript and GTK.
- **`scripts/`**: Global utility scripts (such as a streamlined GMU Eduroam Wi-Fi connector).
- **`branding/`**: Custom ASCII art and system branding assets.

## Installation

An automated installer script (`install.sh`) is provided to safely apply these configurations to your system.

```bash
# Run the standard installer
./install.sh

# See what would change without modifying any files (dry run)
./install.sh --check

# Force overwrite of any existing local changes
./install.sh --force
```

### Installer Features

1. **Safety First:** Computes file hashes to detect local changes. Backs up existing configurations before applying updates.
2. **Auto-Deployment:** Copies the tracked configurations seamlessly into your `~/.config/` directory.
3. **Command Wrapping:** Automatically sets up scripts from the `scripts/` directory as global commands in `~/.local/bin/`.
4. **Shell Integration:** Injects the necessary paths into your `~/.bashrc`, `~/.zshrc`, and system-wide profiles.
5. **Instant Refresh:** Automatically restarts background services like `waybar` and `ags` so changes take effect immediately.