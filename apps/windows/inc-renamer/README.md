# inc-renamer (Windows)

Windows implementation for auto-renaming `*.inc` files to real image extensions.

## Current status

- Version: `0.1.0`
- Core daemon implementation: ready (`src/inc_renamer_daemon.cpp`)
- Startup model: Task Scheduler scripts
- Local runner: `scripts/run-local.ps1`
- Integration test: `tests/integration_test.ps1`
- Runtime validation on target Windows hosts: pending

## Build

```powershell
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```

## Test

```powershell
./tests/integration_test.ps1
```

## Run locally

```powershell
./scripts/run-local.ps1
```

## Install startup task

```powershell
./scripts/install-task.ps1
```

Default trigger is `AtLogOn` (recommended for user Downloads monitoring).
Use startup trigger explicitly if needed:

```powershell
./scripts/install-task.ps1 -AtStartup
```

Optional arguments:

```powershell
./scripts/install-task.ps1 -WatchDir "$env:USERPROFILE\\Downloads" -LogPath "$env:LOCALAPPDATA\\inc-renamer\\inc-renamer.log"
```

## Uninstall startup task

```powershell
./scripts/uninstall-task.ps1
```
