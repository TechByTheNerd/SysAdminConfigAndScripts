<#

.SYNOPSIS
Unlocks all of the presumably portable Bitlocker volumes.

.DESCRIPTION
Unlocks the Bitlocker volumes on the local machine who have a password set, and 
that are NOT set to auto-unlock. These are volumes that require the user to submit a password.

.PARAMETER BitlockerPassword
(Optional) The SecureString password to use to unlock the Bitlocker-protected volumes. If this
is not provided, then the user will be prompted for a password.

.EXAMPLE
./Unlock-BitlockerVolumes.ps1

.EXAMPLE
$bitlockerSecureString = Read-Host -AsSecureString "Enter Bitlocker password: "
./Unlock-BitlockerVolumes.ps1 -BitlockerPassword $bitlockerSecureString
$bitlockerSecureString = $null

.LINK
https://www.techbythenerd.com/
https://github.com/TechByTheNerd/SysAdminConfigAndScripts/tree/master/src/scripts

#>
[CmdLetBinding()]
Param (
    # $BitlockerPassword The password to use to unlock the Bitlocker volumes. If missing, user will be prompted.
    [Parameter(Mandatory=$false)]
    [SecureString]$BitlockerPassword
)
#Requires -RunAsAdministrator

Write-Host "[*] Finding locked Bitlocker volumes..." -ForegroundColor Cyan

$lockedVolumes = Get-BitLockerVolume | Where-Object LockStatus -EQ "Locked"

If ( ($lockedVolumes.Count) -lt 1 ) {
    Write-Host "[+] No Bitlocker volumes are currently locked." -ForegroundColor Green
} else {
    Write-Host "[*] There are $($lockedVolumes.Count) Bitlocker volumes to Unlock: $( ($lockedVolumes | Select-Object -ExpandProperty MountPoint) -join ", " )" -ForegroundColor Cyan

    If ( $null -eq $BitlockerPassword ) {
        Write-Host "[?] Prompting for Bitlocker password." -ForegroundColor Magenta
        $BitlockerPassword = Read-Host -AsSecureString "Enter Bitlocker password: "

        If ( $null -eq $BitlockerPassword ) {
            Write-Host "    [-] User did not enter password or hit cancel. Cannot continue." -ForegroundColor Red
            exit
        } else {
            Write-Host "    [+] User supplied a SecureString password for the Bitlocker volumes." -ForegroundColor Green
        }
    }

    ForEach ( $lockedVolume In $lockedVolumes ) {
        Write-Host "[*] Unlocking $($lockedVolume.MountPoint)..." -ForegroundColor Cyan
        $result = Unlock-BitLocker -MountPoint $lockedVolume.MountPoint -Password $BitlockerPassword -Verbose:$False
        If ( $result.LockStatus -eq "Unlocked" ) {
            Write-Host "    [+] $($lockedVolume.MountPoint) status: $($result.LockStatus)" -ForegroundColor Green
        } else {
            Write-Host "    [-] $($lockedVolume.MountPoint) status: $($result.LockStatus)" -ForegroundColor Red
        }
    }

    $BitlockerPassword = $null
}

Write-Host "[*] Done." -ForegroundColor Cyan
