#!/bin/bash
if [ "$EUID" -ne 0 ]; then
    exec sudo "$0" "$@"
fi

# ==============================================================================
# Arch Linux: NetworkManager -> iwd Migration (GMU Eduroam Edition)
# ==============================================================================
# 
# PREREQUISITES:
# 1. Run as root (sudo).
# 2. Know your GMU NetID and password.
#
# WHAT THIS DOES:
# 1. Disables NetworkManager & wpa_supplicant to prevent conflicts.
# 2. Enables iwd with built-in DHCP (network configuration).
# 3. Sets up systemd-resolved for DNS.
# 4. Creates the secure eduroam profile in /var/lib/iwd/
# ==============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Switching to iwd for GMU Eduroam ===${NC}"

# 1. INSTALL IWD (If missing)
if ! command -v iwctl &> /dev/null; then
    echo "iwd not found. Installing..."
    pacman -S --noconfirm iwd
fi

# 2. GATHER CREDENTIALS
echo ""
echo "Enter your GMU credentials."
read -p "GMU Email (e.g., jdoe@gmu.edu): " IDENTITY
read -s -p "Password: " PASSWORD
echo ""

# 3. STOP CONFLICTING SERVICES
echo -e "\n${GREEN}[1/5] Stopping NetworkManager & wpa_supplicant...${NC}"
systemctl stop NetworkManager
systemctl disable NetworkManager
pkill wpa_supplicant

# 4. CONFIGURE IWD (Enable Built-in DHCP)
echo -e "${GREEN}[2/5] Configuring iwd main.conf...${NC}"
mkdir -p /etc/iwd
cat > /etc/iwd/main.conf <<EOF
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF

# 5. CONFIGURE DNS (systemd-resolved)
echo -e "${GREEN}[3/5] Setting up systemd-resolved DNS...${NC}"
systemctl enable --now systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# 6. CREATE EDUROAM CONFIG
echo -e "${GREEN}[4/5] Creating eduroam provisioning file...${NC}"
cat > /var/lib/iwd/eduroam.8021x <<EOF
[Security]
EAP-Method=PEAP
EAP-Identity=$IDENTITY
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=$IDENTITY
EAP-PEAP-Phase2-Password=$PASSWORD
EOF

chmod 600 /var/lib/iwd/eduroam.8021x

# 7. START IWD & CONNECT
echo -e "${GREEN}[5/5] Starting iwd and connecting...${NC}"
systemctl enable --now iwd
sleep 2

IFACE=$(iwctl device list | grep station | awk '{print $2}' | head -n 1)

if [ -z "$IFACE" ]; then
    echo -e "${RED}Error: No wireless interface found!${NC}"
    echo "Check 'iwctl device list' manually."
    exit 1
fi

echo "Detected Interface: $IFACE"
echo "Scanning..."
iwctl station "$IFACE" scan
sleep 2
echo "Connecting to eduroam..."
iwctl station "$IFACE" connect eduroam

# 8. VERIFY
sleep 5
STATUS=$(iwctl station "$IFACE" show | grep "State" | awk '{print $2}')

if [ "$STATUS" == "connected" ]; then
    echo -e "\n${GREEN}SUCCESS! Connected to eduroam.${NC}"
    echo "Testing connectivity (pinging google.com)..."
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${GREEN}Internet is WORKING.${NC}"
    else
        echo -e "${RED}Connected to WiFi, but no Internet.${NC}"
        echo "Check DNS: cat /etc/resolv.conf"
    fi
else
    echo -e "\n${RED}Connection failed.${NC}"
    echo "Debug with: iwctl station $IFACE get-networks"
fi
