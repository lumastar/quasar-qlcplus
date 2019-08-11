#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# This is the Quasar QLC+ install script to be run in the Raspbian environment

# Install wiringpi to get the gpio utility
apt-get update
apt-get install -y wiringpi

# Change to directory mounted by raspbian-customiser
cd /quasar-qlcplus
# Note that things cannot be moved from here with mv, as it is not part of the loop file system
# The quasar-qlcplus directory will not be included in the final image

# Download and install raspbian-setup
curl -L https://github.com/lumastar/raspbian-setup/releases/download/v0.0.3/raspbian-setup-v0.0.3.zip -o raspbian-setup.zip
unzip raspbian-setup.zip
pushd raspbian-setup
cp ./*.sh /usr/local/bin
# Create and set raspbian-setup config
{
	echo "SILENT_BOOT=disable"
	echo "HOSTNAME=quasar"
	echo "UPDATE_USER=pi,lumastar,rotary"
	echo "INSTALL_WIREGUARD=true"
} >> /data/raspbian-setup.conf
# Create raspbian-setup.log
touch /data/raspbian-setup.log
# Run raspbian-setup.sh
/usr/local/bin/raspbian-setup.sh /data/raspbian-setup.conf /data/raspbian-setup.log
popd

# Install new QLC+ system service
cp ./assets/qlcplus /etc/init.d/qlcplus
systemctl daemon-reload

# Add settings for BitWiard DMX board
# https://bitwizard.nl/wiki/Dmx_interface_for_raspberry_pi
echo -e "\n# For BitWizard DMX interface" >> /boot/config.txt
# Disable Bluetooth in config.txt to support BitWiard DMX board
echo "dtoverlay=pi3-disable-bt" >> /boot/config.txt
# Change UART clock
echo "init_uart_clock=16000000" >> /boot/config.txt
# Disable UART serial interface
systemctl disable serial-getty@ttyAMA0.service
# Remove UART serial interface from cmdline.txt
sed -ie "s|console=ttyAMA0,115200 ||g" /boot/cmdline.txt

# Install files for QLC+ web kiosk mod
cp ./assets/common.css.kiosk /usr/share/qlcplus/web/common.css.kiosk
cp ./assets/common.css.normal /usr/share/qlcplus/web/common.css.normal

# Move other files to data partition
cp ./assets/web_passwd /data/
cp ./assets/qlcplus.conf /data/
cp ./assets/QLC+_RaspberryPi_Stretch_Guide_V1.pdf /data/
cp ./assets/qlcplus_gpio_restarter.sh /data/
cp ./assets/resources.sh /data/

# Copy the quasar-qlcplus.txt info file
cp ./quasar-qlcplus.txt /data/

# TODO: Should other assets from qlcplus-assets also be fetched here?

# Make asset dirs in data partition
ASSETS=( "Fixtures" "InputProfiles" "MidiTemplates" "ModifiersTemplates" "RGBScripts" )
for asset in "${ASSETS[@]}"; do
	mkdir "/data/$asset"
done

exit 0