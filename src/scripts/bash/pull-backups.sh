#!/bin/bash

ACCOUNT=operations
HOST=www.example.com

echo "[*] Getting file listing from remote server...."
ssh -i /home/user/.ssh/id_rsa ${ACCOUNT}@${HOST} "cd ~/backup/new/ && ls -a ./*" > /tmp/remoteFiles.txt
echo "[+] - Done."

echo "[*] Getting file listing on current server..."
cd ~/backups/
ls -a ./*.gpg > /tmp/localFiles.txt
cd - > /dev/null
echo "[+] - Done."


echo "[*] Comparing remote to local to see what is missing..."
missingFiles=`comm -23 /tmp/remoteFiles.txt /tmp/localFiles.txt`
rm -f /tmp/remoteFiles.txt
rm -f /tmp/localFiles.txt

echo "[*] Processing new/missing files:"
for fileName in $( echo "${missingFiles}" )
do
    echo "    [*] Working on '$fileName' file name now."
    scp -p -i /home/user/.ssh/id_rsa ${ACCOUNT}@${HOST}:~/backup/new/${fileName} ~/backups/
done
echo "[+] - Done."


echo "[*] Getting the current backup script and key, too."
scp -p -i /home/user/.ssh/id_rsa ${ACCOUNT}@${HOST}:~/backup/* ~/backups/
echo "[+] - Done."