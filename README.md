# bing-wallpaper-macOS

This project is unofficial and is not affiliated with Microsoft or Bing. Bing images and trademarks belong to their respective owners.

Automatically download Bing's daily "image of the day" and set it as your macOS desktop wallpaper — once a day, with safe retries if you're offline, and no third-party app or menu bar icon required.

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-black" alt="macOS">
  <img src="https://img.shields.io/badge/shell-zsh-89e051" alt="zsh">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
</p>

## What it does

- Fetches the current Bing homepage image (UHD if available, falling back automatically if not) for your chosen market.
- Sets it as your desktop wallpaper on every display.
- Runs automatically via a `launchd` LaunchAgent: at login, at midnight, and every 10 minutes after that.
- The 10-minute checks are cheap — once the wallpaper has been successfully updated for the day, every subsequent check that day exits immediately without touching the network. The frequent schedule exists purely so that if your Mac is offline or asleep at midnight, it catches up automatically as soon as you're back online, rather than waiting until the next day.
- Cleans up old downloaded wallpapers automatically, but only after a new one has been successfully applied — never deletes a working wallpaper to make room for one that hasn't finished downloading.

## Requirements

- macOS (uses `osascript`, `sips`, `plutil`, and `launchd`, all built in — no dependencies to install)
- `zsh` (the default shell on modern macOS)
- An internet connection (for downloading images — the script no-ops safely without one)

## Install

```bash
git clone https://github.com/YOUR_USERNAME/bing-wallpaper-macOS.git
cd bing-wallpaper-macOS
chmod +x install.sh uninstall.sh scripts/bing-wallpaper-macos
./install.sh
```

> If you downloaded this as a ZIP instead of using `git clone`, the executable
> permission bit may not survive the download — the `chmod` line above fixes
> that. A normal `git clone` from GitHub preserves it and the `chmod` is a
> harmless no-op.

This will:

1. Copy the script to `~/.local/bin/bing-wallpaper-macos`
2. Install a LaunchAgent at `~/Library/LaunchAgents/com.bing-wallpaper-macos.agent.plist`
3. Load it immediately with `launchctl`
4. Run it once right away, so you see a new wallpaper without waiting for midnight

### Choosing a market/region

By default, images are fetched for the `en-GB` market. To use a different one, set `BING_MARKET` before installing:

```bash
BING_MARKET=en-US ./install.sh
```

