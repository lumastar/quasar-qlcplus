#!/bin/bash

# This is the build script to be invoked by Travis CI

set -e

echo "BUILD - Will now pull Docker image"
docker pull edwardotme/raspbian-customiser:v0.2

echo "FETCH - Will now fetch source image"
IMAGE_LINK=https://www.qlcplus.org/downloads/raspberry/729b0dc1f5d88bc2e911e306b17b1d70/qlcplus_raspbian_stretch_20190217.7z
wget -nv $IMAGE_LINK
IMAGE_7Z=$(basename $IMAGE_LINK)
sudo apt-get -y update && sudo apt-get -y install p7zip-full
7z e $IMAGE_7Z
rm $IMAGE_7Z
IMAGE_IMG=${IMAGE_7Z%.7z}.img
echo "FETCH - Successfully fetched $IMAGE_IMG"

echo "INSTALL - Will now install modifications"
docker run --privileged --rm \
  -e MOUNT=/quasar-qlcplus \
  -e SOURCE_IMAGE=/quasar-qlcplus/${IMAGE_IMG} \
  -e SCRIPT=/quasar-qlcplus/install.sh \
  -e ADD_DATA_PART=true \
  --mount type=bind,source="$(pwd)",destination=/quasar-qlcplus \
  edwardotme/raspbian-customiser:v0.2

echo "DEPOLY - Will now package image"
zip quasar-qlcplus-${TRAVIS_TAG}.zip $IMAGE_IMG
