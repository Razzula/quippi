#!/usr/bin/env bash
set -euo pipefail

CONFIG=/boot/firmware/config.txt
CMDLINE=/boot/firmware/cmdline.txt

USB_IF="usb0"
USB_IP="192.168.7.2/24"
CON_NAME="USB Ethernet"

echo "Checking Raspberry Pi model..."

MODEL="$(tr -d '\0' < /proc/device-tree/model)"

if [[ "$MODEL" != Raspberry\ Pi\ Zero\ 2\ W* ]]; then
    echo "ERROR: This script is intended for a Raspberry Pi Zero 2 W."
    echo "Detected: $MODEL"
    exit 1
fi

echo "Detected: $MODEL"
echo

echo "Installing dependencies..."

sudo apt update
sudo apt install -y podman openssh-server avahi-daemon network-manager

echo "Enabling Podman auto-update..."
sudo systemctl enable --now podman-auto-update.timer

echo "Enabling SSH..."
sudo systemctl enable --now ssh

echo "Enabling mDNS..."
sudo systemctl enable --now avahi-daemon

echo "Configuring USB Ethernet gadget..."

# Raspberry Pi Zero 2 W uses the DWC2 USB controller for gadget mode.
#
# Remove any existing dwc2 overlay and replace it with one explicitly
# configured for peripheral mode.
sudo sed -i '/^[[:space:]]*dtoverlay=dwc2/d' "$CONFIG"

# Enable the DWC2 USB controller.
echo 'dtoverlay=dwc2' | sudo tee -a "$CONFIG" >/dev/null

# Ensure the USB Ethernet gadget modules are loaded at boot.
if grep -qw 'modules-load=' "$CMDLINE"; then
    sudo sed -i \
        's/modules-load=[^ ]*/modules-load=dwc2,g_ether/' \
        "$CMDLINE"
else
    sudo sed -i \
        '1s/$/ modules-load=dwc2,g_ether/' \
        "$CMDLINE"
fi

echo "Configuring NetworkManager..."

# Remove an existing connection so the configuration is deterministic.
if nmcli connection show "$CON_NAME" >/dev/null 2>&1; then
    sudo nmcli connection delete "$CON_NAME"
fi

sudo nmcli connection add \
    type ethernet \
    ifname "$USB_IF" \
    con-name "$CON_NAME" \
    ipv4.method manual \
    ipv4.addresses "$USB_IP" \
    ipv6.method disabled \
    connection.autoconnect yes

echo
echo "Verifying configuration..."

ERRORS=0

if grep -qx 'dtoverlay=dwc2' "$CONFIG"; then
    echo "✓ DWC2 overlay configured"
else
    echo "✗ DWC2 overlay missing"
    ERRORS=$((ERRORS + 1))
fi

if grep -qw 'modules-load=dwc2,g_ether' "$CMDLINE"; then
    echo "✓ USB gadget modules configured"
else
    echo "✗ USB gadget modules missing"
    ERRORS=$((ERRORS + 1))
fi

if modinfo g_ether >/dev/null 2>&1; then
    echo "✓ g_ether kernel module available"
else
    echo "✗ g_ether kernel module unavailable"
    ERRORS=$((ERRORS + 1))
fi

if nmcli connection show "$CON_NAME" >/dev/null 2>&1; then
    echo "✓ NetworkManager USB Ethernet connection configured"
else
    echo "✗ NetworkManager USB Ethernet connection missing"
    ERRORS=$((ERRORS + 1))
fi

if [[ "$ERRORS" -ne 0 ]]; then
    echo
    echo "Setup failed verification with $ERRORS error(s)."
    exit 1
fi

echo
echo "Configuration verified successfully."
echo
echo "A reboot is required to activate USB Ethernet."
echo
echo "After reboot, verify with:"
echo
echo "  ls /sys/class/udc"
echo "  ip addr show $USB_IF"
echo
echo "Expected:"
echo "  A UDC device should be present."
echo "  $USB_IF should have $USB_IP"
echo
echo "SSH:"
echo "  ssh $(whoami)@192.168.7.2"
echo "  ssh $(whoami)@$(hostname).local"
echo
echo "Connect the Pi Zero 2 W's USB DATA/OTG port (not PWR) to your device."
