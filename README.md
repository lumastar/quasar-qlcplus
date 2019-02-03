# quasar-qlcplus

Scripts and extras to modify QLC+ Raspbian images to run on a Quasar Lighting Control Box.

The `build.sh` script fetches the latest QLC+ Rasbpian `.img` file and uses the [raspbian-customiser]() tool to add a FAT32 format data partition, run scripts in the image, and add extra files. The modified `.img` is then compressed into a `.zip` archive for downloading and writing to SD cards. This is currently run on Travis CI.

The reason for the modification is to enhance the standard QLC+ Raspbian image, and make use of additional  features given by the [Quasar Box Hardware](https://github.com/lumastar/quasar-hardware).
