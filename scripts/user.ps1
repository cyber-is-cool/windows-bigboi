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

l_output="" l_output2=""
l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"
a_users=(); a_ulock=() # initialize arrays
while read -r l_user; do # change system accounts that have a valid login shell to nolog shell
echo -e " - System account \"$l_user\" has a valid logon shell, changing shell to \"$(which nologin)\""
usermod -s "$(which nologin)" "$l_user"
done < <(awk -v pat="$l_valid_shells" -F: '($1!~/(root|sync|shutdown|halt|^\+)/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $(NF) ~ pat) { print $1 }' /etc/passwd)
while read -r l_ulock; do # Lock system accounts that aren't locked
echo -e " - System account \"$l_ulock\" is not locked, locking account"
usermod -L "$l_ulock"
done < <(awk -v pat="$l_valid_shells" -F: '($1!~/(root|^\+)/ && $2!~/LK?/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $(NF) ~ pat) {print $1 }' /etc/passwd)
	}

	echo $l_output
	echo $l_output2

read -p "Locking service accounts"
clear	
{
declare -A HASH_MAP=( ["y"]="yescrypt" ["1"]="md5" ["2"]="blowfish"["5"]="SHA256" ["6"]="SHA512" ["g"]="gost-yescrypt" )
CONFIGURED_HASH=$(sed -n "s/^\s*ENCRYPT_METHOD\s*\(.*\)\s*$/\1/p" /etc/login.defs)
for MY_USER in $(sed -n "s/^\(.*\):\\$.*/\1/p" /etc/shadow)
do
CURRENT_HASH=$(sed -n "s/${MY_USER}:\\$\(.\).*/\1/p" /etc/shadow)
if [[ "${HASH_MAP["${CURRENT_HASH}"]^^}" != "${CONFIGURED_HASH^^}" ]];
then
echo "The password for '${MY_USER}' is using '${HASH_MAP["${CURRENT_HASH}"]}' instead of the configured '${CONFIGURED_HASH}'."
fi
done
}
read -p "Users that dont use current encryption standerd"


clear

/usr/bin/env bash use/log.sh    
read -p "?"
clear
    
clear
awk -F: '($2 == "" ) { print $1 " does not have a password "}' /etc/shadow
read -p "No password users"
sed -e 's/^\([a-zA-Z0-9_]*\):[^:]*:/\1:x:/' -i /etc/passwd

for i in $(cut -s -d: -f4 /etc/passwd | sort -u ); do
	grep -q -P "^.*?:[^:]*:$i:" /etc/group
	if [ $? -ne 0 ]; then
		echo "Group $i is referenced by /etc/passwd but does not exist in /etc/group"
	fi
done
read -p "Group"
sed -ri 's/(^shadow:[^:]*:[^:]*:)([^:]+$)/\1/' /etc/group

while read -r l_count l_uid; do
	if [ "$l_count" -gt 1 ]; then
	echo -e "Duplicate UID: \"$l_uid\" Users: \"$(awk -F: '($3 == n) { print $1 }' n=$l_uid /etc/passwd | xargs)\""
fi
done < <(cut -f3 -d":" /etc/passwd | sort -n | uniq -c)
read -p "Duplicate UID"

cut -d: -f3 /etc/group | sort | uniq -d | while read x ; do
	echo "Duplicate GID ($x) in /etc/group"
done
read -p "duplicate GIDs"
cut -d: -f1 /etc/passwd | sort | uniq -d | while read -r x; do
	echo "Duplicate login name $x in /etc/passwd"
done
read -p "duplicate usernames"

cut -d: -f1 /etc/group | sort | uniq -d | while read -r x; do
	echo "Duplicate group name $x in /etc/group"
done
read -p "duplicate group names"
read -p "CLEAR"
clear
RPCV="$(sudo -Hiu root env | grep '^PATH' | cut -d= -f2)"
echo "$RPCV" | grep -q "::" && echo "root's path contains a empty directory (::)"
echo "$RPCV" | grep -q ":$" && echo "root's path contains a trailing (:)"
for x in $(echo "$RPCV" | tr ":" " "); do
	if [ -d "$x" ]; then
	ls -ldH "$x" | awk '$9 == "." {print "PATH contains current working directory (.)"} $3 != "root" {print $9, "is not owned by root"} substr($1,6,1) != "-" {print $9, "is group writable"} substr($1,9,1) != "-" {print $9, "is world writable"}'
else
	echo "$x is not a directory"
fi
done
read -p "Root intergerty check"
	awk -F: '($3 == 0) { print $1 }' /etc/passwd
read -p "Should be root -=- UID 0"

clear
/usr/bin/env bash use/home.sh    
read -p "cont ---"
clear
/usr/bin/env bash use/dot.sh
read -p "cont ---"
