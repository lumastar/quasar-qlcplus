#!/bin/bash

# This is the install script to be run in the Raspbian environment

# TODO: Run raspbian-setup here to change username, password, hostname

# Install new QLC+ system service
mv ./resources/qlcplus /etc/init.d/qlcplus
systemctl daemon-reload

# Install files for QLC+ web kiosk mod
mv ./assets/common.css.kiosk /usr/share/qlcplus/web/common.css.kiosk
mv ./assets/common.css.normal /usr/share/qlcplus/web/common.css.normal

# Move other files to data partition
mv ./assets/web_passwd /data/
mv ./assets/qlcplus.conf /data/
mv ./assets/QLC+_RaspberryPi_Stretch_Guide_V1.pdf /data/
mv ./assets/qlcplus_gpio_restarter.sh /data/

# TODO: Should other assets from qlcplus-assets also be fetched here?

# Make asset dirs in data partition
ASSETS=( "Fixtures" "InputProfiles" "MidiTemplates" "ModifiersTemplates" "RGBScripts" )
for asset in "${ASSETS[@]}"; do
	mkdir "/data/$asset"
done

exit 0