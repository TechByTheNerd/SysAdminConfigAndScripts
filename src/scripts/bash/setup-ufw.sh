#!/bin/bash

# Install ufw
sudo apt update
sudo apt install ufw -y

# Set default incoming/outgoing rules 
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Enable SSH on new port (NOTE: Change this to correct SSH port)
sudo ufw allow 22/tcp

# Enable web server ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Turn on the firewall
# DANGER: Make sure you are not locking yourself out!
#sudo ufw enable
