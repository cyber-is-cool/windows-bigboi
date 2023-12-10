# windows-bigboi
Get-ChildItem -Path "C:\Users" -Exclude "$env:UserName" | Get-ChildItem -Force -Attributes !ReparsePoint | where{($_.Name -ne "AppData")} | Get-ChildItem -Recurse -File -Force -ErrorAction Ignore -Attributes !ReparsePoint | where{($_.Extension -NotIn ".lnk",".url",".ini",".dat",".log1",".log2",".blf") -and ($_.Extension -NotLike "*-ms")} | Select-Object -Property Directory, Name | Format-Table -Wrap -AutoSize | Out-Host

Get-Process | Where-Object {$_.WorkingSet -gt 20000000}


https://public.cyber.mil/stigs/gpo/
