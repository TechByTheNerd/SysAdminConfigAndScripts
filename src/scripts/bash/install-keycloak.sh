#!/bin/bash

# Colors for messages
GREEN='\033[0;32m'
RED='\033[0;31m'
AMBER='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Exit codes
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_INVALID_ARGS=2

# Function to display success message
success() {
  echo -e "${GREEN}[+] Success:${NC} $1"
}

# Function to display error message and exit
error() {
  echo -e "${RED}[-] Error:${NC} $1"
  exit "$EXIT_FAILURE"
}

# Function to display warning message
warning() {
  echo -e "${AMBER}[!] Warning:${NC} $1"
}

# Function to display informational message
info() {
  echo -e "${CYAN}[*] Informational:${NC} $1"
}

# Function to display usage information
usage() {
  echo "Usage: sudo ./setup_keycloak.sh [--help]"
  echo
  echo "Options:"
  echo "  --help   Display this help screen"
  exit "$EXIT_INVALID_ARGS"
}

# Function to validate hostname
validate_hostname() {
  local hostname=$1
  local regex="^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"

  if [[ ! $hostname =~ $regex ]]; then
    error "Invalid hostname. Please provide a valid hostname."
  fi
}

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
  error "This script should be run with root privileges. Some commands may fail."
fi

# Check command-line arguments
if [[ $1 == "--help" ]]; then
  usage
elif [[ -n $1 ]]; then
  validate_hostname "$1"
  HOSTNAME=$1
else
  read -p "Enter the hostname for Keycloak (e.g., auth.example.com): " input_hostname
  validate_hostname "$input_hostname"
  HOSTNAME=$input_hostname
fi


# Install Docker
info "Installing Docker..."
if ! command -v docker &> /dev/null; then
  if ! curl -fsSL https://get.docker.com -o get-docker.sh; then
    error "Failed to download Docker installation script."
  fi
  if ! sh get-docker.sh; then
    error "Failed to install Docker."
  fi
  rm get-docker.sh
else
  warning "Docker is already installed. Skipping Docker installation."
fi
success "Docker installed."

# Install Docker Compose
info "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
  if ! curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-Linux-x86_64 -o /usr/local/bin/docker-compose; then
    error "Failed to download Docker Compose binary."
  fi
  if ! chmod +x /usr/local/bin/docker-compose; then
    error "Failed to set execute permissions for Docker Compose."
  fi
else
  warning "Docker Compose is already installed. Skipping Docker Compose installation."
fi
success "Docker Compose installed."

# Install Nginx
info "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
  if ! apt-get install nginx -y; then
    error "Failed to install Nginx."
  fi
else
  warning "Nginx is already installed. Skipping Nginx installation."
fi
success "Nginx installed."

# Install Certbot
info "Installing Certbot..."
if ! command -v certbot &> /dev/null; then
  if ! apt-get install certbot -y; then
    error "Failed to install Certbot."
  fi
else
  warning "Certbot is already installed. Skipping Certbot installation."
fi
success "Certbot installed."

# Set variables
KEYCLOAK_USER="admin"
KEYCLOAK_PASSWORD="admin"
KEYCLOAK_DIRECTORY="/opt/keycloak"
KEYCLOAK_USER_HOME="/home/keycloak"

info "Creating Keycloak user and directory..."
if ! id -u keycloak >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" keycloak || error "Failed to create Keycloak user."
else
  warning "Keycloak user already exists. Skipping user creation."
fi

if ! groups keycloak | grep -q docker; then
  usermod -aG docker keycloak || warning "Failed to add Keycloak user to the 'docker' group."
else
  warning "Keycloak user is already in the 'docker' group."
fi

mkdir -p "$KEYCLOAK_DIRECTORY" || error "Failed to create Keycloak directory."
chown -R keycloak:keycloak "$KEYCLOAK_DIRECTORY" || error "Failed to set ownership for Keycloak directory."
success "Keycloak user and directory created."


# Create Docker Compose file
info "Creating Docker Compose file..."
cat >"$KEYCLOAK_DIRECTORY/docker-compose.yaml" <<EOF
version: '3.8'
services:
  keycloak:
    image: jboss/keycloak
    volumes:
      - ./data:/opt/jboss/keycloak/standalone/data
    environment:
      - KEYCLOAK_USER=$KEYCLOAK_USER
      - KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD
    restart: always
