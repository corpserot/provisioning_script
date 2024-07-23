#!/bin/bash

# Modified from:
# https://github.com/Sushrut1101/GoFile-Upload/blob/43b7ecb25a93bb09dc32dea9dc6554a57dd405c0/upload.sh

# Exit if No File is Specified
if [[ "$#"  ==  '0' ]]; then
echo  -e 'ERROR: No File Specified!' && exit 1
fi

# File to Upload
FILE="@$1"

# Find the Best server to upload
SERVER=$(curl -s https://api.gofile.io/getServer | jq  -r '.data|.server')
LINK=$(curl -# -F file=${FILE} https://${SERVER}.gofile.io/uploadFile | jq -r '.data|.downloadPage') 2>&1

# Print the link!
echo $LINK
echo
