# bing-wallpaper

Cross-platform Bing wallpaper updater for macOS and Windows.

The project downloads Bing's daily image of the day, saves it locally, and sets it as the desktop wallpaper.

When enabled, it behaves like a small wallpaper manager: it retries until today's image has been set successfully, restores the wallpaper if it is changed, and re-downloads the image if the local file is deleted.

## Supported platforms

- macOS
- Windows

The macOS version has been tested locally.

The Windows version has been syntax-checked with PowerShell, but still needs end-to-end testing on a real Windows machine.

## Platform installers

Installers are platform-specific.

The root installer scripts are only guides. They do not install anything directly.

For macOS:

    cd macos
    ./install.sh

For Windows:

    cd windows
    .\install.ps1

The macOS installer does not install Windows files, and the Windows installer does not install macOS files.

## macOS install

From the repository root:

    cd macos
    ./install.sh

The macOS installer creates:

    ~/.local/bin/bing-wallpaper

It also installs a LaunchAgent:

    ~/Library/LaunchAgents/com.bing-wallpaper-macos.agent.plist

## Windows install

From PowerShell:

    cd windows
    .\install.ps1

The Windows installer creates a user-level Scheduled Task called:

    Bing Wallpaper

It also installs a command called:

    bing-wallpaper

## Commands

After installation, both platforms support:

    bing-wallpaper
    bing-wallpaper status
    bing-wallpaper market
    bing-wallpaper disable
    bing-wallpaper enable

## Behaviour

When enabled:

- the updater runs automatically
- it downloads today's Bing wallpaper if needed
- it sets the wallpaper
- it records success only after the wallpaper has been set
- it restores the Bing wallpaper if the desktop wallpaper is changed
- it re-downloads the image if the local image file is deleted

When disabled:

- scheduled runs exit immediately
- the current wallpaper is left unchanged
- the LaunchAgent or Scheduled Task can remain installed

Re-enable with:

    bing-wallpaper enable

On re-enable, the updater immediately requests a scheduler run.

## Repository layout

    macos/      macOS implementation
    windows/    Windows implementation

## Attribution

This project is inspired by the general idea of daily Bing wallpaper tools, including the GNOME Bing Wallpaper extension.

It is not a port of that extension and does not reuse its codebase.

## Disclaimer

This project is unofficial and is not affiliated with Microsoft, Bing, GNOME, Apple, or Microsoft Windows.

Bing images are subject to their own copyright and usage terms. They should be used as wallpapers only.

## License

MIT — see `LICENSE`.

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
