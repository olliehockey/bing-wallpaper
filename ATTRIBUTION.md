# Attribution

This project was created as a small macOS adaptation of the general idea behind the GNOME “Bing Wallpaper” extension: automatically using Bing’s daily image as the desktop wallpaper.

The original GNOME extension that inspired this project is:

- Bing Wallpaper / Bing Wallpaper Changer for GNOME
- Repository: https://github.com/neffo/bing-wallpaper-gnome-extension

This macOS project is not a direct port of that GNOME extension. It does not reuse the GNOME Shell extension codebase. Instead, it implements the same broad user-facing idea using macOS-specific tools:

- `launchd` for background scheduling
- a zsh script for downloading and state tracking
- Bing's public wallpaper metadata endpoint
- `desktoppr` and AppleScript/System Events for setting the wallpaper

This project is unofficial and is not affiliated with Microsoft, Bing, GNOME, or the maintainers of the GNOME extension.

Bing wallpaper images remain the property of their respective copyright holders and should only be used as wallpapers.
