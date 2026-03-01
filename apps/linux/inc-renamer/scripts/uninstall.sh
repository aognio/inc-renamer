#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="dev.ognio.inc-renamer.service"
SERVICE_TARGET="/etc/systemd/system/${SERVICE_NAME}"
BIN_TARGET="/usr/local/bin/inc-renamer"

sudo systemctl disable --now "$SERVICE_NAME" || true
sudo rm -f "$SERVICE_TARGET"
sudo rm -f "$BIN_TARGET"
sudo systemctl daemon-reload

echo "Uninstalled $SERVICE_NAME"
