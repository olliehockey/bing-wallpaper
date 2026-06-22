param(
    [Parameter(Position = 0)]
    [string]$Command = "run",

    [Parameter(Position = 1)]
    [string]$Argument = ""
)

$ErrorActionPreference = "Stop"

$DefaultMarket = if ($env:BING_MARKET) { $env:BING_MARKET } else { "en-GB" }
$WallpaperDir = Join-Path $env:USERPROFILE "Pictures\Bing Wallpaper"
$JsonFile = Join-Path $WallpaperDir "latest.json"
$SuccessFile = Join-Path $WallpaperDir ".last-success-date"
$DisabledFile = Join-Path $WallpaperDir ".disabled"
$MarketFile = Join-Path $WallpaperDir ".market"
$TaskName = "Bing Wallpaper"

New-Item -ItemType Directory -Path $WallpaperDir -Force | Out-Null

if (Test-Path -LiteralPath $MarketFile) {
    $Market = (Get-Content -LiteralPath $MarketFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($Market)) {
        $Market = $DefaultMarket
    }
}
else {
    $Market = $DefaultMarket
}

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


function Write-InfoFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonPath,

        [Parameter(Mandatory = $true)]
        [string]$EndDate,

        [string]$ImagePath
    )

    if (-not (Test-Path -LiteralPath $JsonPath)) {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($EndDate)) {
        return $null
    }

    try {
        $data = Get-Content -LiteralPath $JsonPath -Raw | ConvertFrom-Json
        $image = $data.images[0]

        $title = if ($image.title) { $image.title } else { "Unavailable" }
        $copyright = if ($image.copyright) { $image.copyright } else { "Unavailable" }
        $copyrightLink = if ($image.copyrightlink) { $image.copyrightlink } else { "Unavailable" }

        $InfoFile = Join-Path $WallpaperDir "bing-$EndDate-info.txt"

        $content = @"
Bing wallpaper of the day

Date: $EndDate
Market: $Market
Image file: $ImagePath

Title:
$title

Copyright:
$copyright

Source:
$copyrightLink
"@

        Set-Content -LiteralPath $InfoFile -Value $content -Encoding UTF8
        return $InfoFile
    }
    catch {
        return $null
    }
}

function Get-CurrentInfoFile {
    if (Test-Path -LiteralPath $JsonFile) {
        try {
            $data = Get-Content -LiteralPath $JsonFile -Raw | ConvertFrom-Json
            $endDate = $data.images[0].enddate

            if ($endDate) {
                $candidate = Join-Path $WallpaperDir "bing-$endDate-info.txt"
                if (Test-Path -LiteralPath $candidate) {
                    return $candidate
                }
            }
        }
        catch {
        }
    }

    $latest = Get-ChildItem -LiteralPath $WallpaperDir -Filter "bing-*-info.txt" -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object -Last 1

    if ($latest) {
        return $latest.FullName
    }

    return ""
}

function Show-Usage {
    Write-Host "Usage:"
    Write-Host "  bing-wallpaper [command]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  bing-wallpaper"
    Write-Host "      Run the updater normally."
    Write-Host ""
    Write-Host "  bing-wallpaper status"
    Write-Host "      Show whether updates are enabled, the current market, the latest recorded"
    Write-Host "      Bing image date, the current wallpaper path, and the info file path."
    Write-Host ""
    Write-Host "  bing-wallpaper info"
    Write-Host "      Print the current Bing image information note."
    Write-Host ""
    Write-Host "  bing-wallpaper market"
    Write-Host "      Show the current Bing market."
    Write-Host ""
    Write-Host "  bing-wallpaper market MARKET"
    Write-Host "      Change the Bing market, clear the success marker, and request an"
    Write-Host "      immediate updater run."
    Write-Host ""
    Write-Host "  bing-wallpaper market reset"
    Write-Host "      Reset to the default market."
    Write-Host ""
    Write-Host "  bing-wallpaper disable"
    Write-Host "      Pause automatic wallpaper updates without uninstalling."
    Write-Host ""
    Write-Host "  bing-wallpaper enable"
    Write-Host "      Re-enable updates and request an immediate updater run."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  bing-wallpaper status"
    Write-Host "  bing-wallpaper info"
    Write-Host "  bing-wallpaper market en-GB"
    Write-Host "  bing-wallpaper market en-US"
    Write-Host "  bing-wallpaper market fr-FR"
    Write-Host "  bing-wallpaper market de-DE"
    Write-Host "  bing-wallpaper disable"
    Write-Host "  bing-wallpaper enable"
    Write-Host ""
    Write-Host "More help:"
    Write-Host "  bing-wallpaper market --help"
    Write-Host "  bing-wallpaper info --help"
}


