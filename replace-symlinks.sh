#!/bin/sh

if [ $# -lt 1 ]; then
   echo "Usage replace-symlinks.sh <path>" >&2
   exit 1
fi

for link in $(find $1 -type l)
do
    src=$(readlink $link)
    rm -rf $link
    (cd $(dirname $link) && cp -r $src $(basename $link))
done
