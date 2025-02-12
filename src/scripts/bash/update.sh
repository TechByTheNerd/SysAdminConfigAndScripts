#!/bin/bash

# Define colors
Black='\033[0;30m'
DarkGray='\033[1;30m'
Red='\033[0;31m'
LightRed='\033[1;31m'
Green='\033[0;32m'
LightGreen='\033[1;32m'
Brown='\033[0;33m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
LightBlue='\033[1;34m'
Purple='\033[0;35m'
LightPurple='\033[1;35m'
Cyan='\033[0;36m'
LightCyan='\033[1;36m'
LightGray='\033[0;37m'
White='\033[1;37m'
NC='\033[0m' # No Color

Name='Debian-based System Update Utility'
Version='v1.0.0-alpha.1'

# Function to set the terminal title
function setXtermTitle () {
    newTitle=$1
    if [[ -z $newTitle ]]; then
        case "$TERM" in
            xterm*|rxvt*)
                PS1="\[\e]0;$newTitle\u@\h: \w\a\]$PS1"
            ;;
            *)
            ;;
        esac
    else
        case "$TERM" in
            xterm*|rxvt*)
                PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
            ;;
            *)
            ;;
        esac
    fi
}

# Function to set status messages with color
function setStatus(){
    description=$1
    severity=$2
    setXtermTitle "$description"
    logger "$Name $Version: [${severity}] $description"
    case "$severity" in
        s)
            echo -e "[${LightGreen}+${NC}] ${LightGreen}${description}${NC}"
        ;;
        f)
            echo -e "[${Red}-${NC}] ${LightRed}${description}${NC}"
        ;;
        q)
            echo -e "[${LightPurple}?${NC}] ${LightPurple}${description}${NC}"
        ;;
        *)
            echo -e "[${LightCyan}*${NC}] ${LightCyan}${description}${NC}"
        ;;
    esac
    [[ $WithVoice -eq 1 ]] && echo -e "${description}" | espeak
}

# Function to run commands with status messages and error handling
function runCommand(){
    beforeText=$1
    afterText=$2
    commandToRun=$3
    setStatus "${beforeText}" "*"
    if eval "$commandToRun"; then
        setStatus "$afterText" "s"
    else
        setStatus "ERROR: Command failed - $commandToRun" "f"
        exit 1
    fi
}

# Function to check if a command exists
function commandExists() {
    command -v "$1" >/dev/null 2>&1
}

# Main script starts here
echo -e "${LightPurple}$Name $Version${NC}"

# Display usage if help is requested
if [[ $1 == "?" || $1 == "/?" || $1 == "--help" ]]; then
    setStatus "USAGE: sudo $0" "i"
    exit 0
fi

# Ensure the script is run as root
if [[ $(whoami) != "root" ]]; then
    setStatus "ERROR: This utility must be run as root (or sudo)." "f"
    exit 1
fi

WithVoice=0

# Check for espeak if voice is enabled
if [[ $WithVoice -eq 1 ]]; then
    if ! commandExists espeak; then
        setStatus "ERROR: To use speech, please install espeak (sudo apt-get install espeak)" "f"
        exit 1
    else
        setStatus "Voice detected - using espeak." "s"
    fi
fi

# Display system information using neofetch and figlet if available
if commandExists neofetch; then
    echo -e -n "${Yellow}"
    neofetch
    echo -e "${NC}"
fi

if commandExists figlet; then
    echo -e -n "${Yellow}"
    echo "$(hostname)" | figlet
    echo -e "${NC}"
fi

setStatus "Update starting..." "*"

# Run update commands
runCommand "STEP 1 of 4: Refreshing repository cache..." "Repository cache refreshed." "sudo apt-get update -y"
runCommand "STEP 2 of 4: Upgrading all existing packages..." "Existing packages upgraded." "sudo apt-get upgrade -y"
runCommand "STEP 3 of 4: Upgrading packages with conflict detection..." "Upgrade processed." "sudo apt-get dist-upgrade -y"
runCommand "STEP 4 of 4: Cleaning up unused and cached packages..." "Package cleanup complete." "sudo apt-get autoclean -y && sudo apt-get autoremove -y"

# Update snaps
if commandExists snap; then
    runCommand "Updating snaps..." "Snaps updated." "sudo snap refresh"
fi

# Update flatpaks
if commandExists flatpak; then
    runCommand "Updating flatpaks..." "Flatpaks updated." "sudo flatpak update -y"
fi

setStatus "Update complete." "*"

# Update Raspberry Pi firmware if rpi-update is available
if commandExists rpi-update; then
    setStatus "Raspberry Pi Detected." "s"
    [[ $WithVoice -eq 1 ]] && echo -e "Raspberry Pi Detected." | espeak
    setStatus "Updating the Raspberry Pi firmware to the latest (if available)..." "s"
    [[ $WithVoice -eq 1 ]] && echo -e "Updating the Raspberry Pi firmware to the latest." | espeak
    sudo rpi-update
    setStatus "Done updating firmware." "s"
    [[ $WithVoice -eq 1 ]] && echo -e "Done updating firmware." | espeak
fi

# Check if a reboot is required
if [ -f /var/run/reboot-required ]; then
    setStatus "PLEASE NOTE: A reboot is required." "i"
    setStatus "Would you like to reboot now?" "?"
    [[ $WithVoice -eq 1 ]] && echo -e "Would you like to reboot now?" | espeak
    while true; do
        read -e -r -p "> " choice
        case "$choice" in
            y|Y )
                setStatus "Rebooting..." "i"
                sudo reboot
                break
            ;;
            n|N )
                setStatus "Done." "s"
                break
            ;;
            * )
                setStatus "Invalid response. Use 'y' or 'n'." "f"
            ;;
        esac
    done
else
    setStatus "No reboot is required." "i"
fi

setStatus "System update complete." "s"