function Show-MarketUsage {
    Write-Host "Usage:"
    Write-Host "  bing-wallpaper market"
    Write-Host "  bing-wallpaper market MARKET"
    Write-Host "  bing-wallpaper market reset"
    Write-Host ""
    Write-Host "Show or change the Bing market."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  bing-wallpaper market"
    Write-Host "  bing-wallpaper market en-GB"
    Write-Host "  bing-wallpaper market en-US"
    Write-Host "  bing-wallpaper market fr-FR"
    Write-Host "  bing-wallpaper market de-DE"
    Write-Host "  bing-wallpaper market reset"
    Write-Host ""
    Write-Host "Market format:"
    Write-Host "  language-REGION"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  en-GB   United Kingdom English"
    Write-Host "  en-US   United States English"
    Write-Host "  fr-FR   France French"
    Write-Host "  de-DE   Germany German"
    Write-Host "  ja-JP   Japan Japanese"
    Write-Host ""
    Write-Host "Changing market clears the last successful update marker and requests an"
    Write-Host "immediate updater run."
}

function Show-InfoUsage {
    Write-Host "Usage:"
    Write-Host "  bing-wallpaper info"
    Write-Host ""
    Write-Host "Print the current Bing image information note."
    Write-Host ""
    Write-Host "The note is stored beside the downloaded wallpaper using this pattern:"
    Write-Host ""
    Write-Host "  bing-YYYYMMDD-info.txt"
    Write-Host ""
    Write-Host "Example:"
    Write-Host ""
    Write-Host "  %USERPROFILE%\Pictures\Bing Wallpaper\bing-20260623-info.txt"
    Write-Host ""
    Write-Host "The note contains the date, market, image file path, title, copyright/credit,"
    Write-Host "and source link from Bing metadata."
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

    "market" {
        if (@("-h", "-help", "--help", "help") -contains $Argument) {
            Show-MarketUsage
            exit 0
        }

        if ([string]::IsNullOrWhiteSpace($Argument)) {
            Write-Host "Current market: $Market"
            Write-Host ""
            Write-Host "Change market with:"
            Write-Host "  bing-wallpaper market en-US"
            Write-Host "  bing-wallpaper market en-GB"
            Write-Host ""
            Write-Host "Reset to default with:"
            Write-Host "  bing-wallpaper market reset"
            exit 0
        }

        if ($Argument -eq "reset") {
            Remove-Item -LiteralPath $MarketFile -Force -ErrorAction SilentlyContinue
            $Market = $DefaultMarket
            Write-Host "Market reset to default: $Market"
        }
        elseif ($Argument -notmatch '^[a-z]{2}-[A-Z]{2}$') {
            Write-Host "Invalid market: $Argument"
            Write-Host "Expected format like en-GB, en-US, fr-FR, de-DE."
            exit 2
        }
        else {
            $Argument | Set-Content -LiteralPath $MarketFile -Encoding UTF8
            $Market = $Argument
            Write-Host "Market set to: $Market"
        }

        Remove-Item -LiteralPath $SuccessFile -Force -ErrorAction SilentlyContinue
        Write-Host "Cleared last successful update marker so the new market can update immediately."
        Write-Host "Triggering an updater run now."

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

    "info" {
        if (@("-h", "-help", "--help", "help") -contains $Argument) {
            Show-InfoUsage
            exit 0
        }

        $InfoFile = Get-CurrentInfoFile

        if (-not $InfoFile -and (Test-Path -LiteralPath $JsonFile)) {
            try {
                $data = Get-Content -LiteralPath $JsonFile -Raw | ConvertFrom-Json
                $infoEndDate = $data.images[0].enddate
                $infoImage = ""

                $uhdCandidate = Join-Path $WallpaperDir "bing-$infoEndDate-UHD.jpg"
                $standardCandidate = Join-Path $WallpaperDir "bing-$infoEndDate.jpg"

                if (Test-Path -LiteralPath $uhdCandidate) {
                    $infoImage = [System.IO.Path]::GetFullPath($uhdCandidate)
                }
                elseif (Test-Path -LiteralPath $standardCandidate) {
                    $infoImage = [System.IO.Path]::GetFullPath($standardCandidate)
                }

                $InfoFile = Write-InfoFile -JsonPath $JsonFile -EndDate $infoEndDate -ImagePath $infoImage
            }
            catch {
            }
        }

        if ($InfoFile -and (Test-Path -LiteralPath $InfoFile)) {
            Get-Content -LiteralPath $InfoFile
            exit 0
        }

        Write-Host "No Bing wallpaper info file found yet."
        exit 1
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

        Write-Host "Current market: $Market"

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

        $InfoFile = Get-CurrentInfoFile
        if ($InfoFile) {
            Write-Host "Info file: $InfoFile"
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
        Write-InfoFile -JsonPath $JsonFile -EndDate $expectedEndDate -ImagePath $ExpectedImage | Out-Null
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
    Write-InfoFile -JsonPath $JsonFile -EndDate $expectedEndDate -ImagePath $ExpectedImage | Out-Null
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
    $InfoFile = Write-InfoFile -JsonPath $JsonFile -EndDate $EndDate -ImagePath $ImageFile

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
