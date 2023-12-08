# windows-bigboi
Get-ChildItem -Path "C:\Users" -Exclude "$env:UserName" | Get-ChildItem -Force -Attributes !ReparsePoint | where{($_.Name -ne "AppData")} | Get-ChildItem -Recurse -File -Force -ErrorAction Ignore -Attributes !ReparsePoint | where{($_.Extension -NotIn ".lnk",".url",".ini",".dat",".log1",".log2",".blf") -and ($_.Extension -NotLike "*-ms")} | Select-Object -Property Directory, Name | Format-Table -Wrap -AutoSize | Out-Host

https://github.com/svetlyobg/Hardening

#TARD

remove all softwaer 32 and 64 but

Remove all task 
C:\Windows\System32\Tasks
REG
HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Taskcache\Tasks
HKLM\Software\Microsoft\Windows NT\CurrentVersion\Schedule\Taskcache\Tree

clear GP

Settings reset
https://www.tenforums.com/tutorials/165667-how-reset-settings-app-windows-10-a.html#option2
DIAble all task
https://support.microsoft.com/en-us/topic/how-to-perform-a-clean-boot-in-windows-da2f9573-6eec-00ad-2f8a-a97a1807f3dd#:~:text=the%20computer%20unusable.-,On%20the%20Services%20tab%20of%20System%20Configuration%2C%20select%20Hide%20all,Select%20Apply.

reomve acces to admin tools to users
https://www.maketecheasier.com/restrict-administrative-tools-access-windows/

rando
https://github.com/Cqctxs/Cyberpatriot-Windows/blame/main/script.ps1

https://github.com/Klocman/Bulk-Crap-Uninstaller
