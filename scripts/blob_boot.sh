#!/bin/bash

# Default to the branding image if no argument is provided
if [ -z "$1" ]; then
    IMAGE_PATH="$HOME/Documents/dotfiles/branding/boot_flash.png"
else
    IMAGE_PATH=$(realpath "$1")
fi

if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: File '$IMAGE_PATH' does not exist."
    exit 1
fi

echo "Applying boot splash image: $IMAGE_PATH"
echo "This requires sudo privileges."

# Copy the image to the Plymouth theme directory
sudo cp "$IMAGE_PATH" /usr/share/plymouth/themes/omarchy/logo.png

# Ensure the correct permissions
sudo chmod 644 /usr/share/plymouth/themes/omarchy/logo.png

echo "Rebuilding initramfs..."
# Exclusively use mkinitcpio for GRUB compatibility
sudo mkinitcpio -P

echo "Boot splash successfully updated!"