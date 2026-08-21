#!/bin/bash
#
# blob_boot.sh - boot splash and bootloader management.
#
#   blob_boot.sh [image]   Apply a Plymouth boot splash image (default action)
#   blob_boot.sh grub      Migrate from Limine back to GRUB, detecting every OS
#                          --purge removes Limine in the same run instead of
#                          keeping it for one fallback boot
#   blob_boot.sh detect    Rescan for other operating systems, rebuild the menu
#   blob_boot.sh cleanup   Retire Limine once GRUB has been confirmed working
#   blob_boot.sh status    Show what this machine currently boots with
#
# This machine has a 256 MB EFI System Partition, which is why Omarchy switched
# it to a single unified kernel image. Going back to GRUB means going back to a
# separate kernel and initramfs, so every step here is careful about space.

set -euo pipefail

DEFAULT_IMAGE="$HOME/Documents/dotfiles/branding/boot_flash.png"
PLYMOUTH_LOGO="/usr/share/plymouth/themes/omarchy/logo.png"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m    %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m==> %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m!!! %s\033[0m\n' "$*" >&2; exit 1; }

require_sudo() {
    echo "This requires sudo privileges."
    sudo -v || die "Could not obtain sudo."
}

# --------------------------------------------------------------------------
# Boot splash
# --------------------------------------------------------------------------

apply_splash() {
    local image_path
    if [ -z "${1:-}" ]; then
        image_path="$DEFAULT_IMAGE"
    else
        image_path=$(realpath "$1")
    fi

    [ -f "$image_path" ] || die "File '$image_path' does not exist."
    [ -d "$(dirname "$PLYMOUTH_LOGO")" ] || die "Plymouth omarchy theme is not installed."

    log "Applying boot splash image: $image_path"
    require_sudo

    sudo cp "$image_path" "$PLYMOUTH_LOGO"
    sudo chmod 644 "$PLYMOUTH_LOGO"

    log "Rebuilding initramfs"
    rebuild_initramfs

    # Under GRUB the menu references the initramfs by path, so it only needs
    # regenerating if the file set changed - but it is cheap and keeps the menu
    # honest after a kernel or os-prober change.
    if using_grub; then
        log "Refreshing the GRUB menu"
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    ok "Boot splash successfully updated!"
}

# Call mkinitcpio directly: limine-mkinitcpio-hook installs a wrapper at
# /usr/local/bin/mkinitcpio that stops to ask whether to rebuild Limine
# entries, which is useless in a script. While Limine is still the active
# bootloader its own tool is the one that actually updates what boots.
rebuild_initramfs() {
    if command -v limine-mkinitcpio >/dev/null && ! using_grub; then
        info "Limine is still the bootloader; rebuilding through limine-mkinitcpio"
        sudo limine-mkinitcpio
    else
        sudo /usr/bin/mkinitcpio -P
    fi
}

using_grub() {
    [ -f /boot/grub/grub.cfg ] && [ -f /boot/EFI/GRUB/grubx64.efi ]
}

# --------------------------------------------------------------------------
# Limine -> GRUB migration
# --------------------------------------------------------------------------

migrate_to_grub() {
    local purge=0
    [ "${1:-}" = "--purge" ] && purge=1

    [ -d /sys/firmware/efi ] || die "Not booted in UEFI mode; this script assumes UEFI."
    mountpoint -q /boot || die "/boot is not mounted."
    command -v grub-install >/dev/null || die "The 'grub' package is not installed."
    command -v os-prober   >/dev/null || die "The 'os-prober' package is not installed."

    require_sudo

    local machine_id esp_uuid backup
    machine_id=$(</etc/machine-id)
    esp_uuid=$(findmnt -no UUID /boot)
    backup=/root/limine-to-grub-$(date +%Y%m%d-%H%M%S)

    log "Backing up the current boot configuration to $backup"
    sudo mkdir -p "$backup"
    for f in /etc/default/grub /etc/mkinitcpio.d/linux.preset /etc/mkinitcpio.conf \
             /boot/limine.conf /etc/mkinitcpio.conf.d /etc/grub.d; do
        [ -e "$f" ] && sudo cp -a "$f" "$backup/" 2>/dev/null || true
    done
    sudo efibootmgr -v | sudo tee "$backup/efibootmgr-before.txt" >/dev/null 2>&1 || true
    info "saved."

    reclaim_esp_space "$machine_id" "$backup"
    restore_standard_initramfs
    configure_grub_scripts
    install_grub "$esp_uuid"
    fix_failing_boot_units

    if (( purge )); then
        purge_limine
        set_boot_order
        enable_fallback_initramfs
        generate_menu
    else
        # Test GRUB with a one-shot BootNext rather than reordering BootOrder.
        # If GRUB fails to boot, a power cycle falls straight back to Limine on
        # its own - no boot-menu keypress, no timing, nothing to get right while
        # staring at a broken screen.
        set_boot_next
    fi

    log "Result"
    df -h /boot | tail -1 | sed 's/^/    /'
    echo
    info "GRUB menu entries:"
    list_menu_entries
    echo
    if (( purge )); then
        ok "GRUB is the only bootloader. Limine is gone and its space is reclaimed."
    else
        ok "GRUB is installed and set to boot ONCE on the next restart."
        info "If it works:  run '$0 cleanup' to delete Limine and reclaim its 51 MB."
        info "If it fails:  hold the power button, then power on - the firmware falls"
        info "              back to Limine by itself. Nothing to press, nothing lost."
    fi
    info "Backups: $backup"
}

# The 'omarchy' metapackage hard-depends on limine, limine-mkinitcpio-hook and
# limine-snapper-sync, so they can only be forced out with -Rdd - and the next
# omarchy upgrade will resolve those dependencies and pull them straight back in.
#
# NoExtract makes that harmless: pacman may reinstall the packages, but it will
# never write the files that actually do anything. Only the active parts are
# listed - the pacman hooks that rebuild unified kernel images and redeploy
# Limine onto the ESP, plus the /usr/local/bin/mkinitcpio wrapper that shadows
# the real one. Delete these lines from /etc/pacman.conf to undo it.
guard_limine_files() {
    local marker="# Limine neutralised by blob_boot.sh"
    if grep -q "$marker" /etc/pacman.conf; then
        info "pacman.conf guard already present"
        return 0
    fi

    sudo cp /etc/pacman.conf /etc/pacman.conf.bak

    # These are [options] directives, so they have to go inside that section.
    # Appending to the end of the file would land them in the last repo block,
    # where pacman would ignore them.
    sudo awk -v marker="$marker" '
        /^\[options\]/ && !done {
            print
            print marker
            print "NoExtract = etc/pacman.d/hooks/90-mkinitcpio-install.hook"
            print "NoExtract = usr/local/bin/mkinitcpio"
            print "NoExtract = usr/share/libalpm/hooks/60-limine-mkinitcpio-remove-pre.hook"
            print "NoExtract = usr/share/libalpm/hooks/80-limine-efi-deploy.hook"
            print "NoExtract = usr/share/libalpm/hooks/90-limine-mkinitcpio-remove-post.hook"
            done = 1
            next
        }
        { print }
    ' /etc/pacman.conf.bak | sudo tee /etc/pacman.conf >/dev/null

    grep -q "$marker" /etc/pacman.conf \
        || die "Failed to write the NoExtract guard. Your original is at /etc/pacman.conf.bak - restore it before doing anything else."
    info "added NoExtract guard to /etc/pacman.conf (backup: /etc/pacman.conf.bak)"
}

# pacman refuses a plain -R because omarchy depends on these. Force it, but only
# once the guard is in place, so a later reinstall cannot resurrect the hooks.
drop_limine_pkgs() {
    local present=() pkg
    for pkg in "$@"; do
        pacman -Qq "$pkg" &>/dev/null && present+=("$pkg")
    done
    if (( ${#present[@]} == 0 )); then
        info "nothing to remove"
        return 0
    fi

    guard_limine_files

    if sudo pacman -Rn --noconfirm "${present[@]}" 2>/dev/null; then
        info "removed: ${present[*]}"
    else
        warn "the 'omarchy' metapackage depends on these; forcing removal with -Rdd"
        sudo pacman -Rddn --noconfirm "${present[@]}"
        info "removed: ${present[*]}"
        warn "'omarchy' will now report unsatisfied dependencies. That is expected and"
        warn "harmless - nothing checks them outside of a pacman transaction. If a"
        warn "future omarchy upgrade reinstalls them, the guard keeps them inert."
    fi
}

# The ESP is 95% full. Reclaim only files that are provably unreachable, and
# leave Limine's own UKI alone so the machine keeps a working fallback.
reclaim_esp_space() {
    local machine_id=$1 backup=$2
    log "Reclaiming space on the ESP ($(df -h --output=avail /boot | tail -1 | tr -d ' ') free)"

    # Limine's entry tool writes one kernel directory per machine-id. A
    # directory keyed by a different machine-id is left over from a previous
    # install and nothing in NVRAM or limine.conf can reach it.
    local dir name
    shopt -s nullglob
    for dir in /boot/[0-9a-f]*; do
        name=${dir##*/}
        [[ ${#name} -eq 32 && $name =~ ^[0-9a-f]+$ ]] || continue
        [[ $name == "$machine_id" ]] && { info "keeping $name (this machine)"; continue; }
        info "removing stale kernel dir $name ($(sudo du -sh "$dir" | cut -f1))"
        sudo rm -rf "$dir"
    done
    shopt -u nullglob

    # arch-linux.efi is what the mkinitcpio preset wrote; limine.conf boots
    # omarchy_linux.efi and never reads it. Only drop it while the UKI that
    # Limine actually boots is present, so a fallback always survives.
    if [ -f /boot/EFI/Linux/arch-linux.efi ]; then
        if [ -f /boot/EFI/Linux/omarchy_linux.efi ] && ! grep -q "arch-linux.efi" /boot/limine.conf 2>/dev/null; then
            info "removing unreferenced UKI arch-linux.efi ($(sudo du -sh /boot/EFI/Linux/arch-linux.efi | cut -f1))"
            sudo rm -f /boot/EFI/Linux/arch-linux.efi
        else
            warn "arch-linux.efi is still referenced; keeping it"
        fi
    fi

    local avail_kb
    avail_kb=$(df --output=avail -k /boot | tail -1 | tr -d ' ')
    info "ESP now has $((avail_kb / 1024)) MB free"
    (( avail_kb > 61440 )) || die "Only $((avail_kb / 1024)) MB free; an initramfs needs ~60 MB. Nothing further has been changed."
}

restore_standard_initramfs() {
    log "Restoring a standard kernel + initramfs layout"

    # btrfs-overlayfs ships with limine-mkinitcpio-hook and is about to vanish.
    # omarchy_hooks.conf assigns HOOKS wholesale, so filter the hook out from a
    # drop-in that sorts after it instead of editing an Omarchy-managed file.
    sudo tee /etc/mkinitcpio.conf.d/zz-no-limine.conf >/dev/null <<'EOF'
# Written when this machine was migrated from Limine back to GRUB.
# btrfs-overlayfs comes from limine-mkinitcpio-hook, which is no longer
# installed, and this root filesystem is ext4 - so drop the hook rather than
# let mkinitcpio fail on a missing one.
_hooks=()
for _hook in "${HOOKS[@]}"; do
    [[ $_hook == "btrfs-overlayfs" ]] || _hooks+=("$_hook")
done
HOOKS=("${_hooks[@]}")
unset _hooks _hook
EOF
    info "wrote /etc/mkinitcpio.conf.d/zz-no-limine.conf"

    # Only the 'default' preset: Limine's 51 MB UKI is still on the ESP as a
    # fallback and a fallback initramfs will not fit beside it. The cleanup
    # step turns the fallback on once that space comes back.
    sudo tee /etc/mkinitcpio.d/linux.preset >/dev/null <<'EOF'
# mkinitcpio preset file for the 'linux' package

#ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

#default_config="/etc/mkinitcpio.conf"
default_image="/boot/initramfs-linux.img"
#default_uki="/boot/EFI/Linux/arch-linux.efi"
default_options=""

#fallback_config="/etc/mkinitcpio.conf"
fallback_image="/boot/initramfs-linux-fallback.img"
#fallback_uki="/boot/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect"
EOF
    info "wrote /etc/mkinitcpio.d/linux.preset (image, not UKI)"

    # The 'limine' package itself stays for now - EFI/limine plus limine.conf
    # remain a working fallback. Only the pieces that hijack mkinitcpio go.
    log "Removing Limine's mkinitcpio integration"
    drop_limine_pkgs limine-mkinitcpio-hook limine-snapper-sync
    [ -e /usr/local/bin/mkinitcpio ] && warn "/usr/local/bin/mkinitcpio still shadows /usr/bin/mkinitcpio"

    log "Building the initramfs"
    rebuild_initramfs
    [ -f /boot/initramfs-linux.img ] || die "mkinitcpio produced no /boot/initramfs-linux.img. Limine is still bootable - do NOT reboot into GRUB."
    [ -f /boot/vmlinuz-linux ] || die "/boot/vmlinuz-linux is missing."
    info "initramfs: $(du -h /boot/initramfs-linux.img | cut -f1)"
}

# The previous GRUB setup booted a UKI: 10_linux had been made non-executable
# and a custom 15_uki emitted a bare 'uki' command in its place. That is why the
# old menu listed Windows and Ubuntu but no Arch entry at all. Back on a normal
# kernel + initramfs, that has to be undone or the menu cannot boot this system.
configure_grub_scripts() {
    log "Fixing the GRUB menu generators"

    if [ -f /etc/grub.d/10_linux ] && [ ! -x /etc/grub.d/10_linux ]; then
        sudo chmod +x /etc/grub.d/10_linux
        info "enabled 10_linux (generates the Arch entries)"
    fi

    if [ -x /etc/grub.d/15_uki ]; then
        sudo chmod -x /etc/grub.d/15_uki
        info "disabled 15_uki (no unified kernel image any more)"
    fi

    [ -x /etc/grub.d/30_os-prober ] || { sudo chmod +x /etc/grub.d/30_os-prober; info "enabled 30_os-prober"; }
}

install_grub() {
    local esp_uuid=$1
    log "Configuring GRUB"

    set_grub_key() {
        local key=$1 val=$2
        if grep -q "^${key}=" /etc/default/grub; then
            sudo sed -i "s|^${key}=.*|${key}=${val}|" /etc/default/grub
        elif grep -qE "^#\s*${key}=" /etc/default/grub; then
            sudo sed -i "0,/^#\s*${key}=.*/s||${key}=${val}|" /etc/default/grub
        else
            echo "${key}=${val}" | sudo tee -a /etc/default/grub >/dev/null
        fi
        info "${key}=${val}"
    }

    # Carry over the exact kernel command line Limine was booting, so Plymouth
    # and the quiet splash behave the way they do today.
    set_grub_key GRUB_CMDLINE_LINUX_DEFAULT '"rtc_cmos.use_acpi_alarm=1 initramfs_async=0 quiet splash loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"'
    set_grub_key GRUB_DISABLE_OS_PROBER 'false'
    set_grub_key GRUB_TIMEOUT '5'
    set_grub_key GRUB_TIMEOUT_STYLE 'menu'
    set_grub_key GRUB_GFXPAYLOAD_LINUX 'keep'

    log "Installing GRUB to the ESP"
    sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck
    [ -f /boot/EFI/GRUB/grubx64.efi ] || die "grub-install produced no /boot/EFI/GRUB/grubx64.efi."

    generate_menu "$esp_uuid"
}

# --------------------------------------------------------------------------
# OS detection
# --------------------------------------------------------------------------

generate_menu() {
    local esp_uuid=${1:-$(findmnt -no UUID /boot)}

    log "Generating the GRUB menu (os-prober scans for other systems)"
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    # os-prober can miss Windows when its EFI System Partition is the very one
    # mounted at /boot, as it is here. Chainload it explicitly rather than ship
    # a menu with no Windows in it.
    if grep -qi "bootmgfw.efi" /boot/grub/grub.cfg; then
        info "os-prober found Windows"
    elif [ -f /boot/EFI/Microsoft/Boot/bootmgfw.efi ]; then
        warn "os-prober missed Windows; adding an explicit chainload entry"
        sudo tee /etc/grub.d/40_custom >/dev/null <<EOF
#!/bin/sh
exec tail -n +3 \$0
# Entries below are added to the end of the GRUB menu.

# os-prober does not reliably detect Windows when its EFI System Partition is
# the same one mounted at /boot, so chainload the Windows boot manager directly.
menuentry "Windows Boot Manager" --class windows --class os {
    insmod part_gpt
    insmod fat
    insmod chain
    search --no-floppy --fs-uuid --set=root ${esp_uuid}
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
        sudo chmod +x /etc/grub.d/40_custom
        sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi

    verify_menu
}

# Refuse to leave the machine with a menu that cannot boot it.
verify_menu() {
    local entries
    entries=$(grep -cE "^\s*menuentry " /boot/grub/grub.cfg || true)

    grep -qE "^\s*menuentry .*(Arch|Linux)" /boot/grub/grub.cfg \
        || die "grub.cfg contains no Arch entry. Check that /etc/grub.d/10_linux is executable and that /boot/vmlinuz-linux and /boot/initramfs-linux.img both exist. Do NOT reboot into GRUB until this is fixed."

    grep -q "initramfs-linux.img" /boot/grub/grub.cfg \
        || warn "no initramfs referenced in grub.cfg - check the Arch entry by hand"

    info "$entries menu entries generated"
}

list_menu_entries() {
    grep -E "^\s*(menuentry|submenu) '" /boot/grub/grub.cfg \
        | sed -E "s/^[[:space:]]*(menuentry|submenu) '([^']*)'.*/    - \2/"
}

detect_os() {
    using_grub || die "GRUB is not installed yet. Run: $0 grub"
    require_sudo
    generate_menu
    echo
    info "GRUB menu entries:"
    list_menu_entries
    ok "OS detection complete."
}

# --------------------------------------------------------------------------
# Boot-time failures
# --------------------------------------------------------------------------

# Two units fail on every boot on this machine, both left over from a btrfs
# layout that no longer exists - the root filesystem is ext4.
fix_failing_boot_units() {
    log "Clearing boot-time unit failures"

    # fstab still lists a btrfs hibernation swapfile that was never created.
    # zram provides this machine's swap.
    if grep -q "^/swap/swapfile" /etc/fstab && [ ! -f /swap/swapfile ]; then
        sudo cp /etc/fstab /etc/fstab.bak
        sudo sed -i '/^# Btrfs swapfile for system hibernation$/d; /^\/swap\/swapfile/d' /etc/fstab
        sudo systemctl daemon-reload
        info "removed the missing /swap/swapfile entry from fstab (backup: /etc/fstab.bak)"
    fi

    # snapper only manages btrfs subvolumes; on ext4 its timers fail nightly.
    if systemctl list-unit-files snapper-cleanup.timer &>/dev/null \
       && [ "$(findmnt -no FSTYPE /)" != "btrfs" ]; then
        sudo systemctl disable --now snapper-cleanup.timer snapper-timeline.timer &>/dev/null || true
        sudo systemctl reset-failed snapper-cleanup.service &>/dev/null || true
        info "disabled snapper timers (root is $(findmnt -no FSTYPE /), not btrfs)"
    fi
}

# --------------------------------------------------------------------------
# Boot order
# --------------------------------------------------------------------------

# efibootmgr prints "Boot0000* GRUB<TAB>HD(1,GPT,...)" on this machine - the
# device path is there even without -v - so match the label field exactly
# rather than anchoring on end of line.
efi_entry_num() {
    sudo efibootmgr | awk -F'\t' -v want="$1" '
        $1 ~ /^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/ {
            num = substr($1, 5, 4)
            label = $1
            sub(/^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\*? +/, "", label)
            if (label == want) { print num; exit }
        }'
}

# Boot GRUB exactly once, leaving Limine as the standing default. A failed
# GRUB boot then needs no user intervention at all to recover.
set_boot_next() {
    log "Arming GRUB for a one-shot test boot"
    local grub_num limine_num
    grub_num=$(efi_entry_num GRUB)
    [ -n "$grub_num" ] || die "No GRUB entry in NVRAM after grub-install. BootOrder is untouched, so this machine still boots Limine."

    # grub-install prepends its own entry to BootOrder, which would make GRUB the
    # standing default and defeat the whole point of a one-shot test. Put Limine
    # back in front so a failed GRUB boot recovers on a plain power cycle.
    limine_num=$(efi_entry_num Limine)
    if [ -n "$limine_num" ]; then
        local current_order new_order n
        current_order=$(sudo efibootmgr | sed -n 's/^BootOrder: //p')
        new_order=$limine_num
        for n in ${current_order//,/ }; do
            [ "$n" = "$limine_num" ] || new_order+=",$n"
        done
        sudo efibootmgr -o "$new_order" >/dev/null
        info "BootOrder: $new_order (Limine first - the standing default)"
    else
        warn "no Limine entry in NVRAM; GRUB will be the standing default with no automatic fallback"
    fi

    # Set BootNext last: it must survive the BootOrder rewrite above.
    sudo efibootmgr -n "$grub_num" >/dev/null
    info "BootNext=$grub_num (GRUB) - next restart only"
}

set_boot_order() {
    log "Setting the firmware boot order"

    local grub_num limine_num current_order new_order n
    grub_num=$(efi_entry_num GRUB)
    limine_num=$(efi_entry_num Limine)

    [ -n "$grub_num" ] || die "No GRUB entry in NVRAM after grub-install. Limine is still first in the boot order, so the machine remains bootable."

    current_order=$(sudo efibootmgr | sed -n 's/^BootOrder: //p')
    new_order=$grub_num
    [ -n "$limine_num" ] && new_order+=",$limine_num"
    for n in ${current_order//,/ }; do
        [ "$n" = "$grub_num" ] && continue
        [ "$n" = "${limine_num:-}" ] && continue
        new_order+=",$n"
    done

    sudo efibootmgr -o "$new_order" >/dev/null
    info "BootOrder: $new_order  (GRUB=$grub_num, Limine=${limine_num:-none})"
}

# --------------------------------------------------------------------------
# Retire Limine
# --------------------------------------------------------------------------

# Delete every trace of Limine and hand its EFI fallback path to GRUB.
purge_limine() {
    log "Removing Limine"

    drop_limine_pkgs limine limine-mkinitcpio-hook limine-snapper-sync

    # limine-snapper-sync leaves units behind that would fail on every boot once
    # there is no limine.conf for them to write into.
    sudo systemctl disable --now limine-snapper-sync.service limine-snapper-sync.timer &>/dev/null || true

    # /boot/EFI/Linux holds only the unified kernel images Limine booted; with
    # GRUB on a normal kernel + initramfs nothing reads them any more. This is
    # where the 51 MB comes back.
    sudo rm -rf /boot/EFI/limine /boot/EFI/Linux
    sudo rm -f /boot/limine.conf /boot/limine.conf.bak /boot/limine.conf.old
    sudo rm -rf /etc/limine-entry-tool.d /etc/limine-entry-tool.conf /var/lib/limine
    info "removed Limine's files from the ESP"

    local limine_num
    limine_num=$(efi_entry_num Limine)
    [ -n "$limine_num" ] && { sudo efibootmgr -b "$limine_num" -B >/dev/null; info "removed the Limine NVRAM entry"; }

    # EFI/BOOT/BOOTX64.EFI is still Limine's copy. Overwrite it with GRUB so the
    # firmware's default fallback path keeps working if the NVRAM entry is ever
    # lost - otherwise deleting Limine leaves a dead pointer there.
    log "Claiming the removable EFI fallback path for GRUB"
    sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable --recheck
}

# Only worth attempting once Limine's UKI has freed up room on the ESP.
enable_fallback_initramfs() {
    log "Enabling the fallback initramfs"
    sudo sed -i "s|^PRESETS=.*|PRESETS=('default' 'fallback')|" /etc/mkinitcpio.d/linux.preset
    if ! rebuild_initramfs; then
        warn "the fallback initramfs did not build - reverting to the default preset only"
        sudo sed -i "s|^PRESETS=.*|PRESETS=('default')|" /etc/mkinitcpio.d/linux.preset
        sudo rm -f /boot/initramfs-linux-fallback.img
        rebuild_initramfs
    fi
}

cleanup_limine() {
    using_grub || die "GRUB is not installed. Run: $0 grub"
    require_sudo

    # Only safe once the machine has actually come up through GRUB.
    local current
    current=$(sudo efibootmgr | sed -n 's/^BootCurrent: //p')
    [ -n "$current" ] || die "Cannot determine the current boot entry."
    sudo efibootmgr | grep -qE "^Boot${current}\*?[[:space:]]+GRUB" \
        || die "This session did not boot through GRUB (BootCurrent=$current). Reboot first - GRUB is armed for the next restart - then run this again."

    purge_limine
    set_boot_order
    enable_fallback_initramfs
    generate_menu

    echo
    df -h /boot | tail -1 | sed 's/^/    /'
    echo
    info "GRUB menu entries:"
    list_menu_entries
    ok "Limine is gone. GRUB is now the only bootloader."
}

# --------------------------------------------------------------------------
# Status
# --------------------------------------------------------------------------

show_status() {
    log "Bootloader"
    if using_grub; then
        info "GRUB installed at /boot/EFI/GRUB/grubx64.efi"
    else
        warn "GRUB is not installed"
    fi
    pacman -Qq limine &>/dev/null && warn "limine is still installed"
    [ -e /usr/local/bin/mkinitcpio ] && warn "/usr/local/bin/mkinitcpio shadows /usr/bin/mkinitcpio"

    log "Kernel images"
    ls -lh /boot/vmlinuz-linux /boot/initramfs-linux*.img /boot/EFI/Linux/*.efi 2>/dev/null \
        | awk '{print "    " $5 "\t" $9}'

    log "ESP usage"
    df -h /boot | tail -1 | sed 's/^/    /'

    if [ -f /boot/grub/grub.cfg ]; then
        log "GRUB menu entries"
        list_menu_entries
    fi

    log "Firmware boot order"
    sudo efibootmgr 2>/dev/null | grep -E "^(BootCurrent|BootOrder|Boot[0-9A-F]{4})" \
        | grep -viE "USB|Setup|Boot Menu|Diagnostics|NVMe:" | sed 's/^/    /'

    log "Failed units"
    systemctl --failed --no-pager --no-legend | sed 's/^/    /' || info "none"
}

# --------------------------------------------------------------------------

case "${1:-}" in
    grub|migrate)  migrate_to_grub "${2:-}" ;;
    detect|osprobe) detect_os ;;
    cleanup)       cleanup_limine ;;
    status)        show_status ;;
    -h|--help|help)
        sed -n '3,11p' "$0" | sed 's/^# \?//'
        ;;
    *)             apply_splash "${1:-}" ;;
esac
