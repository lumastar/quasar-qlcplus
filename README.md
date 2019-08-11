# quasar-qlcplus

[![Build Status](https://travis-ci.com/lumastar/quasar-qlcplus.svg?branch=master)](https://travis-ci.com/lumastar/quasar-qlcplus)

Scripts and extras to modify QLC+ Raspbian images to run on a Quasar Lighting Control Box.

The `travis.sh` script fetches the latest QLC+ Rasbpian `.img` file,
and uses the [raspbian-customiser](https://github.com/lumastar/raspbian-customiser)
tool to perform the modifications.
The raspbian-customiser adds a FAT32 format data partition to the image file.
It then runs the `install.sh` script inside the image to change and add files.
The modified `.img` is then compressed into a `.zip` archive for downloading,
and writing to SD cards.
This is currently run on Travis CI.

The reason for the modification is to enhance the standard QLC+ Raspbian image,
and make use of additional features given by the
[Quasar Box Hardware](https://github.com/lumastar/quasar-hardware).
