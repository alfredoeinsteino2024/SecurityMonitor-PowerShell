# =============================================================================
# stop.ps1  —  C:\SecurityCam\stop.ps1
# Manually signals monitor.ps1 to stop the active recording.
# Run this any time you want to stop — no hotkey needed.
# Does NOT need to be run as Administrator.
# =============================================================================

$flagFile = "C:\SecurityCam\stop.flag"
$logFile  = "C:\SecurityCam\logs\monitor.log"

# Check if monitor.ps1 is even running before bothering
$monitorRunning = Get-Process powershell -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -match "monitor" -or $_.CommandLine -match "monitor" }

# Write the flag file — monitor.ps1 checks for this every poll cycle
New-Item -Path $flagFile -ItemType File -Force | Out-Null

$line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [STOP] Stop flag written manually via stop.ps1"
Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
Write-Host $line

# Wait up to 10 seconds for monitor.ps1 to pick up the flag and delete it
Write-Host "Waiting for monitor.ps1 to acknowledge..."
$waited = 0
while ((Test-Path $flagFile) -and $waited -lt 10) {
    Start-Sleep -Seconds 1
    $waited++
}

if (-not (Test-Path $flagFile)) {
    Write-Host "Recording stopped successfully. (monitor.ps1 acknowledged in ${waited}s)"
} else {
    Write-Host "WARNING: monitor.ps1 did not pick up the flag within 10 seconds."
    Write-Host "Is monitor.ps1 actually running? Check Task Manager or the log:"
    Write-Host "  Get-Content $logFile -Tail 20"
}
