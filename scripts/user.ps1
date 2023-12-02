#user

Function Set-PasswordRequirement {
	Param()
	
	Begin {
		Write-Output "Implementing password requirement for all user accounts...";
		Write-Output "";
	}
	
	Process {
		Try {
			$UserAccounts = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True";
			$UserAccounts_Number = $UserAccounts.Length;
			
			Write-Output "$UserAccounts_Number user accounts found.";
			Write-Output "";
			
			For ($i = 0; $i -NE $UserAccounts.Length; $i++){
				$Username = $UserAccounts[$i].Name;
				Write-Output "Current user account: $Username.";
				
				Write-Output "Disabling ""Password never expires""...";
				$Error.Clear();
				Try {
					$UserAccount = Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True AND Name='$Username'";
					$UserAccount.PasswordExpires=$True;
					$UserAccount.Put() | Out-Null;
				} Catch {
					Write-Output "...FAILED.";
				}
				If (!$error){
					Write-Output "...Success.";
				}
				
				Write-Output "Enabling ""User must change password at next logon""...";
				$Error.Clear();
				Try {
					$UserAccount = [ADSI]"WinNT://$env:computername/$Username"; 
					$UserAccount.PasswordExpired = 1;
					$UserAccount.SetInfo() | Out-Null;
				} Catch {
					Write-Output "...FAILED.";
				}
				If (!$error){
					Write-Output "...Success.";
				}
				
				Write-Output "";
			}
		}
		
		Catch {
			Write-Output "...FAILED implementing password requirement for all user accounts.";
			Break;
		}
	}
	
	End {
		If($?){ # only execute if the function was successful.
			Write-Output "...Success implementing password requirement for all user accounts.";
		}
	}
}

Set-PasswordRequirement