<#
             ~ Force Intune to retry app installs ~
    2023-11-28 / https://github.com/Arf-Echidna / MIT License
                         ver. 1.0.2

The script performs the following tasks: 
1) Remove the registry keys which track install attempts. Effectively, this resets the install attempt counter for all apps to zero.
2) Restart IME Service, causing evaluation to run ASAP.  
3) Send SyncApp command to IME.

#> 

function Reset-IMEAppStatus {
[CmdletBinding()]
param(
[Parameter(Mandatory = $true)]
[ValidateNotNullOrEmpty()]
[string] ${"Paste in the user's ObjectID from Azure"}
)

## We need the user's object ID from Azure to search for in registry
$UserObjectID = ${"Paste in the user's ObjectID from Azure"}
write-host "Checking for user keys for user w/object ID: $UserObjectID"

## Variables
$Path = "HKLM:SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
$DosPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps"
$Exist = test-path $Path

## Clear the keys
if ($Exist -eq $False) {
write-warning "Path to Win32apps registry does not exist`nPlease verify device is enrolled in Intune and healthy`nExiting script..."
throw "The main Win32app registry key was not found."
}
else {
    $Exist = Test-Path "$Path\$UserObjectID"
    if ($Exist -eq $False) {
        write-warning "User $UserObjectID does not have a registry entry`nIs the UserID Correct?`nHas the user logged in to this PC before?`nExiting script..." 
        throw "The provided UserID was not found."
    }    
    elseif ($Exist -eq $True) {   
        $keys = get-childitem "$Path\$UserObjectID" -recurse | select-object -expandproperty "name" 
        $count = $keys.count
        foreach($key in $keys) {
            write-host "Registry entry found:"
            write-host $key.trimstart("$DosPath\$UserObjectID")
            }
            write-host "Found $count registry entries at $Path\$UserObjectID.`nAttempting to delete..."
            Get-Item  -Path $Path\$UserObjectID | Remove-Item -Recurse -Force
            $Exist = test-path "$Path\$UserObjectID"
            if ($Exist -eq $False) {
                write-host "Successfully removed $count keys from user $UserObjectID" -foregroundcolor green
            }
            elseif ($Exist -eq $True) {
                write-warning "Not all keys successfully removed from $Path\$UserObjectID`nProceeding anyway..."
            }       
        }
    }                     
    
## Restart service
$IMES = "intunemanagementextension"

write-host "Stopping IME Service.." 
get-service $IMES | stop-service
(get-service $IMES).WaitForStatus('Stopped')

write-host "Starting IME Service.." 
get-service $IMES | start-service
(get-service $IMES).WaitForStatus('Running')
write-host "IME Service restarted succesfully."

## Send appsync command
write-host "Sending appsync command to IME..." 
start "intunemanagementextension://syncapp"
write-host "Finished resetting app status for user id: $UserObjectID" -foregroundcolor green
}

## Do the thing! 
Reset-IMEAppStatus