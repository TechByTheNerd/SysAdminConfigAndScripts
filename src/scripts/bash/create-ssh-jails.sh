#!/bin/bash

# Function to create filter files
create_filter() {
    local filter_name=$1
    local filter_path="/etc/fail2ban/filter.d/${filter_name}.conf"

    cat > "$filter_path" << EOF
# Fail2Ban filter for ${filter_name}

[Definition]
failregex = $2
ignoreregex =
EOF

    echo "Created filter: $filter_path"
}

# Function to create jail entries
create_jail() {
    local jail_name=$1
    local filter_name=$2
    local jail_path="/etc/fail2ban/jail.d/${jail_name}.conf"

    cat > "$jail_path" << EOF
# Fail2Ban jail configuration for ${jail_name}

[${jail_name}]
enabled = true
filter = ${filter_name}
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 1h
EOF

    echo "Created jail: $jail_path"
}

# Create filter and jail for sshd-ddos
create_filter "sshd-ddos" "^Received disconnect from <HOST>: 11: .*"
create_jail "sshd-ddos" "sshd-ddos"

# Create filter and jail for sshd-iptables
create_filter "sshd-iptables" "^iptables.* <HOST> .* (?:Authentication failure|Failed \S+ for \S+ from <HOST>(?: port \d*)?(?: ssh\d*)?)"
create_jail "sshd-iptables" "sshd-iptables"

# Create filter and jail for sshd-root
create_filter "sshd-root" "^(?:Refused )?password .*? for .*? from <HOST>\s*$"
create_jail "sshd-root" "sshd-root"

# Create filter and jail for sshd-invaliduser
create_filter "sshd-invaliduser" "^(?:error: PAM: )?Authentication failure for .* from <HOST>\s*$"
create_jail "sshd-invaliduser" "sshd-invaliduser"

# Create filter and jail for sshd-repeated
create_filter "sshd-repeated" "^(?:error: PAM: )?Authentication failure for .* from <HOST>\s*$"
create_jail "sshd-repeated" "sshd-repeated"

# Create filter and jail for sshd-gssapi
create_filter "sshd-gssapi" "^Received disconnect from <HOST>: 14: .*"
create_jail "sshd-gssapi" "sshd-gssapi"

# Create filter and jail for sshd-ssl
create_filter "sshd-ssl" "^(?:error: )?Received disconnect from <HOST>: 14:.*"
create_jail "sshd-ssl" "sshd-ssl"

echo ""
echo "Restarting fail2ban..."
systemctl restart fail2ban

sleep 3

echo "Current Jails:"
./all-jails.sh
