# Overview:

This is an overview of the scripts in this folder.

# Scripts:

Below is a summary of each script and how to use them.

## Script: `backup_apache-wp-mysql.sh`

This is a custom script that:

- Wipes and sets up a working area.
- Backs up MySQL with `mysqldump --all-databases` command.
- Backs up the Apache configuration in `/etc/apache2/`.
- Backs up all of the currently configured LetsEncrypt certs in `/etc/letsencrypt/`.
- Backs up all of the web content in `/var/www/`.
- Backs up the crontab schedule.
- Compresses the above into a `.tar` file.
- Encrypts the archive with AES-256 encryption, using an external key file.
- Removes backups older than 60 days.
- Cleans up working area.

This is set up as a cron job that runs every 12 hours. That crontab looks like this, by the way:

```text
# m     h       dom     mon     dow     command
  0     0       *       *       SAT     certbot renew
  0     */12    *       *       *       /home/username/wordpress-backup.sh
```

The `certbot renew` checks if any www.letsencrypt.org certificates need to be renewed. Meanwhile, this script results in a directory of compressed, encrypted backup files like:

```text
-rw-r--r-- 1 root   root   30547174 Sep 10 05:10 all-sites-backup.2019.09.10.05.09.59.tar.gz.gpg
-rw-r--r-- 1 root   root   30551958 Sep 10 12:00 all-sites-backup.2019.09.10.12.00.01.tar.gz.gpg
-rw-r--r-- 1 root   root   30553873 Sep 11 00:00 all-sites-backup.2019.09.11.00.00.02.tar.gz.gpg
-rw-r--r-- 1 root   root   30394371 Sep 11 12:00 all-sites-backup.2019.09.11.12.00.02.tar.gz.gpg
-rw-r--r-- 1 root   root   30393703 Sep 12 00:00 all-sites-backup.2019.09.12.00.00.02.tar.gz.gpg
-rw-r--r-- 1 root   root   30386922 Sep 12 12:00 all-sites-backup.2019.09.12.12.00.02.tar.gz.gpg
-rw-r--r-- 1 root   root   30384769 Sep 13 00:00 all-sites-backup.2019.09.13.00.00.02.tar.gz.gpg
-rw-r--r-- 1 root   root   30383666 Sep 13 12:00 all-sites-backup.2019.09.13.12.00.02.tar.gz.gpg
-rw-r--r-- 1 root   root   30384871 Sep 14 00:00 all-sites-backup.2019.09.14.00.00.03.tar.gz.gpg
```

Finally, from a remote machine, I have a script that pulls these files down AND (important) pulls down that encryption key file too, so that these files could be decrypted when needed.

## Script: `setup-fail2ban.sh`

This is used to enable a simple Intrusion Prevention System (IPS). This monitors incoming connections. If a user incorrectly attempts to authenticate too many times within a specified time period, then that IP address is banned for a period of time.

## Script: `setup-ufw.sh`

This is used to enable a simple operating-system firewall. This enables SSH and web server ports (port 80 for http, and 443 for SSL). Please note that the line to turn on the firewall is commented out. 

> **WARNING:** You really need to make sure you have all of these settings correct, or else you will be locked out of your own server. For example, if you run SSH on a different port, like port `2222`, then you'd need an incoming `allow` for `2222/tcp`.

## Script: `update.sh`

This is a script I've built up over time that updates/upgrades the current Debian-based distribution to all of the latest software. This patches the current machine, and removes any cache or unneeded packages on the system.

> NOTE: If you install `neofetch` (for an OS ASCII graphic) and `figlet` for large text on the screen, you'll get a more visually interesting output.
