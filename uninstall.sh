#!/bin/zsh
#
# uninstall.sh — removes bing-wallpaper-macos for the current user.
#
# Always removes: the LaunchAgent and the installed script.
# Asks before removing: the downloaded wallpaper images/logs, since
# those are user content you may want to keep.
#
set -euo pipefail

INSTALL_PATH="$HOME/.local/bin/bing-wallpaper-macos"
PLIST_LABEL="com.bing-wallpaper-macos.agent"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
WALLPAPER_DIR="$HOME/Pictures/Bing Wallpaper"

echo "==> Unloading LaunchAgent"
launchctl bootout "gui/$(id -u)/$PLIST_LABEL" >/dev/null 2>&1 || true

if [[ -f "$PLIST_PATH" ]]; then
	echo "==> Removing $PLIST_PATH"
	rm -f "$PLIST_PATH"
fi

if [[ -f "$INSTALL_PATH" ]]; then
	echo "==> Removing $INSTALL_PATH"
	rm -f "$INSTALL_PATH"
fi

rm -f /tmp/bing-wallpaper.out.log /tmp/bing-wallpaper.err.log

if [[ -d "$WALLPAPER_DIR" ]]; then
	echo
	read "REPLY?Also delete downloaded wallpapers in '$WALLPAPER_DIR'? [y/N] "
	if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
		rm -rf "$WALLPAPER_DIR"
		echo "==> Removed $WALLPAPER_DIR"
	else
		echo "==> Left $WALLPAPER_DIR in place"
	fi
fi

echo
echo "==> Uninstalled."

# Remove short convenience command.
rm -f "$HOME/.local/bin/bing-wallpaper"
