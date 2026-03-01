#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

make

TMP_DIR="$(mktemp -d)"
LOG_FILE="$TMP_DIR/inc-renamer.log"
PID=""

cleanup() {
  if [[ -n "$PID" ]] && kill -0 "$PID" >/dev/null 2>&1; then
    kill "$PID" >/dev/null 2>&1 || true
    wait "$PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

printf '\x89PNG\r\n\x1A\nrest' > "$TMP_DIR/sample_png.inc"
printf '\xFF\xD8\xFF\xE0rest' > "$TMP_DIR/sample_jpg.inc"
printf 'GIF89a1234' > "$TMP_DIR/sample_gif.inc"
printf 'not-an-image' > "$TMP_DIR/not_image.inc"

printf '\x89PNG\r\n\x1A\norig' > "$TMP_DIR/dup.png"
printf '\x89PNG\r\n\x1A\nnew' > "$TMP_DIR/dup.png.inc"

./inc-renamer "$TMP_DIR" "$LOG_FILE" 1 &
PID=$!
sleep 3
kill "$PID" >/dev/null 2>&1 || true
wait "$PID" >/dev/null 2>&1 || true
PID=""

assert_file() {
  if [[ ! -f "$1" ]]; then
    echo "Expected file missing: $1" >&2
    exit 1
  fi
}

assert_file "$TMP_DIR/sample_png.png"
assert_file "$TMP_DIR/sample_jpg.jpg"
assert_file "$TMP_DIR/sample_gif.gif"
assert_file "$TMP_DIR/not_image.inc"
assert_file "$TMP_DIR/dup.png"
assert_file "$TMP_DIR/dup-1.png"

if ! grep -q "Renamed:" "$LOG_FILE"; then
  echo "Expected rename entries in log" >&2
  exit 1
fi

if ! grep -q "Skipping non-image .inc file" "$LOG_FILE"; then
  echo "Expected non-image skip entries in log" >&2
  exit 1
fi

echo "Linux integration test passed"
