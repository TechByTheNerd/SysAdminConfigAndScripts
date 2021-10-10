#!/bin/bash

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

Name='Debian-based Backup Utility (additive)'
Version='v1.0.0-alpha.1'


function setStatus(){

    description=$1
    severity=$2

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

    [[ $WithVoice -eq 1 ]] && echo -e ${description} | espeak
}

function runCommand(){

    beforeText=$1
    afterText=$2
    commandToRun=$3

    setStatus "${beforeText}" "*"

    setStatus "    Executing: $commandToRun", "*"

    eval $commandToRun

    setStatus "$afterText" "s"

}

echo -e "${LightPurple}$Name $Version${NC}"


if [[ $1 == "?" || $1 == "/?" || $1 == "--help" ]];
then
    setStatus "USAGE: sudo $0" "i"
    exit -2
fi

if [[ $(whoami) != "root" ]];
then
    setStatus "ERROR: This utility must be run as root (or sudo)." "f"
    exit -1
fi

if [ $(which neofetch | wc -l) -gt 0 ];
then
    echo -e -n "${Yellow}"
    neofetch
    echo -e "${NC}"
fi

if [ $(which figlet | wc -l) -gt 0 ];
then
    echo -e -n "${Yellow}"
    echo $(hostname) | figlet
    echo -e "${NC}"
fi

fileCompressed="backup_`date +%Y.%m.%d.%H.%M.%S`.tar.gz"
fileEncrypted="${fileCompressed}.gpg"
totalSteps="5"

setStatus "Backup starting..." "*"


runCommand "STEP 1 of ${totalSteps}: Dumping up all MySQL databases..." " - Done. All MySQL databases dumped to: '/var/lib/mysql/backup_all_databases.sql'."\
	"mysqldump --all-databases > /var/lib/mysql/backup_all_databases.sql"

runCommand "STEP 2 of ${totalSteps}: Backing up key directories and files..." " - Done."\
	"tar -cvpzf /var/backup/$fileCompressed --exclude=/var/backup/ --exclude=/var/www/nc-data /etc /var/www /var/spool/cron /var/lib/mysql/*.sql"

runCommand "STEP 3 of ${totalSteps}: Encrypting backup..." " - Done. Backup encrypted: ${fileEncrypted}"\
	"gpg -c --cipher-algo AES256 --batch --passphrase-file /etc/backups/secret.key /var/backup/$fileCompressed && rm /var/backup/$fileCompressed"

runCommand "STEP 4 of ${totalSteps}: Remove backups older than 5 days." " - Done."\
	"find /var/backup/backup_* -mtime +5 -exec rm {} \;"

runCommand "STEP 5 of ${totalSteps}: Clean-up, and stage new backup for offsite copy." "Done staging new backups in '/var/backup/latest/'."\
	"rm -Rf /var/backup/latest/* ; rm -f /var/lib/mysql/backup_all_databases.sql ; ln -s /var/backup/$fileEncrypted /var/backup/latest/"

setStatus "Backup complete." "s"
