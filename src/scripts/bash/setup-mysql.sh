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

Name='Debian-based MySQL Initializer'
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


function getRandomPassword {

    size=$1

    chars=abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ0123456789@#_

    for i in $(seq 1 $size); do
        echo -n ${chars:RANDOM%${#chars}:1}
    done
    echo ""

    return 0
}

echo -e "${LightPurple}$Name $Version${NC}"


if [[ $1 == "?" || $1 == "/?" || $1 == "--help" ]];
then
    setStatus "USAGE: sudo $0" "*"
    exit -2
fi


if [[ $(whoami) != "root" ]];
then
    setStatus "ERROR: This utility must be run as root (or sudo)." "f"
    exit -1
fi

setStatus "Installing: MySQL, and related packages..." "*"

apt-get install mysql-server mysql-client expect -y

setStatus "Packages installed." "s"


setStatus "Generating random password for root..." "*"
rootPassword=`getRandomPassword 96`
setStatus "Random password generated." "s"

setStatus "Running MySQL hardening script (i.e. mysql_secure_installation)" "*"


SECURE_MYSQL=$(expect -c "
set timeout 3
spawn mysql_secure_installation
#expect \"Enter current password for root (enter for none):\"
#send \"$CURRENT_MYSQL_PASSWORD\r\"
#expect \"root password?\"
#send \"y\r\"
expect \"New password:\"
send \"${rootPassword}\r\"
expect \"Re-enter new password:\"
send \"${rootPassword}\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")

echo $SECURE_MYSQL

setStatus "MySQL hardening complete." "s"


setStatus "WARNING: This MySQL instance has been set up. The root password is below:" "f"
setStatus "" "f"
setStatus "      User.........: root" "f"
setStatus "      Password.....: ${rootPassword}" "f"
setStatus "" "f"
setStatus "This is the only time this password will be available to you. Record this in your " "f"
setStatus "password manager or vault software right now!" "f"