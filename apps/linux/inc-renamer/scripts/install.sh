#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVICE_NAME="dev.ognio.inc-renamer.service"
SERVICE_TEMPLATE="$ROOT_DIR/systemd/${SERVICE_NAME}.template"
SERVICE_TARGET="/etc/systemd/system/${SERVICE_NAME}"
BIN_TARGET="/usr/local/bin/inc-renamer"

RUN_USER="${RUN_USER:-$(id -un)}"
HOME_DIR="${HOME_DIR:-$HOME}"
WATCH_DIR="${WATCH_DIR:-$HOME_DIR/Downloads}"
LOG_DIR="${LOG_DIR:-$HOME_DIR/.local/state/inc-renamer}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/inc-renamer.log}"
STDOUT_FILE="${STDOUT_FILE:-$LOG_DIR/inc-renamer.stdout.log}"
STDERR_FILE="${STDERR_FILE:-$LOG_DIR/inc-renamer.stderr.log}"

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

cd "$ROOT_DIR"
make
mkdir -p "$LOG_DIR"

TMP_SERVICE="$(mktemp /tmp/inc-renamer.service.XXXXXX)"
trap 'rm -f "$TMP_SERVICE"' EXIT

sed \
  -e "s|__USER__|$(escape_sed "$RUN_USER")|g" \
  -e "s|__WATCH_DIR__|$(escape_sed "$WATCH_DIR")|g" \
  -e "s|__LOG_PATH__|$(escape_sed "$LOG_FILE")|g" \
  -e "s|__STDOUT_PATH__|$(escape_sed "$STDOUT_FILE")|g" \
  -e "s|__STDERR_PATH__|$(escape_sed "$STDERR_FILE")|g" \
  "$SERVICE_TEMPLATE" > "$TMP_SERVICE"

sudo install -m 755 ./inc-renamer "$BIN_TARGET"
sudo install -m 644 "$TMP_SERVICE" "$SERVICE_TARGET"
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"

echo "Installed and started $SERVICE_NAME"
echo "Watching: $WATCH_DIR"
echo "Log file: $LOG_FILE"
