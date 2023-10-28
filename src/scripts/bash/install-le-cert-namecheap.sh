#!/bin/bash

# ANSI color codes
CYAN="\e[36m"
AMBER="\e[33m"
RED="\e[31m"
RESET="\e[0m"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[-] Error: This script must be run as root.${RESET}"
    exit 1
fi

# Check if required positional arguments are provided
if [ "$#" -ne 4 ]; then
    echo -e "${RED}[-] Error: Insufficient arguments. Usage: $0 <HOSTNAME> <NAMECHEAP_API_KEY> <NAMECHEAP_USERNAME> <LETSENCRYPT_EMAIL>${RESET}"
    exit 1
fi

HOSTNAME="$1"
NAMECHEAP_API_KEY="$2"
NAMECHEAP_USERNAME="$3"
LETSENCRYPT_EMAIL="$4"

echo -e "${CYAN}[*] Setting up Namecheap API credentials${RESET}"
mkdir -p /etc/letsencrypt/namecheap
echo -e "dns_namecheap_api_key=$NAMECHEAP_API_KEY\ndns_namecheap_username=$NAMECHEAP_USERNAME" > /etc/letsencrypt/namecheap/api-credentials.ini

if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Error: Failed to set up Namecheap API credentials.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] Setting appropriate permissions for api-credentials.ini${RESET}"
chmod 600 /etc/letsencrypt/namecheap/api-credentials.ini

if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Error: Failed to set appropriate permissions for api-credentials.ini.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] Updating package repository${RESET}"
apt update

if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Error: Failed to update the package repository.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] Installing Python3 and pip${RESET}"
apt install certbot python3-certbot-apache python3-pip -y

if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Error: Failed to install Python3 and pip.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] Installing certbot-dns-namecheap via pip${RESET}"
pip3 install certbot-dns-namecheap

if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Error: Failed to install certbot-dns-namecheap.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] Requesting SSL certificate from Let's Encrypt${RESET}"
certbot certonly --dns-namecheap-credentials /etc/letsencrypt/namecheap/api-credentials.ini --agree-tos --email $LETSENCRYPT_EMAIL -d $HOSTNAME

if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Error: Failed to obtain the SSL certificate.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] Installing SSL certificate with Apache${RESET}"
certbot install --apache --cert-name $HOSTNAME

if [ $? -ne 0 ]; then
    echo -e "${RED}[-] Error: Failed to install the SSL certificate with Apache.${RESET}"
    exit 1
fi

echo -e "${CYAN}[*] SSL certificate has been successfully installed with Apache.${RESET}"
