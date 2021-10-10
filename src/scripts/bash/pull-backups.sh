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

Name='Debian-based Backup Puller'
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

backupRootFolder="/mnt/c/Users/user/SynologyDrive/Backups"
totalSteps="2"

setStatus "Pulling all remote backups..." "*"

runCommand "STEP 1 of ${totalSteps}: Pulling 'docs.bythenerd.com' backup log..." " - Done."\
        "rsync -arvz -e 'ssh -p 20022' --progress operations@docs.bythenerd.com:/var/log/sysbackups/* $backupRootFolder/docs.bythenerd.com/"
runCommand "STEP 2 of ${totalSteps}: Pulling 'docs.bythenerd.com' backup..." " - Done."\
        "rsync -arvz -e 'ssh -p 20022' --progress operations@docs.bythenerd.com:/var/sysbackups/*.gpg $backupRootFolder/docs.bythenerd.com/"

setStatus "Backup complete." "s"
