#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="$(dirname "$0")/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: $ENV_FILE not found." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

: "${WIFI_SSID:?WIFI_SSID is not set in .env}"
: "${WIFI_PASSWORD:?WIFI_PASSWORD is not set in .env}"

echo "Configuring Wi-Fi network: $WIFI_SSID"

if nmcli connection show "$WIFI_SSID" >/dev/null 2>&1; then
    echo "Connection already exists; updating it..."
    sudo nmcli connection modify "$WIFI_SSID" \
        wifi.ssid "$WIFI_SSID" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$WIFI_PASSWORD" \
        connection.autoconnect yes
else
    sudo nmcli connection add \
        type wifi \
        ifname wlan0 \
        con-name "$WIFI_SSID" \
        ssid "$WIFI_SSID" \
        wifi-sec.key-mgmt wpa-psk \
        wifi-sec.psk "$WIFI_PASSWORD" \
        connection.autoconnect yes
fi

echo "Wi-Fi configuration complete."
