# Code Overview

This project is intentionally small. The main behaviour lives in:

- `scripts/bing-wallpaper-macos`
- `LaunchAgents/com.bing-wallpaper-macos.agent.plist.template`
- `install.sh`
- `uninstall.sh`

## What the script does

The script:

1. Creates `~/Pictures/Bing Wallpaper` if it does not already exist.
2. Checks `.last-success-date` to see whether today's wallpaper has already been set successfully.
3. Checks `latest.json` to work out which local Bing image should exist.
4. If today is already marked successful and the image still exists, it exits without doing unnecessary work.
5. If the image is missing, or today has not succeeded yet, it calls Bing's wallpaper metadata endpoint.
6. It downloads the UHD image when available.
7. It verifies the downloaded file is a valid image using `sips`.
8. It sets the macOS wallpaper.
9. It only writes `.last-success-date` after the wallpaper has been confirmed as set.
10. It deletes older downloaded Bing images, keeping only the current one.

## Why it retries

The LaunchAgent runs the script every 10 minutes. The script is safe to run repeatedly because it normally exits early after a successful update.

If Wi-Fi is unavailable, Bing is unreachable, the download fails, or macOS does not confirm the wallpaper was set, the script exits without marking the day successful. That means launchd will try again later.

## Why `.last-success-date` exists

The file `.last-success-date` records the last date on which the wallpaper was successfully downloaded and set.

This prevents repeated downloads throughout the day while still allowing recovery if the local image is deleted.

## Why `latest.json` exists

`latest.json` stores Bing's most recent wallpaper metadata. The script uses it to know which local image file should exist for the current Bing image.

This is how the script can notice that today was marked successful but the local wallpaper image has been deleted.

## Why `desktoppr` is used

macOS wallpaper setting can be unreliable through AppleScript alone, especially when other wallpaper tools have previously modified desktop state.

The script tries `desktoppr` first because it is a direct command-line wallpaper setter. If `desktoppr` does not verify the expected wallpaper path, the script falls back to AppleScript/System Events.

## Why old images are deleted

The project is designed to keep the current Bing wallpaper, not build a long-term wallpaper archive.

After a successful update, old `bing-*.jpg` files are removed from the wallpaper folder.

## Enable and disable behaviour

The updater can be paused without uninstalling the LaunchAgent.

Running:

    bing-wallpaper-macos disable

creates a `.disabled` marker file in `~/Pictures/Bing Wallpaper/`.

When that marker exists, scheduled launchd runs exit immediately and leave the current wallpaper unchanged.

Running:

    bing-wallpaper-macos enable

removes the marker file and allows the next scheduled run to update the wallpaper again.

Running:

    bing-wallpaper-macos status

shows whether updates are currently enabled or disabled.

## Short command alias

The installer creates a short convenience command:

    bing-wallpaper

This is a symlink to the installed script:

    bing-wallpaper-macos

Both commands run the same updater and support the same arguments, including `enable`, `disable`, and `status`.

## Managed wallpaper behaviour

When enabled, the script acts as a small wallpaper manager rather than just a once-per-day downloader.

After a successful daily update, later scheduled runs still check that the expected Bing image exists and is still the current desktop wallpaper.

If the image file has been deleted, the script downloads it again.

If the image exists but the desktop wallpaper has been changed, the script restores the Bing wallpaper without re-downloading it.

If updates are disabled using `bing-wallpaper disable`, the script exits immediately and leaves the current desktop wallpaper unchanged.

## Platform layout

The repository is split by platform.

macOS-specific files live in:

    macos/

Windows-specific files will live in:

    windows/

The root `install.sh` and `uninstall.sh` files are guide scripts only. They do not install anything directly. The user must explicitly choose the platform installer.

## Windows implementation

The Windows implementation lives in:

    windows/

The main updater is:

    windows/scripts/bing-wallpaper-windows.ps1

The installer is:

    windows/install.ps1

The Windows version uses PowerShell, Windows Task Scheduler, the user's Pictures folder, and a small `bing-wallpaper.cmd` launcher.

It follows the same managed wallpaper behaviour as the macOS version: retry until successful, re-download if the image is deleted, and restore the Bing wallpaper if the desktop wallpaper is changed while updates are enabled.

