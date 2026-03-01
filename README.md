<p align="center">
  <img src="assets/images/inc-renamer-icon-1024.png" alt="inc-renamer icon" width="520" />
</p>

# inc-renamer monorepo

`inc-renamer` is a cross-platform background utility suite that continuously fixes wrongly named image files exported as `*.inc`.

It runs as a native startup service on each operating system, watches a target folder (typically Downloads), inspects file signatures (magic bytes), and renames files to the real extension (`.png`, `.jpg`, `.gif`, `.webp`, `.bmp`, `.tiff`, `.heic`, `.heif`) without prompts.

This is especially useful for browser/web extraction workflows (including WhatsApp Web profile-picture exports) where image bytes are correct but filename extensions are lost or mislabeled during download/export.

## What You Get

- Native implementation per platform (macOS, Linux, Windows)
- Auto-start service integration for each OS (`launchd`, `systemd`, Task Scheduler)
- Collision-safe renaming (`file-1.png`, `file-2.png`, ...)
- Plain text operational logs
- Integration tests and CI builds across all three targets

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