EOF
success "Docker Compose file created."

# Create systemd service file
info "Creating systemd service file..."
cat >/etc/systemd/system/keycloak.service <<EOF
[Unit]
Description=Keycloak
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=keycloak
WorkingDirectory=$KEYCLOAK_DIRECTORY
ExecStart=/usr/bin/docker-compose up
ExecStop=/usr/bin/docker-compose down
Restart=always

[Install]
WantedBy=multi-user.target
EOF
success "Systemd service file created."

# Set ownership and permissions for Docker config directory
DOCKER_CONFIG_DIR="$KEYCLOAK_USER_HOME/.docker"
info "Setting ownership and permissions for Docker config directory..."

# Check if Docker config directory exists, create it if necessary
if [[ ! -d "$DOCKER_CONFIG_DIR" ]]; then
  mkdir -p "$DOCKER_CONFIG_DIR" || error "Failed to create Docker config directory."
  success "Docker config directory created."
else
  warning "Docker config directory already exists. Skipping directory creation."
fi

# Set ownership and permissions for Docker config directory
if ! chown -R keycloak:keycloak "$DOCKER_CONFIG_DIR"; then
  error "Failed to set ownership for Docker config directory."
fi

if ! chmod -R 600 "$DOCKER_CONFIG_DIR"; then
  error "Failed to set permissions for Docker config directory."
fi
success "Ownership and permissions set for Docker config directory."


# Reload systemd and start Keycloak service
info "Reloading systemd and starting Keycloak service..."
if ! systemctl is-active --quiet keycloak.service; then
  systemctl daemon-reload || error "Failed to reload systemd."
  systemctl start keycloak.service || error "Failed to start Keycloak service."
else
  warning "Keycloak service is already running. Skipping service start."
fi
success "Keycloak service started."

# Enable Keycloak service to start on boot if not already enabled
info "Enabling Keycloak service to start on boot..."
if ! systemctl is-enabled --quiet keycloak.service; then
  systemctl enable keycloak.service || error "Failed to enable Keycloak service."
else
  warning "Keycloak service is already enabled. Skipping service enablement."
fi
success "Keycloak service enabled."

# Enable Keycloak service to start on boot
info "Enabling Keycloak service to start on boot..."
systemctl enable keycloak.service || error "Failed to enable Keycloak service."
success "Keycloak service enabled."

# Install Nginx
info "Installing Nginx..."
if ! apt-get install nginx -y; then
  error "Failed to install Nginx."
fi
success "Nginx installed."

# Create Nginx configuration
info "Creating Nginx configuration..."
if [[ ! -e /etc/nginx/sites-available/keycloak.conf ]]; then
  cat >/etc/nginx/sites-available/keycloak.conf <<EOF
server {
    listen 80;
    server_name $HOSTNAME;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
  success "Nginx configuration created."
else
  warning "Nginx configuration already exists. Skipping configuration creation."
fi

# Enable Nginx site if it's not already enabled
info "Enabling Nginx site..."
if [[ ! -e /etc/nginx/sites-enabled/keycloak.conf ]]; then
  ln -s /etc/nginx/sites-available/keycloak.conf /etc/nginx/sites-enabled/ || error "Failed to enable Nginx site."
  success "Nginx site enabled."
else
  warning "Nginx site is already enabled. Skipping site enablement."
fi

# Reload Nginx
info "Reloading Nginx..."
systemctl reload nginx || error "Failed to reload Nginx."
success "Nginx reloaded."

# Install Certbot
info "Installing Certbot..."
if ! apt-get install certbot -y; then
  error "Failed to install Certbot."
fi
success "Certbot installed."

# Obtain SSL certificate
info "Obtaining SSL certificate..."
if [[ ! -e /etc/letsencrypt/live/$HOSTNAME/fullchain.pem ]] || [[ ! -e /etc/letsencrypt/live/$HOSTNAME/privkey.pem ]]; then
  certbot certonly --nginx --agree-tos -n -d "$HOSTNAME" || error "Failed to obtain SSL certificate."
  success "SSL certificate obtained."
else
  warning "SSL certificate already exists. Skipping certificate acquisition."
fi

# Display final instructions
echo -e "${CYAN}[+] Keycloak setup complete.${NC}"
echo "You can access Keycloak at https://$HOSTNAME"

exit "$EXIT_SUCCESS"
