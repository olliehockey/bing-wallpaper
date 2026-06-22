#!/bin/zsh
set -euo pipefail

OS_NAME="$(uname -s 2>/dev/null || echo unknown)"

echo "bing-wallpaper platform installer guide"
echo

case "$OS_NAME" in
  Darwin)
    echo "Detected platform: macOS"
    echo
    echo "To install the macOS version, run:"
    echo
    echo "  cd macos"
    echo "  ./install.sh"
    ;;

  MINGW*|MSYS*|CYGWIN*)
    echo "Detected platform: Windows shell"
    echo
    echo "To install the Windows version, run from PowerShell:"
    echo
    echo "  cd windows"
    echo "  .\\install.ps1"
    ;;

  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      echo "Detected platform: WSL/Linux on Windows"
      echo
      echo "Do not install from WSL. Use PowerShell on Windows instead:"
      echo
      echo "  cd windows"
      echo "  .\\install.ps1"
    else
      echo "Detected platform: Linux"
      echo
      echo "Linux is not currently supported by this repo."
    fi
    ;;

  *)
    echo "Could not confidently detect this platform."
    echo
    echo "Choose explicitly:"
    echo
    echo "  macOS:   cd macos && ./install.sh"
    echo "  Windows: cd windows; .\\install.ps1"
    ;;
esac

echo
echo "This root script is only a guide. It does not install anything."
