#!/usr/bin/env bash
set -euo pipefail

PLIST_LABEL="dev.ognio.inc-renamer"
PLIST_TARGET="/Library/LaunchDaemons/${PLIST_LABEL}.plist"
BIN_TARGET="/usr/local/bin/inc-renamer"

if sudo launchctl print system/${PLIST_LABEL} >/dev/null 2>&1; then
  sudo launchctl bootout system/${PLIST_TARGET} || true
fi

sudo rm -f "$PLIST_TARGET"
sudo rm -f "$BIN_TARGET"

echo "Uninstalled ${PLIST_LABEL}"
