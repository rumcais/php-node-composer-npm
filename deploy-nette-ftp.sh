#!/bin/sh

if [ $# -lt 5 ]; then
   echo "Usage deploy-ftp.sh <ftp host> <ftp user> <ftp passwd> <source dir> <targer dir>" >&2
   exit 1
fi

FTP_HOST=$1
FTP_USER=$2
FTP_PASS=$3
SOURCE=$4
TARGET=$5

lftp -c "set ftp:ssl-allow no; open -u $FTP_USER,$FTP_PASS $FTP_HOST; mirror -Rev $SOURCE $TARGET --parallel=10 --exclude-glob .git* --exclude .git/ --exclude temp/sessions/* --exclude www/galleries/* --exclude www/images/*"
