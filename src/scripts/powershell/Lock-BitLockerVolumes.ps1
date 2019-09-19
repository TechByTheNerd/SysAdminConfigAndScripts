<#

.SYNOPSIS
Locks all of the presumably portable Bitlocker volumes.

.DESCRIPTION
Locks the Bitlocker volumes on the local machine who have a password set, and 
that are NOT set to auto-unlock. These are volumes that require the user to submit a password.

.EXAMPLE
./Lock-BitlockerVolumes.ps1

#>
[CmdLetBinding()]
Param ()
#Requires -RunAsAdministrator

Write-Host "[*] Finding unlocked, portable Bitlocker volumes..." -ForegroundColor Cyan

$unlockedVolumes = Get-BitLockerVolume | Where-Object AutoUnlockEnabled -EQ $False | Where-Object LockStatus -EQ "Unlocked"

If ( ($unlockedVolumes.Count) -lt 1 ) {
    Write-Host "[+] No Bitlocker volumes are currently unlocked." -ForegroundColor Green
} else {
    Write-Host "[*] There are $($unlockedVolumes.Count) Bitlocker volumes to lock: $( ($unlockedVolumes | Select-Object -ExpandProperty MountPoint) -join ", " )" -ForegroundColor Cyan

    ForEach ( $unlockedVolume In $unlockedVolumes ) {
        Write-Host "    [*] Locking $($unlockedVolume.MountPoint)..." -ForegroundColor Cyan
        $result = Lock-BitLocker -MountPoint $unlockedVolume.MountPoint -Verbose:$False
        If ( $result.LockStatus -eq "Locked" ) {
            Write-Host "        [+] $($unlockedVolume.MountPoint) status: $($result.LockStatus)" -ForegroundColor Green
        } else {
            Write-Host "        [-] $($unlockedVolume.MountPoint) status: $($result.LockStatus)" -ForegroundColor Red
        }
    }
}

Write-Host "[*] Done." -ForegroundColor Cyan
