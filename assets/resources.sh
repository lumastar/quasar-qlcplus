#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# Script for managing QLC+ resources and web interface passwords in Raspbian

# Check the script is running as root
if [[ $EUID -ne 0 ]]; then
   echo "must be run as root, will now exit" 
   exit 1
fi

ASSETS=( "Fixtures" "InputProfiles" "MidiTemplates" "ModifiersTemplates" "RGBScripts" )
# Make asset dirs in /media/data
for ASSET in "${ASSETS[@]}"; do
	# Move assets in /boot to correct place
	if [ -d "/data/$ASSET" ]; then
		cp -rf "/data/$ASSET" "/root/.qlcplus/"
	fi
done

if [ -e "/data/web_passwd" ]; then
	cp -f /data/webpasswd /root/.qlcplus/
fi
