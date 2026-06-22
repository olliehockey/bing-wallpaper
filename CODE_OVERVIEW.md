# Code overview

This document describes how `bing-wallpaper` is organised and how the updater works.

## Repository layout

    macos/
      macOS installer, uninstaller, LaunchAgent template, and updater script

    windows/
      Windows installer, uninstaller, command launcher, and updater script

    README.md
      User-facing project documentation

    ATTRIBUTION.md
      Attribution and disclaimer notes

## Platform selection

Installation is explicit by platform.

The root installer scripts are guide scripts only. They detect or describe the platform and point the user to the correct platform folder, but they do not install anything directly.

macOS installation is done from:

    macos/install.sh

Windows installation is done from:

    windows/install.ps1

## Shared behaviour

Both platform implementations follow the same overall workflow.

On each normal run:

1. Check whether updates are disabled.
2. If disabled, exit without changing the wallpaper.
3. Check whether today's image was already successfully set.
4. If today's image is already set as the current wallpaper, exit.
5. If today's image exists but the desktop wallpaper is different, restore it.
6. If today's image is missing, download it again.
7. If today's image has not succeeded yet, download and set it.
8. Record success only after the wallpaper setter verifies the change.

## Managed wallpaper behaviour

When enabled, the updater treats Bing as the managed wallpaper.

That means the updater does not merely download once per day. It also checks that the expected Bing image still exists and is still the active desktop wallpaper.

If the user changes the wallpaper while updates are enabled, the next updater run restores the Bing wallpaper.

If the user deletes the local image file, the next updater run downloads it again.

To temporarily use another wallpaper without automatic restoration, run:

    bing-wallpaper disable

## macOS implementation

The macOS updater is:

    macos/scripts/bing-wallpaper-macos

It is written as a zsh script.

The macOS installer copies it to:

    ~/.local/bin/bing-wallpaper-macos

and creates a shorter symlink:

    ~/.local/bin/bing-wallpaper

Automatic runs are handled by launchd through:

    ~/Library/LaunchAgents/com.bing-wallpaper-macos.agent.plist

The LaunchAgent template lives at:

    macos/LaunchAgents/com.bing-wallpaper-macos.agent.plist.template

The script uses Bing's image metadata endpoint, downloads the image, validates it with `sips`, and sets the wallpaper using `desktoppr` when available, with an AppleScript fallback.

## Windows implementation

The Windows updater is:

    windows/scripts/bing-wallpaper-windows.ps1

It is written in PowerShell.

The Windows installer copies it to:

    %LOCALAPPDATA%\Programs\bing-wallpaper

It also creates a command launcher:

    bing-wallpaper.cmd

Automatic runs are handled by Windows Task Scheduler with a task called:

    Bing Wallpaper

The script uses Bing's image metadata endpoint, downloads the image, validates it with .NET image handling, and sets the wallpaper using the Windows registry plus `SystemParametersInfo`.

## Enable and disable behaviour

The updater can be paused without uninstalling the scheduler.

Disable:

    bing-wallpaper disable

This creates a `.disabled` marker file in the wallpaper folder.

Enable:

    bing-wallpaper enable

This removes the marker file and immediately requests a scheduler run.

On macOS, enable requests a LaunchAgent kickstart.

On Windows, enable starts the Scheduled Task.

If the scheduler entry is not available, the updater falls back to running directly.

## Local state

The updater stores state in the user's wallpaper folder.

On macOS:

    ~/Pictures/Bing Wallpaper

On Windows:

    %USERPROFILE%\Pictures\Bing Wallpaper

Important files:

    latest.json
      latest Bing metadata response

    .last-success-date
      date of the last confirmed successful wallpaper update

    .disabled
      marker file used to pause updates

## Cleanup behaviour

The project is designed to keep the current Bing wallpaper, not build a long-term archive.

After a successful update, old `bing-*.jpg` files are removed from the wallpaper folder.

## Image information note

The updater writes a human-readable note for the current Bing image beside the downloaded wallpaper.

The note uses this naming pattern:

    bing-YYYYMMDD-info.txt

For example:

    bing-20260622-info.txt

Read it with:

    bing-wallpaper info

## Market selection

The updater supports changing the Bing market.

Show the current market:

    bing-wallpaper market

Change market:

    bing-wallpaper market en-US
    bing-wallpaper market en-GB

Reset to the default market:

    bing-wallpaper market reset

Changing market clears the last successful update marker and immediately requests a new updater run.
