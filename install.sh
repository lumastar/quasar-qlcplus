#!/bin/bash

# This is the install script to be run in the Raspbian environment

# TODO: Open an issue to get changing to the mount directory integrated into raspbian-customiser
cd /quasar-qlcplus
# Note that things cannot be moved from here with mv, as it is not part of the loop file system
# The quasar-qlcplus directory will not be included in the final image

# TODO: Run raspbian-setup here to change username, password, hostname

# Install new QLC+ system service
cp ./assets/qlcplus /etc/init.d/qlcplus
systemctl daemon-reload

# Install files for QLC+ web kiosk mod
cp ./assets/common.css.kiosk /usr/share/qlcplus/web/common.css.kiosk
cp ./assets/common.css.normal /usr/share/qlcplus/web/common.css.normal

# Move other files to data partition
cp ./assets/web_passwd /data/
cp ./assets/qlcplus.conf /data/
cp ./assets/QLC+_RaspberryPi_Stretch_Guide_V1.pdf /data/
cp ./assets/qlcplus_gpio_restarter.sh /data/

# TODO: Should other assets from qlcplus-assets also be fetched here?

# Make asset dirs in data partition
ASSETS=( "Fixtures" "InputProfiles" "MidiTemplates" "ModifiersTemplates" "RGBScripts" )
for asset in "${ASSETS[@]}"; do
	mkdir "/data/$asset"
done

exit 0