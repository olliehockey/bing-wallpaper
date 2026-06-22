param(
    [Parameter(Position = 0)]
    [string]$Command = "run"
)

$ErrorActionPreference = "Stop"

$Market = if ($env:BING_MARKET) { $env:BING_MARKET } else { "en-GB" }
$WallpaperDir = Join-Path $env:USERPROFILE "Pictures\Bing Wallpaper"
$JsonFile = Join-Path $WallpaperDir "latest.json"
$SuccessFile = Join-Path $WallpaperDir ".last-success-date"
$DisabledFile = Join-Path $WallpaperDir ".disabled"
$TaskName = "Bing Wallpaper"

New-Item -ItemType Directory -Path $WallpaperDir -Force | Out-Null

function Get-CurrentWallpaper {
    try {
        $item = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallPaper -ErrorAction Stop
        return [string]$item.WallPaper
    }
    catch {
        return ""
    }
}

function Enable-NativeWallpaperApi {
    if (-not ("BingWallpaperNativeMethods" -as [type])) {
        Add-Type @"
using System;
using System.Runtime.InteropServices;

public class BingWallpaperNativeMethods
{
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
    }
}

function Test-SamePath {
    param(
        [string]$A,
        [string]$B
    )

    if ([string]::IsNullOrWhiteSpace($A) -or [string]::IsNullOrWhiteSpace($B)) {
        return $false
    }

    return [string]::Equals($A.Trim(), $B.Trim(), [System.StringComparison]::OrdinalIgnoreCase)
}

function Set-BingWallpaper {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    $FullPath = [System.IO.Path]::GetFullPath($ImagePath)

    if (-not (Test-Path -LiteralPath $FullPath)) {
        throw "Wallpaper image does not exist: $FullPath"
    }

    Enable-NativeWallpaperApi

    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallPaper -Value $FullPath
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "10"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0"

    $SPI_SETDESKWALLPAPER = 20
    $SPIF_UPDATEINIFILE = 1
    $SPIF_SENDCHANGE = 2

    $ok = [BingWallpaperNativeMethods]::SystemParametersInfo(
        $SPI_SETDESKWALLPAPER,
        0,
        $FullPath,
        $SPIF_UPDATEINIFILE -bor $SPIF_SENDCHANGE
    )

    Start-Sleep -Seconds 1

    $Current = Get-CurrentWallpaper

    if ($ok -and (Test-SamePath $Current $FullPath)) {
        return $true
    }

    Write-Host "Wallpaper setter did not verify."
    Write-Host "Expected: $FullPath"
    Write-Host "Current:  $Current"
    return $false
}

function Test-ValidImage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
        $img = [System.Drawing.Image]::FromFile($Path)
        $width = $img.Width
        $height = $img.Height
        $img.Dispose()

        return ($width -gt 0 -and $height -gt 0)
    }
    catch {
        return $false
    }
}

function Show-Usage {
    Write-Host "Usage:"
    Write-Host "  bing-wallpaper          Run the updater normally"
    Write-Host "  bing-wallpaper enable   Enable automatic wallpaper updates"
    Write-Host "  bing-wallpaper disable  Disable automatic wallpaper updates"
    Write-Host "  bing-wallpaper status   Show whether updates are enabled or disabled"
}

$Command = $Command.ToLowerInvariant()

