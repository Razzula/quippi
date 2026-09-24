#!/usr/bin/env bash
set -euo pipefail

echo "=== Quippi ==="
sudo systemctl status quippi.service --no-pager

echo
echo "=== Thwip ==="
sudo systemctl status thwip.service --no-pager
