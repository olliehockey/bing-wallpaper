#!/bin/zsh
#
# install.sh — installs bing-wallpaper-macos for the current user.
#
#   * Copies the script to ~/.local/bin/bing-wallpaper-macos
#   * Installs a LaunchAgent that runs it at login, at midnight, and
#     every 10 minutes thereafter (it no-ops once it has already
#     succeeded that day, so this is cheap)
#   * Runs it once immediately so you see a result right away
#
# Usage:
#   ./install.sh                  # uses default market (en-GB)
#   BING_MARKET=en-US ./install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/bing-wallpaper-macos"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_LABEL="com.bing-wallpaper-macos.agent"
PLIST_PATH="$LAUNCH_AGENTS_DIR/$PLIST_LABEL.plist"
MARKET="${BING_MARKET:-en-GB}"

echo "==> Installing bing-wallpaper for macOS"
echo "    Market: $MARKET (override with BING_MARKET=xx-XX ./install.sh)"

mkdir -p "$INSTALL_DIR"
mkdir -p "$LAUNCH_AGENTS_DIR"

echo "==> Copying script to $INSTALL_PATH"
cp "$SCRIPT_DIR/scripts/bing-wallpaper-macos" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "==> Writing LaunchAgent to $PLIST_PATH"
# Substitute the real install path and chosen market into the plist
# template. The market is passed via EnvironmentVariables so the
# script itself never needs to be edited per-install.
sed -e "s|__INSTALL_PATH__|$INSTALL_PATH|" \
    -e "s|__BING_MARKET__|$MARKET|" \
	"$SCRIPT_DIR/LaunchAgents/$PLIST_LABEL.plist.template" > "$PLIST_PATH"

/usr/bin/plutil -lint "$PLIST_PATH" >/dev/null
INTERVAL_FILE="$HOME/Pictures/Bing Wallpaper/.interval"
if [[ -f "$INTERVAL_FILE" ]]; then
  SAVED_INTERVAL="$(tr -d '[:space:]' < "$INTERVAL_FILE")"
  case "$SAVED_INTERVAL" in
    ''|*[!0-9]*)
      SAVED_INTERVAL="600"
      ;;
  esac
  if [[ "$SAVED_INTERVAL" -lt 60 ]]; then
    SAVED_INTERVAL="60"
  fi
  plutil -replace StartInterval -integer "$SAVED_INTERVAL" "$PLIST_PATH"
fi

echo "==> Loading LaunchAgent"
# Unload first in case this is a re-install.
launchctl bootout "gui/$(id -u)/$PLIST_LABEL" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_PATH"

echo "==> Running once now so you see a result immediately..."
"$INSTALL_PATH" || {
	echo
	echo "Note: the first run reported an error above (often just a"
	echo "missing network connection). The LaunchAgent will keep"
	echo "retrying automatically — see 'Troubleshooting' in the README."
}

echo
echo "==> Done."
echo "    Wallpaper images and logs:  $HOME/Pictures/Bing Wallpaper"
echo "    Internal script:        $INSTALL_PATH"
echo "    LaunchAgent:                $PLIST_PATH"
echo "    stdout log:                 /tmp/bing-wallpaper.out.log"
echo "    stderr log:                 /tmp/bing-wallpaper.err.log"
echo
echo "    To uninstall, run: ./uninstall.sh"

# Create short convenience command.
SHORT_COMMAND_PATH="$HOME/.local/bin/bing-wallpaper"
ln -sf "$INSTALL_PATH" "$SHORT_COMMAND_PATH"
echo "    Command:             $SHORT_COMMAND_PATH"
