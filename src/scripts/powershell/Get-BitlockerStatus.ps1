<#

.SYNOPSIS
Gets the status of presumably portable Bitlocker volumes.

.DESCRIPTION
Enumerates the Bitlocker volumes on the local machine who have a password set, and 
that are NOT set to auto-unlock. These are volumes that require the user to submit a password.

.EXAMPLE
PS> ./Get-BitlockerStatus.ps1

#>
[CmdLetBinding()]
Param ()
#Requires -RunAsAdministrator

Write-Host "[*] Finding portable Bitlocker volumes..." -ForegroundColor Cyan

$allVolumes = Get-BitLockerVolume | Where-Object AutoUnlockEnabled -EQ $False

$allVolumes | Select-Object MountPoint, LockStatus | Format-Table -AutoSize