#!/bin/bash

# Exit if No File is Specified
if [[ "$#"  ==  '0' ]]; then
echo  -e 'ERROR: No File Specified!' && exit 1
fi

# File to download
LINK="@$1"

if [[ "$LINK" = *"gofile.io/"* ]]; then
    gofile-dl "$@"
elif [[ "$LINK" = *"drive.google.com/"* ]]; then
    gdown --fuzzy "$@"
elif [[ "$LINK" = *"mega.co/"* || "$LINK" = *"mega.nz/"* ]]; then
    mega-get "$@"
elif [[ -n "$PROVISIONING_WGET" ]]; then
    wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" "$@"
else
    aria2c --console-log-level=error --optimize-concurrent-downloads -c -x 16 -s 16 -k 1M "$@"
fi
