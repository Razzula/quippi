#!/usr/bin/env bash
set -euo pipefail

echo "Installing Quadlet units..."

sudo mkdir -p /etc/containers/systemd

sudo cp quippi.container /etc/containers/systemd/
sudo cp thwip.container /etc/containers/systemd/

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Spinning up services..."
sudo systemctl enable --now quippi.service
sudo systemctl enable --now thwip.service

echo "Installation complete."
