#!/usr/bin/env bash
set -euo pipefail

echo "Installing dependencies..."

sudo apt update
sudo apt install -y podman

echo "Enabling upstream..."
sudo systemctl enable --now podman-auto-update.timer

echo "Setup complete."
