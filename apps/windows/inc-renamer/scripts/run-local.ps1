param(
  [string]$WatchDir = "$env:USERPROFILE\\Downloads",
  [string]$LogPath = "$env:LOCALAPPDATA\\inc-renamer\\inc-renamer.log",
  [int]$IntervalSeconds = 2
)

$binaryPath = "$PSScriptRoot\\..\\build\\Release\\inc-renamer.exe"
if (-not (Test-Path $binaryPath)) {
  throw "Binary not found at $binaryPath. Build first with CMake."
}

$logDir = Split-Path -Path $LogPath -Parent
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

& $binaryPath $WatchDir $LogPath $IntervalSeconds
