#!/bin/bash

# This is the build script to be invoked by Travis CI

set -e

echo "BUILD - Will now pull Docker image"
docker pull edwardotme/raspbian-customiser:v0.2

echo "FETCH - Will now fetch source image"
IMAGE_LINK=https://www.qlcplus.org/downloads/raspberry/713c4e9fbc9d61d8508f6533d97e062e/qlcplus_raspbian_stretch_20181110.7z
wget -nv $IMAGE_LINK
IMAGE_7Z=$(basename $IMAGE_LINK)
sudo apt-get -y install p7zip-full
7z e $IMAGE_7Z
rm $IMAGE_7Z
IMAGE_IMG=${IMAGE_ZIP%.7z}.img
echo "FETCH - Successfully fetched $IMAGE_IMG"

echo "INSTALL - Will now install modifications"
docker run --privileged --rm \
  -e MOUNT=/raspbian-setup \
  -e SOURCE_IMAGE=/raspbian-setup/${IMAGE_IMG} \
  -e SCRIPT=/raspbian-setup/install.sh \
  -e ADD_DATA_PART=true \
  --mount type=bind,source="$(pwd)",destination=/raspbian-setup \
  edwardotme/raspbian-customiser:v0.2

echo "DEPOLY - Will now package image"
zip quasar-qlcplus-${TRAVIS_TAG}.zip $IMAGE_IMG