Any [Bing market code](https://learn.microsoft.com/en-us/bing/search-apis/bing-web-search/reference/market-codes) should work (e.g. `en-US`, `ja-JP`, `fr-FR`, `de-DE`).

To change the market later without reinstalling, edit the `BING_MARKET` value inside `~/Library/LaunchAgents/com.bing-wallpaper-macos.agent.plist`, then reload it:

```bash
launchctl bootout gui/$(id -u)/com.bing-wallpaper-macos.agent
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.bing-wallpaper-macos.agent.plist
```

## Uninstall

```bash
./uninstall.sh
```

This removes the LaunchAgent and the installed script. It will ask before deleting your downloaded wallpaper images, in case you want to keep them.

## Where things live

| What | Where |
|---|---|
| Script | `~/.local/bin/bing-wallpaper-macos` |
| LaunchAgent | `~/Library/LaunchAgents/com.bing-wallpaper-macos.agent.plist` |
| Downloaded images & metadata | `~/Pictures/Bing Wallpaper/` |
| stdout log | `/tmp/bing-wallpaper.out.log` |
| stderr log | `/tmp/bing-wallpaper.err.log` |
| Last successful run date | `~/Pictures/Bing Wallpaper/.last-success-date` |

## How it works

On every invocation, the script:

1. Checks `.last-success-date` and verifies the current wallpaper file still exists. If today is already marked successful and the wallpaper file exists, it exits immediately. If the wallpaper file has been deleted, it re-downloads and restores it.
2. Downloads Bing's metadata JSON for the configured market.
3. Downloads the UHD image (falling back to the standard-resolution image if UHD isn't available for that day's picture).
4. Verifies the downloaded file is actually a valid image (via `sips`) before doing anything else with it — a failed or corrupt download never touches your existing wallpaper.
5. Sets the new image as the desktop wallpaper on every display, via `osascript`/System Events.
6. Only after the wallpaper has been successfully set does it write today's date to `.last-success-date` and clean up the previous day's image.

All intermediate downloads happen to temporary files first and are only moved into place once fully verified, and a `trap` ensures temp files are cleaned up even if the script fails partway through (e.g. due to no internet connection). If a run fails for any reason, your existing wallpaper is left untouched, and the LaunchAgent will simply try again at the next scheduled interval.

## Troubleshooting

**Check the logs:**
```bash
cat /tmp/bing-wallpaper.out.log
cat /tmp/bing-wallpaper.err.log
```

**Run it manually to see what happens:**
```bash
~/.local/bin/bing-wallpaper-macos
```

**Check whether the LaunchAgent is loaded:**
```bash
launchctl print gui/$(id -u)/com.bing-wallpaper-macos.agent
```

**Wallpaper isn't changing even though logs show success:** macOS sometimes requires Accessibility/Automation permission for `osascript` to control System Events on behalf of a background process. If you see a permissions prompt the first time it runs, approve it. You can check under **System Settings → Privacy & Security → Automation**.

**Force a re-run today even though it already succeeded:**
```bash
rm "$HOME/Pictures/Bing Wallpaper/.last-success-date"
~/.local/bin/bing-wallpaper-macos
```

## License

MIT — see [LICENSE](LICENSE).

## Short command

The installer creates two command names:

    bing-wallpaper-macos
    bing-wallpaper

They both run the same updater. The shorter command is provided for day-to-day use.

Examples:

    bing-wallpaper status
    bing-wallpaper disable
    bing-wallpaper enable

The short command is a symlink to the installed `bing-wallpaper-macos` script.


## Managed wallpaper behaviour

When updates are enabled, the project treats the Bing wallpaper as the managed desktop wallpaper.

The LaunchAgent runs periodically. On each run:

- if today's wallpaper has not been downloaded and set successfully, it tries again
- if today's wallpaper file was deleted, it downloads it again
- if today's wallpaper exists but the desktop is using a different wallpaper, it restores the Bing wallpaper
- if updates are disabled, it leaves the current wallpaper unchanged

This means `bing-wallpaper disable` is the correct way to temporarily use another wallpaper without the updater changing it back.


## Enable or disable updates

The LaunchAgent can stay installed while wallpaper updates are temporarily disabled.

Disable automatic updates:

    bing-wallpaper-macos disable

Enable automatic updates again:

    bing-wallpaper-macos enable

Check status:

    bing-wallpaper-macos status

Disabling updates does not delete the current wallpaper or change the desktop. It creates a small `.disabled` marker file in `~/Pictures/Bing Wallpaper/`. While that marker exists, scheduled launchd runs exit without downloading or setting a wallpaper.


## Attribution

This project is a macOS adaptation of the general idea behind the GNOME “Bing Wallpaper” extension: automatically using Bing’s daily image as the desktop wallpaper.

The original GNOME extension that inspired this project is [neffo/bing-wallpaper-gnome-extension](https://github.com/neffo/bing-wallpaper-gnome-extension).

This repository is not a direct port and does not reuse the GNOME Shell extension codebase. It implements the idea separately for macOS using `launchd`, zsh, Bing's wallpaper metadata endpoint, and macOS wallpaper-setting tools.

See [ATTRIBUTION.md](ATTRIBUTION.md) for more detail.

## AI assistance

This project was developed with assistance from ChatGPT. AI assistance was used to help design the macOS workflow, write and debug the shell script, improve retry behaviour, and draft documentation.

The final code was tested locally by the repository owner. See [AI_ASSISTANCE.md](AI_ASSISTANCE.md) for more detail.

## Code overview

The project is intentionally small. The main script downloads Bing's daily wallpaper, verifies it, sets it as the macOS desktop wallpaper, records successful updates, and cleans up old images.

For a plain-English explanation of how the code works, see [CODE_OVERVIEW.md](CODE_OVERVIEW.md).

## Disclaimer

This project is unofficial and is not affiliated with Microsoft, Bing, GNOME, or the maintainers of the GNOME Bing Wallpaper extension.

Bing wallpaper images remain the property of their respective copyright holders and should only be used as wallpapers.
