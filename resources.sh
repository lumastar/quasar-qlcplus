#!/bin/bash

# This script is for managing QLC+ resources and web iterface passwords in Raspbian

ASSETS=( "Fixtures" "InputProfiles" "MidiTemplates" "ModifiersTemplates" "RGBScripts" )
# Make asset dirs in /media/data
for asset in "${ASSETS[@]}"; do
	# Move assets in /boot to correct place
	if [ -e "/data/$asset" ]; then
		cp -r "/data/$asset" "/root/.qlcplus/"
	fi
done

if [ -e "/data/web_passwd" ]; then
	cp /data/webpasswd /root/.qlcplus/
fi
