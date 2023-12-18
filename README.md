# Reset-IMEAppStatus
Force Intune to retry app installs.
This is helpful for testing application deployments.

The script performs the following tasks: 
1) Remove the registry keys which track install attempts. Effectively, this resets the install attempt counter for all apps to zero.
2) Restart IME Service, causing evaluation to run ASAP.  
3) Send SyncApp command to IME.

When ran, will prompt for the user's Object ID from Entra/Intune. 
