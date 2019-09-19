# Overview:

This is an overview of the scripts in this folder.

# Scripts:

Below is a summary of each script and how to use them. The idea for these scripts is that if you have portable USB drives used for backups, and wanted to be able to easily lock and unlock them, you could throw together some scripts to accomplish that.

These scripts only affect Bitlocker drives that have a password set and that don't auto-unlock (for security reasons). It also assumes the same password for all connected USB drives that are Bitlocker-protected.

## Script: `Get-BitlockerStatus.ps1`

This script gets the status of presumed, portable Bitlocker volumes. That is, like portable USB drives that are Bitlocker protected with a password.

### Example Output

```
[*] Finding portable Bitlocker volumes...

MountPoint LockStatus
---------- ----------
E:           Unlocked
F:           Unlocked
H:           Unlocked
```

## Script: `Unlock-BitLockerVolumes.ps1`

This script unlocks presumed, portable Bitlocker volumes. That is, like portable USB drives that are Bitlocker protected with a password.

A `SecureString` password can be passed in, for example like this:

```powershell
$bitlockerSecureString = Read-Host -AsSecureString "Enter Bitlocker password: "
./Unlock-BitlockerVolumes.ps1 -BitlockerPassword $bitlockerSecureString
$bitlockerSecureString = $null
```

or like this:

```powershell
$bitlockerSecureString = ConvertTo-SecureString "P@ssW0rD!" -AsPlainText -Force
./Unlock-BitlockerVolumes.ps1 -BitlockerPassword $bitlockerSecureString
$bitlockerSecureString = $null
```

Or - without the `-BitlockerPassword` argument, the user will be interactively prompted for the password.

### Example Output

```
[*] Finding locked Bitlocker volumes...
[*] There are 3 Bitlocker volumes to Unlock: E:, F:, H:
[?] Prompting for Bitlocker password.
Enter Bitlocker password: : **************
[+] User supplied a SecureString password for the Bitlocker volumes.
[*] Unlocking E:...
    [+] E: status: Unlocked
[*] Unlocking F:...
    [+] F: status: Unlocked
[*] Unlocking H:...                                                                                                                                                                  [+] H: status: Unlocked
    [+] H: status: Unlocked
[*] Done.
```

## Script: `Lock-BitLockerVolumes.ps1`

This script locks presumed, portable Bitlocker volumes. That is, like portable USB drives that are Bitlocker protected with a password.

### Example Output

```
[*] Finding unlocked, portable Bitlocker volumes...
[*] There are 3 Bitlocker volumes to lock: E:, F:, H:
    [*] Locking E:...
        [+] E: status: Locked
    [*] Locking F:...
        [+] F: status: Locked
    [*] Locking H:...
        [+] H: status: Locked
[*] Done.
```
