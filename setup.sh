#!/usr/bin/env bash
set -euo pipefail

echo "Installing dependencies..."

sudo apt update
sudo apt install -y podman openssh-server avahi-daemon

echo "Enabling Podman auto-update..."
sudo systemctl enable --now podman-auto-update.timer

echo "Enabling SSH..."
sudo systemctl enable --now ssh

echo "Enabling mDNS..."
sudo systemctl enable --now avahi-daemon

echo "Enabling USB Ethernet gadget..."

CONFIG=/boot/firmware/config.txt
CMDLINE=/boot/firmware/cmdline.txt

# Enable the USB controller in peripheral/gadget mode.
if ! grep -q '^dtoverlay=dwc2' "$CONFIG"; then
    echo 'dtoverlay=dwc2,dr_mode=peripheral' | sudo tee -a "$CONFIG" >/dev/null
fi

# Load the USB Ethernet gadget driver at boot.
if ! grep -qw 'modules-load=dwc2,g_ether' "$CMDLINE"; then
    sudo sed -i \
        '1s/$/ modules-load=dwc2,g_ether/' \
        "$CMDLINE"
fi

echo "Configuring USB Ethernet..."

# Create a NetworkManager connection for the USB gadget.
if ! nmcli connection show "USB Ethernet" >/dev/null 2>&1; then
    sudo nmcli connection add \
        type ethernet \
        ifname usb0 \
        con-name "USB Ethernet" \
        ipv4.method manual \
        ipv4.addresses 192.168.7.2/24 \
        ipv6.method disabled \
        connection.autoconnect yes
fi

echo "Setup complete."
echo
echo "After reboot:"
echo "  USB Ethernet:   192.168.7.2"
echo "  SSH:            ssh $(whoami)@192.168.7.2"
echo "  mDNS:           ssh $(whoami)@$(hostname).local"
echo
echo "Connect the Pi's USB port (not PWR) to your device."
echo "Reboot to enable USB Ethernet gadget mode."
