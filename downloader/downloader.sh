#!/bin/bash

ip="127.0.0.1"
port=80

file_to_download=$1
output=$2

if [ -z "$file_to_download" ] && [ -z "$output" ]
then
    echo "Usage: downloader.sh <remote-file-to-download> <local-output-path>"
    exit 1
fi

exec 3<>/dev/tcp/"$ip"/"$port"
echo -e "GET /$file_to_download HTTP/1.1\r\n""Host: $ip\r\n""Connection: close\r\n\r\n" >&3

for i in `seq 1 7`;
do
    read -u 3 line
    if [[ $line =~ ^HTTP/1\.0[[:blank:]]([0-9]{3}) ]]
    then
        if [ ${BASH_REMATCH[1]} != "200" ]
        then
            exit 1
        fi
    fi
done

while [ 1 ]
do
    read -u 3 line
    if [ -z "$line" ]
    then
        break
    fi

    echo $line >> $output
done

exec 3<&-
exit 0