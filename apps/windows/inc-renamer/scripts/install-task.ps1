param(
  [string]$WatchDir = "$env:USERPROFILE\\Downloads",
  [string]$BinaryPath = "$PSScriptRoot\\..\\build\\Release\\inc-renamer.exe",
  [string]$LogPath = "$env:LOCALAPPDATA\\inc-renamer\\inc-renamer.log",
  [int]$IntervalSeconds = 2,
  [switch]$AtStartup
)

$taskName = "dev.ognio.inc-renamer"
$logDir = Split-Path -Path $LogPath -Parent
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$arguments = "`"$WatchDir`" `"$LogPath`" $IntervalSeconds"
$action = New-ScheduledTaskAction -Execute $BinaryPath -Argument $arguments
if ($AtStartup) {
  $trigger = New-ScheduledTaskTrigger -AtStartup
} else {
  $trigger = New-ScheduledTaskTrigger -AtLogOn
}
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force
Start-ScheduledTask -TaskName $taskName
Write-Output "Installed and started task $taskName"
