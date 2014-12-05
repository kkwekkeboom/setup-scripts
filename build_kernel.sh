mkdir kernel

echo "Checking out kernel 3.14.25-ti-r37"
cd kernel
if [[ ! -e linux ]]; then
	git clone https://github.com/kkwekkeboom/linux
fi
cd linux
git checkout vaf_defconfig

echo "Configuring kernel"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- bb.org_defconfig

echo "Compiling kernel"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 uImage dtbs LOADADDR=0x82000000

echo "Copy kernel and device tree kernel folder"
cp arch/arm/boot/uImage ../
cp arch/arm/boot/dts/am335x-boneblack.dtb ../

echo "Compiling kernel modules"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j2 modules

echo "Installing kernel modules in kernel folder"
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- INSTALL_MOD_PATH=../kernel_modules modules_install


echo "Finished"
cd ../../
