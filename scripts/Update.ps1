Function Enable-WindowsUpdate {
	Param()
	
	Begin {
		Write-Output "Enabling Windows Update...";
		Write-Output "";
	}
	
	Process {
		Try {
			Write-Output "`t Checking Windows service...";
			$WindowsUpdate_Service = Get-Service "wuauserv";
			$WindowsUpdate_StartupType = Get-WmiObject -Class Win32_Service -Property StartMode -Filter "Name='wuauserv'" | Select-Object -ExpandProperty StartMode;
			
			If ($WindowsUpdate_StartupType -Eq "Auto"){
				Write-Output "`t `t ...Startup type is already set to automatic.";
			} Else {
				Write-Output "`t `t ...Startup type is NOT set to automatic. Setting...";
				
				Try {
					Set-Service $WindowsUpdate_Service.Name -StartupType Automatic;
				}
				Catch {
					Write-Output "`t `t ...FAILURE. Exiting...";
					
					Break;
				}
				If($?){
					Write-Output "`t `t ...Success.";
				}
			}
			
			Write-Output "";
			
			If ($WindowsUpdate_Service.Status -Eq "Stopped"){
				Write-Output "`t `t ...Status is set to stopped. Starting...";
				Try {
					Start-Service $WindowsUpdate_Service.Name;
				}
				Catch {
					Write-Output "`t `t ...FAILURE. Exiting...";
					
					Break;
				}
				If($?){
					Write-Output "`t `t ...Success.";
				}
			} ElseIf ($WindowsUpdate_Service.Status -Eq "Running"){
				Write-Output "`t `t ...Status is already running.";
			}
		}
		
		Catch {
			Write-Output "`t ...FAILURE. Something went wrong.";
			Break;
		}
	}
	
	End {
		If($?){ # only execute if the function was successful.
			
		}
	}
}

Function Configure-WindowsUpdate {
	Param()
	
	Begin {
		Write-Output "Configuring Windows Update...";
		Write-Output "";
	}
	
	Process {
		Try {
			$WindowsUpdate_RegistryPath = "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU";
			$WindowsUpdate = New-Object -ComObject "Microsoft.Update.AutoUpdate";
			$WindowsUpdate_Settings = $WindowsUpdate.Settings;
			
			Write-Output "`t Enabling Windows Update...";
			
			Try {
				If (-Not (Test-Path $WindowsUpdate_RegistryPath)){
					New-Item -Path $WindowsUpdate_RegistryPath -Force | Out-Null;
				}
				
				Set-ItemProperty -Path $WindowsUpdate_RegistryPath -Name "NoAutoUpdate" -Type DWORD -Value "0" -Force;
			}
			Catch {
				Write-Output "`t `t ...FAILURE. Exiting...";
				
				Break;
			}
			If($?){
				Write-Output "`t `t ...Success.";
			}
			
			Write-Output "";
			
			Write-Output "`t Checking Important Updates configuration...";
			
			If ($WindowsUpdate_Settings.NotificationLevel -Eq 1) {
				Write-Output "`t `t ...Currently set to ""Never check for updates (not recommended)"".";
			} ElseIf ($WindowsUpdate_Settings.NotificationLevel -Eq 2) {
				Write-Output "`t `t ...Currently set to ""Check for updates but let me choose whether to download and install them"".";
			} ElseIf ($WindowsUpdate_Settings.NotificationLevel -Eq 3) {
				Write-Output "`t `t ...Currently set to ""Download updates but let me choose whether to install them"".";
			} ElseIf ($WindowsUpdate_Settings.NotificationLevel -Eq 4) {
				Write-Output "`t `t ...Currently set to ""Install updates automatically (recommended)"".";
			}
			
			Write-Output "";
			
			Write-Output "`t `t Setting to ""Install updates automatically (recommended)""...";
			
			Try {
				Set-ItemProperty -Path $WindowsUpdate_RegistryPath -Name "AUOptions" -Type DWORD -Value "4" -Force;
			}
			Catch {
				Write-Output "`t `t ...FAILURE. Exiting...";
				
				Break;
			}
			If($?){
				Write-Output "`t `t ...Success.";
			}
		
			Write-Output "";
			
			Write-Output "`t Checking Recommended Updates configuration...";
			
			If ($WindowsUpdate_Settings.IncludeRecommendedUpdates -Eq $False) {
				Write-Output "`t `t ...Currently set to disabled. ";
				Write-Output "";
				Write-Output "`t `t Setting to enabled...";
				
				Try {
					Set-ItemProperty -Path $WindowsUpdate_RegistryPath -Name "AutoInstallMinorUpdates" -Type DWORD -Value "0" -Force;
					Set-ItemProperty -Path $WindowsUpdate_RegistryPath -Name "IncludeRecommendedUpdates" -Type DWORD -Value "1" -Force;
				}
				Catch {
					Write-Output "`t `t ...FAILURE. Exiting...";
					
					Break;
				}
				If($?){
					Write-Output "`t `t ...Success.";
				}
			} ElseIf ($WindowsUpdate_Settings.IncludeRecommendedUpdates -Eq $True) {
				Write-Output "`t `t ...Set to enabled.";
			}
			
			Write-Output "";
			
			Write-Output "`t Setting Windows Update to update other Microsoft products...";
			
			Try {
				Set-ItemProperty -Path $WindowsUpdate_RegistryPath -Name "AllowMUUpdateService" -Type DWORD -Value "1" -Force;
				
				$MicrosoftUpdateServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager";
				$MicrosoftUpdateServiceManager.ClientApplicationID = "My App";
				$MicrosoftUpdateServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"") | Out-Null;
			}
			Catch {
				Write-Output "`t `t ...FAILURE. Exiting...";
				
				Break;
			}
			If($?){
				Write-Output "`t `t ...Success.";
			}
			
			Write-Output "";
			
			Write-Output "`t Setting installation schedule to default ""Every day at 03:00"".";
			
			Try {
				Set-ItemProperty -Path $WindowsUpdate_RegistryPath -Name "ScheduledInstallDay" -Type DWORD -Value "0" -Force;
				Set-ItemProperty -Path $WindowsUpdate_RegistryPath -Name "ScheduledInstallTime" -Type DWORD -Value "3" -Force;
			}
			Catch {
				Write-Output "`t `t ...FAILURE. Exiting...";
				
				Break;
			}
			If($?){
				Write-Output "`t `t ...Success.";
			}
		}
		
		Catch {
			Write-Output "`t ...FAILURE. Something went wrong.";
			Break;
		}
		
		
	}
	
	End {
		If($?){ # only execute if the function was successful.
			
		}
	}
}

Configure-WindowsUpdate

Install-Module PSWindowsUpdate
Add-WUServiceManager -MicrosoftUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot | Out-File "C:\($env.computername-Get-Date -f yyyy-MM-dd)-MSUpdates.log" -Force
