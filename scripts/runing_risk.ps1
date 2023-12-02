

try {
    $backupPath = "$($PSScriptRoot)\gpback)"
    New-Item -ItemType Directory -Force -Path ($backupPath | Split-Path -Parent) | Out-Null
    Copy-Item -Path "$($env:SystemRoot)\System32\GroupPolicy" -Destination $backupPath -Recurse -ErrorAction Stop
} catch {
    Write-Output "Failed"
    cmd /c pause
    exit
}

cmd /c RD /S /Q "%WinDir%\System32\GroupPolicyUsers"
cmd /c RD /S /Q "%WinDir%\System32\GroupPolicy"

gpupdate /force

pause
pause

Install-Module PSWindowsUpdate
Add-WUServiceManager -MicrosoftUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot | Out-File "C:\($env.computername-Get-Date -f yyyy-MM-dd)-MSUpdates.log" -Force
