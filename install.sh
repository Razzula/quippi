#!/usr/bin/env bash
set -euo pipefail

echo "Installing Quadlet units..."

sudo mkdir -p /etc/containers/systemd

sudo cp quippi.container /etc/containers/systemd/
sudo cp thwip.container /etc/containers/systemd/

echo "Reloading systemd..."
sudo systemctl daemon-reload

echo "Spinning up services..."
sudo systemctl start quippi.service
sudo systemctl start thwip.service

echo "Installation complete."
