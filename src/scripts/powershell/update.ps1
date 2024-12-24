# Prerequisites
# - `winget` Installed by default in Windows 11.
# - `choco` Install Chocolatey from chocolatey.org. `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`
# - `winfetch` Install using Chocolatey (`choco install winfetch`).
# - `figlet` Install using Chocolatey (`choco install figlet-go`).
# - Windows Update Module: Install PSWindowsUpdate module with: `Install-Module -Name PSWindowsUpdate -Force`

# Color Definitions
$Black = "`e[0;30m"
$DarkGray = "`e[1;30m"
$Red = "`e[0;31m"
$LightRed = "`e[1;31m"
$Green = "`e[0;32m"
$LightGreen = "`e[1;32m"
$Brown = "`e[0;33m"
$Yellow = "`e[1;33m"
$Blue = "`e[0;34m"
$LightBlue = "`e[1;34m"
$Purple = "`e[0;35m"
$LightPurple = "`e[1;35m"
$Cyan = "`e[0;36m"
$LightCyan = "`e[1;36m"
$LightGray = "`e[0;37m"
$White = "`e[1;37m"
$NC = "`e[0m" # No Color

# Script Info
$Name = "Windows Update Utility"
$Version = "v1.0.0-alpha.1"

function Set-Status {
    param (
        [string]$Message,
        [string]$Severity
    )

    switch ($Severity) {
        "s" { Write-Host "[+] $Message" -ForegroundColor Green }
        "f" { Write-Host "[-] $Message" -ForegroundColor Red }
        "q" { Write-Host "[?] $Message" -ForegroundColor Magenta }
        default { Write-Host "[*] $Message" -ForegroundColor Cyan }
    }
}

function Run-Command {
    param (
        [string]$BeforeText,
        [string]$AfterText,
        [scriptblock]$CommandToRun
    )

    Set-Status $BeforeText "s"
    & $CommandToRun
    Set-Status $AfterText "s"
}

Write-Host "$Name $Version" -ForegroundColor Magenta

# Check for Administrator Rights
If (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Set-Status "ERROR: This utility must be run as an administrator." "f"
    exit 1
}

# Optional Winfetch/Neofetch Display
if (Get-Command winfetch -ErrorAction SilentlyContinue) {
    Write-Host -ForegroundColor Yellow
    winfetch
    Write-Host $NC
}

if (Get-Command figlet -ErrorAction SilentlyContinue) {
    Write-Host -ForegroundColor Yellow
    hostname | figlet
    Write-Host $NC
}

Set-Status "Update starting..." "s"

# Winget Upgrade
Run-Command "STEP 1 of 4: Checking for Winget package updates..." "Winget updates checked." {
    winget upgrade
}
Run-Command "STEP 2 of 4: Upgrading Winget packages..." "Winget packages upgraded." {
    winget upgrade --all --nowarn --disable-interactivity --accept-source-agreements --accept-package-agreements
}

# Chocolatey Upgrade
Run-Command "STEP 3 of 4: Upgrading Chocolatey packages..." "Chocolatey packages upgraded." {
    choco upgrade all -y
}

# Windows Update
Run-Command "STEP 4 of 4: Checking for Windows Updates..." "Windows updates checked." {
    Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
}

# Restart if Required
if (Get-ComputerInfo -Property CsRequiresManualRestart) {
    Set-Status "A restart is required. Would you like to restart now? [y/n]" "q"
    $Choice = Read-Host "> "
    switch ($Choice.ToLower()) {
        "y" {
            Set-Status "Rebooting now..." "i"
            Restart-Computer
        }
        "n" {
            Set-Status "Skipping reboot." "i"
        }
        default {
            Set-Status "Invalid response. Skipping reboot." "f"
        }
    }
} else {
    Set-Status "No reboot required." "i"
}

Set-Status "System update complete." "s"
