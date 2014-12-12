ROOTFS=/media/rootfs
BOOT=/media/boot
BUILD_DIR=build/tmp-angstrom_v2012_12-eglibc/deploy/images/beaglebone
pflag=
pval=
mflag=
mval=
cflag=
#expect to partitions of an SD-card

create_flasher_image()
{
	if [[ ! -d $ROOTFS ]]; then
		echo "no rootfs mounted";
		exit
	fi
	if [[ ! -d $BOOT ]]; then
		echo "no boot partition mounted";
		exit
	fi
	#if [[ ! -e ./kernel/uImage ]]; then
	#	echo "First build kernel (build_kernel.sh)"
	#	exit;
	#fi

	if [[ ! -e ${BUILD_DIR}/console-image-vaf-beaglebone.tar.xz ]]; then
		echo "First build console image (bitbake console-image-vaf)"
		exit;
	fi

	if [[ ! -e ${BUILD_DIR}/flasher-image-vaf-beaglebone.tar.xz ]]; then
		echo "First build flasher image (bitbake flasher-image-vaf)"
		exit
	fi

	if [[ ! -e ${BUILD_DIR}/MLO-beaglebone-2013.04 ]]; then
		echo "First build MLO (bitbake u-boot-vaf)"
		exit
	fi

	if [[ ! -e ${BUILD_DIR}/u-boot-beaglebone-2013.04-r0.img ]]; then
		echo "First build u-boot (bitbake u-boot-vaf)"
		exit
	fi

	FLASHER_IMAGE=$(find ${BUILD_DIR} -name "flasher-image-vaf*.tar.xz")
	echo "Copying ${FLASHER_IMAGE} to $ROOTFS"
	sudo rm -r ${ROOTFS}/*
	sudo rm -r ${BOOT}/*
	sudo tar -xf ${BUILD_DIR}/flasher-image-vaf-beaglebone.tar.xz -C ${ROOTFS}
	sudo cp sources/meta-angstrom/recipes-core/base-files/base-files/fstab ${ROOTFS}/etc

#	echo "Copying 3.14.25 kernel"
#	sudo rm ${ROOTFS}/boot/uImag*
#	sudo cp ./kernel/uImage ${ROOTFS}/boot

#	echo "Copying kernel modules to include kernel 3.14.25"
	#sudo rm -r ${ROOTFS}/lib/modules/*
#	cd kernel/linux
#	sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- INSTALL_MOD_PATH=${ROOTFS}
#	sudo cp -r ./kernel/kernel_modules/lib/modules/* ${ROOTFS}/lib/modules
#	cd ../../
#	echo "Copying device tree"
#	sudo cp ./kernel/am335x-boneblack.dtb ${ROOTFS}/boot

	echo "Copying deployment image"
	sudo mkdir -p ${BOOT}/linux
	sudo cp ${BUILD_DIR}/console-image-vaf-beaglebone.tar.xz ${BOOT}/linux

	echo "Coyping bootloader MLO and uEnv"
	sudo cp ${BUILD_DIR}/MLO-beaglebone-2013.04 ${BOOT}/MLO
	sudo cp ${BUILD_DIR}/u-boot-beaglebone-2013.04-r0.img ${BOOT}/u-boot.img
	#echo "fdtaddr=0x88000000" > ${BOOT}/uEnv.txt
	#sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/uEnv.txt ${BOOT}
	sync
}

prepare_sdcard()
{
	echo "preparing drive: $1"
	fdisk -l $1
	read -p "Press [Enter] to continue..."
	umount ${1}1
	umount ${1}2
	export LC_ALL=C

	if [ $# -ne 1 ]; then
		echo "Usage: $0 <drive>"
		exit 1;
	fi

	DRIVE=$1
	
	dd if=/dev/zero of=$DRIVE bs=1024 count=1024

	SIZE=`fdisk -l $DRIVE | grep Disk | grep bytes | awk '{print $5}'`

	echo DISK SIZE - $SIZE bytes

	CYLINDERS=`echo $SIZE/255/63/512 | bc`

	echo CYLINDERS - $CYLINDERS
	{
	echo ,5,0x0C,*
	echo ,12,,-
	} | sfdisk -D -H 255 -S 63 -C $CYLINDERS $DRIVE

	sleep 1
	sync
	mkfs.msdos ${1}1 -n "boot"
	mkfs.ext2 ${1}2 -L "rootfs"
}

while getopts cp: arg; do
  case "${arg}" in
  p)
 	    pval="$OPTARG"
			pflag=1
      ;;
  c)
			cflag=1
      ;;
	m)	
			mval="$OPTARG"
			mflags=1
			;;
	\?)	
			echo "invalid option -$OPTARG" >&2
			;;
  esac
done

if [ ! -z "$pflag" ]; then
	prepare_sdcard $pval
fi
if [ ! -z "$cflag" ]; then
	create_flasher_image
fi

shift $((OPTIND-1))
