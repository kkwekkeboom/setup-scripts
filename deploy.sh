ROOTFS=/media/rootfs
BOOT=/media/boot
BUILD_DIR=build/tmp-angstrom_v2013_06-eglibc/deploy/images/beaglebone
pflag=
pval=
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
	FLASHER_IMAGE=$(find ${BUILD_DIR} -name "flasher-image-vaf*.tar.xz")
	echo "Copying ${FLASHER_IMAGE} to $ROOTFS"
	sudo rm -r ${ROOTFS}/*
	sudo tar -xf ${BUILD_DIR}/flasher-image-vaf-beaglebone.tar.xz -C ${ROOTFS}
	sudo cp sources/meta-angstrom/recipes-core/base-files/base-files/fstab ${ROOTFS}/etc

	echo "Copying kernel"
	#sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/uImage_vaf ${ROOTFS}/boot
#	sudo ln -sf /boot/uImage_vaf ${ROOTFS}/boot/uImage

	echo "Copying deployment image"
	sudo mkdir -p ${BOOT}/linux
	sudo cp ${BUILD_DIR}/console-image-vaf-beaglebone.tar.xz ${BOOT}/linux

	echo "Coyping bootloader MLO and uEnv"
	sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/MLO ${BOOT}
	sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/u-boot.img ${BOOT}
	sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/uEnv.txt ${BOOT}
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
	echo ,21,,-
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


