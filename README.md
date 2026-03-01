# inc-renamer monorepo

Cross-platform `*.inc` image-extension repair toolset.

This monorepo contains platform-specific service implementations that watch a folder, detect real image formats by magic bytes, and rename files from `*.inc` to the proper extension.

## Assets

Project icon files:

- `assets/images/inc-renamer-icon-1024.png` (source)
- `assets/images/inc-renamer-icon-256.png` (resized)

Icon preview:

<p align="center">
  <img src="assets/images/inc-renamer-icon-1024.png" alt="inc-renamer icon" width="520" />
</p>

## Repository layout

- `apps/macos/inc-renamer`: Production-ready macOS daemon + `launchd` installer.
- `apps/linux/inc-renamer`: Linux daemon + `systemd` installer.
- `apps/windows/inc-renamer`: Windows daemon + Task Scheduler installer.

## Current status

- macOS: `1.0.0` implemented
- Linux: `0.1.0` implementation ready (host validation pending)
- Windows: `0.1.0` implementation ready (host validation pending)

Per-platform version files:

- `apps/macos/inc-renamer/VERSION`
- `apps/linux/inc-renamer/VERSION`
- `apps/windows/inc-renamer/VERSION`

Root `VERSION` is monorepo metadata; release versions for binaries are platform-specific.

## Why this exists

Some extraction workflows (including WhatsApp Web profile-picture extraction flows) can write valid image bytes with an incorrect `.inc` suffix. These services automatically correct extensions so files open normally in platform tooling.

## Quick start

### macOS

```bash
cd apps/macos/inc-renamer
./scripts/install.sh
```

### Linux

```bash
cd apps/linux/inc-renamer
./scripts/install.sh
```

### Windows

```powershell
cd apps/windows/inc-renamer
./scripts/install-task.ps1
```

## CI

A GitHub Actions matrix build validates all three targets:

- `.github/workflows/build.yml`
# inc-renamer
