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



