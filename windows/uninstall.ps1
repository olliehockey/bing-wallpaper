$ErrorActionPreference = "Stop"

$TaskName = "Bing Wallpaper"
$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\bing-wallpaper"

Write-Host "==> Uninstalling Bing Wallpaper for Windows"

$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($Task) {
    Write-Host "==> Removing scheduled task: $TaskName"
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}
else {
    Write-Host "==> Scheduled task not found: $TaskName"
}

if (Test-Path -LiteralPath $InstallDir) {
    Write-Host "==> Removing installed command files from $InstallDir"
    Remove-Item -LiteralPath $InstallDir -Recurse -Force
}
else {
    Write-Host "==> Install directory not found: $InstallDir"
}

$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath) {
    $PathParts = $UserPath -split ";" | Where-Object {
        $_ -and ($_.TrimEnd("\") -ine $InstallDir.TrimEnd("\"))
    }

    $NewPath = ($PathParts -join ";")

    if ($NewPath -ne $UserPath) {
        Write-Host "==> Removing $InstallDir from your user PATH"
        [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    }
}

Write-Host ""
Write-Host "==> Done."
Write-Host "    Wallpaper images were left in:"
Write-Host "    $env:USERPROFILE\Pictures\Bing Wallpaper"
