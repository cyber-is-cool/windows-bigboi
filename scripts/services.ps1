#Import the GroupPolicies.csv file into a variable

$services = Import-Csv -Path "$($PSScriptRoot)\Services.csv"

foreach ($service in $services) {
    
    try {
        Set-Service -Name $service.Process -StartupType $service.Mode -ErrorAction Stop
        Write-Host "$($service.Name) was configured incorrectly. Startup type has been switched to $($service.Mode)." -ForegroundColor green
    } catch {
        Write-Host "Failed to change startup type for $($service.Name) to $($service.Mode)." -ForegroundColor red
        continue
    }

    if (($service.Mode -eq 'Automatic') -and -not ((Get-Service | where name -eq $service.Process).Status -eq 'Running')) {
        try {
            Start-Service -Name $service.Process -ErrorAction Stop | Out-Null
            Write-Host "$($service.Name) is now started." -ForegroundColor green
        } catch {
            Write-Host "Failed to start the $($service.Name) service." -ForegroundColor red
            continue
        }
    }

    if (($service.Mode -eq 'Disabled') -and -not ((Get-Service | where name -eq $service.Process).Status -eq 'Stopped')) {
        try {
            Stop-Service -Name $service.Process -ErrorAction Stop | Out-Null
            Write-Host "$($service.Name) is now stopped." -ForegroundColor green
        } catch {
            Write-Host "Failed to stop the $($service.Name) service." -ForegroundColor red
            continue
        }
        
    }
}


Function Secure-WindowsServices {
	Param()
	
	Begin {
		Write-Output "Securing all Windows services...";
	}
	
	Process {
		Try {
			If ($AlreadyRun -Eq $Null){
				$AlreadyRun = $False;
			} Else {
				$AlreadyRun = $True;
			}
			
			If ($AlreadyRun -Eq $False){
				[System.Collections.ArrayList]$FilesChecked = @(); # This is critical to ensuring that the array isn't a fixed size so that items can be added;
				[System.Collections.ArrayList]$FoldersChecked = @(); # This is critical to ensuring that the array isn't a fixed size so that items can be added;
			}
			
			Write-Output "";
			
			Write-Output "`t Searching for Windows services...";
			
			$WindowsServices = Get-WmiObject Win32_Service | Select Name, DisplayName, PathName | Sort-Object DisplayName;
			$WindowsServices_Total = $WindowsServices.Length;
			
			Write-Output "`t`t $WindowsServices_Total Windows services found.";
			
			Write-Output "";
			
			For ($i = 0; $i -LT $WindowsServices_Total; $i++) {
				$Count = $i + 1;
				
				$WindowsService_DisplayName = $WindowsServices[$i].DisplayName;
				$WindowsService_Path = $WindowsServices[$i].PathName;
				$WindowsService_File_Path = ($WindowsService_Path -Replace '(.+exe).*', '$1').Trim('"');
				$WindowsService_Folder_Path = Split-Path -Parent $WindowsService_File_Path;
				
				Write-Output "`t Windows service ""$WindowsService_DisplayName"" ($Count of $WindowsServices_Total)...";
				
				If ($FoldersChecked -Contains $WindowsService_Folder_Path){
					Write-Output "`t`t Folder ""$WindowsService_Folder_Path"": Security has already been ensured.";
					Write-Output "";
				} Else {
					$FoldersChecked += $WindowsService_Folder_Path;
					
					Write-Output "`t`t Folder ""$WindowsService_Folder_Path"": Security has not yet been ensured.";
					
					Correct-InsecurePermissions -Path $WindowsService_Folder_Path;
				}
				
				If ($FilesChecked -Contains $WindowsService_File_Path){
					Write-Output "`t`t File ""$WindowsService_File_Path"": Security has already been ensured.";
					Write-Output "";
				} Else {
					$FilesChecked += $WindowsService_File_Path;
					
					Write-Output "`t`t File ""$WindowsService_File_Path"": Security has not yet been ensured.";
					
					Correct-InsecurePermissions -Path $WindowsService_File_Path;
				}
			}
		}
		
		Catch {
			Write-Output "...FAILURE securing all Windows services.";
			$_.Exception.Message;
			$_.Exception.ItemName;
			Break;
		}
	}
	
	End {
		If($?){
			Write-Output "...Success securing all Windows services.";
		}
	}
}

Function Correct-InsecurePermissions {
	Param(
		[Parameter(Mandatory=$true)][String]$Path
	)
	
	Begin {
		
	}
	
	Process {
		Try {
			$ACL = Get-ACL $Path;
			$ACL_Access = $ACL | Select -Expand Access;
			
			$InsecurePermissionsFound = $False;
			
			ForEach ($ACE_Current in $ACL_Access) {
				$SecurityPrincipal = $ACE_Current.IdentityReference;
				$Permissions = $ACE_Current.FileSystemRights.ToString() -Split ", ";
				$Inheritance = $ACE_Current.IsInherited;
				
				ForEach ($Permission in $Permissions){
					If ((($Permission -Eq "FullControl") -Or ($Permission -Eq "Modify") -Or ($Permission -Eq "Write")) -And (($SecurityPrincipal -Eq "Everyone") -Or ($SecurityPrincipal -Eq "NT AUTHORITY\Authenticated Users") -Or ($SecurityPrincipal -Eq "BUILTIN\Users") -Or ($SecurityPrincipal -Eq "$Env:USERDOMAIN\Domain Users"))) {
						$InsecurePermissionsFound = $True;
						
						Write-Output "`t`t`t [WARNING] Insecure permissions found: ""$Permission"" granted to ""$SecurityPrincipal"".";
						
						If ($Inheritance -Eq $True){
							$Error.Clear();
							Try {
								$ACL.SetAccessRuleProtection($True,$True);
								Set-Acl -Path $Path -AclObject $ACL;
							} Catch {
								Write-Output "`t`t`t`t [FAILURE] Could not convert permissions from inherited to explicit.";
							}
							If (!$error){
								Write-Output "`t`t`t`t [SUCCESS] Converted permissions from inherited to explicit.";
							}
							
							# Once permission inheritance has been disabled, the permissions need to be re-acquired in order to remove ACEs
							$ACL = Get-ACL $Path;
						} Else {
							Write-Output "`t`t`t`t [NOTIFICATION] Permissions not inherited.";
						}
						
						Write-Output "";
						
						$Error.Clear();
						Try {
							$ACE_New = New-Object System.Security.AccessControl.FileSystemAccessRule($SecurityPrincipal, $Permission, , , "Allow");
							$ACL.RemoveAccessRuleAll($ACE_New);
							Set-Acl -Path $Path -AclObject $ACL;
						} Catch {
							Write-Output "`t`t`t`t [FAILURE] Insecure permissions could not be removed.";
						}
						If (!$error){
							Write-Output "`t`t`t`t [SUCCESS] Removed insecure permissions.";
						}
						
						Write-Output "";
					}
				}
			}
			
			If ($InsecurePermissionsFound -Eq $False) {
				Write-Output "`t`t`t [NOTIFICATION] No insecure permissions found.";
				Write-Output "";
			}
		}
		
		Catch {
			Write-Output "`t`t`t ...FAILURE.";
			$_.Exception.Message;
			$_.Exception.ItemName;
			Break;
		}
	}
	
	End {
		If($?){
			
		}
	}
}

Secure-WindowsServices;