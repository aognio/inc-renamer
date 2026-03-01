#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_LABEL="dev.ognio.inc-renamer"
PLIST_TARGET="/Library/LaunchDaemons/${PLIST_LABEL}.plist"
PLIST_TEMPLATE="$ROOT_DIR/launchd/dev.ognio.inc-renamer.plist.template"
BIN_TARGET="/usr/local/bin/inc-renamer"

RUN_USER="${RUN_USER:-$(id -un)}"
HOME_DIR="${HOME_DIR:-$HOME}"
WATCH_DIR="${WATCH_DIR:-$HOME_DIR/Downloads}"
LOG_DIR="${LOG_DIR:-$HOME_DIR/Library/Logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/inc-renamer.log}"
STDOUT_FILE="${STDOUT_FILE:-$LOG_DIR/inc-renamer.stdout.log}"
STDERR_FILE="${STDERR_FILE:-$LOG_DIR/inc-renamer.stderr.log}"

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

cd "$ROOT_DIR"
make

mkdir -p "$LOG_DIR"

TMP_PLIST="$(mktemp /tmp/inc-renamer.plist.XXXXXX)"
trap 'rm -f "$TMP_PLIST"' EXIT

sed \
  -e "s|__LABEL__|$(escape_sed "$PLIST_LABEL")|g" \
  -e "s|__BIN__|$(escape_sed "$BIN_TARGET")|g" \
  -e "s|__WATCH_DIR__|$(escape_sed "$WATCH_DIR")|g" \
  -e "s|__LOG_PATH__|$(escape_sed "$LOG_FILE")|g" \
  -e "s|__STDOUT_PATH__|$(escape_sed "$STDOUT_FILE")|g" \
  -e "s|__STDERR_PATH__|$(escape_sed "$STDERR_FILE")|g" \
  -e "s|__USER__|$(escape_sed "$RUN_USER")|g" \
  "$PLIST_TEMPLATE" > "$TMP_PLIST"

sudo install -m 755 ./inc-renamer "$BIN_TARGET"
sudo install -m 644 "$TMP_PLIST" "$PLIST_TARGET"

if sudo launchctl print system/${PLIST_LABEL} >/dev/null 2>&1; then
  sudo launchctl bootout system/${PLIST_TARGET} || true
fi

sudo launchctl bootstrap system "$PLIST_TARGET"
sudo launchctl enable system/${PLIST_LABEL}
sudo launchctl kickstart -k system/${PLIST_LABEL}

echo "Installed and started ${PLIST_LABEL}"
echo "Watching: ${WATCH_DIR}"
echo "Log file: ${LOG_FILE}"
