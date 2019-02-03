#!/bin/bash

# This is the build script to be invoked by Travis CI

set -e

echo "BUILD - Will now pull Docker image"
docker pull edwardotme/raspbian-customiser:v0.2

echo "FETCH - Will now fetch source image"
IMAGE_LINK=
wget -nv $IMAGE_LINK
IMAGE_ZIP=$(basename $IMAGE_LINK)
unzip -o $IMAGE_ZIP
rm $IMAGE_ZIP
IMAGE_IMG=${IMAGE_ZIP%.zip}.img
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
