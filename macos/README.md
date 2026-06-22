# macOS

macOS support lives in this folder.

## Install

From the repository root:

    cd macos
    ./install.sh

The installer creates the user-facing command:

    ~/.local/bin/bing-wallpaper

Automatic runs are handled by launchd.

## Commands

After installing:

    bing-wallpaper status
    bing-wallpaper market
    bing-wallpaper info
    bing-wallpaper disable
    bing-wallpaper enable
    bing-wallpaper

## Behaviour

When enabled, the macOS version keeps Bing as the managed wallpaper.

If today's image has not been set successfully, it keeps trying.

If the wallpaper image is deleted, it downloads it again.

If the desktop wallpaper is changed, it restores the Bing wallpaper.

If updates are disabled, scheduled runs exit immediately and leave the wallpaper unchanged.

## Uninstall

From the repository root:

    cd macos
    ./uninstall.sh

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
