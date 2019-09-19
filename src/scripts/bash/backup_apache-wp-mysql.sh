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

Name='Debian-based Wordpress/Apache/MySQL Backup Utility'
Version='v1.0.0-alpha.1'

function setXtermTitle () {

    newTitle=$1

    if [[ -z $newTitle ]]
    then
        case "$TERM" in
            xterm*|rxvt*)
                PS1="\[\e]0;$newTitle\u@\h: \w\a\]$PS1"
            ;;
            *)
            ;;
        esac
    else
        case "$TERM" in
            xterm*|rxvt*)
                PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
            ;;
            *)
            ;;
        esac
    fi
}

function setStatus(){

    description=$1
    severity=$2

    setXtermTitle $description

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

fileCompressed="all-sites-backup.`date +%Y.%m.%d.%H.%M.%S`.tar.gz"
fileEncrypted="${fileCompressed}.gpg"
totalSteps="12"

setStatus "Backup starting..." "*"

runCommand "STEP 1 of ${totalSteps}: Wiping working area." " - Done. Working area clean"\
	"cd /var/backups/sysbackups/ && rm -Rf ./temp"
runCommand "STEP 2 or ${totalSteps}: Setting up new work area." " - Done. Work area set up"\
	"mkdir ./temp && cd temp"
runCommand "STEP 3 of ${totalSteps}: Backuping up all MySQL databases..." " - Done. All MySQL databases backed up to work area."\
	"mkdir ./mysql/ && mysqldump --all-databases > ./mysql/all_databases.sql"
runCommand "STEP 4 of ${totalSteps}: Backing up Apache website configuration..." " - Done. Apache website configuration backed up to work area."\
	"cp -R /etc/apache2/ ./apache/"
runCommand "STEP 5 of ${totalSteps}: Backing up LetsEncrypt SSL certificates..." " - Done. LetsEncrypt SSL certificates backed up to work area."\
	"cp -R /etc/letsencrypt/ ./certs/"
runCommand "STEP 6 of ${totalSteps}: Backing up physical WordPress files..." " - Done. Physical WordPress files backed up to work area."\
	"cp -R /var/www/ ./www/"
runCommand "STEP 7 of ${totalSteps}: Backing up Crontab..." " - Done. Crontab backed up to work area."\
	"crontab -l > ./crontab.txt"
runCommand "STEP 8 of ${totalSteps}: Compressing backup..." " - Done. Backup compressed: ${fileCompressed}"\
	"cd .. && tar -zcpf ./backups/${fileCompressed} ./temp/"
runCommand "STEP 9 of ${totalSteps}: Encrypting backup..." " - Done. Backup encrypted: ${fileEncrypted}"\
	"gpg -c --cipher-algo AES256 --batch --passphrase-file /var/backups/sysbackups/secret.key ./backups/${fileCompressed} && rm ./backups/${fileCompressed}"
runCommand "STEP 10 of ${totalSteps}: Cleaning up work area..." " - Done. Work area wipred."\
	"rm -Rf ./temp/"
runCommand "STEP 11 of ${totalSteps}: Remove backups older than 60 days." " - Done. Older files removed."\
	"find ./backups/all-sites-backup.* -mtime +60 -exec rm {} \;"
runCommand "STEP 12 of ${totalSteps}: Stage new backups for offsite copy." "Done staging new backups in './new/'."\
	"rm ./new/* ; cd ./new/ && find ../backups/all-sites-backup.* -mtime -1 -exec ln -s {} ./ \; && cd .."

setStatus "Backup complete." "s"
