#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# This is the Quasar QLC+ install script to be run in the Raspbian environment

if [[ $EUID -ne 0 ]]; then
   echo "this script requires root privileges"
   exit 1
fi

# Install wiringpi to get the gpio utility
apt-get update
apt-get install -y wiringpi

# Enter directory of quasar-qlcplus repo
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/" >/dev/null 2>&1 && pwd )"
pushd "$REPO_ROOT"

# Note that when using the raspian-customiser tool used in the Travis CI build
# files cannot be moved from here with mv, as it is not part of the loop file
# system. Files should be copied with cp instead. The quasar-qlcplus directory
# will not be included in the final image with.

# Download and install raspbian-setup
curl -L https://github.com/lumastar/raspbian-setup/releases/download/v0.0.4/raspbian-setup-v0.0.4.zip -o raspbian-setup.zip
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
/usr/local/bin/raspbian-setup.sh /data/raspbian-setup.conf
popd

# Install new QLC+ system service
cp ./assets/qlcplus /etc/init.d/qlcplus
systemctl daemon-reload
# Install QLC+ scripts
cp ./assets/qlcplus-helper.sh /usr/local/bin/
cp ./assets/qlcplus-utility-button.sh /usr/local/bin/

# Add settings for BitWiard DMX board to config.txt
# https://bitwizard.nl/wiki/Dmx_interface_for_raspberry_pi
{
    echo -e "\n# For BitWizard DMX interface"
    # Disable Bluetooth in config.txt to support BitWiard DMX board
    echo "dtoverlay=pi3-disable-bt"
    # Change UART clock
    echo "init_uart_clock=16000000" >> /boot/config.txt
} >> /boot/config.txt

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

# Copy the quasar-qlcplus.txt info file
cp ./quasar-qlcplus.txt /data/

# Make asset directories in data partition
ASSETS=( "fixtures" "inputprofiles" "miditemplates" "modifierstemplates" "rgbscripts" )
for asset in "${ASSETS[@]}"; do
	mkdir "/data/$asset"
done

popd
