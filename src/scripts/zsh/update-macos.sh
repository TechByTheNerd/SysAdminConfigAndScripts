#!/bin/zsh

# Colors for output formatting
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

NAME='macOS Update Utility'
VERSION='v1.0.4'

function setStatus() {
  description=$1
  color=$2
  echo -e "[${color}*${NC}] ${description}"
}

function runCommand() {
  beforeText=$1
  afterText=$2
  commandToRun=$3

  setStatus "$beforeText" "$YELLOW"
  eval $commandToRun
  setStatus "$afterText" "$GREEN"
}

# Handle script termination gracefully
trap "setStatus 'Script terminated by user.' '$RED'; exit 1" SIGINT SIGTERM

# Print script name and version
echo -e "${YELLOW}$NAME $VERSION${NC}"

# Display system information using neofetch (if available)
if command -v neofetch &> /dev/null; then
  neofetch
else
  setStatus "Neofetch is not installed. You can install it with 'brew install neofetch'." "$YELLOW"
fi

# Display computer name using figlet (if available)
if command -v figlet &> /dev/null; then
  echo -e "${YELLOW}"
  figlet $(hostname)
  echo -e "${NC}"
else
  setStatus "Figlet is not installed. You can install it with 'brew install figlet'." "$YELLOW"
fi


# Step 1: Update macOS
runCommand "STEP 1 of 4: Checking for macOS updates..." "macOS update check complete." "softwareupdate -l"

# Get current macOS version
CURRENT_VERSION=$(sw_vers -productVersion)

# Prompt for major macOS upgrade
MAJOR_UPGRADE_LABEL=$(softwareupdate -l | grep -E "Label:.*macOS.*Version: [0-9]+\.[0-9]+\.[0-9]*" | awk -F ': ' '{print $2}' | head -n 1)
MAJOR_UPGRADE_VERSION=$(echo "$MAJOR_UPGRADE_LABEL" | grep -oE '[0-9]+\.[0-9]+')

if [[ "$MAJOR_UPGRADE_VERSION" > "$CURRENT_VERSION" ]]; then
  setStatus "A major macOS upgrade is available (Version $MAJOR_UPGRADE_VERSION). Do you want to install it? (y/n)" "$YELLOW"
  read -q "UPGRADE_NOW?Enter your choice: "
  echo ""
  if [[ "$UPGRADE_NOW" == "y" || "$UPGRADE_NOW" == "Y" ]]; then
    setStatus "Installing major macOS upgrade..." "$YELLOW"
    softwareupdate -i "$MAJOR_UPGRADE_LABEL"
  else
    setStatus "Skipping major macOS upgrade." "$YELLOW"
    setStatus "Installing only current macOS patches..." "$YELLOW"
    softwareupdate -i -a
  fi
else
  setStatus "Installing available macOS updates..." "$YELLOW"
  softwareupdate -i -r
fi

# Step 3: Update App Store applications (if installed)
if command -v mas &> /dev/null; then
  setStatus "STEP 2 of 4: Checking for App Store updates..." "$YELLOW"
  runCommand "Checking for App Store updates..." "App Store updates complete." "mas upgrade"
else
  setStatus "MAS (Mac App Store CLI) is not installed. Skipping App Store updates." "$YELLOW"
  setStatus "You can install it with 'brew install mas' if you wish to update App Store apps via this script." "$YELLOW"
fi

# Step 4: Update Homebrew packages
runCommand "STEP 3 of 4: Updating Homebrew packages..." "Homebrew packages updated." "brew update && brew upgrade"

# Step 4: Cleanup unused Homebrew packages
runCommand "STEP 4 of 4: Cleaning up Homebrew..." "Homebrew cleanup complete." "brew cleanup"

# Check if a reboot is required
if softwareupdate -l | grep -q "restart"; then
  setStatus "PLEASE NOTE: A reboot is required." "$YELLOW"
  read -q "REBOOT_NOW?Would you like to reboot now? (y/n): "
  echo ""
  if [[ "$REBOOT_NOW" == "y" || "$REBOOT_NOW" == "Y" ]]; then
    setStatus "Rebooting..." "$YELLOW"
    reboot
  else
    setStatus "Done. Please remember to reboot the system at your convenience." "$GREEN"
  fi
else
  setStatus "No reboot is required." "$GREEN"
fi

setStatus "System update complete." "$GREEN"
