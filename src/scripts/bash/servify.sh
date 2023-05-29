#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "[-] This script must be run as root."
   exit 1
fi


# Check if all required parameters are provided
if [ $# -ne 4 ]; then
    echo "[-] Error: Incorrect number of parameters provided"
    echo "Usage: $0 <docker_image_name> <service_name> <host_port> <container_port>"
    exit 1
fi

docker_image_name=$1
service_name=$2
host_port=$3
container_port=$4

# Create a systemd service file
cat > "/etc/systemd/system/$service_name.service" << EOF
[Unit]
Description=$service_name Docker container
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run -p $host_port:$container_port $docker_image_name
ExecStop=/usr/bin/docker stop $service_name

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon
systemctl daemon-reload
if [ $? -eq 0 ]; then
    echo "[+] Success: Reloaded systemd daemon"
else
    echo "[-] Error: Failed to reload systemd daemon"
    exit 1
fi

# Enable the systemd service
systemctl enable $service_name.service
if [ $? -eq 0 ]; then
    echo "[+] Success: Enabled systemd service $service_name.service"
else
    echo "[-] Error: Failed to enable systemd service $service_name.service"
    exit 1
fi

# Start the systemd service
systemctl start $service_name.service
if [ $? -eq 0 ]; then
    echo "[+] Success: Started systemd service $service_name.service"
else
    echo "[-] Error: Failed to start systemd service $service_name.service"
    exit 1
fi

# Create a Nginx configuration file
cat > "/etc/nginx/sites-available/$service_name.example.com" << EOF
server {
    listen 80;
    server_name $service_name.example.com;

    location / {
        proxy_pass http://127.0.0.1:$host_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Enable the Nginx site
ln -s "/etc/nginx/sites-available/$service_name.example.com" "/etc/nginx/sites-enabled/"
if [ $? -eq 0 ]; then
    echo "[+] Success: Enabled Nginx site $service_name.example.com"
else
    echo "[-] Error: Failed to enable Nginx site $service_name.example.com"
    exit 1
fi

# Reload Nginx to apply the changes
systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "[+] Success: Reloaded Nginx to apply changes"
else
    echo "[-] Error: Failed to reload Nginx"
    exit 1
fi

sleep 2

# Obtain an SSL/TLS certificate using certbot
echo "certbot --nginx --non-interactive --agree-tos --redirect --hsts --domains $service_name.example.com"
if [ $? -eq 0 ]; then
    echo "[+] Success: Obtained SSL/TLS certificate for $service_name.example.com and enabled automatic redirect"
else
    echo "[-] Error: Failed to obtain SSL/TLS certificate for $service_name.example.com"
    exit 1
fi

# Reload Nginx to apply the changes
systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "[+] Success: Reloaded Nginx to apply changes"
else
    echo "[-] Error: Failed to reload Nginx"
    exit 1
fi
