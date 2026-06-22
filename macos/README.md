# macOS

macOS support lives in this folder.

## Install

From the repository root:

    cd macos
    ./install.sh

The installer copies the updater to:

    ~/.local/bin/bing-wallpaper-macos

It also creates the short command:

    ~/.local/bin/bing-wallpaper

Automatic runs are handled by launchd.

## Commands

After installing:

    bing-wallpaper status
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
