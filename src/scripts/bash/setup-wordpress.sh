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

Name='Debian-based Wordpress Installer'
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
    setStatus "USAGE: sudo $0 [www.example.com] [root password]" "*"
    exit -2
fi

if [ -z $2 ];
then
    setStatus "USAGE: sudo $0 [www.example.com] [root password]" "*"
    exit -3
else
    domain=$1
    domainSafe=${domain//\./\_}         # Replace: www.example.com to www_example_com
    domainSafe=${domainSafe//-/\_}      # Replace: www.ex-ample.com to www_ex_ample_com
    domainRoot=${domain//www\./}        # Get the example.com part of the domain.
    rootPassword=$2
    setStatus "Setting up Wordpress for: ${domain} (${domainSafe})" "*"
fi


if [[ $(whoami) != "root" ]];
then
    setStatus "ERROR: This utility must be run as root (or sudo)." "f"
    exit -1
fi


setStatus "Checking if Wordpress has been downloaded..." "*"
if [ ! -f /tmp/latest.tar.gz ]; then
    setStatus "WARNING: Wordpress not found, downloading..." "*"
    cd /tmp/
    wget http://wordpress.org/latest.tar.gz
else
    setStatus "Wordpress found in /tmp/" "s"
fi

setStatus "Installing: Apache2, PHP, MySQL, and related packages..." "*"

apt-get install mysql-server mysql-client -y

apt-get install apache2 php libapache2-mod-php php-mysql php-curl php-gd php-intl php-pear php-imagick php-imap php-memcache php-ps php-pspell php-recode php-tidy php-xmlrpc php-xsl -y

setStatus "Packages installed." "s"


setStatus "Generating random password for Wordpress DB user..." "*"
wpPassword=`getRandomPassword 32`
setStatus "Random password generated." "s"


setStatus "Setting up Wordpress on the file system: /var/www/${domain}" "*"
cd /tmp/
setStatus " - Unzipping Wordpress..." "*"
unzipCount=`tar -xvzf latest.tar.gz | wc -l`
setStatus "Files unzipped: ${unzipCount}"

if [ ! -d /var/www/${domain} ];
then
    setStatus " - Creating destination folder and copying Wordpress files..." "*"
    mkdir /var/www/${domain}
else
    setStatus " - WARNING: Destination folder exists." "*"
fi

copyCount=`cp -uR wordpress/* /var/www/${domain}/ | wc -l`
setStatus "Files Copied: ${copyCount}"

setStatus " - Copying default starting configuration to the root wp-config.php, if missing."
cp /var/www/${domain}/wp-config-sample.php /var/www/${domain}/wp-config.php

wpUser="wpUser_${domainSafe}"
authKey=`getRandomPassword 64`
secureAuthKey=`getRandomPassword 64`
loggedInKey=`getRandomPassword 64`
nonceKey=`getRandomPassword 64`
authSalt=`getRandomPassword 64`
secureAuthSalt=`getRandomPassword 64`
loggedInSalt=`getRandomPassword 64`
nonceSalt=`getRandomPassword 64`

setStatus " - Updating wp-config.php with values for this site." "*"
replace01="sed -i.orig -e 's/database_name_here/${domainSafe}/g' /var/www/${domain}/wp-config.php"
replace02="sed -i -e 's/username_here/${wpUser}/g' /var/www/${domain}/wp-config.php"
replace03="sed -i -e 's/password_here/${wpPassword}/g' /var/www/${domain}/wp-config.php"

replace04="sed -i -e '0,/put your unique phrase here/ s//${authKey}/g' /var/www/${domain}/wp-config.php"
replace05="sed -i -e '0,/put your unique phrase here/ s//${secureAuthKey}/g' /var/www/${domain}/wp-config.php"
replace06="sed -i -e '0,/put your unique phrase here/ s//${loggedInKey}/g' /var/www/${domain}/wp-config.php"
replace07="sed -i -e '0,/put your unique phrase here/ s//${nonceKey}/g' /var/www/${domain}/wp-config.php"
replace08="sed -i -e '0,/put your unique phrase here/ s//${authSalt}/g' /var/www/${domain}/wp-config.php"
replace09="sed -i -e '0,/put your unique phrase here/ s//${secureAuthSalt}/g' /var/www/${domain}/wp-config.php"
replace10="sed -i -e '0,/put your unique phrase here/ s//${loggedInSalt}/g' /var/www/${domain}/wp-config.php"
replace11="sed -i -e '0,/put your unique phrase here/ s//${nonceSalt}/g' /var/www/${domain}/wp-config.php"

eval $replace01
eval $replace02
eval $replace03
eval $replace04
eval $replace05
eval $replace06
eval $replace07
eval $replace08
eval $replace09
eval $replace10
eval $replace11

setStatus " - Changing ownership to www-data:www-data for /var/www/${domain}" "*"
chown -R www-data:www-data /var/www/${domain}/

setStatus " - Setting file permissions to 0755 in /var/www/${domain}" "*"
chmod -R 755 /var/www/${domain}/

setStatus "Restarting the Apache web server..." "*"
systemctl restart apache2

setStatus "Setting up MySQL datbabase." "*"


setStatus " - Executing: \"DROP DATABASE ${domainSafe};\""
mysql -u root -p${rootPassword} -e "DROP DATABASE ${domainSafe};"

setStatus " - Executing: \"CREATE DATABASE ${domainSafe};\""
mysql -u root -p${rootPassword} -e "CREATE DATABASE ${domainSafe};"


setStatus " - Executing: \"DROP USER ${wpUser}@localhost;\""
mysql -u root -p${rootPassword} -e "DROP USER ${wpUser}@localhost;"

setStatus " - Executing: \"CREATE USER ${wpUser}@localhost IDENTIFIED BY '${wpPassword}';\""
mysql -u root -p${rootPassword} -e "CREATE USER ${wpUser}@localhost IDENTIFIED BY '${wpPassword}';"


setStatus " - Executing: \"GRANT ALL ON ${domainSafe}.* to ${wpUser}@localhost;\""
mysql -u root -p${rootPassword} -e "GRANT ALL ON ${domainSafe}.* to ${wpUser}@localhost;"

setStatus " - Executing: \"FLUSH PRIVILEGES;\""
mysql -u root -p${rootPassword} -e "FLUSH PRIVILEGES;"

setStatus " - Restarting MySQL Server..."
systemctl restart mysql

setStatus "MySQL setup complete." "s"

echo ""

function setUpApacheDomain {
    currentDomain=$1

    setStatus "Creating site for ${currentDomain} on port 80"

cat << EOF > /etc/apache2/sites-available/100-${currentDomain}.conf
<VirtualHost *:80>
        ServerName ${currentDomain}
        DocumentRoot /var/www/${currentDomain}

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    setStatus "Making new website available"
    cd /etc/apache2/sites-enabled/
    ln -s /etc/apache2/sites-available/100-${currentDomain}.conf ./

    setStatus "Restarting Apache web server."
    systemctl restart apache2

#    setStatus "Running CertBot to get SSL certificate (via LetsEncrypt.org)"
#    certbot --test-cert --apache -d ${currentDomain}
#    certbot --apache -d ${currentDomain}
}

setUpApacheDomain ${domain}
#setUpApacheDomain ${domainRoot}



setStatus "Restarting Apache web server a final time."
systemctl restart apache2

setStatus "You should be able to navigate to https://${domain}/" "s"