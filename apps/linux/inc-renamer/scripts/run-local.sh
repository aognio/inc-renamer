#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WATCH_DIR="${1:-$HOME/Downloads}"
LOG_DIR="${LOG_DIR:-$HOME/.local/state/inc-renamer}"
LOG_FILE="${2:-$LOG_DIR/inc-renamer.log}"
INTERVAL="${3:-2}"

mkdir -p "$LOG_DIR"
cd "$ROOT_DIR"
make
exec ./inc-renamer "$WATCH_DIR" "$LOG_FILE" "$INTERVAL"
