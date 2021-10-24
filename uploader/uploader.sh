#!/bin/bash

ip="127.0.0.1"
port=8100

file_to_upload=$1

if [ -z "$file_to_upload" ] || [ ! -f $file_to_upload ]
then
    echo "Usage: uploader.sh <local-file-to-upload>"
    exit 1
fi

exec 4<>/dev/tcp/"$ip"/"$port"
cat $file_to_upload >&4
exec 4<&-
exit 0