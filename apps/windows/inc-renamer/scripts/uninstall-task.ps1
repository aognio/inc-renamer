$taskName = "dev.ognio.inc-renamer"
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Write-Output "Uninstalled task $taskName"
