# inc-renamer (Linux)

Linux implementation for auto-renaming `*.inc` files to real image extensions.

## Current status

- Version: `0.1.0`
- Core daemon implementation: ready (`src/inc_renamer_daemon.c`)
- Startup model: `systemd` service template + install scripts
- Local runner: `scripts/run-local.sh`
- Integration test: `tests/integration_test.sh`
- Runtime validation on target Linux hosts: pending

## Build

```bash
make
```

## Test

```bash
./tests/integration_test.sh
```

## Run locally

```bash
./scripts/run-local.sh
```

Optional args:

```bash
./scripts/run-local.sh "$HOME/Downloads" "$HOME/.local/state/inc-renamer/inc-renamer.log" 2
```

## Install systemd service

```bash
./scripts/install.sh
```

Optional overrides:

```bash
WATCH_DIR="$HOME/Downloads" \
LOG_DIR="$HOME/.local/state/inc-renamer" \
RUN_USER="$(id -un)" \
./scripts/install.sh
```

## Uninstall

```bash
./scripts/uninstall.sh
```
