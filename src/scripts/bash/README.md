# Overview:

This is an overview of the scripts in this folder.

# Scripts:

Below is a summary of each script and how to use them.

## Script: `backup_additive.sh`

This is a script that just backs up up the folders that you definitely need. For example, if you have a web server, you might just backup:

- `/etc/`
- `/var/www/`
- `/var/spool/cron`

So, when you need to restore, you would:

1. Start from a fresh VM.
2. Install the needed software.
3. Restore the directories that were backed-up.

> ### ℹ️ NOTE:
> This requires a `/etc/backups/secret.key` file. In that file, put a long, random set of characters that will be used for encryption. For example, a 64-character string [from a password generator](https://www.lastpass.com/features/password-generator) will do.

This may be fine in some scenarios, but you much test your restores to make sure that you are capturing everything that you need. You could run this, and capture all of the `stderr` and `stdout` with something like this:

```bash
./backup_additive.sh > ~/backup_`date +%Y.%m.%d.%H.%M.%S`.log 2>&1
```
That results in a filename like this: `backup_2021.10.09.21.28.23.log`.

## Script: `backup_subtractive.sh`

This is a script that backups the entire `/` file system, except where folders were explicitly excluded. Luckily, there are [some good examples](https://help.ubuntu.com/community/BackupYourSystem/TAR#Alternate_backup) of directories to exclude, for example:

- `/proc`
- `/tmp`
- `/mnt`
- `/dev`
- `/sys`
- `/run`
- `/media`
- `/log`
- `/var/cache/apt/archives`
- `/usr/src/linux-headers*`
- `/home/*/.gvfs`
- `/home/*/.cache`
- `/home/*/.local/share/Trash`

In this scenario you'd always to exclude your *previous* backups, and any "noise* that is specific to your setup.

> ### ℹ️ NOTE:
> This requires a `/etc/backups/secret.key` file. In that file, put a long, random set of characters that will be used for encryption. For example, a 64-character string [from a password generator](https://www.lastpass.com/features/password-generator) will do.

You could run this, and capture all of the `stderr` and `stdout` with something like this:

```bash
./backup_subtractive.sh > ~/backup_`date +%Y.%m.%d.%H.%M.%S`.log 2>&1
```
That results in a filename like this: `backup_2021.10.09.21.28.23.log`.

## Script: `backup_apache-wp-mysql.sh`

This is a custom script that was used in a specific environment where it stages all of the key files, and then tars, zips, and encrypts the folder:

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

```text++
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

## Script: `update-batch.sh`

This is a non-interactive version of the `update.sh` from above. Instead of interactively prompting you to reboot if a reboot is required, this will reboot automatically.

This script is best run via a cron job. Use the following to edit the cron schedule:

```bash
crontab -e
```

Then, add a line like this to have this run every day at 8am:

```crontab
  0     8       *       *       *       /root/update-batch.sh > /root/update-batch_lastrun.log 2>&1
```

To use a different schedule, use a website like:

> https://crontab.guru

To get the correct parameters for a different schedule.
