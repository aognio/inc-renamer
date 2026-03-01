# inc-renamer (macOS)

A lightweight C daemon that watches a folder and auto-renames files ending in `.inc` to the correct image extension by checking file signature bytes.

Version: `1.0.0`

## Use case

Some tools export images with a wrong `.inc` suffix. A common case is assets pulled from web sessions (for example, profile pictures from WhatsApp Web exports) where files are valid images but have the wrong extension.

`inc-renamer` fixes this automatically so files open correctly in Finder, Preview, and image tooling.

## Known source: WhatsApp Web profile pictures

This project is explicitly useful for WhatsApp Web profile-picture extraction workflows where downloaded files can appear as `*.inc` even though their bytes are valid PNG/JPEG/WEBP images.

### Why this can happen (especially visible on macOS)

- WhatsApp Web profile photos are fetched as web media resources (often blob/cached resources) and not always as direct file downloads with stable filename metadata.
- The browser can know the MIME type in memory, but third-party extraction flows (extensions, scripts, devtools copy/save flows, cache exporters) may not preserve that metadata when writing files.
- If the exporting tool cannot map MIME to a known extension, it may fall back to a generic or incorrect suffix such as `.inc`.
- On macOS, Finder/Quick Look rely heavily on file extension for default app association, so a wrong suffix is immediately obvious even when the image bytes are valid.

### Windows comparison checklist

When you test on Windows, compare these points:

- Browser and version (Chrome/Edge/Firefox)
- Download method (direct click/save vs extension/script/devtools)
- Final filename and extension
- Reported MIME type in network/devtools
- Signature bytes (`file` on macOS/Linux, or equivalent tools on Windows)

If MIME and signature still indicate image data but extension is `.inc`, the root issue is the export pipeline, not WhatsApp image encoding itself.

## Features

- Watches a folder continuously (default: `$HOME/Downloads`)
- Every 2 seconds scans for `*.inc`
- Detects real image format from magic bytes (does not trust extension)
- Renames automatically with no prompts
- Handles name collisions (`file-1.png`, `file-2.png`, ...)
- Writes text logs to `$HOME/Library/Logs/inc-renamer.log`
- Installs as a macOS `launchd` boot service

## Design choice: built-in detection vs `file`

This project intentionally uses built-in magic-byte checks inside the daemon instead of calling the external `file` command.

Reasons:

- Lower overhead: no process spawn for every candidate file.
- More predictable runtime: no parsing of command output that can vary by environment.
- Fewer dependencies: no reliance on external command behavior, shell integration, or locale output differences.
- Better service reliability: simpler execution model under `launchd`.

`file` can still be useful when broad, generic format detection is needed. For this tool, the focus is a small, explicit image set with stable and fast detection.

## Supported image formats

| Format | Magic-byte signature (high level) | Output extension |
|---|---|---|
| PNG | `89 50 4E 47 0D 0A 1A 0A` | `.png` |
| JPEG | `FF D8 FF` | `.jpg` |
| GIF | `GIF87a` or `GIF89a` | `.gif` |
| WEBP | `RIFF....WEBP` | `.webp` |
| BMP | `BM` | `.bmp` |
| TIFF | `II 2A 00` or `MM 00 2A` | `.tiff` |
| HEIC | ISO BMFF `ftyp` with HEIC brands (`heic`, `heix`, `hevc`, `hevx`, `mif1`, `msf1`) | `.heic` |
| HEIF | ISO BMFF `ftyp` with brand `heif` | `.heif` |

## Build

```bash
make
```

## Test

```bash
./tests/integration_test.sh
```

## Install as boot service

```bash
./scripts/install.sh
```

The installer builds the binary, installs it to `/usr/local/bin/inc-renamer`, renders a machine-specific plist from `launchd/dev.ognio.inc-renamer.plist.template`, and installs it to `/Library/LaunchDaemons/dev.ognio.inc-renamer.plist`.

## Optional install overrides

You can customize runtime paths at install time:

```bash
WATCH_DIR="$HOME/Downloads" \
LOG_DIR="$HOME/Library/Logs" \
RUN_USER="$(id -un)" \
./scripts/install.sh
```

## Uninstall

```bash
./scripts/uninstall.sh
```

## Verify service

```bash
sudo launchctl print system/dev.ognio.inc-renamer
```

## Tail logs

```bash
tail -f "$HOME/Library/Logs/inc-renamer.log"
```

## Manual test

```bash
cp /path/to/some-image.png "$HOME/Downloads/testfile.inc"
sleep 3
ls -l "$HOME/Downloads"/testfile*
```