switch ($Command) {
    "enable" {
        Remove-Item -LiteralPath $DisabledFile -Force -ErrorAction SilentlyContinue
        Write-Host "Bing wallpaper updates enabled."
        Write-Host "Triggering a Scheduled Task run now."

        $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

        if ($Task) {
            Start-ScheduledTask -TaskName $TaskName
            Write-Host "Scheduled Task triggered."
            exit 0
        }

        Write-Host "Scheduled Task is not currently registered. Running updater directly instead."

        $ScriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
        & $ScriptPath
        exit $LASTEXITCODE
    }

    "disable" {
        (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ") | Set-Content -LiteralPath $DisabledFile -Encoding UTF8
        Write-Host "Bing wallpaper updates disabled."
        Write-Host "Current wallpaper has not been changed."
        Write-Host "Run this to re-enable:"
        Write-Host "  bing-wallpaper enable"
        exit 0
    }

    "status" {
        if (Test-Path -LiteralPath $DisabledFile) {
            Write-Host "Status: disabled"
            Write-Host "Disabled marker: $DisabledFile"
            Write-Host "Disabled since: $((Get-Content -LiteralPath $DisabledFile -Raw).Trim())"
            Write-Host ""
            Write-Host "Run this to re-enable:"
            Write-Host "  bing-wallpaper enable"
        }
        else {
            Write-Host "Status: enabled"
            Write-Host "Updates are allowed."
        }

        if (Test-Path -LiteralPath $SuccessFile) {
            Write-Host "Last successful update: $((Get-Content -LiteralPath $SuccessFile -Raw).Trim())"
        }
        else {
            Write-Host "Last successful update: none recorded"
        }

        if (Test-Path -LiteralPath $JsonFile) {
            try {
                $existingJson = Get-Content -LiteralPath $JsonFile -Raw | ConvertFrom-Json
                $endDate = $existingJson.images[0].enddate
                if ($endDate) {
                    Write-Host "Latest recorded Bing image date: $endDate"
                }
            }
            catch {
            }
        }

        $current = Get-CurrentWallpaper
        if ($current) {
            Write-Host "Current wallpaper: $current"
        }

        exit 0
    }

    "run" {
    }

    "" {
    }

    "-h" {
        Show-Usage
        exit 0
    }

    "--help" {
        Show-Usage
        exit 0
    }

    "-help" {
        Show-Usage
        exit 0
    }

    "help" {
        Show-Usage
        exit 0
    }

    default {
        Write-Host "Unknown command: $Command"
        Write-Host ""
        Show-Usage
        exit 2
    }
}

if (Test-Path -LiteralPath $DisabledFile) {
    Write-Host "Bing wallpaper updates are disabled. Leaving wallpaper unchanged."
    Write-Host "Run this to re-enable:"
    Write-Host "  bing-wallpaper enable"
    exit 0
}

$Today = Get-Date -Format "yyyy-MM-dd"
$LastSuccess = ""

if (Test-Path -LiteralPath $SuccessFile) {
    $LastSuccess = (Get-Content -LiteralPath $SuccessFile -Raw).Trim()
}

$ExpectedImage = ""

if (Test-Path -LiteralPath $JsonFile) {
    try {
        $existingJson = Get-Content -LiteralPath $JsonFile -Raw | ConvertFrom-Json
        $expectedEndDate = $existingJson.images[0].enddate

        if ($expectedEndDate) {
            $uhdCandidate = Join-Path $WallpaperDir "bing-$expectedEndDate-UHD.jpg"
            $standardCandidate = Join-Path $WallpaperDir "bing-$expectedEndDate.jpg"

            if (Test-Path -LiteralPath $uhdCandidate) {
                $ExpectedImage = [System.IO.Path]::GetFullPath($uhdCandidate)
            }
            elseif (Test-Path -LiteralPath $standardCandidate) {
                $ExpectedImage = [System.IO.Path]::GetFullPath($standardCandidate)
            }
        }
    }
    catch {
    }
}

if (($LastSuccess -eq $Today) -and $ExpectedImage) {
    $CurrentWallpaper = Get-CurrentWallpaper

    if (Test-SamePath $CurrentWallpaper $ExpectedImage) {
        Write-Host "Wallpaper already successfully updated today ($Today). Local image exists and is currently set: $ExpectedImage. Leaving as-is."
        exit 0
    }

    Write-Host "Today's Bing wallpaper exists, but the desktop is not using it. Restoring wallpaper."
    Write-Host "Expected: $ExpectedImage"
    Write-Host "Current:  $CurrentWallpaper"

    if (-not (Set-BingWallpaper -ImagePath $ExpectedImage)) {
        Write-Host "Could not restore Bing wallpaper. Not marking this run as successful."
        exit 1
    }

    $Today | Set-Content -LiteralPath $SuccessFile -Encoding UTF8
    Write-Host "Restored wallpaper to $ExpectedImage"
    exit 0
}

if ($LastSuccess -eq $Today) {
    Write-Host "Today was marked successful, but the local Bing wallpaper file is missing. Re-downloading."
}

$TmpJson = Join-Path $WallpaperDir ".latest.$PID.json"
$TmpImage = Join-Path $WallpaperDir ".bing.$PID.jpg"

try {
    $ApiUrl = "https://www.bing.com/HPImageArchive.aspx?format=js&uhd=1&idx=0&n=1&mkt=$Market"

    $JsonResponse = Invoke-WebRequest -Uri $ApiUrl -UseBasicParsing -TimeoutSec 60
    $JsonText = $JsonResponse.Content
    $BingData = $JsonText | ConvertFrom-Json

    $Image = $BingData.images[0]
    $UrlBase = $Image.urlbase
    $EndDate = $Image.enddate

    $UhdUrl = "https://www.bing.com${UrlBase}_UHD.jpg"
    $ImageFile = Join-Path $WallpaperDir "bing-$EndDate-UHD.jpg"

    try {
        Invoke-WebRequest -Uri $UhdUrl -UseBasicParsing -TimeoutSec 120 -OutFile $TmpImage
    }
    catch {
        Remove-Item -LiteralPath $TmpImage -Force -ErrorAction SilentlyContinue

        $StandardUrl = "https://www.bing.com$($Image.url)"
        $ImageFile = Join-Path $WallpaperDir "bing-$EndDate.jpg"

        Invoke-WebRequest -Uri $StandardUrl -UseBasicParsing -TimeoutSec 120 -OutFile $TmpImage
    }

    if (-not (Test-ValidImage -Path $TmpImage)) {
        Write-Host "Downloaded file was not a valid image. Leaving wallpaper unchanged."
        exit 1
    }

    $JsonText | Set-Content -LiteralPath $TmpJson -Encoding UTF8

    Move-Item -LiteralPath $TmpJson -Destination $JsonFile -Force
    Move-Item -LiteralPath $TmpImage -Destination $ImageFile -Force

    $ImageFile = [System.IO.Path]::GetFullPath($ImageFile)

    if (-not (Set-BingWallpaper -ImagePath $ImageFile)) {
        Write-Host "Wallpaper was downloaded, but Windows did not confirm it was set."
        Write-Host "Not marking today as successful so Task Scheduler can retry later."
        exit 1
    }

    $Today | Set-Content -LiteralPath $SuccessFile -Encoding UTF8

    Get-ChildItem -LiteralPath $WallpaperDir -Filter "bing-*.jpg" -ErrorAction SilentlyContinue |
        Where-Object { -not (Test-SamePath $_.FullName $ImageFile) } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    Write-Host "Set wallpaper to $ImageFile"
    Write-Host "Marked $Today as successfully updated."
    Write-Host "Old Bing wallpapers cleaned up."
}
finally {
    Remove-Item -LiteralPath $TmpJson -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $TmpImage -Force -ErrorAction SilentlyContinue
}
