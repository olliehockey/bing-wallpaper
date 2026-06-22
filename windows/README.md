# Windows

Windows support lives in this folder.

The Windows version uses:

- PowerShell for the updater
- Windows Task Scheduler for automatic runs
- the current user's Pictures folder for downloaded wallpapers
- a small `bing-wallpaper.cmd` launcher for the short command

## Install

Open PowerShell from the repository root, then run:

    cd windows
    .\install.ps1

The installer copies the updater to:

    %LOCALAPPDATA%\Programs\bing-wallpaper

It also creates a scheduled task named:

    Bing Wallpaper

The task runs at logon and then repeatedly throughout the day.

## Commands

After installing, open a new terminal if needed, then run:

    bing-wallpaper status
    bing-wallpaper disable
    bing-wallpaper enable
    bing-wallpaper

## Behaviour

When enabled, the Windows version behaves like the macOS version.

It keeps trying until today's Bing wallpaper has been downloaded and set successfully.

After success, later scheduled runs check whether the expected image still exists and whether it is still the current desktop wallpaper.

If the image file has been deleted, it downloads it again.

If the image exists but the desktop wallpaper has been changed, it restores the Bing wallpaper without re-downloading it.

If updates are disabled using `bing-wallpaper disable`, the script exits immediately and leaves the current wallpaper unchanged.

## Uninstall

From the repository root, run:

    cd windows
    .\uninstall.ps1

The uninstaller removes the scheduled task and installed command files.

Downloaded wallpaper images are left in your Pictures folder.
