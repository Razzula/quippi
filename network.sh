#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:?Usage: $0 <env-file> [connection-name]}"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "Error: $ENV_FILE not found." >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

: "${WIFI_SSID:?WIFI_SSID is not set in $ENV_FILE}"
: "${WIFI_PASSWORD:?WIFI_PASSWORD is not set in $ENV_FILE}"

CONNECTION_NAME="${2:-${CONNECTION_NAME:-$WIFI_SSID}}"
WIFI_INTERFACE="${WIFI_INTERFACE:-wlan0}"
WIFI_PRIORITY="${WIFI_PRIORITY:-0}"
WIFI_AUTOCONNECT="${WIFI_AUTOCONNECT:-yes}"
WIFI_KEY_MGMT="${WIFI_KEY_MGMT:-wpa-psk}"

echo "Configuring Wi-Fi network: $WIFI_SSID"
echo "Connection name: $CONNECTION_NAME"

if nmcli connection show "$CONNECTION_NAME" >/dev/null 2>&1; then
    echo "Connection already exists; updating it..."
    sudo nmcli connection modify "$CONNECTION_NAME" \
        connection.interface-name "$WIFI_INTERFACE" \
        connection.autoconnect "$WIFI_AUTOCONNECT" \
        connection.autoconnect-priority "$WIFI_PRIORITY" \
        wifi.ssid "$WIFI_SSID" \
        wifi-sec.key-mgmt "$WIFI_KEY_MGMT" \
        wifi-sec.psk "$WIFI_PASSWORD"
else
    sudo nmcli connection add \
        type wifi \
        ifname "$WIFI_INTERFACE" \
        con-name "$CONNECTION_NAME" \
        ssid "$WIFI_SSID" \
        connection.autoconnect "$WIFI_AUTOCONNECT" \
        connection.autoconnect-priority "$WIFI_PRIORITY" \
        wifi-sec.key-mgmt "$WIFI_KEY_MGMT" \
        wifi-sec.psk "$WIFI_PASSWORD"
fi

echo "Wi-Fi configuration complete."
