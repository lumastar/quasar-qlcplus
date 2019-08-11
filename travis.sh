#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# This is the Quasar QLC+ build script to be invoked by Travis CI

echo "FETCH - Will now install requirements"
sudo apt-get update
sudo apt-get install -y shellcheck p7zip-full

echo "TEST - Will now Shellcheck scripts"
shellcheck travis.sh
shellcheck install.sh
# We don't want to follow all sourced scripts here to can ignore error SC1091 
shellcheck -e SC1091 assets/qlcplus
shellcheck assets/qlcplus_gpio_restarter.sh
shellcheck assets/resources.sh
echo "TEST - Successfully Shellchecked scripts"

echo "BUILD - Will now pull Docker image"
docker pull edwardotme/raspbian-customiser:v0.2.1

echo "FETCH - Will now fetch source image"
IMAGE_LINK=https://www.qlcplus.org/downloads/raspberry/729b0dc1f5d88bc2e911e306b17b1d70/qlcplus_raspbian_stretch_20190217.7z
wget -nv $IMAGE_LINK
IMAGE_7Z=$(basename $IMAGE_LINK)
7z e "$IMAGE_7Z"
rm "$IMAGE_7Z"
IMAGE_IMG=${IMAGE_7Z%.7z}.img
echo "FETCH - Successfully fetched $IMAGE_IMG"

# Create quasar-qlcplus.txt info file
DATE=$(date '+%Y.%m.%d-%H.%M.%S')
{
	echo "Quasar QLC+"
	echo "Scripts and extras to modify QLC+ Raspbian images to run on a Quasar Lighting Control Box."
	echo "https://github.com/lumastar/quasar-qlcplus"
	echo "Based on ${IMAGE_IMG}"
	echo "Version ${TRAVIS_TAG}"
	echo "Built ${DATE}"
} >> quasar-qlcplus.txt

echo "INSTALL - Will now install modifications"
docker run --privileged --rm \
  -e MOUNT="/quasar-qlcplus" \
  -e SOURCE_IMAGE="/quasar-qlcplus/${IMAGE_IMG}" \
  -e SCRIPT="/quasar-qlcplus/install.sh" \
  -e ADD_DATA_PART="true" \
  --mount type=bind,source="$(pwd)",destination=/quasar-qlcplus \
  edwardotme/raspbian-customiser:v0.2.1

echo "DEPOLY - Will now package image"
FINAL_IMAGE_IMG=quasar-qlcplus-${TRAVIS_TAG}.img
mv "$IMAGE_IMG" "$FINAL_IMAGE_IMG"
FINAL_IMAGE_ZIP=quasar-qlcplus-${TRAVIS_TAG}.zip
zip "$FINAL_IMAGE_ZIP" "$FINAL_IMAGE_IMG"
