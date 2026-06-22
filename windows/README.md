# Windows

Windows support lives in this folder.

The Windows version uses:

- PowerShell for the updater
- Windows Task Scheduler for automatic runs
- the user's Pictures folder for downloaded wallpapers
- a small `bing-wallpaper.cmd` launcher for the short command

## Install

Open PowerShell from the repository root, then run:

    cd windows
    .\install.ps1

The installer copies the updater to:

    %LOCALAPPDATA%\Programs\bing-wallpaper

It also creates a scheduled task named:

    Bing Wallpaper

## Commands

After installing, open a new terminal if needed, then run:

    bing-wallpaper status
    bing-wallpaper market
    bing-wallpaper info
    bing-wallpaper disable
    bing-wallpaper enable
    bing-wallpaper

## Behaviour

When enabled, the Windows version keeps Bing as the managed wallpaper.

If today's image has not been set successfully, it keeps trying.

If the wallpaper image is deleted, it downloads it again.

If the desktop wallpaper is changed, it restores the Bing wallpaper.

If updates are disabled, scheduled runs exit immediately and leave the wallpaper unchanged.

## Uninstall

From the repository root:

    cd windows
    .\uninstall.ps1

The uninstaller removes the scheduled task and installed command files.

Downloaded wallpaper images are left in the user's Pictures folder.

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

## Help

Show general help:

    bing-wallpaper --help

Show market help:

    bing-wallpaper market --help

Show image info help:

    bing-wallpaper info --help
