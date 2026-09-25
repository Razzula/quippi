#!/usr/bin/env bash
set -euo pipefail

echo "Installing Quadlet units..."

sudo mkdir -p /etc/containers/systemd

sudo cp quippi.container /etc/containers/systemd/
sudo cp thwip.container /etc/containers/systemd/

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Updating containers..."
sudo podman auto-update

echo "Spinning up services..."
sudo systemctl restart quippi.service
sudo systemctl restart thwip.service

echo "Installation complete."
