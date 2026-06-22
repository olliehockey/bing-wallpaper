$ErrorActionPreference = "Stop"

$TaskName = "Bing Wallpaper"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\bing-wallpaper"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SourceScript = Join-Path $RepoDir "scripts\bing-wallpaper-windows.ps1"
$InstalledScript = Join-Path $InstallDir "bing-wallpaper-windows.ps1"
$InstalledCommand = Join-Path $InstallDir "bing-wallpaper.cmd"

if (-not (Test-Path -LiteralPath $SourceScript)) {
    throw "Could not find source script: $SourceScript"
}

Write-Host "==> Installing Bing Wallpaper for Windows"

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

Write-Host "==> Copying script to $InstalledScript"
Copy-Item -LiteralPath $SourceScript -Destination $InstalledScript -Force

$CmdContent = @'
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\Programs\bing-wallpaper\bing-wallpaper-windows.ps1" %*
'@

Set-Content -LiteralPath $InstalledCommand -Value $CmdContent -Encoding ASCII

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $UserPath) {
    $UserPath = ""
}

$PathParts = $UserPath -split ";" | Where-Object { $_ -ne "" }
$AlreadyOnPath = $false

foreach ($Part in $PathParts) {
    if ($Part.TrimEnd("\") -ieq $InstallDir.TrimEnd("\")) {
        $AlreadyOnPath = $true
    }
}

if (-not $AlreadyOnPath) {
    Write-Host "==> Adding $InstallDir to your user PATH"
    $NewPath = if ($UserPath.Trim()) { "$UserPath;$InstallDir" } else { $InstallDir }
    [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    $env:Path = "$env:Path;$InstallDir"
}
else {
    Write-Host "==> PATH already contains $InstallDir"
}

Write-Host "==> Creating scheduled task"

$PowerShellExe = (Get-Command powershell.exe).Source
$Action = New-ScheduledTaskAction -Execute $PowerShellExe -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$InstalledScript`""

$LogonTrigger = New-ScheduledTaskTrigger -AtLogOn
$RepeatingTrigger = New-ScheduledTaskTrigger -Daily -At ([datetime]::Today)
$RepeatingTrigger.Repetition.Interval = "PT10M"
$RepeatingTrigger.Repetition.Duration = "P1D"

$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger @($LogonTrigger, $RepeatingTrigger) `
    -Settings $Settings `
    -Description "Downloads Bing's daily wallpaper and keeps it as the Windows desktop wallpaper while enabled." `
    -Force | Out-Null

Write-Host "==> Running once now so you see a result immediately"
& $InstalledScript

Write-Host ""
Write-Host "==> Done."
Write-Host "    Script installed at: $InstalledScript"
Write-Host "    Command installed at: $InstalledCommand"
Write-Host "    Scheduled task: $TaskName"
Write-Host ""
Write-Host "    You may need to open a new terminal before the bing-wallpaper command is available."
Write-Host ""
Write-Host "    Commands:"
Write-Host "      bing-wallpaper status"
Write-Host "      bing-wallpaper disable"
Write-Host "      bing-wallpaper enable"
Write-Host ""
Write-Host "    To uninstall, run:"
Write-Host "      cd windows"
Write-Host "      .\uninstall.ps1"
