#!/bin/bash

# NOTE: Must run as root. Use: sudo -s

# Install ufw
apt update
apt install fail2ban -y

# Generate default config file that configures SSH and Nginx
cat<< EOF > /etc/fail2ban/jail.local
[INCLUDES]
before = paths-debian.conf

[DEFAULT]
enabled = false
ignorecommand =
bantime  = 10m
findtime  = 10m
maxretry = 5
backend = auto
usedns = warn
logencoding = auto
mode = normal
filter = %(__name__)s[mode=%(mode)s]
destemail = root@localhost
sender = root@<fq-hostname>
mta = sendmail
protocol = tcp
chain = <known/chain>
port = 0:65535
fail2ban_agent = Fail2Ban/%(fail2ban_version)s
banaction = iptables-multiport
banaction_allports = iptables-allports
action_ = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mw = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
            %(mta)s-whois[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s"]
action_mwl = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
action_xarf = %(banaction)s[name=%(__name__)s, bantime="%(bantime)s", port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
             xarf-login-attack[service=%(__name__)s, sender="%(sender)s", logpath=%(logpath)s, port="%(port)s"]
action_cf_mwl = cloudflare[cfuser="%(cfemail)s", cftoken="%(cfapikey)s"]
                %(mta)s-whois-lines[name=%(__name__)s, sender="%(sender)s", dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s"]
action_blocklist_de  = blocklist_de[email="%(sender)s", service=%(filter)s, apikey="%(blocklist_de_apikey)s", agent="%(fail2ban_agent)s"]
action_badips = badips.py[category="%(__name__)s", banaction="%(banaction)s", agent="%(fail2ban_agent)s"]
action_badips_report = badips[category="%(__name__)s", agent="%(fail2ban_agent)s"]
action_abuseipdb = abuseipdb
action = %(action_)s

#
# JAILS
#
[sshd]
enabled = true
mode   = aggressive
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[dropbear]
enabled = true
port     = ssh
logpath  = %(dropbear_log)s
backend  = %(dropbear_backend)s

[apache-auth]
enabled = true
port     = http,https
logpath  = %(apache_error_log)s

[apache-badbots]
enabled = true
port     = http,https
logpath  = %(apache_access_log)s
bantime  = 48h
maxretry = 1

[apache-noscript]
enabled = true
port     = http,https
logpath  = %(apache_error_log)s

[apache-overflows]
enabled = true
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-nohome]
enabled = true
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-botsearch]
enabled = true
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-fakegooglebot]
enabled = true
port     = http,https
logpath  = %(apache_access_log)s
maxretry = 1
ignorecommand = %(ignorecommands_dir)s/apache-fakegooglebot <ip>

[apache-modsecurity]
enabled = true
port     = http,https
logpath  = %(apache_error_log)s
maxretry = 2

[apache-shellshock]
enabled = true
port    = http,https
logpath = %(apache_error_log)s
maxretry = 1

[php-url-fopen]
enabled = true
port    = http,https
logpath = %(nginx_access_log)s
          %(apache_access_log)s
EOF

# Set service to start and to start on boot-up
systemctl start fail2ban
systemctl enable fail2ban

# List current jails:
echo "Current fail2ban Jails:"
fail2ban-client status

# Show status of the SSHD jail:
echo "SSHD Jail Status:"
fail2ban-client status sshd
